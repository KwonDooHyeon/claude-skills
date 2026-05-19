# claude-skills

개인용 Claude Code 스킬 모음.

## 설치

```bash
# 1. 마켓플레이스 등록 (한 번만)
/plugin marketplace add KwonDooHyeon/claude-skills

# 2. 원하는 플러그인만 선택 설치
/plugin install dh-cmux@dh-skills     # cmux 워크스페이스 관리
/plugin install dh-git@dh-skills      # git 커밋 커맨드
/plugin install dh-html@dh-skills     # 직전 답변을 sidebar TOC 테크닥 HTML 로 렌더링
/plugin install dh-handoff@dh-skills  # 세션 상태를 다음 세션으로 넘기는 핸드오프
```

설치 후 신규 플러그인이 자동완성에 안 뜨면 `/reload-plugins` 또는 Claude Code 재시작.

## 플러그인 목록

### dh-cmux
cmux 워크스페이스의 모든 surface를 관찰하고 오케스트레이션하는 스킬.

```bash
/cmux-workspace              # 전체 상태 조회
/cmux-workspace tree         # 트리 구조
/cmux-workspace read <name>  # 특정 surface 읽기
/cmux-workspace send <name> <msg>  # 메시지 전송
/cmux-workspace browse <url> # 브라우저에서 URL 열기
```

**Stop hook 포함:** Claude Code 작업이 끝날 때마다 자동으로 `cmux notify`를 호출하여 작업 완료 알림을 띄웁니다. 멀티 세션 환경에서 다른 세션의 작업 완료를 즉시 인지할 수 있습니다.

### dh-git
Conventional Commits 스타일의 한국어 git 커밋.

```bash
/git-commit                  # 변경사항 분석 후 커밋 메시지 생성
/git-commit "직접 메시지"     # 메시지 직접 지정
```

### dh-html
직전 AI 답변을 **sidebar TOC + 다크모드 대응 테크닥 스타일** HTML 로 렌더링. 긴 설명·스펙·정리 답변을 브라우저에서 한눈에 훑기 위한 on-demand 뷰어.

```bash
/html                        # 직전 AI 답변을 테크닥 HTML 로 렌더링
```

자연어 트리거도 동작: "HTML로 보여줘", "이거 HTML 로 보고싶어", "한눈에 보여줘".

**출력:** `/tmp/claude-html-<timestamp>.html` 파일 생성 후 `file://` URL 한 줄 반환. 자동 오픈 없음 — cmd+클릭으로 직접 브라우저에서 확인.

**특징:** 인라인 CSS, 외부 의존성 0, JS 미사용. 답변 markdown 의 구조(H1~H3, 코드블록, 표, 인용)를 보존하면서 좌측 sidebar TOC 와 본문 스크롤 동기화. 다크/라이트 자동 전환.

### dh-handoff
긴 세션 끝에 진행 상황·결정·다음 액션을 **마크다운 한 장**으로 저장. `/clear` 후 다음 세션이 이 파일만 읽으면 같은 지점에서 작업 이어감. 빌트인 `/rewind`(같은 세션 과거 되감기)와 별개 — 이건 **미래 세션에 바통 넘기기**.

```bash
/handoff                     # 현재 세션 상태를 ~/.claude/handoffs/<slug>/{timestamp,latest}.md 로 저장
```

자연어 트리거도 동작: "핸드오프", "컨텍스트 저장", "clear 전 정리", "다음 세션에 넘겨줘".

**출력:** 아카이브(`<timestamp>.md`) + 최신(`latest.md`) 두 파일 + 다음 세션에 그대로 붙여넣을 resume 프롬프트 한 줄.

**포맷:** 9 섹션 고정(요약 / 저장소 상태 / 한 일 / 결정·근거 / 미해결 / 다음 액션 / 읽어볼 파일 / 컨텍스트 단서 / 첫 프롬프트). 다음 세션 Claude 가 "어디까지 했지?" 묻지 않게 §6 액션은 실행 가능 단위, §4 결정엔 항상 근거 한 줄.
