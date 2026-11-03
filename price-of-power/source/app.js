/* Представление использует только публичную проекцию модели. Никаких сетевых запросов. */
(function() {
  'use strict';
  const G = window.PriceOfPower;
  const $ = selector => document.querySelector(selector);
  const esc = value => String(value).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  const signed = n => `${n > 0 ? '+' : ''}${n}`;
  const fmt = n => Number(n).toLocaleString('ru-RU');
  const MANUAL = 'priceOfPower.v04.manual', AUTO = 'priceOfPower.v04.auto';
  const ui = { tab: 'home', filter: 'Все', target: 'val', metric: 'gold', range: 12, scene: null, chat: null, mapStarted: false, map:{scale:1,x:0,y:0} };
  let state = G.createGame(), toastTimer, storageOkay = true, turnBusy = false, mapDrag = null;
  function toast(message, error = false) {
    const node = $('#status'); node.textContent = message; node.hidden = false; node.classList.toggle('error', error);
    clearTimeout(toastTimer); toastTimer = setTimeout(() => { node.hidden = true; }, 6500);
  }
  function store(key) {
    try { localStorage.setItem(key, G.serialize(state)); storageOkay = true; return true; }
    catch { storageOkay = false; $('#save-state').textContent = 'Браузер запретил сохранение. Используйте файл в разделе хроники.'; return false; }
  }
  function perform(action, message) {
    try { const previousBattle = G.getView(state).military?.battle?.id; state = action(state); if (G.getView(state).military?.battle?.id && G.getView(state).military.battle.id !== previousBattle) ui.tab = 'army'; store(AUTO); render(); if (message) toast(message); return true; }
    catch (error) { toast(error.message, true); return false; }
  }
  async function nextMonth() {
    if (turnBusy || $('#next-month').disabled) return;
    turnBusy = true;
    const before = G.getView(state);
    $('#next-month').disabled = true;
    window.PopPresentation.beginTurn(before.date);
    try {
      await new Promise(resolve => setTimeout(resolve, 120));
      if (perform(G.advanceMonth)) {
        const after = G.getView(state);
        await window.PopPresentation.finishTurn(after, {...before,player:after.lastTurn?.before || before.player});
      } else window.PopPresentation.cancelTurn();
    } finally { turnBusy = false; render(); }
  }
  function showIntroduction(force = false) {
    const v = G.getView(state);
    if (v.month !== 0 || v.history.length !== 1) return;
    try { if (!force && localStorage.getItem(`popIntro06:${v.seed}`)) return; } catch {}
    window.PopPresentation.showIntro(v);
  }
  function setTab(tab, scroll = false) {
    if (!['home', 'council', 'orders', 'development', 'court', 'army', 'intel', 'history'].includes(tab)) return;
    if(tab!=='home')ui.mapStarted=true;
    ui.tab = tab;
    document.body.classList.toggle('map-interface',ui.mapStarted);
    for (const panel of document.querySelectorAll('[data-page]')) panel.hidden = ui.mapStarted ? (panel.dataset.page!=='home'&&panel.dataset.page!==tab) : panel.dataset.page!==tab;
    $('#map-panel-close')?.remove();
    if(ui.mapStarted&&tab!=='home'){
      const close=document.createElement('button');close.id='map-panel-close';close.className='map-panel-close';close.dataset.tab='home';close.setAttribute('aria-label','Вернуться на карту');close.innerHTML='<span>×</span> На карту';
      document.querySelector(`[data-page="${tab}"]`).prepend(close);
    }
    $('#stats').hidden = !ui.mapStarted && tab === 'home';
    $('#realm-details').hidden = !ui.mapStarted && tab === 'home';
    $('.turn-control').hidden = !ui.mapStarted && tab === 'home';
    for (const item of document.querySelectorAll('nav [data-tab]')) {
      const active = item.dataset.tab === tab; item.classList.toggle('active', active);
      if (active) item.setAttribute('aria-current', 'page'); else item.removeAttribute('aria-current');
    }
    if (scroll && !ui.mapStarted) window.scrollTo({ top: 0, behavior: 'auto' });
  }
  function applyMapTransform(){const map=$('.dominion-map');if(map){map.style.transform=`translate(${ui.map.x}px,${ui.map.y}px) scale(${ui.map.scale})`;map.classList.toggle('zoom-detail',ui.map.scale>=1.2);map.setAttribute('data-zoom',String(ui.map.scale));}}
  function changeMapZoom(delta){ui.map.scale=Math.max(.7,Math.min(2.4,Math.round((ui.map.scale+delta)*10)/10));applyMapTransform();}
  function resetMap(){ui.map={scale:1,x:0,y:0};applyMapTransform();}
  function changesHTML(changes, before = null, after = null) {
    const items = Object.entries(changes);
    if (!items.length) return '<span class="muted">Числовые показатели не изменились.</span>';
    return `<div class="changes">${items.map(([key, value]) => `<span class="${value >= 0 ? 'positive' : 'negative'}">${esc(G.METRICS[key])} ${before ? `${fmt(before[key])} → ${fmt(after[key])} (${signed(value)})` : signed(value)}</span>`).join('')}</div>`;
  }
  function portrait(person, small = false) {
    return `<span class="portrait portrait--${esc(person.id)} ${small ? 'small' : ''}" role="img" aria-label="${esc(person.name)}"></span>`;
  }
  function renderHome(v) {
    const fresh = v.month === 0 && v.history.length === 1;
    $('#home-opening').textContent = fresh ? '1248 год. Умер старый князь. Вам достались печать, речная долина и страна, которая ждёт решений. Теперь её история — ваша ответственность.' : `${v.date}. Идёт ${v.yearOfRule}-й год вашего правления. То, что вы построили, кому поверили и что оставили без ответа, уже стало частью истории этой земли.`;
    $('#enter-reign').textContent = fresh ? 'Вступить в правление →' : v.ended ? 'Открыть летопись правления →' : 'Вернуться к совету →';
    $('#home-identity').innerHTML = `<span>Форма правления<b>Княжество</b></span><span>Столица<b>Арден</b></span><span>Население<b>${fmt(v.player.population)} тыс.</b></span><span>Положение<b>${v.ended ? 'Правление завершено' : 'Вы у власти'}</b></span>`;
    let realmMap=$('#home-action-map');
    if(!realmMap){realmMap=document.createElement('section');realmMap.id='home-action-map';realmMap.className='home-action-map';document.querySelector('#realm-home .home-columns').before(realmMap);}
    const incoming=v.military?.enemyMarches?.length||0;
    realmMap.innerHTML=`<div class="home-map-heading"><div><span class="eyebrow">ВАШИ ВЛАДЕНИЯ · АРДЕНСКОЕ КНЯЖЕСТВО</span><h2>Управляйте страной на карте</h2></div><p>${incoming?`К рубежам движется враг: походов замечено ${incoming}. Крепость отмечена тревогой.`:'Столица, деревни, угодья, промыслы и рубежи принадлежат вам. Выберите объект княжества.'}</p></div><div class="map-controls" aria-label="Управление картой"><button data-map-action="out" aria-label="Уменьшить">−</button><button data-map-action="reset">Вся карта</button><button data-map-action="in" aria-label="Увеличить">+</button><small>Колесо — масштаб · потяните карту</small></div><div class="home-map-canvas dominion-map ${incoming?'under-threat':''}"><svg class="dominion-boundaries" viewBox="0 0 1200 720" preserveAspectRatio="none" aria-hidden="true"><path class="dominion-border" d="M103 174 286 74 510 98 690 52 1009 119 1113 290 1060 535 832 655 557 624 326 684 114 543 61 340Z"/><path class="province" d="M103 174 286 74 382 279 182 366 61 340Z"/><path class="province" d="M286 74 510 98 573 309 382 279Z"/><path class="province" d="M510 98 690 52 829 269 573 309Z"/><path class="province" d="M690 52 1009 119 1113 290 829 269Z"/><path class="province" d="M61 340 182 366 385 489 326 684 114 543Z"/><path class="province" d="M182 366 382 279 573 309 586 510 385 489Z"/><path class="province" d="M573 309 829 269 923 458 832 655 586 510Z"/><path class="province" d="M829 269 1113 290 1060 535 832 655 923 458Z"/><path class="dominion-river" d="M660 38C628 164 737 231 643 342S579 529 632 697"/><path class="dominion-road" d="M220 555 465 424 610 337 824 252 1028 182M467 424 370 225M610 337 836 535"/></svg><span class="map-title">АРДЕНСКОЕ КНЯЖЕСТВО</span><span class="outside north">СЕВЕРНЫЙ РУБЕЖ · НОРДВИК</span><span class="outside west">ЗАПАДНЫЙ ТРАКТ · ВАЛЬДОРИЯ</span><span class="outside east">ВОСТОЧНЫЙ ТРАКТ · МЕРСИЯ</span><button class="home-hotspot map-primary capital" data-tab="council"><b>♛</b><strong>Столица Арден</strong><small>${v.event?'совет ждёт решения':`${v.orders.length} дел в работе`}</small></button><button class="home-hotspot map-detail palace" data-tab="court"><b>♙</b><strong>Княжеский двор</strong><small>${v.encounters.filter(e=>!e.resolved).length} прошений</small></button><button class="home-hotspot map-primary town" data-tab="development"><b>⌂</b><strong>Городские кварталы</strong><small>службы, дома и строительство</small></button><button class="home-hotspot map-primary fields" data-tab="development"><b>❧</b><strong>Долинные земли</strong><small>поля ${v.player.farms} · сады ${v.player.orchards}</small></button><button class="home-hotspot map-detail forest" data-tab="orders"><b>♣</b><strong>Западные леса</strong><small>древесина ${v.player.wood}</small></button><button class="home-hotspot map-detail mines" data-tab="orders"><b>◆</b><strong>Каменные промыслы</strong><small>камень ${v.player.stone} · железо ${v.player.iron}</small></button><button class="home-hotspot map-primary port" data-tab="intel"><b>⚓</b><strong>Речная переправа</strong><small>торговля и посольства</small></button><button class="home-hotspot map-primary fortress ${incoming?'threat':''}" data-tab="army"><b>⚔</b><strong>Пограничная крепость</strong><small>${incoming?'ВРАГ ПРИБЛИЖАЕТСЯ':`оборона ${v.player.defense}`}</small></button><button class="home-hotspot map-detail chancery" data-tab="development"><b>▤</b><strong>Канцелярия</strong><small>законы и назначения</small></button><button class="home-hotspot map-detail chronicle" data-tab="history"><b>≡</b><strong>Архив</strong><small>показатели и летопись</small></button></div>`;
    applyMapTransform();
    const starts = {
      balanced: { title: 'Наследство Ольмара', text: 'Вы получили страну, способную жить дальше, но привыкшую откладывать трудные решения. Денег хватит на первые начинания. Зерна в амбарах достаточно на время, однако зимние расходы превышают поступления.', challenge: 'Определить, что нельзя откладывать. Укрепить хозяйство, познакомиться с людьми и выяснить, насколько обоснованы пограничные опасения.' },
      frontier: { title: 'Княжество на рубеже', text: 'Вы вступили на престол после усиления пограничных застав. Дружина подготовлена лучше, чем прежде, но военные приготовления встревожили соседей. На хозяйство осталось меньше денег.', challenge: 'Выяснить, кто действительно угрожает Ардену. Найти равновесие между безопасностью, расходами на войска и отношениями с другими дворами.' },
      scarcity: { title: 'После недорода', text: 'Предыдущий урожай подвёл долину. В казне сохранились деньги, но деревни уже просят зерно. Люди ждут не торжественных обещаний, а помощи до прихода следующих обозов.', challenge: 'Обеспечить людей пищей и восстановить доверие. Затем наладить производство, чтобы каждую зиму не начинать с той же просьбы.' },
    };
    const start = starts[v.scenario];
    $('#home-scenario').innerHTML = `<span class="eyebrow">${fresh ? 'ВАШЕ НАЧАЛО' : 'С ЧЕГО НАЧАЛАСЬ ЭТА ИСТОРИЯ'}</span><h2>${esc(start.title)}</h2><p>${esc(start.text)}</p><div class="inheritance-notes"><strong>Первые вопросы правления</strong>${esc(start.challenge)}</div><p class="inheritance-notes">Вы управляете казной и законами, выбираете людей и лично разбираете дела. Советники помогут, но видят мир по-разному. После первого года летописец подведёт итоги; кампания продолжится.</p>`;
    const construction = v.buildings.reduce((n,b) => n + v.player[b.key],0);
    const hostile = v.neighbors.filter(n => n.relations === 'Враждебные').length;
    $('#home-situation').innerHTML = [
      { tab: 'history', label: 'КАЗНА И СНАБЖЕНИЕ', value: `${fmt(v.player.gold)} монет`, text: `Зерно: ${fmt(v.player.food)}. Текущий месячный баланс: казна ${signed(v.economy.gold)}, зерно ${signed(v.economy.food)}.` },
      { tab: 'court', label: 'ЛЮДИ КНЯЖЕСТВА', value: `${v.player.stability}% устойчивости`, text: `Стабильность отражает положение в стране. Здоровье жителей: ${v.player.health}%. У каждого посетителя своя просьба.` },
      { tab: 'development', label: 'ГОРОД И ЗЕМЛИ', value: `${construction} улучшений`, text: `Действующих поручений: ${v.orders.length}. Решайте, во что вложиться — в хозяйство, городские службы или знания.` },
      { tab: 'intel', label: 'ГРАНИЦЫ И СОСЕДИ', value: `${v.player.army} сила войска`, text: `Оборона: ${v.player.defense}. ${hostile ? `Враждебных дворов: ${hostile}.` : 'С соседями остаётся пространство для переговоров.'} Их реальные намерения предстоит выяснять.` },
    ].map(c => `<button class="situation-card" data-tab="${c.tab}"><span class="eyebrow">${c.label}</span><strong>${esc(c.value)}</strong><p>${esc(c.text)}</p></button>`).join('');
    $('#home-people').innerHTML = ['treasurer','marshal','governor'].map(id => {
      const p = v.characters.find(p => p.id === id);
      return `<article class="home-person">${portrait(p)}<div class="home-person-copy"><span class="eyebrow">${esc(p.role)}</span><h3>${esc(p.name)}</h3><p>${esc(p.temperament || p.description)}</p><button class="text-button" data-tab="court">Характер и личные связи →</button></div></article>`;
    }).join('');
  }
  function art(symbol, x = 0, y = 0, scale = 1) {
    let inside;
    if (symbol === 'tree') inside = '<path d="M27 63V35m29 28V30" stroke-width="4"/><circle cx="27" cy="28" r="16" fill="#667c46"/><circle cx="56" cy="23" r="18" fill="#84904f"/><g fill="#d3b36d" stroke="none"><circle cx="23" cy="23" r="3"/><circle cx="58" cy="18" r="3"/><circle cx="48" cy="28" r="3"/></g>';
    else if (symbol === 'field') inside = '<path d="m4 47 38-22 40 22-38 22Z" fill="#637047"/><path d="m12 48 31-17m-21 24 31-17m-20 24 30-18m-55-3 33 19m-20-26 32 19" stroke="#b9ae68"/>';
    else if (symbol === 'road') inside = '<path d="M6 61Q42 24 78 61" stroke-width="12" stroke="#a6a080"/><path d="M6 61Q42 24 78 61" stroke-width="6" stroke="#d1c096"/><path d="M17 57v12m50-12v12" stroke-width="4"/>';
    else if (symbol === 'well') inside = '<ellipse cx="42" cy="56" rx="22" ry="10" fill="#879078"/><path d="M20 46v12q22 13 44 0V46" fill="#aaa58b"/><ellipse cx="42" cy="46" rx="22" ry="8" fill="#435e55"/><path d="M24 46V19h36v27M18 20l24-15 25 15" fill="none" stroke-width="3"/><path d="M43 20v23"/>';
    else {
      const extra = symbol === 'university' ? '<path d="M33 28V7h20v21M30 7h26M43 1v8" fill="#9c9e80"/>' : '';
      const mark = symbol === 'clinic' ? '<path d="M39 34h8v8h8v8h-8v8h-8v-8h-8v-8h8Z" fill="#c2d1ad" stroke="none"/>' : symbol === 'school' ? '<path d="M26 35q9-5 17 0 9-5 17 0v17q-9-5-17 0-8-5-17 0Z" fill="#d2c591"/><path d="M43 35v17"/>' : '';
      inside = `<path d="M14 65V30h58v35" fill="#9b9e81"/><path d="m7 31 36-23 36 23Z" fill="#697c59"/>${extra}<path d="M36 65V48q7-10 14 0v17" fill="#3b4c3b"/><path d="M22 37v8m42-8v8" stroke="#d8cd9d" stroke-width="5"/>${mark}`;
    }
    return `<g transform="translate(${x} ${y}) scale(${scale})" stroke="#c3b88e" stroke-width="1.2" stroke-linejoin="round">${inside}</g>`;
  }
  function renderTown(v) { window.PopDevelopment.renderTown(v); }
  function renderStats(v) {
    const rows = [
      ['gold', 'Казна', '◉', 'монет', `${signed(v.economy.gold)} / мес. по текущему бюджету`],
      ['food', 'Зерно', '❧', 'запас', `${signed(v.economy.food)} / мес. · ${v.economy.season}`],
      ['stability', 'Стабильность', '◇', '%', v.player.stability < 40 ? 'Совет встревожен положением' : 'Основа доверия к правлению'],
      ['army', 'Армия', '⚔', 'сила', 'Обучение и содержание дружины'],
    ];
    $('#stats').innerHTML = rows.map(([key, title, icon, unit, hint]) => `<div class="stat" data-stat="${key}"><div class="stat-label"><span class="stat-symbol" aria-hidden="true">${icon}</span>${title}</div><div><span class="stat-value">${fmt(v.player[key])}</span><span class="stat-unit">${unit}</span></div><span class="stat-change ${['gold','food'].includes(key) && v.economy[key] < 0 ? 'negative' : ''}">${esc(hint)}</span></div>`).join('');
    $('#realm-details').innerHTML = [['defense','Оборона'],['population','Население, тыс.'],['health','Здоровье'],['wood','Древесина'],['stone','Камень'],['iron','Железо'],['goods','Товары'],['science','Наука'],['diplomacy','Дипломатия'],['intel','Разведка']].map(([key,title])=>`<span>${title}<b>${v.player[key]}${key==='health'?'%':''}</b></span>`).join('');
  }
  function renderCouncil(v) {
    const e = v.event;
    $('#council-event').innerHTML = v.ended ? '<span class="eyebrow">ЛЕТОПИСЬ ЗАВЕРШЕНА</span><h2>У каждой власти есть цена</h2><p class="event-body">Совет отстранил правителя. Прочитайте развязку этой истории или начните новую кампанию с другими решениями.</p><div class="choices"><button class="choice" data-action="chapter"><strong>Прочитать итоги</strong></button><button class="choice" data-action="new"><strong>Новая история</strong></button></div>' : e ? `<span class="eyebrow">${esc(e.category)}</span><h2>${esc(e.title)}</h2><p class="event-body">${esc(e.text)}</p><p class="event-cause">${esc(e.cause)}</p><div class="choices">${e.choices.map((c,i) => `<button class="choice" data-choice="${c.id}" ${c.disabled ? 'disabled' : ''}><span class="choice-index">0${i + 1}</span><strong>${esc(c.title)}</strong><span class="choice-description">${esc(c.description)}</span><small>${c.gold ? `${c.gold} монет` : c.food ? `${c.food} зерна` : 'Без затрат'}${c.disabled ? ' · не хватает ресурсов' : ''}</small></button>`).join('')}</div>` : `<span class="eyebrow">СРОЧНОЕ РЕШЕНИЕ ПРИНЯТО</span><h2>Пока совет ждёт вестей</h2><p class="event-body">Распорядитесь ресурсами, примите посетителей или отправьтесь в княжество. Когда будете готовы, завершите месяц.</p><p class="calm">${v.chains.length ? v.chains.map(c => `${c.type === 'border' ? 'Пограничная тревога' : 'Цена хлеба'}: продолжение через ${c.dueIn} мес.`).join(' · ') : 'Новые обстоятельства появятся по мере развития мира.'}</p>`;
    const latestCouncil = v.history.find(h => h.kind === 'council' && h.month === v.month);
    if (!e && latestCouncil) $('#council-event').insertAdjacentHTML('beforeend', `<section id="council-result" class="council-aftermath" aria-live="polite"><span class="eyebrow">ЧТО ПРОИЗОШЛО</span><p class="event-body">${esc(latestCouncil.text)}</p>${changesHTML(latestCouncil.changes)}<p class="event-cause">${esc(latestCouncil.reason)}</p></section>`);
    $('#queue-count').textContent = `${v.orders.length} / 6`;
    $('#nav-orders').textContent = v.orders.length;
    $('#active-orders').innerHTML = v.orders.length ? v.orders.map(o => {
      const d = v.commands.find(d => d.id === o.type), name = o.target ? ` · ${v.neighbors.find(n => n.id === o.target).name}` : '';
      return `<div class="order"><h3 class="order-name">${esc(d.name)}</h3><div class="order-meta">${esc(d.executor + name)}</div><div class="order-progress"><span style="width:${(o.duration - o.remaining) / o.duration * 100}%"></span></div><div class="order-stage"><span>Осталось ${o.remaining} мес.</span><span>${o.duration - o.remaining} из ${o.duration}</span></div></div>`;
    }).join('') : '<div class="empty-state">Исполнители ждут поручений. Начните с запасов, разведки или развития города.</div>';
    $('#completed-orders').innerHTML = v.completed.length ? '<div class="completed-title">НЕДАВНО ЗАВЕРШЕНО</div>' + v.completed.slice(0, 3).map(o => `<div class="completed-item"><strong>${esc(v.commands.find(d => d.id === o.type).name)}</strong><p>${esc(o.result)}</p></div>`).join('') : '';
    let advice = 'Посмотрите, что известно о соседях, и оставьте часть казны на непредвиденные дела. Сведения с возрастом теряют точность.';
    if (v.player.food < 35) advice = 'Зерна мало. Быстрая закупка поможет пережить ближайший месяц; поля и сады дадут устойчивый источник еды.';
    else if (v.economy.food < 0) advice = 'Мы съедаем больше, чем производим. Запас позволяет выиграть время, но нужны поля, сады или ограничение вывоза зерна.';
    else if (v.player.gold < 30) advice = 'Казна близка к истощению. Не начинайте всё сразу: развитие и содержание служб должны опираться на доход.';
    $('#adviser').innerHTML = `<span class="eyebrow">КАЗНАЧЕЙ МИРЕНА ВЕЛЬ</span><p>«${esc(advice)}»</p><div class="influence-panel"><span class="eyebrow">КТО ВЛИЯЕТ НА ГОРОД</span>${v.factions.map(f=>`<article class="influence-row ${f.illegal?'illegal':''}"><div><strong>${esc(f.name)}</strong><small>${esc(f.sphere)}</small></div><span>влияние <b>${f.influence}</b></span></article>`).join('')}<button class="text-button" data-tab="orders">Действия против подполья и сделки →</button></div>`;
    $('.appointments-board')?.remove();
    $('#adviser').insertAdjacentHTML('afterend',`<section class="appointments-board"><div class="section-heading"><div><span class="eyebrow">ЛЮДИ НА КЛЮЧЕВЫХ ДОЛЖНОСТЯХ</span><h2>Кадровые решения</h2></div><span>${v.epidemic?`⚠ ${esc(v.epidemic.name)} · ещё ${v.epidemic.remaining} мес.`:'Назначение расходует 1 поручение'}</span></div>${v.offices.map(o=>`<article class="office-card"><h3>${esc(o.name)}</h3><p>${esc(o.purpose)}</p><div class="office-candidates">${o.candidates.map(c=>`<div class="candidate ${o.appointed===c.id?'appointed':''}"><strong>${esc(c.name)}</strong><small>${esc(c.experience)}</small><span>Связи: ${esc(c.connections)}</span><p class="candidate-plus">+ ${esc(c.benefit)}</p><p class="candidate-minus">− ${esc(c.cost)}</p><button class="button secondary" data-appoint-office="${o.id}" data-appoint-candidate="${c.id}" ${o.appointed===c.id?'disabled':''}>${o.appointed===c.id?'Занимает должность':'Назначить'}</button></div>`).join('')}</div></article>`).join('')}</section>`);
    const report = $('#monthly-report'); report.hidden = !v.lastTurn;
    if (v.lastTurn) report.innerHTML = `<div class="section-heading"><h2>Итоги: ${esc(G.date(v.lastTurn.month - 1))}</h2><button class="text-button" data-tab="history">История показателей →</button></div>${changesHTML(v.lastTurn.changes, v.lastTurn.before, v.lastTurn.after)}<details><summary>Почему изменились показатели · ${v.lastTurn.entries.length} записей</summary>${v.lastTurn.entries.map(h => `<div class="turn-entry"><p>${esc(h.text)}</p>${changesHTML(h.changes)}<span>${esc(h.reason)}</span></div>`).join('')}</details>`;
  }
  function commandCard(v, d, building = null) {
    const blocker = G.orderBlocker(state, d.id, ui.target);
    if (building) return window.PopDevelopment.buildingCard(v, d, building, blocker);
    const icon = building ? `<svg viewBox="0 0 90 75" class="building-icon" aria-hidden="true">${art(building.symbol)}</svg><div class="levels" aria-label="Уровень ${d.level} из ${d.maxLevel}">${Array.from({length: d.maxLevel}, (_, i) => `<span class="${i < d.level ? 'filled' : ''}"></span>`).join('')}</div>` : '';
    return `<article class="command-card"><span class="eyebrow">${building ? `УРОВЕНЬ ${d.level} / ${d.maxLevel}` : esc(d.category)}</span>${icon}<h2>${esc(building ? building.name : d.name)}</h2><p class="command-description">${esc(building ? building.effect : d.description)}</p><div class="command-cost"><span>◉ ${d.gold} монет</span><span>◷ ${d.duration} мес.</span></div><button class="button secondary" data-order="${d.id}" ${blocker ? 'disabled' : ''}>${building ? d.level ? 'Повысить уровень' : 'Начать строительство' : 'Отдать приказ'}</button><p class="command-blocker">${esc(blocker || d.executor)}</p></article>`;
  }
  function renderOrders(v) {
    const categories=['Все',...new Set(v.commands.filter(d=>!d.building&&!d.law).map(d=>d.category))];
    $('#filters').innerHTML = categories.map(c => `<button class="filter ${ui.filter === c ? 'active' : ''}" data-filter="${c}" aria-pressed="${ui.filter === c}">${c}</button>`).join('');
    $('#action-points').textContent = `Новых приказов: ${v.ap} / 2`;
    $('#development-ap').textContent = `Новых приказов: ${v.ap} / 2`;
    $('#command-catalog').innerHTML = v.commands.filter(d => !d.building && !d.law && (ui.filter === 'Все' || d.category === ui.filter)).map(d => commandCard(v, d)).join('');
    $('#buildings').innerHTML = v.buildings.map(b => commandCard(v, v.commands.find(d => d.id === b.command), b)).join('');
    $('#policy-budget').innerHTML = `<h3>Что происходит с зерном и казной</h3><p>Зерно: производство <strong>+${v.economy.production}</strong>, пища жителей и войска <strong>−${v.economy.consumption}</strong>, торговый вывоз <strong>−${v.economy.exports || 0}</strong>, потери хранения <strong>−${v.economy.losses}</strong>. Баланс <strong>${signed(v.economy.food)}/мес.</strong></p><p>Казна: поступления <strong>+${v.economy.income}</strong>, содержание войска, служб и действующих законов <strong>−${v.economy.upkeep}</strong>. Баланс <strong>${signed(v.economy.gold)}/мес.</strong> Принятие указа не требует отдельной платы.</p>`;
    const incoming=v.military?.enemyMarches?.length||0;
    $('#laws').innerHTML = `<aside class="policy-alert ${incoming?'danger':''}"><strong>${incoming?'Военная угроза у границ':'Чрезвычайного положения нет'}</strong><p>${incoming?'Можно немедленно ввести призыв, перевести мастерские на военные заказы и организовать помощь жителей. После мира каждый режим можно так же быстро отменить.':'Трудовые и военные правила можно менять сразу. Мирный режим сохраняет хозяйство; мобилизация оправдана при реальной угрозе.'}</p></aside>`+v.lawOptions.map(law => `<article class="law-card ${law.flexible?'law-flexible':''}"><span class="eyebrow">${law.flexible?'МЕНЯЕТСЯ НЕМЕДЛЕННО':'ДЕЙСТВУЮЩИЙ УКЛАД'}</span><h2>${esc(law.name)}</h2><p class="law-explanation">${esc(law.explanation || '')}</p>${law.options.map(o => {
      const active = v.laws[law.key] === o.value, d = v.commands.find(d => d.id === `law_${law.key}_${o.value}`), blocker = G.orderBlocker(state, d.id, ui.target);
      return `<div class="law-option"><strong>${esc(o.name)}</strong>${active ? ' <span class="badge">Действует</span>' : ''}<p>${esc(o.effect)}</p><button class="button secondary" data-order="${d.id}" ${blocker ? 'disabled' : ''}>${active ? 'Закон действует' : blocker ? esc(blocker) : law.flexible?'Изменить сейчас · без платы':'Подготовить указ · без сбора'}</button></div>`;
    }).join('')}</article>`).join('');
    renderTown(v);
  }
  function renderReport(r) {
    return `<div class="report"><div class="report-source"><span>${esc(r.source)}</span><span>${r.age > 2 ? 'Устаревает' : 'Донесение'}</span></div><div class="report-date">${esc(r.date)} · давность ${r.age} мес.</div><div class="army-estimate">${r.armyMin}–${r.armyMax}<small>оценка силы армии</small></div><p class="intent">Вероятно: ${esc(r.intentLabel)}</p><div class="confidence"><div class="confidence-track"><span style="width:${r.effectiveConfidence}%"></span></div><span>Уверенность ${r.effectiveConfidence}%</span></div></div>`;
  }
  function renderIntel(v) {
    $('#neighbors').innerHTML = v.neighbors.map(n => {
      const blocker = G.orderBlocker(state, 'scout', n.id);
      return `<article class="intel-card"><div class="country-heading"><span class="eyebrow">${esc(n.ruler)}</span><h2>${esc(n.name)}</h2><p>${esc(n.trait)}</p><span class="relation-label">${esc(n.relations)}</span>${n.pactRemaining ? `<p>Договор: ещё ${n.pactRemaining} мес.</p>` : ''}</div><div class="intel-body"><p class="goal">Известный интерес: ${esc(n.goal)}</p>${n.reports[0] ? renderReport(n.reports[0]) : '<p class="muted">Свежих сведений нет.</p>'}${n.reports.length > 1 ? `<details class="old-reports"><summary>Предыдущие сведения</summary>${n.reports.slice(1).map(renderReport).join('')}</details>` : ''}<button class="button secondary" data-scout="${n.id}" ${blocker ? 'disabled' : ''}>Разведка · 14 монет · 2 мес.</button><p class="command-blocker">${esc(blocker || 'Агент может попасться. Сведения могут оказаться ошибочными.')}</p></div></article>`;
    }).join('');
    for (const n of v.neighbors) {
      const marker = document.querySelector(`[data-map-country="${n.id}"]`);
      if (!marker) continue;
      marker.setAttribute('fill', n.relations === 'Доброжелательные' ? '#b6cc95' : n.relations === 'Враждебные' ? '#d5937d' : '#d8ba79');
      marker.querySelector('title').textContent = `${n.name}: ${n.relations.toLowerCase()}`;
    }
  }
  function renderCourt(v) {
    $('#attention').textContent = `Осталось личных дел: ${v.attention}`;
    renderRuler(v);
    $('#encounter-preview').innerHTML = v.encounters.map(e => `<button class="encounter-preview ${e.urgency?'urgent':''}" data-scene="${e.id}">${portrait(e.person, true)}<span><small>${esc(e.type)} · ${esc(e.person.name)}</small><strong>${esc(e.title)}</strong>${e.urgency?`<em>${esc(e.urgency)}</em>`:''}</span><span aria-hidden="true">${e.resolved ? '✓' : '→'}</span></button>`).join('') || '<p class="muted">Новые посетители прибудут в следующем месяце.</p>';
    $('#encounters').innerHTML = v.encounters.map(e => `<article class="command-card story-card ${e.urgency?'story-urgent':''}"><div class="section-heading"><span class="eyebrow">${esc(e.type)}</span>${portrait(e.person, true)}</div><h2>${esc(e.title)}</h2>${e.urgency?`<p class="story-urgency">⚠ ${esc(e.urgency)}. Если снова не ответить, просьба получит самостоятельное последствие.</p>`:''}<p class="command-description">${esc(e.quote)}</p><p class="story-person">${esc(e.person.name)} · ${esc(e.place)}</p><button class="button secondary" data-scene="${e.id}">${e.resolved ? 'Решение принято · прочитать' : 'Открыть встречу →'}</button></article>`).join('');
    $('#characters').innerHTML = v.characters.map(p => `<article class="person-card">${portrait(p)}<div><span class="eyebrow">${esc(p.role)}</span><h3>${esc(p.name)}</h3><p>${esc(p.temperament || p.description)}</p><div class="confidence"><div class="confidence-track"><span style="width:${p.trust}%"></span></div><span>Доверие ${p.trust}%</span></div><small>${esc(p.bonus || 'Доверие меняется от ваших личных решений.')}</small><button class="button secondary chat-open" data-chat="${esc(p.id)}">Поговорить · бесплатно</button><details class="character-profile"><summary>Характер и личные связи</summary><p>${esc(p.bio || p.description)}</p><dl>${[['Ценит',p.values],['Слабость',p.blindSpot],['Личный интерес',p.personalStake]].filter(([,value])=>value).map(([label,value])=>`<dt>${label}</dt><dd>${esc(value)}</dd>`).join('')}</dl>${p.ties?.length ? `<ul>${p.ties.map(t=>`<li>${esc(t)}</li>`).join('')}</ul>` : ''}</details></div></article>`).join('');
    $('#conversation-notes').innerHTML = (v.conversationNotes || []).map(n => `<article><span class="eyebrow">${esc(n.name)} · ${esc(n.date)}</span><h3>${esc(n.title)}</h3><p>${esc(n.response)}</p></article>`).join('') || '<p class="muted">Пока здесь нет записей. Задайте человеку вопрос, чтобы сохранить ответ.</p>';
    $('#future-stories').innerHTML = v.futureStories.length ? `<div class="adviser"><span class="eyebrow">ИСТОРИИ ПРОДОЛЖАЮТСЯ</span>${v.futureStories.map(f => `<p>${esc(f.title)} · ожидается через ${f.dueIn} мес.</p>`).join('')}</div>` : '';
  }
  function renderRuler(v) {
    const r = v.ruler; if (!r) return;
    $('#ruler-status').innerHTML = `<div><span class="eyebrow">ЛИЧНОЕ СОСТОЯНИЕ ПРАВИТЕЛЯ</span><h2>${r.ill ? 'Лекарь отменил новые аудиенции' : 'Правление требует сил'}</h2><div class="ruler-meters"><span>Ваше здоровье <b>${r.health}%</b></span><span>Переутомление <b>${r.fatigue}%</b></span><span>Приёмов сверх нормы за месяц <b>${r.overtimeThisMonth}</b></span></div><p class="ruler-warning ${r.fatigue >= 65 || r.ill ? 'negative' : ''}">${esc(r.warning)}</p><p class="muted">Это ваше личное состояние. Показатель здоровья княжества относится к жителям. Совет продолжит разбирать срочные дела, пока вы восстанавливаетесь.</p></div><div class="ruler-actions"><button class="button secondary" data-action="overtime" ${r.canOvertime ? '' : 'disabled'}>Работать сверх нормы · ещё один приём</button><button class="button quiet" data-action="rest-ruler" ${r.canRest ? '' : 'disabled'}>Отменить приёмы и отдохнуть</button></div>`;
  }
  function renderChat(v) {
    const p = v.characters.find(p => p.id === ui.chat?.personId); if (!p) return;
    const topic = (p.topics || []).find(t => t.id === ui.chat.topicId);
    $('#chat-content').innerHTML = `<span class="eyebrow">РАЗГОВОР БЕЗ ПРОШЕНИЯ</span><div class="scene-person">${portrait(p)}<div><h2>${esc(p.name)}</h2><p class="muted">${esc(p.role)}</p><p class="scene-temperament">${esc(p.temperament || p.description)}</p></div></div><p class="chat-intro">Можно узнать человека и его взгляд на жизнь княжества. Разговор не требует денег и не расходует государственные поручения или лимит личных дел. Повторное чтение не даёт наград.</p>${v.ruler?.ill ? '<p class="negative">Во время болезни новые разговоры отложены. Прежние записи можно перечитать.</p>' : ''}<div class="chat-questions">${(p.topics || []).map(t=>`<button class="button secondary ${topic?.id === t.id ? 'selected' : ''}" data-talk-person="${esc(p.id)}" data-talk-topic="${esc(t.id)}" ${v.ruler?.ill && !t.asked ? 'disabled' : ''}>${t.asked ? 'Перечитать: ' : ''}${esc(t.title)}</button>`).join('')}</div>${topic?.asked ? `<section id="chat-reply"><span class="eyebrow">${esc(p.name)} ОТВЕЧАЕТ</span>${topic.response.split('\n').map(text=>`<p>${esc(text)}</p>`).join('')}<small>Ответ записан в вашей записной книжке.</small></section>` : '<p class="muted chat-prompt">Выберите вопрос, который хотите задать.</p>'}`;
  }
  function renderScene(v) {
    const scene = v.encounters.find(e => e.id === ui.scene); if (!scene) return;
    const selected = scene.choices.find(c => c.id === scene.choice);
    const result = scene.result;
    const relations = (result?.relations || []).map(r => {
      const description = r.before !== r.after ? `${r.before} → ${r.after}` : r.direction === 'improved' ? `отношения улучшились; остаются ${r.after.toLowerCase()}` : r.direction === 'worsened' ? `отношения ухудшились; остаются ${r.after.toLowerCase()}` : r.after;
      return `<p>${esc(r.name)}: ${esc(description)}.</p>`;
    }).join('');
    const resultHTML = scene.resolved ? `<section id="scene-result" class="adviser scene-result" aria-live="polite"><span class="eyebrow">РЕШЕНИЕ ПРИНЯТО</span><p>${esc(selected?.title || '')}</p><p class="scene-afterword">${esc(result?.narrative || 'Встреча завершена. Записи о решении сохранены в летописи.')}</p>${result?.changes ? changesHTML(result.changes) : '<p class="muted">Точные изменения этой старой встречи в сохранении не записаны.</p>'}<div class="result-facts">${typeof result?.trustChange === 'number' ? `<p class="trust-delta">${esc(scene.person.name)}: доверие ${signed(result.trustChange)}.</p>` : ''}${relations}</div></section>` : `<p class="muted scene-hint">Личное внимание: ${v.attention}. Встреча не расходует лимит государственных приказов.</p><div class="scene-choices">${scene.choices.map(c => `<button class="choice" data-story-choice="${c.id}" ${c.disabled ? 'disabled' : ''}><strong>${esc(c.title)}</strong><span class="choice-description">${esc(c.description)}</span><small>${c.gold ? `Необходимо: ${c.gold} монет` : 'Без расходов монет'}${c.food ? ` · ${c.food} зерна` : ''}${c.disabled ? ' · сейчас недоступно' : ''}</small></button>`).join('')}</div>`;
    $('#scene-content').innerHTML = `<span class="eyebrow">${esc(scene.type)} · ${esc(scene.place)}</span><div class="scene-person">${portrait(scene.person)}<div><h2>${esc(scene.title)}</h2><p class="muted">${esc(scene.person.name)} · ${esc(scene.person.role)}</p><p class="scene-temperament">${esc(scene.person.temperament || scene.person.description)}</p></div></div><section class="scene-request"><span class="eyebrow">${scene.resolved ? 'С ЧЕМ К ВАМ ПРИШЛИ' : 'ЧЕГО ОТ ВАС ХОТЯТ'}</span><p>${esc(scene.request || scene.title)}</p></section><div class="scene-story">${scene.text.split('\n').map(p => `<p>${esc(p)}</p>`).join('')}</div><p class="scene-quote">${esc(scene.quote)}</p>${scene.origin !== null ? `<p class="event-cause">Продолжение вашего решения в ${esc(G.date(scene.origin).toLowerCase())}.</p>` : ''}${resultHTML}`;
  }
  function renderChart(v) {
    const data = v.metrics.slice(-(ui.range + 1)), key = ui.metric, values = data.map(m => m.values[key]);
    const lo = Math.min(...values), hi = Math.max(...values), span = Math.max(4, hi - lo), min = Math.max(0, lo - span * 0.15), max = hi + span * 0.2;
    const width = 900, left = 58, right = 870, top = 25, bottom = 230;
    const point = (m, i) => [data.length === 1 ? (left + right) / 2 : left + i / (data.length - 1) * (right - left), bottom - (m.values[key] - min) / (max - min) * (bottom - top)];
    const points = data.map(point), path = points.map(([x,y],i) => `${i ? 'L' : 'M'}${x.toFixed(1)} ${y.toFixed(1)}`).join(' ');
    const labels = [...new Set([0, Math.floor((data.length - 1) / 2), data.length - 1])];
    $('#metric-chart').innerHTML = `<div class="chart-description">${esc(G.METRICS[key])}: ${fmt(values[0])} → ${fmt(values.at(-1))} <small>(${signed(values.at(-1) - values[0])})</small></div><svg class="chart" viewBox="0 0 ${width} 275" role="group" aria-label="График: ${esc(G.METRICS[key])}">${[0,1,2,3].map(i => {const y = top + i / 3 * (bottom - top); return `<path d="M${left} ${y}H${right}" stroke="#45553c" stroke-width="1"/><text x="${left - 10}" y="${y + 4}" text-anchor="end">${Math.round(max - i / 3 * (max - min))}</text>`;}).join('')}${data.length > 1 ? `<path d="${path} L${right} ${bottom} L${left} ${bottom}Z" fill="#bdaf6c" opacity=".07"/><path d="${path}" stroke="#d8ba79" stroke-width="2.5" fill="none"/>` : ''}${points.map(([x,y],i) => `<circle cx="${x}" cy="${y}" r="${data.length > 24 ? 2.5 : 4}" tabindex="0" aria-label="${esc(G.date(data[i].month))}: ${values[i]}"><title>${esc(G.date(data[i].month))}: ${esc(G.METRICS[key])} ${values[i]}</title></circle>`).join('')}${labels.map(i => `<text x="${point(data[i], i)[0]}" y="260" text-anchor="${i === 0 && data.length > 1 ? 'start' : i === data.length - 1 && data.length > 1 ? 'end' : 'middle'}">${esc(G.date(data[i].month))}</text>`).join('')}</svg>${data.length === 1 ? '<p class="muted">Пока есть только начальная точка. Первый результат появится после завершения месяца.</p>' : ''}`;
  }
  function renderHistory(v) {
    $('#history').innerHTML = v.history.map(h => `<article class="history-item ${esc(h.kind)}"><span class="history-date">${esc(G.date(h.month))}</span><p class="history-text">${esc(h.text)}</p>${Object.keys(h.changes).length ? changesHTML(h.changes) : ''}<p class="history-reason">${esc(h.reason)}</p></article>`).join('');
    $('#chapter-button').hidden = !v.chapter;
    renderChart(v);
  }
  function renderChapter(v) {
    const c = v.chapter; if (!c) return;
    $('#chapter-content').innerHTML = `<span class="eyebrow">${c.final ? 'РАЗВЯЗКА КАМПАНИИ' : `ГЛАВА ${c.year} · ИТОГИ ПРАВЛЕНИЯ`}</span><h2>${esc(c.title)}</h2><p class="chapter-story">${esc(c.story)}</p><div class="chapter-stats">${['gold','food','stability','army','health','science'].map(k => `<div class="chapter-stat">${esc(G.METRICS[k])}<b>${fmt(c.initial[k])} → ${fmt(c.values[k])}</b><span class="${c.values[k] >= c.initial[k] ? 'positive' : 'negative'}">${signed(c.values[k] - c.initial[k])} с начала кампании</span></div>`).join('')}</div><p class="muted" style="margin-top:16px">Построено уровней: ${c.buildings}. Враждебных соседей: ${c.hostile} из 3. ${c.final ? 'Начните новую историю, чтобы попробовать другие решения.' : 'Глава завершена. Состояние мира и последствия сохранятся в следующем году.'}</p>`;
    $('#continue-chapter').textContent = c.final ? 'Вернуться к летописи' : 'Продолжить правление →';
  }
  function render() {
    const v = G.getView(state);
    if(v.month>0||v.history.length>1)ui.mapStarted=true;
    $('#date').textContent = v.date; $('#rule-year').textContent = `${v.yearOfRule}-й год правления`;
    $('#next-month').disabled = v.ended || Boolean(v.event) || Boolean(v.chapter && !v.chapter.acknowledged);
    $('#turn-hint').textContent = v.ended ? 'Правление завершено' : v.event ? 'Совет ожидает решения' : v.chapter && !v.chapter.acknowledged ? 'Прочитайте итоги года' : `${v.ap}/2 новых приказов · ${v.attention}/2 личных дел`;
    $('#ended').hidden = !v.ended;
    if (v.ended) $('#ended').innerHTML = '<h2>История этого правления закончилась</h2><p>Государство потеряло устойчивость. В летописи можно увидеть, какие решения к этому привели.</p>';
    renderHome(v); renderStats(v); renderCouncil(v); renderOrders(v); renderIntel(v); renderCourt(v); renderHistory(v); renderChapter(v);
    if (ui.scene !== null) renderScene(v);
    if (ui.chat) renderChat(v);
    window.PopMilitaryUI.render(v, { quote: opts => G.militaryQuote(state, opts) });
    const battle = v.military?.battle;
    $('#military-alert').hidden = !battle;
    if (battle) $('#military-alert').innerHTML = `<span>На рубежах идёт бой: ${esc(battle.locationName)}. Выберите приказ или отступление.</span><button class="button secondary" data-tab="army">К войску →</button>`;
    if (battle) { $('#next-month').disabled = true; $('#turn-hint').textContent = 'Сначала завершите столкновение'; }
    setTab(ui.tab);
    if (storageOkay) $('#save-state').textContent = `Ключ мира: ${v.seed} · локальная кампания`;
    if (v.chapter && !v.chapter.acknowledged && !v.military?.battle && !turnBusy && !$('#chapter-dialog').open) {
      for (const dialog of document.querySelectorAll('dialog[open]')) dialog.close();
      $('#chapter-dialog').showModal();
    }
  }
  function downloadSave() {
    const blob = new Blob([G.serialize(state)], { type: 'application/json;charset=utf-8' });
    const url = URL.createObjectURL(blob), a = document.createElement('a');
    a.href = url; a.download = `cena-vlasti-${1248 + Math.floor(state.month / 12)}-${String(state.month % 12 + 1).padStart(2,'0')}.json`;
    document.body.append(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
  $('#chart-metric').innerHTML = Object.entries(G.METRICS).map(([key, title]) => `<option value="${key}">${title}</option>`).join('');
  document.addEventListener('click', event => {
    const b = event.target.closest('button, a[data-tab]'); if (!b || b.disabled) return;
    if(b.dataset.mapAction){if(b.dataset.mapAction==='in')changeMapZoom(.2);else if(b.dataset.mapAction==='out')changeMapZoom(-.2);else resetMap();return;}
    if (b.dataset.tab) { event.preventDefault();const repeated=b.closest('nav')&&ui.mapStarted&&ui.tab===b.dataset.tab&&b.dataset.tab!=='home';setTab(repeated?'home':b.dataset.tab, true); return; }
    if (b.dataset.filter) { ui.filter = b.dataset.filter; renderOrders(G.getView(state)); return; }
    if (b.dataset.order) { perform(s => G.queueOrder(s, b.dataset.order, ui.target), 'Поручение принято. Следите за сроком в разделе совета.'); return; }
    if(b.dataset.appointOffice){perform(s=>G.appointOfficial(s,b.dataset.appointOffice,b.dataset.appointCandidate),'Назначение вступило в силу. Плюсы и риски записаны в хронике.');return;}
    if (b.dataset.scout) { perform(s => G.queueOrder(s, 'scout', b.dataset.scout), 'Разведчик отправлен. Ответ ожидается через два месяца.'); return; }
    if (b.dataset.chat) { ui.chat = {personId:b.dataset.chat, topicId:null}; renderChat(G.getView(state)); $('#chat-dialog').showModal(); return; }
    if (b.dataset.talkPerson) { ui.chat = {personId:b.dataset.talkPerson,topicId:b.dataset.talkTopic}; perform(s => G.talkToCharacter(s,b.dataset.talkPerson,b.dataset.talkTopic)); return; }
    if (b.dataset.choice) { perform(s => G.chooseEvent(s, b.dataset.choice), 'Решение принято. Изменения записаны в хронике.'); return; }
    if (b.dataset.scene) { ui.scene = Number(b.dataset.scene); renderScene(G.getView(state)); $('#scene-dialog').showModal(); return; }
    if (b.dataset.storyChoice) { perform(s => G.resolveEncounter(s, ui.scene, b.dataset.storyChoice), 'Встреча завершена. Последствия записаны в летописи.'); return; }
    switch (b.dataset.action) {
      case 'overtime': perform(G.workOvertime); break;
      case 'rest-ruler': perform(G.restRuler); break;
      case 'close-chat': $('#chat-dialog').close(); ui.chat = null; break;
      case 'next': nextMonth(); break;
      case 'new': $('#world-seed').value = `Арден-${Date.now().toString(36)}`; $('#new-game-dialog').showModal(); break;
      case 'close-new': $('#new-game-dialog').close(); break;
      case 'close-scene': $('#scene-dialog').close(); ui.scene = null; break;
      case 'save': if (store(MANUAL)) toast('Ручное сохранение записано в этом браузере.'); else toast('Браузер запретил запись. Скачайте сохранение в разделе хроники.', true); break;
      case 'load':
        try { const raw = localStorage.getItem(MANUAL) || localStorage.getItem(AUTO); if (!raw) throw new Error('Сохранений пока нет. Сначала сохраните кампанию или откройте файл.'); const loaded = G.deserialize(raw); state = loaded; ui.scene = null; ui.chat = null; ui.tab = 'home'; render(); toast('Кампания восстановлена.'); } catch(error) { toast(error.message, true); }
        break;
      case 'export': try { downloadSave(); } catch(error) { toast(error.message, true); } break;
      case 'import': $('#save-file').click(); break;
      case 'chapter': if (state.chapter) { renderChapter(G.getView(state)); $('#chapter-dialog').showModal(); } break;
      case 'continue': $('#chapter-dialog').close(); perform(G.acknowledgeChapter); break;
    }
  });
  document.addEventListener('pop:military', e => { const d=e.detail; if(d.action==='launch') perform(s=>G.launchMilitary(s,d),'Поход сформирован. Состав отрядов и срок пути показаны в «Вестях с дорог».'); else if(d.action==='tactic') perform(s=>G.battleOrder(s,d.tactic),'Боевой приказ исполнен: силы, позиции и журнал столкновения обновлены.'); });
  document.addEventListener('wheel',event=>{if(!event.target.closest('.dominion-map')||!ui.mapStarted)return;event.preventDefault();changeMapZoom(event.deltaY<0?.15:-.15);},{passive:false});
  document.addEventListener('pointerdown',event=>{const map=event.target.closest('.dominion-map');if(!map||event.target.closest('button'))return;mapDrag={id:event.pointerId,startX:event.clientX,startY:event.clientY,x:ui.map.x,y:ui.map.y};map.setPointerCapture?.(event.pointerId);map.classList.add('dragging');});
  document.addEventListener('pointermove',event=>{if(!mapDrag||mapDrag.id!==event.pointerId)return;ui.map.x=mapDrag.x+event.clientX-mapDrag.startX;ui.map.y=mapDrag.y+event.clientY-mapDrag.startY;applyMapTransform();});
  document.addEventListener('pointerup',event=>{if(!mapDrag||mapDrag.id!==event.pointerId)return;mapDrag=null;$('.dominion-map')?.classList.remove('dragging');});
  $('#order-target').addEventListener('change', e => { ui.target = e.target.value; renderOrders(G.getView(state)); });
  $('#chart-metric').addEventListener('change', e => { ui.metric = e.target.value; renderChart(G.getView(state)); });
  $('#chart-range').addEventListener('change', e => { ui.range = Number(e.target.value); renderChart(G.getView(state)); });
  $('#new-game-form').addEventListener('submit', e => {
    e.preventDefault();
    try { const fresh = G.createGame({ seed: $('#world-seed').value, scenario: $('#scenario').value }); state = fresh; ui.scene = null; ui.chat = null; ui.tab = 'home'; ui.mapStarted = false; $('#new-game-dialog').close(); store(AUTO); render(); showIntroduction(true); toast('Новая история началась. Ручное сохранение не удалено.'); }
    catch(error) { toast(error.message, true); }
  });
  $('#save-file').addEventListener('change', async e => {
    const file = e.target.files[0]; if (!file) return;
    try { if (file.size > 1000000) throw new Error('Файл слишком велик для сохранения игры.'); const loaded = G.deserialize(await file.text()); state = loaded; ui.scene = null; ui.chat = null; ui.tab = 'home'; store(AUTO); render(); toast('Кампания загружена из файла.'); }
    catch(error) { toast(error.message, true); }
    finally { e.target.value = ''; }
  });
  // Escape не позволяет пропустить обязательное прочтение итогов, но закрывает обычные встречи.
  $('#chapter-dialog').addEventListener('cancel', e => { e.preventDefault(); $('#chapter-dialog').close(); perform(G.acknowledgeChapter); });
  window.PopPresentation.init({onIntroDone:()=>{ try { localStorage.setItem(`popIntro06:${state.seed}`,'seen'); } catch {} setTab('home',true); }});
  try { const raw = localStorage.getItem(AUTO); if (raw) state = G.deserialize(raw); }
  catch { storageOkay = false; toast('Автосохранение недоступно. Можно играть дальше и скачивать сохранение в файл через раздел хроники.', true); }
  render();
  showIntroduction();
})();
