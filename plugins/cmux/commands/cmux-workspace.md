---
allowed-tools: Bash(cmux *)
description: cmux 워크스페이스의 모든 surface를 관찰하고, 상태를 요약하고, 다른 세션에 메시지를 전송하고, 브라우저로 URL을 열어 테스트하고, 서버를 실행하고, 도메인별 작업을 해당 세션에 위임하는 스킬. "세션 상태", "워크스페이스 확인", "서버 상태", "다른 세션에 전달", "surface 확인", "브라우저로 열어줘", "서버 띄워줘", "백엔드 실행", "프론트 실행", "서버 로그", "서버 시작", "서버 중지", "분석해줘", "코드 봐줘", "기능 알고싶어", "흐름 보여줘", "어떻게 동작해", "리팩토링", "엔진/백엔드/프론트 작업" 등의 요청 시 트리거. **모든 서브프로젝트 도메인 작업은 해당 세션에 위임 (root 직접 처리 금지 — 단순 운영 명령 예외)**.
argument-hint: [status|send <surface> <msg>|read <surface>|tree|browse <url>]
---

# cmux 워크스페이스 관리

루트 세션에서 cmux 워크스페이스 내 모든 surface를 관찰하고 오케스트레이션하는 스킬.
여러 세션의 작업 상태를 한 곳에서 파악하고, 메시지 전송, 브라우저 테스트, 서버 실행까지 가능.

---

## ⚠️ references/ 안내 — 필수 Read 자료 (안 읽고 진행 시 사고 책임)

본 메인 파일은 *진입점 + summary* 만 담는다. 절차 / 규약 / 예외 / 근거는 모두 `references/` 의 5개 파일에 정리. **상황별로 *반드시* 해당 reference 를 Read 한 후 진행**:

| 상황 | 필수 Read 파일 |
|---|---|
| 도메인 작업 위임 결정 / root inline 판단 / 위임 메시지 송신 | `references/delegation-patterns.md` |
| 위임 메시지 작성 / sentinel 형식 / 완료 폴링 | `references/sentinel-polling.md` |
| 디버깅 사고 처리 / errors 문서 작성 / 위치 결정 | `references/error-documentation.md` |
| ctx 40% handoff 경고(`⚠️ [cmux 룰 17]`) 수신 시 대응 처리 (측정은 훅 자동) | `references/ctx-handoff-lifecycle.md` |
| 중요 규칙 17개 상세 / 룰 12, 13, 17 등의 정확한 절차 | `references/rules.md` |

**즉흥 처리 금지** — "Sentinel 이야 그냥 'DONE' 쓰지 뭐", "위임 안 하고 root 가 직접 grep 하면 빠르지" 같은 본능적 판단은 사고를 부른다. 위 reference 가 그 사고들의 *결과로* 작성된 규약.

---

## cmux 계층 구조

```
Window → Workspace (사이드바 항목) → Pane (분할 영역) → Surface (탭)
```

## 핵심 cmux 명령어

```bash
# 워크스페이스 & Surface
cmux tree --all                              # 전체 트리 구조
cmux identify                               # 현재 위치
cmux read-screen --surface <ref>             # surface 화면 읽기
cmux read-screen --surface <ref> --scrollback --lines 200  # 스크롤백 포함
cmux send --surface <ref> "텍스트"           # surface에 텍스트 전송
cmux send-key --surface <ref> enter          # 키 입력 전송 (키 이름은 lowercase: enter / ctrl+c / esc / tab / space)
cmux list-workspaces                         # 워크스페이스 목록
cmux new-surface --pane <ref> --workspace <ref>  # 새 surface(탭) 생성
cmux rename-tab --surface <ref> "이름"       # 탭 이름 변경
cmux close-surface --surface <ref>           # surface 닫기

# 브라우저 자동화 (agent-browser — 외부 헤드리스 데몬)
agent-browser open <url>          # 1. 페이지 열기 (--headed 로 창 표시)
agent-browser snapshot -i         # 2. 상호작용 요소 + @eN ref 확인
agent-browser click @e3           # 3. ref로 조작 (페이지 바뀌면 재-snapshot)
agent-browser screenshot /tmp/ss.png   # 보고용 스크린샷
agent-browser close               # 작업 끝나면 데몬 정리
# 전체 레퍼런스(find/wait/auth/network/tab/session): agent-browser skills get core --full
```

