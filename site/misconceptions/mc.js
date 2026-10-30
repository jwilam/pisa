/* 先排除誤解：共用資料、導覽及工具。新增誤解時，只需在 MYTHS 加一項。 */
(function(){
  const MYTHS = [
    {id:'sampling', ic:'🎲', t:'抽樣', st:'done', href:'sampling.html',
     myth:'學校可以自行揀選學生參加 PISA，所以樣本不能代表香港',
     check:'學校以 PPS 系統抽樣抽出，學生由軟件從完整名單隨機抽出；國家中心只提供名單及執行，無權揀選或替換。',
     pages:[['sampling.html','① 誰決定誰參加？'],['sampling-pps.html','② 學校怎樣抽？'],
            ['sampling-students.html','③ 學生怎樣抽？'],['sampling-standards.html','④ 標準與抽樣誤差']]},
    {id:'schedule', ic:'📅', t:'施測日期', st:'plan',
     myth:'施測日期選得不好（例如考試季前後），令學生表現下降',
     check:'比較不同施測日期場次的表現，檢視日期與分數是否有關。'},
    {id:'effort', ic:'😴', t:'學生不投入', st:'plan',
     myth:'香港學生在 PISA「求其做」，所以分數下跌',
     check:'以作答時間等過程數據分析「不充分作答」（insufficient effort responding），並藉此介紹大型評估怎樣處理低風險測驗的作答投入。'},
    {id:'translation', ic:'🈶', t:'翻譯', st:'plan',
     myth:'中文譯本有問題，令題目對香港學生特別難',
     check:'檢視 PISA 的翻譯及驗證程序，以及個別題目在香港是否異常地難。'},
    {id:'drill', ic:'📝', t:'未有操練', st:'plan',
     myth:'學生沒有為 PISA 操練，所以考得不好',
     check:'PISA 評估在陌生情境中運用知識的素養，而非課程內容；我們會檢視「未有操練」能否解釋長期趨勢。'},
    {id:'covid', ic:'🦠', t:'疫情', st:'plan',
     myth:'表現下跌是疫情造成的',
     check:'OECD 指出疫情是全球表現下降的背景，而非成因；不少國家及地區的下跌早於疫情。'},
    {id:'trend', ic:'📉', t:'只在 2025 下跌', st:'link', href:'../trends.html',
     myth:'香港表現到 2025 年才突然下跌',
     check:'香港自 2015 年起已持續下行，並且是全球下降趨勢的一部分。'}
  ];

  /* 已讀紀錄（只存於本機） */
  const here = location.pathname.split('/').pop() || 'index.html';
  let seen = [];
  try { seen = JSON.parse(localStorage.getItem('mc-visited') || '[]'); } catch(e){}
  if (!seen.includes(here)){ seen.push(here); try { localStorage.setItem('mc-visited', JSON.stringify(seen)); } catch(e){} }

  /* 可重現的隨機數（示意圖每次相同） */
  const rng = seed => () => { seed |= 0; seed = seed + 0x6D2B79F5 | 0;
    let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296; };
  const gauss = r => { let u = 0, v = 0; while (!u) u = r(); while (!v) v = r();
    return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v); };

  window.MC = {myths: MYTHS, seen, here, rng, gauss};

  /* 子頁導覽 */
  const id = document.body.dataset.mc, nav = document.getElementById('mc-nav'), nx = document.getElementById('mc-next');
  if (!id || id === 'hub' || !nav) return;
  const k = MYTHS.findIndex(m => m.id === id); if (k < 0) return;
  const m = MYTHS[k], pg = m.pages || [], pi = pg.findIndex(p => p[0] === here);
    nav.innerHTML = `<div class="mc-crumb"><a href="index.html">🧭 先排除誤解</a> › ${m.ic} 誤解 ${k + 1}：${m.t}
      <a class="mc-faqlink" href="faq.html">❓ 常見問題 FAQ</a></div>
    <ol class="mc-steps">${pg.map((p, j) => `<li class="${j === pi ? 'on' : seen.includes(p[0]) ? 'seen' : ''}">
      <a href="${p[0]}"${j === pi ? ' aria-current="page"' : ''}>${p[1]}</a></li>`).join('')}</ol>`;

  
  if (nx){
    const prev = pg[pi - 1], next = pg[pi + 1];
    nx.innerHTML = `<div class="mc-pager">
      ${prev ? `<a href="${prev[0]}">← ${prev[1]}</a>` : `<a href="index.html">← 誤解總覽</a>`}
      ${next ? `<a class="nx" href="${next[0]}">下一頁：${next[1]} →</a>` : `<a class="nx" href="index.html">✓ 完成，回到誤解總覽 →</a>`}</div>`;
  }
})();
