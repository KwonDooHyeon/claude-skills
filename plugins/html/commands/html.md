---
allowed-tools: Write
description: 직전 AI 답변에서 핵심 정보(TL;DR, 트레이드오프, Insight, 다음 액션 등)만 추출해 HTML 카드 대시보드로 렌더링하고 tmp 경로의 file URL 을 반환. 트리거 — HTML로 보여줘, 이거 시각화, 핵심만 정리, html 로 보고 싶어 등.
argument-hint: 인자 없음 (직전 AI 답변 대상)
---

# /html — 직전 답변 핵심 추출 + HTML 렌더링

직전 AI 답변을 markdown→HTML 1:1 변환이 아니라, **핵심 정보만 압축 추출**해서 한눈에 보이는 카드 대시보드로 렌더링.

## 동작 절차

1. **직전 AI 답변 식별** — 현재 대화 turn 의 바로 이전 assistant 메시지 본문
2. **핵심 정보 추출** — 아래 "추출 패턴" 표에 매칭되는 부분만 골라냄. **답변 전체를 옮기지 말 것**
3. **timestamp 생성** — `date +%Y%m%d-%H%M%S` (Bash)
4. **HTML 작성** — `Write` 도구로 `/tmp/claude-html-<timestamp>.html` 에 저장
5. **URL 출력만** — 마지막 응답에 `file:///tmp/claude-html-<timestamp>.html` 한 줄. 그 외 장황한 설명 금지. 사용자가 직접 cmd+클릭으로 염

## 추출 패턴 (이것만 골라서 HTML 에 담음)

| 답변 속 패턴 | HTML 변환 | CSS 클래스 |
|---|---|---|
| TL;DR / 한 줄 결론 / 추천 | 상단 큰 카드 | `.tldr` |
| 표 (`\|...\|`) | 스타일링된 `<table>` | `.cmp-table` |
| 옵션 비교 (A vs B vs C) | 카드 그리드 (`<div class="grid">`) | `.option-card` |
| `★ Insight ─────` 박스 | 좌측 컬러 보더 박스 | `.insight` |
| 결정 사항 / 추천 (✅, "Recommended") | 강조 카드 (초록 보더) | `.decision` |
| 경고 / 안티패턴 (🔴, "금지", "주의") | 빨간 보더 박스 | `.warning` |
| 다음 액션 / 단계 / TODO | 체크박스 리스트 | `.actions` |
| 코드 / 명령어 / 파일 경로 | `<pre><code>` 블록 | `.code` |
| 트레이드오프 매트릭스 | 색상 셀 테이블 (🟢🟡🔴) | `.tradeoff` |

**버려야 할 것** (HTML 에 담지 말 것):
- 사고 과정 서술, 중간 정리, "왜 이렇게 했는지" 장황 설명 → 답변에는 있어도 HTML 에는 빼기
- 본문 헤더 (H1/H2/H3) 의 위계 그대로 옮기기 → 카드 레이아웃으로 재구성
- 같은 정보 두 번 (예: 표로도 있고 본문에도 있음) → 표만 남기기

## HTML 표준 템플릿

매번 같은 CSS 를 사용해 일관성 + 토큰 절약. **이 템플릿을 그대로 복사**해서 `<body>` 안의 카드만 답변별로 채움:

