# cmux 중요 규칙 17개 — 상세 (필수 Read 자료)

> **언제 이 파일을 Read 하나**: 메인 `cmux-workspace` 의 "중요 규칙" 섹션은 *한 줄 summary* 만 — 상세 절차/예외/근거가 필요한 모든 경우 본 파일을 Read. 특히 룰 12 (sentinel), 룰 13 (위임-직전 80% 경고), 룰 17 (ctx 40% handoff — 측정은 훅 자동, 경고 수신 시 대응) 은 *작업 직전* 반드시 Read.

---

## 0. 도메인 작업은 무조건 위임 — 단 *단순 운영 명령* 은 root inline 우선

서브프로젝트 도메인 (engine/back/front 등) 작업은 root 가 직접 처리하지 않고 해당 세션에 `cmux send` 로 위임. 분석·탐색·디버깅·변경 모두 해당.

**단 예외**: 1줄 patch / 단순 `git push` / 단순 `git pull` / 파일 1개 read / 단일 명령 실행 같은 *round-trip 비용 (위임 메시지 작성 1~2분 + sentinel 폴링 평균 3분) > 도메인 메모리 누적 가치* 인 작업은 root inline 처리.

자세한 분류 기준은 `references/delegation-patterns.md` 의 "효율성 함정 경고 + root inline 예외" 섹션 **필수 Read**.

**이 규칙은 *큰* 도메인 작업에 한해 효율성보다 우선**.

## 1. 자기 자신 제외

`cmux identify`로 현재 surface 확인, 상태 조회 시 제외.

## 2. 이름으로 매칭

surface ref보다 이름으로 찾기. 부분 일치 허용.

## 3. 전송 전 확인

`send` 모드에서는 반드시 사용자 확인 후 전송.

## 4. 에러 감지

화면에 에러, traceback, 실패 메시지가 보이면 강조하여 알림.

## 5. Claude 세션 감지

Claude Code 관련 내용이 보이면 진행 중인 작업과 진행률 분석.

## 6. 브라우저는 새 창

`cmux new-window`로 별도 창에서 열기. 현재 작업 공간 보호.

## 7. 입력 대기 감지

surface에 프롬프트나 선택지가 보이면 "사용자 입력을 기다리고 있습니다" 알림.

## 8. 서버 surface 중복 방지

서버 실행 전 같은 이름의 surface가 이미 있으면 재사용.

## 9. 서버 실행 명령 불확실 시 물어보기

프로젝트 구조로 판단이 안 되면 사용자에게 확인.

## 10. 디버깅 결과는 에러 문서로 남기기

다른 세션에 문제를 전달하고 해결한 경우, **또는 root 가 직접 해결한 운영/인프라 사고** (예: 좀비 프로세스 `kill -9` 폴백, 포트 충돌, 의존성 충돌 등) 도 모두 **작업이 속한 서브프로젝트의** `errors/NN-slug.md` 에 독립 파일로 정리 (모노레포면 루트가 아닌 서브프로젝트 쪽). 한 번 해결된 문제도 지식으로 축적.

위치 판단 규칙은 `references/error-documentation.md` 의 5번 항목 참조 **필수 Read**.

*root 가 직접 처리한 사고가 가장 자주 누락된다* — 다른 세션에 위임하지 않았다는 이유로 기록을 빠뜨리지 말 것.

## 11. 작업 지시 전 관련 `errors/` 문서 확인

다른 세션에 `cmux send`로 작업을 지시하기 전에, **작업 대상 서브프로젝트의** `errors/` + 루트 `errors/` 둘 다 확인한다. 작업이 건드릴 영역(스키마, 프로토콜, 통합 지점, 설정 값 등)과 관련된 기록이 있으면 해당 `errors/NN-*.md` 경로를 `send` 본문에 포함시켜 전달한다. 재발 방지 루프.

- 해당 위치에 `errors/` 디렉토리가 없거나 비어 있으면 건너뛴다.
- 작업과 관련 없는 에러는 포함하지 않는다 (과다 전달 방지).
- 룰 10 (에러 문서 남기기) 과 한 쌍으로 작동한다: **쓰기(10) ↔ 읽기(11)**.

## 12. 위임 sentinel + 폴링 timeout 필수 ⚠️ 작업 직전 references/sentinel-polling.md 필수 Read

모든 위임은 unique sentinel + timeout 보호. **파일 기반 sentinel (`/tmp/cmux-done-<slug>`) 이 기본 권장**, 화면 기반 (`<<<DONE:<slug>>>>`) 은 fallback. 화면 기반 사용 시 baseline count 캡처 + scrollback 포함 grep 필수 — 즉흥적인 sentinel ("DONE", "끝남", "OK") 금지.

