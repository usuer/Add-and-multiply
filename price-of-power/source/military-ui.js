(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.PopMilitaryUI = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function () {
  'use strict';
  const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  const number = n => Number.isFinite(Number(n)) ? Math.round(Number(n)) : 0;
  const missionNames = { patrol: 'Патрулирование', expedition: 'Поход против разбойников', defend: 'Защита рубежа', return: 'Возвращение в столицу' };
  const supplyNames = { light: 'Лёгкий обоз', normal: 'Обычный обоз', full: 'Полный обоз' };
  const symbols = { capital: '♜', forest: '♧', west: '⌂', north: '△', ford: '≈', east: '◇' };
  const fallbackPosition = { capital: [76, 40], forest: [23, 24], west: [20, 69], north: [55, 14], ford: [50, 66], east: [83, 78] };
  let current = null, quoteFn = null, provinceQuoteFn = null, battleDrag = null;
  const ui = { target: 'forest', mission: 'expedition', supply: 'normal', selected: null, provinceTarget:'forest', provinceProject:'watch', battleUnit:null, battleTarget:'enemy-main',battleId:null,battlePlans:{},battleFeature:null,battleHelp:true,animatedRound:null };
  const provinceWorks = {
    watch:{name:'Дозорные посты',description:'Сдерживают рост разбойников и недовольства в этой местности.'},
    depot:{name:'Провиантские склады',description:'Поддерживают снабжение стоящих здесь отрядов.'},
    route:{name:'Обустройство дороги',description:'Сокращает путь походов через местность.'},
  };
  const callbacks = () => ({quote:quoteFn,provinceQuote:provinceQuoteFn});
  function weatherName(value) { return typeof value === 'string' ? ({clear:'Ясная погода',rain:'Дождь и раскисшие дороги',snow:'Зима, снег на дорогах'})[value] || value : value?.label || value?.name || 'Обычная погода'; }
  function estimate(value) {
    if (value && typeof value === 'object' && Number.isFinite(value.min) && Number.isFinite(value.max)) return `${number(value.min)}–${number(value.max)}`;
    if (Number.isFinite(value)) return `около ${number(value)}`;
    return 'не установлена';
  }
  function position(location) {
    const fallback = fallbackPosition[location.id] || [50, 50];
    let x = Number(location.x), y = Number(location.y);
    if (!Number.isFinite(x) || !Number.isFinite(y)) return fallback;
    // Поддерживаем процентные координаты и координаты условного холста 1000×530.
    if (x > 100 || y > 100) { x = x / 10; y = y / 5.3; }
    return [Math.max(10, Math.min(90, x)), Math.max(12, Math.min(86, y))];
  }
  function dispatch(detail) {
    if (typeof document !== 'undefined') document.dispatchEvent(new CustomEvent('pop:military', { detail }));
  }
  function meter(label, value, danger = false) {
    const bounded = Math.max(0, Math.min(100, number(value)));
    return `<div class="military-meter ${danger ? 'strain' : ''}"><span>${esc(label)} <b>${bounded}%</b></span><div><i style="width:${bounded}%"></i></div></div>`;
  }
  function unitHTML(unit) {
    const ready = unit.status === 'ready' && unit.strength > 0;
    const checked = ui.selected?.has(unit.id) ? 'checked' : '';
    return `<article class="military-unit ${ready ? 'ready' : 'unavailable'}" data-military-unit="${esc(unit.id)}"><div class="section-heading"><span class="unit-emblem" aria-hidden="true">${unit.type === 'archers' ? '➶' : unit.type === 'cavalry' ? '♞' : '⚔'}</span><span class="badge">${esc(unit.statusLabel || (ready ? 'Готов к приказу' : unit.status === 'battle' ? 'В сражении' : 'В походе'))}</span></div><h3>${esc(unit.name)}</h3><p class="unit-type">${esc(unit.typeLabel || unit.type)}</p><div class="unit-strength"><b>${number(unit.strength)}</b><span>сила отряда</span></div><p class="unit-position">${esc(unit.locationName || unit.location || 'В дороге')}</p>${meter('Боевой дух', unit.morale)}${meter('Усталость', unit.fatigue, true)}<div class="unit-facts"><span>Опыт <b>${number(unit.experience)}</b></span><span>Провиант <b>${number(unit.food)}</b></span></div><label class="military-unit-select"><input type="checkbox" data-unit="${esc(unit.id)}" ${checked} ${ready ? '' : 'disabled'}>Включить в поход</label></article>`;
  }
  function mapHTML(m) {
    const lines = [['capital', 'north'], ['capital', 'east'], ['capital', 'ford'], ['ford', 'west'], ['ford', 'forest'], ['forest', 'north']].map(([a,b]) => {
      const first = m.locations.find(l => l.id === a), second = m.locations.find(l => l.id === b);
      if (!first || !second) return '';
      const [x,y] = position(first), [x2,y2] = position(second);
      return `<path d="M${x * 10} ${y * 5.3}L${x2 * 10} ${y2 * 5.3}"/>`;
    }).join('');
    return `<div class="campaign-map-scroll"><div id="campaign-map" class="campaign-map"><svg viewBox="0 0 1000 530" aria-hidden="true" class="campaign-geography"><path d="M0 0H430L505 90 425 238 289 304 0 250Z" fill="#233f2d" opacity=".7"/><path d="M1000 530H180L294 351 531 315 646 454Z" fill="#a28c4d" opacity=".18"/><path d="M440 0Q580 80 505 175T494 320T440 530" fill="none" stroke="#94bbb0" stroke-width="18" opacity=".55"/><path d="M440 0Q580 80 505 175T494 320T440 530" fill="none" stroke="#d6d2af" stroke-width="2" opacity=".5"/><g fill="none" stroke="#d5bc7e" stroke-opacity=".65" stroke-width="3" stroke-dasharray="7 7">${lines}</g><g fill="#9aa487" opacity=".5"><path d="m420 65 34-52 32 52Zm65 2 43-67 41 67Zm77 13 33-48 32 48Zm-419 74 13-28 13 28Zm22 17 13-28 13 28Zm-40 3 13-28 13 28Z"/></g></svg>${m.locations.map(l => {
      const [x,y] = position(l), threat = number(l.bandits) >= 50 || number(l.unrest) >= 60;
      return `<button class="campaign-location ${ui.target === l.id ? 'selected' : ''} ${threat ? 'threatened' : ''}" data-military-location="${esc(l.id)}" style="left:${x}%;top:${y}%" aria-pressed="${ui.target === l.id}" aria-label="${esc(l.name)}, ${esc(l.terrainLabel)}, разбойники ${number(l.bandits)}, волнения ${number(l.unrest)}"><span class="location-emblem" aria-hidden="true">${symbols[l.id] || '◇'}</span><strong>${esc(l.name)}</strong><small>${esc(l.terrainLabel)}</small>${l.friendlyUnits ? `<em>${Array.isArray(l.friendlyUnits) ? l.friendlyUnits.length : number(l.friendlyUnits)} отр. здесь</em>` : ''}${threat ? '<b class="location-danger">Тревожно</b>' : ''}</button>`;
    }).join('')}<span class="map-compass" aria-hidden="true">С<br>↑</span></div></div>`;
  }
  function locationHTML(m) {
    const l = m.locations.find(l => l.id === ui.target) || m.locations[0];
    if (!l) return '';
    return `<div id="military-location-detail" class="military-location-detail"><div><span class="eyebrow">ВЫБРАННАЯ МЕСТНОСТЬ</span><h3>${esc(l.name)}</h3><p>${esc(l.terrainLabel)}${l.id === 'capital' ? ' · княжеская крепость' : ''}</p></div><div>${meter('Разбойники', l.bandits, true)}${meter('Недовольство', l.unrest, true)}</div><p class="muted">${l.terrain === 'forest' ? 'Лес стесняет конницу и скрывает подходы. Разведка и усталость отряда особенно важны.' : l.terrain === 'river' || l.id === 'ford' ? 'Переправа замедляет наступление. Защитники могут воспользоваться узким подходом.' : l.terrain === 'hill' || l.id === 'north' ? 'Подъём утомляет войска. Высота помогает держать оборону и вести стрельбу.' : l.id === 'capital' ? 'В столице отряды опираются на укрепления. Ушедшие в поход не защищают стены одновременно.' : 'Открытая местность оставляет пространство для манёвра. Припасов должно хватить на дорогу и столкновение.'}</p></div>`;
  }
  function marchesHTML(m) {
    const yours = (m.marches || []).map(a => `<article class="march-card"><div class="section-heading"><strong>${esc(a.missionLabel || missionNames[a.mission] || 'Поход')}</strong><span class="badge">${number(a.remaining)} мес. до прибытия</span></div><h3>→ ${esc(a.targetName || a.target)}</h3><p>${(a.unitIds || []).length} отр. · ${esc(supplyNames[a.supply] || a.supply || 'Обоз')} · провиант ${number(a.food)}</p><div class="march-progress"><i style="width:${a.duration ? Math.min(100, (a.duration - a.remaining) / a.duration * 100) : 0}%"></i></div></article>`).join('');
    const incoming = (m.enemyMarches || []).map(a => `<article class="march-card incoming"><span class="eyebrow">ПРИБЛИЖАЕТСЯ ЧУЖОЙ ОТРЯД</span><h3>${esc(a.attackerName)} → ${esc(a.targetName || a.target)}</h3><p>Оценка силы: ${esc(estimate(a.estimate))}. До ожидаемого прибытия ${number(a.remaining)} мес.</p><p>Пока противник в пути, можно собрать защитников в выбранной местности.</p></article>`).join('');
    return yours || incoming ? yours + incoming : '<p class="military-empty">Отряды не находятся в походе. Выберите место на карте и подготовьте выступление.</p>';
  }
  function battleHTML(m) {
    const b = m.battle;
    if (!b) return `<section id="battle-area" class="battle-idle"><span class="eyebrow">КОГДА ПРИДЁТСЯ СРАЖАТЬСЯ</span><h2>Местность — тоже участник боя</h2><p>Столкновение начнётся, когда отряды встретятся в одной местности. Вы увидите состояние людей и сможете отдавать приказы по ходу боя или отступить.</p></section>`;
    const participants = m.units.filter(u => b.unitIds.includes(u.id));
    if(ui.battleId!==b.id){ui.battleId=b.id;ui.battlePlans={};ui.battleFeature=null;ui.battleHelp=true;}
    const advance=Math.min(2,number(b.phase)), playerTop=[76,64,57][advance], enemyTop=[24,36,43][advance],unitTop=u=>76-Math.min(2,Math.max(0,number(b.unitPositions?.[u.id])))*9.5;
    const unitKind=type=>/arch|стрел/i.test(type)?'archers':/caval|конн/i.test(type)?'cavalry':/reserve|резерв/i.test(type)?'reserve':'infantry';
    const formation=(type,enemy=false,depth=3)=>{const kind=unitKind(type),count=kind==='cavalry'?6:9,cols=Math.ceil(count/depth),lines=Math.ceil(count/cols),stepX=kind==='cavalry'?36:28,stepY=kind==='cavalry'?48:40,rowIndex=(enemy?3:0)+({infantry:0,archers:1,cavalry:2,reserve:0})[kind];return `<div class="unit-formation topdown painted-individual ${enemy?'hostile':''} formation-${kind} depth-${depth}" role="img" aria-label="${enemy?'Вражеский':'Наш'} строй: ${esc(type)}, ${depth} ${depth===1?'линия':'линии'}">${Array.from({length:count},(_,i)=>{const row=Math.floor(i/cols),inRow=Math.min(cols,count-row*cols),col=i-row*cols,x=(col-(inRow-1)/2)*stepX,y=(row-(lines-1)/2)*stepY;return `<i class="painted-fighter" style="left:calc(50% + ${x}px);top:calc(50% + ${y}px);background-position:${i*12.5}% ${rowIndex*20}%"></i>`}).join('')}</div>`;};
    const coordOf=(u,i)=>ui.battlePlans[u.id]||b.unitCoords?.[u.id]||{x:22+i*28,y:unitTop(u)-(i%2)*3},rows=b.unitFormations||{},roundActions=b.lastRoundActions?.length?b.lastRoundActions:(b.lastAction?[b.lastAction]:[]);
    const playerTokens = participants.map((u,i)=>{const c=coordOf(u,i),planned=ui.battlePlans[u.id],depth=rows[u.id]||2,acted=roundActions.some(a=>a.unitId===u.id);return `<div class="battle-token player-token phase-${advance} rows-${depth} ${planned?'planned':''} ${acted?'acting':''} ${u.id===ui.battleUnit?'selected-unit':''}" data-battle-unit="${esc(u.id)}" data-unit-kind="${unitKind(u.type)}" style="left:${number(c.x)}%;top:${number(c.y)}%">${formation(u.type,false,depth)}<div class="formation-label"><b>${esc(u.name)}</b><small>${planned?'ПЛАН: ':''}${esc(u.typeLabel)} · ${number(u.strength)} · дух ${number(u.morale)}%</small><i><span style="width:${Math.max(8,Math.min(100,u.morale))}%"></span></i></div></div>`}).join('');
    const enemyTokens=(b.enemyUnits||[]).filter(u=>u.strength>0).map((u,i)=>`<div class="battle-token enemy-token phase-${advance} ${roundActions.some(a=>a.targetId===u.id)?'target-hit':''} ${u.id===ui.battleTarget?'selected-target':''}" data-battle-enemy="${esc(u.id)}" data-unit-kind="${unitKind(u.type)}" style="left:${14+i*18}%;top:${enemyTop+(i%2)*5}%">${formation(u.type,true,3)}<div class="formation-label"><b>${esc(u.name)}</b><small>${esc(u.type)} · около ${number(u.strength)}</small><i><span style="width:${Math.max(8,Math.min(100,b.enemyMorale))}%"></span></i></div></div>`).join('');
    const featureIcon={command:'⚑',cart:'▣',stakes:'╳',reserve:'♜',trees:'♣',hill:'▲',rocks:'◆',river:'≈',bridge:'═',farm:'❧',ditch:'⌁',wall:'▥',tower:'♜',gate:'▤',arrows:'➶',wounded:'✚'};
    const features=(b.features||[]).map(f=>`<button class="battle-object object-${esc(f.kind)} ${ui.battleFeature===f.id?'selected':''}" data-battle-feature="${esc(f.id)}" style="left:${number(f.x)}%;top:${number(f.y)}%" title="${esc(f.effect)}"><b>${featureIcon[f.kind]||'◆'}</b><span>${esc(f.label)}</span></button>`).join('');
    const allTactics = b.tactics || [{id:'guard',name:'Держать строй',description:'Сберечь людей и встретить удар.'},{id:'advance',name:'Наступать',description:'Давить на противника основными силами.'},{id:'withdraw',name:'Отступить',description:'Выйти из боя, сохранив тех, кто сможет уйти.'}];
    const acted=new Set(b.actedUnitIds||[]),aliveParticipants=participants.filter(u=>u.strength>0),waiting=aliveParticipants.filter(u=>!acted.has(u.id));
    if(!ui.battleUnit||!participants.some(u=>u.id===ui.battleUnit&&u.strength>0)||acted.has(ui.battleUnit)&&waiting.length)ui.battleUnit=(waiting[0]||aliveParticipants[0])?.id||null;
    const acting=participants.find(u=>u.id===ui.battleUnit),targets=(b.enemyUnits||[]).filter(u=>u.strength>0),tactics=allTactics.filter(t=>!t.types||t.types.includes(acting?.type));
    const alreadyActed=acted.has(acting?.id),restricted=t=>acting?.type==='archers'&&b.phase===0&&['melee','fallback'].includes(t.id),actedCount=aliveParticipants.filter(u=>acted.has(u.id)).length;
    const actingIndex=Math.max(0,participants.findIndex(u=>u.id===ui.battleUnit)),targetIndex=Math.max(0,targets.findIndex(u=>u.id===ui.battleTarget)),activeCoord=acting?coordOf(acting,actingIndex):{x:50,y:75},pathX1=number(activeCoord.x),pathY1=number(activeCoord.y),pathX2=14+targetIndex*18,pathY2=enemyTop+(targetIndex%2)*5;
    const plannedPaths=Object.entries(ui.battlePlans).map(([id,p])=>{const u=participants.find(x=>x.id===id),i=participants.indexOf(u),base=b.unitCoords?.[id]||{x:22+i*28,y:78},ti=Math.max(0,targets.findIndex(t=>t.id===p.targetId));return `<line class="planned-move" x1="${number(base.x)}" y1="${number(base.y)}" x2="${number(p.x)}" y2="${number(p.y)}" marker-end="url(#move-arrow)"/><line class="planned-attack" x1="${number(p.x)}" y1="${number(p.y)}" x2="${14+ti*18}" y2="${enemyTop+(ti%2)*5}" marker-end="url(#order-arrow)"/>`}).join('');
    const orderPath=`<svg class="battle-grid-overlay" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true"><defs><marker id="order-arrow" markerWidth="5" markerHeight="5" refX="4" refY="2.5" orient="auto"><path d="M0 0 5 2.5 0 5Z"/></marker><marker id="move-arrow" markerWidth="5" markerHeight="5" refX="4" refY="2.5" orient="auto"><path d="M0 0 5 2.5 0 5Z"/></marker></defs>${plannedPaths||`<line x1="${pathX1}" y1="${pathY1}" x2="${pathX2}" y2="${pathY2}" marker-end="url(#order-arrow)"/>`}</svg>`;
    const turnOrder=`<div class="battle-turn-order"><strong>${b.deployed?'Общий план раунда':'Расстановка войск'}</strong>${aliveParticipants.map(u=>`<button data-battle-unit="${esc(u.id)}" class="${ui.battlePlans[u.id]?'done':u.id===ui.battleUnit?'current':''}"><i>${ui.battlePlans[u.id]?'✓':'•'}</i>${esc(u.name)}<small>${ui.battlePlans[u.id]?b.deployed?'приказ подготовлен':'позиция изменена':b.deployed?'ожидает приказа':'нажмите для выбора'}</small></button>`).join('')}</div>`;
    const selectedRows=rows[acting?.id]||2,feature=(b.features||[]).find(f=>f.id===ui.battleFeature);
    const arrows=`<div class="map-orders" aria-label="Перемещение выбранного отряда"><button data-battle-move="up" title="Вперёд">↑</button><button data-battle-move="left" title="Влево">←</button><button data-battle-move="hold" title="Остаться">●</button><button data-battle-move="right" title="Вправо">→</button><button data-battle-move="down" title="Назад">↓</button></div>`;
    const formations=!b.deployed?`<div class="formation-orders"><span>Глубина строя</span>${[1,2,3].map(n=>`<button data-battle-rows="${n}" class="${selectedRows===n?'active':''}">${n} ${n===1?'линия':n===2?'линии':'линии'}</button>`).join('')}</div>`:'';
    const tacticalControl=`${turnOrder}<section class="direct-command"><div><span class="eyebrow">${b.deployed?'ПРИКАЗ ВЫБРАННОМУ ОТРЯДУ':'ПЕРЕД БОЕМ'}</span><h3>${esc(acting?.name||'Выберите отряд на поле')}</h3><p>${b.deployed?'Нажмите клетку или стрелку, затем выберите способ действия и цель прямо на поле. Приказ выполнится только вместе с остальными.':'Перемещайте выбранный отряд внутри светлой зоны и задайте глубину строя. Одна линия даёт широкий фронт, три — более устойчивую глубину.'}</p></div>${arrows}${formations}${acting?`<div class="unit-profile"><span>Атака <b>${acting.attack}</b></span><span>Броня <b>${acting.armor}</b></span><span>Дальность <b>${acting.range}</b></span><span>Скорость <b>${acting.speed}</b></span><p>${esc(acting.role)}</p></div>`:''}</section>${feature?`<aside class="terrain-explanation"><b>${esc(feature.label)}</b><span>${esc(feature.effect)}</span><small>${feature.kind==='cart'?'Обоз поддерживает мораль; враг может попытаться его захватить.':feature.kind==='command'?'Рядом с пунктом приказы исполняются надёжнее.':feature.kind==='stakes'?'Конница теряет силу натиска у заграждений.':'Положение отряда относительно объекта меняет укрытие, обзор или проходимость.'}</small></aside>`:''}`;
    const grid=`<div class="battle-cell-grid">${Array.from({length:45},(_,i)=>{const x=10+(i%9)*10,y=22+Math.floor(i/9)*14,allowed=b.deployed||y>=62;return `<button data-battle-cell="1" data-x="${x}" data-y="${y}" ${allowed?'':'disabled'} aria-label="Клетка ${i%9+1}, ${Math.floor(i/9)+1}"></button>`}).join('')}</div>`;
    const latest=b.log?.at(-1),a=b.lastAction,lastTarget=(b.enemyUnits||[]).find(u=>u.id===a?.targetId);
    const actionReport=a?`<div class="battle-action-result detailed" role="status"><div class="order-done"><b>${esc(a.unitName)}: ${esc(a.tacticName)}</b><span>Цель: ${esc(lastTarget?.name||'главный строй')}. ${esc(a.position)}</span><span class="terrain-result">Местность: ${esc(a.terrainEffect||'без особого влияния.')}</span><em>Ответ врага: ${esc(a.enemyResponse||'противник перестраивается и отвечает ударом.')}</em></div><div class="exchange own"><small>НАШИ ПОТЕРИ</small><strong>−${number(a.ownLoss)}</strong></div><div class="exchange enemy"><small>ПОТЕРИ ВРАГА</small><strong>−${number(a.enemyLoss)}</strong></div><div class="battle-assessment ${a.advantage>=3?'good':a.advantage<=-3?'bad':''}">${esc(a.assessment)} Дух противника: ${number(a.enemyMoraleBefore)}% → ${number(a.enemyMoraleAfter)}%.</div></div>`:latest?`<div class="battle-action-result" role="status"><b>Приказ исполнен.</b><span>${esc(latest)}</span><small>Позиции и силы на схеме обновлены.</small></div>`:'';
    const combatEffects=roundActions.length?`<svg class="combat-effect simultaneous" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">${roundActions.map((action,ai)=>{const actorIndex=Math.max(0,participants.findIndex(u=>u.id===action.unitId)),targetIndex=Math.max(0,targets.findIndex(u=>u.id===action.targetId)),actor=participants[actorIndex],c=coordOf(actor,actorIndex),x1=number(c.x),y1=number(c.y),x2=14+targetIndex*18,y2=enemyTop+(targetIndex%2)*5,count=action.tactic==='ranged'?7:3;return Array.from({length:count},(_,i)=>`<line class="${action.tactic==='ranged'?'arrow-shot':'melee-shot'}" x1="${x1+(i-3)*.35}" y1="${y1}" x2="${x2+(i-3)*.4}" y2="${y2}" style="--delay:${ai*.22+i*.06}s"/>`).join('')}).join('')}</svg>`:'';
    const readyCount=aliveParticipants.filter(u=>ui.battlePlans[u.id]?.tactic).length;
    const actionPanel=b.deployed?`<div class="battle-tactics">${tactics.map(t=>{const disabled=restricted(t),selected=ui.battlePlans[acting?.id]?.tactic===t.id;const why=restricted(t)?'Противник ещё не вошёл в ближний бой.':t.description;return `<button class="button ${selected?'primary':t.id==='withdraw'?'quiet':'secondary'}" data-battle-tactic="${esc(t.id)}" ${disabled?'disabled':''}><strong>${selected?'✓ ':''}${esc(t.name)}</strong><span>${esc(why)}</span></button>`;}).join('')}</div><button class="execute-round button primary" data-battle-execute ${readyCount===aliveParticipants.length?'':'disabled'}>Выполнить общий план · ${readyCount}/${aliveParticipants.length} приказов</button>`:`<button class="confirm-deployment button primary" data-battle-deploy>Подтвердить расстановку и начать бой</button>`;
    const currentPlan=ui.battlePlans[acting?.id],nextHint=!b.deployed?'Выберите отряд, перетащите его в светлой зоне и задайте глубину строя.':readyCount===aliveParticipants.length?'Все приказы готовы. Проверьте линии на поле и нажмите «Выполнить общий план».':currentPlan?.tactic?'Выберите следующий отряд: серые карточки ещё ждут приказа.':'Для выбранного отряда укажите клетку, цель и боевое действие.';
    const tutorial=ui.battleHelp?`<section class="battle-tutorial"><div><span class="eyebrow">КАК КОМАНДОВАТЬ</span><strong>${b.deployed?'Подготовьте общий план, затем запустите раунд':'Сначала расставьте войска'}</strong></div><ol>${b.deployed?`<li class="done">Нажмите свой отряд</li><li class="${currentPlan?'done':'current'}">Укажите клетку движения</li><li class="${currentPlan?.targetId?'done':currentPlan?'current':''}">Нажмите строй противника</li><li class="${currentPlan?.tactic?'done':currentPlan?.targetId?'current':''}">Выберите действие отряда</li><li class="${readyCount===aliveParticipants.length?'done':readyCount?'current':''}">Повторите для всех: ${readyCount}/${aliveParticipants.length}</li>`:`<li class="done">Нажмите свой отряд</li><li class="${currentPlan?'done':'current'}">Перетащите его или нажмите клетку</li><li class="current">Выберите 1, 2 или 3 линии</li><li>Расставьте остальные части</li><li>Подтвердите расстановку</li>`}</ol><p><b>Сейчас:</b> ${esc(nextHint)}</p><div class="battle-legend"><span><i class="move"></i> голубая линия — движение</span><span><i class="attack"></i> жёлтая линия — атака</span><span><i class="cell"></i> светлые клетки — доступная зона</span></div><button data-battle-help>Скрыть памятку</button></section>`:`<button class="battle-help-restore" data-battle-help>Как управлять боем?</button>`;
    const terrainMarks=({forest:'<span class="physical-zone physical-left">ГУСТОЙ ЛЕС · УКРЫТИЕ</span><span class="physical-zone physical-right">ОПУШКА · КОННИЦА МЕДЛЕННЕЕ</span>',hill:'<span class="physical-zone physical-high">ВЫСОТА · ЛУЧШИЙ ОБЗОР И СТРЕЛЬБА</span>',river:'<span class="physical-zone physical-water">БРОД · СТРОЙ НАРУШАЕТСЯ</span><span class="physical-zone physical-bridge">МОСТ · УЗКИЙ ФРОНТ</span>',plain:'<span class="physical-zone physical-open">ОТКРЫТОЕ ПОЛЕ · РАЗГОН КОННИЦЫ</span>',fortress:'<span class="physical-zone physical-wall">СТЕНЫ · СИЛЬНАЯ ОБОРОНА</span>'})[b.terrain]||'';
    return `<section id="battle-area" class="battle-card ${b.deployed?'combat-stage':'deployment-stage'}" data-phase="${number(b.phase)}"><div class="battle-heading"><div><span class="eyebrow">${b.deployed?(b.defending?'ЗАЩИТА КНЯЖЕСТВА':'СТОЛКНОВЕНИЕ'):'РАССТАНОВКА ПЕРЕД БОЕМ'}</span><h2>${esc(b.locationName)}</h2><p>${esc(b.terrainLabel)} · ${esc(weatherName(b.weather || m.weather))}</p></div><div class="battle-phase"><small>${b.deployed?`РАУНД ${number(b.phase)+1} ИЗ 3 · ПЛАН ${readyCount}/${aliveParticipants.length}`:'БОЙ ЕЩЁ НЕ НАЧАЛСЯ'}</small><strong>${b.deployed?esc(b.phaseName||`Фаза ${number(b.phase)+1}`):'Выберите исходные позиции'}</strong></div></div>${tutorial}${actionReport}<div class="battlefield terrain-${esc(b.terrain)} action-${esc(a?.tactic||'ready')}"><div class="battle-enemy-heading"><strong>${esc(b.attackerName)}</strong><small>Общая оценка силы: ${esc(estimate(b.enemyEstimate))}</small></div>${terrainMarks}<span class="battle-zone zone-enemy">Тыл противника</span><span class="battle-zone zone-contact">Линия столкновения</span><span class="battle-zone zone-friendly">${b.deployed?'Наша исходная линия':'Зона расстановки'}</span>${grid}${orderPath}${features}${enemyTokens}${playerTokens}${combatEffects}<span class="battle-field-caption">Нажмите свой отряд, затем клетку назначения. Вражеский отряд выбирается нажатием прямо по его строю.</span></div><div class="battle-condition"><span>Местность и объекты поля влияют на обзор, укрытие, проходимость и силу натиска.</span><b>Сторона: ${b.defending?'оборона':'наступление'}</b></div>${tacticalControl}${actionPanel}${b.log?.length?`<div class="battle-log" aria-live="polite"><h3>Хроника боя</h3>${b.log.map((line,i)=>`<p><b>${i+1}.</b> ${esc(line)}</p>`).join('')}</div>`:''}</section>`;
  }
  function resultHTML(result) {
    if (!result) return '';
    const changes = Object.entries(result.changes || {}).map(([key,value])=>`<span class="${value >= 0 ? 'positive' : 'negative'}">${esc(({army:'Армия',gold:'Казна',food:'Зерно',stability:'Стабильность',defense:'Оборона'})[key] || key)} ${value > 0 ? '+' : ''}${number(value)}</span>`).join('');
    return `<section id="military-result" class="military-result ${result.outcome === 'victory' ? 'victory' : ''}" aria-live="polite"><span class="eyebrow">ПОСЛЕДНЕЕ СТОЛКНОВЕНИЕ · ${esc(result.locationName)}</span><h2>${esc(result.title || ({victory:'Победа',defeat:'Поражение',retreat:'Отступление'})[result.outcome])}</h2><p>${esc(result.text)}</p><div class="changes">${changes}</div><div class="result-losses"><span>Наши потери силы: <b>${number(result.losses)}</b></span><span>Потери противника: <b>${number(result.enemyLosses)}</b></span></div>${result.log?.length ? `<details><summary>Ход столкновения</summary>${result.log.map(line=>`<p>${esc(line)}</p>`).join('')}</details>` : ''}</section>`;
  }
  function quoteHTML() {
    const m = current.military, unitIds = m.units.filter(u => ui.selected?.has(u.id) && u.status === 'ready' && u.strength > 0).map(u=>u.id);
    if (!unitIds.length) return { html: '<p class="muted">Выберите хотя бы один готовый отряд. Находящиеся в походе или в бою недоступны.</p>', disabled: true };
    if (m.battle) return {html:'<p class="muted">Сначала завершите текущее столкновение.</p>',disabled:true};
    if (current.ended) return {html:'<p class="muted">Правление завершено.</p>',disabled:true};
    if (quoteFn) {
      try {
        const q = quoteFn({ target: ui.target, unitIds, mission: ui.mission, supply: ui.supply });
        const enough = current.player.food >= q.food, allowed = enough && q.canLaunch !== false;
        const explanation = !allowed ? q.reason || 'Не хватает зерна для выбранного обоза. Измените состав или запас провианта.' : 'Провиант выдаётся при выступлении. Дорога и пребывание в пути утомляют людей.';
        const names=m.units.filter(u=>unitIds.includes(u.id)).map(u=>u.name).join(', ');
        return { html: `<div class="march-selection"><small>В ПОХОД ОТПРАВЯТСЯ</small><strong>${esc(names)}</strong></div><div class="march-quote"><span>В пути <b>${number(q.duration)} мес.</b></span><span>Обоз <b>${number(q.food)} зерна</b></span><span>Отрядов <b>${unitIds.length}</b></span></div><p class="muted">${esc(explanation)}</p>`, disabled: !allowed };
      } catch (error) { return {html:`<p class="muted">${esc(error.message)}</p>`,disabled:true}; }
    }
    return { html: '<p class="muted">Приказ задаёт маршрут и обоз. Прибытие происходит при завершении месяцев; лёгкий обоз увеличивает риск нехватки еды.</p>', disabled: false };
  }
  function updateQuote() {
    const box = typeof document === 'undefined' ? null : document.getElementById('military-quote');
    if (!box || !current) return;
    const q = quoteHTML(); box.innerHTML = q.html;
    const button = document.getElementById('military-launch'); if (button) button.disabled = q.disabled;
  }
  function provinceHTML(v) {
    const m=v.military, projects=m.projects || [];
    const active=projects.length ? projects.map(p=>{
      const place=m.locations.find(l=>l.id===p.target), type=p.project || p.type;
      return `<article class="province-project"><div><strong>${esc(provinceWorks[type]?.name || 'Улучшение местности')}</strong><span>${esc(p.targetName || place?.name || p.target)}</span></div><b>${number(p.remaining)} мес. осталось</b></article>`;
    }).join('') : '<p class="military-empty">Строек в местностях пока нет. Выберите рубеж и вид улучшения.</p>';
    return `<section id="province-development" class="province-development"><div class="section-heading"><div><span class="eyebrow">ОПЕКА НАД ЗЕМЛЯМИ КНЯЖЕСТВА</span><h2>Развитие рубежей</h2></div><span class="badge">Три уровня каждого улучшения</span></div><p class="province-intro">Дозор, склады и дороги развиваются отдельно в каждой местности. Это работа на два месяца: в одном месте можно вести одно улучшение за раз. Более высокие уровни требуют больше средств.</p><div class="province-levels">${m.locations.map(l=>`<button class="province-level-card ${ui.provinceTarget===l.id?'selected':''}" data-province-target="${esc(l.id)}" aria-pressed="${ui.provinceTarget===l.id}"><strong>${esc(l.name)}</strong>${Object.entries(provinceWorks).map(([id,p])=>`<span>${esc(p.name)} <b>${number(l.improvements?.[id])} / 3</b></span>`).join('')}</button>`).join('')}</div><div class="province-planning"><form id="province-orders"><div class="military-form-fields"><label>Где строить<select id="province-target">${m.locations.map(l=>`<option value="${esc(l.id)}" ${ui.provinceTarget===l.id?'selected':''}>${esc(l.name)}</option>`).join('')}</select></label><label>Что улучшить<select id="province-project">${Object.entries(provinceWorks).map(([id,p])=>`<option value="${id}" ${ui.provinceProject===id?'selected':''}>${esc(p.name)}</option>`).join('')}</select></label></div><p class="province-effect">${esc(provinceWorks[ui.provinceProject].description)}</p><div id="province-quote" aria-live="polite"></div><button type="submit" class="button primary" id="province-build">Начать улучшение →</button></form><div id="province-projects"><span class="eyebrow">СТРОЙКИ НА РУБЕЖАХ</span>${active}</div></div></section>`;
  }
  function provinceQuoteHTML() {
    if(!provinceQuoteFn)return {html:'<p class="muted">Расчёт строительства пока недоступен.</p>',disabled:true};
    try{
      const q=provinceQuoteFn({target:ui.provinceTarget,project:ui.provinceProject});
      const enough=current.player.gold>=q.gold && current.player.food>=q.food, allowed=enough && q.canBuild!==false;
      return {html:`<div class="march-quote"><span>Стоимость <b>${number(q.gold)} монет</b></span><span>Провиант <b>${number(q.food)} зерна</b></span><span>Срок <b>${number(q.duration || 2)} мес.</b></span></div><p class="muted">${esc(allowed?'Расходуется один новый государственный приказ. Средства выдаются при начале работ.':q.reason || 'Не хватает монет или зерна для этого улучшения.')}</p>`,disabled:!allowed};
    }catch(error){return {html:`<p class="muted">${esc(error.message)}</p>`,disabled:true};}
  }
  function updateProvinceQuote(){
    const box=document.getElementById('province-quote');if(!box || !current)return;
    const q=provinceQuoteHTML();box.innerHTML=q.html;
    const button=document.getElementById('province-build');if(button)button.disabled=q.disabled;
  }
  function planned(unitId){
    const b=current?.military?.battle,u=current?.military?.units?.find(x=>x.id===unitId);if(!b||!u)return null;
    const c=ui.battlePlans[unitId]||b.unitCoords?.[unitId]||{x:50,y:75};
    return ui.battlePlans[unitId]||(ui.battlePlans[unitId]={x:c.x,y:c.y,targetId:ui.battleTarget,tactic:u.type==='archers'?'ranged':u.type==='cavalry'?'flank':'guard'});
  }
  function moveSelected(dx,dy){
    const b=current?.military?.battle;if(!b||!ui.battleUnit)return;
    const p=planned(ui.battleUnit);p.x=Math.max(10,Math.min(90,p.x+dx));p.y=Math.max(b.deployed?38:62,Math.min(88,p.y+dy));render(current,callbacks());
  }
  function tokenFor(field, attribute, id) {
    return [...field.querySelectorAll(`[${attribute}]`)].find(node => node.dataset[attribute.replace(/^data-/, '').replace(/-([a-z])/g,(_,c)=>c.toUpperCase())] === id);
  }
  function projectile(field, from, to, delay, index) {
    const fieldBox=field.getBoundingClientRect(),a=from.getBoundingClientRect(),b=to.getBoundingClientRect();
    const x=a.left+a.width/2-fieldBox.left+(index-3)*4,y=a.top+a.height*.38-fieldBox.top+(index%2)*5;
    const dx=b.left+b.width/2-fieldBox.left-x+(index-3)*5,dy=b.top+b.height*.42-fieldBox.top-y+(index%3-1)*7;
    const arrow=document.createElement('i'),arc=34+Math.abs(index-3)*3,angle=(vx,vy)=>Math.atan2(vy,vx)*180/Math.PI;arrow.className='battle-projectile';arrow.style.left=`${x}px`;arrow.style.top=`${y}px`;field.append(arrow);
    const flight=arrow.animate([{transform:`translate(0,0) rotate(${angle(dx,dy-arc*2)}deg)`,opacity:0},{opacity:1,offset:.08},{transform:`translate(${dx*.5}px,${dy*.5-arc}px) rotate(${angle(dx,dy)}deg)`,opacity:1,offset:.5},{transform:`translate(${dx}px,${dy}px) rotate(${angle(dx,dy+arc*2)}deg)`,opacity:1,offset:.88},{transform:`translate(${dx}px,${dy}px) rotate(${angle(dx,dy+arc*2)}deg)`,opacity:0}],{duration:920,delay,fill:'forwards',easing:'linear'});
    flight.finished.catch(()=>{}).finally(()=>arrow.remove());
  }
  function impact(field, token, delay, ranged) {
    const box=token.getBoundingClientRect(),root=field.getBoundingClientRect(),burst=document.createElement('i');burst.className=`battle-impact ${ranged?'arrow-impact':'steel-impact'}`;burst.style.left=`${box.left+box.width/2-root.left}px`;burst.style.top=`${box.top+box.height*.45-root.top}px`;burst.innerHTML='<i></i><i></i><i></i><i></i><i></i><i></i>';field.append(burst);
    const animation=burst.animate([{transform:'translate(-50%,-50%) scale(.25)',opacity:0},{transform:'translate(-50%,-50%) scale(1)',opacity:1,offset:.3},{transform:'translate(-50%,-50%) scale(1.45)',opacity:0}],{duration:620,delay,fill:'forwards',easing:'cubic-bezier(.15,.8,.25,1)'});animation.finished.catch(()=>{}).finally(()=>burst.remove());
  }
  function lossMarker(field, token, value, delay, enemy=false) {
    if(!value)return;const box=token.getBoundingClientRect(),root=field.getBoundingClientRect(),mark=document.createElement('b');
    mark.className=`battle-loss ${enemy?'enemy-loss':'own-loss'}`;mark.textContent=`−${number(value)}`;mark.style.left=`${box.left+box.width/2-root.left}px`;mark.style.top=`${box.top+box.height*.25-root.top}px`;field.append(mark);
    const effect=mark.animate([{transform:'translate(-50%,8px) scale(.7)',opacity:0},{transform:'translate(-50%,-8px) scale(1.15)',opacity:1,offset:.25},{transform:'translate(-50%,-42px) scale(1)',opacity:0}],{duration:1050,delay,fill:'forwards',easing:'ease-out'});effect.finished.catch(()=>{}).finally(()=>mark.remove());
  }
  function clash(field, actor, target, action, start) {
    const a=actor.getBoundingClientRect(),b=target.getBoundingClientRect(),dx=(b.left+b.width/2)-(a.left+a.width/2),dy=(b.top+b.height/2)-(a.top+a.height/2),ranged=action.tactic==='ranged';
    actor.classList.add(ranged?'anim-volley':'anim-charge');target.classList.add('anim-defend');
    if(ranged){for(let i=0;i<7;i++)projectile(field,actor,target,start+i*65,i);}
    else {
      actor.animate([{transform:'translate(-50%,-50%)'},{transform:`translate(calc(-50% + ${dx*.68}px),calc(-50% + ${dy*.68}px))`,offset:.46},{transform:`translate(calc(-50% + ${dx*.61}px),calc(-50% + ${dy*.61}px))`,offset:.7},{transform:'translate(-50%,-50%)'}],{duration:1450,delay:start,fill:'none',easing:'cubic-bezier(.2,.75,.2,1)'});
      target.animate([{transform:'translate(-50%,-50%)'},{transform:'translate(-50%,-50%)',offset:.42},{transform:`translate(calc(-50% + ${-dx*.12}px),calc(-50% + ${-dy*.12}px))`,offset:.6},{transform:'translate(-50%,-50%)'}],{duration:1450,delay:start,fill:'none',easing:'ease-out'});
    }
    const hitAt=start+(ranged?820:620),attackers=[...actor.querySelectorAll('.painted-fighter')],defenders=[...target.querySelectorAll('.painted-fighter')];impact(field,target,hitAt,ranged);
    attackers.forEach((fighter,i)=>fighter.animate(ranged?[{transform:'translate(-50%,-50%) rotate(-4deg)'},{transform:'translate(-50%,-58%) rotate(8deg)'},{transform:'translate(-50%,-50%)'}]:[{transform:'translate(-50%,-50%)'},{transform:`translate(${i%2?'-35%':'-60%'},-68%) rotate(${i%2?18:-16}deg)`},{transform:'translate(-50%,-50%)'}],{duration:ranged?520:520,delay:start+(i%3)*55,easing:'ease-in-out'}));
    defenders.slice(0,Math.max(2,Math.min(5,Math.ceil(number(action.enemyLoss)/2)))).forEach((fighter,i)=>fighter.animate([{transform:'translate(-50%,-50%) rotate(180deg)',filter:'brightness(1)'},{transform:`translate(${i%2?'-25%':'-75%'},-35%) rotate(${215+i*9}deg)`,filter:'brightness(1.7) sepia(1)',offset:.38},{transform:`translate(${i%2?'-25%':'-75%'},20%) rotate(${250+i*8}deg)`,filter:'brightness(.55)',opacity:.35}],{duration:900,delay:hitAt+i*45,fill:'forwards',easing:'ease-out'}));
    lossMarker(field,target,action.enemyLoss,hitAt,true);lossMarker(field,actor,action.ownLoss,hitAt+260,false);
    setTimeout(()=>{actor.classList.remove('anim-volley','anim-charge');target.classList.remove('anim-defend');},start+1550);
  }
  function playBattleSequence(b) {
    if(!b)return;const actions=b.lastRoundActions?.length?b.lastRoundActions:(b.lastAction?[b.lastAction]:[]);if(!actions.length)return;
    const key=`${b.id}:${b.phase}:${actions.map(a=>`${a.unitId}:${a.tactic}:${a.enemyLoss}:${a.ownLoss}`).join('|')}`;if(ui.animatedRound===key)return;ui.animatedRound=key;
    const field=document.querySelector('#battle-area .battlefield');if(!field)return;field.classList.add('battle-animating');const status=document.createElement('div');status.className='battle-animation-status';status.innerHTML='<i></i><span>Выполняется общий план раунда</span>';field.append(status);
    actions.forEach((action,i)=>{const actor=tokenFor(field,'data-battle-unit',action.unitId),target=tokenFor(field,'data-battle-enemy',action.targetId);if(actor&&target)clash(field,actor,target,action,260+i*1650);});
    setTimeout(()=>{field?.classList.remove('battle-animating');status.remove();},Math.max(1800,actions.length*1650+500));
  }
  function render(v, options = {}) {
    if (typeof document === 'undefined') return;
    const target = document.getElementById('military-content'); if (!target) return;
    current = v; quoteFn = typeof options === 'function' ? options : options.quote || null;
    provinceQuoteFn = typeof options === 'object' ? options.provinceQuote || null : null;
    const m = v.military;
    if (!m) { target.innerHTML = '<p class="military-empty">Военные сведения пока недоступны.</p>'; return; }
    if (!m.locations.some(l=>l.id===ui.target)) ui.target = m.locations[0]?.id || 'capital';
    if (!m.locations.some(l=>l.id===ui.provinceTarget)) ui.provinceTarget=m.locations[0]?.id || 'capital';
    if (ui.selected === null) ui.selected = new Set(m.units.filter(u=>u.status==='ready' && u.strength>0).map(u=>u.id));
    const capitalStrength = m.units.filter(u=>u.location==='capital' && u.status==='ready').reduce((sum,u)=>sum+u.strength,0);
    target.innerHTML = `<div class="military-intro"><p>Поход требует времени и провианта. Отряды могут устать ещё до встречи с противником. Усиливайте опасные рубежи, следите за дорогами и выбирайте, где принять бой.</p><span class="badge">${esc(weatherName(m.weather))}</span></div><section id="military-summary" class="military-summary"><div><small>ВСЕГО СИЛЫ</small><strong>${number(m.summary?.totalStrength ?? v.player.army)}</strong></div><div><small>ГОТОВО К ПОХОДУ</small><strong>${number(m.summary?.readyStrength)}</strong></div><div><small>ОБОРОНА СТОЛИЦЫ</small><strong>${number(v.player.defense)}</strong></div><div><small>ТРЕВОЖНЫЕ МЕСТА</small><strong>${number(m.summary?.banditSites) + number(m.summary?.unrestSites)}</strong></div></section><section class="campaign-card"><div class="section-heading"><div><span class="eyebrow">ДОРОГИ, ЛЕСА И ПЕРЕПРАВЫ</span><h2>Карта рубежей</h2></div><span class="muted">Выберите местность</span></div>${mapHTML(m)}${locationHTML(m)}<p class="campaign-map-note">На узком экране карту можно прокручивать в стороны. Сила войска — условный показатель, не число людей.</p></section><section class="military-castle"><div><span class="eyebrow">СЕРДЦЕ КНЯЖЕСТВА</span><h2>Замок Ардена</h2><p>Укрепления: ${number(v.player.defense)} · находящиеся в столице отряды: ${number(capitalStrength)} силы.</p><p>Стены помогают обороне столицы. Воевода не сможет одновременно выставить один отряд у ворот и отправить его к далёкой заставе.</p></div></section><div class="page-heading"><div><span class="eyebrow">ЛЮДИ ПОД ВАШИМ ЗНАМЕНЕМ</span><h2>Дружина и отряды</h2></div><span class="muted">Резерв: ${number(m.reserve)}</span></div><section id="military-units" class="military-units">${m.units.map(unitHTML).join('')}</section><div class="military-planning"><form id="military-orders"><span class="eyebrow">ПРИКАЗ ВОЕВОДЕ</span><h2>Подготовить поход</h2><div class="military-form-fields"><label>Местность<select id="military-target" ${ui.mission==='return'?'disabled':''}>${m.locations.map(l=>`<option value="${esc(l.id)}" ${ui.target===l.id?'selected':''}>${esc(l.name)} · ${esc(l.terrainLabel)}</option>`).join('')}</select></label><label>Задача<select id="military-mission">${Object.entries(missionNames).map(([id,name])=>`<option value="${id}" ${ui.mission===id?'selected':''}>${name}</option>`).join('')}</select></label><label>Провиант<select id="military-supply">${Object.entries(supplyNames).map(([id,name])=>`<option value="${id}" ${ui.supply===id?'selected':''}>${name}</option>`).join('')}</select></label></div><div id="military-quote" aria-live="polite"></div><button type="submit" class="button primary" id="military-launch">Отдать приказ о выступлении →</button></form><section id="military-marches"><span class="eyebrow">ВЕСТИ С ДОРОГ</span><h2>Походы и приближение угроз</h2>${marchesHTML(m)}</section></div>${battleHTML(m)}${resultHTML(m.lastBattle)}`;
    if(provinceQuoteFn)target.querySelector('.military-castle').insertAdjacentHTML('beforebegin',provinceHTML(v));
    updateQuote();updateProvinceQuote();
    playBattleSequence(m.battle);
  }
  if (typeof document !== 'undefined') {
    document.addEventListener('pointerdown',event=>{
      const token=event.target.closest('.player-token[data-battle-unit]'),field=token?.closest('.battlefield');if(!token||!field||!current?.military?.battle)return;
      ui.battleUnit=token.dataset.battleUnit;battleDrag={pointerId:event.pointerId,token,field,moved:false};token.setPointerCapture?.(event.pointerId);token.classList.add('dragging-unit');
    });
    document.addEventListener('pointermove',event=>{
      if(!battleDrag||battleDrag.pointerId!==event.pointerId)return;const rect=battleDrag.field.getBoundingClientRect();if(!rect.width||!rect.height)return;
      const b=current.military.battle,minY=b.deployed?38:62,pctX=(event.clientX-rect.left)/rect.width*100,pctY=(event.clientY-rect.top)/rect.height*100,x=Math.max(10,Math.min(90,10+Math.round((pctX-10)/10)*10)),y=Math.max(minY,Math.min(88,22+Math.round((pctY-22)/14)*14));
      battleDrag.moved=true;battleDrag.x=x;battleDrag.y=y;battleDrag.token.style.left=x+'%';battleDrag.token.style.top=y+'%';event.preventDefault();
    },{passive:false});
    document.addEventListener('pointerup',event=>{
      if(!battleDrag||battleDrag.pointerId!==event.pointerId)return;const drag=battleDrag;battleDrag=null;drag.token.classList.remove('dragging-unit');if(drag.moved){const p=planned(drag.token.dataset.battleUnit);if(p){p.x=drag.x;p.y=drag.y;}render(current,callbacks());}
    });
    document.addEventListener('click', event => {
      const location = event.target.closest('[data-military-location]');
      if (location && current) { ui.target = location.dataset.militaryLocation; ui.provinceTarget=ui.target; if (ui.mission==='return' && ui.target!=='capital') ui.mission='defend'; render(current,callbacks()); return; }
      const province=event.target.closest('[data-province-target]');
      if(province&&current){ui.provinceTarget=province.dataset.provinceTarget;render(current,callbacks());return;}
      const help=event.target.closest('[data-battle-help]');if(help&&current?.military?.battle){ui.battleHelp=!ui.battleHelp;render(current,callbacks());return;}
      const tactic = event.target.closest('[data-battle-tactic]');
      const own=event.target.closest('[data-battle-unit]');if(own&&current?.military?.battle){ui.battleUnit=own.dataset.battleUnit;render(current,callbacks());return;}
      const enemy=event.target.closest('[data-battle-enemy]');if(enemy&&current?.military?.battle){ui.battleTarget=enemy.dataset.battleEnemy;const p=planned(ui.battleUnit);if(p)p.targetId=ui.battleTarget;render(current,callbacks());return;}
      const feature=event.target.closest('[data-battle-feature]');if(feature&&current?.military?.battle){ui.battleFeature=ui.battleFeature===feature.dataset.battleFeature?null:feature.dataset.battleFeature;render(current,callbacks());return;}
      const cell=event.target.closest('[data-battle-cell]');if(cell&&!cell.disabled&&current?.military?.battle){const p=planned(ui.battleUnit);if(p){p.x=Number(cell.dataset.x);p.y=Number(cell.dataset.y);render(current,callbacks());}return;}
      const move=event.target.closest('[data-battle-move]');if(move&&current?.military?.battle){const d={up:[0,-7],down:[0,7],left:[-8,0],right:[8,0],hold:[0,0]}[move.dataset.battleMove];moveSelected(...d);return;}
      const row=event.target.closest('[data-battle-rows]');if(row&&current?.military?.battle){const b=current.military.battle,c=b.unitCoords?.[ui.battleUnit]||{x:50,y:75};dispatch({action:'deploy',placements:[{unitId:ui.battleUnit,x:c.x,y:c.y,rows:Number(row.dataset.battleRows)}],confirm:false});return;}
      const confirm=event.target.closest('[data-battle-deploy]');if(confirm&&current?.military?.battle){const b=current.military.battle,placements=b.unitIds.map((id,i)=>{const p=ui.battlePlans[id]||b.unitCoords?.[id]||{x:22+i*28,y:78-(i%2)*3};return {unitId:id,x:p.x,y:p.y,rows:b.unitFormations?.[id]||2};});dispatch({action:'deploy',placements,confirm:true});ui.battlePlans={};return;}
      const execute=event.target.closest('[data-battle-execute]');if(execute&&!execute.disabled&&current?.military?.battle){const orders=current.military.battle.unitIds.map(id=>({unitId:id,...ui.battlePlans[id]}));ui.battlePlans={};dispatch({action:'orders',orders});return;}
      if (tactic && !tactic.disabled){const p=planned(ui.battleUnit);if(p){p.tactic=tactic.dataset.battleTactic;p.targetId=ui.battleTarget;render(current,callbacks());}return;}
    });
    document.addEventListener('change', event => {
      if (!current) return;
      if (event.target.matches('input[data-unit]')) { if(event.target.checked)ui.selected.add(event.target.dataset.unit);else ui.selected.delete(event.target.dataset.unit);updateQuote(); }
      if (event.target.id==='military-target') { ui.target=event.target.value;render(current,callbacks()); }
      if (event.target.id==='military-supply') { ui.supply=event.target.value;updateQuote(); }
      if (event.target.id==='military-mission') { ui.mission=event.target.value;if(ui.mission==='return')ui.target='capital';render(current,callbacks()); }
      if(event.target.id==='province-target'){ui.provinceTarget=event.target.value;render(current,callbacks());}
      if(event.target.id==='province-project'){ui.provinceProject=event.target.value;render(current,callbacks());}
      if(event.target.id==='battle-unit'){ui.battleUnit=event.target.value;render(current,callbacks());}
      if(event.target.id==='battle-target'){ui.battleTarget=event.target.value;render(current,callbacks());}
    });
    document.addEventListener('submit', event => {
      if(event.target.id==='province-orders'&&current){event.preventDefault();if(provinceQuoteHTML().disabled)return;dispatch({action:'develop',target:ui.provinceTarget,project:ui.provinceProject});return;}
      if (event.target.id!=='military-orders' || !current) return;
      event.preventDefault();
      const q=quoteHTML();if(q.disabled)return;
      const unitIds=current.military.units.filter(u=>ui.selected.has(u.id)&&u.status==='ready'&&u.strength>0).map(u=>u.id);
      dispatch({action:'launch',target:ui.target,unitIds,mission:ui.mission,supply:ui.supply});
    });
  }
  return { render };
});
