# claude-skills

개인용 Claude Code 스킬 모음.

## 설치

```bash
# 1. 마켓플레이스 등록
/plugin marketplace add KwonDooHyeon/claude-skills

# 2. 플러그인 설치
/plugin install dh-commands@dh-skills
```

## 포함된 스킬

### cmux-workspace
cmux 워크스페이스의 모든 surface를 관찰하고 오케스트레이션하는 스킬.

```bash
/cmux-workspace              # 전체 상태 조회
/cmux-workspace tree         # 트리 구조
/cmux-workspace read <name>  # 특정 surface 읽기
/cmux-workspace send <name> <msg>  # 메시지 전송
/cmux-workspace browse <url> # 브라우저에서 URL 열기
```
