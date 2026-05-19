---
allowed-tools: Write, Bash
description: 직전 AI 답변을 sidebar TOC + 다크모드 대응 테크닥 스타일 HTML로 렌더링하고 tmp 경로의 file URL 을 반환. 트리거 — HTML로 보여줘, 이거 HTML 로 보고싶어, 한눈에 보여줘 등.
argument-hint: 인자 없음 (직전 AI 답변 대상)
---

# /html — 직전 답변을 테크닥 스타일 HTML 로 렌더링

직전 AI 답변을 **있는 그대로** 충실히 렌더링한다 (카드 추출 X). 좌측 sticky sidebar TOC, 다크모드 자동 대응, 한국어 친화 타이포그래피, GitHub-스타일 색감.

## 동작 절차

1. **직전 AI 답변 식별** — 현재 대화 turn 의 바로 이전 assistant 메시지 본문
2. **답변의 markdown 구조 파싱** (헤더 H1/H2/H3, 단락, 리스트, 표, 코드 블록, 인용구, hr 등) — 사고 과정 서술은 빼고 정보 본문만
3. **TOC 항목 수집** — H2/H3 만. 각 헤더에 안정적인 id 부여 (`s-1`, `s-2-1`, ... 형식 권장 — 한글 슬러그 불안정성 회피)
4. **timestamp 생성** — `date +%Y%m%d-%H%M%S` (Bash)
5. **HTML 작성** — `Write` 도구로 `/tmp/claude-html-<timestamp>.html` 에 저장. 아래 **표준 템플릿**의 CSS 를 그대로 사용하고 본문/TOC 만 답변에 맞게 채움
6. **URL 출력만** — 마지막 응답에 `file:///tmp/claude-html-<timestamp>.html` 한 줄 + 한 줄짜리 짧은 요약. 그 외 장황한 설명 금지. `open` 명령 자동 실행 금지 (사용자가 cmd+클릭)

## 무엇을 렌더링하고 무엇을 빼는가

**담는다 (정보 본문)**:
- 답변의 본문 H1/H2/H3 와 모든 단락
- 표, 리스트(ol/ul), 코드 블록, 인용구
- 다이어그램·아스키 아트가 `<pre>` 블록 안에 있다면 그대로 (등폭 글꼴, 줄바꿈/공백 보존)

**뺀다 (메타·중간 잡설)**:
- "지금부터…", "정리하면…", "다음 단계로…" 같은 진행 멘트
- 사용자에게 한 추가 질문 (질문은 답변이 아님)
- 같은 정보가 표 + 본문 둘 다 있으면 표만 남김
- "이 모양이 맞나요?" 같은 확인 요청 줄

## 표준 템플릿 (그대로 사용)

본문/TOC 자리만 답변별로 채운다. CSS·레이아웃·다크모드 토큰은 절대 바꾸지 말 것 (일관성 + 토큰 절약).