```html
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>Claude Highlight — {{title}}</title>
<style>
  * { box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
    background: #f5f5f7;
    color: #1d1d1f;
    margin: 0;
    padding: 32px;
    line-height: 1.6;
  }
  .container { max-width: 980px; margin: 0 auto; }
  .meta { color: #86868b; font-size: 13px; margin-bottom: 24px; }
  h1.page-title { font-size: 28px; margin: 0 0 8px 0; }

  .card {
    background: #fff;
    border-radius: 12px;
    padding: 20px 24px;
    margin-bottom: 16px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.06);
  }
  .card h2 { font-size: 18px; margin: 0 0 12px 0; color: #1d1d1f; }

  /* TL;DR — 상단 강조 */
  .tldr { background: #0071e3; color: #fff; }
  .tldr h2 { color: #fff; }
  .tldr p { font-size: 17px; margin: 0; }

  /* Insight — 좌측 보더 */
  .insight {
    border-left: 4px solid #ff9500;
    background: #fff8ec;
  }
  .insight h2 { color: #c2410c; }
  .insight ul { margin: 8px 0 0 0; padding-left: 20px; }

  /* Decision — 추천 / 결정 */
  .decision { border-left: 4px solid #30d158; }
  .decision h2 { color: #1e8e3e; }

  /* Warning — 경고 / 안티패턴 */
  .warning { border-left: 4px solid #ff3b30; background: #fff5f5; }
  .warning h2 { color: #c62828; }

  /* Grid for option cards */
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 12px;
  }
  .option-card {
    background: #fff;
    border-radius: 10px;
    padding: 16px;
    border: 1px solid #e5e5e7;
  }
  .option-card h3 { margin: 0 0 8px 0; font-size: 16px; }
  .option-card .pros { color: #1e8e3e; }
  .option-card .cons { color: #c62828; }

  /* Tables */
  table { width: 100%; border-collapse: collapse; margin: 8px 0; }
  th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #e5e5e7; }
  th { background: #f5f5f7; font-weight: 600; }
  tr:hover td { background: #fafafa; }

  /* Code */
  pre, code {
    font-family: "SF Mono", Menlo, Monaco, monospace;
    font-size: 13px;
  }
  pre {
    background: #1d1d1f;
    color: #f5f5f7;
    padding: 12px 16px;
    border-radius: 8px;
    overflow-x: auto;
  }
  code:not(pre code) {
    background: #f0f0f2;
    padding: 2px 6px;
    border-radius: 4px;
    color: #d70015;
  }

  /* Action checklist */
  .actions ul { list-style: none; padding-left: 0; }
  .actions li::before { content: "☐ "; color: #86868b; margin-right: 4px; }
  .actions li { padding: 4px 0; }

  /* Status icons */
  .ok { color: #1e8e3e; }
  .warn { color: #c2410c; }
  .err { color: #c62828; }
</style>
</head>
<body>
<div class="container">
  <div class="meta">Claude Code — {{timestamp}}</div>
  <h1 class="page-title">{{한 줄 주제}}</h1>

  <!-- TL;DR 카드 -->
  <div class="card tldr">
    <h2>TL;DR</h2>
    <p>{{한 문장 결론}}</p>
  </div>

  <!-- Insight (있을 때만) -->
  <div class="card insight">
    <h2>Insight</h2>
    <ul>{{핵심 통찰 항목들}}</ul>
  </div>

  <!-- Decision (있을 때만) -->
  <div class="card decision">
    <h2>결정 / 추천</h2>
    <p>{{추천 사항}}</p>
  </div>

  <!-- 옵션 비교 (있을 때만) -->
  <div class="card">
    <h2>옵션 비교</h2>
    <div class="grid">{{option-card 들}}</div>
  </div>

  <!-- 트레이드오프 표 (있을 때만) -->
  <div class="card">
    <h2>트레이드오프</h2>
    <table>{{비교 표}}</table>
  </div>

  <!-- 다음 액션 (있을 때만) -->
  <div class="card actions">
    <h2>다음 액션</h2>
    <ul>{{액션 항목들}}</ul>
  </div>

  <!-- Warning (있을 때만) -->
  <div class="card warning">
    <h2>주의 / 안티패턴</h2>
    <ul>{{경고 항목들}}</ul>
  </div>
</div>
</body>
</html>
```

## 카드 선택 규칙

위 템플릿의 카드는 **답변에 해당 패턴이 있을 때만** 포함. 없으면 그 카드 통째로 삭제. 강제로 채우지 말 것 — 빈 카드는 가독성을 해침.

최소 카드 (대부분 답변): `meta` + `page-title` + `TL;DR`
최대 카드 (옵션 비교 답변): 위 모든 카드

## 최종 응답 형식

HTML 파일 작성 후 사용자에게는 **딱 이 두 줄만** 출력:

```
file:///tmp/claude-html-<timestamp>.html

핵심 N개 추출 — TL;DR / 옵션 N개 / Insight / 다음 액션 N개
```

장황한 설명, 작업 후기, 추가 제안 모두 금지. URL 이 핵심 산출물.

## 안티패턴 (절대 하지 말 것)

- ❌ 답변 markdown 을 1:1 로 HTML 변환 (h1→h1, p→p) — 그건 일반 markdown 뷰어
- ❌ 답변에 없는 정보를 새로 만들기 — hallucination
- ❌ CSS 를 카드별로 다르게 — 일관성 깨짐, 토큰 낭비
- ❌ 외부 CDN (Tailwind, Bootstrap, jQuery) — 의존성 + 오프라인 미동작
- ❌ JavaScript — 정적 HTML 로 충분
- ❌ 다크 모드 토글 같은 부가 기능 — 단순 시각화가 목적
- ❌ 파일 작성 후 `open` 명령으로 자동 열기 — 사용자가 URL 만 받고 직접 클릭

## 토큰 효율

답변이 길수록 압축 효과 ↑:
- 5000 토큰짜리 장황한 답변 → 1500~2500 토큰짜리 HTML (핵심만)
- 표 1개 + TL;DR 만 있는 짧은 답변 → ~800 토큰 HTML

사용자가 명시 호출 시에만 발동하므로 자동 비용 0.
