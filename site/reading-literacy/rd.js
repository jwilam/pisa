/* =========================================================
   PISA HKU · 閱讀素養專題：頁面資料與導覽（不載入 js/site.js）
   ========================================================= */
window.RD = (() => {
    const CH = {
    f:{n:'Ⅰ', zh:'框架',   en:'Framework',      c:'#2a7f8f', bg:'#eaf4f5'},
    m:{n:'Ⅱ', zh:'多文本', en:'Multiple Texts', c:'#b8860b', bg:'#fbf4e2'},
    e:{n:'Ⅲ', zh:'審辨',   en:'Epistemic',      c:'#2f5d50', bg:'#e9f1ed'},
    c:{n:'Ⅳ', zh:'課堂',   en:'Classroom',      c:'#6a5a8c', bg:'#efebf5'},
    s:{n:'Ⅴ', zh:'樣例',   en:'Released Units', c:'#9a4f2c', bg:'#f8ece4'}
  };

  /* q：本頁回答的問題（u 理解、e 評鑑、j 證成）；min：閱讀分鐘 */
  const PAGES = [
    {f:'index.html',      ic:'📚', zh:'專題總覽'},
    {f:'ecosystem.html',  ch:'f', ic:'🌐', zh:'閱讀環境變了',     q:'u',   min:5,  d:'社交媒體、演算法與生成式 AI 如何改變閱讀'},
    {f:'definition.html', ch:'f', ic:'📝', zh:'閱讀素養新定義',   q:'uej', min:6,  d:'2029 定義逐詞拆解，對照 2018 年'},
    {f:'model.html',      ch:'f', ic:'🔺', zh:'讀者×文本×任務',   q:'u',   min:8,  d:'組織模型、文本分類及新增的任務限制'},
    {f:'processes.html',  ch:'f', ic:'🪜', zh:'閱讀過程與分量表', q:'ue',  min:8,  d:'四層閱讀過程、三個分量表、八個等級'},
    {f:'documents.html',  ch:'m', ic:'🧩', zh:'文件模型',         q:'u',   min:10, d:'七個環節、三個階段；AI 抹去了甚麼'},
    {f:'conflict.html',   ch:'m', ic:'⚖️', zh:'當文本互相矛盾',   q:'ej',  min:8,  d:'D-ISC：由察覺矛盾到有條件的判斷'},
    {f:'disorder.html',   ch:'e', ic:'🚨', zh:'資訊失序',         q:'e',   min:6,  d:'錯誤、虛假、惡意資訊；十四個關鍵詞'},
    {f:'vigilance.html',  ch:'e', ic:'🔍', zh:'查證與認知警覺',   q:'e',   min:8,  d:'來源及內容警覺、橫向閱讀、警號'},
    {f:'argument.html',   ch:'e', ic:'🧱', zh:'論證與推理',       q:'j',   min:8,  d:'Toulmin 論證模型；事實與意見'},
    {f:'classroom.html',  ch:'c', ic:'🏫', zh:'課堂啟示',         q:'uej', min:6,  d:'把審辨閱讀帶進各科課堂'},
    {f:'samples.html',    ch:'s', ic:'🧪', zh:'PISA 2018 公開樣例', q:'uej', min:5,  d:'四個公開單元：論壇、矛盾文本、搜尋結果、多頁網站'},
    {f:'sample.html',     ch:'s', ic:'▶️', zh:'樣例試做與評析',   q:'uej', min:30, d:'站內試做，對照題目解析、評析及文本結構圖'}
  ];
  const Q = {u:'說了甚麼？', e:'可信嗎？', j:'為何相信？'};
  const BACK = {f:'../reading.html#rl-feature', ic:'📖', zh:'08 閱讀教育的反思'};

  const cur = document.body.dataset.rd || 'index.html';
  const me = PAGES.find(p => p.f === cur) || PAGES[0];
  const ch = CH[me.ch];
  const num = p => String(PAGES.indexOf(p)).padStart(2, '0');
  const first = k => PAGES.find(p => p.ch === k);
  if (ch){ document.body.style.setProperty('--rc', ch.c); document.body.style.setProperty('--rbg', ch.bg); }

  /* 頁首：取代 #site-header */
  const hdr = document.createElement('header');
  hdr.className = 'rd-top';
  hdr.innerHTML = `<div class="in">
    <a class="rd-badge" href="../index.html" title="PISA 2025 研討會專題主頁">PISA HK</a>
    <a class="rd-ttl" href="index.html">閱讀素養專題<small>READING</small></a>
    <nav class="rd-tabs" aria-label="閱讀素養專題導覽">
      <a href="index.html" class="${cur === 'index.html' ? 'on' : ''}">00 總覽</a>
      ${Object.entries(CH).map(([k,c]) => `<a href="${first(k).f}" class="${me.ch === k ? 'on' : ''}" style="--tc:${c.c}"><span class="n">${c.n}</span>${c.zh}</a>`).join('')}
      <a class="back" href="${BACK.f}" title="返回第 08 章">↩ 08 閱讀</a>
    </nav></div>`;
  const oh = document.getElementById('site-header'); if (oh) oh.replaceWith(hdr); else document.body.prepend(hdr);

  /* 橫幅：章節標籤及三問徽章 */
  document.querySelectorAll('.rd-eyebrow:empty').forEach(e => e.textContent = ch ? `${ch.n} ${ch.zh} · ${num(me)}` : '閱讀素養專題');
  document.querySelectorAll('.rd-q').forEach(e => e.innerHTML =
    Object.entries(Q).map(([k,t]) => `<span class="${(me.q || '').includes(k) ? 'on' : ''}">${t}</span>`).join(''));

  /* 章節條 */
  const cs = document.getElementById('rd-chap');
  if (cs && ch) cs.innerHTML = `<div class="in">${PAGES.filter(p => p.ch === me.ch).map(p =>
    `<a href="${p.f}" class="${p === me ? 'on' : ''}"${p === me ? ' aria-current="page"' : ''}><span class="n">${num(p)}</span>${p.ic} ${p.zh}</a>`).join('')}</div>`;

  /* 麵包屑 */
  const cr = document.getElementById('rd-crumb');
  if (cr) cr.innerHTML = `<a href="../index.html">首頁</a> › <a href="${BACK.f}">08 閱讀</a> › ` +
    (cur === 'index.html' ? '閱讀素養專題' : `<a href="index.html">閱讀素養專題</a> › ${me.zh}`);

  /* 翻頁 */
  const pg = document.getElementById('rd-pager');
  if (pg){
    const i = PAGES.indexOf(me), pv = i === 0 ? BACK : PAGES[i-1], nx = PAGES[i+1];
    pg.innerHTML = `<a href="${pv.f}"><small>← 上一頁</small><b>${pv.ic} ${pv.zh}</b></a>` +
      (nx ? `<a class="nx" href="${nx.f}"><small>下一頁 →</small><b>${nx.ic} ${nx.zh}</b></a>`
          : `<a class="nx" href="../digital.html#mail"><small>延伸 →</small><b>💻 09 從 LDW 到 MAIL</b></a>`);
  }

  /* 頁尾：取代 #site-footer */
  const ft = document.createElement('footer');
  ft.className = 'rd-foot';
  ft.innerHTML = `<div class="in"><span>PISA 2025 研討會專題 · 閱讀素養專題</span>
    <span><a href="${BACK.f}">第 08 章</a> · <a href="../index.html">研討會主頁</a></span></div>`;
  const of = document.getElementById('site-footer'); if (of) of.replaceWith(ft); else document.body.append(ft);

  return {CH, PAGES, Q, num};
})();
