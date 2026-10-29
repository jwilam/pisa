/* ===== PISA 2025 研討會專題 — Shared Navigation ===== */
const PAGES = [
  { file: "index.html",        no: "01", short: "介紹",      title: "介紹",                         desc: "研討會背景、主講嘉賓及專題目錄" },
  { file: "pisa-nature.html",  no: "02", short: "教育體檢",  title: "PISA 的性質與定位",             desc: "一次「教育體檢」，而非國際競賽；解讀結果的五大原則", speaker: "梁貫成教授" },
  { file: "competencies.html", no: "03", short: "未來準備度", title: "演化中的能力",                  desc: "PISA 框架二十多年的演變，以及學習能動性的崛起", speaker: "羅陸慧英教授" },
  { file: "trends.html",       no: "04", short: "十年趨勢",  title: "從十年趨勢看香港",              desc: "三大核心範疇自 2012 年高峰後的持續下行", speaker: "陳錦河教授" },
  { file: "misconceptions/index.html", no: "05", short: "誤解排除", title: "先排除誤解", desc: "國際大型評估研究", speaker: "PISA 2025 團隊" },
  { file: "agency.html",       no: "06", short: "學習能動性", title: "學習能動性的結構",              desc: "心理測量網絡分析：甚麼因素與科學表現相關？", speaker: "林葦葉教授" },
  { file: "science.html",      no: "07", short: "科學",      title: "科學教育的反思",                desc: "培育「有能力的非專家」，建立知情的信任", speaker: "陳錦河教授" },
  { file: "mathematics.html",  no: "08", short: "數學",      title: "數學教育的反思",                desc: "立足長處，讓扎實基礎通向深度推理", speaker: "梁貫成教授" },
  { file: "reading.html",      no: "09", short: "閱讀",      title: "閱讀教育的反思",                desc: "在 AI 與多文本時代，學生需要怎樣的閱讀素養？", speaker: "鍾竹梅教授" },
  { file: "digital.html",      no: "10", short: "數碼與 AI", title: "從 LDW 到 MAIL",                desc: "發揮數碼學習所長，邁向 PISA 2029", speaker: "羅陸慧英教授" },
  { file: "conclusion.html",   no: "11", short: "結語",      title: "結語：為未來而教",              desc: "四個範疇的反思與研究團隊的核心共識" }
];

/* ★ 1. Must be read here, at the top level (it's null inside DOMContentLoaded) */
const SITE_JS_SRC = document.currentScript && document.currentScript.src;

document.addEventListener("DOMContentLoaded", () => {
  const current = document.body.dataset.page || "index.html";
  const idx = PAGES.findIndex(p => p.file === current);

  /* ★ 2. Site root: .../site/js/site.js → .../site/
        Fallback: count the "/" in data-page, e.g. "misconceptions/index.html" → "../" */
  const ROOT = SITE_JS_SRC
    ? new URL("../", SITE_JS_SRC).href
    : "../".repeat((current.match(/\//g) || []).length);
  const link = f => ROOT + f;

  /* Header */
  const header = document.getElementById("site-header");
  if (header) {
    header.outerHTML = `
    <header class="site-header">
      <div class="header-inner">
        <a class="brand" href="${link("index.html")}"><span class="brand-badge">PISA HK</span>PISA 2025 研討會專題</a>
        <button class="nav-toggle" aria-expanded="false" aria-controls="site-nav">☰ 章節目錄</button>
        <nav class="site-nav" id="site-nav" aria-label="章節導覽">
          <ul>${PAGES.map(p => `<li><a href="${link(p.file)}"${p.file === current ? ' aria-current="page"' : ""}>${p.no} ${p.short}</a></li>`).join("")}</ul>
        </nav>
      </div>
      <div class="progress"><span></span></div>
    </header>`;
    const btn = document.querySelector(".nav-toggle");
    const nav = document.getElementById("site-nav");
    btn.addEventListener("click", () => {
      const open = nav.classList.toggle("open");
      btn.setAttribute("aria-expanded", open);
    });
  }

  /* Table of contents (home page) */
  const toc = document.getElementById("toc-cards");
  if (toc) {
    toc.innerHTML = PAGES.slice(1).map(p => `
      <a class="toc-card" href="${link(p.file)}">
        <span class="n">${p.no}</span>
        <h4>${p.title}</h4>
        <p>${p.desc}</p>
        ${p.speaker ? `<small>主講：${p.speaker}</small>` : ""}
      </a>`).join("");
  }

  /* Previous / next pager */
  const pager = document.getElementById("pager");
  if (pager && idx > -1) {
    const prev = PAGES[idx - 1], next = PAGES[idx + 1];
    pager.className = "pager";
    pager.innerHTML =
      (prev ? `<a class="prev" href="${link(prev.file)}"><small>← 上一章</small><b>${prev.no} ${prev.title}</b></a>` : "") +
      (next ? `<a class="next" href="${link(next.file)}"><small>下一章 →</small><b>${next.no} ${next.title}</b></a>` : "");
  }

  /* Footer */
  const footer = document.getElementById("site-footer");
  if (footer) {
    footer.outerHTML = `
    <footer class="site-footer">
      <div class="inner">
        <div>香港大學教育學院 PISA 香港研究團隊<br>本專題根據 2026 年 10 月 17 日研討會之演講內容及相關研究數據整理。</div>
        <div><a href="${link("index.html")}">返回專題首頁</a> · <a href="#top">回到頁頂 ↑</a></div>
      </div>
    </footer>`;
  }

  /* Wrap tables for mobile scrolling */
  document.querySelectorAll(".content table").forEach(t => {
    if (!t.parentElement.classList.contains("table-wrap")) {
      const w = document.createElement("div");
      w.className = "table-wrap";
      t.parentNode.insertBefore(w, t);
      w.appendChild(t);
    }
  });

  /* Reading progress bar */
  const bar = document.querySelector(".progress span");
  const onScroll = () => {
    const h = document.documentElement;
    const max = h.scrollHeight - h.clientHeight;
    if (bar) bar.style.width = (max > 0 ? (h.scrollTop / max) * 100 : 0) + "%";
  };
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();
});