---

## 동작 모드

### $ARGUMENTS가 없거나 "status" — 전체 상태 조회

1. `cmux identify`로 자기 자신의 surface 확인
2. `cmux tree --all`로 전체 구조 파악
3. 현재 워크스페이스의 모든 terminal surface를 식별 (자기 자신 제외)
4. 각 surface에 `cmux read-screen --surface <ref>` 실행
5. 각 surface 상태를 분석하여 요약

출력 형식:

```
## 워크스페이스: {workspace_name}

### 📍 {surface_name} (surface:{ref})
상태: {현재 상태 분석}
요약: {화면 내용 기반 요약}

---
마지막 확인: {현재 시각}
```

### "tree" — 트리만 표시

`cmux tree --all` 결과를 그대로 표시.

### "send <surface_name> <message>" — 메시지 전송

1. `cmux tree --all`로 surface 찾기 (이름 부분 일치)
2. 사용자에게 대상과 메시지를 확인받기
3. `cmux send --surface <ref> "<message>"` 실행
4. 필요 시 `cmux send-key --surface <ref> "Enter"`

### "read <surface_name>" — 특정 surface 읽기

1. `cmux tree --all`로 surface 찾기
2. `cmux read-screen --surface <ref>` 실행 (필요 시 `--scrollback --lines 200`)
3. 화면 내용을 AI가 분석하여 요약

### "browse <url>" — URL 열어 확인

외부 **agent-browser**(헤드리스)로 연다. cmux 워크스페이스를 건드리지 않으므로 창 관리 불필요.
명령을 실행하기 전 처음 1회 `agent-browser skills get core --full` 로 최신 사용법 확인 권장.

1. `agent-browser open <url>` — 사용자가 "창 띄워"/"보면서 할래" 라고 하면 `--headed` 추가
2. `agent-browser snapshot -i` 로 내용(상호작용 요소 + @eN ref) 읽기
3. 필요 시 `agent-browser screenshot /tmp/<name>.png` 로 사용자에게 보고
4. 추가 조작이 필요하면 ref로 (`agent-browser click @e3` → 페이지 바뀌면 재-snapshot)
5. 읽기/조작 완료 후 `agent-browser close` 로 데몬·Chrome 정리

> 헤드리스라 닫을 "창"이 없으므로 예전의 "창을 닫을까요?" 확인 단계는 없음 — `close` 는 백그라운드 데몬 정리용.

### 서버 실행 — 사용자가 "서버 띄워줘", "백엔드 실행", "프론트 실행" 등을 요청할 때

사용자의 요청에서 무엇을 실행할지 판단한 후 아래 순서로 진행:

1. **cmux identify로 현재 위치 확인** (현재 pane과 workspace를 알아야 surface를 만들 수 있음)
2. **cmux tree로 이미 실행 중인 로그 surface가 있는지 확인** — 같은 이름의 surface가 있으면 재사용 (중복 생성 방지)
3. **새 surface 생성** — 루트 세션과 같은 pane에 탭으로 추가:
   ```bash
   cmux new-surface --pane <현재_pane_ref> --workspace <현재_workspace_ref>
   ```
4. **탭 이름 변경** — 용도를 알 수 있도록:
   ```bash
   cmux rename-tab --surface <새_surface_ref> "<이름>"
   ```
   이름 규칙: `{프로젝트}-{역할}-log` (예: `voice-back-log`, `voice-web-log`)
