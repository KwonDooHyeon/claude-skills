---
allowed-tools: Write, Bash
description: 직전 AI 답변 (또는 사용자가 지정한 markdown 파일) 을 sidebar TOC + 다크모드 + 풍부한 시각화 (mermaid 다이어그램 · chart.js · prism.js 코드 하이라이트) + 인터랙티브 컴포넌트 (accordion · 체크리스트 · 탭 · 테마 토글 · TOC 스크롤 동기화) 풀세트 테크닥 스타일 HTML 로 렌더링하고 tmp 경로의 file URL 을 반환. 트리거 — HTML로 보여줘, 한눈에 보여줘, 시각화해줘, 인터랙티브, 다이어그램 등.
argument-hint: 인자 없음 (직전 AI 답변 대상). 또는 markdown 파일 경로 지정. 정적/오프라인 원하면 "정적으로", "오프라인" 같은 키워드 명시.
---

# /html — 직전 답변을 풍부 시각화 + 인터랙티브 테크닥 HTML 로 렌더링

직전 AI 답변을 **있는 그대로** 충실히 렌더링한다 (카드 추출 X). 좌측 sticky sidebar TOC + 다크모드 자동 대응 + 한국어 친화 타이포그래피 + GitHub-스타일 색감. **기본이 풍부 모드** — mermaid 다이어그램 · chart.js · prism.js 신택스 하이라이트 · accordion · 인터랙티브 체크리스트 · 탭 · 테마 토글 · TOC 스크롤 동기화가 표준 포함.

**트레이드오프**: 인터넷 연결 필요. 오프라인 시 mermaid/chart.js/prism.js 미렌더 (텍스트와 레이아웃은 그대로). 사용자가 "정적으로", "오프라인 호환" 등 명시하면 fallback (정적 모드) 으로 — CDN/JS 모두 제거.

## 동작 절차

1. **대상 식별** — 직전 assistant 메시지 본문. 사용자가 특정 파일 경로 명시 시 그 파일 (예: plan 문서, README).
2. **모드 결정** — 기본은 풍부 모드. 사용자가 "정적/오프라인" 명시 시만 fallback.
3. **markdown 구조 파싱** (H1/H2/H3, 단락, 리스트, 표, 코드 블록, 인용구, hr 등) — 사고 과정 서술은 빼고 정보 본문만
4. **TOC 항목 수집** — H2/H3 만. 각 헤더에 안정적 id (`s-1`, `s-2-1`) — 한글 슬러그 회피
5. **시각화 컴포넌트 선택** — 답변 내용에 맞게:
   - API/외부 호출 흐름 있음 → mermaid 시퀀스 다이어그램
   - 분기/상태 전이 있음 → mermaid flowchart
   - 변경 전/후 메트릭 비교 있음 → chart.js bar/line
   - 검증 항목 N개 있음 → 인터랙티브 체크리스트
   - 변경 파일 / 사례 N개 있음 → accordion 으로 펼침
   - 변경 전/후 비교 있음 → before/after grid 또는 탭
   - 핵심 결정 N건 있음 → hero 카드 grid
6. **timestamp** — `date +%Y%m%d-%H%M%S`
7. **HTML 작성** — `Write` 로 `/tmp/claude-html-<timestamp>.html`. 아래 표준 템플릿 사용.
8. **URL 출력만** — `file:///tmp/claude-html-<timestamp>.html` + 한 줄 요약 (트레이드오프 한 마디 포함).

## 무엇을 렌더링하고 무엇을 빼는가

**담는다 (정보 본문)**:
- 답변의 본문 H1/H2/H3 와 모든 단락
- 표, 리스트(ol/ul), 코드 블록, 인용구
- 다이어그램·아스키 아트가 `<pre>` 블록 안에 있다면 그대로 (또는 의미 보존하며 mermaid 로 재작성)

**뺀다 (메타·중간 잡설)**:
- "지금부터…", "정리하면…", "다음 단계로…" 같은 진행 멘트
- 사용자에게 한 추가 질문
- 같은 정보가 표 + 본문 둘 다 있으면 표만 남김
- "이 모양이 맞나요?" 같은 확인 요청 줄

## 표준 템플릿 (그대로 사용)

CSS 토큰·레이아웃·CDN 버전은 절대 바꾸지 말 것 (일관성 + 토큰 절약 + 캐시 효과). 본문/TOC/시각화 컴포넌트 자리만 답변에 맞게 채운다.

