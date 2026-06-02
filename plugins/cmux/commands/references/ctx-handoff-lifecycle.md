# cmux ctx 40% 자동 handoff 라이프사이클 (필수 Read 자료)

> **언제 이 파일을 Read 하나**: 메인 `cmux-workspace` 가 *룰 17 (매 turn 시작 ctx 측정)* 을 안내한 모든 경우. 매 turn 시작 시 측정 절차 + 임계값 도달 시 처리는 본 파일이 기준. 안 읽고 즉흥 처리 시 false-positive / 사고 시점 손실 가능.

---

## 룰 17 전체 — 매 turn 시작 ctx 측정 + 40% 자동 handoff

사용자 요청 (사용자 doobie3141@gmail.com / 2026-06-02 결정). 룰 13 의 위임-직전 80% 경고와 별개의 *상시 모니터링 layer*.

### 트리거 조건

- **체크 시점**: 매 turn 시작 시 (사용자 prompt 수신 직후, 다른 도구 호출 이전).
- **임계값**: 40% 초과 (`>=40`).
- **False-positive 차단**: 같은 세션에서 *2 turn 연속* 40% 초과 시에만 발동. TUI redraw fluctuation / 짧은 spike 차단.
- **Cooldown**: 한 세션에 대해 자동 handoff trigger 후 1시간 (또는 새 /clear 가 실제 발생할 때까지) 중복 발동 금지.

### 측정 절차

1. `cmux tree --all` 로 워크스페이스 내 모든 terminal surface 식별 (자기 자신 제외 — 단 root self 항목은 별도 처리).
2. 각 surface 에 `cmux read-screen --surface <ref> --lines 50` → `grep -oE 'ctx[: ]*[0-9]+%' | head -1 | grep -oE '[0-9]+'` 로 ctx 값 추출. 미감지면 *조용히 skip* (false alarm 차단).
3. 추출된 값을 `/tmp/cmux-ctx-history-<surface_ref>.log` 에 한 줄씩 append (`<unix_timestamp> <ctx_pct>`). 직전 turn 값과 비교해서 *2 turn 연속 40% 초과* 판정.

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

- ctx 게이지 화면 파싱 fragile — TUI layout 변경 시 정규식 깨질 수 있음. 미감지 = 안전한 skip.
- Root self-측정은 본 turn 의 응답이 누적되기 *전* 시점이라 정확도 보장 어려움. 부드러운 알림 수준 유지.
- `/tmp/cmux-ctx-history-*` 로그는 디스크 누적 — 주기적 정리 필요 (별도 cron / 또는 매 알림 시 1주 이상 된 로그 자동 삭제).