5. **경로 이동 + 서버 실행** — 해당 surface에 명령 전송:
   ```bash
   cmux send --surface <새_surface_ref> "cd <경로> && <실행 명령>"
   cmux send-key --surface <새_surface_ref> "Enter"
   ```
6. **사용자에게 결과 보고** — "surface:XX에서 서버가 시작되었습니다. 로그를 확인하려면 탭을 전환하세요."

#### 실행할 명령은 프로젝트 구조를 먼저 파악해서 결정

서버 실행 명령은 프로젝트마다 다르므로, 프로젝트 디렉토리를 먼저 확인한다:
- `package.json`이 있으면 → Node.js 프로젝트 (`pnpm dev`, `npm run dev` 등)
- `pyproject.toml`이 있으면 → Python 프로젝트 (`uv run uvicorn ...` 등)
- `docker-compose.yml`이 있으면 → Docker 필요 여부 확인
- 확신이 없으면 사용자에게 실행 명령을 물어보기

#### 서버 중지

사용자가 "서버 중지", "서버 꺼줘" 등을 요청하면:
1. 로그 surface를 찾기 (이름으로 매칭)
2. `cmux send-key --surface <ref> ctrl+c` 로 Ctrl+C 전송 (키 이름은 lowercase 가 정식 — `C-c` 는 invalid)
3. **30초 내 종료 안 되면 강제 종료 폴백** — `lsof -ti:<port> | xargs kill -9` 로 포트 점유 좀비 프로세스 정리. 흔한 케이스: `uvicorn --reload` 가 WebSocket / async resource 종료 지연으로 hung, `pnpm dev` 가 파일 watcher 락 유지, Spring Boot devtools 가 클래스로더 미정리 등.
4. 폴백을 실제로 발동했다면 해당 서브프로젝트의 `errors/` 에 사고 기록 (룰 10 / 13 참조 — 절차는 `references/error-documentation.md` **필수 Read**).
5. 필요 시 surface를 닫기: `cmux close-surface --surface <ref>`

### 도메인 작업 위임 — *큰 작업* 한정 / 단순 운영은 root inline

> **위임 송신 *전* `references/delegation-patterns.md` + `references/sentinel-polling.md` 필수 Read.** 안 읽고 즉흥 위임 시 sentinel 누락 / 차단 문구 누락 / quoting 사고 책임.

핵심 한 줄 요약:

- 큰 작업 (5+ 파일 grep / 3+ 파일 변경 / 디버깅 / 복합 흐름) → **위임**
- 단순 운영 (1줄 patch / git push|pull / 파일 1개 read / 단순 cmux 운영 / `~/.claude` 작업) → **root inline**
- 판단 기준: *round-trip 비용 (메시지 작성 1~2분 + sentinel 폴링 평균 3분)* 이 *세션 메모리 누적 가치* 보다 큰가? → 답이 *비용 > 가치* 면 inline
- 의도 모호 시 사용자 확인 우선

위임 절차 7단계 / root inline 예외 케이스 분류 / 위임 메시지 표준 템플릿 / 메타 메시지 + 파일 경로 패턴 / 세션 간 병렬 위임 → 전부 `references/delegation-patterns.md` 에 있음. **위임 결정 시 본 reference 가 1순위 진입점**.

### 멀티 세션 디버깅 + 에러 문서화

> **디버깅 시 `references/error-documentation.md` 필수 Read.** errors 위치 판단 (모노레포 룰) / frontmatter 8필드 표준 / 본문 5섹션 구조 모두 거기 있음.

핵심 한 줄 요약:

