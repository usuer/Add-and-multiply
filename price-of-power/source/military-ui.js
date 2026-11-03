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
  let current = null, quoteFn = null, provinceQuoteFn = null;
  const ui = { target: 'forest', mission: 'expedition', supply: 'normal', selected: null, provinceTarget:'forest', provinceProject:'watch', battleUnit:null, battleTarget:'enemy-main' };
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
    const advance=Math.min(2,number(b.phase)), playerTop=[76,64,57][advance], enemyTop=[24,36,43][advance];
    const formation=(type,enemy=false)=>`<div class="unit-formation ${enemy?'hostile':''} formation-${esc(type).toLowerCase()}">${Array.from({length:6},(_,i)=>`<i class="soldier soldier-${i}"></i>`).join('')}</div>`;
    const playerTokens = participants.flatMap((u,i) => [0,1].map(part=>`<div class="battle-token player-token detachment-${part} phase-${advance}" style="left:${18+i*25+part*7}%;top:${playerTop-(i%2)*4+part*3}%">${formation(u.type)}<b>${part?`${esc(u.name)} · II`:`${esc(u.name)} · I`}</b><small>${esc(u.typeLabel)} · сила ${number(Math.ceil(u.strength/2))} · дух ${number(u.morale)}%</small></div>`)).join('');
    const enemyTokens=(b.enemyUnits||[]).filter(u=>u.strength>0).map((u,i)=>`<div class="battle-token enemy-token phase-${advance}" style="left:${18+i*16}%;top:${enemyTop+(i%2)*5}%">${formation(u.type,true)}<b>${esc(u.name)}</b><small>${esc(u.type)} · оценка ${number(u.strength)}</small></div>`).join('');
    const featureIcon={command:'⚑',cart:'▣',stakes:'╳',reserve:'♜',trees:'♣',hill:'▲',rocks:'◆',river:'≈',bridge:'═',farm:'❧',ditch:'⌁',wall:'▥',tower:'♜',gate:'▤',arrows:'➶',wounded:'✚'};
    const features=(b.features||[]).map(f=>`<div class="battle-object object-${esc(f.kind)}" style="left:${number(f.x)}%;top:${number(f.y)}%" title="${esc(f.effect)}"><b>${featureIcon[f.kind]||'◆'}</b><span>${esc(f.label)}</span></div>`).join('');
    const tactics = b.tactics || [{id:'guard',name:'Держать строй',description:'Сберечь людей и встретить удар.'},{id:'advance',name:'Наступать',description:'Давить на противника основными силами.'},{id:'flank',name:'Обойти с фланга',description:'Попытаться использовать пространство и укрытия.'},{id:'ranged',name:'Вести обстрел',description:'Дать лучникам возможность действовать.'},{id:'withdraw',name:'Отступить',description:'Выйти из боя, сохранив тех, кто сможет уйти.'}];
    if(!ui.battleUnit||!participants.some(u=>u.id===ui.battleUnit&&u.strength>0))ui.battleUnit=participants.find(u=>u.strength>0)?.id||null;
    const acting=participants.find(u=>u.id===ui.battleUnit),targets=(b.enemyUnits||[]).filter(u=>u.strength>0);
    const tacticalControl=`<section class="tactical-control"><div><label>Кому отдать приказ<select id="battle-unit">${participants.filter(u=>u.strength>0).map(u=>`<option value="${esc(u.id)}" ${u.id===ui.battleUnit?'selected':''}>${esc(u.name)} · ${esc(u.typeLabel)} · ${u.strength}</option>`).join('')}</select></label><label>Цель приказа<select id="battle-target">${targets.map(u=>`<option value="${esc(u.id)}" ${u.id===ui.battleTarget?'selected':''}>${esc(u.name)} · ${esc(u.type)} · ~${u.strength}</option>`).join('')}</select></label></div>${acting?`<div class="unit-profile"><strong>${esc(acting.name)}</strong><span>Атака <b>${acting.attack}</b></span><span>Броня <b>${acting.armor}</b></span><span>Дальность <b>${acting.range}</b></span><span>Скорость <b>${acting.speed}</b></span><span>Ближний бой <b>${acting.melee}</b></span><p>${esc(acting.role)}</p></div>`:''}</section>`;
    const latest=b.log?.at(-1),a=b.lastAction,lastTarget=(b.enemyUnits||[]).find(u=>u.id===a?.targetId);
    const actionReport=a?`<div class="battle-action-result detailed" role="status"><div class="order-done"><b>${esc(a.unitName)}: ${esc(a.tacticName)}</b><span>Цель: ${esc(lastTarget?.name||'главный строй')}. ${esc(a.position)}</span></div><div class="exchange own"><small>НАШИ ПОТЕРИ</small><strong>−${number(a.ownLoss)}</strong></div><div class="exchange enemy"><small>ПОТЕРИ ВРАГА</small><strong>−${number(a.enemyLoss)}</strong></div><div class="battle-assessment ${a.advantage>=3?'good':a.advantage<=-3?'bad':''}">${esc(a.assessment)} Дух противника: ${number(a.enemyMoraleBefore)}% → ${number(a.enemyMoraleAfter)}%.</div></div>`:latest?`<div class="battle-action-result" role="status"><b>Приказ исполнен.</b><span>${esc(latest)}</span><small>Позиции и силы на схеме обновлены.</small></div>`:'';
    return `<section id="battle-area" class="battle-card" data-phase="${number(b.phase)}"><div class="battle-heading"><div><span class="eyebrow">${b.defending ? 'ЗАЩИТА КНЯЖЕСТВА' : 'СТОЛКНОВЕНИЕ'}</span><h2>${esc(b.locationName)}</h2><p>${esc(b.terrainLabel)} · ${esc(weatherName(b.weather || m.weather))}</p></div><div class="battle-phase"><small>ХОД БОЯ ${number(b.phase)+1} ИЗ 3</small><strong>${esc(b.phaseName || `Фаза ${number(b.phase) + 1}`)}</strong></div></div>${actionReport}<div class="battlefield terrain-${esc(b.terrain)}"><div class="battle-enemy-heading"><strong>${esc(b.attackerName)}</strong><small>Общая оценка силы: ${esc(estimate(b.enemyEstimate))}</small></div>${features}${enemyTokens}${playerTokens}<span class="battle-field-caption">Наведите на объект, чтобы увидеть его роль. Отряды меняют позиции после каждого приказа.</span></div><div class="battle-condition"><span>Боевой расчёт учитывает снабжение, усталость, дух, опыт и местность.</span><b>Сторона: ${b.defending ? 'оборона' : 'наступление'}</b></div>${tacticalControl}<div class="battle-tactics">${tactics.map(t=>`<button class="button ${t.id === 'withdraw' ? 'quiet' : 'secondary'}" data-battle-tactic="${esc(t.id)}"><strong>${esc(t.name)}</strong><span>${esc(t.description)}</span></button>`).join('')}</div>${b.log?.length ? `<div class="battle-log" aria-live="polite"><h3>Ход столкновения</h3>${b.log.map((line,i)=>`<p><b>${i+1}.</b> ${esc(line)}</p>`).join('')}</div>` : ''}</section>`;
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
  }
  if (typeof document !== 'undefined') {
    document.addEventListener('click', event => {
      const location = event.target.closest('[data-military-location]');
      if (location && current) { ui.target = location.dataset.militaryLocation; ui.provinceTarget=ui.target; if (ui.mission==='return' && ui.target!=='capital') ui.mission='defend'; render(current,callbacks()); return; }
      const province=event.target.closest('[data-province-target]');
      if(province&&current){ui.provinceTarget=province.dataset.provinceTarget;render(current,callbacks());return;}
      const tactic = event.target.closest('[data-battle-tactic]');
      if (tactic && !tactic.disabled) dispatch({action:'tactic',tactic:tactic.dataset.battleTactic,unitId:ui.battleUnit,targetId:ui.battleTarget});
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
