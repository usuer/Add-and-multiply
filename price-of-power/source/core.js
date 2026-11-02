/* Цена власти: детерминированная модель. Работает в браузере и Node.js. */
(function (root, factory) {
  'use strict';
  const api = factory(typeof module === 'object' && module.exports ? require('./stories.js') : root.PopStories);
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.PriceOfPower = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (STORY_DATA) {
  'use strict';
  const VERSION = 4;
  const { PEOPLE, STORIES } = STORY_DATA;
  const MONTHS = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
  const COUNTRIES = [
    { id: 'val', name: 'Вальдория', ruler: 'Король Эдрик', trait: 'Осторожный и подозрительный', goal: 'Безопасные границы', army: 70, gold: 88, aggression: 48, relation: -24 },
    { id: 'mer', name: 'Мерсия', ruler: 'Совет торговых домов', trait: 'Прагматичная республика', goal: 'Прибыль от торговли', army: 43, gold: 125, aggression: 22, relation: 22 },
    { id: 'nor', name: 'Нордвик', ruler: 'Князь Рагнар', trait: 'Честолюбивый и воинственный', goal: 'Военное превосходство', army: 82, gold: 70, aggression: 76, relation: -12 },
  ];
  const COMMANDS = [
    { id: 'scout', name: 'Отправить разведчика', category: 'Дипломатия', actor: 'agents', executor: 'Тайная канцелярия', duration: 2, gold: 14, target: true, description: 'Донесение о войске и намерениях. Агент может ошибиться или попасться.' },
    { id: 'envoy', name: 'Отправить посольство', category: 'Дипломатия', actor: 'envoys', executor: 'Посольский двор', duration: 2, gold: 12, target: true, description: 'Попытка снизить недоверие и договориться о торговле. Успех не гарантирован.' },
    { id: 'patrol', name: 'Усилить патрули', category: 'Оборона', actor: 'military', executor: 'Пограничная стража', duration: 1, gold: 11, description: 'Оборона +7. Военные приготовления повышают подозрения соседей.' },
    { id: 'train', name: 'Обучить войска', category: 'Оборона', actor: 'military', executor: 'Воевода', duration: 2, gold: 17, description: 'Армия +10. Больше войск — больше расходов и потребления зерна.' },
    { id: 'farm', name: 'Развить земледелие', category: 'Хозяйство', actor: 'builders', executor: 'Земские мастера', duration: 3, gold: 16, description: 'Поля +1: ежемесячный урожай +5; при завершении зерно +12.' },
    { id: 'road', name: 'Проложить дорогу', category: 'Хозяйство', actor: 'builders', executor: 'Дорожная артель', duration: 3, gold: 18, description: 'Дороги +1: доход +3 за месяц, оборона +2.' },
    { id: 'aid', name: 'Поддержать жителей', category: 'Хозяйство', actor: 'civil', executor: 'Земский совет', duration: 1, gold: 13, description: 'Стабильность +10. Помощь смягчит недовольство, но не устранит нехватку еды.' },
    { id: 'grain', name: 'Закупить зерно', category: 'Хозяйство', actor: 'merchants', executor: 'Купеческая гильдия', duration: 1, gold: 14, description: 'Зерно +28. Поставка поступит до месячного потребления.' },
    { id: 'school', name: 'Открыть школу', category: 'Образование', actor: 'scholars', executor: 'Учёный совет', duration: 3, gold: 18, description: 'Наука +1, дипломатия +1. Каждая ступень науки повышает базовый доход.' },
    { id: 'network', name: 'Обучить разведчиков', category: 'Образование', actor: 'agents', executor: 'Тайная канцелярия', duration: 3, gold: 15, description: 'Разведка +1. Более точные сведения и меньший риск поимки.' },
  ];
  const BUILDINGS = [
    { command: 'farm', key: 'farms', name: 'Поля и усадьбы', symbol: 'field', effect: 'Производство зерна +5/мес.; при завершении зерно +12.', max: 5 },
    { command: 'orchard', key: 'orchards', name: 'Общественные сады', symbol: 'tree', effect: 'Зерно +3/мес., доход +1/мес., здоровье +3 при открытии.', max: 3, gold: 20, duration: 3 },
    { command: 'road', key: 'roads', name: 'Дороги и мосты', symbol: 'road', effect: 'Доход +3/мес., оборона +2 при завершении.', max: 5 },
    { command: 'well', key: 'wells', name: 'Колодцы и водопровод', symbol: 'well', effect: 'Здоровье +1/мес. и +4 при открытии.', max: 3, gold: 16, duration: 2 },
    { command: 'granary', key: 'granaries', name: 'Зернохранилища', symbol: 'store', effect: 'Потери зерна при хранении −3/мес. за уровень (до нуля).', max: 3, gold: 24, duration: 3 },
    { command: 'school', key: 'schools', name: 'Земские школы', symbol: 'school', effect: 'Наука +1, дипломатия +1. Открывают путь к университету.', max: 3 },
    { command: 'clinic', key: 'clinics', name: 'Городские лечебницы', symbol: 'clinic', effect: 'Здоровье +2/мес. Содержание: 2 монеты/мес.', max: 3, gold: 28, duration: 3 },
    { command: 'university', key: 'universities', name: 'Университет', symbol: 'university', effect: 'Наука +2, разведка +1, доход +4/мес. Содержание: 3 монеты/мес. Нужны 2 школы и наука 4.', max: 2, gold: 55, duration: 4, requires: { schools: 2, science: 4 } },
  ];
  for (const b of BUILDINGS) {
    let d = COMMANDS.find(c => c.id === b.command);
    if (!d) { d = { id: b.command, name: `Построить: ${b.name.toLowerCase()}`, category: 'Город', actor: 'builders', executor: 'Земские мастера', gold: b.gold, duration: b.duration, description: b.effect }; COMMANDS.push(d); }
    d.building = b.key;
  }
  const LAWS = [
    { key: 'tax', name: 'Налогообложение', options: [
      { value: 'low', name: 'Щадящий сбор', effect: 'Доход −4/мес., стабильность +2/мес.' },
      { value: 'balanced', name: 'Обычный сбор', effect: 'Базовый доход. Без дополнительного влияния на стабильность.' },
      { value: 'high', name: 'Чрезвычайный сбор', effect: 'Доход +7/мес., стабильность −3/мес.' },
    ] },
    { key: 'grain', name: 'Торговля зерном', options: [
      { value: 'market', name: 'Свободная продажа', effect: 'Без ограничений и дополнительных расходов.' },
      { value: 'reserve', name: 'Княжеский резерв', effect: 'Доход −3/мес., потребление запасов зерна −2/мес.' },
    ] },
    { key: 'education', name: 'Доступ к образованию', options: [
      { value: 'elite', name: 'Дворцовая школа', effect: 'Обучение при дворе. Без дополнительного содержания.' },
      { value: 'public', name: 'Общедоступное обучение', effect: 'Содержание 4 монеты/мес., стабильность +1/мес., наука +1 раз в полгода. Нужна земская школа.' },
    ] },
  ];
  for (const law of LAWS) for (const option of law.options) COMMANDS.push({ id: `law_${law.key}_${option.value}`, name: option.name, category: 'Законы', actor: 'council', executor: 'Княжеская канцелярия', gold: 5, duration: 1, law: law.key, value: option.value, description: option.effect });
  const CAPACITY = { agents: 1, envoys: 1, military: 2, builders: 2, civil: 1, merchants: 1, scholars: 1, council: 1 };
  const METRICS = { gold: 'Казна', food: 'Зерно', stability: 'Стабильность', army: 'Армия', defense: 'Оборона', health: 'Здоровье', population: 'Население', science: 'Наука', diplomacy: 'Дипломатия', intel: 'Разведка', farms: 'Поля', roads: 'Дороги', orchards: 'Сады', wells: 'Водопровод', granaries: 'Склады', schools: 'Школы', clinics: 'Лечебницы', universities: 'Университеты', trade: 'Договоры' };
  const INTENTS = { trade: 'расширение торговли', train: 'набор и обучение войск', fortify: 'укрепление границы', raid: 'подготовка военного давления', recover: 'восстановление хозяйства', diplomacy: 'поиск соглашений' };
  const clamp = (n, min, max) => Math.max(min, Math.min(max, n));
  const copy = value => JSON.parse(JSON.stringify(value));
  const country = id => COUNTRIES.find(n => n.id === id);
  const definition = id => COMMANDS.find(c => c.id === id);
  const relationLabel = value => value > 20 ? 'Доброжелательные' : value < -35 ? 'Враждебные' : value < -10 ? 'Напряжённые' : 'Сдержанные';
  const trusted = (s, id) => s.characters?.find(p => p.id === id)?.trust >= 75;
  function fail(message) { throw new Error(message); }
  function hash(text) { let h = 2166136261; for (const c of String(text)) { h ^= c.charCodeAt(0); h = Math.imul(h, 16777619); } return h >>> 0; }
  function random(s) {
    s.rng = (s.rng + 0x6D2B79F5) >>> 0;
    let t = s.rng; t = Math.imul(t ^ t >>> 15, t | 1); t ^= t + Math.imul(t ^ t >>> 7, t | 61);
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  }
  const date = month => `${MONTHS[month % 12]} ${1248 + Math.floor(month / 12)}`;
  function differences(before, after) { return Object.fromEntries(Object.keys(METRICS).filter(k => after[k] !== before[k]).map(k => [k, after[k] - before[k]])); }
  function log(s, text, reason = '', kind = 'court', changes = {}) {
    s.history.unshift({ id: s.nextId++, month: s.month, text, reason, kind, changes });
    s.history = s.history.slice(0, 100);
  }
  function settle(s) {
    const p = s.player;
    for (const key of ['gold', 'food', 'army']) p[key] = clamp(Math.round(p[key]), 0, 9999);
    p.defense = clamp(Math.round(p.defense), 0, 200);
    p.stability = clamp(Math.round(p.stability), 0, 100);
    p.health = clamp(Math.round(p.health), 0, 100);
    p.population = clamp(Math.round(p.population), 0, 500);
    for (const key of ['science', 'diplomacy', 'intel', 'farms', 'roads', 'trade', 'orchards', 'wells', 'granaries', 'schools', 'clinics', 'universities']) p[key] = clamp(p[key], 0, 20);
    for (const b of BUILDINGS) p[b.key] = clamp(p[b.key], 0, b.max);
    for (const n of s.neighbors) {
      for (const key of ['gold', 'food', 'army', 'defense']) n[key] = clamp(Math.round(n[key]), 0, 9999);
      n.stability = clamp(Math.round(n.stability), 0, 100);
      n.relation = clamp(n.relation, -100, 100);
      for (const key of Object.keys(n.relations)) n.relations[key] = clamp(n.relations[key], -100, 100);
    }
    if (!s.ended && (p.stability === 0 || p.population < 10)) {
      s.ended = true;
      log(s, 'Совет отстранил правителя. Эта история завершена.', 'Государство потеряло устойчивость или население.', 'danger');
    }
    return s;
  }
  function economy(s) {
    const p = s.player;
    const season = s.month % 12;
    const harvest = season >= 7 && season <= 9 ? 15 : season <= 1 || season === 11 ? 5 : 9;
    const income = 17 + p.roads * 3 + p.trade * 3 + p.science + p.orchards + p.universities * 2 + ({ low: -4, balanced: 0, high: 7 })[s.laws.tax] - (s.laws.grain === 'reserve' ? 3 : 0) + (trusted(s, 'treasurer') ? 2 : 0);
    const upkeep = 7 + Math.floor(p.army / 20) + p.clinics * 2 + p.universities * 3 + (s.laws.education === 'public' ? 4 : 0) - (trusted(s, 'marshal') ? 1 : 0);
    const production = harvest + p.farms * 5 + p.orchards * 3;
    const consumption = Math.max(5, 9 + Math.floor(p.army / 18) - (p.rationUntil > s.month ? 4 : 0) - (s.laws.grain === 'reserve' ? 2 : 0));
    const losses = Math.max(0, Math.floor(p.food * 0.025) - p.granaries * 3);
    return { income, upkeep, production, consumption, losses, gold: income - upkeep, food: production - consumption - losses, season: harvest === 15 ? 'сбор урожая' : harvest === 5 ? 'зимние запасы' : 'полевые работы' };
  }
  function observe(s, army, defense = 0) {
    return { army: Math.max(1, Math.round(army * (0.6 + random(s) * 0.8))), defense: Math.round(defense * (0.6 + random(s) * 0.8)), month: s.month };
  }
  function createGame({ seed = 'Арден-1248', scenario = 'balanced' } = {}) {
    if (!['balanced', 'frontier', 'scarcity'].includes(scenario)) fail('Неизвестные условия кампании.');
    seed = String(seed).trim().slice(0, 80) || 'Арден-1248';
    const s = { version: VERSION, seed, scenario, rng: hash(seed), month: 0, nextId: 1, ap: 2, ended: false,
      player: { gold: 110, food: 80, stability: 68, army: 55, defense: 35, health: 68, science: 2, diplomacy: 2, intel: 1, population: 100, farms: 0, roads: 0, orchards: 0, wells: 0, granaries: 0, schools: 0, clinics: 0, universities: 0, trade: 0, rationUntil: 0 },
      neighbors: [], orders: [], completed: [], reports: [], history: [], aiHistory: [], chains: [], cooldowns: { border: 0, grain: 0 }, pending: null,
      laws: { tax: 'balanced', grain: 'market', education: 'elite' }, metrics: [], lastTurn: null, chapter: null, initial: null, monthStart: null, monthStartId: 1,
      attention: 2, characters: PEOPLE.map(p => ({ id: p.id, trust: 50 })), encounters: [], futureStories: [], storyMemory: {} };
    if (scenario === 'frontier') { s.player.army = 68; s.player.gold = 95; s.player.defense = 42; }
    if (scenario === 'scarcity') { s.player.food = 36; s.player.gold = 130; s.player.stability = 58; }
    s.neighbors = COUNTRIES.map(c => ({ id: c.id, gold: c.gold, food: 70, army: c.army, defense: 25, stability: 70,
      relation: c.relation - (scenario === 'frontier' ? 16 : 0), aggression: c.aggression, intent: 'fortify', turns: 0, pactUntil: 0,
      relations: Object.fromEntries(COUNTRIES.filter(o => o.id !== c.id).map(o => [o.id, c.id === 'nor' || o.id === 'nor' ? -25 : 10])), beliefs: {} }));
    for (const n of s.neighbors) {
      n.beliefs.player = observe(s, s.player.army, s.player.defense);
      for (const other of s.neighbors) if (other.id !== n.id) n.beliefs[other.id] = observe(s, other.army, other.defense);
      issueReport(s, n, 'Купеческие слухи', 0.48);
    }
    log(s, 'Вы приняли печать Арденского княжества. Ваша история начинается.', 'У каждого соседа собственные цели. Начальные слухи не проверены.');
    refreshEvent(s);
    refreshEncounters(s);
    s.initial = copy(s.player); s.monthStart = copy(s.player); s.monthStartId = s.nextId;
    s.metrics.push({ month: 0, values: copy(s.player) });
    return s;
  }
  function issueReport(s, n, source, confidence) {
    const accurateIntent = random(s) < confidence;
    const intents = Object.keys(INTENTS);
    const alternatives = intents.filter(id => id !== n.intent);
    const intent = accurateIntent ? n.intent : alternatives[Math.floor(random(s) * alternatives.length)];
    const bias = (random(s) - 0.5) * (1.8 - confidence);
    const estimate = Math.max(5, Math.round(n.army * (1 + bias)));
    const margin = Math.max(5, Math.round(estimate * (0.3 - confidence * 0.17)));
    s.reports.unshift({ id: s.nextId++, target: n.id, observed: s.month, delivered: s.month, source,
      confidence: Math.round(confidence * 100), armyMin: Math.max(0, estimate - margin), armyMax: estimate + margin, intent });
    s.reports = s.reports.slice(0, 30);
  }
  function orderBlocker(s, id, target) {
    const d = commandDetails(s, id);
    if (!d) return 'Неизвестный приказ.';
    if (s.ended) return 'Правление завершено.';
    if (d.requirement) return d.requirement;
    if (d.target && !country(target)) return 'Выберите государство.';
    if (s.ap < 1) return 'Лимит двух новых приказов на этот месяц исчерпан.';
    if (s.orders.length >= 6) return 'Одновременно можно вести шесть поручений.';
    if (s.player.gold < d.gold) return `Не хватает монет: нужно ${d.gold}.`;
    if (s.orders.filter(o => definition(o.type).actor === d.actor).length >= CAPACITY[d.actor]) return `${d.executor}: все исполнители заняты.`;
    return '';
  }
  function commandDetails(s, id) {
    const base = definition(id); if (!base) return null;
    const d = { ...base, requirement: '' };
    if (d.building) {
      const b = BUILDINGS.find(b => b.key === d.building), level = s.player[b.key];
      d.gold = Math.round(base.gold * (1 + level * 0.5)); d.level = level; d.maxLevel = b.max;
      if (trusted(s, 'engineer')) d.gold = Math.floor(d.gold * 0.9);
      if (level >= b.max) d.requirement = 'Достигнут максимальный уровень.';
      else if (s.orders.some(o => o.type === id)) d.requirement = 'Этот объект уже строится.';
      else if (b.requires && Object.entries(b.requires).some(([k, v]) => s.player[k] < v)) d.requirement = 'Нужны 2 школы и наука не ниже 4.';
    }
    if (d.law) {
      if (s.laws[d.law] === d.value) d.requirement = 'Закон уже действует.';
      else if (s.orders.some(o => definition(o.type).law === d.law)) d.requirement = 'Изменение этого закона уже готовится.';
      else if (d.law === 'education' && d.value === 'public' && s.player.schools < 1) d.requirement = 'Сначала постройте земскую школу.';
    }
    return d;
  }
  function queueOrder(state, id, target = 'val') {
    const blocker = orderBlocker(state, id, target); if (blocker) fail(blocker);
    const s = copy(state), d = commandDetails(s, id);
    s.player.gold -= d.gold; s.ap--;
    s.orders.push({ id: s.nextId++, type: id, target: d.target ? target : null, remaining: d.duration, duration: d.duration, started: s.month, paid: d.gold });
    log(s, `${d.name}${d.target ? ': ' + country(target).name : ''}. Поручение принято.`, `Казна −${d.gold}. Срок: ${d.duration} мес. Исполнитель: ${d.executor}.`, 'order', { gold: -d.gold });
    return s;
  }
  function completeOrder(s, o) {
    const p = s.player, n = s.neighbors.find(n => n.id === o.target), d = definition(o.type);
    const before = copy(p);
    let result = '';
    if (d.law) { s.laws[d.law] = d.value; result = `Закон вступил в силу. ${d.description}`; }
    switch (o.type) {
      case 'scout': {
        const risk = clamp(0.18 + n.aggression * 0.001 - p.intel * 0.025, 0.04, 0.3);
        if (random(s) < risk) { n.relation -= 8; result = 'Агент схвачен. Донесение не доставлено; отношения ухудшились.'; }
        else { issueReport(s, n, 'Тайная канцелярия', clamp(0.61 + p.intel * 0.045, 0.6, 0.93)); result = 'Получено новое донесение. Оценки могут быть ошибочными.'; }
        break;
      }
      case 'envoy':
        if (random(s) < clamp(0.53 + p.diplomacy * 0.06 + n.relation / 400 + (trusted(s, 'envoy') ? 0.1 : 0), 0.2, 0.92)) {
          n.relation += 18; result = 'Посольство снизило недоверие.';
          if (n.relation > 10 && n.pactUntil <= s.month) { n.pactUntil = s.month + 6; p.trade++; result += ' На 6 месяцев открыт торговый договор: доход +3/мес.'; }
        } else { n.relation -= 5; result = 'Условия отвергнуты. Недоверие выросло; потраченные средства не возвращены.'; }
        break;
      case 'patrol': p.defense += 7; s.neighbors.forEach(n => { n.relation -= 3; }); result = 'Оборона +7. Соседи насторожились из-за усиления застав.'; break;
      case 'train': p.army += 10; result = 'Армия +10. Проверьте растущие расходы на содержание.'; break;
      case 'farm': p.farms++; p.food += 12; result = 'Поля +1, зерно +12. Производство зерна +5/мес.'; break;
      case 'road': p.roads++; p.defense += 2; result = 'Дороги +1, оборона +2. Доход +3/мес.'; break;
      case 'aid': p.stability += 10; result = 'Стабильность +10. Земский совет доставил помощь жителям.'; break;
      case 'grain': p.food += 28; result = 'Зерно +28. Обоз прибыл до месячного потребления.'; break;
      case 'school': p.schools++; p.science++; p.diplomacy++; result = 'Школы +1, наука +1, дипломатия +1. Доход от управления +1/мес.'; break;
      case 'network': p.intel++; result = 'Разведка +1. Подготовленные агенты дают более надёжные сведения.'; break;
      case 'orchard': p.orchards++; p.health += 3; result = 'Сады +1, здоровье +3. Производство зерна +3/мес., доход +1/мес.'; break;
      case 'well': p.wells++; p.health += 4; result = 'Водопровод +1, здоровье +4. Здоровье растёт на 1/мес.'; break;
      case 'granary': p.granaries++; result = 'Склады +1. Потери от хранения уменьшены на 3/мес. (до нуля).'; break;
      case 'clinic': p.clinics++; result = 'Лечебницы +1. Здоровье +2/мес., содержание −2 монеты/мес.'; break;
      case 'university': p.universities++; p.science += 2; p.intel++; result = 'Университеты +1, наука +2, разведка +1. Доход +4/мес., содержание −3/мес.'; break;
    }
    settle(s);
    log(s, `${d.name}: ${result}`, `Завершено поручение, выданное в ${date(o.started).toLowerCase()}.`, o.type === 'scout' ? 'intel' : 'success', differences(before, p));
    s.completed.unshift({ ...o, remaining: 0, finished: s.month, result });
    s.completed = s.completed.slice(0, 12);
  }
  /* Решение получает только собственные сведения страны, без истинного состояния чужих армий. */
  function decideNeighbor(n) {
    if (n.food < 24 || n.stability < 42) return { action: 'recover', target: null, reason: 'Нехватка продовольствия или внутренние волнения.' };
    if (n.gold < 20) return { action: 'trade', target: null, reason: 'Недостаточно средств для военной политики.' };
    const targets = Object.entries(n.beliefs).map(([id, belief]) => ({ id, belief, relation: id === 'player' ? n.relation : n.relations[id] }));
    targets.sort((a, b) => (a.relation + a.belief.army * 0.3) - (b.relation + b.belief.army * 0.3));
    const weakest = targets[0];
    if (weakest && n.aggression > 45 && weakest.relation < -32 && n.army > weakest.belief.army * 0.85 + weakest.belief.defense * 0.3 && n.gold >= 12) {
      return { action: 'raid', target: weakest.id, reason: 'Враждебные отношения и предполагаемое военное превосходство.' };
    }
    if (n.id === 'mer' && n.gold < 180) return { action: 'trade', target: null, reason: 'Торговая республика наращивает прибыль.' };
    if (n.relation < -30 && n.defense < 65 && n.gold >= 12) return { action: 'fortify', target: null, reason: 'Недоверие к Ардену требует укрепления рубежей.' };
    if (n.army < (n.id === 'nor' ? 100 : 75) && n.gold >= 16) return { action: 'train', target: null, reason: 'Правитель восстанавливает желаемую численность войск.' };
    return { action: 'diplomacy', target: null, reason: 'Сила достаточна, новый конфликт невыгоден.' };
  }
  function runNeighbors(s) {
    // Наблюдение — отдельная фаза. Во время выбора цели ИИ не читает скрытую силу противника.
    for (const n of s.neighbors) {
      n.gold += 9 + (n.id === 'mer' ? 5 : 0) - Math.floor(n.army / 22);
      n.food += 10 - Math.floor(n.army / 14);
      if (random(s) < 0.4) n.beliefs.player = observe(s, s.player.army, s.player.defense);
      for (const other of s.neighbors) if (other.id !== n.id && random(s) < 0.25) n.beliefs[other.id] = observe(s, other.army, other.defense);
    }
    const decisions = s.neighbors.map(n => ({ id: n.id, ...decideNeighbor(n) }));
    for (const decision of decisions) {
      const n = s.neighbors.find(n => n.id === decision.id);
      n.intent = decision.action; n.turns++;
      switch (decision.action) {
        case 'recover': n.gold -= Math.min(n.gold, 10); n.food += 22; n.stability += 8; break;
        case 'trade': n.gold += 12; n.food += 4; break;
        case 'train': n.gold -= 16; n.army += 7; break;
        case 'fortify': n.gold -= 12; n.defense += 6; break;
        case 'diplomacy': n.relation += 3; for (const id of Object.keys(n.relations)) n.relations[id] += 2; break;
        case 'raid': {
          n.gold -= 12;
          const victim = decision.target === 'player' ? s.player : s.neighbors.find(o => o.id === decision.target);
          const before = copy(s.player);
          const success = random(s) < clamp(0.5 + (n.army - victim.army - victim.defense * 0.65) / 180, 0.12, 0.85);
          n.army -= 3 + Math.floor(random(s) * 5);
          if (success) {
            const loot = Math.min(victim.gold, 12); victim.gold -= loot; n.gold += loot;
            victim.food -= Math.min(victim.food, 8); victim.stability -= 5; victim.army -= Math.min(victim.army, 4);
          }
          if (decision.target === 'player') {
            n.relation -= 8;
            log(s, `${country(n.id).name}: ${success ? 'набег прорвался через границу. Казна и запасы пострадали.' : 'пограничная стража отбила набег.'}`, 'Взаимное недоверие и оценка нашей силы спровоцировали соседа. Разведданные могли устареть.', 'danger', differences(before, s.player));
          } else { n.relations[decision.target] -= 8; victim.relations[n.id] -= 10; }
          break;
        }
      }
      s.aiHistory.unshift({ month: s.month, ...decision });
    }
    s.aiHistory = s.aiHistory.slice(0, 120);
  }
  function refreshEvent(s) {
    if (s.ended || s.pending) return;
    const due = s.chains.filter(c => c.due <= s.month).sort((a, b) => a.due - b.due)[0];
    if (due) { s.pending = { kind: due.type + '_followup', target: due.target, approach: due.approach, origin: due.origin, secret: due.secret, created: s.month }; s.chains.splice(s.chains.indexOf(due), 1); return; }
    if (s.player.food < 60 && s.cooldowns.grain <= s.month && !s.chains.some(c => c.type === 'grain')) {
      s.pending = { kind: 'grain', target: null, created: s.month }; return;
    }
    const anxious = s.neighbors.filter(n => n.relation < -20).sort((a, b) => a.relation - b.relation)[0];
    if (anxious && s.cooldowns.border <= s.month && !s.chains.some(c => c.type === 'border')) {
      s.pending = { kind: 'border', target: anxious.id, secret: random(s) < 0.5 ? 'bandits' : 'soldiers', created: s.month };
    }
  }
  function eventView(s) {
    const e = s.pending; if (!e) return null;
    const name = e.target ? country(e.target).name : '';
    const choice = (id, title, description, gold = 0, food = 0) => ({ id, title, description, gold, food, disabled: s.player.gold < gold || s.player.food < food });
    const common = { kind: e.kind, target: e.target, date: date(e.created) };
    if (e.kind === 'border') return { ...common, title: 'Огни за пограничной рекой', category: 'Пограничная тревога · I',
      text: `Стражники заметили вооружённых людей у рубежей. ${name} не дала объяснений. Это может быть подготовка набега, обычный дозор или разбойники.`,
      cause: 'Сосед встревожен отношениями с Арденом. Непроверенный слух может усилить взаимные подозрения.',
      choices: [choice('investigate', 'Выяснить, кто это', 'Послать следопытов и дождаться проверенных сведений.', 8), choice('mobilize', 'Выдвинуть гарнизон', 'Показать, что княжество готово охранять переправу.', 12), choice('wait', 'Пока наблюдать', 'Не предпринимать новых действий до следующей вести с границы.')] };
    if (e.kind === 'border_followup') return { ...common, title: e.approach === 'investigate' ? 'Следы у переправы' : 'Два берега, два гарнизона', category: 'Пограничная тревога · II',
      text: e.approach === 'investigate' ? (e.secret === 'bandits' ? 'Следопыты нашли лагерь разбойников. Следов приказа чужого правителя нет. Слух о вторжении оказался поспешным.' : 'Следопыты опознали соседский дозор. Его приказ — наблюдать за нашей границей; доказательств вторжения нет.') : 'После нашего ответа сосед усилил заставы. Каждый двор объясняет свои приготовления защитой и подозревает другой.',
      cause: `Продолжение решения «${({ investigate: 'Выяснить, кто это', mobilize: 'Выдвинуть гарнизон', wait: 'Пока наблюдать' })[e.approach]}», принятого в ${date(e.origin).toLowerCase()}.`,
      choices: [choice('talk', 'Созвать пограничную встречу', 'Предложить соседу обсудить случившееся лицом к лицу.', 6), choice('guard', 'Сохранить усиленную стражу', 'Оставить людей на передовых заставах.'), choice('standdown', 'Отвести лишние патрули', 'Вернуть часть стражи с пограничных позиций.')] };
    if (e.kind === 'grain') return { ...common, title: 'Старосты просят открыть амбары', category: 'Цена хлеба · I',
      text: 'Запасы зерна опустились ниже 60. Старосты просят помощи деревням, купцы предлагают привозное зерно. Отказ от любых мер тоже имеет последствия.',
      cause: `Сейчас в запасе ${s.player.food}; месячный баланс ${signed(economy(s).food)}. Нехватка пищи подрывает стабильность.`,
      choices: [choice('relief', 'Открыть княжеские амбары', 'Отдать часть запасов деревням, обратившимся за помощью.', 0, 12), choice('import', 'Оплатить обозы', 'Заказать продовольствие у купцов.', 14), choice('ration', 'Ввести нормирование', 'Установить общий порядок выдачи зерна из запасов.')] };
    return { ...common, title: 'После голодной зимы', category: 'Цена хлеба · II',
      text: ({ relief: 'Деревни помнят, что амбары открыли вовремя. Теперь земледельцы просят вложиться в следующий урожай.', import: 'Привозное зерно помогло, но сделало деревни зависимыми от купеческих обозов. Пора выбрать долгосрочную меру.', ration: 'Нормирование растянуло запасы, однако тяжело далось жителям. Совет предлагает перейти к восстановлению.' })[e.approach],
      cause: `Последствие продовольственного решения в ${date(e.origin).toLowerCase()}. Разовая помощь не заменяет производство.`,
      choices: [choice('fields', 'Помочь деревням с посевом', 'Выделить средства на общие работы и следующий урожай.', 12), choice('fair', 'Распределить помощь поровну', 'Собрать оставшуюся помощь и передать её деревням на равных условиях.'), choice('levy', 'Потребовать новый сбор', 'Поручить сборщикам получить средства с деревень.')] };
  }
  function chooseEvent(state, choiceId) {
    if (state.ended) fail('Правление завершено.');
    if (!state.pending) fail('Срочного решения сейчас нет.');
    const option = eventView(state).choices.find(c => c.id === choiceId);
    if (!option) fail('Неизвестное решение совета.');
    if (option.disabled) fail('Для решения не хватает монет или зерна.');
    const s = copy(state), e = s.pending, p = s.player, n = s.neighbors.find(n => n.id === e.target), before = copy(s.player);
    p.gold -= option.gold; p.food -= option.food;
    if (e.kind === 'border') {
      if (choiceId === 'mobilize') { p.defense += 8; n.relation -= 12; }
      if (choiceId === 'wait') n.relation -= 4;
      s.chains.push({ type: 'border', target: e.target, approach: choiceId, due: s.month + 2, origin: s.month, secret: e.secret });
    } else if (e.kind === 'border_followup') {
      if (choiceId === 'talk') n.relation += e.approach === 'investigate' ? 25 : 12;
      if (choiceId === 'guard') { p.defense += 5; n.relation -= 12; }
      if (choiceId === 'standdown') { p.defense = Math.max(0, p.defense - 4); n.relation += 16; }
      s.cooldowns.border = s.month + 7;
    } else if (e.kind === 'grain') {
      if (choiceId === 'relief') p.stability += 9;
      if (choiceId === 'import') p.food += 28;
      if (choiceId === 'ration') { p.stability -= 6; p.rationUntil = s.month + 3; }
      s.chains.push({ type: 'grain', target: null, approach: choiceId, due: s.month + 3, origin: s.month, secret: null });
    } else {
      if (choiceId === 'fields') { if (p.farms >= 5) p.food += 20; else p.farms++; p.stability += 3; }
      if (choiceId === 'fair') { p.food += 8; p.stability += 4; }
      if (choiceId === 'levy') { p.gold += 14; p.stability -= 9; }
      s.cooldowns.grain = s.month + 6;
    }
    settle(s);
    const aftermath = {
      border: { investigate: 'Следопыты отправились к переправе. Вы поручили им проверить следы, прежде чем обвинять соседа. Ответа пока нет.', mobilize: 'Гарнизон занял новые позиции у переправы. Заставы укрепились, но соседские дозоры встретили ваше выдвижение с большим недоверием.', wait: 'Вы не стали отдавать новых распоряжений. На границе продолжили наблюдение, а подозрения остались без объяснения.' },
      border_followup: { talk: e.approach === 'investigate' ? 'На пограничной встрече вы предъявили собранные сведения. Разговор помог снять часть взаимных подозрений.' : 'Представители двух сторон встретились у границы. После разговора сосед стал менее враждебно оценивать ваши действия.', guard: 'Усиленная стража осталась на заставах. Рубеж стал крепче, однако на другом берегу сочли это признаком недоверия.', standdown: 'Часть передовых патрулей вернулась к обычной службе. Оборона на этом участке ослабла, зато сосед увидел в отводе людей шаг к спокойствию.' },
      grain: { relief: 'Зерно из княжеских амбаров передали просившим деревням. Жители приняли помощь с благодарностью; собственные запасы двора уменьшились.', import: 'Оплаченные купеческие обозы доставили зерно в амбары. Непосредственную нехватку удалось смягчить, но вопрос о будущем снабжении остался.', ration: 'В княжестве начали выдавать зерно по общей норме. Запасы стали расходовать бережнее, однако ограничения встретили недовольство жителей.' },
      grain_followup: { fields: before.farms >= 5 ? 'На уже освоенных полях организовали дополнительные работы и собрали зерно. Деревни увидели, что двор готов вкладываться в их хозяйство.' : 'Деревни получили средства на посев и освоили новые поля. Производство стало устойчивее, а жители встретили поддержку с надеждой.', fair: 'Оставшуюся помощь собрали и передали деревням по общему порядку. Запасы пополнились, а спор о том, кому достанется больше, затих.', levy: 'Сборщики доставили в казну новые средства. В деревнях тяжёлый сбор запомнили как требование платить вскоре после перенесённой нужды.' },
    }[e.kind][choiceId];
    log(s, `${option.title}. ${aftermath}`, eventView(state).cause, 'council', differences(before, p));
    s.pending = null;
    if (s.ended) s.chapter = makeChapter(s);
    return settle(s);
  }
  function advanceMonth(state) {
    if (state.ended) fail('Правление завершено. Начните новую кампанию.');
    if (state.pending) fail('Сначала примите срочное решение совета.');
    if (state.chapter && !state.chapter.acknowledged) fail('Сначала прочитайте итоги года и продолжите правление.');
    const s = copy(state); s.month++;
    // Истёкший договор закрывается до доходов и нового посольства: без лишнего
    // месяца дохода и без двойного счётчика при продлении в тот же ход.
    for (const n of s.neighbors) if (n.pactUntil && n.pactUntil <= s.month) {
      n.pactUntil = 0; s.player.trade = Math.max(0, s.player.trade - 1);
      log(s, `Торговый договор с ${country(n.id).name} истёк.`, 'Посольство может договориться о новом сроке. Доход −3/мес.', 'world', { trade: -1 });
    }
    const active = [];
    for (const o of s.orders) { o.remaining--; if (o.remaining === 0) completeOrder(s, o); else active.push(o); }
    s.orders = active;
    const flow = economy({ ...s, month: s.month - 1 });
    const p = s.player;
    const beforeEconomy = copy(p);
    const unpaid = p.gold + flow.income < flow.upkeep;
    p.gold += flow.gold;
    p.food += flow.food;
    settle(s);
    log(s, `Месячный баланс: казна ${signed(p.gold - beforeEconomy.gold)}, зерно ${signed(p.food - beforeEconomy.food)}.`, `Налоги и торговля +${flow.income}, содержание −${flow.upkeep}; урожай +${flow.production}, потребление −${flow.consumption}, потери хранения −${flow.losses}. Завершённые приказы уже учтены.`, 'economy', differences(beforeEconomy, p));
    const beforeLiving = copy(p);
    if (unpaid) { p.stability -= 7; log(s, 'Казна не покрыла жалование. Недовольство гарнизона растёт.', 'Недостаток средств: стабильность −7.', 'danger'); }
    if (p.food < 15) { p.stability -= 9; p.army -= Math.min(p.army, 3); p.population -= 1; p.health -= 5; log(s, 'Нехватка зерна ударила по деревням и войскам.', 'Запас ниже 15: стабильность −9, армия −3, население −1 тыс., здоровье −5.', 'danger'); }
    else if (p.food > 45 && p.stability < 85) p.stability += 1;
    p.stability += ({ low: 2, balanced: 0, high: -3 })[s.laws.tax] + (s.laws.education === 'public' ? 1 : 0) + (trusted(s, 'governor') ? 1 : 0);
    p.health += p.wells + p.clinics * 2 + (trusted(s, 'doctor') ? 1 : 0);
    if (s.month % 3 === 0 && p.health >= 70 && p.food > 30 && p.stability > 50) p.population++;
    if (s.laws.education === 'public' && p.schools > 0 && s.month % 6 === 0) p.science++;
    settle(s);
    const livingChanges = differences(beforeLiving, p);
    if (Object.keys(livingChanges).length) log(s, 'Жизнь княжества: жители, законы и городские службы.', 'Учтены питание, налоговый закон, образование, водопровод и лечебницы. Здоровое население при достатке растёт раз в квартал.', 'society', livingChanges);
    // Нельзя грабить уже отрицательные запасы: сначала нормализуем расчёт экономики.
    settle(s);
    if (!s.ended) runNeighbors(s);
    s.ap = 2;
    if (s.month % 12 === 0 && !s.ended) log(s, `Завершён ${s.month / 12}-й год правления. Кампания продолжается.`, 'Соседи, стройки и нерешённые дела переходят в следующий год.', 'milestone');
    settle(s); refreshEvent(s); s.attention = 2; refreshEncounters(s);
    s.lastTurn = { month: s.month, before: copy(state.monthStart), after: copy(s.player), changes: differences(state.monthStart, s.player), entries: copy(s.history.filter(h => h.id >= state.monthStartId).reverse()) };
    s.metrics.push({ month: s.month, values: copy(s.player) }); s.metrics = s.metrics.slice(-121);
    s.monthStart = copy(s.player); s.monthStartId = s.nextId;
    if (s.month % 12 === 0 || s.ended) s.chapter = makeChapter(s);
    return s;
  }
  function makeChapter(s) {
    const p = s.player, buildings = BUILDINGS.reduce((sum, b) => sum + p[b.key], 0), hostile = s.neighbors.filter(n => n.relation < -35).length;
    const title = s.ended ? 'Печать снята с вашей руки' : p.stability < 35 ? 'Трон пошатнулся, но устоял' : hostile >= 2 ? 'Мир на острие меча' : buildings >= 4 ? 'Княжество обрело опору' : 'Первый рубеж пройден';
    const story = s.ended ? 'Совет отстранил вас от власти. Цепь решений закончилась потерей устойчивости: одних обещаний оказалось недостаточно.' : `Летописец завершает ${Math.floor(s.month / 12)}-й год. ${buildings >= 4 ? 'Ваши вложения изменили повседневную жизнь княжества.' : 'Правление сохранилось, но основы будущего ещё предстоит построить.'} ${p.food < 30 ? 'Пустеющие амбары остаются главным вопросом следующего года.' : 'В амбарах есть зерно, и у жителей остаётся надежда.'} ${hostile >= 2 ? 'Военные подозрения соседей не исчезли — следующий год обещает быть тревожным.' : 'Дипломатия оставила пространство для мирного продолжения истории.'}`;
    return { year: Math.max(1, Math.ceil(s.month / 12)), month: s.month, title, story, buildings, hostile, acknowledged: false, final: s.ended, values: copy(p), initial: copy(s.initial) };
  }
  function acknowledgeChapter(state) { const s = copy(state); if (s.chapter) s.chapter.acknowledged = true; return s; }
  function refreshEncounters(s) {
    if (s.ended) { s.encounters = []; return; }
    s.encounters = [];
    const due = s.futureStories.filter(f => f.due <= s.month).slice(0, 2);
    for (const f of due) { s.encounters.push({ id: s.nextId++, template: f.template, created: s.month, resolved: false, origin: f.origin }); s.futureStories.splice(s.futureStories.indexOf(f), 1); }
    const candidates = STORIES.filter(t => !t.followup && (s.storyMemory[t.id] === undefined || s.month - s.storyMemory[t.id] >= 4) && (!t.when || (t.when.below !== undefined ? s.player[t.when.metric] < t.when.below : s.player[t.when.metric] > t.when.above)))
      .map(t => ({ t, score: random(s) + (t.when ? 0.3 : 0) })).sort((a, b) => b.score - a.score);
    for (const { t } of candidates.slice(0, 3 - s.encounters.length)) { s.storyMemory[t.id] = s.month; s.encounters.push({ id: s.nextId++, template: t.id, created: s.month, resolved: false, origin: null }); }
  }
  function storyView(s, encounter) {
    const t = STORIES.find(t => t.id === encounter.template), person = PEOPLE.find(p => p.id === t.person), trust = s.characters.find(p => p.id === t.person).trust;
    const view = { id: encounter.id, type: t.type, title: t.title, request: t.request, text: t.text, quote: t.quote, place: t.place, person: { ...person, trust }, date: date(encounter.created), resolved: encounter.resolved, choice: encounter.choice || null, origin: encounter.origin,
      choices: t.choices.map(c => ({ id: c.id, title: c.title, description: c.description, gold: c.gold, food: c.food,
        disabled: encounter.resolved || s.ended || s.attention < 1 || s.player.gold < c.gold || s.player.food < c.food || (c.future && s.futureStories.length >= 8) })) };
    if (encounter.resolved) {
      if (encounter.result) view.result = copy(encounter.result);
      else {
        // В сохранениях 0.4 итогового объекта ещё не было. Показатели можно
        // восстановить из журнала, но прошлое изменение доверия не выдумываем.
        const selected = t.choices.find(c => c.id === encounter.choice);
        const titles = [t.title, t.legacyTitle].filter(Boolean), choiceTitles = [selected.title, selected.legacyTitle].filter(Boolean);
        const entry = s.history.find(h => h.kind === 'story' && h.month === encounter.created && titles.some(title => choiceTitles.some(choice => h.text === `${title}: ${choice}.`)));
        view.result = { narrative: selected.aftermath, changes: entry ? copy(entry.changes) : null, trustChange: null, relations: [] };
      }
    }
    return view;
  }
  function resolveEncounter(state, encounterId, choiceId) {
    if (state.ended) fail('Правление завершено.');
    const encounter = state.encounters.find(e => e.id === encounterId);
    if (!encounter || encounter.resolved) fail('Эта встреча уже завершена или её время прошло.');
    const available = storyView(state, encounter).choices.find(c => c.id === choiceId);
    if (!available || available.disabled) fail('Для этого решения не хватает средств или личного внимания.');
    const s = copy(state), e = s.encounters.find(e => e.id === encounterId), t = STORIES.find(t => t.id === e.template), c = t.choices.find(c => c.id === choiceId), before = copy(s.player);
    s.player.gold -= c.gold; s.player.food -= c.food;
    for (const [key, value] of Object.entries(c.change)) s.player[key] += value;
    const person = s.characters.find(p => p.id === t.person), beforeTrust = person.trust;
    const beforeRelations = Object.fromEntries(s.neighbors.map(n => [n.id, n.relation]));
    person.trust = clamp(person.trust + (c.trust || 0), 0, 100);
    if (c.relation) for (const [id, value] of Object.entries(c.relation)) s.neighbors.find(n => n.id === id).relation += value;
    if (c.future) s.futureStories.push({ template: c.future, due: s.month + c.delay, origin: s.month });
    s.attention--; e.resolved = true; e.choice = choiceId;
    settle(s);
    e.result = { narrative: c.aftermath, changes: differences(before, s.player), trustChange: person.trust - beforeTrust,
      relations: s.neighbors.filter(n => n.relation !== beforeRelations[n.id]).map(n => ({ id: n.id, name: country(n.id).name, before: relationLabel(beforeRelations[n.id]), after: relationLabel(n.relation), direction: n.relation > beforeRelations[n.id] ? 'improved' : 'worsened' })) };
    const trustNote = e.result.trustChange ? ` Доверие: ${signed(e.result.trustChange)}.` : '';
    log(s, `${t.title}: ${c.title}.`, `${c.aftermath}${trustNote}${c.future ? ' Теперь ожидается ответ по этому делу.' : ''}`, 'story', copy(e.result.changes));
    if (s.ended) s.chapter = makeChapter(s);
    return s;
  }
  function signed(n) { return `${n > 0 ? '+' : ''}${n}`; }
  function getView(s) {
    return { version: VERSION, seed: s.seed, scenario: s.scenario, month: s.month, date: date(s.month), yearOfRule: Math.floor(s.month / 12) + 1,
      player: copy(s.player), economy: economy(s), ap: s.ap, ended: s.ended, event: eventView(s), orders: copy(s.orders), completed: copy(s.completed), history: copy(s.history),
      neighbors: COUNTRIES.map(c => { const n = s.neighbors.find(n => n.id === c.id); return { id: c.id, name: c.name, ruler: c.ruler, trait: c.trait, goal: c.goal,
        relations: relationLabel(n.relation),
        pactRemaining: Math.max(0, n.pactUntil - s.month), reports: s.reports.filter(r => r.target === c.id).slice(0, 3).map(r => ({ ...copy(r), age: s.month - r.observed, effectiveConfidence: Math.max(15, r.confidence - (s.month - r.observed) * 6), date: date(r.observed), intentLabel: INTENTS[r.intent] })) }; }),
      commands: COMMANDS.map(d => commandDetails(s, d.id)), buildings: copy(BUILDINGS), lawOptions: copy(LAWS), laws: copy(s.laws), metrics: copy(s.metrics), lastTurn: copy(s.lastTurn), chapter: copy(s.chapter),
      attention: s.attention, characters: s.characters.map(p => ({ ...PEOPLE.find(t => t.id === p.id), trust: p.trust, bonus: `${p.trust >= 75 ? 'Действует' : 'При доверии 75+'}: ${({ treasurer: 'доход +2/мес.', marshal: 'содержание армии −1/мес.', doctor: 'здоровье +1/мес.', engineer: 'строительство дешевле на 10%.', envoy: 'шанс успеха посольства +10 п. п.', governor: 'стабильность +1/мес.' })[p.id]}` })), encounters: s.encounters.map(e => storyView(s, e)), futureStories: s.futureStories.map(f => ({ title: `Ожидаются вести: ${STORIES.find(t => t.id === f.template).person === 'governor' ? 'западные деревни' : STORIES.find(t => t.id === f.template).person === 'marshal' ? 'пограничная застава' : 'порученная проверка'}`, dueIn: Math.max(0, f.due - s.month) })),
      chains: s.chains.map(c => ({ type: c.type, dueIn: Math.max(0, c.due - s.month) })) };
  }

  // Проверяем весь сохранённый граф перед использованием. Невалидный импорт не меняет текущую игру.
  function validateState(s) {
    const isObject = o => o !== null && typeof o === 'object' && !Array.isArray(o);
    const check = (condition, label) => { if (!condition) fail(`Повреждённое сохранение: ${label}.`); };
    const number = (n, min = 0, max = 9999) => Number.isInteger(n) && n >= min && n <= max;
    const text = (v, max = 1000) => typeof v === 'string' && v.length <= max;
    const list = (v, max) => Array.isArray(v) && v.length <= max;
    check(isObject(s) && s.version === VERSION, 'версия модели');
    check(text(s.seed, 80) && ['balanced', 'frontier', 'scarcity'].includes(s.scenario), 'условия кампании');
    check(number(s.month, 0, 1000000) && number(s.rng, 0, 4294967295) && number(s.nextId, 1, 1000000000) && number(s.ap, 0, 2) && typeof s.ended === 'boolean', 'ход и генератор случайностей');
    check(isObject(s.player), 'показатели княжества');
    for (const key of ['gold', 'food', 'army']) check(number(s.player[key]), key);
    for (const key of ['stability', 'population', 'defense', 'health']) check(number(s.player[key], 0, { stability: 100, population: 500, defense: 200, health: 100 }[key]), key);
    for (const key of ['farms', 'roads', 'trade', 'science', 'intel', 'diplomacy', 'orchards', 'wells', 'granaries', 'schools', 'clinics', 'universities']) check(number(s.player[key], 0, 20), key);
    check(number(s.player.rationUntil, 0, 1000010), 'нормирование');
    check(list(s.neighbors, 3) && s.neighbors.length === 3 && new Set(s.neighbors.map(n => n?.id)).size === 3, 'государства');
    for (const n of s.neighbors) {
      check(isObject(n) && country(n.id), 'государство');
      for (const key of ['gold', 'food', 'army', 'defense']) check(number(n[key]), 'ресурсы соседа');
      check(number(n.stability, 0, 100) && number(n.relation, -100, 100) && number(n.aggression, 0, 100) && number(n.turns, 0, 1000000) && number(n.pactUntil, 0, 1000010) && Object.hasOwn(INTENTS, n.intent), 'политика соседа');
      check(isObject(n.beliefs) && isObject(n.relations), 'знания соседа');
      for (const id of ['player', ...COUNTRIES.filter(c => c.id !== n.id).map(c => c.id)]) {
        const b = n.beliefs[id]; check(isObject(b) && number(b.army, 0, 15000) && number(b.defense, 0, 15000) && number(b.month, 0, s.month), 'наблюдения соседа');
        if (id !== 'player') check(number(n.relations[id], -100, 100), 'отношения соседей');
      }
    }
    check(list(s.orders, 6) && list(s.completed, 12), 'очередь поручений');
    const ids = new Set();
    for (const o of [...s.orders, ...s.completed]) {
      const d = definition(o?.type);
      check(isObject(o) && d && number(o.id, 1, s.nextId - 1) && !ids.has(o.id), 'идентификатор поручения'); ids.add(o.id);
      check((d.target ? Boolean(country(o.target)) : o.target === null) && o.duration === d.duration && number(o.remaining, 0, o.duration) && number(o.started, 0, s.month) && number(o.paid), 'срок, цена и цель поручения');
    }
    for (const o of s.orders) check(o.remaining > 0, 'активное поручение');
    for (const o of s.completed) check(o.remaining === 0 && number(o.finished, o.started, s.month) && text(o.result), 'завершённое поручение');
    for (const [actor, capacity] of Object.entries(CAPACITY)) check(s.orders.filter(o => definition(o.type).actor === actor).length <= capacity, 'исполнители');
    check(list(s.reports, 30) && list(s.history, 100) && list(s.aiHistory, 120) && list(s.chains, 2), 'журналы');
    for (const r of s.reports) check(isObject(r) && number(r.id, 1, s.nextId - 1) && country(r.target) && text(r.source, 80) && number(r.observed, 0, s.month) && number(r.delivered, r.observed, s.month) && number(r.confidence, 0, 100) && number(r.armyMin, 0, 20000) && number(r.armyMax, r.armyMin, 20000) && Object.hasOwn(INTENTS, r.intent), 'донесение');
    const validChanges = changes => isObject(changes) && Object.entries(changes).every(([k, v]) => Object.hasOwn(METRICS, k) && number(v, -9999, 9999));
    const validEntry = h => isObject(h) && number(h.id, 1, s.nextId - 1) && number(h.month, 0, s.month) && text(h.text) && text(h.reason) && text(h.kind, 40) && validChanges(h.changes);
    for (const h of s.history) check(validEntry(h), 'хроника');
    for (const h of s.aiHistory) check(isObject(h) && country(h.id) && number(h.month, 0, s.month) && Object.hasOwn(INTENTS, h.action) && (h.target === null || h.target === 'player' || country(h.target)) && text(h.reason), 'действие ИИ');
    const validApproach = (type, a) => (type === 'border' ? ['investigate', 'mobilize', 'wait'] : ['relief', 'import', 'ration']).includes(a);
    for (const c of s.chains) check(isObject(c) && ['border', 'grain'].includes(c.type) && validApproach(c.type, c.approach) && number(c.origin, 0, s.month) && number(c.due, c.origin, 1000010) && (c.type === 'border' ? country(c.target) && ['bandits', 'soldiers'].includes(c.secret) : c.target === null && c.secret === null), 'сюжетная цепочка');
    check(isObject(s.cooldowns) && number(s.cooldowns.border, 0, 1000010) && number(s.cooldowns.grain, 0, 1000010), 'сроки событий');
    if (s.pending !== null) {
      const e = s.pending;
      check(isObject(e) && ['border', 'grain', 'border_followup', 'grain_followup'].includes(e.kind) && number(e.created, 0, s.month), 'событие совета');
      if (e.kind.startsWith('border')) check(country(e.target) && ['bandits', 'soldiers'].includes(e.secret), 'пограничное событие');
      else check(e.target === null, 'продовольственное событие');
      if (e.kind.endsWith('_followup')) check(validApproach(e.kind.split('_')[0], e.approach) && number(e.origin, 0, s.month), 'продолжение события');
    }
    check(isObject(s.laws) && LAWS.every(law => law.options.some(o => o.value === s.laws[law.key])), 'законы');
    const validSnapshot = p => isObject(p) && Object.keys(METRICS).every(k => number(p[k])) && number(p.stability, 0, 100) && number(p.health, 0, 100) && number(p.rationUntil, 0, 1000010);
    check(validSnapshot(s.initial) && validSnapshot(s.monthStart) && number(s.monthStartId, 1, s.nextId), 'начало правления и месяца');
    check(list(s.metrics, 121) && s.metrics.length > 0 && s.metrics.every((m, i) => isObject(m) && number(m.month, 0, s.month) && validSnapshot(m.values) && (i === 0 || m.month === s.metrics[i - 1].month + 1)) && s.metrics.at(-1).month === s.month, 'история показателей');
    if (s.lastTurn !== null) check(isObject(s.lastTurn) && s.lastTurn.month === s.month && validSnapshot(s.lastTurn.before) && validSnapshot(s.lastTurn.after) && validChanges(s.lastTurn.changes) && list(s.lastTurn.entries, 100) && s.lastTurn.entries.every(validEntry), 'отчёт за месяц');
    if (s.chapter !== null) check(isObject(s.chapter) && number(s.chapter.year, 1, 1000000) && number(s.chapter.month, 0, s.month) && text(s.chapter.title) && text(s.chapter.story) && number(s.chapter.buildings) && number(s.chapter.hostile, 0, 3) && typeof s.chapter.acknowledged === 'boolean' && typeof s.chapter.final === 'boolean' && validSnapshot(s.chapter.values) && validSnapshot(s.chapter.initial), 'итог главы');
    check(number(s.attention, 0, 2) && list(s.characters, 6) && s.characters.length === 6 && new Set(s.characters.map(p => p?.id)).size === 6 && s.characters.every(p => PEOPLE.some(t => t.id === p?.id) && number(p.trust, 0, 100)), 'персонажи и личное внимание');
    check(list(s.encounters, 3) && s.encounters.every(e => isObject(e) && number(e.id, 1, s.nextId - 1) && STORIES.some(t => t.id === e.template && (!e.resolved || t.choices.some(c => c.id === e.choice))) && number(e.created, 0, s.month) && typeof e.resolved === 'boolean' && (e.origin === null || number(e.origin, 0, s.month))), 'встречи');
    const stances = ['Доброжелательные', 'Враждебные', 'Напряжённые', 'Сдержанные'];
    for (const e of s.encounters) if (Object.hasOwn(e, 'result')) {
      const r = e.result;
      check(e.resolved && isObject(r) && text(r.narrative, 2000) && validChanges(r.changes) && number(r.trustChange, -100, 100) && list(r.relations, 3) && r.relations.every(n => isObject(n) && country(n.id) && n.name === country(n.id).name && stances.includes(n.before) && stances.includes(n.after) && ['improved', 'worsened'].includes(n.direction)), 'итог встречи');
    }
    check(list(s.futureStories, 8) && s.futureStories.every(f => isObject(f) && STORIES.some(t => t.id === f.template && t.followup) && number(f.due, 0, 1000010) && number(f.origin, 0, s.month)), 'продолжения встреч');
    check(isObject(s.storyMemory) && Object.entries(s.storyMemory).every(([id, month]) => STORIES.some(t => t.id === id) && number(month, 0, s.month)), 'память историй');
    return true;
  }
  function serialize(s) { validateState(s); return JSON.stringify({ format: 'price-of-power', version: VERSION, state: s }); }
  function deserialize(raw) {
    if (typeof raw !== 'string' || raw.length > 1000000) fail('Файл сохранения слишком велик или имеет неверный формат.');
    let envelope;
    try { envelope = JSON.parse(raw); } catch { fail('Файл не является сохранением JSON.'); }
    if (!envelope || envelope.format !== 'price-of-power' || envelope.version !== VERSION) fail('Это сохранение другой игры или несовместимой версии. Нужна версия 0.4.');
    validateState(envelope.state);
    return copy(envelope.state);
  }
  return { VERSION, COUNTRIES: copy(COUNTRIES), COMMANDS: copy(COMMANDS), BUILDINGS: copy(BUILDINGS), LAWS: copy(LAWS), METRICS: copy(METRICS), INTENTS: copy(INTENTS), createGame, queueOrder, orderBlocker, chooseEvent, advanceMonth, acknowledgeChapter, resolveEncounter, getView, economy, decideNeighbor, serialize, deserialize, validateState, date };
});