**상세 규약은 `references/sentinel-polling.md` 를 *위임 송신 전* 반드시 Read. 안 읽고 즉흥 sentinel 사용 시 폴링 무한 stuck 사고 책임**.

## 13. Sub-session 컨텍스트 게이지 확인 (위임 직전, 80% 경고)

위임 전 `cmux read-screen` 으로 sub-session 의 ctx 게이지 (`ctx: NN%`) 를 확인한다. 80% 초과 시 사용자에게 경고 ("front 세션 컨텍스트 80% 초과, /clear 또는 작업 분할 권장"). limit 근처에서 큰 위임은 작업 중 truncation 위험.

룰 17 (ctx 40% handoff — 측정은 훅 자동) 과는 *별개의 layer* — 룰 13 은 *위임-직전 위험 경고*(에이전트가 직접 read-screen), 룰 17 은 *훅 기반 상시 모니터링*.

## 14. 동시 위임 금지 (같은 세션 한정)

같은 sub-session 에 한 번에 하나의 작업만. 이전 위임의 sentinel 이 잡힐 때까지 다음 위임 메시지를 보내지 않는다. 동시 송신 시 메시지가 섞여서 들어가거나 첫 작업의 인터랙티브 입력으로 두 번째 메시지가 흡수되는 사고 발생.

긴급히 인터럽트가 필요하면 `cmux send-key ctrl+c` 로 명시적 취소 후 재위임. **단 서로 다른 세션엔 병렬 위임이 기본** — `references/delegation-patterns.md` 의 "세션 간 병렬 위임" 섹션 참조.

## 15. Claude Code TUI 의 자동완성 ghost text 를 실제 입력으로 오인 금지

`cmux read-screen` 으로 sub-session 의 프롬프트 영역에 텍스트가 보여도 그게 **자동완성 ghost text** (이전 명령 history 미리보기) 일 수 있다. 실제 입력 buffer 는 비어 있는 상태. 구분 방법:

- **`-- INSERT --` 표시가 있으면 실제 입력**. 없거나 다른 상태 표시면 ghost text 가능성 큼.
- ghost text 의 텍스트는 보통 dim(흐릿) 표시지만 `cmux read-screen` 은 색상 정보를 포기하므로 화면 텍스트만으로는 구분 어려움.
- **확실한 판정 방법**: `cmux send-key backspace` 한 번 보내고 다시 `read-screen` → 텍스트가 그대로면 ghost, 한 글자 줄면 실제 입력.
- ghost text 면 `backspace` / `ctrl+u` / `ctrl+c` / `esc` 모두 무의미 (지울 게 없음). 이걸 반복하며 시간 낭비 금지.
- ghost 가 보이는 상태에서 그냥 `cmux send` 로 새 텍스트 보내면 ghost 가 사라지고 새 텍스트가 정상 입력된다 — 별도 클리어 절차 불필요.
- 의심이 1초라도 들면 즉시 사용자에게 한 줄 확인 ("프롬프트의 X 텍스트가 실제 입력인지 ghost text 인지 알려달라"). 키 조합 4~5개 시도하며 추정하는 것보다 훨씬 빠르다.

## 16. 긴 메시지 `cmux send` 의 paste expansion / timeout 처리

1KB 가 넘는 메시지를 `cmux send` 로 보내면 Claude Code TUI 가 "paste expansion" 모드로 진입하면서 `cmux send` 응답이 늦어 **timeout 으로 보이지만 실제 텍스트는 정상 입력된 경우가 많다**. 처리 절차:

1. `cmux send` timeout 직후 **반드시 `cmux read-screen` 으로 실제 입력 상태 먼저 확인**. 화면에 메시지 일부가 보이면 입력 성공.
2. 화면 마지막에 `paste again to expand` 표시가 있으면 Claude Code 가 큰 paste 를 축약 표시 중. 그래도 입력은 들어간 상태. `cmux send-key enter` 만 보내면 submit.
3. 입력이 정말 안 들어갔으면 메시지를 1KB 이내로 줄여서 재시도 (자세한 컨텍스트는 위키 경로 참조로 대체).
4. timeout 만 보고 곧장 같은 메시지를 재전송하면 두 번 입력되어 sub-session 이 혼란 — 반드시 read-screen 으로 1차 시도 결과 확인 후 재시도 여부 결정.

## 17. ctx 40% 자동 handoff 라이프사이클 ⚠️ 측정은 훅 자동 — 경고 수신 시 references/ctx-handoff-lifecycle.md 필수 Read