```html
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<title>{{한 줄 제목}}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism-tomorrow.min.css">
<style>
:root {
  --bg: #ffffff;
  --fg: #1f2328;
  --muted: #59636e;
  --border: #d1d9e0;
  --link: #0969da;
  --accent: #0969da;
  --accent-soft: #ddf4ff;
  --code-bg: #f6f8fa;
  --code-fg: #1f2328;
  --table-stripe: #f6f8fa;
  --sidebar-bg: #f6f8fa;
  --card-bg: #ffffff;
  --shadow: 0 1px 3px rgba(0,0,0,0.08), 0 4px 12px rgba(0,0,0,0.04);
  --success: #1a7f37;
  --warn: #9a6700;
  --danger: #cf222e;
  --info: #0969da;
}
[data-theme="dark"] {
  --bg: #0d1117; --fg: #e6edf3; --muted: #9198a1; --border: #30363d;
  --link: #4493f8; --accent: #4493f8; --accent-soft: #1c2b40;
  --code-bg: #151b23; --code-fg: #e6edf3; --table-stripe: #151b23;
  --sidebar-bg: #0d1117; --card-bg: #151b23;
  --shadow: 0 1px 3px rgba(0,0,0,0.4), 0 4px 12px rgba(0,0,0,0.3);
  --success: #3fb950; --warn: #d29922; --danger: #f85149; --info: #4493f8;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #0d1117; --fg: #e6edf3; --muted: #9198a1; --border: #30363d;
    --link: #4493f8; --accent: #4493f8; --accent-soft: #1c2b40;
    --code-bg: #151b23; --code-fg: #e6edf3; --table-stripe: #151b23;
    --sidebar-bg: #0d1117; --card-bg: #151b23;
    --shadow: 0 1px 3px rgba(0,0,0,0.4), 0 4px 12px rgba(0,0,0,0.3);
    --success: #3fb950; --warn: #d29922; --danger: #f85149; --info: #4493f8;
  }
}
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Pretendard", "Segoe UI", Helvetica, Arial, "Noto Sans KR", sans-serif; background: var(--bg); color: var(--fg); line-height: 1.65; font-size: 16px; transition: background 0.2s, color 0.2s; }
a { color: var(--link); text-decoration: none; }
a:hover { text-decoration: underline; }
.layout { display: grid; grid-template-columns: 280px 1fr; gap: 0; min-height: 100vh; }
@media (max-width: 1100px) { .layout { grid-template-columns: 1fr; } .sidebar { display: none; } }
.sidebar { position: sticky; top: 0; height: 100vh; overflow-y: auto; padding: 24px 16px 24px 24px; background: var(--sidebar-bg); border-right: 1px solid var(--border); font-size: 13.5px; }
.sidebar h1 { font-size: 16px; margin: 0 0 4px; color: var(--fg); }
.sidebar .tag { display: inline-block; padding: 2px 8px; border-radius: 999px; background: var(--accent); color: white; font-size: 11px; margin-bottom: 12px; }
.sidebar ul { list-style: none; padding: 0; margin: 0 0 8px; }
.sidebar li { margin: 4px 0; }
.sidebar li.toc-l3 { margin-left: 14px; font-size: 12.5px; color: var(--muted); }
.sidebar a { color: var(--fg); display: block; padding: 4px 8px; border-radius: 6px; border-left: 2px solid transparent; }
.sidebar a:hover { color: var(--accent); background: var(--accent-soft); text-decoration: none; }
.sidebar a.active { color: var(--accent); border-left-color: var(--accent); font-weight: 600; background: var(--accent-soft); }
.theme-toggle { position: fixed; top: 16px; right: 16px; z-index: 100; background: var(--card-bg); color: var(--fg); border: 1px solid var(--border); border-radius: 999px; padding: 8px 14px; cursor: pointer; font-size: 13px; box-shadow: var(--shadow); }
.theme-toggle:hover { background: var(--accent-soft); border-color: var(--accent); }
.main { padding: 40px 56px 80px; max-width: 1100px; width: 100%; }
@media (max-width: 1100px) { .main { padding: 24px 20px 60px; } }
h1 { font-size: 32px; margin: 0 0 24px; border-bottom: 1px solid var(--border); padding-bottom: 12px; }
h2 { font-size: 24px; margin: 48px 0 16px; padding-bottom: 8px; border-bottom: 1px solid var(--border); scroll-margin-top: 16px; }
h3 { font-size: 19px; margin: 28px 0 12px; scroll-margin-top: 16px; }
h4 { font-size: 16px; margin: 20px 0 8px; }
p { margin: 12px 0; }
ul, ol { padding-left: 28px; }
li { margin: 4px 0; }
blockquote { margin: 16px 0; padding: 8px 16px; border-left: 4px solid var(--accent); background: var(--code-bg); color: var(--fg); }
blockquote p { margin: 6px 0; }
code { font-family: "SF Mono", "JetBrains Mono", Menlo, Monaco, Consolas, "Courier New", monospace; font-size: 13.5px; background: var(--code-bg); color: var(--code-fg); padding: 1.5px 5px; border-radius: 4px; border: 1px solid var(--border); }
pre { background: var(--code-bg) !important; color: var(--code-fg); padding: 14px 18px !important; border-radius: 8px; border: 1px solid var(--border); overflow-x: auto; font-size: 13px; line-height: 1.55; }
pre code { background: transparent !important; border: none; padding: 0; font-size: inherit; white-space: pre; }
table { border-collapse: collapse; width: 100%; margin: 16px 0; font-size: 14.5px; display: block; overflow-x: auto; }
th, td { border: 1px solid var(--border); padding: 8px 12px; text-align: left; vertical-align: top; }
th { background: var(--code-bg); font-weight: 600; }
tbody tr:nth-child(even) { background: var(--table-stripe); }
hr { border: none; border-top: 1px solid var(--border); margin: 32px 0; }
strong { font-weight: 600; }

/* hero 카드 */
.hero-cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin: 24px 0 32px; }
@media (max-width: 800px) { .hero-cards { grid-template-columns: 1fr; } }
.hero-card { background: var(--card-bg); border: 1px solid var(--border); border-radius: 12px; padding: 20px; box-shadow: var(--shadow); }
.hero-card .label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted); margin-bottom: 8px; }
.hero-card .value { font-size: 18px; font-weight: 600; color: var(--fg); margin-bottom: 6px; }
.hero-card .detail { font-size: 13px; color: var(--muted); }
.hero-card.accent { border-top: 3px solid var(--accent); }
.hero-card.warn { border-top: 3px solid var(--warn); }
.hero-card.success { border-top: 3px solid var(--success); }
.hero-card.danger { border-top: 3px solid var(--danger); }

/* badge */
.badge { display: inline-block; padding: 2px 10px; border-radius: 999px; font-size: 11px; font-weight: 600; margin-right: 4px; }
.badge.kept { background: var(--code-bg); color: var(--success); border: 1px solid var(--success); }
.badge.changed { background: var(--accent-soft); color: var(--accent); border: 1px solid var(--accent); }
.badge.added { background: var(--code-bg); color: var(--info); border: 1px solid var(--info); }
.badge.risk { background: var(--code-bg); color: var(--danger); border: 1px solid var(--danger); }
.badge.warn { background: var(--code-bg); color: var(--warn); border: 1px solid var(--warn); }

/* before/after grid */
.beforeafter { display: grid; grid-template-columns: 1fr 40px 1fr; gap: 0; margin: 16px 0; align-items: stretch; }
@media (max-width: 800px) { .beforeafter { grid-template-columns: 1fr; } .beforeafter .arrow { display: none; } }
.beforeafter .box { background: var(--card-bg); border: 1px solid var(--border); border-radius: 10px; padding: 16px; }
.beforeafter .box .head { font-size: 12px; text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted); margin-bottom: 8px; }
.beforeafter .box.before .head { color: var(--danger); }
.beforeafter .box.after .head { color: var(--success); }
.beforeafter .arrow { display: flex; align-items: center; justify-content: center; color: var(--accent); font-size: 24px; }

/* mermaid / chart 컨테이너 */
.mermaid-wrap, .chart-wrap { background: var(--card-bg); border: 1px solid var(--border); border-radius: 12px; padding: 24px; margin: 16px 0; box-shadow: var(--shadow); }
.mermaid-wrap .caption, .chart-wrap .caption { font-size: 12px; color: var(--muted); text-align: center; margin-top: 12px; font-style: italic; }
.mermaid { text-align: center; }

/* accordion */
.accordion { margin: 16px 0; }
.accordion-item { background: var(--card-bg); border: 1px solid var(--border); border-radius: 8px; margin-bottom: 8px; overflow: hidden; }
.accordion-header { width: 100%; background: transparent; border: none; color: var(--fg); padding: 14px 18px; text-align: left; cursor: pointer; font-size: 15px; font-weight: 600; display: flex; align-items: center; justify-content: space-between; font-family: inherit; }
.accordion-header:hover { background: var(--accent-soft); }
.accordion-header .file-path { font-family: "SF Mono", Menlo, Consolas, monospace; font-size: 13px; color: var(--accent); font-weight: normal; }
.accordion-header .chevron { transition: transform 0.2s; font-size: 12px; color: var(--muted); }
.accordion-item.open .accordion-header .chevron { transform: rotate(180deg); }
.accordion-body { max-height: 0; overflow: hidden; transition: max-height 0.3s ease-out; padding: 0 18px; }
.accordion-item.open .accordion-body { max-height: 4000px; padding: 0 18px 16px; }

/* checklist */
.checklist { background: var(--card-bg); border: 1px solid var(--border); border-radius: 12px; padding: 20px; margin: 16px 0; box-shadow: var(--shadow); }
.checklist h4 { margin-top: 0; }
.checklist-item { display: flex; align-items: flex-start; gap: 12px; padding: 10px 0; border-bottom: 1px dashed var(--border); }
.checklist-item:last-child { border-bottom: none; }
.checklist-item input[type="checkbox"] { margin-top: 4px; width: 18px; height: 18px; cursor: pointer; accent-color: var(--accent); }
.checklist-item label { flex: 1; cursor: pointer; line-height: 1.5; }
.checklist-item input:checked + label { color: var(--muted); text-decoration: line-through; }
.checklist-progress { margin-top: 12px; font-size: 12px; color: var(--muted); text-align: right; }

/* tabs */
.tabs { display: flex; border-bottom: 1px solid var(--border); margin: 16px 0 0; gap: 4px; }
.tab { background: transparent; border: 1px solid transparent; border-bottom: none; color: var(--muted); padding: 8px 16px; cursor: pointer; font-size: 14px; font-family: inherit; border-radius: 6px 6px 0 0; }
.tab.active { color: var(--accent); background: var(--card-bg); border-color: var(--border); border-bottom: 1px solid var(--card-bg); margin-bottom: -1px; font-weight: 600; }
.tab-pane { display: none; padding: 16px; background: var(--card-bg); border: 1px solid var(--border); border-top: none; border-radius: 0 0 8px 8px; }
.tab-pane.active { display: block; }

/* section intro */
.section-intro { font-size: 14px; color: var(--muted); margin: 8px 0 16px; padding-left: 12px; border-left: 3px solid var(--border); }

::-webkit-scrollbar { width: 10px; height: 10px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--border); border-radius: 5px; }
</style>
</head>
<body>

<button class="theme-toggle" onclick="toggleTheme()">🌓 테마</button>

<div class="layout">
  <nav class="sidebar">
    <h1>{{사이드바 짧은 제목 ≤ 20자}}</h1>
    <span class="tag">{{유형 라벨, 예: Notes · 날짜}}</span>
    <ul id="toc">
      {{TOC: <li class="toc-l2"><a href="#s-1">…</a></li>}}
    </ul>
  </nav>
  <main class="main">
    <h1>{{본문 H1 — 답변의 주제 한 줄}}</h1>
    {{본문: H2/H3 에 id 부여 + 적절한 시각화 컴포넌트}}
  </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/mermaid@10.9.0/dist/mermaid.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/components/prism-core.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/prismjs@1.29.0/plugins/autoloader/prism-autoloader.min.js"></script>

<script>
// ===== Theme =====
function getTheme() {
  return document.documentElement.getAttribute('data-theme')
       || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
}
function toggleTheme() {
  const next = getTheme() === 'dark' ? 'light' : 'dark';
  document.documentElement.setAttribute('data-theme', next);
  localStorage.setItem('html-theme', next);
  renderMermaid();
  if (window.allCharts) { window.allCharts.forEach(c => { c.destroy(); }); window.allCharts = []; if (window.drawCharts) window.drawCharts(); }
}
(function initTheme() {
  const saved = localStorage.getItem('html-theme');
  if (saved) document.documentElement.setAttribute('data-theme', saved);
})();

// ===== Mermaid =====
function renderMermaid() {
  const theme = getTheme() === 'dark' ? 'dark' : 'default';
  if (typeof mermaid === 'undefined') return;
  mermaid.initialize({ startOnLoad: false, theme: theme, themeVariables: { fontFamily: '-apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Pretendard", sans-serif', fontSize: '14px' } });
  document.querySelectorAll('.mermaid').forEach(el => {
    if (!el.dataset.original) el.dataset.original = el.innerHTML;
    el.innerHTML = el.dataset.original;
    el.removeAttribute('data-processed');
  });
  mermaid.run({ querySelector: '.mermaid' });
}
if (typeof mermaid !== 'undefined') renderMermaid();
else window.addEventListener('load', () => { if (typeof mermaid !== 'undefined') renderMermaid(); });

// ===== Chart.js — drawCharts() 함수를 본문에서 정의해 호출 =====
window.allCharts = [];
// 예시:
// window.drawCharts = function() {
//   const ctx = document.getElementById('myChart').getContext('2d');
//   const isDark = getTheme() === 'dark';
//   const fg = isDark ? '#e6edf3' : '#1f2328';
//   const grid = isDark ? '#30363d' : '#d1d9e0';
//   const chart = new Chart(ctx, { type: 'bar', data: {...}, options: {scales: {x: {ticks: {color: fg}, grid: {color: grid}}, y: {ticks: {color: fg}, grid: {color: grid}}}, plugins: {legend: {labels: {color: fg}}}} });
//   window.allCharts.push(chart);
// };
// if (typeof Chart !== 'undefined') window.drawCharts();

// ===== Accordion =====
function toggleAccordion(btn) { btn.closest('.accordion-item').classList.toggle('open'); }

// ===== Tabs =====
function switchTab(btn, paneId) {
  const tabs = btn.parentElement.querySelectorAll('.tab');
  const panes = btn.parentElement.parentElement.querySelectorAll('.tab-pane');
  tabs.forEach(t => t.classList.remove('active'));
  panes.forEach(p => p.classList.remove('active'));
  btn.classList.add('active');
  document.getElementById(paneId).classList.add('active');
}

// ===== Checklist persistence =====
(function initChecklist() {
  const checkboxes = document.querySelectorAll('.check-persist');
  const progress = document.getElementById('checklist-progress');
  function update() {
    if (!progress) return;
    const total = checkboxes.length;
    const checked = Array.from(checkboxes).filter(c => c.checked).length;
    progress.textContent = `진행: ${checked} / ${total} 완료`;
  }
  checkboxes.forEach(cb => {
    const saved = localStorage.getItem('check-' + cb.id);
    if (saved === 'true') cb.checked = true;
    cb.addEventListener('change', () => { localStorage.setItem('check-' + cb.id, cb.checked); update(); });
  });
  update();
})();

// ===== TOC scroll sync =====
(function initTocSync() {
  const tocLinks = document.querySelectorAll('#toc a');
  const headings = Array.from(tocLinks).map(a => document.querySelector(a.getAttribute('href'))).filter(Boolean);
  if (!headings.length) return;
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const id = entry.target.id;
        tocLinks.forEach(a => a.classList.toggle('active', a.getAttribute('href') === '#' + id));
      }
    });
  }, { rootMargin: '-20% 0px -70% 0px' });
  headings.forEach(h => observer.observe(h));
})();
</script>

</body>
</html>
```

