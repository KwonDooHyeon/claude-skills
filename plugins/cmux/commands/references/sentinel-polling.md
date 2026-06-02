# cmux 위임 sentinel & 폴링 규약 (필수 Read 자료)

> **언제 이 파일을 Read 하나**: 메인 `cmux-workspace` 가 *위임 메시지 송신* 또는 *완료 폴링* 또는 *룰 12 (sentinel 필수)* 를 안내한 모든 경우. **즉흥적인 sentinel ("DONE", "OK", "끝남") 절대 금지** — 본 파일의 규약 그대로 사용. 안 읽고 진행 시 폴링 무한 stuck 사고 책임.

---

## 왜 sentinel 규약이 필요한가

위임 메시지는 **완료 신호 (sentinel)** 를 반드시 포함해야 한다. 즉흥적인 "DONE" 같은 토큰은 sub-session 이 일반화하면서 다른 토큰으로 출력하기 쉽다 (예: root 가 "DONE-2" 를 지시했는데 sub-session 이 그냥 "DONE" 으로 출력 → 폴링 무한 stuck). 실제로 발생한 사고 기반 규약.

부수 이유:

- cmux send 로는 sub-session 이 root 의 *현재 대화 turn 에 끼어드는 알림* 을 보낼 수 없다 (cmux send 는 root 의 terminal stdin 에 텍스트만 쓸 뿐). root 가 폴링하는 게 표준.
- 폴링이 실패하면 root 는 영원히 대기 → 사용자 작업이 막힘. sentinel + timeout + baseline 캡처 (또는 파일 기반) 은 이 실패 모드를 차단하는 안전장치.

---

## 방식 A — 파일 기반 sentinel (권장, 가장 견고)

화면 출력 기반은 (a) 위임 메시지 본문에 sentinel 토큰이 포함돼 grep 이 *자기 자신*을 매칭하는 false-positive, (b) TUI redraw 가 sentinel 라인을 잠깐 흩뜨려 매칭 누락, (c) ASCII 박스 렌더링이 토큰을 짤라먹는 문제가 모두 가능하다. 파일 기반은 이 셋을 한 번에 차단한다.

### Sentinel 규약 (파일)

- task-slug 는 작업당 unique (예: `figma-fix-1`, `mic-pulse`, `tts-scroll`)
- sentinel 파일: `/tmp/cmux-done-<task-slug>` (작업 시작 전 root 가 기존 파일 삭제: `rm -f /tmp/cmux-done-<slug>`)
- 결과 파일: `/tmp/cmux-result-<task-slug>.md` (sub-session 이 결과를 markdown 으로 직접 기록)
- 위임 메시지에 다음 문장을 **원문 그대로** 포함:
  > "작업이 완료되면 다음 두 가지를 차례로 실행하세요:
  > 1. 결과 요약을 `/tmp/cmux-result-<task-slug>.md` 에 markdown 으로 작성 (변경 파일 / 변경 요약 / 검증 결과 섹션 포함)
  > 2. `touch /tmp/cmux-done-<task-slug>` 를 실행해서 완료 신호 전송"

### 폴링 규약 (파일)

```bash
rm -f /tmp/cmux-done-<slug>   # baseline 보장: 송신 전 삭제
# ... cmux send 로 위임 메시지 발사 ...
bash -c '
  deadline=$((SECONDS + 900))   # 상한 15분
  until [ -f /tmp/cmux-done-<slug> ]; do
    if [ $SECONDS -ge $deadline ]; then echo "TIMEOUT after 900s"; exit 124; fi
    sleep 15
  done
  echo "DONE"
'
# 완료 후 결과 추출
cat /tmp/cmux-result-<slug>.md
```

### 왜 `timeout` 명령을 안 쓰는가

GNU `timeout` 은 macOS 기본 환경에 없다 (BSD 미포함). `brew install coreutils` 로 `gtimeout` 설치는 가능하지만 모든 머신에서 보장 못 함. 위 패턴은 bash 내장 `SECONDS` (subshell 시작부터의 경과 초) 만 사용해서 **모든 POSIX 환경에서 동작**.

---

## 방식 B — 화면 출력 sentinel (fallback, 단순 작업만)

sub-session 이 파일시스템 접근을 거부하는 환경이거나 1줄짜리 micro task 등에는 화면 기반도 가능하지만, **false-positive 우회를 반드시 적용**해야 한다.

### Sentinel 규약 (화면)

- 형식: `<<<DONE:<task-slug>>>>` (fixed-string, 정규식 메타 없음)
- 위임 메시지에 sentinel 을 원문 인용할 때는 **분리 표기**로 false-positive 차단:
  > "작업이 끝나면 마지막 줄에 다음 토큰을 그대로 합쳐서 출력하세요: `<<<` + `DONE:<task-slug>` + `>>>`"

  이렇게 적으면 위임 메시지 본문에는 완전한 sentinel 이 안 생기고, sub-session 이 합쳐서 출력할 때만 매칭됨.

### 폴링 규약 (화면)

- 위임 송신 *전* 에 baseline count 캡처 (split 표기를 안 쓴 경우 1, 쓴 경우 0):
  ```bash
  baseline=$(cmux read-screen --surface <ref> --scrollback --lines 500 | grep -cF "<<<DONE:<slug>>>>")
  # ... cmux send 로 위임 발사 ...
  bash -c "
    deadline=\$((SECONDS + 900))
    until [ \$(cmux read-screen --surface <ref> --scrollback --lines 500 | grep -cF '<<<DONE:<slug>>>>') -gt $baseline ]; do
      if [ \$SECONDS -ge \$deadline ]; then echo 'TIMEOUT after 900s'; exit 124; fi
      sleep 15
    done
    echo 'DONE'
  "
  ```
- scrollback 포함이 필수 (화면이 스크롤돼서 baseline 라인이 사라지면 count 가 감소해 false-positive 발생)
- TUI redraw 로 count 가 fluctuate 가능 — `-gt baseline` 조건이 잠시 만족됐다가 다시 떨어질 수 있음. 폴링 종료 후 read-screen 으로 실제 결과 존재 여부 사람이 검증.

---

## 공통: 타임아웃 처리

- **bash 내장 `SECONDS` 기반 패턴 강제** — GNU `timeout` / `gtimeout` 명령에 의존 금지 (macOS BSD 환경에 없음). `bash -c 'deadline=$((SECONDS+N)); until <cond>; do [ $SECONDS -ge $deadline ] && exit 124; sleep 15; done'` 형태가 표준.
- 상한: 일반 작업 600초(10분), 긴 분석/리팩토링 1800초(30분). `sleep` 은 10~15초 (너무 짧으면 토큰 낭비).
- 타임아웃 exit 124 (또는 `echo TIMEOUT`) 시: 즉시 `cmux read-screen` 으로 마지막 화면 + (방식 A) `ls /tmp/cmux-*-<slug>*` 를 사용자에게 보고. 계속 기다릴지 / 중단할지 사용자가 결정.
- `run_in_background: true` 로 띄우되, **시작 시 sentinel 식별자와 예상 소요 시간을 사용자에게 알린다**.
