# cmux 도메인 위임 패턴 (필수 Read 자료)

> **언제 이 파일을 Read 하나**: 메인 `cmux-workspace` 가 *도메인 작업 위임* 또는 *root inline 결정* 또는 *위임 메시지 송신* 을 안내한 모든 경우. 위임 송신 *전*에 반드시 Read. 안 읽고 위임 진행 시 사고 책임.

---

## 도메인 작업 위임 정책

cmux 워크스페이스에 서브프로젝트별 Claude Code 세션이 떠있는 경우, root 세션은 **그 도메인의 모든 작업** (분석·탐색·디버깅·코드 변경) 을 **반드시 해당 세션에 위임**한다. root 가 직접 답하지 않는다.

이 정책은 "멀티 세션 디버깅" 워크플로 보다 **상위 규칙**. 디버깅은 이 정책의 한 사례.

### 위임 대상 작업

- ✅ **분석·탐색** — "engine 봐줘", "back 의 X 어떻게 동작해", "front 코드 분석해줘", "기능 카탈로그 만들어줘"
- ✅ **디버깅** — 특정 서브프로젝트의 버그 (멀티 세션 디버깅 워크플로와 결합 진행)
- ✅ **변경 작업** — 특정 서브프로젝트의 코드 수정 / 리팩토링 / 기능 추가
- ✅ **로컬 운영** — 특정 서브프로젝트의 테스트 실행 / 로그 분석

### 예외 — root 가 직접 처리해도 됨

- 워크스페이스 전체 상태 조회 ("status", "tree", "어디까지 됐어")
- 서버 운영 명령 (서버 실행/중지 — 별도 워크플로)
- **크로스커팅 변경** (2개 이상 서브프로젝트 동시 영향: 공통 스키마/프로토콜/배포 파이프라인/인프라 설정)
- 사용자가 명시적으로 "root 에서 직접 해줘" 라고 요청한 경우

### 대상 세션 판단 기준

1. 메시지에 서브프로젝트 이름 명시 (예: "engine", "back", "front") → 해당 세션
2. 파일 경로가 서브프로젝트 디렉토리 안 → 그 세션
3. 도메인 키워드 (예: "백엔드 API" / "프론트 UI" / "엔진 LLM") → 해당 세션
4. 모호하면 사용자에게 확인 후 진행 (자의로 판단 금지)

### 위임 절차 (7단계)

1. **대상 세션 확인** — `cmux tree --all` 로 surface ref 찾기
2. **사용자 요청을 구체화** — 단순 전달이 아니라 **목적·기대 결과·제약** 까지 포함한 자기 완결적 지시로 변환. 위임 메시지에는 반드시 **unique sentinel** 을 포함한다 (`references/sentinel-polling.md` 필수 Read).
3. **`cmux send` + `send-key enter`** 로 송신 (아래 "메타 메시지 + 파일 경로 패턴" 강제 적용)
4. **완료 폴링** — bash 내장 `SECONDS` 기반 deadline 패턴 + 파일 기반 sentinel. sentinel 없는 폴링 / 타임아웃 보호 없는 폴링 **금지**. 자세한 패턴은 `references/sentinel-polling.md` 필수 Read.
5. **결과 수집** — root 에서 `cmux read-screen` 으로 그 세션의 결과를 가져옴. 결과 파일은 `/tmp/cmux-result-<slug>.md` 에 sub-session 이 직접 작성.
6. **사용자에게 보고** — root 가 정리해서 최종 응답
7. **코드 변경 동반 시** → `references/error-documentation.md` 의 5~8단계 (errors/ 문서화) 까지 진행

---

## "효율성 함정" 경고 + root inline 예외

LLM 의 자연스러운 본능: "단순한 grep 한 번이면 답이 나오는데 굳이 다른 세션 거치는 게 비효율" 이라는 판단이 들기 쉽다. **이 본능을 따르지 말 것** — 단 *큰* 도메인 작업에 한해서만.

사용자가 멀티 세션 구조를 만든 이유는 **효율** 이 아니라 **각 세션의 도메인 컨텍스트 누적**. 분석/탐색/디버깅/큰 변경 은 해당 세션이 해야 그 세션의 메모리·메모/위키에 쌓인다. root 가 가로채면 그 누적이 끊긴다.

판단이 흔들릴 때 기준:
- **"이 작업이 어느 세션의 메모리에 쌓여야 하는가?"**
- **"round-trip 비용 (위임 메시지 작성 1~2분 + sentinel 폴링 평균 3분) 이 누적 가치보다 큰가?"**

