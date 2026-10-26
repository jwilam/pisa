/* ===== 學習能動性研究系列 (EGA) — navigation & interactions ===== */
const EGA_PAGES = [
  { file: "index.html",  no: "A", short: "研究發現", title: "學習能動性與科學表現：研究發現" },
  { file: "method.html", no: "B", short: "分析方法", title: "如何以 EGA 分析 PISA 數據" }
];

document.addEventListener("DOMContentLoaded", () => {
  const current = document.body.dataset.page || "index.html";
  const idx = EGA_PAGES.findIndex(p => p.file === current);

  const header = document.getElementById("site-header");
  if (header) {
    header.outerHTML = `
    <header class="site-header"><div class="header-inner">
      <a class="brand" href="index.html"><span class="brand-badge">PISA HK</span>學習能動性研究</a>
      <button class="nav-toggle" aria-expanded="false" aria-controls="site-nav">☰ 目錄</button>
      <nav class="site-nav" id="site-nav" aria-label="系列導覽"><ul>
        ${EGA_PAGES.map(p => `<li><a href="${p.file}"${p.file === current ? ' aria-current="page"' : ""}>${p.no} ${p.short}</a></li>`).join("")}
        <li><a href="../agency.html">05 學習能動性（研討會）</a></li>
        <li><a href="../science-factors/index.html">科學表現因素系列</a></li>
        <li><a href="../agency.html">↩ 05 學習能動性</a></li>
      </ul></nav>
    </div><div class="progress"><span></span></div></header>`;
    const btn = document.querySelector(".nav-toggle"), nav = document.getElementById("site-nav");
    btn.addEventListener("click", () => btn.setAttribute("aria-expanded", nav.classList.toggle("open")));
  }

  const pager = document.getElementById("pager");
  if (pager && idx > -1) {
    const prev = EGA_PAGES[idx - 1], next = EGA_PAGES[idx + 1];
    pager.className = "pager";
    pager.innerHTML =
      (prev ? `<a class="prev" href="${prev.file}"><small>← 上一頁</small><b>${prev.no} ${prev.title}</b></a>`
            : `<a class="prev" href="../agency.html"><small>← 研討會專題</small><b>05 學習能動性的結構</b></a>`) +
      (next ? `<a class="next" href="${next.file}"><small>下一頁 →</small><b>${next.no} ${next.title}</b></a>`
            : `<a class="next" href="../science-factors/index.html"><small>延伸閱讀 →</small><b>科學表現背後的因素</b></a>`);
  }

  const footer = document.getElementById("site-footer");
  if (footer) footer.outerHTML = `
    <footer class="site-footer"><div class="inner">
      <div>香港大學教育學院 PISA 香港研究團隊<br>數據：PISA 2025 香港學生數據（OECD）；分析：探索性圖分析（EGA）。</div>
      <div><a href="../index.html">研討會專題</a> · <a href="#top">回到頁頂 ↑</a></div>
    </div></footer>`;

  const bar = document.querySelector(".progress span");
  const onScroll = () => { const h = document.documentElement, m = h.scrollHeight - h.clientHeight;
    if (bar) bar.style.width = (m > 0 ? h.scrollTop / m * 100 : 0) + "%"; };
  window.addEventListener("scroll", onScroll, { passive: true }); onScroll();

  /* Deck: fullscreen */
  const full = document.getElementById("deck-full"), frame = document.querySelector(".deck-frame iframe");
  if (full && frame) full.addEventListener("click", () => (frame.requestFullscreen || frame.webkitRequestFullscreen)?.call(frame));

  /* Figure lightbox */
  const lb = document.createElement("div"); lb.id = "ega-lightbox"; lb.innerHTML = "<img alt='放大的圖表'>";
  document.body.appendChild(lb); lb.addEventListener("click", () => lb.classList.remove("on"));
  document.querySelectorAll("figure.efig img").forEach(img => img.addEventListener("click", () => {
    lb.querySelector("img").src = img.src; lb.classList.add("on"); }));
  document.addEventListener("keydown", e => { if (e.key === "Escape") lb.classList.remove("on"); });

  /* Method stepper */
  document.querySelectorAll("[data-stepper]").forEach(box => {
    const btns = [...box.querySelectorAll(".st-btn")], panels = [...box.querySelectorAll(".st-panel")];
    const go = i => {
      btns.forEach((b, j) => b.setAttribute("aria-selected", i === j));
      panels.forEach((p, j) => p.hidden = i !== j);
      box.querySelectorAll(".st-prev").forEach(b => b.disabled = i === 0);
      box.querySelectorAll(".st-next").forEach(b => b.disabled = i === panels.length - 1);
      box.dataset.i = i;
    };
    btns.forEach((b, i) => b.addEventListener("click", () => go(i)));
    box.querySelectorAll(".st-prev").forEach(b => b.addEventListener("click", () => go(+box.dataset.i - 1)));
    box.querySelectorAll(".st-next").forEach(b => b.addEventListener("click", () => go(+box.dataset.i + 1)));
    go(0);
  });

  /* Copy code */
  document.querySelectorAll(".code-box").forEach(box => {
    const b = document.createElement("button"); b.className = "copy-btn"; b.textContent = "複製";
    b.addEventListener("click", () => navigator.clipboard.writeText(box.querySelector("pre").innerText)
      .then(() => { b.textContent = "已複製 ✓"; setTimeout(() => b.textContent = "複製", 1500); }));
    box.appendChild(b);
  });
});