## 시각화 컴포넌트 사용 가이드

답변 내용에 맞게 *필요한 것만* 채워 넣는다. 모두 의무 사용 아님.

### Hero 카드 grid — 핵심 결정/지표 한눈에

```html
<div class="hero-cards">
  <div class="hero-card accent">
    <div class="label">라벨</div>
    <div class="value">짧은 값</div>
    <div class="detail">설명</div>
  </div>
  <!-- accent / warn / success / danger / (none) 클래스로 상단 색 -->
</div>
```

### mermaid 시퀀스 다이어그램 — API/외부 호출 흐름

```html
<div class="mermaid-wrap">
  <pre class="mermaid">
sequenceDiagram
  participant A as Client
  participant B as Server
  A->>B: request
  B-->>A: response
  </pre>
  <div class="caption">설명 캡션</div>
</div>
```

### mermaid flowchart — 분기/상태 전이

```html
<div class="mermaid-wrap">
  <pre class="mermaid">
flowchart TD
  X[입력] --> Y{조건?}
  Y -- yes --> Z[결과 A]
  Y -- no --> W[결과 B]
  </pre>
</div>
```

### chart.js — 메트릭 비교 (변경 전/후 등)

본문에 `<canvas>` 두고 `window.drawCharts` 함수에 본문 chart 정의를 모두 채워 넣는다. `toggleTheme` 이 자동으로 호출 → 다크/라이트 시 재렌더.

