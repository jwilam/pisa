/* ===== Interactive PISA trend chart: Hong Kong vs OECD-23 ===== */
(() => {
  const D = {
    science: {
      label: "科學", cls: "sci",
      years: [2006, 2009, 2012, 2015, 2018, 2022, 2025],
      hk:    [542, 549, 555, 523, 517, 520, 496],
      oecd:  [503, 506, 505, 497, 493, 491, 486],
      major: [2006, 2015, 2025],
      story: "香港科學成績於 2012 年達 555 分高峰，2015 年急跌 32 分；2015 至 2022 年間的變化在統計上並不顯著；2025 年再跌 24 分至 496 分，是歷屆最低。同期 OECD-23 平均只下跌 5 分，香港與 OECD-23 的差距由 2012 年的 50 分收窄至 10 分。",
      dist: { years: [2025], high: [9.1], low: [20.9],
        note: "科學暫只列出 2025 年數據；高表現學生比例自 2015 年起大致穩定在約一成，低表現學生比例則為歷屆最高。" }
    },
    math: {
      label: "數學", cls: "math",
      years: [2003, 2006, 2009, 2012, 2015, 2018, 2022, 2025],
      hk:    [550, 547, 555, 561, 548, 551, 540, 522],
      oecd:  [502, 501, 502, 499, 496, 496, 480, 469],
      major: [2003, 2012, 2022],
      story: "數學是香港最具優勢的範疇，2025 年仍比 OECD-23 平均高 53 分。不過，成績在 2018 年後連續下跌，由 551 分降至 522 分，為歷屆最低。OECD-23 平均同期亦明顯下滑，差距變化不大，但香港本身的下行趨勢值得警惕。",
      dist: { years: [2012, 2018, 2022, 2025], high: [33.7, 29.0, 27.2, 20.7], low: [8.5, 9.2, 13.8, 17.0] }
    },
    reading: {
      label: "閱讀", cls: "read",
      years: [2000, 2003, 2006, 2009, 2012, 2015, 2018, 2022, 2025],
      hk:    [526, 510, 536, 533, 543, 527, 524, 500, 480], /* 待核實：2012 年 543（圖表）vs 545（報告文字） */
      oecd:  [500, 497, 495, 499, 501, 497, 493, 482, 466],
      major: [2000, 2009, 2018],
      story: "閱讀是跌幅最大的範疇。2003 年曾跌至 510 分，其後回升至 2012 年的高峰；但 2012 年後持續下滑，單在 2018 至 2025 年間便下跌 44 分。與 OECD-23 的差距由 2012 年的 42 分收窄至 14 分，逐漸趨向 OECD 平均水平。",
      dist: { years: [2012, 2018, 2022, 2025], high: [16.8, 14.8, 9.0, 5.8], low: [6.8, 12.6, 17.5, 22.0] }
    }
  };
  const CMP_YEARS = [2012, 2015, 2018, 2022, 2025];
  const CMP_STORY = "以 2012 年為基準，三個範疇均持續下跌：閱讀 −63 分、科學 −59 分、數學 −39 分。三科走勢方向一致，反映問題並非個別學科獨有；2018 年後，閱讀的跌勢最急。";

  const NS = "http://www.w3.org/2000/svg";
  const W = 760, H = 420, M = { t: 34, r: 34, b: 46, l: 58 };
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const $ = s => document.querySelector(s);
  const state = { view: "science", gap: true, major: true, labels: true, idx: null };
  let cur = null;

  const el = (tag, a = {}, p) => { const e = document.createElementNS(NS, tag); for (const k in a) e.setAttribute(k, a[k]); if (p) p.appendChild(e); return e; };
  const txt = (tag, a, p, s) => { const e = el(tag, a, p); e.textContent = s; return e; };
  const fmt = n => n === 0 ? "0" : (n > 0 ? "+" : "−") + Math.abs(n);

  function animate(p) {
    if (reduce) return;
    const len = p.getTotalLength();
    p.style.strokeDasharray = len; p.style.strokeDashoffset = len;
    p.getBoundingClientRect();
    p.style.transition = "stroke-dashoffset 1.1s ease"; p.style.strokeDashoffset = 0;
  }

  function seriesFor(view) {
    if (view !== "compare") {
      const d = D[view];
      return { years: d.years, yMin: 460, yMax: 570, ticks: [460, 480, 500, 520, 540, 560], x1: 2026,
        series: [{ name: "香港", cls: "hk", vals: d.hk }, { name: "OECD-23 平均", cls: "oecd", vals: d.oecd }] };
    }
    return { years: CMP_YEARS, yMin: -70, yMax: 10, ticks: [-60, -40, -20, 0], x1: 2028,
      series: Object.values(D).map(d => {
        const base = d.hk[d.years.indexOf(2012)];
        return { name: d.label, cls: d.cls, vals: CMP_YEARS.map(y => d.hk[d.years.indexOf(y)] - base) };
      }) };
  }

  function drawChart() {
    const svg = $("#trend-svg"); svg.innerHTML = "";
    const isCmp = state.view === "compare";
    const { years, series, yMin, yMax, ticks, x1 } = seriesFor(state.view);
    const x0 = years[0] - 1;
    const X = v => M.l + (v - x0) / (x1 - x0) * (W - M.l - M.r);
    const Y = v => M.t + (yMax - v) / (yMax - yMin) * (H - M.t - M.b);

    const g = el("g", { class: "t-grid t-axis" }, svg);
    ticks.forEach(t => {
      el("line", { x1: M.l, x2: W - M.r, y1: Y(t), y2: Y(t), class: isCmp && t === 0 ? "t-zero" : "" }, g);
      txt("text", { x: M.l - 10, y: Y(t) + 4, "text-anchor": "end" }, g, isCmp ? fmt(t) : t);
    });
    years.forEach(yr => txt("text", { x: X(yr), y: H - M.b + 22, "text-anchor": "middle" }, g, yr));
    txt("text", { x: 14, y: M.t + (H - M.t - M.b) / 2, class: "t-axis-title", "text-anchor": "middle",
      transform: `rotate(-90 14 ${M.t + (H - M.t - M.b) / 2})` }, svg, isCmp ? "相對 2012 年的變化（分）" : "平均分");

    if (!isCmp && state.major)
      D[state.view].major.forEach(yr => el("rect", { x: X(yr) - 15, y: M.t, width: 30, height: H - M.t - M.b, rx: 6, class: "t-band" }, svg));

    if (!isCmp && state.gap) {
      const top = years.map((yr, i) => `${X(yr)},${Y(series[0].vals[i])}`);
      const bot = years.map((yr, i) => `${X(yr)},${Y(series[1].vals[i])}`).reverse();
      el("polygon", { points: top.concat(bot).join(" "), class: "t-gap" }, svg);
    }

    series.forEach(s => animate(el("path", {
      d: years.map((yr, i) => `${i ? "L" : "M"}${X(yr)},${Y(s.vals[i])}`).join(""), class: `t-line ${s.cls}` }, svg)));

    series.forEach((s, si) => years.forEach((yr, i) => {
      el("circle", { cx: X(yr), cy: Y(s.vals[i]), r: s.cls === "oecd" ? 4.5 : 5.5, class: `t-dot ${s.cls}`, "data-i": i }, svg);
      if (state.labels && !isCmp)
        txt("text", { x: X(yr), y: Y(s.vals[i]) + (si === 0 ? -11 : 20), "text-anchor": "middle", class: `t-label ${s.cls}` }, svg, s.vals[i]);
    }));

    if (isCmp) series.forEach(s => {
      const last = s.vals[s.vals.length - 1];
      txt("text", { x: X(2025) + 12, y: Y(last) + 4, class: `t-label ${s.cls}` }, svg, `${s.name} ${fmt(last)}`);
    });
    else {
      const hk = series[0].vals, pi = hk.indexOf(Math.max(...hk));
      txt("text", { x: X(years[pi]), y: Y(hk[pi]) - (state.labels ? 28 : 14), "text-anchor": "middle", class: "t-peak" }, svg, "▼ 高峰");
    }

    const guide = el("line", { class: "t-guide", x1: -20, x2: -20, y1: M.t, y2: H - M.b }, svg);
    const hit = el("rect", { x: M.l - 10, y: 0, width: W - M.l - M.r + 20, height: H, fill: "transparent" }, svg);
    cur = { years, series, X, Y, guide, isCmp, svg };

    const near = clientX => {
      const r = svg.getBoundingClientRect(), x = (clientX - r.left) / r.width * W;
      let b = 0; years.forEach((yr, i) => { if (Math.abs(X(yr) - x) < Math.abs(X(years[b]) - x)) b = i; });
      return b;
    };
    hit.addEventListener("mousemove", e => show(near(e.clientX)));
    hit.addEventListener("mouseleave", hide);
    hit.addEventListener("touchstart", e => show(near(e.touches[0].clientX)), { passive: true });

    svg.setAttribute("aria-label", isCmp
      ? "三個範疇相對 2012 年的分數變化折線圖"
      : `香港與 OECD-23 平均的${D[state.view].label}成績趨勢折線圖，${years[0]} 至 2025 年`);
    state.idx = null;
  }

  function show(i) {
    if (!cur) return;
    state.idx = i;
    const { years, series, X, Y, guide, isCmp, svg } = cur, yr = years[i];
    guide.setAttribute("x1", X(yr)); guide.setAttribute("x2", X(yr));
    svg.querySelectorAll(".t-dot").forEach(d => d.classList.toggle("active", +d.dataset.i === i));

    let html = `<b>${yr} 年</b>`;
    if (isCmp) html += series.map(s => `<br>${s.name}：${fmt(s.vals[i])} 分`).join("");
    else {
      const hk = series[0].vals[i], oe = series[1].vals[i];
      html += `<br>香港：${hk}　OECD-23：${oe}<br>差距：${fmt(hk - oe)} 分`;
      if (i > 0) html += `<br>較上一輪：${fmt(hk - series[0].vals[i - 1])} 分`;
      if (D[state.view].major.includes(yr)) html += `<br>★ 主要範疇年份`;
    }
    const tip = $("#trend-tip"), box = $(".chart-box");
    const r = svg.getBoundingClientRect(), br = box.getBoundingClientRect();
    const topVal = Math.max(...series.map(s => s.vals[i]));
    let left = r.left - br.left + X(yr) / W * r.width;
    left = Math.max(95, Math.min(br.width - 95, left));
    tip.style.left = left + "px";
    tip.style.top = (r.top - br.top + Y(topVal) / H * r.height - 8) + "px";
    tip.innerHTML = html; tip.classList.add("show");
    $("#trend-status").textContent = tip.textContent;
  }
  function hide() {
    $("#trend-tip").classList.remove("show");
    if (cur) { cur.guide.setAttribute("x1", -20); cur.guide.setAttribute("x2", -20);
      cur.svg.querySelectorAll(".t-dot.active").forEach(d => d.classList.remove("active")); }
  }

  function drawStats() {
    const box = $("#trend-stats");
    const card = (v, s, alert, small) => `<div class="stat${alert ? " alert" : ""}"><b>${v}</b><span>${s}</span>${small ? `<small>${small}</small>` : ""}</div>`;
    if (state.view === "compare") {
      box.innerHTML = Object.values(D).map(d => {
        const ch = d.hk[d.hk.length - 1] - d.hk[d.years.indexOf(2012)];
        return card(fmt(ch), `${d.label}：2012 → 2025`, true);
      }).join("");
      return;
    }
    const d = D[state.view], n = d.hk.length;
    const max = Math.max(...d.hk), pi = d.hk.indexOf(max), last = d.hk[n - 1];
    const gapPeak = max - d.oecd[pi], gapNow = last - d.oecd[n - 1];
    box.innerHTML =
      card(max, `${d.years[pi]} 年高峰`) +
      card(last, "2025 年平均分") +
      card(fmt(last - max), "自高峰的變化", true) +
      card(fmt(last - d.hk[n - 2]), "2022–2025 變化", true, `OECD-23：${fmt(d.oecd[n - 1] - d.oecd[n - 2])}`) +
      card(`${fmt(gapPeak)} → ${fmt(gapNow)}`, "與 OECD-23 的差距", false, `${d.years[pi]} → 2025`);
  }

  function drawLegend() {
    const L = $("#trend-legend");
    L.innerHTML = state.view === "compare"
      ? Object.values(D).map(d => `<span><i style="background:var(--c-${d.cls})"></i>${d.label}</span>`).join("") +
        `<span><i style="background:var(--ink);height:2px"></i>2012 年基準線</span>`
      : `<span><i style="background:var(--green)"></i>香港</span><span><i style="background:var(--gold)"></i>OECD-23 平均</span>` +
        `<span><i class="box" style="background:rgba(18,122,106,.18)"></i>兩者差距</span>` +
        `<span><i class="box" style="background:rgba(201,162,39,.25)"></i>主要範疇年份</span>`;
  }

  function drawDist() {
    const wrap = $("#dist-wrap");
    if (state.view === "compare") { wrap.hidden = true; return; }
    wrap.hidden = false;
    const d = D[state.view].dist, MAX = 40;
    $("#dist-title").textContent = `${D[state.view].label}：高表現與低表現學生比例`;
    $("#dist-body").innerHTML =
      `<div class="dist-head"><span>年份</span><span>高表現（第 5 級或以上）</span><span>低表現（未達第 2 級）</span></div>` +
      d.years.map((y, i) => `<div class="dist-row"><b>${y}</b>
        <div class="dist-bar high"><i data-w="${d.high[i] / MAX * 100}"></i><span>${d.high[i].toFixed(1)}%</span></div>
        <div class="dist-bar low"><i data-w="${d.low[i] / MAX * 100}"></i><span>${d.low[i].toFixed(1)}%</span></div></div>`).join("") +
      (d.note ? `<p class="table-note" style="margin-top:.6rem">${d.note}</p>` : "");
    requestAnimationFrame(() => requestAnimationFrame(() =>
      $("#dist-body").querySelectorAll(".dist-bar i").forEach(i => i.style.width = i.dataset.w + "%")));
  }

  function drawTable() {
    const t = $("#trend-table");
    if (state.view === "compare") {
      t.innerHTML = `<tr><th class="num">年份</th>${Object.values(D).map(d => `<th class="num">${d.label}</th>`).join("")}</tr>` +
        CMP_YEARS.map(y => `<tr><td class="num">${y}</td>${Object.values(D).map(d =>
          `<td class="num">${fmt(d.hk[d.years.indexOf(y)] - d.hk[d.years.indexOf(2012)])}</td>`).join("")}</tr>`).join("");
      return;
    }
    const d = D[state.view];
    t.innerHTML = `<tr><th class="num">年份</th><th class="num">香港</th><th class="num">OECD-23</th><th class="num">差距</th><th class="num">香港較上一輪</th></tr>` +
      d.years.map((y, i) => `<tr${d.major.includes(y) ? ' class="hl"' : ""}><td class="num">${y}${d.major.includes(y) ? " ★" : ""}</td>
        <td class="num">${d.hk[i]}</td><td class="num">${d.oecd[i]}</td><td class="num">${fmt(d.hk[i] - d.oecd[i])}</td>
        <td class="num${i && d.hk[i] < d.hk[i - 1] ? " neg" : ""}">${i ? fmt(d.hk[i] - d.hk[i - 1]) : "—"}</td></tr>`).join("");
  }

  function render() {
    document.querySelectorAll(".trend-tabs button").forEach(b => b.setAttribute("aria-selected", b.dataset.view === state.view));
    document.querySelectorAll(".toggles .single-only").forEach(l => l.classList.toggle("off", state.view === "compare"));
    $("#trend-story").innerHTML = `<p>${state.view === "compare" ? CMP_STORY : D[state.view].story}</p>`;
    hide(); drawStats(); drawLegend(); drawChart(); drawDist(); drawTable();
  }

  document.addEventListener("DOMContentLoaded", () => {
    if (!$("#trend-svg")) return;
    const root = document.documentElement.style;
    root.setProperty("--c-sci", "#127a6a"); root.setProperty("--c-math", "#c9a227"); root.setProperty("--c-read", "#7a4fb0");

    const fromHash = () => { const h = location.hash.slice(1); if (D[h] || h === "compare") state.view = h; };
    fromHash();

    document.querySelectorAll(".trend-tabs button").forEach(b => b.addEventListener("click", () => {
      state.view = b.dataset.view; history.replaceState(null, "", "#" + state.view); render();
    }));
    window.addEventListener("hashchange", () => { fromHash(); render(); });

    [["#tg-gap", "gap"], ["#tg-major", "major"], ["#tg-labels", "labels"]].forEach(([id, k]) =>
      $(id).addEventListener("change", e => { state[k] = e.target.checked; drawChart(); }));

    const svg = $("#trend-svg");
    svg.addEventListener("keydown", e => {
      if (!cur) return;
      const n = cur.years.length;
      if (e.key === "ArrowRight") { show(state.idx === null ? 0 : Math.min(n - 1, state.idx + 1)); e.preventDefault(); }
      if (e.key === "ArrowLeft")  { show(state.idx === null ? n - 1 : Math.max(0, state.idx - 1)); e.preventDefault(); }
      if (e.key === "Escape") hide();
    });
    svg.addEventListener("blur", hide);

    let t; window.addEventListener("resize", () => { clearTimeout(t); t = setTimeout(hide, 100); });
    render();
  });
})();