```html
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<title>{{한 줄 제목}}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
:root {
  --bg: #ffffff;
  --fg: #1f2328;
  --muted: #59636e;
  --border: #d1d9e0;
  --link: #0969da;
  --accent: #0969da;
  --code-bg: #f6f8fa;
  --code-fg: #1f2328;
  --table-stripe: #f6f8fa;
  --sidebar-bg: #f6f8fa;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0d1117;
    --fg: #e6edf3;
    --muted: #9198a1;
    --border: #30363d;
    --link: #4493f8;
    --accent: #4493f8;
    --code-bg: #151b23;
    --code-fg: #e6edf3;
    --table-stripe: #151b23;
    --sidebar-bg: #0d1117;
  }
}
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Pretendard",
               "Segoe UI", Helvetica, Arial, "Noto Sans KR", sans-serif;
  background: var(--bg);
  color: var(--fg);
  line-height: 1.65;
  font-size: 16px;
}
a { color: var(--link); text-decoration: none; }
a:hover { text-decoration: underline; }
.layout { display: grid; grid-template-columns: 280px 1fr; gap: 0; min-height: 100vh; }
@media (max-width: 900px) { .layout { grid-template-columns: 1fr; } .sidebar { display: none; } }
.sidebar {
  position: sticky; top: 0; height: 100vh; overflow-y: auto;
  padding: 24px 16px 24px 24px;
  background: var(--sidebar-bg);
  border-right: 1px solid var(--border);
  font-size: 13.5px;
}
.sidebar h1 { font-size: 16px; margin: 0 0 4px; color: var(--fg); }
.sidebar .tag { display: inline-block; padding: 2px 8px; border-radius: 999px;
                background: var(--accent); color: white; font-size: 11px; margin-bottom: 12px; }
.sidebar ul { list-style: none; padding: 0; margin: 0 0 8px; }
.sidebar li { margin: 4px 0; }
.sidebar li.toc-l3 { margin-left: 14px; font-size: 12.5px; color: var(--muted); }
.sidebar a { color: var(--fg); }
.sidebar a:hover { color: var(--accent); }
.main {
  padding: 40px 56px 80px;
  max-width: 980px;
  width: 100%;
}
@media (max-width: 900px) { .main { padding: 24px 20px 60px; } }
h1 { font-size: 32px; margin: 0 0 24px; border-bottom: 1px solid var(--border); padding-bottom: 12px; }
h2 { font-size: 24px; margin: 40px 0 16px; padding-bottom: 8px; border-bottom: 1px solid var(--border); scroll-margin-top: 16px; }
h3 { font-size: 19px; margin: 28px 0 12px; scroll-margin-top: 16px; }
h4 { font-size: 16px; margin: 20px 0 8px; }
p { margin: 12px 0; }
ul, ol { padding-left: 28px; }
li { margin: 4px 0; }
blockquote {
  margin: 16px 0;
  padding: 8px 16px;
  border-left: 4px solid var(--accent);
  background: var(--code-bg);
  color: var(--fg);
}
blockquote p { margin: 6px 0; }
code {
  font-family: "SF Mono", "JetBrains Mono", Menlo, Monaco, Consolas, "Courier New", monospace;
  font-size: 13.5px;
  background: var(--code-bg);
  color: var(--code-fg);
  padding: 1.5px 5px;
  border-radius: 4px;
  border: 1px solid var(--border);
}
pre {
  background: var(--code-bg);
  color: var(--code-fg);
  padding: 14px 18px;
  border-radius: 8px;
  border: 1px solid var(--border);
  overflow-x: auto;
  font-size: 13px;
  line-height: 1.55;
}
pre code { background: transparent; border: none; padding: 0; font-size: inherit; white-space: pre; }
table {
  border-collapse: collapse;
  width: 100%;
  margin: 16px 0;
  font-size: 14.5px;
  display: block;
  overflow-x: auto;
}
th, td {
  border: 1px solid var(--border);
  padding: 8px 12px;
  text-align: left;
  vertical-align: top;
}
th { background: var(--code-bg); font-weight: 600; }
tbody tr:nth-child(even) { background: var(--table-stripe); }
hr { border: none; border-top: 1px solid var(--border); margin: 32px 0; }
strong { font-weight: 600; }
::-webkit-scrollbar { width: 10px; height: 10px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--border); border-radius: 5px; }
</style>
</head>
<body>
<div class="layout">
  <nav class="sidebar">
    <h1>{{사이드바 짧은 제목 ≤ 20자}}</h1>
    <span class="tag">{{유형 라벨, 예: Notes · 날짜}}</span>
    <ul>
      {{TOC: <li class="toc-l2"><a href="#s-1">…</a></li>
            <li class="toc-l3"><a href="#s-1-1">…</a></li>}}
    </ul>
  </nav>
  <main class="main">
    <h1>{{본문 H1 — 답변의 주제 한 줄}}</h1>
    {{본문: H2/H3 에 id 부여, 그 외 markdown 요소를 HTML 로 변환}}
  </main>
</div>
</body>
</html>
```

