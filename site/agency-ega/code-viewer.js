/* ===== R script viewer: sections · search · function index · lazy syntax highlighting ===== */
(() => {
  const INFO = {
    "HEADER":                   { zh: "檔頭與套件",         desc: "分析流程概覽、版本修訂說明及所需 R 套件", g: "setup" },
    "CONFIGURATION":            { zh: "設定區",             desc: "全部可調整參數；重現或改編分析時只需修改此處", g: "setup" },
    "CONSTANTS":                { zh: "常數",               desc: "可能值數目、PISA 缺失值代碼、置信水平臨界值", g: "setup" },
    "METADATA HELPERS":         { zh: "數據清理函數",       desc: "解析變項標籤、辨識缺失代碼、清理 WLE 指數、計算題目合成分數", g: "helper" },
    "NETWORK / DESIGN HELPERS": { zh: "網絡與抽樣設計函數", desc: "加權及條件相關、Fay-BRR + Rubin 合併、正定修正、EGA 包裝、標籤對齊、穩定性表", g: "helper" },
    "PLOT HELPERS":             { zh: "繪圖函數",           desc: "穩定性圖、森林圖及網絡圖（外環、分色填充、區域、標籤避讓）", g: "helper" },
    "1":  { zh: "載入數據",               desc: "讀取學生數據、國家對照表及變項元數據", g: "main" },
    "2":  { zh: "篩選地區及群組",         desc: "保留香港學生；檢查抽樣設計變項是否齊全", g: "main" },
    "3":  { zh: "建立節點",               desc: "14 個 WLE 指數 + 2 個題目合成分數 + 科學可能值", g: "main" },
    "4":  { zh: "分析樣本與流失診斷",     desc: "單一完整個案樣本；比較保留與排除的學生", g: "main" },
    "5":  { zh: "冗餘檢查（UVA，可選）",  desc: "檢查節點是否重複量度同一概念；本研究未啟用", g: "main" },
    "6":  { zh: "以抽樣設計為本的估計",   desc: "10 個可能值 × 81 組權重：相關、偏相關及可預測度", g: "main" },
    "7":  { zh: "EBIC 樣本量與正定修正",  desc: "名義／Kish／設計效應樣本量；必要時修正相關矩陣", g: "main" },
    "8":  { zh: "主要 EGA",               desc: "EBICglasso + Leiden；網絡負荷及 TEFI", g: "main" },
    "9":  { zh: "敏感度分析",             desc: "3 種 EBIC 樣本量 × 3 種社群偵測演算法", g: "main" },
    "10": { zh: "穩定性：學校群集自助抽樣", desc: "分層內重抽學校 500 次；節點及維度穩定性", g: "main" },
    "11": { zh: "出版表格",               desc: "連線、節點、可預測度、描述統計及流失表；輸出 CSV", g: "main" }
  };
  const GROUPS = [["setup", "設定"], ["helper", "輔助函數"], ["main", "主流程"]];
  const KW = new Set("function if else for while repeat break next return in".split(" "));
  const CONST = new Set("TRUE FALSE NULL NA NA_real_ NA_integer_ NA_character_ Inf NaN".split(" "));
  const TOK = /(#.*$)|("(?:[^"\\]|\\.)*"?|'(?:[^'\\]|\\.)*'?)|(`[^`]*`)|(\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?L?\b)|([A-Za-z.][A-Za-z0-9._]*)|(<<-|<-|\|>|%[^%\s]*%)/g;
  const FN = /^(`[^`]+`|[A-Za-z.][A-Za-z0-9._]*)\s*<-\s*function\b/;
  const esc = s => s.replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

  const root = document.getElementById("rcode");
  if (!root) return;
  const body = root.querySelector(".cv-body"), toc = root.querySelector(".cv-toc");
  const q = root.querySelector(".cv-search"), cnt = root.querySelector(".cv-count");
  const fnSel = root.querySelector(".cv-fn"), stats = root.querySelector(".cv-stats");
  let L = [], S = [], hits = [], hitPos = -1, tocLinks = [];

  function hl(line) {
    let out = "", last = 0;
    for (const m of line.matchAll(TOK)) {
      const t = m[0]; let c = "";
      out += esc(line.slice(last, m.index));
      if (m[1]) c = "c"; else if (m[2] || m[3]) c = "s"; else if (m[4]) c = "n";
      else if (m[5]) c = KW.has(t) ? "k" : CONST.has(t) ? "v" : /^\s*\(/.test(line.slice(m.index + t.length)) ? "f" : "";
      else if (m[6]) c = "o";
      out += c ? `<span class="t-${c}">${esc(t)}</span>` : esc(t);
      last = m.index + t.length;
    }
    return out + esc(line.slice(last));
  }

  function parse(src) {
    const lines = src.replace(/\r\n?/g, "\n").split("\n");
    if (lines.length && lines[lines.length - 1] === "") lines.pop();
    const RULE = /^#\s*={8,}\s*$/, TITLE = /^#\s*={2,}\s+(.+?)\s+={2,}\s*$/;
    const starts = [];
    for (let i = 0; i < lines.length - 1; i++)
      if (RULE.test(lines[i]) && TITLE.test(lines[i + 1])) starts.push({ at: i, name: lines[i + 1].match(TITLE)[1].trim() });
    const secs = [], first = starts.length ? starts[0].at : lines.length;
    if (first > 0) secs.push({ name: "HEADER", from: 0, to: first });
    starts.forEach((s, k) => secs.push({ name: s.name, from: s.at, to: k + 1 < starts.length ? starts[k + 1].at : lines.length }));
    secs.forEach(s => { const m = s.name.match(/^(\d+)\./); s.num = m ? m[1] : null; s.key = m ? m[1] : s.name.toUpperCase(); });
    return { lines, secs };
  }
  const info = s => INFO[s.key] || { zh: s.name, desc: "", g: "main" };

  function copyText(t, btn, label) {
    const done = () => { btn.textContent = "已複製 ✓"; setTimeout(() => btn.textContent = label, 1500); };
    if (navigator.clipboard && window.isSecureContext) navigator.clipboard.writeText(t).then(done);
    else { const a = document.createElement("textarea"); a.value = t; document.body.appendChild(a); a.select();
      document.execCommand("copy"); a.remove(); done(); }
  }

  function render(i) {
    const s = S[i]; if (s.done) return;
    let html = "";
    for (let j = s.from; j < s.to; j++) html += `<span class="ln" id="L${j + 1}" data-n="${j + 1}">${hl(L[j]) || " "}</span>`;
    s.el.querySelector("pre").innerHTML = html; s.done = true; mark(i);
  }
  function mark(i) {
    const s = S[i]; if (!s.done) return;
    s.el.querySelectorAll(".ln.hit").forEach(e => e.classList.remove("hit"));
    (s.hits || []).forEach(j => document.getElementById("L" + (j + 1))?.classList.add("hit"));
  }
  function open(i, scroll) {
    S[i].el.open = true; render(i);
    if (scroll) S[i].el.scrollIntoView({ behavior: "smooth", block: "start" });
  }
  function jump(n) {
    const i = S.findIndex(s => n - 1 >= s.from && n - 1 < s.to); if (i < 0) return;
    open(i);
    const el = document.getElementById("L" + n); if (!el) return;
    el.scrollIntoView({ behavior: "smooth", block: "center" });
    el.classList.remove("flash"); void el.offsetWidth; el.classList.add("flash");
  }

  function search(term) {
    const t = term.trim().toLowerCase(), on = t.length >= 2;
    hits = []; hitPos = -1;
    S.forEach((s, i) => {
      s.hits = [];
      if (on) for (let j = s.from; j < s.to; j++) if (L[j].toLowerCase().includes(t)) s.hits.push(j);
      hits.push(...s.hits.map(j => j + 1));
      s.el.classList.toggle("dim", on && !s.hits.length);
      const b = s.el.querySelector(".cv-hits"), tb = tocLinks[i].querySelector(".hits");
      b.hidden = tb.hidden = !s.hits.length; b.textContent = tb.textContent = s.hits.length;
      tocLinks[i].classList.toggle("has-hit", s.hits.length > 0);
      if (s.hits.length) open(i);
      mark(i);
    });
    cnt.textContent = !on ? "" : hits.length ? `共 ${hits.length} 處 · 按 Enter 逐一跳至` : "找不到結果";
  }

  function build() {
    body.innerHTML = S.map((s, i) => {
      const f = info(s), tag = s.num ? "§" + s.num : f.g === "setup" ? "設定" : "函數";
      return `<details class="cv-sec g-${f.g}" id="cv-sec-${i}">
        <summary><span class="cv-tag">${tag}</span>
          <span class="cv-title"><b>${esc(f.zh)}</b><small>${f.desc ? esc(f.desc) + " · " : ""}<code>${esc(s.name)}</code></small></span>
          <span class="cv-meta"><span class="cv-hits" hidden></span>L${s.from + 1}–${s.to} · ${s.to - s.from} 行</span></summary>
        <div class="cv-secbar"><button type="button" class="cv-mini" data-copy="${i}">複製本節</button><button type="button" class="cv-mini" data-close="${i}">收起 ▲</button></div>
        <div class="cv-code"><pre></pre></div></details>`;
    }).join("");
    S.forEach((s, i) => { s.el = document.getElementById("cv-sec-" + i); s.el.addEventListener("toggle", () => s.el.open && render(i)); });

    toc.innerHTML = GROUPS.map(([g, label]) => {
      const items = S.map((s, i) => [s, i]).filter(([s]) => info(s).g === g);
      return items.length ? `<h5>${label}</h5>` + items.map(([s, i]) =>
        `<a href="#cv-sec-${i}" data-sec="${i}"><span>${s.num ? s.num + ". " : ""}${esc(info(s).zh)}</span><small class="hits" hidden></small></a>`).join("") : "";
    }).join("");
    tocLinks = S.map((_, i) => toc.querySelector(`[data-sec="${i}"]`));
    tocLinks.forEach(a => a.addEventListener("click", e => { e.preventDefault(); open(+a.dataset.sec, true); }));

    const fns = []; L.forEach((t, j) => { const m = t.match(FN); if (m) fns.push([m[1], j + 1]); });
    fnSel.innerHTML = `<option value="">跳至函數（${fns.length}）…</option>` +
      fns.map(([n, ln]) => `<option value="${ln}">${esc(n)}　L${ln}</option>`).join("");
    fnSel.onchange = () => { if (fnSel.value) jump(+fnSel.value); fnSel.value = ""; };
    stats.textContent = `${L.length.toLocaleString()} 行 · ${S.length} 節 · ${fns.length} 個函數 · 點擊標題展開，代碼只在展開時載入`;

    body.addEventListener("click", e => {
      const c = e.target.closest("[data-copy]"), x = e.target.closest("[data-close]");
      if (c) { const s = S[+c.dataset.copy]; copyText(L.slice(s.from, s.to).join("\n"), c, "複製本節"); }
      if (x) { const s = S[+x.dataset.close]; s.el.open = false; s.el.scrollIntoView({ block: "nearest" }); }
    });
    root.querySelector("[data-act=expand]").onclick = () => S.forEach((_, i) => open(i));
    root.querySelector("[data-act=collapse]").onclick = () => S.forEach(s => s.el.open = false);

    let tm; q.addEventListener("input", () => { clearTimeout(tm); tm = setTimeout(() => search(q.value), 200); });
    q.addEventListener("keydown", e => {
      if (e.key === "Enter" && hits.length) { e.preventDefault(); hitPos = (hitPos + 1) % hits.length;
        jump(hits[hitPos]); cnt.textContent = `第 ${hitPos + 1} / ${hits.length} 處`; }
      if (e.key === "Escape") { q.value = ""; search(""); }
    });

    const fromHash = () => { const h = location.hash.match(/^#L(\d+)$/); if (h) jump(+h[1]); };
    window.addEventListener("hashchange", fromHash); fromHash();
  }

  /* Step buttons: <button data-code="6"> or data-code="NETWORK / DESIGN HELPERS" */
  document.querySelectorAll("[data-code]").forEach(b => b.addEventListener("click", () => {
    const i = S.findIndex(s => s.key === b.dataset.code.toUpperCase());
    if (i > -1) open(i, true); else document.getElementById("code")?.scrollIntoView({ behavior: "smooth" });
  }));

  (async () => {
    const inline = document.getElementById("r-inline");
    let src = inline && inline.textContent.trim() ? inline.textContent : null;
    if (!src) {
      try { const r = await fetch(root.dataset.src, { cache: "no-cache" }); if (!r.ok) throw new Error(r.status); src = await r.text(); }
      catch (e) {
        body.innerHTML = `<div class="callout warn"><div class="callout-title">未能載入 R 代碼</div><p>${
          location.protocol === "file:"
            ? "以 file:// 直接開啟網頁時，瀏覽器會阻擋讀取外部檔案。請以本機伺服器預覽（在網站根目錄執行 <code>python -m http.server</code>，再開啟 http://localhost:8000），或"
            : `請確認檔案 <code>${esc(root.dataset.src)}</code> 已上載，或`}<a href="${esc(root.dataset.src)}" download>直接下載 R 檔</a>。</p></div>`;
        return;
      }
    }
    ({ lines: L, secs: S } = parse(src));
    build();
  })();
})();