**측정은 `hooks/measure-ctx.sh`(UserPromptSubmit 훅)가 매 prompt 자동 수행** (2026-06-08 제어 역전 — 에이전트 self-policing 누락 방지). 에이전트는 *직접 측정하지 않는다*. 사용자 요청 (사용자 doobie3141@gmail.com / 2026-06-02 결정). 룰 13 의 위임-직전 80% 경고와 별개의 *상시 모니터링 layer*.

훅이 2연속 40%↑ 감지 시 컨텍스트에 `⚠️ [cmux 룰 17] surface:N ctx N% (2연속 40%↑) — handoff 검토 권장` 를 주입. **이 경고가 보일 때만** `references/ctx-handoff-lifecycle.md` 를 Read 하고 대응 절차(Sub-session 분기 / Root 자신 분기) 수행. 경고 없으면 룰 17 관련 행동 불필요.

### 한 줄 summary

- 측정: 훅 자동 (에이전트 직접 측정 금지) / 트리거: 직전 2개 측정 연속 40%↑
- 대응: 컨텍스트에 `⚠️ [cmux 룰 17]` 경고 보이면 lifecycle Read 후 처리
- Sub-session: 사용자 OK → 자동 handoff → /clear → 재개 prompt (반자동)
- Root self: 부드러운 한 줄 알림 (사용자가 /clear 직접 입력)
- Cooldown: 1시간 / 세션 독립 / 미감지 시 안전 skip

---

## 18. 사용자 의견 필요 시 AskUserQuestion tool 강제 사용 ⚠️

사용자 요청 (사용자 doobie3141@gmail.com / 2026-06-02 결정). cmux 스킬 동작 중 보고/응답에 *사용자 의견/결정/선택지 비교* 가 들어가면 자연어 표가 아니라 **AskUserQuestion tool 호출**.

### 발동 조건 (모두 충족 시 AskUserQuestion 사용)

1. **결정/선택지** 가 보고 안에 있음 — 예: "옵션 A 폐기 vs B commit vs C 리팩토", "단순 push vs rebase vs feature 브랜치"
2. **사용자 응답 없이 진행 불가** — root 가 임의로 선택하면 사고/낭비 위험
3. **옵션 ≤ 4개** — AskUserQuestion 은 한 질문당 최대 4 옵션
4. **질문 ≤ 4개** — 한 번에 최대 4 질문 묶음

### 예외 — 자연어 보고 그대로 OK

- **단순 완료 보고**: commit hash + 변경 요약 + "다음 단계?" 정도. 결정 옵션이 없음
- **사용자가 다음 액션 명시 후 진행 보고**: "push 해줘" → 진행 후 결과 보고
- **옵션이 1개 (선택의 여지 없음)**: "이대로 가시면 됩니다" 같은 단일 path
- **사고/에러 알림만**: 사용자가 인지해야 하는 사실만 전달, 결정 요구 없음
- **opinion-free 분석 보고**: 사실만 정리, 사용자가 다음 액션 자유 결정

### AskUserQuestion 형식 표준

- `question`: 결정 사항 + 영향 명시 ("이 결정이 X 에 영향" 한 줄 포함)
- `header`: 12자 이내 짧은 라벨 (예: "Push 방식")
- `options`: 2~4개. 첫 번째에 **권고안 + "(Recommended)" 표기**. 각 옵션의 `description` 에 *trade-off* 간단 명시
- `multiSelect`: 기본 false. 비배타적 선택일 때만 true (예: "어떤 기능을 활성화하시겠어요?")

### 발동 시 행동 흐름

1. 보고 본문에서 결정 사항 식별
2. 옵션 ≤ 4개로 정리 + 권고안 결정
3. AskUserQuestion tool 호출 — 다른 자연어 진행 안내 *없이*
4. 사용자 응답 수신 후 *바로* 그 결정에 맞는 작업 진행 (다시 확인 묻지 않음)

### 안티패턴 (금지)

- 자연어 표 ("| A | B | C | … | 어느 옵션으로 갈까요?") 만 보고 종료
- 옵션이 5개 이상이면 그대로 AskUserQuestion 에 넣기 (이때는 *우선순위* 상위 3~4개로 압축 후 사용)
- 단일 path 인데 형식상 AskUserQuestion 호출 (불필요한 한 turn 추가)
- AskUserQuestion 응답 받은 직후 다시 "이대로 진행할까요?" 재확인 (이중 확인)

### 본 룰의 한계

- AskUserQuestion 이 *플랫폼 지원* 에 의존. 일부 환경에서 미지원이면 자연어 옵션 표로 fallback
- 사용자가 "Other" 선택지 입력으로 4개 외 답변 가능 — 이때는 자연어 응답 그대로 처리
