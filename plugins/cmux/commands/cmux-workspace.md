---
allowed-tools: Bash(cmux *)
description: cmux 워크스페이스의 모든 surface를 관찰하고, 상태를 요약하고, 다른 세션에 메시지를 전송하고, 브라우저로 URL을 열어 테스트하고, 서버를 실행하고, 도메인별 작업을 해당 세션에 위임하는 스킬. "세션 상태", "워크스페이스 확인", "서버 상태", "다른 세션에 전달", "surface 확인", "브라우저로 열어줘", "서버 띄워줘", "백엔드 실행", "프론트 실행", "서버 로그", "서버 시작", "서버 중지", "분석해줘", "코드 봐줘", "기능 알고싶어", "흐름 보여줘", "어떻게 동작해", "리팩토링", "엔진/백엔드/프론트 작업" 등의 요청 시 트리거. **모든 서브프로젝트 도메인 작업은 해당 세션에 위임 (root 직접 처리 금지)**.
argument-hint: [status|send <surface> <msg>|read <surface>|tree|browse <url>]
---

# cmux 워크스페이스 관리

루트 세션에서 cmux 워크스페이스 내 모든 surface를 관찰하고 오케스트레이션하는 스킬.
여러 세션의 작업 상태를 한 곳에서 파악하고, 메시지 전송, 브라우저 테스트, 서버 실행까지 가능.

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
cmux send-key --surface <ref> "Enter"        # 키 입력 전송
cmux list-workspaces                         # 워크스페이스 목록
cmux new-surface --pane <ref> --workspace <ref>  # 새 surface(탭) 생성
cmux rename-tab --surface <ref> "이름"       # 탭 이름 변경
cmux close-surface --surface <ref>           # surface 닫기

# 브라우저 자동화
cmux new-window                              # 새 창 생성
cmux close-window --window <ref>             # 창 닫기
cmux browser open <url>                      # 브라우저 열기
cmux browser --surface <ref> wait --load-state complete  # 로딩 대기
cmux browser --surface <ref> snapshot --compact          # DOM 스냅샷
cmux browser --surface <ref> screenshot --out /tmp/ss.png # 스크린샷
cmux browser --surface <ref> get text "selector"         # 텍스트 추출
cmux browser --surface <ref> click "selector"            # 클릭
cmux browser --surface <ref> type "selector" "text"      # 입력
cmux browser --surface <ref> eval "js코드"               # JS 실행
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

### "browse <url>" — 브라우저에서 URL 열기

**반드시 새 창(window)에서 열기.** 현재 워크스페이스에 열면 작업 공간이 방해됨.

1. `cmux new-window` 로 새 창 생성 (window ref 기록, 예: OK <window-uuid>)
2. 새 창에서 `cmux browser open <url> --window <window-uuid>` 실행 — **반드시 --window 지정!** 생략하면 기존 pane에서 reuse됨
3. `cmux browser <surface> wait --load-state complete` 로 로딩 대기
4. `cmux browser <surface> snapshot --compact` 로 내용 읽기
5. 필요 시 스크린샷: `cmux browser <surface> screenshot --out /tmp/<name>.png`
6. 읽기 완료 후 AskUserQuestion으로 "브라우저 창을 닫을까요?" 확인
7. 닫겠다고 하면 `cmux close-window --window <ref>` 정리

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
2. `cmux send-key --surface <ref> "C-c"` 로 Ctrl+C 전송
3. 필요 시 surface를 닫기: `cmux close-surface --surface <ref>`

### 도메인 작업 위임 정책 (필수 — 모든 도메인 작업)

cmux 워크스페이스에 서브프로젝트별 Claude Code 세션이 떠있는 경우, root 세션은 **그 도메인의 모든 작업** (분석·탐색·디버깅·코드 변경) 을 **반드시 해당 세션에 위임**한다. root 가 직접 답하지 않는다.

이 정책은 아래 "멀티 세션 디버깅" 워크플로 보다 **상위 규칙**. 디버깅은 이 정책의 한 사례.

#### 위임 대상 작업

- ✅ **분석·탐색** — "engine 봐줘", "back 의 X 어떻게 동작해", "front 코드 분석해줘", "기능 카탈로그 만들어줘"
- ✅ **디버깅** — 특정 서브프로젝트의 버그 (멀티 세션 디버깅 워크플로와 결합 진행)
- ✅ **변경 작업** — 특정 서브프로젝트의 코드 수정 / 리팩토링 / 기능 추가
- ✅ **로컬 운영** — 특정 서브프로젝트의 테스트 실행 / 로그 분석

#### 예외 — root 가 직접 처리해도 됨

