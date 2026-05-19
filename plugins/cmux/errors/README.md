# dh-cmux skill — 사고 기록

cmux 워크스페이스 스킬을 운영하면서 발견한 도구 한계·운영 사고를 영속화. 동일 사고를 두 번 부딪히지 않기 위한 지식 축적.

## 작성 규칙

- 파일명: `NN-short-slug.md` (2자리 zero-pad 순번)
- 한 파일 = 하나의 사고
- 본문에 frontmatter (id / date / title / category / status / area / tags) + 섹션 (발생 시점 / 증상 / 원인 / 해결 방법 / 교훈)
- enum
  - `category`: `cmux-tool | sentinel | delegation | workflow`
  - `status`: `resolved | in-progress`
  - `area`: `tooling`

## 목차

| ID | 제목 | 카테고리 | 상태 |
|---|---|---|---|
| 01 | [cmux send 멀티라인 메시지 hang](01-cmux-send-multiline-hang.md) | cmux-tool | resolved |