```html
<div class="chart-wrap">
  <h4>지표 제목</h4>
  <canvas id="chart1" height="120"></canvas>
</div>
<script>
window.drawCharts = function() {
  const ctx = document.getElementById('chart1').getContext('2d');
  const isDark = getTheme() === 'dark';
  const fg = isDark ? '#e6edf3' : '#1f2328';
  const grid = isDark ? '#30363d' : '#d1d9e0';
  const chart = new Chart(ctx, {
    type: 'bar',
    data: { labels: [...], datasets: [{ label: 'Before', data: [...], backgroundColor: 'rgba(207,34,46,0.6)' }, { label: 'After', data: [...], backgroundColor: 'rgba(26,127,55,0.6)' }] },
    options: { responsive: true, indexAxis: 'y', scales: { x: { ticks: {color: fg}, grid: {color: grid} }, y: { ticks: {color: fg}, grid: {color: grid} } }, plugins: { legend: { labels: {color: fg} } } }
  });
  window.allCharts.push(chart);
};
if (typeof Chart !== 'undefined') window.drawCharts();
</script>
```

### before/after grid — 변경 전후 비교

```html
<div class="beforeafter">
  <div class="box before"><div class="head">🔴 변경 전</div>...</div>
  <div class="arrow">→</div>
  <div class="box after"><div class="head">🟢 변경 후</div>...</div>
</div>
```