## 변환 규칙 (markdown → HTML)

| markdown | HTML |
|----------|------|
| `## 제목` | `<h2 id="s-N">제목</h2>` |
| `### 제목` | `<h3 id="s-N-M">제목</h3>` |
| `**bold**` | `<strong>bold</strong>` |
| `` `code` `` | `<code>code</code>` |
| 표 (\| ... \|) | `<table><thead>…<tbody>…</table>` |
| 펜스 코드 (` ```lang `) | `<pre><code class="language-lang">…</code></pre>` |
| `> 인용` | `<blockquote><p>인용</p></blockquote>` |
| `- 항목` | `<ul><li>항목</li></ul>` |
| `1. 항목` | `<ol><li>항목</li></ol>` |
| `---` | `<hr>` |
| 링크 `[text](url)` | `<a href="url">text</a>` |
| 단락 빈 줄 분리 | `<p>…</p>` |

**ASCII 아트/다이어그램**: 펜스 코드 블록(```` ``` ````) 안에 있으면 `<pre><code>` 로 변환하되 내부 공백·줄바꿈·박스문자(`│ ─ ┌ ┐ └ ┘ ▼ ◀ ▶`) 그대로 보존.

**HTML 이스케이프**: `<`, `>`, `&` 는 본문 내용일 때 `&lt;`, `&gt;`, `&amp;` 로 변환. 단 의도적으로 HTML 인 부분(예: 사용자 답변에 직접 `<details>` 가 있다면)은 보존.

**TOC id 부여**: 한글 헤더의 슬러그가 깨지기 쉬우니 `s-1`, `s-2`, `s-2-1`, `s-2-2` 처럼 **순번 기반 id** 권장. TOC `<a href="#s-N">` 도 같은 id 를 가리키게.

## 사이드바 채우기 규칙

- `h1`: 사이드바용 짧은 제목 (≤ 20자). 답변 주제를 한 단어/짧은 구로
- `.tag`: 답변 성격 라벨 + 날짜 (예: "Notes · 2026-05-19", "Design · 2026-05-19", "Brainstorm · 2026-05-19"). 답변 톤을 한눈에
- TOC: H2 는 `toc-l2`, H3 는 `toc-l3` 클래스로 들여쓰기
- 답변에 H2 가 2개 미만이면 TOC 항목 빈 채로 두지 말고 사이드바를 통째로 숨김 — `<nav class="sidebar">` 블록을 제거하고 `.layout { grid-template-columns: 1fr; }` 인라인 적용

## 최종 응답 형식

HTML 파일 작성 후 사용자에게 **딱 이 형식**으로:

```
file:///tmp/claude-html-<timestamp>.html

{{한 줄 요약 — 예: "TOC 12개 섹션, 표 3, 코드블록 2"}}
```

장황한 작업 후기, 추가 제안 모두 금지. URL 이 핵심 산출물.

## 안티패턴 (절대 하지 말 것)

- ❌ 답변에 없는 정보 만들기 (hallucination)
- ❌ CSS 토큰값(`--accent`, `--bg` 등) 변경 — 일관성 깨짐
- ❌ 외부 CDN (Tailwind, Bootstrap, marked.js 등) — 의존성 + 오프라인 미동작
- ❌ JavaScript — 정적 HTML 로 충분
- ❌ 본문 텍스트를 **요약**하거나 **재작성** — 답변 그대로 옮기는 게 원칙. 잡설만 걷어내기
- ❌ 파일 작성 후 `open` 명령으로 자동 열기 — 사용자가 URL 만 받고 직접 클릭
- ❌ H1 을 답변 첫 줄로 무지성 채우기 — 답변의 진짜 주제를 추출

## 토큰 효율

표준 CSS 가 매번 동일하므로 캐시 효과 ↑. 답변 본문만 변환하면 되므로 추가 비용은 답변 길이에 비례 (선형).
