/* =========================================================
   PISA HKU · LDW 專題共用資料與導覽（一處編輯，全專題同步）
   本專題不載入 js/site.js；頁首、頁尾由本檔產生。
   ========================================================= */
window.LDW = (() => {
  const BASE = 'https://pisa2025ldw.pilaproject.org/';
  const EMBED = true;                                     // ← 若 OECD 平台禁止內嵌，改為 false

  const PLAYLIST = 'PLMpwEGX-30A29snF5DwAS9AyZa9Ux6moI';   // 港大 PISA 2025 HKU：在數碼世界中學習（9 集）
  const SUBS = {yue:'yue', msc:'zh-Hant', en:'en'};          // ← 按 YouTube 字幕軌語言代碼調整
  /* t：集數；d：標題；len：片長；id：影片 ID（留空則按播放清單次序播放） */
    /* t：集數；d：標題；len：片長；id：YouTube 影片 ID（watch?v= 後的 11 個字元） */
  const EPS = [
    {t:'LDW1', d:'示例 Sample',       len:'3:27',  id:'mxG7znlOjXI'},
    {t:'LDW2', d:'簡介 Introduction', len:'2:07',  id:'t4tBTZ45twQ'},
    {t:'LDW3', d:'展示 Show',         len:'6:27',  id:'5x8cG3Y6yQE'},
    {t:'LDW4', d:'學習 Learn 1',      len:'15:21', id:'ECwfX9cZ1ws'},
    {t:'LDW5', d:'學習 Learn 2',      len:'7:53',  id:'K2FGAi8ABas'},
    {t:'LDW6', d:'學習 Learn 3',      len:'9:42',  id:'QltwjVXY_U4'},
    {t:'LDW7', d:'學習 Learn 4',      len:'10:39', id:'OhzPV3o10i0'},
    {t:'LDW8', d:'應用 Apply 1',      len:'7:20',  id:'SfGWgWiTF3o'},
    {t:'LDW9', d:'應用 Apply 2',      len:'7:38',  id:'JHJmP7r_DoE'}
  ];


  /*const EPS = Array.from({length:9}, (_,i) => ({t:'LDW' + (i+1), d:'', id:''})); // ← 填 d（標題）及 id（影片 ID）*/
  const LANG = {'zh-HK':'中文', 'en-HK':'English', 'en':'English'};
  const TYPE = {prog:{zh:'編程', c:'#3b5bdb', bg:'#edf1fd'}, model:{zh:'建模', c:'#0c8a73', bg:'#e6f5f1'}};
  const STUDY = {main:{zh:'正式研究', b:'#16224a', f:'#fff'}, ft:{zh:'實地測試', b:'#e7e2d4', f:'#5d6b68'}};

  const UNITS = [
    {k:'claw', unit:'RobotArm', item:'P1M101', ic:'🦾', zh:'回收機械爪', en:'Recycling Claw', type:'prog', study:'main', langs:['zh-HK','en-HK'],
     topic:'自動化回收、機械人', task:'以積木式編程控制機械爪，把罐和膠樽分類放進正確的回收箱。',
     ph:{show:'追蹤方格上的方向指令、找出缺少的移動積木、判斷迴圈次數，並預測條件指令的執行路徑。',
         learn:'在積木式編程介面編寫及除錯程式，學習重複迴圈及條件判斷（如「如果機械爪拿着罐」）。',
         apply:'設計用最少積木的分類程式，處理一組混合回收物。'},
     comp:['演算法設計','序列控制','重複迴圈','條件邏輯','除錯','程式效率'],
     tip:'先用最簡單的序列完成，再找出重複的部分改用迴圈，最後才追求最少積木。'},
    {k:'fitness', unit:'FitnessApp', item:'P1M201', ic:'⌚', zh:'健身應用程式', en:'Fitness App', type:'model', study:'main', langs:['zh-HK','en-HK'],
     topic:'健康、體能活動與能量消耗', task:'調整運動類型、時間及強度，在安全心率內達到卡路里目標。',
     ph:{show:'閱讀心率及卡路里圖表，理解輸入變量與輸出結果的關係。',
         learn:'在模型積木中設定變量並執行模擬，以實驗找出符合目標的參數。',
         apply:'建立多階段健身計劃模型，在多項健康限制下達成每周目標。'},
     comp:['計算建模','模擬實驗','參數調整','圖表詮釋','多重限制下的取捨'],
     tip:'每次只改一個變量並記錄結果；留意心率上限這類「不能越過」的限制。'},
    {k:'landing', unit:'SafeLanding', item:'P1M501', verify:true, ic:'🚀', zh:'安全着陸', en:'Safe Landing', type:'model', study:'main', langs:['zh-HK','en-HK'],
     topic:'太空探索、進入大氣層與對接', task:'調整推力、進入角度等參數，讓太空船在 D 行星安全着陸並與太空站對接。',
     ph:{show:'閱讀軌跡及行星大氣數據表，按速度及大氣密度選擇着陸地點。',
         learn:'調整引擎推力、進入角度及隔熱盾，系統地測試，達到安全着陸速度而不耗盡燃料。',
         apply:'在大氣阻力或燃料等條件改變時，重新校準參數完成對接。'},
     comp:['計算建模','系統化試驗','動態數據詮釋','速度、推力與燃料的取捨','問題分解'],
     tip:'先找出每個參數的影響方向，再收窄範圍。〈熱身體驗〉的建模小遊戲就是這類思考。'},
    {k:'conservation', unit:'Conservation', item:'P1M401', ic:'🦌', zh:'生態保育', en:'Conservation', type:'model', study:'ft', langs:['en'],
     topic:'生態系統、野生動物族群與保育', task:'操作生態模擬，調整出生率、死亡率、保護區大小等變量，使模型輸出與真實觀察數據吻合。',
     comp:['系統建模','模型驗證','參數校準','數據比較','假設檢驗'],
     note:'實地測試顯示此單元難度很高：不少學生未能掌握「驗證模型，就是找出一組與真實數據吻合的模型輸出」。',
     tip:'先看清楚目標數據的趨勢，再逐一調整參數，比較模擬曲線與目標曲線。'},
    {k:'dolphin', unit:'DolphinCall', item:'P1M801', ic:'🐬', zh:'海豚叫聲', en:'DolphinCall', type:'model', study:'ft', langs:['en'], video:true,
     topic:'海洋生物、生物聲學', task:'運用計算工具分析海豚叫聲錄音及頻譜，篩選頻率、設定閾值，辨識個別海豚的叫聲特徵。',
     comp:['數據篩選','模式辨識','閾值設定','減少雜訊'],
     note:'未有納入正式研究，但作為公開資源保留。',
     tip:'打開側欄「港大影片」，按「平分畫面」，一邊看粵語講解，一邊試做。'},
    {k:'bus', unit:'BusSchedule', item:'P1M901', ic:'🚌', zh:'巴士時間表', en:'BusSchedule', type:'model', study:'ft', langs:['en'],
     topic:'城市交通規劃', task:'為巴士路線建立時間表模型，調整開車間距、載客量及停站時間，減少乘客等候及車輛擠塞。',
     comp:['系統模擬','排程演算法','多變量限制','網絡優化'],
     tip:'先找出繁忙時段的瓶頸，再決定改變哪一個變量。'}
  ];

  /* 專題頁面（順序即頁首分頁及翻頁順序；播放器另設按鈕） */
  const PAGES = [
    {f:'index.html',     ic:'💻', zh:'專題主頁', tab:'總覽'},
    {f:'design.html',    ic:'🧭', zh:'評估設計'},
    {f:'warmup.html',    ic:'🧩', zh:'熱身體驗'},
    {f:'units.html',     ic:'🗂️', zh:'六個單元'},
    {f:'classroom.html', ic:'🏫', zh:'課堂啟示'}
  ];
  const CH = {f:'../digital.html', ic:'📖', zh:'09 從 LDW 到 MAIL'};   // 所屬章節

  const unit = k => UNITS.find(u => u.k === k);
  const url  = (u, l) => `${BASE}?unit=${u.unit}&item=${u.item}&lang=${l || u.langs[0]}`;
  const play = (k, l, p) => `player.html?u=${k}${l ? '&lang=' + l : ''}${p ? '&panel=' + p : ''}`;

  /* 試做進度（只存於瀏覽器） */
  const KEY = 'ldw-progress';
  const load = () => { try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch(e){ return {}; } };
  const prog = k => load()[k] || {};
  const setProg = (k, patch) => { const o = load(); o[k] = Object.assign(o[k] || {}, patch); try { localStorage.setItem(KEY, JSON.stringify(o)); } catch(e){} };
  const doneCount = () => UNITS.filter(u => prog(u.k).v).length;

  /* ---------- 專題頁首（取代全站頁首） ---------- */
  const cur = document.body.dataset.lw;
  const hdr = document.createElement('header');
  hdr.className = 'lw-top';
  hdr.innerHTML = `<div class="in">
    <a class="lw-badge" href="../index.html" title="PISA 2025 研討會專題主頁">PISA HK</a>
    <a class="lw-ttl" href="index.html">數碼世界中的學習<small>LDW</small></a>
    <nav class="lw-tabs" aria-label="LDW 專題導覽">
      ${PAGES.map((p,i) => `<a href="${p.f}" class="${p.f === cur ? 'on' : ''}"${p.f === cur ? ' aria-current="page"' : ''}>${String(i).padStart(2,'0')} ${p.tab || p.zh}</a>`).join('')}
      <a class="play${cur === 'player.html' ? ' on' : ''}" href="player.html"${cur === 'player.html' ? ' aria-current="page"' : ''}>▶ 試做</a>
      <a class="back" href="${CH.f}" title="返回第 09 章：從 LDW 到 MAIL">↩ 09 數碼與 AI</a>
    </nav></div>`;
  const oldH = document.getElementById('site-header');
  if (oldH) oldH.replaceWith(hdr); else document.body.prepend(hdr);
  const oldNav = document.getElementById('lw-nav'); if (oldNav) oldNav.remove();   // 舊版第二行導覽

  /* ---------- 專題頁尾 ---------- */
  const ft = document.createElement('footer');
  ft.className = 'lw-foot';
  ft.innerHTML = `<div class="in"><span>PISA 2025 研討會專題 · 數碼世界中的學習（LDW）</span>
    <span>單元由 OECD 提供 · <a href="${CH.f}">第 09 章</a> · <a href="../index.html">研討會主頁</a></span></div>`;
  const oldF = document.getElementById('site-footer');
  if (oldF) oldF.replaceWith(ft); else document.body.append(ft);

  /* ---------- 麵包屑：自動加入所屬章節 ---------- */
  document.querySelectorAll('.lw-crumb').forEach(c => {
    const home = c.querySelector('a[href="../index.html"]');
    if (home && !c.querySelector(`a[href="${CH.f}"]`)) home.insertAdjacentHTML('afterend', ` › <a href="${CH.f}">09 數碼與 AI</a>`);
  });

  /* ---------- 翻頁：專題主頁的「上一頁」是第 09 章 ---------- */
  const pg = document.getElementById('lw-pager');
  if (pg){
    let i = PAGES.findIndex(p => p.f === cur), pv, nx;
    if (i < 0){ pv = PAGES[3]; nx = PAGES[4]; } else { pv = i === 0 ? CH : PAGES[i-1]; nx = PAGES[i+1]; }
    pg.innerHTML = `<a href="${pv.f}"><small>← 上一頁</small><b>${pv.ic} ${pv.zh}</b></a>` +
                   (nx ? `<a class="nx" href="${nx.f}"><small>下一頁 →</small><b>${nx.ic} ${nx.zh}</b></a>`
                       : `<a class="nx" href="player.html"><small>開始試做 →</small><b>▶ 試做播放器</b></a>`);
  }

  return {BASE, EMBED, PLAYLIST, SUBS, EPS, LANG, TYPE, STUDY, UNITS, PAGES, unit, url, play, prog, setProg, doneCount};
})();

