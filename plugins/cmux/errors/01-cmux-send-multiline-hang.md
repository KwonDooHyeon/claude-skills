---
id: "01"
date: 2026-05-19
title: cmux send 가 큰 멀티라인 메시지(약 6KB)에서 hang 됨
category: cmux-tool
status: resolved
area: tooling
tags: [cmux-send, delegation, multiline, hang, timeout, workaround]
---

# [01] cmux send 멀티라인 메시지 hang — 파일 본문 + 메타 메시지 경로 전달 패턴

## 발생 시점

2026-05-19, rda 음성 API 가이드 작성을 rda-back2 (surface:28) 세션에 위임하던 중. 위임 메시지 파일 `/tmp/cmux-msg-voice-api-client-docs.txt` 가 약 5.8 KB 였음.

## 증상

큰 멀티라인 메시지를 `cmux send --surface <ref> "$(cat <파일>)"` 으로 송신했을 때:

```
$ cmux send --surface surface:28 "$(cat /tmp/cmux-msg-voice-api-client-docs.txt)"
Error: Command timed out          # 60초 timeout
```

180초로 timeout 연장 후 재시도해도 동일.

```
$ cmux send --surface surface:28 "$(cat /tmp/cmux-msg-voice-api-client-docs.txt)"
Error: Command timed out          # 180초 timeout
```

이 동안 대상 surface 화면에는 **아무 변화도 없음** — 입력박스에 글자가 한 글자도 들어가지 않음. 출력 버퍼에 partial write 흔적도 없음.

대조군 sanity test:

```
$ cmux send --surface surface:28 "ping"
OK surface:28 workspace:12        # 즉시 성공
```

→ 짧은 메시지(`ping`)는 정상. 크기/멀티라인 구조 둘 중 하나가 트리거.

## 원인

cmux send 가 큰 멀티라인 텍스트를 stdin 으로 stream 할 때 hang. 정확한 메커니즘은 미확정이지만 후보:

- TUI(Claude Code) 입력 버퍼의 reflow / paste-mode 핸드셰이크가 큰 paste 단위에서 동기 처리 지연
- cmux send 자체가 stdin write 를 ack 받을 때까지 대기하는데, 큰 입력에서 TUI 측 ack 가 늦어 deadline 초과
- 멀티라인 포함 시 cmux 가 각 줄을 개별 syscall 로 보내며 누적 latency 가 timeout 한계를 초과

어떤 경우든 **cmux send 의 정상 사용 범위 밖** 으로 보임. 짧은 단발 메시지는 안전, 긴 인지적 본문은 위험.

대략적 경계: 1 KB 이하 / 수 줄 이하는 안전. 6 KB / 60+ 줄은 hang. 정확한 임계값은 측정 안 함.

## 해결 방법

**패턴**: 위임 메시지의 본문을 파일로 두고, cmux send 로는 **그 파일 경로를 가리키는 짧은 메타 메시지만** 전달한다. sub-session 의 Claude 가 Read 도구로 파일을 직접 읽게 한다.

### Before — 직접 본문 송신 (hang)

```bash
# 본문 파일 작성 후:
cmux send --surface surface:28 "$(cat /tmp/cmux-msg-<slug>.txt)"
cmux send-key --surface surface:28 enter
```

### After — 메타 메시지 + 파일 경로 (안전)

```bash
# 본문 파일은 동일하게 작성:
# /tmp/cmux-msg-<slug>.txt 에 멀티라인 위임 메시지

# cmux send 로는 짧은 메타 메시지만:
cmux send --surface surface:28 "AskUserQuestion 없이 바로 작업 진행. /tmp/cmux-msg-<slug>.txt 를 Read 도구로 읽고 그 안의 지시를 그대로 수행하세요. 완료 시 sentinel touch 까지."
cmux send-key --surface surface:28 enter
```

핵심:

- 메타 메시지는 **1 줄, ~150자 이내** 로 유지 (cmux send 안전 영역)
- 메타 메시지 첫 줄에 "AskUserQuestion 없이 바로 작업 진행" 차단 문구 유지 (도메인 위임 정책 표준)
- 메타 메시지에 파일 경로를 절대경로로 명시
- 본문 파일은 그대로 유지 — sub-session 이 Read 도구로 읽을 때 동일한 위임 표준 템플릿이 그대로 살아 있음

부수 효과 (긍정적):

- 메타 메시지에는 위임 본문의 sentinel 토큰 (`<<<DONE:<slug>>>>`) 이 등장하지 않음 → 화면 기반 sentinel 의 false-positive 회피와 자연스럽게 정합. 단 본 표준은 파일 기반 sentinel 이 기본이라 이 효과는 부차적.
- sub-session 의 read-screen 출력에 위임 본문이 한 화면 가득 안 찍힘 → 디버깅 시 화면 가독성 향상.

비용:

- sub-session 의 첫 액션이 "Read 한 번 더" 인 점. 토큰 ~수십 단위 추가. 무시 가능.

## 교훈

1. **cmux send 의 안전 입력 크기 상한은 명확히 작다.** 한 줄 + 특수문자 적음 + ~150자 이내가 안전 영역. 그 너머는 시행착오.
2. **위임 메시지 본문은 항상 파일로 두는 것이 표준에 맞다.** dh-cmux 스킬의 "위임 메시지 송신 — quoting 안전 패턴" 섹션은 *quoting 안전* 만 강조하지만 *크기 안전* 도 동일한 결론으로 수렴한다. 본문 = 파일 = 표준.
3. **cmux send 호출은 항상 짧게.** 메타 메시지 형식 (위 "After" 예시) 을 위임 표준 템플릿의 송신 절차에 곧장 적용하는 게 안전.
4. **재시도가 무용한 timeout 은 도구 한계의 신호.** 같은 명령을 60초 → 180초로 늘려도 통과 못 하면 입력 자체가 hang 됐다고 보고 우회 패턴으로 즉시 전환. 무한 재시도 금지.
5. **sanity test 1줄 (`cmux send "ping"`) 로 통신 자체와 입력 크기 문제를 분리할 수 있다.** 화면이 즉시 받으면 *입력 크기* 문제로 확정, 안 받으면 surface 자체 또는 cmux 데몬 문제. 진단 단계로 유용.