### Accordion — 변경 파일 N개 펼침

```html
<div class="accordion">
  <div class="accordion-item">
    <button class="accordion-header" onclick="toggleAccordion(this)">
      <span><span class="badge added">신규</span> <span class="file-path">path/to/file</span> — 설명</span>
      <span class="chevron">▼</span>
    </button>
    <div class="accordion-body">
      <pre><code class="language-python">...</code></pre>
    </div>
  </div>
</div>
```

### Tabs — 같은 영역 before/after 토글

```html
<div class="tabs">
  <button class="tab active" onclick="switchTab(this, 'tab-after')">After</button>
  <button class="tab" onclick="switchTab(this, 'tab-before')">Before</button>
</div>
<div id="tab-after" class="tab-pane active"><pre><code class="language-python">...</code></pre></div>
<div id="tab-before" class="tab-pane"><pre><code class="language-python">...</code></pre></div>
```

### Checklist — 진행도 localStorage 보존

```html
<div class="checklist">
  <h4>검증 항목</h4>
  <div class="checklist-item">
    <input type="checkbox" id="c-1" class="check-persist">
    <label for="c-1">항목 1</label>
  </div>
  <!-- ... -->
  <div class="checklist-progress" id="checklist-progress">진행: 0 / N 완료</div>
</div>
```

