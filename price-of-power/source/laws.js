/* Законы княжества: определения и дополнительные эффекты политики 0.6. */
(function (root, factory) {
  'use strict';
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.PopLaws = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  // Правитель не покупает право издать указ. Подготовка занимает работу
  // канцелярии и одно поручение; расходы возникают у действующей политики.
  const adoption = Object.freeze({ gold: 0, duration: 1, ap: 1, actor: 'council' });
  const defaults = Object.freeze({
    tax: 'balanced', grain: 'market', education: 'elite',
    health:'household',justice:'discretion',land:'dues',identity:'local',policing:'ward',punishment:'restorative',
    workday:'customary',workingAge:'family',conscription:'retinue',warEconomy:'civilian',civilDuty:'voluntary',
  });
  const LAWS = [
    {
      key: 'tax', name: 'Налогообложение', category: 'Казна', symbol: 'coin', adoption,
      explanation: 'Размер сбора меняет доход казны и отношение жителей к бремени налогов.',
      options: [
        { value: 'low', name: 'Щадящий сбор', effect: 'Доход −4/мес., стабильность +2/мес. Жителям оставляют больше средств.' },
        { value: 'balanced', name: 'Обычный сбор', effect: 'Базовый доход без дополнительного влияния на стабильность.' },
        { value: 'high', name: 'Чрезвычайный сбор', effect: 'Доход +7/мес., стабильность −3/мес. Казна получает больше ценой недовольства жителей.' },
      ],
    },
    {
      key: 'grain', name: 'Вывоз зерна', category: 'Снабжение', symbol: 'grain', adoption,
      explanation: 'Указ определяет, уходит ли часть зерна с торговыми обозами. Жители и армия продолжают есть столько же.',
      options: [
        {
          value: 'market', name: 'Свободная продажа',
          effect: 'Торговые обозы вывозят 2 зерна/мес. Доход от этой торговли включён в обычный доход княжества.',
          explanation: 'Вывоз показывается в балансе отдельно от еды жителей, армии и потерь при хранении.',
        },
        {
          value: 'reserve', name: 'Ограничить вывоз зерна',
          effect: 'Вывоз прекращается: 2 зерна/мес. остаются в стране. Торговый доход −3/мес. Потребление жителей и армии не меняется.',
          explanation: 'Это не нормирование еды и не платная закупка. Княжество отказывается от части торговой выручки, сохраняя зерно внутри страны.',
        },
      ],
    },
    {
      key: 'education', name: 'Доступ к образованию', category: 'Люди', symbol: 'book', adoption,
      explanation: 'Чтобы учить людей за счёт казны, нужна хотя бы одна земская школа.',
      options: [
        { value: 'elite', name: 'Обучение при дворе', effect: 'Занятия при дворе без дополнительного ежемесячного содержания.' },
        {
          value: 'public', name: 'Общедоступное обучение',
          effect: 'Содержание 4 монеты/мес.; стабильность +1/мес.; наука +1 раз в полгода. Нужна земская школа.',
          requires: { schools: 1 },
        },
      ],
    },
    {
      key: 'health', name: 'Городская гигиена', category: 'Люди', symbol: 'water', adoption,
      explanation: 'Оплата очистки улиц и стоков, проверки колодцев и вывоза отходов помогает предупреждать болезни. Это можно организовать до строительства лечебницы.',
      options: [
        { value: 'household', name: 'Забота самих дворов', effect: 'Уборку организуют жители. Нет отдельной статьи содержания или дополнительного роста здоровья.' },
        { value: 'municipal', name: 'Городская санитарная служба', effect: 'Содержание 3 монеты/мес., здоровье +2/мес. Не требует лечебницы.' },
      ],
    },
    {
      key: 'justice', name: 'Порядок разбирательств', category: 'Управление', symbol: 'scales', adoption,
      explanation: 'Публичный приём жалоб и ведение протоколов требуют постоянной работы писцов, зато правила становятся понятнее жителям.',
      options: [
        { value: 'discretion', name: 'Княжеское усмотрение', effect: 'Дела разбирают в обычном порядке. Нет дополнительного содержания или изменения стабильности.' },
        { value: 'open', name: 'Открытый приём и протоколы', effect: 'Содержание 2 монеты/мес., стабильность +1/мес. Двор оплачивает писцов и регулярный приём жалоб.' },
      ],
    },
    {
      key: 'land', name: 'Общинные земли', category: 'Хозяйство', symbol: 'field', adoption,
      explanation: 'Можно оставить прежние денежные сборы с земель или передать часть угодий общинам для выращивания пищи.',
      options: [
        { value: 'dues', name: 'Прежние земельные сборы', effect: 'Базовые денежные сборы и производство зерна без дополнительных изменений.' },
        { value: 'commons', name: 'Угодья для общинных посевов', effect: 'Доход −3/мес.; производство зерна +3/мес.; стабильность +1/мес. Общины получают землю взамен части денежных сборов.' },
      ],
    },
    {key:'identity',name:'Учёт жителей и документы',category:'Правопорядок',symbol:'document',adoption,explanation:'Учёт помогает искать преступников и распределять повинности, но требует писцов и вызывает тревогу у тех, кто привык жить без надзора.',options:[
      {value:'local',name:'Поручительство соседей',effect:'Личность подтверждают старосты и соседи. Нет содержания; ворам проще скрываться между кварталами.'},
      {value:'register',name:'Городские реестры и удостоверения',effect:'Содержание 2 монеты/мес.; преступность снижается, разведка +1 разово после принятия; стабильность −1/мес. без открытого суда.'},
    ]},
    {key:'policing',name:'Устройство городской стражи',category:'Правопорядок',symbol:'watch',adoption,explanation:'Можно оставить охрану кварталам или содержать профессиональных служащих с жалованием, патрулями и ответственностью перед судом.',options:[
      {value:'ward',name:'Квартальная самоохрана',effect:'Нет постоянного содержания. Качество охраны зависит от жителей и влияния местных группировок.'},
      {value:'professional',name:'Профессиональная городская стража',effect:'Содержание 4 монеты/мес.; стабильность +1/мес., меньше краж и пожаров. Полный эффект требует здания стражи.'},
    ]},
    {key:'punishment',name:'Мера наказания',category:'Правопорядок',symbol:'prison',adoption,explanation:'Наказание может возмещать ущерб, изолировать опасных людей или устрашать. Жестокость подавляет часть преступлений, но создаёт страх и ошибки.',options:[
      {value:'restorative',name:'Возмещение и общественные работы',effect:'Осуждённые возмещают ущерб и работают на город. Стабильность +1/мес. при открытом суде.'},
      {value:'imprisonment',name:'Тюремное заключение',effect:'Содержание 2 монеты/мес.; преступные сети теряют влияние. Нужна городская тюрьма для полного эффекта.'},
      {value:'harsh',name:'Показательные суровые кары',effect:'Содержание 1 монета/мес.; быстро снижает открытое воровство, но стабильность −2/мес. и повышается риск эмиграции.'},
    ]},
    {key:'workday',name:'Распорядок труда',category:'Труд и общество',symbol:'clock',adoption,flexible:true,explanation:'Распорядок можно пересмотреть одним указом. Более долгий день ускоряет хозяйство, но истощает людей и усиливает недовольство.',options:[
      {value:'short',name:'Сокращённый день',effect:'Доход −3/мес., производство товаров ниже; здоровье +1 и стабильность +1/мес.'},
      {value:'customary',name:'Обычный распорядок',effect:'Работа по привычному укладу без дополнительных выгод и потерь.'},
      {value:'long',name:'Продлённый день',effect:'Доход +5/мес., мастерские производят больше; здоровье −1 и стабильность −2/мес.'},
    ]},
    {key:'workingAge',name:'Возраст допуска к труду',category:'Труд и общество',symbol:'people',adoption,flexible:true,explanation:'Указ определяет, с какого возраста разрешён наём. Ранний труд даёт больше рабочих рук сейчас, но вредит здоровью и обучению следующего поколения.',options:[
      {value:'protected',name:'Труд с шестнадцати лет',effect:'Доход −2/мес.; здоровье +1/мес., общедоступное образование приносит больше науки.'},
      {value:'family',name:'Семейное усмотрение',effect:'Возраст определяют семьи и цехи. Нет отдельного эффекта.'},
      {value:'early',name:'Труд с двенадцати лет',effect:'Доход +4/мес.; здоровье −2/мес., стабильность −1/мес. и слабее развитие науки.'},
    ]},
    {key:'conscription',name:'Воинская обязанность',category:'Военное положение',symbol:'sword',adoption,flexible:true,explanation:'От дружины можно перейти к призыву или всеобщему ополчению. Массовая армия защищает стены, но забирает людей из хозяйства.',options:[
      {value:'retinue',name:'Профессиональная дружина',effect:'Сражаются обученные части. Нет дополнительной мобилизации или ущерба хозяйству.'},
      {value:'levy',name:'Ограниченный призыв',effect:'Оборона +8, содержание +3/мес.; доход −3 и стабильность −1/мес.'},
      {value:'total',name:'Всеобщее ополчение',effect:'Оборона +20, армия получает резерв у стен; доход −9, зерно −4 и стабильность −3/мес.'},
    ]},
    {key:'warEconomy',name:'Назначение производства',category:'Военное положение',symbol:'forge',adoption,flexible:true,explanation:'Мастерские могут делать товары для рынка либо срочно снабжать армию. Перевод туда и обратно происходит сразу, но частая смена раздражает цехи.',options:[
      {value:'civilian',name:'Мирное производство',effect:'Обычный выпуск товаров и торговый доход.'},
      {value:'mixed',name:'Военные заказы',effect:'Оборона +5; мастерские дают меньше товаров, содержание +2/мес.'},
      {value:'militarized',name:'Всё для фронта',effect:'Оборона +14 и армейское снабжение; мастерские не дают торговых товаров, доход −6 и стабильность −2/мес.'},
    ]},
    {key:'civilDuty',name:'Гражданская помощь в войну',category:'Военное положение',symbol:'shield',adoption,flexible:true,explanation:'Жители могут помогать добровольно либо по повинности: чинить стены, перевозить провиант и ухаживать за ранеными.',options:[
      {value:'voluntary',name:'Добровольная помощь',effect:'Нет постоянных затрат и принуждения.'},
      {value:'organized',name:'Организованные городские команды',effect:'Оборона +4, потери от пожаров меньше; содержание 2 монеты/мес.'},
      {value:'compulsory',name:'Всеобщая трудовая повинность',effect:'Оборона +9, строительство быстрее; доход −4, здоровье −1 и стабильность −2/мес.'},
    ]},
  ];
  for (const law of LAWS) {
    for (const option of law.options) {
      option.gold = 0;
      option.duration = 1;
      if (option.requires) Object.freeze(option.requires);
      Object.freeze(option);
    }
    Object.freeze(law.options);
    Object.freeze(law);
  }
  Object.freeze(LAWS);

  function isObject(value) {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
  }

  // Миграция старых трёх законов добавляет только отсутствующие значения.
  // Неверное существующее значение не подменяется корректным по умолчанию.
  function normalize(laws) {
    if (laws === undefined) return { ...defaults };
    if (!isObject(laws)) return laws;
    return { ...defaults, ...laws };
  }

  function validate(laws) {
    if (!isObject(laws) || Object.keys(laws).length !== LAWS.length) return false;
    return LAWS.every(law => Object.hasOwn(laws, law.key) && law.options.some(option => option.value === laws[law.key]));
  }

  function resolveLaws(state) {
    const laws = normalize(state && state.laws);
    if (!validate(laws)) throw new Error('Неизвестное или повреждённое положение закона.');
    return laws;
  }

  // В существующем ядре уже учтены tax, grain и education. Эти функции
  // возвращают только прибавки трёх новых областей, без двойного счёта.
  function extraEconomy(state) {
    const laws = resolveLaws(state);
    return {
      upkeep:(laws.health==='municipal'?3:0)+(laws.justice==='open'?2:0)+(laws.identity==='register'?2:0)+(laws.policing==='professional'?4:0)+(laws.punishment==='imprisonment'?2:laws.punishment==='harsh'?1:0)+(laws.conscription==='levy'?3:0)+(laws.warEconomy==='mixed'?2:0)+(laws.civilDuty==='organized'?2:0),
      income:(laws.land==='commons'?-3:0)+(laws.workday==='short'?-3:laws.workday==='long'?5:0)+(laws.workingAge==='protected'?-2:laws.workingAge==='early'?4:0)+(laws.conscription==='levy'?-3:laws.conscription==='total'?-9:0)+(laws.warEconomy==='militarized'?-6:0)+(laws.civilDuty==='compulsory'?-4:0),
      production: laws.land === 'commons' ? 3 : 0,
    };
  }

  function monthlyEffects(state) {
    const laws = resolveLaws(state);
    return {
      health:(laws.health==='municipal'?2:0)+(laws.workday==='short'?1:laws.workday==='long'?-1:0)+(laws.workingAge==='protected'?1:laws.workingAge==='early'?-2:0)-(laws.civilDuty==='compulsory'?1:0),
      stability:(laws.justice==='open'?1:0)+(laws.land==='commons'?1:0)+(laws.policing==='professional'?1:0)+(laws.punishment==='restorative'&&laws.justice==='open'&&state.player?.courts>0?1:0)-(laws.punishment==='harsh'?2:0)-(laws.identity==='register'&&laws.justice!=='open'?1:0)+(laws.workday==='short'?1:laws.workday==='long'?-2:0)-(laws.workingAge==='early'?1:0)-(laws.conscription==='levy'?1:laws.conscription==='total'?3:0)-(laws.warEconomy==='militarized'?2:0)-(laws.civilDuty==='compulsory'?2:0),
    };
  }

  return { LAWS, defaults, adoption, extraEconomy, monthlyEffects, normalize, validate };
});
