# claude-skills

개인용 Claude Code 스킬 모음.

## 설치

```bash
# 1. 마켓플레이스 등록 (한 번만)
/plugin marketplace add KwonDooHyeon/claude-skills

# 2. 원하는 플러그인만 선택 설치
/plugin install dh-cmux@dh-skills     # cmux 워크스페이스 관리
/plugin install dh-git@dh-skills      # git 커밋 커맨드
```

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