- 디버깅도 도메인 위임 정책 적용 — 해당 세션에 위임
- 사고 해결 후 *반드시* `errors/NN-*.md` 기록 (룰 10)
- 모노레포면 *해당 서브프로젝트의 errors/* (루트 errors/ 가 아님)
- 작업 지시 전 *관련 errors 사전 확인* + 위임 메시지에 포함 (룰 11)

---

## 중요 규칙 — 17개 summary (상세는 references/rules.md 필수 Read)

각 룰의 *상세 절차 / 예외 / 근거* 가 필요한 모든 상황에서 **`references/rules.md` Read 후 적용**. 메인의 한 줄 만 보고 행동하면 사고 위험.

0. **도메인 작업은 무조건 위임 — 단 *단순 운영 명령* 은 root inline 우선** (큰 작업에 한해 효율성보다 우선). 분류 기준 → `references/delegation-patterns.md`.
1. **자기 자신 제외** — `cmux identify` 로 확인 후 상태 조회 시 제외.
2. **이름으로 매칭** — surface ref 보다 이름. 부분 일치 허용.
3. **전송 전 확인** — `send` 모드는 반드시 사용자 확인 후 전송.
4. **에러 감지** — 화면의 에러/traceback/실패 메시지는 강조 알림.
5. **Claude 세션 감지** — Claude Code 관련 내용 보이면 진행 작업/진행률 분석.
6. **브라우저는 agent-browser (외부 헤드리스)** — cmux 워크스페이스 안 건드림. 기본 헤드리스, 관전 시 `--headed`, 작업 후 `agent-browser close`.
7. **입력 대기 감지** — 프롬프트/선택지 보이면 "사용자 입력 대기" 알림.
8. **서버 surface 중복 방지** — 같은 이름 surface 있으면 재사용.
9. **서버 실행 명령 불확실 시 물어보기** — 자의 판단 금지.
10. **디버깅 결과는 에러 문서로 남기기** — root 직접 처리 사고도 포함. 절차 → `references/error-documentation.md`.
11. **작업 지시 전 관련 `errors/` 문서 확인** — 작업 대상 + 루트 errors 둘 다 확인 + 위임 메시지에 포함.
12. **위임 sentinel + 폴링 timeout 필수** ⚠️ — 즉흥 sentinel ("DONE", "OK") **절대 금지**. 작업 직전 `references/sentinel-polling.md` **필수 Read**.
13. **Sub-session 컨텍스트 게이지 확인 (위임 직전, 80% 경고)** — 룰 17 과 별개 layer. 80% 초과 시 사용자 경고.
14. **동시 위임 금지 (같은 세션 한정)** — 서로 다른 세션엔 병렬이 기본. 절차 → `references/delegation-patterns.md` 의 "세션 간 병렬 위임".
15. **TUI 자동완성 ghost text 오인 금지** — `-- INSERT --` 표시 + `cmux send-key backspace` 로 판정. 상세 → `references/rules.md`.
16. **긴 메시지 `cmux send` paste expansion / timeout 처리** — timeout 직후 `read-screen` 으로 실제 입력 상태 우선 확인. 상세 → `references/rules.md`.
17. **ctx 40% 자동 handoff 라이프사이클** ⚠️ — **측정은 `hooks/measure-ctx.sh`(UserPromptSubmit 훅)가 자동 수행** (에이전트 직접 측정 금지). 훅이 2연속 40%↑ 감지 시 컨텍스트에 `⚠️ [cmux 룰 17] ... handoff 검토 권장` 경고 주입. **이 경고가 보일 때만** `references/ctx-handoff-lifecycle.md` Read 후 대응. Sub: 반자동 (사용자 OK 후 자동 handoff → /clear → 재개). Root self: 부드러운 한 줄 알림 (사용자가 /clear 직접 입력).
18. **사용자 의견 필요 시 AskUserQuestion tool 강제 사용** ⚠️ — 보고 중 *결정/선택지/옵션 비교* 가 필요하면 자연어 표 ("A/B/C 중 어떻게 가시겠어요?") 대신 **반드시 AskUserQuestion tool 호출**. 사용자 doobie3141@gmail.com 명시 요청 (2026-06-02). 자연어 옵션 나열은 사용자 응답 부담 ↑ + 의도 모호. AskUserQuestion 이 선택 UI 제공해 빠른 결정. **자세한 발동 조건 / 예외 / 형식은 `references/rules.md` 의 룰 18 절 필수 Read**.
