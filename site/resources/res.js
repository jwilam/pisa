/* resources/res.js · 延伸資源專區 */
(function(){
  const CHECKED = '2026-10-23';   // 每次檢查連結後更新

  /* ===== 五個途徑（由淺入深） ===== */
  const LINKS = [
    {n:1, time:'5 分鐘', icon:'📊', type:'互動圖表',
     zh:'PISA 2025 重點結果（Dashboard）', en:'PISA 2025 key results',
     url:'https://www.oecd.org/en/about/programmes/pisa/pisa-data.html', /* TODO：換成附件 Dashboard／infographic 的實際網址 */
     aud:['teacher','leader'],
     note:'最快掌握全球結果的入口。適合在科組會議開場時，用 5 分鐘建立共同背景。',
     rel:['../trends.html','香港歷屆趨勢']},
    {n:2, time:'15 分鐘', icon:'🇭🇰', type:'簡報',
     zh:'香港（中國）國家／地區簡報', en:'Country Note: Hong Kong (China)',
     url:'https://www.oecd.org/en/publications/pisa-2025-results-volume-i-country-notes_2d4ff9ea-en/hong-kong-china_453f39ca-en.html',
     aud:['teacher','leader','research'],
     note:'OECD 對香港結果的官方摘要。本站引用香港分數時，均以此及結果報告為準。',
     rel:['../science.html','科學教育']},
    {n:3, time:'深入閱讀', icon:'📘', type:'報告',
     zh:'PISA 2025 結果報告（第一冊）', en:'PISA 2025 Results (Volume I): Future-Ready Students',
     url:'https://www.oecd.org/en/publications/2026/09/pisa-2025-results-volume-i_5265bfb1.html',
     aud:['leader','research'],
     note:'2026 年 9 月 8 日發布，涵蓋 91 個國家／地區逾 76 萬名學生。報告指出閱讀跌幅集中在評估資訊、跨來源連結等 AI 時代的關鍵能力，可與本站閱讀力框架對讀。',
     rel:['../reading-framework.html','多文本閱讀力框架']},
    {n:4, time:'比較', icon:'🧭', type:'數據平台',
     zh:'Education GPS', en:'OECD Education GPS',
     url:'https://gpseducation.oecd.org/',
     aud:['leader','research'],
     note:'可下載全套 PISA 指標，並產生國家／地區概況 PDF。適合把香港與新加坡、澳門等地並列比較。',
     rel:['../science-factors/comparison.html','港新比較']},
    {n:5, time:'自行分析', icon:'🗄️', type:'原始數據',
     zh:'PISA 2025 數據庫', en:'PISA 2025 Database',
     url:'https://www.oecd.org/en/data/datasets/pisa-2025-database.html',
     aud:['research'],
     note:'學生、校長、教師及家長的完整個別回應。分析時必須使用抽樣權重、重複權重及可能值，否則結果會有偏差。',
     rel:['../agency-ega/method.html','本站分析步驟']}
  ];

  /* ===== 影片（title 留空會自動從 YouTube 讀取） ===== */
    /* ===== 影片（note 可為一句文字，或 {what, why, who} 三段） ===== */
  const VIDEOS = [
    {id:'JkhES3H86WQ', grp:'oecd', len:'約 44 分鐘',
     title:'PISA | The 2025 PISA results (Extended)',
     by:'OECD · Andreas Schleicher',
     rel:['../trends.html','香港歷屆趨勢'],
     note:{
       what:'由 OECD 教育及技能司司長 Andreas Schleicher 主講，全面剖析 PISA 2025 全球數據，涵蓋科學素養、閱讀跌幅、教育公平、社經差距，以及數碼裝置與 AI 的影響。',
       why:'權威且數據完整，跳出單一學科成績的框架，揭示教育政策、課堂實踐與學生非認知能力（如求知慾及心理韌性）之間的關聯。',
       who:'教育政策制定者、大專研究人員及學校管理層：宏觀分析全球趨勢、評估教育體系的參考。'}},
    {id:'MiHzd0aTIkA', grp:'oecd',
     title:'PISA 2025: How is artificial intelligence impacting education?',
     by:'OECD',
     rel:['../reading-framework.html','多文本時代的閱讀力'],
     note:{
       what:'OECD 精華短片，探討 AI 與數碼科技對學生學習及閱讀素養的衝擊，指出過度依賴 AI 產出答案，可能削弱批判思考與深度閱讀能力。',
       why:'節奏明快、切中要害：關鍵不在禁用或盲目使用 AI，而在於課堂中落實「AI 素養」及批判查證的教育。',
       who:'關注數碼教學的前線教師、課程發展主任，以及關心子女科技使用習慣的家長。'}},
    {id:'tzrb8-2xIQo', grp:'hk',
     title:'PISA不是比賽！五個重點拆解香港教育的「身體檢查」報告',
     by:'香港前線教育工作者 · 港大 PISA 2025 發布會後分享',
     rel:['../science.html','科學教育：減少操練、增加探究'],
     note:{
       what:'香港前線教育工作者參加港大 PISA 2025 發布會後的反思，提煉五個實踐重點，強調把 PISA 視為教育的「健康檢查」，而非排名競賽。',
       why:'立足香港課堂，直指過度操練與課程擠迫的問題，並提出「減法教學」、認識論知識（Epistemic Knowledge）及提升學生學習能動性等具體的課堂轉型方向。',
       who:'香港中小學校長、科主任、前線教師及準教師：容易引起共鳴，並可轉化為教學靈感。'}}
  ];

  /* ===== 本站延伸專題（站內頁面，同一分頁開啟；不參與讀者篩選） ===== */
  const SITE = [
    {icon:'💻', time:'約 30 分鐘／單元',
     zh:'數碼世界中的學習（LDW）', en:'Learning in the Digital World',
     url:'../ldw/index.html',
     note:{
       what:'PISA 2025 創新範疇專題：評估設計、熱身小遊戲、六個 OECD 公開單元，並可在本站播放器內試做。',
       why:'每個單元分「展示、學習、應用、反思」四個階段。親身試做，最能理解香港學生在這個範疇的表現。',
       who:'教師可用於課堂試做及教師培訓；家長和學生可直接體驗。'},
     also:[['../ldw/player.html?u=dolphin&panel=video','🎬 港大 DolphinCall 影片']]}
  ];




  const AUD = {teacher:'教師', leader:'學校領導', research:'研究人員'};
  const GRP = {oecd:'OECD 官方', hk:'香港教師分享'};
  const page = document.body.dataset.res;
  const esc = s => String(s||'').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
  
  const noteHTML = t => typeof t === 'string'
    ? `<p class="r-note${/^【/.test(t)?' todo':''}"><b>編者按</b>${esc(t)}</p>`
    : `<div class="r-note r-note3"><b>編者按</b><dl>
         <dt>內容</dt><dd>${esc(t.what)}</dd>
         <dt>推薦原因</dt><dd>${esc(t.why)}</dd>
         <dt>適合對象</dt><dd>${esc(t.who)}</dd></dl></div>`;
  
  const relHTML = r => r ? `<a class="rel" href="${r[0]}">${r[1]} →</a>` : '';

  /* ---- header / footer ---- */
  const top = document.getElementById('r-top');
  if (top) top.innerHTML = `<div class="in">
    <a class="r-brand" href="index.html">PISA 2025 · 港大研討會專題<small>延伸資源 EXTERNAL RESOURCES</small></a>
    <nav class="r-tabs">
      <a href="index.html" class="${page==='hub'?'on':''}">資源總覽</a>
      <a href="videos.html" class="${page==='videos'?'on':''}">影片</a>
      <a class="r-back" href="../index.html">↩ 返回研討會專題</a>
    </nav></div>`;
  const foot = document.getElementById('r-foot');
  if (foot) foot.innerHTML = `<div class="in">
    <p><b>關於外部資源：</b>本區連結的報告、數據及影片，版權及觀點屬原作者或機構。本站負責選取及撰寫編者按，並不代表原作者認可本站內容。</p>
    <p>連結最後檢查：${CHECKED}｜如發現失效連結，請通知網站編輯。</p></div>`;

  /* ---- titles from YouTube oEmbed ---- */
  const cache = {};
  function loadTitle(v){
    if (v.title) return Promise.resolve(v.title);
    return cache[v.id] ||= fetch('https://www.youtube.com/oembed?format=json&url=' +
        encodeURIComponent('https://www.youtube.com/watch?v=' + v.id))
      .then(r => r.ok ? r.json() : Promise.reject()).then(j => j.title).catch(() => 'YouTube 影片');
  }
  function fillTitles(){
    VIDEOS.forEach(v => loadTitle(v).then(t =>
      document.querySelectorAll(`[data-title="${v.id}"]`).forEach(e => e.textContent = t)));
  }

  /* ---- card templates ---- */
  function linkCard(L){
    const host = new URL(L.url).hostname.replace(/^www\./,'');
    return `<article class="r-card" data-aud="${L.aud.join(' ')}">
      <div class="hd"><span class="no">${L.n}</span><h3>${L.icon} ${L.zh}<small>${L.en}</small></h3></div>
      <div class="r-meta"><span class="pill t">${L.type}</span><span class="pill">⏱ ${L.time}</span>
        ${L.aud.map(a => `<span class="pill">${AUD[a]}</span>`).join('')}</div>
      ${noteHTML(L.note)}${relHTML(L.rel)}
      <div class="r-act"><span class="dom">🌐 ${host} · 英文</span>
        <a class="btn" href="${L.url}" target="_blank" rel="noopener">開啟 ↗<span class="sr">（於新分頁開啟）</span></a></div>
    </article>`;
  }
  function vCard(v){
    return `<a class="r-vcard" href="videos.html#v=${v.id}" data-id="${v.id}">
      <div class="th"><img loading="lazy" src="https://i.ytimg.com/vi/${v.id}/hqdefault.jpg" alt="">
        <span class="play">▶</span><span class="where">本站播放</span></div>
      <div class="bd"><span class="pill ${v.grp}">${GRP[v.grp]}</span>
        <h3 data-title="${v.id}">${esc(v.title) || '載入標題中…'}</h3><small>${esc(v.by)}${v.len ? ' · ⏱ ' + v.len : ''}</small>
</div></a>`;
  }
  
    function siteCard(S){
    return `<article class="r-card">
      <div class="hd"><h3>${S.icon} ${S.zh}<small>${S.en}</small></h3></div>
      <div class="r-meta"><span class="pill t">本站專題</span><span class="pill">⏱ ${S.time}</span></div>
      ${noteHTML(S.note)}
      <div class="r-act"><span class="dom">📍 本站 · 中文</span>
        ${(S.also || []).map(a => `<a class="btn ghost" href="${a[0]}">${a[1]}</a>`).join('')}
        <a class="btn" href="${S.url}">進入專題 →</a></div>
    </article>`;
  }


  /* ---- hub page ---- */
  const lg = document.getElementById('r-links');
  if (lg){
	if (SITE.length) lg.insertAdjacentHTML('afterend',
      `<section class="r-site" aria-label="本站延伸專題"><h2>本站延伸專題</h2>${SITE.map(siteCard).join('')}</section>`);
    lg.innerHTML = LINKS.map(linkCard).join('');
    const fb = document.querySelectorAll('.r-filter button');
    fb.forEach(b => b.addEventListener('click', () => {
      fb.forEach(x => x.classList.toggle('on', x === b));
      const a = b.dataset.aud;
      lg.querySelectorAll('.r-card').forEach(c =>
        c.classList.toggle('hide', a !== 'all' && !c.dataset.aud.split(' ').includes(a)));
    }));
  }
  const vp = document.getElementById('r-vpreview');
  if (vp) vp.innerHTML = VIDEOS.map(vCard).join('');

  /* ---- video page ---- */
  const stage = document.getElementById('r-stage');
  if (stage){
    ['oecd','hk'].forEach(g => {
      const el = document.getElementById('r-list-' + g);
      if (el) el.innerHTML = VIDEOS.filter(v => v.grp === g).map(vCard).join('');
    });
    document.addEventListener('click', e => {
      const c = e.target.closest('.r-vcard'); if (!c) return;
      e.preventDefault(); location.hash = 'v=' + c.dataset.id;
    });
    window.addEventListener('hashchange', () => {
      show(fromHash()); stage.scrollIntoView({behavior:'smooth', block:'start'});
    });
    show(fromHash());
  }
  function fromHash(){
    const m = location.hash.match(/v=([\w-]{11})/);
    return VIDEOS.find(v => m && v.id === m[1]) || VIDEOS[0];
  }
    function show(v){
    const i = VIDEOS.indexOf(v), prev = VIDEOS[i-1], next = VIDEOS[i+1];
    const yt = `https://www.youtube.com/watch?v=${v.id}`;
    stage.innerHTML = `
      <div class="r-player" role="button" tabindex="0" aria-label="在本站播放影片">
        <img src="https://i.ytimg.com/vi/${v.id}/hqdefault.jpg" alt="">
        <span class="big">▶</span><span class="hint">按此在本站播放 · 影片由 YouTube 提供</span></div>
      <div class="r-info">
        <div class="meta">
          <span class="pill ${v.grp}">${GRP[v.grp]}</span>
          <h2 data-title="${v.id}">${esc(v.title) || '載入標題中…'}</h2>
          <span class="by">${esc(v.by)}${v.len ? ' · ⏱ ' + v.len : ''}</span>
          ${relHTML(v.rel)}
          <a class="btn ghost" href="${yt}" target="_blank" rel="noopener">在 YouTube 觀看 ↗</a>
        </div>
        ${noteHTML(v.note)}
        <div class="nav">${prev ? `<a class="btn ghost" href="#v=${prev.id}">← 上一段</a>` : '<span></span>'}
          ${next ? `<a class="btn ghost" href="#v=${next.id}">下一段 →</a>` : ''}</div>
      </div>`;
    const p = stage.querySelector('.r-player');
    const stop = () => { p.onclick = p.onkeydown = null; p.style.cursor = 'default'; p.removeAttribute('role'); };
    const play = () => {
      stop();
      if (location.protocol === 'file:') {          // 本機直接開啟：YouTube 不允許嵌入播放
        p.insertAdjacentHTML('beforeend', `<div class="r-local">
          <b>本機預覽無法在頁內播放 YouTube 影片</b>
          <small>以本機伺服器開啟或上載網站後，即可在本站播放。現在可先到 YouTube 觀看。</small>
          <a class="btn" href="${yt}" target="_blank" rel="noopener">在 YouTube 觀看 ↗</a></div>`);
        return;
      }
      p.innerHTML = `<iframe src="https://www.youtube-nocookie.com/embed/${v.id}?autoplay=1&rel=0"
        title="${esc(v.title || 'YouTube 影片')}" allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
        allowfullscreen referrerpolicy="strict-origin-when-cross-origin"></iframe>`;
    };
    p.onclick = play;
    p.onkeydown = e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); play(); } };
    document.querySelectorAll('.r-vcard').forEach(c => c.classList.toggle('on', c.dataset.id === v.id));
    fillTitles();
  }

  fillTitles();
})();
