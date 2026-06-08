# cmux ctx 40% 자동 handoff 라이프사이클 (필수 Read 자료)

> **언제 이 파일을 Read 하나**: 컨텍스트에 `⚠️ [cmux 룰 17] ... handoff 검토 권장` 경고가 나타난 경우. **측정은 더 이상 에이전트가 직접 하지 않는다** — `hooks/measure-ctx.sh`(UserPromptSubmit 훅)가 자동 수행한다. 본 파일은 *경고를 받았을 때의 대응 절차* 기준. 안 읽고 즉흥 처리 시 false-positive / 사고 시점 손실 가능.

---

## 룰 17 전체 — 훅 자동 측정 + 경고 수신 시 40% 자동 handoff 대응

사용자 요청 (사용자 doobie3141@gmail.com / 2026-06-02 결정). 룰 13 의 위임-직전 80% 경고와 별개의 *상시 모니터링 layer*.

**역할 분담** (2026-06-08 제어 역전):
- **측정/기록/판정 = 훅** (`hooks/measure-ctx.sh`, UserPromptSubmit). 매 prompt 마다 harness 가 강제 실행 → 에이전트 누락 불가.
- **대응 = 에이전트** (본 파일). 훅이 stdout 으로 주입한 경고를 보고 handoff 절차 수행.

### 측정은 훅이 한다 (에이전트 직접 측정 금지)

`measure-ctx.sh` 가 매 prompt 마다 자동으로:

1. `cmux tree --all` 로 모든 terminal surface 식별.
2. 각 surface 의 `cmux read-screen` 에서 `ctx[: ]*[0-9]+%` 추출 (미감지 = 조용히 skip).
3. `/tmp/cmux-ctx-history-<surface_ref>.log` 에 `<unix_timestamp> <ctx_pct>` append + trim.
4. *직전 2개 측정 모두 ≥40% + 1h 쿨다운* 경과 시 stdout 으로 경고 주입:
   `⚠️ [cmux 룰 17] surface:N ctx N% (2연속 40%↑) — handoff 검토 권장`

→ **에이전트는 위 측정을 다시 수행하지 않는다.** 컨텍스트에 위 경고가 보이면 곧장 아래 *대응 절차*로 진행. 경고가 없으면 룰 17 관련 행동 불필요.

### 트리거 조건 (훅이 판정, 참고용)

- **체크 시점**: 매 prompt (UserPromptSubmit 훅 = harness 강제 실행).
- **임계값**: 40% 이상 (`>=40`).
- **False-positive 차단**: 같은 세션에서 *직전 2개 측정 연속* 40%↑ 시에만 발동. TUI redraw fluctuation / 짧은 spike 차단. ctx 미감지 surface 는 skip.
- **Cooldown**: 한 세션에 대해 경고 발동 후 1시간 (`/tmp/cmux-ctx-cooldown-<safe>` mtime 기준) 중복 발동 금지.

### Sub-session 분기 (반자동)

트리거 시 root 가 다음 순서로 진행:

1. 사용자에게 한 화면 알림: "⚠️ <session_name> ctx <pct>% (2 turn 연속). 자동 handoff + /clear 진행해도 될까요?"
2. 사용자 OK 응답 시:
   - 해당 세션에 `cmux send` 로 handoff 작성 지시 송신 (목적·현재 진행 상황·다음 액션 포함하는 markdown 을 `/tmp/cmux-handoff-<surface_ref>-<timestamp>.md` 에 작성 후 `touch /tmp/cmux-handoff-done-<surface_ref>` sentinel).
   - sentinel 대기 (상한 5분).
   - sentinel 잡히면 `cmux send '/clear'` + `cmux send-key enter` 로 clear 발화.
   - 5초 대기 후 `cmux read-screen` 으로 빈 prompt 확인.
   - 재개 prompt 송신: `cmux send "이전 세션의 handoff 가 /tmp/cmux-handoff-<surface_ref>-<timestamp>.md 에 있다. Read 도구로 읽고 그 안의 다음 액션부터 작업 재개해라."` + enter.
   - cooldown 시작.
3. 사용자 NO/스킵 응답 시: 그 세션에 대한 cooldown 만 시작 (사용자가 다시 묻지 않게).

### Root 자신 분기 (부드러운 알림)

Root 는 self-`/clear` 불가능. 트리거 시:

1. 본 turn 의 응답 *맨 위* 에 한 줄: "⚠️ root ctx <pct>% (2 turn 연속). 필요 시 handoff 파일 작성해드릴까요? 그 후 `/clear` 입력 → 새 세션에서 handoff 파일 읽고 재개."
2. 사용자가 OK 하면 root 가 직접 handoff 작성 (`/tmp/cmux-handoff-root-<timestamp>.md`). 이후 사용자 액션 (사용자가 직접 `/clear` 입력).
3. 본 turn 의 작업은 *현재 turn 안에서 완결되는 것까지만* 진행. 새 위임 송신 / 큰 분석 시작 금지.
4. cooldown 시작 (사용자가 매 turn 같은 알림 받지 않게).

### 동작 정책

- **각 세션에 대해 독립적으로 동작** — 한 sub-session 이 cooldown 중이어도 다른 sub-session 은 정상 측정/트리거.
- **알림 우선순위**: ctx 알림은 *작업 시작 전* 단계라 본 turn 의 다른 작업보다 *먼저* 사용자에게 표시. 다른 분석/위임은 사용자 OK/NO 응답 받은 뒤 진행.

### 본 룰의 한계

- **훅은 세션 START 에 로드** — 플러그인(마켓플레이스/캐시)을 고쳐도 *현재 실행 중인 세션엔 미적용*. 적용은 다음 새 세션부터. 룰 변경은 한 박자 늦게 반영됨을 전제.
- ctx 게이지 화면 파싱 fragile — TUI layout 변경 시 정규식 깨질 수 있음. 미감지 = 안전한 skip (훅이 처리).
- Root self 도 훅이 측정하지만, 본 turn 의 응답이 누적되기 *전* 시점이라 정확도 보장 어려움. 부드러운 알림 수준 유지.
- `/tmp/cmux-ctx-history-*` 로그는 훅이 마지막 ~50줄로 trim 하므로 무한 누적은 아님. `/tmp/cmux-ctx-cooldown-*` 파일은 1h 쿨다운 마커.
- 측정 자체 디버깅이 필요하면 훅을 직접 실행: `CMUX_CTX_THRESHOLD=4 ${CLAUDE_PLUGIN_ROOT}/hooks/measure-ctx.sh` (env 로 임계값/쿨다운 오버라이드 가능).