### Badge — 상태 라벨

```html
<span class="badge kept">✓ 안전</span>
<span class="badge changed">변경</span>
<span class="badge added">신규</span>
<span class="badge risk">위험</span>
<span class="badge warn">주의</span>
```

## 변환 규칙 (markdown → HTML)

| markdown | HTML |
|----------|------|
| `## 제목` | `<h2 id="s-N">제목</h2>` |
| `### 제목` | `<h3 id="s-N-M">제목</h3>` |
| `**bold**` | `<strong>bold</strong>` |
| `` `code` `` | `<code>code</code>` |
| 표 (\| ... \|) | `<table><thead>…<tbody>…</table>` |
| 펜스 코드 (` ```lang `) | `<pre><code class="language-lang">…</code></pre>` (prism.js autoloader 가 자동 highlight) |
| `> 인용` | `<blockquote><p>인용</p></blockquote>` |
| `- 항목` | `<ul><li>항목</li></ul>` |
| `1. 항목` | `<ol><li>항목</li></ol>` |
| `---` | `<hr>` |
| 링크 `[text](url)` | `<a href="url">text</a>` |
| 단락 빈 줄 분리 | `<p>…</p>` |

**ASCII 아트/다이어그램**: 답변에 ASCII 흐름도가 있으면 mermaid 로 다시 그리는 게 가독성 ↑ (의미 보존 필수). 의미 정확 변환 어려우면 원본 그대로 `<pre>` 보존.

**HTML 이스케이프**: `<`, `>`, `&` 는 본문 내용일 때 `&lt;`, `&gt;`, `&amp;`. 단 의도적 HTML (예: `<details>`) 은 보존.

**TOC id**: 한글 슬러그 회피 — `s-1`, `s-2`, `s-2-1` 순번 기반.

## 사이드바 채우기 규칙

- `h1`: 짧은 제목 (≤ 20자)
- `.tag`: 답변 성격 + 날짜 (예: "Plan · 2026-05-27", "Notes · 2026-05-19")
- TOC: H2 는 `toc-l2`, H3 는 `toc-l3` 클래스
- H2 가 2개 미만이면 사이드바 통째로 숨김 — `<nav class="sidebar">` 제거 + `.layout { grid-template-columns: 1fr; }`

## 최종 응답 형식

HTML 파일 작성 후 사용자에게 **딱 이 형식**으로:

```
file:///tmp/claude-html-<timestamp>.html

{{한 줄 요약 — 예: "mermaid 2 + chart.js 1 + accordion 5, 체크리스트 14 (오프라인 시 다이어그램 미렌더)"}}
```

장황한 작업 후기, 추가 제안 모두 금지. URL 이 핵심 산출물.

## 정적 fallback 모드 (사용자가 "정적/오프라인" 명시 시만)

기본 풍부 모드의 트레이드오프 (인터넷 의존, 오프라인 시 mermaid/chart 미렌더) 가 부담스러우면 사용자가 명시적으로 정적 모드 요청.

이때 차이:
- head 의 `<link rel="stylesheet" href="...prism...">` 제거
- body 끝 `<script src="...mermaid...">`, `<script src="...chart...">`, `<script src="...prism...">` 4개 제거
- mermaid `<pre class="mermaid">` 는 원본 ASCII 다이어그램으로 대체 (또는 그대로 두면 그냥 텍스트로 보임)
- chart.js `<canvas>` + script 는 정적 표로 대체
- accordion/checklist/탭/토글은 그대로 두되 onclick 등 JS 의존 동작은 안 됨 (기본 HTML 표시만)
- 또는 더 엄격히 — body 끝 `<script>` 블록 통째로 제거

정적 fallback 의 한 줄 응답 예: `"TOC 7 섹션, 표 3, 코드블록 8 (정적 모드)"`.

## 안티패턴 (절대 하지 말 것)

- ❌ 답변에 없는 정보 만들기 (hallucination)
- ❌ CSS 토큰값(`--accent`, `--bg`, `--card-bg` 등) 변경 — 일관성 깨짐
- ❌ 허용 라이브러리 (mermaid / chart.js / prism.js) 외의 의존성 추가 (Tailwind, Bootstrap, jQuery, marked.js 등) — 검증된 조합만
- ❌ CDN 버전 임의 변경 — 본 스킬이 보장하는 mermaid@10.9.0 / chart.js@4.4.0 / prismjs@1.29.0 픽스
- ❌ 트레이드오프 미고지 — 풍부 모드는 인터넷 필요 / 오프라인 시 다이어그램 미렌더라는 점을 응답 한 줄에 명시
- ❌ 본문 텍스트를 **요약**하거나 **재작성** — 답변 그대로 옮기는 게 원칙. 잡설만 걷어내기
- ❌ 파일 작성 후 `open` 명령으로 자동 열기 — 사용자가 URL 만 받고 직접 클릭
- ❌ H1 을 답변 첫 줄로 무지성 채우기 — 답변의 진짜 주제를 추출
- ❌ 시각화 컴포넌트 *전부* 의무 사용 — 답변 내용에 안 맞는 컴포넌트 억지로 만들지 말 것 (예: 표 1개짜리 답변에 chart.js 강제 X)

## 토큰 효율

표준 CSS + JS 가 매번 동일하므로 캐시 효과 ↑. 답변 본문만 변환하면 되므로 추가 비용은 답변 길이 + 사용한 컴포넌트 수에 비례. CDN 스크립트 태그는 5개 고정.
