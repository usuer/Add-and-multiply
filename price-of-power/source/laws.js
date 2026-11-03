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
    health: 'household', justice: 'discretion', land: 'dues',
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
      income: laws.land === 'commons' ? -3 : 0,
      upkeep: (laws.health === 'municipal' ? 3 : 0) + (laws.justice === 'open' ? 2 : 0),
      production: laws.land === 'commons' ? 3 : 0,
    };
  }

  function monthlyEffects(state) {
    const laws = resolveLaws(state);
    return {
      health: laws.health === 'municipal' ? 2 : 0,
      stability: (laws.justice === 'open' ? 1 : 0) + (laws.land === 'commons' ? 1 : 0),
    };
  }

  return { LAWS, defaults, adoption, extraEconomy, monthlyEffects, normalize, validate };
});
