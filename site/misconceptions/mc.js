/* 先排除誤解：共用資料、導覽及工具。新增誤解時，只需在 MYTHS 加一項。 */
(function(){
  const MYTHS = [
    {id:'sampling', ic:'🎲', t:'抽樣', st:'done', href:'sampling.html',
     myth:'學校可以自行揀選學生參加 PISA，所以樣本不能代表香港',
     check:'學校以 PPS 系統抽樣抽出，學生由軟件從完整名單隨機抽出；國家中心只提供名單及執行，無權揀選或替換。',
     pages:[['sampling.html','① 誰決定誰參加？'],['sampling-pps.html','② 學校怎樣抽？'],
            ['sampling-students.html','③ 學生怎樣抽？'],['sampling-standards.html','④ 標準與抽樣誤差']],
     faq:[['administration','FAQ：抽樣、施測期及施測安排有否影響結果？']]},
	  {id:'schedule', ic:'📅', t:'施測日期', st:'done', href:'faq.html#faq-administration',
     myth:'施測日期選得不好（例如考試季前後），令學生表現下降',
     check:'香港 PISA 2025 數據符合 OECD 質素標準。2022 年同樣在 5 至 7 月施測；本地分析顯示，控制學生及學校變項後，較後的施測日期與較低分數沒有統計上顯著的關係。'},
    {id:'effort', ic:'😴', t:'學生不投入', st:'done', href:'faq.html#faq-engagement',
     myth:'香港學生在 PISA「求其做」，所以分數下跌',
     check:'學生自評努力程度約 7.3／10，大致穩定；未作答題目比率低。閱讀的倉促作答由 2018 年 5.0% 升至 2025 年 8.8%（接近 OECD 約 9%），值得留意，但不能解釋長期下行。'},
	  {id:'translation', ic:'🈶', t:'翻譯', st:'plan',
     myth:'中文譯本有問題，令題目對香港學生特別難',
     check:'PISA 設有翻譯、改編及國際驗證程序；團隊正檢視個別題目在香港是否異常地難。',
     faq:[['assessment-language','FAQ：應考語言與翻譯程序']]},
    {id:'language', ic:'🗣️', t:'應考語言', st:'done', href:'faq.html#faq-assessment-language',
     myth:'較多學生以英文應考，拉低分數或令結果不能比較',
     check:'加權數據約 55% 以中文、45% 以英文應考；調整社經背景、性別及抽樣分層後，英文組平均分仍較中文組高。'},
    {id:'drill', ic:'📝', t:'題型陌生／未有操練', st:'done', href:'faq.html#faq-item-format',
     myth:'學生沒有練習 PISA 題型，所以考得不好',
     check:'最陌生的 LDW 反而是香港最強的範疇（545 分，屬表現最佳之列），題型陌生不足以解釋其他範疇的表現。'},
    {id:'covid', ic:'🦠', t:'疫情', st:'done', href:'faq.html#faq-covid',
     myth:'表現下跌主要或完全是疫情停課造成的',
     check:'不少教育系統都受疫情影響，而香港大部分範疇的下行早於疫情；PISA 是調查，不能單獨確定疫情的因果比重。'},
    {id:'trend', ic:'📉', t:'只在 2025 下跌', st:'done', href:'faq.html#faq-trend',
     myth:'香港表現到 2025 年才突然下跌',
     check:'香港分數在 2012 年見頂，其後大致下行；OECD 在 2025 年之前已有記錄。'}
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
            <a class="mc-faqlink" href="${m.faq ? 'faq.html#faq-' + m.faq[0][0] : 'faq.html'}">❓ 常見問題 FAQ</a></div>
    <ol class="mc-steps">${pg.map((p, j) => `<li class="${j === pi ? 'on' : seen.includes(p[0]) ? 'seen' : ''}">
      <a href="${p[0]}"${j === pi ? ' aria-current="page"' : ''}>${p[1]}</a></li>`).join('')}</ol>`;

  
  if (nx){
    const prev = pg[pi - 1], next = pg[pi + 1];
    nx.innerHTML = `<div class="mc-pager">
      ${prev ? `<a href="${prev[0]}">← ${prev[1]}</a>` : `<a href="index.html">← 誤解總覽</a>`}
      ${next ? `<a class="nx" href="${next[0]}">下一頁：${next[1]} →</a>` : `<a class="nx" href="index.html">✓ 完成，回到誤解總覽 →</a>`}</div>`;
  }
})();