답이 *root* / *비용 > 가치* 면 root inline.

### 예외 — root inline 우선 케이스

다음 작업은 도메인 위임 시 round-trip 비용 (5분+) 이 메모리 누적 가치보다 *명백히 크다*. root inline 처리:

- **단순 git 운영**: `git push` (사전 가드 후), `git pull` (사용자 결정 후), `git status` 확인 등
- **1줄 patch / typo fix / 단일 import 정리** (사용자가 의도/위치 명시한 후)
- **파일 1개 read / 단일 grep 결과 확인**
- **사용자가 결정 명시한 후 단순 실행** ("그대로 push 해줘", "그 파일 보여줘" 등)
- **단순 cmux 운영**: `cmux tree`, `cmux identify`, `cmux read-screen` 단일 호출
- **자기 자신 (root) 의 ~/.claude/ 또는 marketplaces/ 영역 작업** — 도메인 세션 자체가 없거나 root 의 영역

### 위임 우선 케이스 (그대로)

- 5+ 파일 grep / 아키텍처 검토 / 큰 분석
- 3+ 파일 코드 변경 / jest·test 작성 동반
- 디버깅 / 사고 원인 추적 / errors 문서 동반
- 사용자 의도 모호 → 도메인 컨텍스트로 판단 필요
- 작업 1개당 *Read + Edit + Bash + Read* 같은 복합 흐름

### 작업 sizing 직관

- root 가 **5초~30초 안에 끝낼 수 있음** → inline
- 작업이 **1~2분 이상** 걸리거나 **복합 도구 흐름** → 위임 검토

---

## 세션 간 병렬 위임 (서로 다른 세션은 동시에)

룰 14 의 "동시 위임 금지" 는 **같은 sub-session 에 한정**된다. **서로 다른 세션** (예: engine + front + back) 에 독립적인 작업을 줄 때는 **병렬 위임이 기본** — 직렬로 하나씩 기다리지 말 것. 사용자가 멀티 세션을 띄운 이유 중 하나가 동시 진행이다.

발동 조건: 작업들이 **상호 독립** (한 세션 결과가 다른 세션 입력이 아님) 이고 **서로 다른 sub-session** 대상일 때. 의존 관계가 있으면 직렬.

절차:

1. **slug 를 작업마다 unique 하게** — `engine-refactor-1`, `front-fix-1` 처럼 세션·작업이 구분되게. sentinel/result 파일도 각각 분리 (`/tmp/cmux-done-engine-refactor-1`, `/tmp/cmux-done-front-fix-1`).
2. **각 세션에 메타 메시지 + 파일 경로 패턴으로 송신** (단일 위임과 동일). 송신 전 각 세션 ctx 게이지 확인 (룰 13).
3. **폴링은 모든 sentinel 을 한 루프에서 동시 감시** — 각각 별도 폴링을 직렬로 돌리면 병렬 의미가 없다:
   ```bash
   bash -c '
     deadline=$((SECONDS + 1800))
     slugs="engine-refactor-1 front-fix-1"
     until [ -z "$slugs" ]; do
       [ $SECONDS -ge $deadline ] && { echo "TIMEOUT 남은:$slugs"; exit 124; }
       rest=""
       for s in $slugs; do [ -f /tmp/cmux-done-$s ] && echo "DONE $s" || rest="$rest $s"; done
       slugs="$(echo $rest | xargs)"
       [ -n "$slugs" ] && sleep 15
     done
     echo "ALL DONE"
   '
   ```
4. **결과 수집은 완료된 순서대로** — 각 `/tmp/cmux-result-<slug>.md` 를 읽어 세션별로 정리 후 통합 보고.

주의:
- **같은 세션엔 여전히 1개씩** (룰 14 그대로). 병렬은 세션 *간* 에만.
- **크로스커팅 작업** (2개 이상 세션이 같은 파일/스키마 동시 변경) 은 병렬 금지 — 충돌. 이건 root 직접 처리 또는 직렬.
- 타임아웃 시 **어느 slug 가 남았는지** 명시해서 보고 (위 패턴이 남은 slug 출력).

---

## 위임 메시지 표준 템플릿 (필수 4요소)

매 위임마다 즉흥적으로 메시지를 짜면 sentinel 누락 / AskUserQuestion 인터럽트 / quoting 실패 같은 사고가 반복된다. 다음 템플릿의 빈칸을 채워 사용:

```
[차단 문구 — 첫 줄에 두기]
이미 작업이 명확합니다. AskUserQuestion 등 추가 사용자 확인 절차 없이 바로 분석 및 작업을 진행하세요. 모호한 부분은 자체 판단으로 결정하고, 결과 파일에 그 판단 근거를 기록하세요.

## 작업
<무엇을, 왜>

## 컨텍스트
<지금까지의 흐름, 직전 변경 사항, 백엔드/프론트 상태>

## 구현 힌트 (선택)
<예상 파일, 패턴 제안>

## 관련 errors 문서 (있을 때만)
- <서브프로젝트>/errors/NN-*.md — <해당 사고 요약>

## 완료 보고 (필수)
작업이 완료되면 다음 두 가지를 차례로 실행하세요:
1. 결과 요약을 /tmp/cmux-result-<task-slug>.md 에 markdown 으로 작성 (## 변경 파일 / ## 변경 요약 / ## 검증 결과 섹션 포함)
2. `touch /tmp/cmux-done-<task-slug>` 실행
```

핵심 4요소:
- **차단 문구** — AskUserQuestion 인터럽트 방지 (`첫 줄` 에 위치해서 sub-session 이 메시지 첫 줄로 인터랙티브 모드 진입하는 사고 차단)
- **컨텍스트** — sub-session 이 같은 세션이라도 시간이 지나면 기억이 흐려지므로 명시
- **관련 errors** — 룰 11 의 사전 확인 결과를 여기 포함 (재발 방지 루프)
- **완료 보고** — 파일 기반 sentinel 형식 (`references/sentinel-polling.md` 의 방식 A)

---

## 위임 메시지 송신 — 메타 메시지 + 파일 경로 패턴

`cmux send` 는 두 가지 한계가 있다:

1. **quoting 깨짐** — 멀티라인 / 특수문자 (`{`, `}`, `*`, `` ` ``, `$`, `(`, `)`, 따옴표) 포함 시 zsh/bash quoting 사고
2. **크기 hang** — 약 6 KB / 60+ 줄 이상 메시지에서 `cmux send "$(cat <file>)"` 가 60~180 초 timeout 으로 hang (TUI 입력 버퍼 reflow / paste-mode 핸드셰이크 지연). 정확 임계값은 미측정이나 1 KB / 수 줄 이하만 안전.

→ 이전 표준이었던 `cmux send "$(cat <file>)"` 는 1번 문제는 해결했지만 2번에서 깨진다. 두 문제를 동시에 차단하려면 **메타 메시지 + 파일 경로** 패턴:

```bash
# 1. 위임 본문은 항상 파일에 작성 (Write 도구 사용 — escape 걱정 없음)
#    파일 경로: /tmp/cmux-msg-<task-slug>.txt

# 2. cmux send 로는 짧은 메타 메시지만 송신 — 본문 인라인 금지:
cmux send --surface <ref> "AskUserQuestion 없이 진행. /tmp/cmux-msg-<task-slug>.txt 를 Read 도구로 읽고 그 안의 지시 그대로 수행. 완료 시 sentinel touch."
cmux send-key --surface <ref> enter
```

규칙:

- 메타 메시지는 **한 줄, ~150 자 이내, 특수문자 적게** — cmux send 안전 영역
- 첫 부분에 "AskUserQuestion 없이 진행" 차단 문구
- 파일 경로는 **절대경로**로 명시 (sub-session 의 cwd 와 무관하게 작동)
- 임시 메시지 파일은 송신 후 삭제하지 않음 (디버깅 / 재참조용)

부수 효과:

- 메타 메시지에는 본문의 sentinel 토큰이 없음 → 화면 기반 sentinel 의 false-positive 회피와 자연 정합
- sub-session 의 read-screen 출력에 위임 본문이 한 화면 가득 안 찍힘 → 디버깅 시 화면 가독성 ↑

비용: sub-session 의 첫 액션이 "Read 한 번 더" 인 점. 토큰 ~수십 단위 추가. 무시 가능.

진단 sanity test: `cmux send --surface <ref> "ping"` 한 줄이 즉시 받아지면 통신 정상. hang 발생 시 즉시 메타 메시지 패턴으로 우회 — 60→180 초 timeout 늘리기 재시도 금지.

**참고 errors**: `plugins/cmux/errors/01-cmux-send-multiline-hang.md` — 5.8 KB 위임 메시지 hang 사고, 본 패턴 도출 배경.
