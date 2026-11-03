/* Цена власти: детерминированная модель. Работает в браузере и Node.js. */
(function (root, factory) {
  'use strict';
  const node = typeof module === 'object' && module.exports;
  const api = factory(node ? require('./stories.js') : root.PopStories, node ? require('./laws.js') : root.PopLaws, node ? require('./military.js') : root.PopMilitary);
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.PriceOfPower = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function (STORY_DATA, LAW_DATA, MILITARY) {
  'use strict';
  const VERSION = 4;
  const { PEOPLE, STORIES, TALKS } = STORY_DATA;
  const MONTHS = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
  const COUNTRIES = [
    { id: 'val', name: 'Вальдория', ruler: 'Король Эдрик', trait: 'Осторожный и подозрительный', goal: 'Безопасные границы', army: 70, gold: 88, aggression: 48, relation: -24 },
    { id: 'mer', name: 'Мерсия', ruler: 'Совет торговых домов', trait: 'Прагматичная республика', goal: 'Прибыль от торговли', army: 43, gold: 125, aggression: 22, relation: 22 },
    { id: 'nor', name: 'Нордвик', ruler: 'Князь Рагнар', trait: 'Честолюбивый и воинственный', goal: 'Военное превосходство', army: 82, gold: 70, aggression: 76, relation: -12 },
  ];
  const OFFICES=[
    {id:'medicine',name:'Глава врачебной службы',purpose:'Отвечает за эпидемии, лечебницы и карантин.',candidates:[
      {id:'lada',name:'Лада Мирская',experience:'Земский лекарь; знает деревни и доверяет профилактике.',connections:'Старосты и повитухи',benefit:'Здоровье +2/мес. во время эпидемии.',cost:'Требует открытых отчётов и не скрывает ошибки двора.'},
      {id:'severin',name:'Северин Край',experience:'Придворный врач с учёбой за границей.',connections:'Знать и иностранные аптекари',benefit:'Эпидемии короче; содержание службы +2 монеты.',cost:'Плохо понимает бедные кварталы.'},
      {id:'agafya',name:'Агафья Рудная',experience:'Жёсткий организатор карантинных застав.',connections:'Стража и монастырские приюты',benefit:'Потери населения от эпидемий ниже.',cost:'Карантин снижает стабильность на 1/мес. во время болезни.'},
    ]},
    {id:'army',name:'Воевода княжества',purpose:'Руководит обороной, призывом и снабжением армии.',candidates:[
      {id:'boran',name:'Боран Вельский',experience:'Ветеран пограничных походов.',connections:'Дружина и старые офицеры',benefit:'Оборона +6.',cost:'Содержание армии +2 монеты/мес.'},
      {id:'ratmir',name:'Ратмир Ольхов',experience:'Молодой сторонник строевой реформы.',connections:'Младшие командиры',benefit:'Обучение войск дешевле и эффективнее.',cost:'Старая дружина относится к нему настороженно.'},
      {id:'yaropolk',name:'Ярополк Дан',experience:'Знатный землевладелец и переговорщик.',connections:'Боярское ополчение',benefit:'Стабильность +1 при ограниченном призыве.',cost:'Оборона слабее профессионального воеводы.'},
    ]},
    {id:'justice',name:'Глава суда и порядка',purpose:'Курирует суды, тюрьмы, стражу и расследования.',candidates:[
      {id:'vera',name:'Вера Тихая',experience:'Судебный писец, известна точностью разбирательств.',connections:'Писцы и ремесленные братства',benefit:'Открытый суд даёт стабильность +1.',cost:'Расследования идут медленнее.'},
      {id:'grom',name:'Гром Железный',experience:'Бывший начальник ворот.',connections:'Городская стража',benefit:'Незаконные группировки теряют больше влияния.',cost:'При суровых карах стабильность −1/мес.'},
      {id:'milan',name:'Милан Речной',experience:'Посредник между купцами и кварталами.',connections:'Гильдия и речные перевозчики',benefit:'Доход +2/мес.',cost:'Контрабандисты медленнее теряют влияние.'},
    ]},
    {id:'works',name:'Распорядитель городских работ',purpose:'Управляет строителями, службами и рабочими повинностями.',candidates:[
      {id:'toma',name:'Тома Каменный',experience:'Мастер мостов и крепостных стен.',connections:'Каменщики и инженеры',benefit:'Строительство дешевле на 8%.',cost:'Городские службы получают меньше внимания.'},
      {id:'elena',name:'Елена Садовая',experience:'Управляла общинными работами.',connections:'Старосты и земские артели',benefit:'Здоровье +1 при организованной гражданской помощи.',cost:'Военные стройки не получают особого преимущества.'},
      {id:'kord',name:'Корд Цеховой',experience:'Богатый хозяин мастерских.',connections:'Ремесленные братства',benefit:'Мастерские дают +1 товар.',cost:'Доход −1/мес. из-за льгот цехам.'},
    ]},
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
    {id:'trade_goods',name:'Заключить сделку о товарах',category:'Дипломатия',actor:'merchants',executor:'Купеческая гильдия',duration:1,gold:3,target:true,description:'Продать до 10 товаров. Цена зависит от отношений, рынков и положения партнёра.'},
    {id:'intimidate',name:'Потребовать торговую уступку',category:'Дипломатия',actor:'envoys',executor:'Посольский двор',duration:1,gold:5,target:true,description:'Сильная армия может добиться скидки, но отказ резко ухудшит отношения.'},
    {id:'sabotage',name:'Подготовить диверсию',category:'Тайные дела',actor:'agents',executor:'Тайная канцелярия',duration:2,gold:18,target:true,description:'Ослабить оборону или хозяйство соседа. Успех зависит от разведки и специалистов; провал раскрывает участие.'},
    {id:'bribe_source',name:'Подкупить источник',category:'Тайные дела',actor:'agents',executor:'Тайная канцелярия',duration:1,gold:12,target:true,description:'Купить более точное донесение у чиновника или купца соседнего государства.'},
    {id:'recruit_expert',name:'Переманить специалиста',category:'Образование',actor:'envoys',executor:'Посольский двор',duration:2,gold:24,target:true,description:'Попытаться пригласить инженера, лекаря или разведчика. Отношения и престиж науки влияют на успех.'},
    {id:'tech_agriculture',name:'Исследовать севооборот',category:'Технологии',actor:'scholars',executor:'Учёный совет',duration:3,gold:22,description:'Технология повышает урожай каждого уровня полей.'},
    {id:'tech_engineering',name:'Исследовать каменное строительство',category:'Технологии',actor:'scholars',executor:'Учёный совет',duration:3,gold:28,description:'Технология укрепляет дороги, мосты и защиту от аварий.'},
    {id:'tech_medicine',name:'Развить врачебное дело',category:'Технологии',actor:'scholars',executor:'Учёный совет',duration:3,gold:26,description:'Технология усиливает лечебницы и снижает ущерб эпидемий.'},
    {id:'tech_military',name:'Создать полевой устав',category:'Технологии',actor:'scholars',executor:'Учёный совет',duration:3,gold:30,description:'Технология повышает опыт войск и качество походного снабжения.'},
    {id:'crackdown',name:'Операция против подполья',category:'Правопорядок',actor:'civil',executor:'Городская стража',duration:1,gold:10,description:'Снизить влияние сильнейшей незаконной группировки. Жёсткая операция может задеть невиновных.'},
    {id:'informants',name:'Внедрить осведомителей',category:'Тайные дела',actor:'agents',executor:'Тайная канцелярия',duration:2,gold:14,description:'Получать сведения из воровской и контрабандной среды, не вступая с ней в открытый союз.'},
    {id:'underworld_deal',name:'Тайная сделка с контрабандистами',category:'Правопорядок',actor:'merchants',executor:'Доверенный казначея',duration:1,gold:4,description:'Получить дешёвые товары и сведения ценой роста влияния подполья.'},
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
    { command:'houses',key:'houses',name:'Жилые кварталы',symbol:'houses',effect:'Вместимость населения и устойчивость; снижает эмиграцию при росте города.',max:5,gold:22,duration:3 },
    { command:'smithy',key:'smithies',name:'Кузницы',symbol:'smithy',effect:'Железо превращается в изделия; оборона и снабжение войска получают поддержку.',max:3,gold:30,duration:3 },
    { command:'lumberyard',key:'lumberyards',name:'Лесные дворы',symbol:'lumber',effect:'Древесина +4/мес. Нужна для жилья, мостов и ремонта после бедствий.',max:3,gold:20,duration:2 },
    { command:'quarry',key:'quarries',name:'Каменоломни',symbol:'quarry',effect:'Камень +3/мес. Укрепляет дороги, стены и общественные здания.',max:3,gold:26,duration:3 },
    { command:'mine',key:'mines',name:'Рудники',symbol:'mine',effect:'Железо +2/мес.; тяжёлая работа требует здоровья и порядка.',max:3,gold:34,duration:4 },
    { command:'workshop',key:'workshops',name:'Ремесленные мастерские',symbol:'workshop',effect:'Товары +3/мес. Каждый уровень даёт ещё одну строительную бригаду.',max:3,gold:32,duration:3 },
    { command:'market',key:'markets',name:'Торговые ряды',symbol:'market',effect:'Доход +3/мес.; товары можно выгоднее продавать соседям.',max:3,gold:25,duration:2 },
    { command:'firewatch',key:'fireStations',name:'Пожарная стража',symbol:'fire',effect:'Снижает ущерб от городских пожаров и защищает жилые кварталы.',max:2,gold:24,duration:2 },
    { command:'sanitation',key:'sanitation',name:'Канализация и очистка',symbol:'sanitation',effect:'Здоровье +1/мес.; снижает риск эпидемий и загрязнения воды.',max:3,gold:30,duration:3 },
    { command:'court',key:'courts',name:'Городской суд',symbol:'court',effect:'Открытые службы порядка дают стабильность и помогают разбирать злоупотребления.',max:2,gold:28,duration:3 },
    { command:'post',key:'postOffices',name:'Почтовая служба',symbol:'post',effect:'Дипломатия и разведка; донесения и просьбы быстрее доходят до двора.',max:2,gold:24,duration:2 },
    { command:'barracks',key:'barracks',name:'Казармы и арсенал',symbol:'barracks',effect:'Оборона +4 и качество подготовки армии при завершении.',max:3,gold:36,duration:3 },
    {command:'citywatch',key:'cityWatch',name:'Управление городской стражи',symbol:'watch',effect:'Профессиональные служащие патрулируют кварталы и расследуют преступления.',max:3,gold:32,duration:3},
    {command:'prison',key:'prisons',name:'Городская тюрьма',symbol:'prison',effect:'Позволяет изолировать опасных преступников; требует содержания и судебного надзора.',max:2,gold:38,duration:4},
  ];
  for (const b of BUILDINGS) {
    let d = COMMANDS.find(c => c.id === b.command);
    if (!d) { d = { id: b.command, name: `Построить: ${b.name.toLowerCase()}`, category: 'Город', actor: 'builders', executor: 'Земские мастера', gold: b.gold, duration: b.duration, description: b.effect }; COMMANDS.push(d); }
    d.building = b.key;
  }
  const LAWS = LAW_DATA.LAWS;
  for (const law of LAWS) for (const option of law.options) COMMANDS.push({ id: `law_${law.key}_${option.value}`, name: option.name, category: 'Законы', actor: 'council', executor: 'Княжеская канцелярия', gold: 0, duration: 1, law: law.key, value: option.value, description: option.effect });
  const CAPACITY = { agents: 1, envoys: 1, military: 2, builders: 2, civil: 1, merchants: 1, scholars: 1, council: 1 };
  const METRICS = { gold:'Казна',food:'Зерно',wood:'Древесина',stone:'Камень',iron:'Железо',goods:'Товары',stability:'Стабильность',army:'Армия',defense:'Оборона',health:'Здоровье',population:'Население',science:'Наука',diplomacy:'Дипломатия',intel:'Разведка',farms:'Поля',roads:'Дороги',orchards:'Сады',wells:'Водопровод',granaries:'Склады',schools:'Школы',clinics:'Лечебницы',universities:'Университеты',houses:'Жильё',smithies:'Кузницы',lumberyards:'Лесные дворы',quarries:'Каменоломни',mines:'Рудники',workshops:'Мастерские',markets:'Рынки',fireStations:'Пожарная стража',sanitation:'Канализация',courts:'Суды',postOffices:'Почта',barracks:'Казармы',cityWatch:'Городская стража',prisons:'Тюрьмы',trade:'Договоры' };
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
    for (const key of ['gold','food','wood','stone','iron','goods','army']) p[key] = clamp(Math.round(p[key]), 0, 9999);
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
    if (s.military) MILITARY.syncArmy(s);
    if (!s.ended && (p.stability === 0 || p.population < 10)) {
      s.ended = true;
      log(s, 'Совет отстранил правителя. Эта история завершена.', 'Государство потеряло устойчивость или население.', 'danger');
    }
    return s;
  }
  function economy(s) {
    const p = s.player, policy = LAW_DATA.extraEconomy(s);
    const season = s.month % 12;
    const harvest = season >= 7 && season <= 9 ? 15 : season <= 1 || season === 11 ? 5 : 9;
    const income = 17 + p.roads * 3 + p.trade * 3 + p.science + p.orchards + p.universities * 2 + p.markets*3 + p.workshops*2 + ({ low: -4, balanced: 0, high: 7 })[s.laws.tax] - (s.laws.grain === 'reserve' ? 3 : 0) + (trusted(s, 'treasurer') ? 2 : 0) + (s.appointments?.justice==='milan'?2:0) - (s.appointments?.works==='kord'?1:0) + policy.income;
    const upkeep = 7 + Math.floor(p.army / 20) + p.clinics * 2 + p.universities * 3 + p.fireStations + p.sanitation*2 + p.courts + p.postOffices + p.barracks + (s.laws.education === 'public' ? 4 : 0) - (trusted(s, 'marshal') ? 1 : 0) + policy.upkeep;
    const production = harvest + p.farms * (5+(s.technologies?.includes('agriculture')?2:0)) + p.orchards * 3 + policy.production;
    const consumption = Math.max(3, 7 + Math.floor(MILITARY.homeStrength(s) / 18) - (p.rationUntil > s.month ? 4 : 0));
    const exports = s.laws.grain === 'market' ? 2 : 0;
    const losses = Math.max(0, Math.floor(p.food * 0.025) - p.granaries * 3);
    return { income, upkeep, production, consumption, exports, losses, gold: income - upkeep, food: production - consumption - exports - losses, season: harvest === 15 ? 'сбор урожая' : harvest === 5 ? 'зимние запасы' : 'полевые работы' };
  }
  function createRuler() { return { fatigue: 0, health: 100, illUntil: 0, overtimeThisMonth: 0, restedThisMonth: false }; }
  function isRulerIll(s) { return Boolean(s.ruler && s.ruler.illUntil > s.month); }
  function rulerView(s) {
    const r = s.ruler || createRuler(), ill = isRulerIll(s);
    const warning = ill ? 'Лекарь запретил личный приём. Для выздоровления нужны отдых и время; совет может разбирать государственные дела.' : r.fatigue >= 65 ? 'Лекарь предупреждает: дальнейшая работа опасна. Сильное переутомление может привести к болезни и остановке личного приёма.' : r.fatigue >= 35 ? 'Вы устали. Советуетесь с лекарем: лучше закончить приём и отдохнуть, пока усталость не стала опасной.' : 'Вы можете принимать посетителей. Дополнительная работа даёт время для ещё одной встречи, но накапливает усталость.';
    return { ...copy(r), ill, monthsUntilRecovery: Math.max(0, r.illUntil - s.month), warning, canOvertime: !s.ended && !ill && r.overtimeThisMonth < 6, canRest: !s.ended && !r.restedThisMonth };
  }
  function workOvertime(state) {
    if (state.ended) fail('Правление завершено.');
    if (isRulerIll(state)) fail('Правитель болен. Дополнительная работа недоступна до выздоровления.');
    if (state.ruler.overtimeThisMonth >= 6) fail('Вы уже продлили рабочий день слишком много раз. Пора отдохнуть.');
    const s = copy(state), r = s.ruler;
    r.fatigue = clamp(r.fatigue + 18 + r.overtimeThisMonth * 4, 0, 100);
    r.overtimeThisMonth++;
    r.health = clamp(r.health - Math.max(0, Math.floor((r.fatigue - 30) / 10)), 0, 100);
    s.attention = Math.min(12, s.attention + 1);
    let ill = false;
    if (r.fatigue >= 85) ill = r.fatigue === 100 || random(s) < (r.fatigue - 60) / 50;
    if (ill) {
      r.health = Math.min(r.health, 45); r.illUntil = s.month + 2; s.attention = 0;
      log(s, 'Правитель слёг после переутомления. Личный приём остановлен.', 'Усталость достигла опасного уровня после предупреждений. Лекарь требует отдыха; государственные дела совет может продолжать без личных аудиенций.', 'ruler');
    } else log(s, 'Вы продлили рабочий день и получили время для ещё одной личной встречи.', `Усталость правителя: ${r.fatigue} из 100. ${r.fatigue >= 65 ? 'Лекарь предупреждает об опасности продолжения работы.' : r.fatigue >= 35 ? 'Накопилась заметная усталость; отдых восстановит силы.' : 'Работа сверх нормы постепенно истощает силы.'}`, 'ruler');
    return s;
  }
  function restRuler(state) {
    if (state.ended) fail('Правление завершено.');
    if (state.ruler.restedThisMonth) fail('В этом месяце вы уже выделили время для отдыха.');
    const s = copy(state), r = s.ruler;
    r.fatigue = Math.max(0, r.fatigue - 30); r.health = Math.min(100, r.health + 16); r.restedThisMonth = true; s.attention = 0;
    log(s, 'Вы отменили оставшийся личный приём и отвели время на отдых.', `Усталость правителя: ${r.fatigue}; здоровье: ${r.health}. Государственные поручения продолжают исполняться.`, 'ruler');
    return s;
  }
  function advanceRuler(s) {
    const r = s.ruler, wasIll = r.illUntil > s.month - 1;
    r.fatigue = Math.max(0, r.fatigue - (wasIll ? 30 : 12) - (r.restedThisMonth ? 8 : 0));
    r.health = Math.min(100, r.health + (wasIll ? 18 : 6));
    r.overtimeThisMonth = 0; r.restedThisMonth = false;
    if (wasIll && !isRulerIll(s)) log(s, 'Правитель выздоровел и может вернуться к личным встречам.', 'Время и отдых восстановили силы. Лекарь просит не повторять прежний режим работы.', 'ruler');
  }
  function observe(s, army, defense = 0) {
    return { army: Math.max(1, Math.round(army * (0.6 + random(s) * 0.8))), defense: Math.round(defense * (0.6 + random(s) * 0.8)), month: s.month };
  }
  function createGame({ seed = 'Арден-1248', scenario = 'balanced' } = {}) {
    if (!['balanced', 'frontier', 'scarcity'].includes(scenario)) fail('Неизвестные условия кампании.');
    seed = String(seed).trim().slice(0, 80) || 'Арден-1248';
    const s = { version: VERSION, seed, scenario, rng: hash(seed), month: 0, nextId: 1, ap: 2, ended: false,
      player: { gold:110,food:80,wood:18,stone:12,iron:6,goods:8,stability:68,army:55,defense:35,health:68,science:2,diplomacy:2,intel:1,population:100,farms:1,roads:1,orchards:0,wells:1,granaries:1,schools:0,clinics:0,universities:0,houses:1,smithies:1,lumberyards:1,quarries:0,mines:0,workshops:1,markets:1,fireStations:0,sanitation:0,courts:0,postOffices:0,barracks:1,cityWatch:0,prisons:0,trade:0,rationUntil:0 },
      neighbors: [], orders: [], completed: [], reports: [], history: [], aiHistory: [], chains: [], cooldowns: { border: 0, grain: 0 }, pending: null,
      laws: { ...LAW_DATA.defaults }, metrics: [], lastTurn: null, chapter: null, initial: null, monthStart: null, monthStartId: 1,
      ruler:createRuler(),attention:2,characters:PEOPLE.map(p=>({id:p.id,trust:50})),encounters:[],futureStories:[],storyMemory:{},conversations:[],nextCrisis:3,epidemic:null,appointments:{medicine:'lada',army:'yaropolk',justice:'vera',works:'elena'},technologies:[],specialists:{builders:1,physicians:1,spies:1,diplomats:1,engineers:1},tradeTerms:{},factions:[{id:'guild',name:'Купеческая гильдия',sphere:'торговля и пошлины',illegal:false,influence:42,relation:5},{id:'artisans',name:'Ремесленные братства',sphere:'мастерские и рабочие',illegal:false,influence:36,relation:10},{id:'watch',name:'Старая городская стража',sphere:'ворота и квартальный порядок',illegal:false,influence:28,relation:0},{id:'smugglers',name:'Речные контрабандисты',sphere:'тайный ввоз и переправы',illegal:true,influence:24,relation:-5},{id:'thieves',name:'Воровская сеть Нижнего города',sphere:'кражи, скупщики и укрытия',illegal:true,influence:18,relation:-15}] };
    if (scenario === 'frontier') { s.player.army = 68; s.player.gold = 95; s.player.defense = 42; }
    if (scenario === 'scarcity') { s.player.food = 36; s.player.gold = 130; s.player.stability = 58; }
    s.military = MILITARY.create(s);
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
    if(d.law&&LAWS.find(law=>law.key===d.law)?.flexible)return '';
    const capacity=(CAPACITY[d.actor]||1)+(d.actor==='builders'?s.player.workshops+Math.max(0,(s.specialists?.builders||1)-1):0);
    if (s.orders.filter(o => definition(o.type).actor === d.actor).length >= capacity) return `${d.executor}: все исполнители заняты (${capacity}). Развивайте ремесленные мастерские, чтобы увеличить число строительных бригад.`;
    return '';
  }
  function commandDetails(s, id) {
    const base = definition(id); if (!base) return null;
    const d = { ...base, requirement: '' };
    if (d.building) {
      const b = BUILDINGS.find(b => b.key === d.building), level = s.player[b.key];
      d.gold = Math.round(base.gold * (1 + level * 0.5)); d.level = level; d.maxLevel = b.max;
      if (trusted(s, 'engineer')) d.gold = Math.floor(d.gold * 0.9);
      if(s.appointments?.works==='toma')d.gold=Math.floor(d.gold*.92);
      if (level >= b.max) d.requirement = 'Достигнут максимальный уровень.';
      else if (s.orders.some(o => o.type === id)) d.requirement = 'Этот объект уже строится.';
      else if (b.requires && Object.entries(b.requires).some(([k, v]) => s.player[k] < v)) d.requirement = 'Нужны 2 школы и наука не ниже 4.';
    }
    if (d.law) {
      if (s.laws[d.law] === d.value) d.requirement = 'Закон уже действует.';
      else if (s.orders.some(o => definition(o.type).law === d.law)) d.requirement = 'Изменение этого закона уже готовится.';
      else if (d.law === 'education' && d.value === 'public' && s.player.schools < 1) d.requirement = 'Сначала постройте земскую школу.';
    }
    if(id.startsWith('tech_')){const tech=id.slice(5);if(s.technologies.includes(tech))d.requirement='Технология уже освоена.';else if(s.player.science<3)d.requirement='Нужна наука не ниже 3.';}
    if(id==='trade_goods'&&s.player.goods<1)d.requirement='Нет товаров для продажи. Нужны ремесленные мастерские.';
    if(id==='crackdown'&&s.player.cityWatch<1)d.requirement='Сначала создайте управление городской стражи.';
    return d;
  }
  function queueOrder(state, id, target = 'val') {
    const blocker = orderBlocker(state, id, target); if (blocker) fail(blocker);
    const s = copy(state), d = commandDetails(s, id);
    s.player.gold -= d.gold; s.ap--;
    const lawDefinition=d.law&&LAWS.find(law=>law.key===d.law);
    if(lawDefinition?.flexible){
      const before=copy(s.player),previous=s.laws[d.law];
      applyFlexibleLaw(s,d.law,d.value,previous);
      log(s,`${d.name}: указ вступил в силу немедленно.`,`Распорядительные правила можно менять без месячного ожидания. ${d.description}`,'law',differences(before,s.player));
      return s;
    }
    s.orders.push({ id: s.nextId++, type: id, target: d.target ? target : null, remaining: d.duration, duration: d.duration, started: s.month, paid: d.gold });
    log(s, `${d.name}${d.target ? ': ' + country(target).name : ''}. Поручение принято.`, `${d.gold ? 'Казна −' + d.gold + '.' : 'Без разовой платы казне.'} Срок: ${d.duration} мес. Исполнитель: ${d.executor}.`, 'order', d.gold ? { gold: -d.gold } : {});
    return s;
  }
  function appointOfficial(state,officeId,candidateId){
    if(state.ended)fail('Правление завершено.');
    const office=OFFICES.find(o=>o.id===officeId),candidate=office?.candidates.find(c=>c.id===candidateId);
    if(!office||!candidate)fail('Неизвестная должность или кандидат.');
    if(state.appointments[officeId]===candidateId)fail('Этот человек уже занимает должность.');
    if(state.ap<1)fail('Для назначения нужно одно государственное поручение.');
    const s=copy(state),previous=office.candidates.find(c=>c.id===s.appointments[officeId]);s.appointments[officeId]=candidateId;s.ap--;
    log(s,`${candidate.name} назначен: ${office.name.toLowerCase()}.`,`Сменён ${previous?.name||'временно исполняющий обязанности'}. Польза: ${candidate.benefit} Компромисс: ${candidate.cost}`,'appointment');
    return s;
  }
  function applyFlexibleLaw(s,key,value,previous=s.laws[key]){
    const defenseBonus={
      conscription:{retinue:0,levy:8,total:20},
      warEconomy:{civilian:0,mixed:5,militarized:14},
      civilDuty:{voluntary:0,organized:4,compulsory:9},
    };
    if(defenseBonus[key])s.player.defense+=defenseBonus[key][value]-defenseBonus[key][previous];
    s.laws[key]=value;
    settle(s);
  }
  function completeOrder(s, o) {
    const p = s.player, n = s.neighbors.find(n => n.id === o.target), d = definition(o.type);
    const before = copy(p);
    let result = '';
    if (d.law) { s.laws[d.law] = d.value;if(d.law==='identity'&&d.value==='register')p.intel++;result = `Закон вступил в силу. ${d.description}${d.law==='identity'&&d.value==='register'?' Реестры дали разведке +1.':''}`; }
    switch (o.type) {
      case 'scout': {
        const risk = clamp(0.18 + n.aggression * 0.001 - p.intel * 0.025-(s.specialists.spies-1)*.02, 0.04, 0.3);
        if (random(s) < risk) { n.relation -= 8; result = 'Агент схвачен. Донесение не доставлено; отношения ухудшились.'; }
        else { issueReport(s, n, 'Тайная канцелярия', clamp(0.61 + p.intel * 0.045, 0.6, 0.93)); result = 'Получено новое донесение. Оценки могут быть ошибочными.'; }
        break;
      }
      case 'envoy':
        if (random(s) < clamp(0.53 + p.diplomacy * 0.06 + n.relation / 400 + (trusted(s, 'envoy') ? 0.1 : 0)+(s.specialists.diplomats-1)*.03, 0.2, 0.95)) {
          n.relation += 18; result = 'Посольство снизило недоверие.';
          if (n.relation > 10 && n.pactUntil <= s.month) { n.pactUntil = s.month + 6; p.trade++; result += ' На 6 месяцев открыт торговый договор: доход +3/мес.'; }
        } else { n.relation -= 5; result = 'Условия отвергнуты. Недоверие выросло; потраченные средства не возвращены.'; }
        break;
      case 'patrol': p.defense += 7; s.neighbors.forEach(n => { n.relation -= 3; }); result = 'Оборона +7. Соседи насторожились из-за усиления застав.'; break;
      case 'train': p.army += s.appointments.army==='ratmir'?13:10; result = s.appointments.army==='ratmir'?'Реформа Ратмира ускорила обучение: армия +13.':'Армия +10. Проверьте растущие расходы на содержание.'; break;
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
      case 'houses': p.houses++;p.stability+=2;result='Жилой квартал заселён. Вместимость города и стабильность выросли.';break;
      case 'smithy': p.smithies++;p.defense+=2;result='Кузница начала работу. Оборона +2; железо можно превращать в товары.';break;
      case 'lumberyard': p.lumberyards++;result='Лесной двор открыт. Древесина поступает каждый месяц.';break;
      case 'quarry': p.quarries++;result='Каменоломня открыта. Камень поступает каждый месяц.';break;
      case 'mine': p.mines++;p.health-=1;result='Рудник открыт. Железо поступает каждый месяц; тяжёлая работа требует надзора.';break;
      case 'workshop': p.workshops++;result='Мастерские открыты. Производятся товары; доступна дополнительная строительная бригада.';break;
      case 'market': p.markets++;result='Торговые ряды открыты. Доход +3/мес. и выше ценность товаров.';break;
      case 'firewatch': p.fireStations++;result='Пожарная стража создана. Пожары наносят меньше ущерба.';break;
      case 'sanitation': p.sanitation++;p.health+=3;result='Очистная служба работает. Здоровье +3 сейчас и +1/мес.';break;
      case 'court': p.courts++;p.stability+=3;result='Городской суд открыт. Стабильность +3; злоупотребления разбираются быстрее.';break;
      case 'post': p.postOffices++;p.diplomacy++;p.intel++;result='Почтовая служба открыта. Дипломатия и разведка +1.';break;
      case 'barracks': p.barracks++;p.defense+=4;result='Казармы и арсенал готовы. Оборона +4.';break;
      case 'citywatch':p.cityWatch++;p.stability+=2;result='Управление стражи открыто. Патрули и следователи начали постоянную службу.';break;
      case 'prison':p.prisons++;result='Городская тюрьма открыта. Заключение теперь возможно без импровизированных подвалов.';break;
      case 'trade_goods':{const amount=Math.min(10,p.goods),relationFactor=1+n.relation/200,terms=s.tradeTerms[n.id]||0,price=Math.max(1,Math.round((2+p.markets+terms)*relationFactor));p.goods-=amount;p.gold+=amount*price;n.gold=Math.max(0,n.gold-amount*price);result=`Продано ${amount} товаров по ${price} монет. Отношение партнёра и уровень рынков определили цену.`;break;}
      case 'intimidate':{const advantage=p.army-(n.army+n.defense*.3),success=advantage>15&&random(s)<clamp(.45+advantage/180+p.diplomacy*.02,0.2,.9);if(success){s.tradeTerms[n.id]=2;n.relation-=8;result='Сосед уступил под военным давлением: следующие сделки получают выгодную цену, но доверие снизилось.';}else{n.relation-=18;n.aggression=clamp(n.aggression+8,0,100);result='Ультиматум отвергнут. Отношения ухудшились, сосед усилил военную настороженность.';}break;}
      case 'sabotage':{const chance=clamp(.28+p.intel*.055+s.specialists.spies*.06-n.defense*.002,0.15,.86);if(random(s)<chance){const damage=5+p.intel;n.defense=Math.max(0,n.defense-damage);n.gold=Math.max(0,n.gold-8);result=`Диверсия удалась: оборона соседа ослаблена на ${damage}, часть снабжения потеряна.`;}else{n.relation-=22;n.aggression=clamp(n.aggression+12,0,100);result='Исполнителей раскрыли. Сосед обвиняет Арден и готовит ответные меры.';}break;}
      case 'bribe_source':{issueReport(s,n,'Подкупленный чиновник',clamp(.72+p.intel*.035+s.specialists.spies*.03,.72,.96));result='Источник передал свежее донесение. Оно точнее обычных слухов, но всё ещё не является полной истиной.';break;}
      case 'recruit_expert':{const success=random(s)<clamp(.3+p.science*.04+p.diplomacy*.035+n.relation/500,.15,.88);if(success){const types=['builders','physicians','spies','diplomats','engineers'],type=types[Math.floor(random(s)*types.length)];s.specialists[type]=Math.min(5,s.specialists[type]+1);n.relation-=5;result=`В Арден переехал опытный специалист: ${({builders:'мастер-строитель',physicians:'лекарь',spies:'разведчик',diplomats:'дипломат',engineers:'инженер'})[type]}. Уровень этой службы вырос.`;}else{n.relation-=3;result='Специалист отказался покидать родину. Соседний двор заметил попытку переманивания.';}break;}
      case 'tech_agriculture':s.technologies.push('agriculture');result='Освоен севооборот: поля дают больше зерна каждый месяц.';break;
      case 'tech_engineering':s.technologies.push('engineering');p.defense+=3;result='Освоено каменное строительство: оборона +3, аварии дорог и зданий менее разрушительны.';break;
      case 'tech_medicine':s.technologies.push('medicine');p.health+=4;result='Развито врачебное дело: здоровье +4, лечебницы работают эффективнее.';break;
      case 'tech_military':s.technologies.push('military');p.defense+=2;for(const u of s.military.units)u.experience=clamp(u.experience+8,0,100);result='Принят полевой устав: опыт всех отрядов +8, оборона +2.';break;
      case 'crackdown':{const group=[...s.factions].filter(f=>f.illegal).sort((a,b)=>b.influence-a.influence)[0],strength=p.cityWatch*8+p.courts*4+s.specialists.spies*3+(s.appointments.justice==='grom'?8:0),success=random(s)<clamp(.42+strength/100,.35,.92);if(success){const drop=Math.min(group.influence,10+strength);group.influence-=drop;group.relation-=15;p.stability+=1;result=`Операция против «${group.name}» снизила влияние группировки на ${drop}. Изъятые записи переданы суду.`;}else{group.influence=Math.min(100,group.influence+6);p.stability-=4;result=`Операция против «${group.name}» провалилась: утечка сведений помогла главарям скрыться, жители жалуются на обыски.`;}break;}
      case 'informants':{const group=s.factions.find(f=>f.id==='thieves');group.relation+=8;s.specialists.spies=Math.min(5,s.specialists.spies+1);p.intel++;result='В подполье появились осведомители. Разведка и уровень тайной службы выросли, но связь с преступной средой придётся скрывать.';break;}
      case 'underworld_deal':{const group=s.factions.find(f=>f.id==='smugglers');group.influence=Math.min(100,group.influence+8);group.relation+=12;p.goods+=12;p.gold+=8;p.stability-=2;result='Контрабандисты доставили товары в обход пошлин. Казна и склады выиграли, но подполье стало сильнее.';break;}
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
    const playerBelief = n.beliefs.player;
    if (n.aggression > 60 && n.turns >= 3 && n.relation <= 30 && n.pactUntil <= n.turns && playerBelief.army < n.army * 0.5 && playerBelief.defense < n.army * 0.8 && n.gold >= 12) return { action: 'raid', target: 'player', reason: 'Правитель видит слабую защиту соседа по собственным сведениям и считает давление выгодным.' };
    const targets = Object.entries(n.beliefs).map(([id, belief]) => ({ id, belief, relation: id === 'player' ? n.relation : n.relations[id] }));
    targets.sort((a, b) => (a.relation + a.belief.army * 0.3) - (b.relation + b.belief.army * 0.3));
    const weakest = targets[0];
    if (weakest && n.aggression > 45 && weakest.relation < -32 && n.army > weakest.belief.army * 0.85 + weakest.belief.defense * 0.3 && n.gold >= 12) {
      return { action: 'raid', target: weakest.id, reason: 'Враждебные отношения и предполагаемое военное превосходство.' };
    }
    if (n.id === 'mer' && n.gold < 180) return { action: 'trade', target: null, reason: 'Торговая республика наращивает прибыль.' };
    if (n.relation < -30 && n.defense < 65 && n.gold >= 12) return { action: 'fortify', target: null, reason: 'Недоверие к Ардену требует укрепления рубежей.' };
    const desiredArmy = Math.min(600, (n.id === 'nor' ? 100 : 75) + Math.round(playerBelief.army * 0.55));
    if (n.army < desiredArmy && n.gold >= 16) return { action: 'train', target: null, reason: 'Правитель восстанавливает желаемую численность войск.' };
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
          if (decision.target === 'player') {
            n.relation -= 8;
            logMilitary(s, MILITARY.scheduleEnemyRaid(s, n.id, n.army, () => random(s)));
            break;
          }
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
  function shuffledIds(s, ids) {
    const result = [...ids];
    for (let i = result.length - 1; i > 0; i--) { const j = Math.floor(random(s) * (i + 1)); [result[i], result[j]] = [result[j], result[i]]; }
    return result;
  }
  function setCouncilChoiceOrder(s) {
    if (s.pending && !Object.hasOwn(s.pending, 'choiceOrder')) s.pending.choiceOrder = shuffledIds(s, rawEventView(s).choices.map(c => c.id));
  }
  function refreshEvent(s) {
    if (s.ended || s.pending) return;
    const due = s.chains.filter(c => c.due <= s.month).sort((a, b) => a.due - b.due)[0];
    if (due) { s.pending = { kind: due.type + '_followup', target: due.target, approach: due.approach, origin: due.origin, secret: due.secret, created: s.month }; s.chains.splice(s.chains.indexOf(due), 1); setCouncilChoiceOrder(s); return; }
    if (s.player.food < 60 && s.cooldowns.grain <= s.month && !s.chains.some(c => c.type === 'grain')) {
      s.pending = { kind: 'grain', target: null, created: s.month }; setCouncilChoiceOrder(s); return;
    }
    const anxious = s.neighbors.filter(n => n.relation < -20).sort((a, b) => a.relation - b.relation)[0];
    if (anxious && s.cooldowns.border <= s.month && !s.chains.some(c => c.type === 'border')) {
      s.pending = { kind: 'border', target: anxious.id, secret: random(s) < 0.5 ? 'bandits' : 'soldiers', created: s.month }; setCouncilChoiceOrder(s);
    }
  }
  function rawEventView(s) {
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
  function eventView(s) {
    const view = rawEventView(s); if (!view) return null;
    if (s.pending.choiceOrder) view.choices = s.pending.choiceOrder.map(id => view.choices.find(c => c.id === id));
    return view;
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
    if (MILITARY.hasBattle(state)) fail('Сначала завершите столкновение на карте войска.');
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
    log(s, `Месячный баланс: казна ${signed(p.gold - beforeEconomy.gold)}, зерно ${signed(p.food - beforeEconomy.food)}.`, `Налоги и торговля +${flow.income}, содержание −${flow.upkeep}; урожай +${flow.production}, еда жителей и армии −${flow.consumption}, вывоз −${flow.exports}, потери хранения −${flow.losses}. Завершённые приказы уже учтены.`, 'economy', differences(beforeEconomy, p));
    const beforeIndustry=copy(p);
    p.wood+=p.lumberyards*4;p.stone+=p.quarries*3;p.iron+=p.mines*2;
    const ironUsed=Math.min(p.iron,p.smithies),woodUsed=Math.min(p.wood,p.workshops);p.iron-=ironUsed;p.wood-=woodUsed;
    const goodsRate=s.laws.warEconomy==='militarized'?0:s.laws.warEconomy==='mixed'?1:3;
    const laborBonus=s.laws.workday==='long'?p.workshops:s.laws.workday==='short'?-Math.min(p.workshops,1):0;
    p.goods+=Math.max(0,p.workshops*goodsRate+ironUsed+laborBonus+(s.appointments.works==='kord'&&p.workshops?1:0));
    settle(s);const industryChanges=differences(beforeIndustry,p);
    if(Object.keys(industryChanges).length)log(s,'Мастерские и добывающие дворы завершили месячную работу.',`Лесные дворы дали ${p.lumberyards*4} древесины, каменоломни ${p.quarries*3} камня, рудники ${p.mines*2} железа. Кузницы и мастерские переработали доступное сырьё.`,'industry',industryChanges);
    const beforeLiving = copy(p), societyPolicy = LAW_DATA.monthlyEffects(s);
    if (unpaid) { p.stability -= 7; log(s, 'Казна не покрыла жалование. Недовольство гарнизона растёт.', 'Недостаток средств: стабильность −7.', 'danger'); }
    if (p.food < 15) { p.stability -= 9; p.army -= Math.min(p.army, 3); p.population -= 1; p.health -= 5; log(s, 'Нехватка зерна ударила по деревням и войскам.', 'Запас ниже 15: стабильность −9, армия −3, население −1 тыс., здоровье −5.', 'danger'); }
    else if (p.food > 45 && p.stability < 85) p.stability += 1;
    p.stability += ({ low: 2, balanced: 0, high: -3 })[s.laws.tax] + (s.laws.education === 'public' ? 1 : 0) + (trusted(s, 'governor') ? 1 : 0) + societyPolicy.stability;
    if(s.appointments.justice==='vera'&&s.laws.justice==='open')p.stability++;
    if(s.appointments.justice==='grom'&&s.laws.punishment==='harsh')p.stability--;
    if(s.appointments.army==='yaropolk'&&s.laws.conscription==='levy')p.stability++;
    p.health += p.wells + p.clinics * (2+(s.technologies.includes('medicine')?1:0)) + p.sanitation + (trusted(s, 'doctor') ? 1 : 0) + Math.max(0,s.specialists.physicians-1) + societyPolicy.health;
    if(s.appointments.works==='elena'&&s.laws.civilDuty==='organized')p.health++;
    const housing=85+p.houses*20;
    if(p.population>housing){p.population--;p.stability-=3;log(s,'Семьи покидают переполненный Арден. Жильё и работа не успевают за населением.',`Вместимость жилья ${housing} тыс., население ${p.population+1} тыс.: эмиграция −1 тыс., стабильность −3.`,'migration',{});}
    else if(p.stability<35&&s.month%2===0){p.population--;log(s,'Несколько семей уехали из княжества, опасаясь беспорядков и произвола.','Низкая стабильность вызвала эмиграцию −1 тыс. жителей.','migration',{});}
    if (s.month % 3 === 0 && p.health >= 70 && p.food > 30 && p.stability > 50) p.population++;
    if (s.laws.education === 'public' && p.schools > 0 && s.month % 6 === 0) p.science+=s.laws.workingAge==='protected'?2:s.laws.workingAge==='early'?0:1;
    settle(s);
    const livingChanges = differences(beforeLiving, p);
    if (Object.keys(livingChanges).length) log(s, 'Жизнь княжества: жители, законы и городские службы.', 'Учтены питание, налоговый закон, образование, водопровод и лечебницы. Здоровое население при достатке растёт раз в квартал.', 'society', livingChanges);
    runEpidemic(s);
    if (s.month >= s.nextCrisis) runDomesticCrisis(s);
    runCityInfluence(s);
    // Нельзя грабить уже отрицательные запасы: сначала нормализуем расчёт экономики.
    settle(s);
    if (!s.ended) { runNeighbors(s); logMilitary(s, MILITARY.advance(s, () => random(s))); }
    s.ap = 2;
    if (s.month % 12 === 0 && !s.ended) log(s, `Завершён ${s.month / 12}-й год правления. Кампания продолжается.`, 'Соседи, стройки и нерешённые дела переходят в следующий год.', 'milestone');
    settle(s); refreshEvent(s); advanceRuler(s); s.attention = isRulerIll(s) ? 0 : 2; refreshEncounters(s);
    s.lastTurn = { month: s.month, before: copy(state.monthStart), after: copy(s.player), changes: differences(state.monthStart, s.player), entries: copy(s.history.filter(h => h.id >= state.monthStartId).reverse()) };
    s.metrics.push({ month: s.month, values: copy(s.player) }); s.metrics = s.metrics.slice(-121);
    s.monthStart = copy(s.player); s.monthStartId = s.nextId;
    if ((s.month % 12 === 0 && !MILITARY.hasBattle(s)) || s.ended) s.chapter = makeChapter(s);
    return s;
  }
  function runDomesticCrisis(s) {
    const p=s.player,roll=Math.floor(random(s)*5),before=copy(p);let text,reason;
    if(roll===0){const protectedFood=p.granaries*12,loss=Math.min(p.food,Math.max(2,12-protectedFood));p.food-=loss;text=loss>2?'Крысы добрались до старых амбаров. Часть зимнего зерна испорчена.':'На амбарном дворе нашли крысиные ходы, но исправные зернохранилища спасли почти весь запас.';reason=`Потеряно ${loss} зерна. Каждый уровень зернохранилищ уменьшает ущерб.`;}
    else if(roll===1){const guarded=p.wells+p.fireStations+p.sanitation+(s.laws.civilDuty==='organized'?1:s.laws.civilDuty==='compulsory'?2:0),loss=Math.max(1,7-guarded*2);p.health-=loss;p.stability-=Math.max(0,3-guarded);text=guarded?'Пожар в нижнем городе потушили водовозы и пожарная стража. Несколько дворов всё же пострадали.':'В нижнем городе разошёлся пожар. Без воды и городской службы огонь перескакивал с крыши на крышу.';reason=`Здоровье −${loss}. Колодцы, пожарная стража и организованные команды жителей снижают последствия.`;}
    else if(roll===2){const protectedRoad=p.roads>0,loss=protectedRoad?2:9;p.gold-=Math.min(p.gold,loss);p.food-=Math.min(p.food,protectedRoad?1:6);p.stability-=protectedRoad?0:3;text=protectedRoad?'Весенний паводок повредил настил у переправы, но каменные работы удержали дорогу.':'Паводок размыл старый мост и отрезал деревни от рынка. Обозы встали, жители требуют ремонта.';reason=protectedRoad?'Дороги и мосты ограничили ущерб.':'Без действующих дорог потеряны монеты и провиант, стабильность снизилась.';}
    else if(roll===3){const upkeep=p.defense>=40,loss=upkeep?3:10;p.gold-=Math.min(p.gold,loss);p.defense-=upkeep?0:2;text=upkeep?'После ливня кровельщики быстро закрыли течь в арсенале. Ремонт оказался небольшим.':'Крыша арсенала протекла: тетивы и часть доспехов пришлось срочно спасать и чинить.';reason=upkeep?'Укреплённый замок снизил цену ремонта.':'Слабое содержание замка стоило казне и двум пунктам обороны.';}
    else{if(!s.epidemic){const names=['Красная горячка','Речная лихорадка','Сухой кашель'];s.epidemic={name:names[Math.floor(random(s)*names.length)],remaining:3,severity:2+Math.floor(random(s)*2)};text=`В нижнем городе выявлена болезнь: ${s.epidemic.name}. Лекари требуют наблюдения и готовят изоляторы.`;reason='Эпидемия продлится несколько месяцев. Лечебницы, санитария, врачи и выбранный глава службы определят потери.';}else{text='Лекари усилили надзор за уже идущей эпидемией.';reason='Новая болезнь не началась, пока продолжается прежняя.';}}
    settle(s);log(s,text,reason,'crisis',differences(before,p));s.nextCrisis=s.month+2+Math.floor(random(s)*3);
  }
  function runEpidemic(s){
    if(!s.epidemic)return;
    const p=s.player,e=s.epidemic,before=copy(p),head=s.appointments.medicine;
    const protection=p.clinics*2+p.sanitation+p.wells+Math.max(0,s.specialists.physicians-1)+(s.technologies.includes('medicine')?2:0);
    const healthLoss=Math.max(1,e.severity*4-protection-(head==='lada'?2:0));
    const populationLoss=Math.max(0,e.severity-1-Math.floor(protection/4)-(head==='agafya'?1:0));
    p.health-=healthLoss;p.population-=populationLoss;p.stability-=head==='agafya'?1:Math.max(0,e.severity-2);
    e.remaining-=head==='severin'&&e.remaining>1?2:1;
    settle(s);log(s,`${e.name}: месяц эпидемии. Лекари обходят дома, службы изолируют очаги.`,`Здоровье −${healthLoss}${populationLoss?`, население −${populationLoss} тыс.`:''}. Защита служб: ${protection}. Решение главы врачебной службы учтено.`,'epidemic',differences(before,p));
    if(e.remaining<=0){log(s,`${e.name} отступила. Ограничения снимают, лечебницы возвращаются к обычной работе.`,'Продолжительность и потери зависели от городской медицины, санитарии и руководителя службы.','epidemic');s.epidemic=null;}
  }
  function runCityInfluence(s){
    const p=s.player,thieves=s.factions.find(f=>f.id==='thieves'),smugglers=s.factions.find(f=>f.id==='smugglers');
    const control=p.cityWatch*7+p.courts*4+p.prisons*3+(s.laws.identity==='register'?7:0)+(s.laws.policing==='professional'?8:0)+(s.laws.punishment==='harsh'?5:s.laws.punishment==='imprisonment'?3:0);
    thieves.influence=clamp(thieves.influence+(control<20?2:-1),0,100);smugglers.influence=clamp(smugglers.influence+(p.markets>1&&s.laws.grain==='reserve'?2:0)-(control>35?1:0),0,100);
    if(random(s)<clamp((thieves.influence+smugglers.influence-control)/180,.03,.38)){
      const before=copy(p),loss=Math.min(p.gold,3+Math.floor(thieves.influence/8));p.gold-=loss;const goods=Math.min(p.goods,Math.floor(smugglers.influence/15));p.goods-=goods;p.stability-=s.laws.punishment==='harsh'?1:2;settle(s);
      log(s,'Ночью ограбили склады у речного рынка. Скупщики успели спрятать часть добычи.','Влияние подполья превысило возможности стражи. Документы, профессиональные патрули, суд и тюрьма снижают риск.','crime',differences(before,p));
    }
  }
  function logMilitary(s, entries) {
    for (const e of entries) log(s, e.text, e.reason || '', e.kind || 'military', copy(e.changes || {}));
  }
  function militaryQuote(state, options) {
    const q = MILITARY.quote(state, options);
    const reason = state.ended ? 'Правление завершено.' : MILITARY.hasBattle(state) ? 'Сначала завершите сражение.' : state.ap < 1 ? 'Нужен один свободный государственный приказ.' : state.player.food < q.food ? `Для обоза нужно ${q.food} зерна.` : '';
    return { ...q, canLaunch: !reason, reason };
  }
  function launchMilitary(state, options) {
    if (state.ended) fail('Правление завершено.');
    if (state.ap < 1) fail('Для похода нужен один свободный государственный приказ.');
    const s = copy(state);
    const entries = MILITARY.launch(s, options); s.ap--;
    logMilitary(s, entries); return settle(s);
  }
  function battleOrder(state, tactic) {
    if (state.ended) fail('Правление завершено.');
    const s = copy(state); logMilitary(s, MILITARY.issueBattleOrder(s, tactic, () => random(s))); settle(s);
    if (s.ended || (s.month > 0 && s.month % 12 === 0 && !MILITARY.hasBattle(s) && (!s.chapter || s.chapter.month !== s.month))) s.chapter = makeChapter(s);
    return s;
  }
  function makeChapter(s) {
    const p = s.player, buildings = BUILDINGS.reduce((sum, b) => sum + p[b.key], 0), hostile = s.neighbors.filter(n => n.relation < -35).length;
    const title = s.ended ? 'Печать снята с вашей руки' : p.stability < 35 ? 'Трон пошатнулся, но устоял' : hostile >= 2 ? 'Мир на острие меча' : buildings >= 4 ? 'Княжество обрело опору' : 'Первый рубеж пройден';
    const story = s.ended ? 'Совет отстранил вас от власти. Цепь решений закончилась потерей устойчивости: одних обещаний оказалось недостаточно.' : `Летописец завершает ${Math.floor(s.month / 12)}-й год. ${buildings >= 4 ? 'Ваши вложения изменили повседневную жизнь княжества.' : 'Правление сохранилось, но основы будущего ещё предстоит построить.'} ${p.food < 30 ? 'Пустеющие амбары остаются главным вопросом следующего года.' : 'В амбарах есть зерно, и у жителей остаётся надежда.'} ${hostile >= 2 ? 'Военные подозрения соседей не исчезли — следующий год обещает быть тревожным.' : 'Дипломатия оставила пространство для мирного продолжения истории.'}`;
    return { year: Math.max(1, Math.ceil(s.month / 12)), month: s.month, title, story, buildings, hostile, acknowledged: false, final: s.ended, values: copy(p), initial: copy(s.initial) };
  }
  function acknowledgeChapter(state) { const s = copy(state); if (s.chapter) s.chapter.acknowledged = true; return s; }
  function newEncounter(s, template, origin = null) {
    const t = STORIES.find(t => t.id === template);
    return { id: s.nextId++, template, created: s.month, resolved: false, origin, choiceOrder: shuffledIds(s, t.choices.map(c => c.id)) };
  }
  function storyConditionsMet(s, t) {
    const c = t.conditions || {};
    return (c.minMonth === undefined || s.month >= c.minMonth)
      && (c.minBuildings === undefined || BUILDINGS.reduce((sum, b) => sum + s.player[b.key], 0) >= c.minBuildings)
      && (c.minGold === undefined || s.player.gold >= c.minGold)
      && (c.minFood === undefined || s.player.food >= c.minFood)
      && (c.minScience === undefined || s.player.science >= c.minScience)
      && (c.maxStability === undefined || s.player.stability <= c.maxStability)
      && (c.minBandits === undefined || Math.max(0, ...(s.military?.locations || []).map(p => p.bandits)) >= c.minBandits);
  }
  function refreshEncounters(s) {
    if (s.ended) { s.encounters = []; return; }
    const retained=[];
    for(const e of s.encounters){
      if(e.resolved)continue;
      const age=s.month-e.created;
      if(age>=3){const t=STORIES.find(t=>t.id===e.template),before=copy(s.player);s.player.stability-=2;if(t.person==='governor'||t.person==='elder')s.player.food-=Math.min(s.player.food,4);else if(t.person==='marshal'||t.person==='captain')s.player.defense-=1;else s.player.gold-=Math.min(s.player.gold,3);const trust=s.characters.find(p=>p.id===t.person);if(trust)trust.trust=clamp(trust.trust-4,0,100);settle(s);log(s,`Просьба «${t.title}» осталась без ответа. ${t.person==='governor'||t.person==='elder'?'Жители решили, что двор их не слышит.':t.person==='marshal'||t.person==='captain'?'Служба на этом участке пришла в упадок.':'Проситель перестал ждать решения двора.'}`,'Три месяца без ответа: доверие просителя −4, стабильность −2 и предметные потери.','neglect',differences(before,s.player));}
      else retained.push(e);
    }
    const limit=s.month===0?3:5,dueReady=s.futureStories.filter(f=>f.due<=s.month).slice(0,2);
    s.encounters=retained.slice(-Math.max(0,limit-dueReady.length));
    const slots=Math.max(0,limit-s.encounters.length);
    const due = dueReady.slice(0,slots);
    for (const f of due) { s.encounters.push(newEncounter(s, f.template, f.origin)); s.futureStories.splice(s.futureStories.indexOf(f), 1); }
    const candidates = STORIES.filter(t => !t.followup && storyConditionsMet(s, t) && (s.storyMemory[t.id] === undefined || s.month - s.storyMemory[t.id] >= (t.cooldown || 6)) && (!t.when || (t.when.below !== undefined ? s.player[t.when.metric] < t.when.below : s.player[t.when.metric] > t.when.above)))
      .map(t => ({ t, score: random(s) + (s.storyMemory[t.id] === undefined ? 2 : 0) + (t.when ? 0.3 : 0) })).sort((a, b) => b.score - a.score);
    for (const { t } of candidates.slice(0, Math.max(0,limit-s.encounters.length))) { s.storyMemory[t.id] = s.month; s.encounters.push(newEncounter(s, t.id)); }
  }
  function storyView(s, encounter) {
    const t = STORIES.find(t => t.id === encounter.template), person = PEOPLE.find(p => p.id === t.person), trust = s.characters.find(p => p.id === t.person).trust;
    const view = { id: encounter.id, type: t.type, title: t.title, request: t.request, text: t.text, quote: t.quote, place: t.place, person: { ...copy(person), trust }, date: date(encounter.created), waitingMonths: Math.max(0,s.month-encounter.created), urgency: !encounter.resolved && s.month-encounter.created>=2 ? 'Последний месяц до последствий' : !encounter.resolved && s.month-encounter.created>=1 ? 'Ожидает ответа второй месяц' : null, resolved: encounter.resolved, choice: encounter.choice || null, origin: encounter.origin,
      choices: (encounter.choiceOrder ? encounter.choiceOrder.map(id => t.choices.find(c => c.id === id)) : t.choices).map(c => ({ id: c.id, title: c.title, description: c.description, gold: c.gold, food: c.food,
        disabled: encounter.resolved || s.ended || isRulerIll(s) || s.attention < 1 || s.player.gold < c.gold || s.player.food < c.food || (c.future && s.futureStories.length >= 8) })) };
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
    if (isRulerIll(state)) fail('Правитель болен и пока не может принимать личные встречи. Совет продолжает обычную работу.');
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
  function talkToCharacter(state, personId, topicId) {
    const person = PEOPLE.find(p => p.id === personId), topic = TALKS[personId]?.find(t => t.id === topicId);
    if (!person || !topic) fail('Неизвестный собеседник или тема разговора.');
    if ((state.conversations || []).some(c => c.personId === personId && c.topicId === topicId)) return copy(state);
    if (state.ended) fail('Правление завершено. Ранее записанные разговоры доступны в досье.');
    if (isRulerIll(state)) fail('Правителю нужен отдых: новые разговоры недоступны до выздоровления.');
    const s = copy(state);
    if (!s.conversations) s.conversations = [];
    s.conversations.push({ personId, topicId, response: topic.response, month: s.month });
    log(s, `Разговор с ${person.name}: ${topic.title}`, topic.response, 'conversation');
    return s;
  }
  function conversationTopics(s, personId) {
    return (TALKS[personId] || []).map(topic => {
      const known = (s.conversations || []).find(c => c.personId === personId && c.topicId === topic.id);
      return { id: topic.id, title: topic.title, asked: Boolean(known), disabled: (s.ended || isRulerIll(s)) && !known, ...(known ? { response: known.response, month: known.month, date: date(known.month) } : {}) };
    });
  }
  function characterView(s, p) {
    const bonus = { treasurer: 'доход +2/мес.', marshal: 'содержание армии −1/мес.', doctor: 'здоровье +1/мес.', engineer: 'строительство дешевле на 10%.', envoy: 'шанс успеха посольства +10 п. п.', governor: 'стабильность +1/мес.' }[p.id];
    return { ...copy(PEOPLE.find(t => t.id === p.id)), trust: p.trust,
      bonus: bonus ? `${p.trust >= 75 ? 'Действует' : 'При доверии 75+'}: ${bonus}` : 'Делится опытом и местными сведениями; отдельного административного бонуса нет.',
      topics: conversationTopics(s, p.id) };
  }
  function getView(s) {
    return { version: VERSION, seed: s.seed, scenario: s.scenario, month: s.month, date: date(s.month), yearOfRule: Math.floor(s.month / 12) + 1,
      player: copy(s.player), economy: economy(s), ap: s.ap, ended: s.ended, event: eventView(s), orders: copy(s.orders), completed: copy(s.completed), history: copy(s.history),
      neighbors: COUNTRIES.map(c => { const n = s.neighbors.find(n => n.id === c.id); return { id: c.id, name: c.name, ruler: c.ruler, trait: c.trait, goal: c.goal,
        relations: relationLabel(n.relation),
        pactRemaining: Math.max(0, n.pactUntil - s.month), reports: s.reports.filter(r => r.target === c.id).slice(0, 3).map(r => ({ ...copy(r), age: s.month - r.observed, effectiveConfidence: Math.max(15, r.confidence - (s.month - r.observed) * 6), date: date(r.observed), intentLabel: INTENTS[r.intent] })) }; }),
      commands:COMMANDS.map(d=>commandDetails(s,d.id)),buildings:copy(BUILDINGS),lawOptions:copy(LAWS),laws:copy(s.laws),technologies:copy(s.technologies),specialists:copy(s.specialists),tradeTerms:copy(s.tradeTerms),factions:copy(s.factions),offices:OFFICES.map(o=>({...copy(o),appointed:s.appointments[o.id]})),epidemic:copy(s.epidemic),metrics:copy(s.metrics),lastTurn:copy(s.lastTurn),chapter:copy(s.chapter),
      military: MILITARY.view(s), ruler: rulerView(s), attention: s.attention, characters: s.characters.map(p => characterView(s, p)), encounters: s.encounters.map(e => storyView(s, e)), futureStories: s.futureStories.map(f => ({ title: `Ожидаются вести: ${STORIES.find(t => t.id === f.template).person === 'governor' ? 'западные деревни' : STORIES.find(t => t.id === f.template).person === 'marshal' ? 'пограничная застава' : 'порученная проверка'}`, dueIn: Math.max(0, f.due - s.month) })),
      conversationNotes: (s.conversations || []).map(c => ({ ...copy(c), name: PEOPLE.find(p => p.id === c.personId).name, title: TALKS[c.personId].find(t => t.id === c.topicId).title, date: date(c.month) })),
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
    check(list(s.technologies,4)&&new Set(s.technologies).size===s.technologies.length&&s.technologies.every(t=>['agriculture','engineering','medicine','military'].includes(t)),'технологии');
    check(isObject(s.specialists)&&['builders','physicians','spies','diplomats','engineers'].every(k=>number(s.specialists[k],1,5)),'специалисты');
    check(isObject(s.tradeTerms)&&Object.entries(s.tradeTerms).every(([k,v])=>country(k)&&number(v,0,3)),'торговые условия');
    check(isObject(s.appointments)&&OFFICES.every(o=>o.candidates.some(c=>c.id===s.appointments[o.id])),'государственные назначения');
    check(s.epidemic===null||(isObject(s.epidemic)&&text(s.epidemic.name,80)&&number(s.epidemic.remaining,1,3)&&number(s.epidemic.severity,1,4)),'эпидемия');
    check(list(s.factions,5)&&s.factions.length===5&&new Set(s.factions.map(f=>f.id)).size===5&&s.factions.every(f=>isObject(f)&&text(f.name,100)&&text(f.sphere,100)&&typeof f.illegal==='boolean'&&number(f.influence,0,100)&&number(f.relation,-100,100)),'городские группы влияния');
    for (const key of ['gold','food','wood','stone','iron','goods','army']) check(number(s.player[key]), key);
    for (const key of ['stability', 'population', 'defense', 'health']) check(number(s.player[key], 0, { stability: 100, population: 500, defense: 200, health: 100 }[key]), key);
    for (const key of ['farms','roads','trade','science','intel','diplomacy','orchards','wells','granaries','schools','clinics','universities','houses','smithies','lumberyards','quarries','mines','workshops','markets','fireStations','sanitation','courts','postOffices','barracks','cityWatch','prisons']) check(number(s.player[key],0,20),key);
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
    for (const [actor, baseCapacity] of Object.entries(CAPACITY)) {const capacity=baseCapacity+(actor==='builders'?s.player.workshops:0);check(s.orders.filter(o=>definition(o.type).actor===actor).length<=capacity,'исполнители');}
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
      if (Object.hasOwn(e, 'choiceOrder')) { const ids = rawEventView(s).choices.map(c => c.id); check(list(e.choiceOrder, ids.length) && e.choiceOrder.length === ids.length && new Set(e.choiceOrder).size === ids.length && e.choiceOrder.every(id => ids.includes(id)), 'порядок решений совета'); }
      if (e.kind.endsWith('_followup')) check(validApproach(e.kind.split('_')[0], e.approach) && number(e.origin, 0, s.month), 'продолжение события');
    }
    check(LAW_DATA.validate(s.laws), 'законы');
    check(MILITARY.validate(s.military, s), 'войска, походы и сражения');
    const validSnapshot = p => isObject(p) && Object.keys(METRICS).every(k => number(p[k])) && number(p.stability, 0, 100) && number(p.health, 0, 100) && number(p.rationUntil, 0, 1000010);
    check(validSnapshot(s.initial) && validSnapshot(s.monthStart) && number(s.monthStartId, 1, s.nextId) && number(s.nextCrisis, s.month, 1000010), 'начало правления, месяца и следующий хозяйственный риск');
    check(list(s.metrics, 121) && s.metrics.length > 0 && s.metrics.every((m, i) => isObject(m) && number(m.month, 0, s.month) && validSnapshot(m.values) && (i === 0 || m.month === s.metrics[i - 1].month + 1)) && s.metrics.at(-1).month === s.month, 'история показателей');
    if (s.lastTurn !== null) check(isObject(s.lastTurn) && s.lastTurn.month === s.month && validSnapshot(s.lastTurn.before) && validSnapshot(s.lastTurn.after) && validChanges(s.lastTurn.changes) && list(s.lastTurn.entries, 100) && s.lastTurn.entries.every(validEntry), 'отчёт за месяц');
    if (s.chapter !== null) check(isObject(s.chapter) && number(s.chapter.year, 1, 1000000) && number(s.chapter.month, 0, s.month) && text(s.chapter.title) && text(s.chapter.story) && number(s.chapter.buildings) && number(s.chapter.hostile, 0, 3) && typeof s.chapter.acknowledged === 'boolean' && typeof s.chapter.final === 'boolean' && validSnapshot(s.chapter.values) && validSnapshot(s.chapter.initial), 'итог главы');
    check(number(s.attention, 0, 12) && list(s.characters, PEOPLE.length) && s.characters.length === PEOPLE.length && new Set(s.characters.map(p => p?.id)).size === PEOPLE.length && s.characters.every(p => PEOPLE.some(t => t.id === p?.id) && number(p.trust, 0, 100)), 'персонажи и личное внимание');
    check(isObject(s.ruler) && number(s.ruler.fatigue, 0, 100) && number(s.ruler.health, 0, 100) && number(s.ruler.illUntil, 0, 1000010) && number(s.ruler.overtimeThisMonth, 0, 6) && typeof s.ruler.restedThisMonth === 'boolean' && (!isRulerIll(s) || s.attention === 0), 'здоровье правителя');
    const conversations = Object.hasOwn(s, 'conversations') ? s.conversations : [];
    check(list(conversations, PEOPLE.length * 2) && conversations.every(c => isObject(c) && PEOPLE.some(p => p.id === c.personId) && TALKS[c.personId]?.some(t => t.id === c.topicId) && number(c.month, 0, s.month) && text(c.response, 3000)) && new Set(conversations.map(c => `${c.personId}/${c.topicId}`)).size === conversations.length, 'разговоры и полученные сведения');
    check(list(s.encounters, 5) && s.encounters.every(e => isObject(e) && number(e.id, 1, s.nextId - 1) && STORIES.some(t => t.id === e.template && (!e.resolved || t.choices.some(c => c.id === e.choice))) && number(e.created, 0, s.month) && typeof e.resolved === 'boolean' && (e.origin === null || number(e.origin, 0, s.month))), 'встречи');
    for (const e of s.encounters) if (Object.hasOwn(e, 'choiceOrder')) { const ids = STORIES.find(t => t.id === e.template).choices.map(c => c.id); check(list(e.choiceOrder, ids.length) && e.choiceOrder.length === ids.length && new Set(e.choiceOrder).size === ids.length && e.choiceOrder.every(id => ids.includes(id)), 'порядок решений встречи'); }
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
  function normalizeLegacyState(s) {
    const originalIds = ['treasurer', 'marshal', 'doctor', 'engineer', 'envoy', 'governor'];
    // Только полный исходный состав 0.4–0.5 мигрируется автоматически. Потеря
    // произвольного персонажа в повреждённом файле не маскируется восстановлением.
    if (Array.isArray(s.characters) && s.characters.length === originalIds.length && new Set(s.characters.map(p => p?.id)).size === originalIds.length && s.characters.every(p => originalIds.includes(p?.id))) {
      for (const p of PEOPLE) if (!originalIds.includes(p.id)) s.characters.push({ id: p.id, trust: 50 });
    }
    if (!Object.hasOwn(s, 'conversations')) s.conversations = [];
    if (Object.hasOwn(s, 'laws')) s.laws = LAW_DATA.normalize(s.laws);
    if (!Object.hasOwn(s, 'ruler')) s.ruler = createRuler();
    if (!Object.hasOwn(s, 'military')) s.military = MILITARY.create(s);
    if (!Object.hasOwn(s, 'nextCrisis')) s.nextCrisis = s.month + 3;
    if(!Object.hasOwn(s,'technologies'))s.technologies=[];
    if(!Object.hasOwn(s,'specialists'))s.specialists={builders:1,physicians:1,spies:1,diplomats:1,engineers:1};
    if(!Object.hasOwn(s,'tradeTerms'))s.tradeTerms={};
    if(!Object.hasOwn(s,'appointments'))s.appointments={medicine:'lada',army:'yaropolk',justice:'vera',works:'elena'};
    if(!Object.hasOwn(s,'epidemic'))s.epidemic=null;
    if(!Object.hasOwn(s,'factions'))s.factions=[{id:'guild',name:'Купеческая гильдия',sphere:'торговля и пошлины',illegal:false,influence:42,relation:5},{id:'artisans',name:'Ремесленные братства',sphere:'мастерские и рабочие',illegal:false,influence:36,relation:10},{id:'watch',name:'Старая городская стража',sphere:'ворота и квартальный порядок',illegal:false,influence:28,relation:0},{id:'smugglers',name:'Речные контрабандисты',sphere:'тайный ввоз и переправы',illegal:true,influence:24,relation:-5},{id:'thieves',name:'Воровская сеть Нижнего города',sphere:'кражи, скупщики и укрытия',illegal:true,influence:18,relation:-15}];
    const additions={wood:0,stone:0,iron:0,goods:0,houses:0,smithies:0,lumberyards:0,quarries:0,mines:0,workshops:0,markets:0,fireStations:0,sanitation:0,courts:0,postOffices:0,barracks:0,cityWatch:0,prisons:0};
    const fill=p=>{if(!p||typeof p!=='object')return;for(const [key,value] of Object.entries(additions))if(!Object.hasOwn(p,key))p[key]=value;};
    fill(s.player);fill(s.initial);fill(s.monthStart);for(const m of s.metrics||[])fill(m.values);if(s.lastTurn){fill(s.lastTurn.before);fill(s.lastTurn.after);}if(s.chapter){fill(s.chapter.values);fill(s.chapter.initial);}
    return s;
  }
  function deserialize(raw) {
    if (typeof raw !== 'string' || raw.length > 1000000) fail('Файл сохранения слишком велик или имеет неверный формат.');
    let envelope;
    try { envelope = JSON.parse(raw); } catch { fail('Файл не является сохранением JSON.'); }
    if (!envelope || envelope.format !== 'price-of-power' || envelope.version !== VERSION) fail('Это сохранение другой игры или несовместимой версии. Нужен формат сохранений 4.');
    if (!envelope.state || typeof envelope.state !== 'object' || Array.isArray(envelope.state)) fail('Повреждённое сохранение: состояние кампании.');
    const restored = normalizeLegacyState(copy(envelope.state));
    validateState(restored);
    return restored;
  }
  return { VERSION, COUNTRIES: copy(COUNTRIES), COMMANDS: copy(COMMANDS), BUILDINGS: copy(BUILDINGS), LAWS: copy(LAWS), OFFICES:copy(OFFICES), METRICS: copy(METRICS), INTENTS: copy(INTENTS), createGame, queueOrder, appointOfficial, orderBlocker, chooseEvent, advanceMonth, acknowledgeChapter, resolveEncounter, talkToCharacter, workOvertime, restRuler, militaryQuote, launchMilitary, battleOrder, getView, economy, decideNeighbor, serialize, deserialize, validateState, date };
});