- 워크스페이스 전체 상태 조회 ("status", "tree", "어디까지 됐어")
- 서버 운영 명령 (서버 실행/중지 — 위 별도 워크플로)
- **크로스커팅 변경** (2개 이상 서브프로젝트 동시 영향: 공통 스키마/프로토콜/배포 파이프라인/인프라 설정)
- 사용자가 명시적으로 "root 에서 직접 해줘" 라고 요청한 경우

#### 대상 세션 판단 기준

1. 메시지에 서브프로젝트 이름 명시 (예: "engine", "back", "front") → 해당 세션
2. 파일 경로가 서브프로젝트 디렉토리 안 → 그 세션
3. 도메인 키워드 (예: "백엔드 API" / "프론트 UI" / "엔진 LLM") → 해당 세션
4. 모호하면 사용자에게 확인 후 진행 (자의로 판단 금지)

#### 위임 절차

1. **대상 세션 확인** — `cmux tree --all` 로 surface ref 찾기
2. **사용자 요청을 구체화** — 단순 전달이 아니라 **목적·기대 결과·제약** 까지 포함한 자기 완결적 지시로 변환
3. **`cmux send` + `send-key Enter`** 로 송신
4. **완료 폴링** — `until cmux read-screen --surface <ref> | grep -qE "<완료 시그널>"; do sleep 3; done` 패턴으로 끝까지 대기
5. **결과 수집** — root 에서 `cmux read-screen` 으로 그 세션의 결과를 가져옴
6. **사용자에게 보고** — root 가 정리해서 최종 응답
7. **코드 변경 동반 시** → 멀티 세션 디버깅 워크플로의 5~8단계 (errors/ 문서화) 까지 진행

#### "효율성 함정" 경고

LLM 의 자연스러운 본능: "단순한 grep 한 번이면 답이 나오는데 굳이 다른 세션 거치는 게 비효율" 이라는 판단이 들기 쉽다. **이 본능을 따르지 말 것**.

사용자가 멀티 세션 구조를 만든 이유는 **효율** 이 아니라 **각 세션의 도메인 컨텍스트 누적**. 단순 grep 도 해당 세션이 하면 그 세션의 메모리·메모/위키에 쌓인다. root 가 가로채면 그 누적이 끊긴다.

판단이 흔들릴 때 기준: **"이 작업이 어느 세션의 메모리에 쌓여야 하는가?"**. 답이 root 가 아니면 무조건 위임.

---

### 멀티 세션 디버깅 + 에러 문서화 워크플로

위 도메인 위임 정책의 **버그/에러 특화 사례**. 사용자가 다른 세션(예: `voice_server`, `voice-web`)에서 발생한 버그/에러에 대해 질문하거나 수정을 요청할 때는 아래 순서를 반드시 따를 것:

1. **대상 세션 판단** — 사용자의 질문 맥락으로 어느 세션에 전달할지 결정 (백엔드 버그는 voice_server, 프론트 버그는 voice-web 등)
2. **필요 시 선행 조사** — 루트 세션에서 직접 읽을 수 있는 파일(로그, 소스 코드)을 먼저 확인해서 문제를 구체화. 가능하면 원인 가설까지 정리
3. **질문/수정 요청을 해당 세션에 전송** — `cmux send` + `send-key Enter`로 구체적인 지시 전달. 증상, 예상 원인, 수정 방향을 명확히 작성
4. **작업 완료 여부 확인** — `cmux read-screen --surface <ref>`로 해당 세션이 답변/수정을 끝냈는지 주기적으로 확인. 여전히 진행 중이면 완료까지 대기
5. **에러 문서 위치 결정 (모노레포 필수)** — 저장소 구조를 먼저 확인:
   - **단일 프로젝트** (루트 바로 아래 소스): `<repo_root>/errors/`
   - **모노레포** (루트 밑에 `engine/`, `web/`, `server/`, `mobile/` 등 서브프로젝트가 병렬): **수정한 코드가 속한 서브프로젝트의 `errors/` 사용**. 예: engine 버그는 `<repo_root>/engine/errors/`, web 버그는 `<repo_root>/web/errors/`
   - **크로스커팅** (2개 이상 서브프로젝트를 동시에 건드림 — 스키마/프로토콜/배포 파이프라인 등): 루트 `<repo_root>/errors/` 사용
   - 판단 기준: "이 지식이 필요한 사람은 누구인가?" — 엔진만 보는 사람이면 engine 내부, 모두가 봐야 하면 루트
