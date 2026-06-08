#!/bin/bash
# measure-ctx.sh — cmux 룰 17: 매 prompt 마다 각 terminal surface 의 ctx% 측정.
#
# UserPromptSubmit 훅. 이 훅의 stdout 은 다음 turn 의 컨텍스트로 주입된다.
# → 어떤 surface 가 2연속 40%↑ 면 stdout 으로 handoff 검토 경고를 내보내,
#   에이전트가 직접 측정하지 않아도 harness 가 룰 17 을 강제하게 한다.
#
# 안전 규약 (다른 환경/PC 공유 가정):
# - cmux 가 없으면 조용히 종료 (다른 환경 영향 없음)
# - ctx 미감지 surface 는 skip (화면 파싱 fragile → false alarm 차단)
# - 무슨 일이 있어도 exit 0 (훅 오류로 세션 방해 금지)

# cmux CLI 가 없으면 아무것도 안 함
command -v cmux >/dev/null 2>&1 || exit 0

TS=$(date +%s)
THRESHOLD=${CMUX_CTX_THRESHOLD:-40}    # 경고 발동 ctx 임계값(%) — env 오버라이드 가능(테스트용)
COOLDOWN=${CMUX_CTX_COOLDOWN:-3600}    # 같은 surface 재경고 쿨다운(초) = 1h
TRIM=50                                # 히스토리 로그 보존 줄 수

WARN=""

# 전체 트리에서 terminal surface ref 열거 (모든 workspace — 룰 17 은 세션 전역)
SURFACES=$(cmux tree --all 2>/dev/null \
  | grep -oE 'surface:[0-9]+ \[terminal\]' \
  | grep -oE 'surface:[0-9]+')

for ref in $SURFACES; do
  safe=${ref/:/}                                  # surface:4 → surface4 (기존 로그 컨벤션)
  log="/tmp/cmux-ctx-history-${safe}.log"
  cool="/tmp/cmux-ctx-cooldown-${safe}"

  # 화면 하단 상태줄에서 ctx% 추출. 미감지(유휴/비-Claude surface) → skip.
  pct=$(cmux read-screen --surface "$ref" --lines 6 2>/dev/null \
        | grep -oE 'ctx[: ]*[0-9]+%' | grep -oE '[0-9]+' | tail -1)
  [ -z "$pct" ] && continue

  # 히스토리 append + trim (마지막 TRIM 줄만 보존)
  echo "$TS $pct" >> "$log"
  if tail -n "$TRIM" "$log" > "${log}.tmp" 2>/dev/null; then
    mv "${log}.tmp" "$log"
  fi

  # 숫자 측정 라인만 추려 직전 2개 모두 ≥ THRESHOLD 인지 판정
  # (handoff_done 같은 비숫자 마커 라인은 무시)
  last2=$(grep -E '^[0-9]+ [0-9]+$' "$log" | tail -2)
  count=$(printf '%s\n' "$last2" | grep -c .)
  [ "$count" -lt 2 ] && continue
  high=$(printf '%s\n' "$last2" | awk -v t="$THRESHOLD" '{ if ($2+0 >= t) c++ } END { print c+0 }')
  [ "$high" -lt 2 ] && continue

  # 쿨다운 체크 — cooldown 파일 mtime 이 COOLDOWN 이내면 재경고 skip
  # stat: macOS(-f %m) / GNU(-c %Y) 모두 대응
  if [ -f "$cool" ]; then
    mtime=$(stat -f %m "$cool" 2>/dev/null || stat -c %Y "$cool" 2>/dev/null || echo 0)
    age=$(( TS - mtime ))
    [ "$age" -lt "$COOLDOWN" ] && continue
  fi
  : > "$cool"                                      # 쿨다운 시작(touch)

  cur=$(printf '%s\n' "$last2" | tail -1 | awk '{print $2}')
  WARN="${WARN}⚠️ [cmux 룰 17] ${ref} ctx ${cur}% (2연속 ${THRESHOLD}%↑) — handoff 검토 권장\n"
done

# stdout 출력 = 컨텍스트 주입 (경고 있을 때만)
[ -n "$WARN" ] && printf "%b" "$WARN"
exit 0
