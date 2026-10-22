/* ===== 科學表現因素系列 — navigation & interactions ===== */
const SF_PAGES = [
  { file: "index.html",         no: "00", short: "總覽",     title: "科學表現背後的因素", desc: "為何聚焦科學信念、樂趣與自我效能感" },
  { file: "indicators.html",    no: "01", short: "三大指標", title: "三個關鍵指標",       desc: "每個指數量度甚麼？學生回答哪些題目？" },
  { file: "comparison.html",    no: "02", short: "港星比較", title: "香港、新加坡與 OECD", desc: "互動圖表：三個指數的比較" },
  { file: "profiles.html",      no: "03", short: "查證與常識", title: "科學認知取向",     desc: "學生如何在證據與常識之間取捨？" },
  { file: "collaboration.html", no: "04", short: "協作悖論", title: "協作與探究的悖論",   desc: "為何協作越多，成績未必越好？" },
  { file: "implications.html",  no: "05", short: "課堂啟示", title: "從數據到課堂",       desc: "提升信念、樂趣與自信的教學槓桿" }
];

document.addEventListener("DOMContentLoaded", () => {
  const current = document.body.dataset.page || "index.html";
  const idx = SF_PAGES.findIndex(p => p.file === current);

  /* Header */
  const header = document.getElementById("site-header");
  if (header) {
    header.outerHTML = `
    <header class="site-header">
      <div class="header-inner">
        <a class="brand" href="index.html"><span class="brand-badge">PISA HK</span>科學表現因素系列</a>
        <button class="nav-toggle" aria-expanded="false" aria-controls="site-nav">☰ 目錄</button>
        <nav class="site-nav" id="site-nav" aria-label="系列導覽"><ul>
          ${SF_PAGES.map(p => `<li><a href="${p.file}"${p.file === current ? ' aria-current="page"' : ""}>${p.no} ${p.short}</a></li>`).join("")}
          <li><a href="../index.html">↩ 研討會專題</a></li>
        </ul></nav>
      </div>
      <div class="progress"><span></span></div>
    </header>`;
    const btn = document.querySelector(".nav-toggle"), nav = document.getElementById("site-nav");
    btn.addEventListener("click", () => btn.setAttribute("aria-expanded", nav.classList.toggle("open")));
  }

  /* TOC */
  const toc = document.getElementById("sf-toc");
  if (toc) toc.innerHTML = SF_PAGES.slice(1).map(p => `
    <a class="toc-card" href="${p.file}"><span class="n">${p.no}</span><h4>${p.title}</h4><p>${p.desc}</p></a>`).join("");

  /* Pager */
  const pager = document.getElementById("pager");
  if (pager && idx > -1) {
    const prev = SF_PAGES[idx - 1], next = SF_PAGES[idx + 1];
    pager.className = "pager";
    pager.innerHTML =
      (prev ? `<a class="prev" href="${prev.file}"><small>← 上一頁</small><b>${prev.no} ${prev.title}</b></a>` : "") +
      (next ? `<a class="next" href="${next.file}"><small>下一頁 →</small><b>${next.no} ${next.title}</b></a>`
            : `<a class="next" href="../science.html"><small>延伸閱讀 →</small><b>研討會專題：科學教育的反思</b></a>`);
  }

  /* Footer */
  const footer = document.getElementById("site-footer");
  if (footer) footer.outerHTML = `
    <footer class="site-footer"><div class="inner">
      <div>香港大學教育學院 PISA 香港研究團隊<br>資料來源：OECD《PISA 2025 Results (Volume I): Future-Ready Students》及研究團隊分析。</div>
      <div><a href="index.html">系列首頁</a> · <a href="../index.html">研討會專題</a> · <a href="#top">回到頁頂 ↑</a></div>
    </div></footer>`;

  /* Table wrapper */
  document.querySelectorAll(".content table").forEach(t => {
    if (!t.parentElement.classList.contains("table-wrap")) {
      const w = document.createElement("div"); w.className = "table-wrap";
      t.parentNode.insertBefore(w, t); w.appendChild(t);
    }
  });

  /* Progress bar */
  const bar = document.querySelector(".progress span");
  const onScroll = () => {
    const h = document.documentElement, max = h.scrollHeight - h.clientHeight;
    if (bar) bar.style.width = (max > 0 ? h.scrollTop / max * 100 : 0) + "%";
  };
  window.addEventListener("scroll", onScroll, { passive: true }); onScroll();

  /* Tabs */
  document.querySelectorAll("[data-tabs]").forEach(box => {
    const btns = box.querySelectorAll(".tab-btn"), panels = box.querySelectorAll(".tab-panel");
    btns.forEach((b, i) => b.addEventListener("click", () => {
      btns.forEach((x, j) => { x.setAttribute("aria-selected", i === j); panels[j].hidden = i !== j; });
    }));
  });

  /* Diverging chart */
  const chart = document.getElementById("idx-chart");
  if (chart) {
    const DATA = {
      STBELSCIE: { label: "科學本質信念", HKG: 0.02, SGP: 0.20,
        note: "<b>科學本質信念：</b>香港（0.02）與 OECD 平均相若；新加坡（0.20）較高。兩地均有逾九成學生同意「資訊應經其他可靠來源查證」。" },
      JOYSCIE: { label: "科學學習樂趣", HKG: -0.32, SGP: -0.11,
        note: "<b>科學學習樂趣：</b>兩地均低於 OECD 平均，香港（−0.32）是三者中最低。高成績不一定帶來高興趣，這是東亞體系常見的「成績與樂趣落差」。" },
      EFFSCIE: { label: "科學自我效能感", HKG: -0.19, SGP: 0.31,
        note: "<b>科學自我效能感：</b>新加坡學生（0.31）對完成科學任務較有信心；香港學生（−0.19）的自評則較保守。" }
    };
    const row = (name, v, cls) => {
      const w = Math.min(Math.abs(v) / 0.5 * 50, 50), left = v < 0 ? 50 - w : 50;
      return `<div class="dv-row ${cls}"><span class="dv-name">${name}</span>
        <div class="dv-track"><i data-l="${left}" data-w="${w}" style="left:50%"></i><b></b></div>
        <span class="dv-val">${v > 0 ? "+" : v < 0 ? "−" : ""}${Math.abs(v).toFixed(2)}</span></div>`;
    };
    const note = document.getElementById("idx-note");
    const render = key => {
      const keys = key === "all" ? Object.keys(DATA) : [key];
      chart.innerHTML = keys.map(k => `<div class="dv-group"><div class="dv-title">${DATA[k].label}<small>${k}</small></div>
        ${row("香港", DATA[k].HKG, "hk")}${row("新加坡", DATA[k].SGP, "sg")}${row("OECD 平均", 0, "oecd")}</div>`).join("") +
        `<div class="dv-scale"><span></span><div><span>−0.5</span><span>0</span><span>+0.5</span></div><span></span></div>`;
      requestAnimationFrame(() => requestAnimationFrame(() =>
        chart.querySelectorAll(".dv-track i").forEach(i => { i.style.left = i.dataset.l + "%"; i.style.width = i.dataset.w + "%"; })));
      note.innerHTML = key === "all"
        ? "<b>整體圖像：</b>香港在科學本質信念上與 OECD 相若，但在<b>樂趣</b>及<b>自我效能感</b>兩個情意指標上均低於平均。點選上方按鈕查看個別指數的解讀。"
        : DATA[key].note;
    };
    document.querySelectorAll(".chip[data-key]").forEach(c => c.addEventListener("click", () => {
      document.querySelectorAll(".chip[data-key]").forEach(x => x.classList.toggle("active", x === c));
      render(c.dataset.key);
    }));
    render("all");
  }

  /* Profile quiz */
  const quiz = document.getElementById("profile-quiz");
  if (quiz) {
    const ans = {};
    const P = {
      "10": { n: "強科學取向", d: "重視查證來源，並且不會以常識凌駕科學研究。OECD 平均約 46% 學生屬此類，平均科學成績最高（約 532 分）。" },
      "11": { n: "非限制取向", d: "認同查證來源，但同時認為應多依賴常識。OECD 平均約 37% 學生屬此類（平均約 466 分）。在香港、日本等高表現體系，這類學生的比例相對較高。" },
      "00": { n: "信任科學但不查證", d: "相信科學研究，卻不認為需要查證資訊來源。OECD 平均約 11% 學生屬此類。在 AI 與社交媒體時代，「不查證」本身就是風險。" },
      "01": { n: "不查證且依賴常識", d: "既不查證來源，亦傾向以常識取代科學研究。OECD 平均約 5% 學生屬此類，是最需要支援的群組。" }
    };
    quiz.querySelectorAll(".opt").forEach(b => b.addEventListener("click", () => {
      ans[b.dataset.q] = b.dataset.v;
      quiz.querySelectorAll(`.opt[data-q="${b.dataset.q}"]`).forEach(x => x.classList.toggle("sel", x === b));
      if (ans.check !== undefined && ans.cs !== undefined) {
        const key = ans.check + ans.cs, p = P[key];
        document.querySelectorAll(".matrix .cell").forEach(c => c.classList.toggle("on", c.dataset.key === key));
        const r = document.getElementById("quiz-result");
        r.hidden = false;
        r.innerHTML = `<h4>你的回答對應：${p.n}</h4><p>${p.d}</p><p class="table-note">此小測只供理解概念，並非 PISA 的正式量度。</p>`;
      }
    }));
  }

  /* Collaboration checklist */
  const cl = document.getElementById("collab-check");
  if (cl) {
    const boxes = [...cl.querySelectorAll("input")], fill = cl.querySelector(".meter span"), msg = cl.querySelector(".meter-msg");
    const upd = () => {
      const n = boxes.filter(b => b.checked).length, t = boxes.length;
      fill.style.width = n / t * 100 + "%";
      msg.textContent = n === 0 ? "勾選你的協作任務已具備的元素。"
        : n <= 2 ? `${n}/${t}：任務可能偏向「表面協作」，學生容易忙於分工而少於思考。`
        : n <= 4 ? `${n}/${t}：已有良好基礎，可再加強證據要求或總結反思。`
        : `${n}/${t}：任務具備高度認知激發的特質，值得與同儕分享！`;
    };
    boxes.forEach(b => b.addEventListener("change", upd)); upd();
  }
});