6. **에러 문서 작성** — 결정된 디렉토리에 독립 파일로 정리:
   - 디렉토리가 없으면 새로 생성 (`mkdir -p <path>`) + 해당 디렉토리의 `README.md` 신설 (목차 테이블 + 작성 규칙)
   - 파일명: `NN-short-slug.md` (2자리 순번, **해당 디렉토리 내** 기존 중 가장 큰 번호 +1). 다른 디렉토리의 번호와는 독립
   - 섹션: **발생 시점 / 증상(원문 로그 포함) / 원인 / 해결 방법(코드 포함) / 교훈**
   - 한 파일 = 하나의 문제 (몰아넣지 말 것)
7. **목차 업데이트** — 해당 디렉토리의 `README.md` 목차 테이블에 새 항목 추가. 상태 표시(✅ 해결 / 🔄 진행 중) 포함
8. **사용자 보고** — 원인과 해결 내용을 간결히 보고하고, 작성한 에러 문서 경로를 명시 (어느 `errors/` 인지 포함)

**왜 이 워크플로가 필요한가:**
멀티 세션 환경에서는 각 세션이 독립적으로 일하기 때문에, 문제 해결 후 그 맥락이 흩어진다. 루트 세션이 조율자 역할을 하면서 모든 이슈를 한 곳에 영속적으로 남겨야 나중에 참조 가능하다. 사용자는 일회성 해결이 아니라 **지식의 축적**을 원한다.

**에러 문서 템플릿:**

```markdown
# [NN] 제목 — 한 줄 요약

## 발생 시점
YYYY-MM-DD, 어느 단계에서

## 증상
사용자 관점에서 본 현상 + 원문 에러 로그

## 원인
근본 원인 분석 (1차 증상이 아닌 밑바닥 원인)

## 해결 방법
구체적 수정 내용 (수정 전/후 코드 포함)

## 교훈 (선택)
유사 문제 재발 방지를 위한 인사이트
```

---

## 중요 규칙

0. **도메인 작업은 무조건 위임** — 서브프로젝트 도메인 (engine/back/front 등) 작업은 root 가 직접 처리하지 않고 해당 세션에 `cmux send` 로 위임. 분석·탐색·디버깅·변경 모두 해당. 자세한 규칙은 "도메인 작업 위임 정책" 섹션 참조. **이 규칙은 효율성보다 우선**.
1. **자기 자신 제외** — `cmux identify`로 현재 surface 확인, 상태 조회 시 제외
2. **이름으로 매칭** — surface ref보다 이름으로 찾기. 부분 일치 허용
3. **전송 전 확인** — `send` 모드에서는 반드시 사용자 확인 후 전송
4. **에러 감지** — 화면에 에러, traceback, 실패 메시지가 보이면 강조하여 알림
5. **Claude 세션 감지** — Claude Code 관련 내용이 보이면 진행 중인 작업과 진행률 분석
6. **브라우저는 새 창** — `cmux new-window`로 별도 창에서 열기. 현재 작업 공간 보호
7. **입력 대기 감지** — surface에 프롬프트나 선택지가 보이면 "사용자 입력을 기다리고 있습니다" 알림
8. **서버 surface 중복 방지** — 서버 실행 전 같은 이름의 surface가 이미 있으면 재사용
9. **서버 실행 명령 불확실 시 물어보기** — 프로젝트 구조로 판단이 안 되면 사용자에게 확인
10. **디버깅 결과는 에러 문서로 남기기** — 다른 세션에 문제를 전달하고 해결한 경우, **작업이 속한 서브프로젝트의** `errors/NN-slug.md` 에 독립 파일로 정리 (모노레포면 루트가 아닌 서브프로젝트 쪽). 한 번 해결된 문제도 지식으로 축적. 위치 판단 규칙은 "멀티 세션 디버깅 + 에러 문서화 워크플로" 의 5번 항목 참조.
11. **작업 지시 전 관련 `errors/` 문서 확인** — 다른 세션에 `cmux send`로 작업을 지시하기 전에, **작업 대상 서브프로젝트의** `errors/` + 루트 `errors/` 둘 다 확인한다. 작업이 건드릴 영역(스키마, 프로토콜, 통합 지점, 설정 값 등)과 관련된 기록이 있으면 해당 `errors/NN-*.md` 경로를 `send` 본문에 포함시켜 전달한다. 재발 방지 루프.
    - 해당 위치에 `errors/` 디렉토리가 없거나 비어 있으면 건너뛴다.
    - 작업과 관련 없는 에러는 포함하지 않는다 (과다 전달 방지).
    - 규칙 10(에러 문서 남기기)과 한 쌍으로 작동한다: **쓰기(10) ↔ 읽기(11)**.
