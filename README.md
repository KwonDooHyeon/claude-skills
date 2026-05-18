# claude-skills

개인용 Claude Code 스킬 모음.

## 설치

```bash
# 1. 마켓플레이스 등록 (한 번만)
/plugin marketplace add KwonDooHyeon/claude-skills

# 2. 원하는 플러그인만 선택 설치
/plugin install dh-cmux@dh-skills     # cmux 워크스페이스 관리
/plugin install dh-git@dh-skills      # git 커밋 커맨드
/plugin install dh-html@dh-skills     # 직전 답변 핵심 추출 HTML 렌더링
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
직전 AI 답변에서 핵심 정보(TL;DR / 트레이드오프 / Insight / 다음 액션)만 추출해 HTML 카드 대시보드로 렌더링. 장황한 답변을 한눈에 보기 위한 on-demand 시각화.

```bash
/html                        # 직전 AI 답변을 HTML 카드로 추출
```

자연어 트리거도 동작: "HTML로 보여줘", "이거 시각화", "핵심만 정리".

**출력:** `/tmp/claude-html-<timestamp>.html` 파일 생성 후 `file://` URL 한 줄 반환. 자동 오픈 없음 — cmd+클릭으로 직접 브라우저에서 확인.

**특징:** 인라인 CSS, 외부 의존성 0, JS 미사용. 답변 markdown 을 1:1 변환이 아니라 핵심 패턴만 추출(TL;DR/표/Insight 박스/체크리스트). 답변이 길수록 압축 효과 ↑.
