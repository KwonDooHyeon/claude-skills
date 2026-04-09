---
allowed-tools: Bash(cmux *)
description: cmux 워크스페이스의 모든 surface를 관찰하고, 상태를 요약하고, 다른 세션에 메시지를 전송하고, 브라우저로 URL을 열어 테스트하고, 서버를 실행하는 스킬. "세션 상태", "워크스페이스 확인", "서버 상태", "다른 세션에 전달", "surface 확인", "브라우저로 열어줘", "서버 띄워줘", "백엔드 실행", "프론트 실행", "서버 로그", "서버 시작", "서버 중지" 등의 요청 시 트리거.
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

1. `cmux new-window` 로 새 창 생성 (window ref 기록)
2. 새 창에서 `cmux browser open <url>` 실행
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

---

## 중요 규칙

1. **자기 자신 제외** — `cmux identify`로 현재 surface 확인, 상태 조회 시 제외
2. **이름으로 매칭** — surface ref보다 이름으로 찾기. 부분 일치 허용
3. **전송 전 확인** — `send` 모드에서는 반드시 사용자 확인 후 전송
4. **에러 감지** — 화면에 에러, traceback, 실패 메시지가 보이면 강조하여 알림
5. **Claude 세션 감지** — Claude Code 관련 내용이 보이면 진행 중인 작업과 진행률 분석
6. **브라우저는 새 창** — `cmux new-window`로 별도 창에서 열기. 현재 작업 공간 보호
7. **입력 대기 감지** — surface에 프롬프트나 선택지가 보이면 "사용자 입력을 기다리고 있습니다" 알림
8. **서버 surface 중복 방지** — 서버 실행 전 같은 이름의 surface가 이미 있으면 재사용
9. **서버 실행 명령 불확실 시 물어보기** — 프로젝트 구조로 판단이 안 되면 사용자에게 확인
