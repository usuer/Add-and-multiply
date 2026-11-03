'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const P = require('../source/laws');

test('четырнадцать областей закона сохраняют прежние идентификаторы', () => {
  assert.equal(P.LAWS.length, 14);
  const options = Object.fromEntries(P.LAWS.map(law => [law.key, law.options.map(option => option.value)]));
  assert.deepEqual(options.tax, ['low', 'balanced', 'high']);
  assert.deepEqual(options.grain, ['market', 'reserve']);
  assert.deepEqual(options.education, ['elite', 'public']);
  assert.ok(options.health&&options.justice&&options.land&&options.identity&&options.policing&&options.punishment);
  assert.ok(options.workday&&options.workingAge&&options.conscription&&options.warEconomy&&options.civilDuty);
});

test('принятие законов бесплатно, но требует месяца и работы канцелярии', () => {
  for (const law of P.LAWS) {
    assert.deepEqual(law.adoption, { gold: 0, duration: 1, ap: 1, actor: 'council' });
    for (const option of law.options) {
      assert.equal(option.gold, 0);
      assert.equal(option.duration, 1);
    }
  }
});

test('сохранение с тремя законами получает новые исходные политики без изменения выбора', () => {
  const original = { tax: 'high', grain: 'reserve', education: 'public' };
  const before = JSON.stringify(original);
  const updated = P.normalize(original);
  assert.equal(P.validate(updated), true);
  assert.deepEqual(updated, { ...P.defaults, ...original });
  assert.equal(updated.tax, 'high');
  assert.equal(updated.grain, 'reserve');
  assert.equal(updated.education, 'public');
  assert.equal(JSON.stringify(original), before);
  assert.notEqual(updated, original);
});

test('миграция не маскирует неверные значения и неизвестные законы', () => {
  assert.equal(P.validate(P.normalize({ tax: 'unlimited' })), false);
  assert.equal(P.validate(P.normalize({ tax: null })), false);
  assert.equal(P.validate(P.normalize({ ...P.defaults, magic: 'free' })), false);
  assert.equal(P.validate({ tax: 'balanced', grain: 'market', education: 'elite' }), false);
  for (const bad of [null, [], 'market', 5, true]) assert.equal(P.validate(P.normalize(bad)), false);
  assert.equal(P.validate(P.normalize(undefined)), true);
});

test('исходные новые законы не вводят скрытых расходов или бонусов', () => {
  const s = { laws: { ...P.defaults } };
  assert.deepEqual(P.extraEconomy(s), { income: 0, upkeep: 0, production: 0 });
  assert.deepEqual(P.monthlyEffects(s), { health: 0, stability: 0 });
});

test('санитарная служба стоит денег каждый месяц и повышает здоровье без строительного требования', () => {
  const s = { laws: { ...P.defaults, health: 'municipal' }, player: { clinics: 0, wells: 0 } };
  assert.deepEqual(P.extraEconomy(s), { income: 0, upkeep: 3, production: 0 });
  assert.deepEqual(P.monthlyEffects(s), { health: 2, stability: 0 });
});

test('публичные разбирательства оплачивают работу писцов и повышают стабильность', () => {
  const s = { laws: { ...P.defaults, justice: 'open' } };
  assert.deepEqual(P.extraEconomy(s), { income: 0, upkeep: 2, production: 0 });
  assert.deepEqual(P.monthlyEffects(s), { health: 0, stability: 1 });
});

test('общинные посевы заменяют часть денежного дохода зерном и стабильностью', () => {
  const s = { laws: { ...P.defaults, land: 'commons' } };
  assert.deepEqual(P.extraEconomy(s), { income: -3, upkeep: 0, production: 3 });
  assert.deepEqual(P.monthlyEffects(s), { health: 0, stability: 1 });
});

test('политики складываются, не мутируют состояние и отменяются без остаточных эффектов', () => {
  const s = { laws: { ...P.defaults, health: 'municipal', justice: 'open', land: 'commons' }, player: { gold: 20 } };
  const before = JSON.stringify(s);
  assert.deepEqual(P.extraEconomy(s), { income: -3, upkeep: 5, production: 3 });
  assert.deepEqual(P.monthlyEffects(s), { health: 2, stability: 2 });
  assert.equal(JSON.stringify(s), before);
  const restored = { laws: { ...s.laws, health: 'household', justice: 'discretion', land: 'dues' } };
  assert.deepEqual(P.extraEconomy(restored), { income: 0, upkeep: 0, production: 0 });
  assert.deepEqual(P.monthlyEffects(restored), { health: 0, stability: 0 });
});

test('новые расчёты не повторяют уже учтённые налог, зерно и образование', () => {
  const s = { laws: { ...P.defaults, tax: 'high', grain: 'reserve', education: 'public' } };
  assert.deepEqual(P.extraEconomy(s), { income: 0, upkeep: 0, production: 0 });
  assert.deepEqual(P.monthlyEffects(s), { health: 0, stability: 0 });
});

test('ошибочная политика не получает частично посчитанный эффект', () => {
  const s = { laws: { ...P.defaults, justice: 'nonsense' } };
  assert.throws(() => P.extraEconomy(s), /закона/);
  assert.throws(() => P.monthlyEffects(s), /закона/);
});

test('описание вывоза отличает продажу зерна от потребления людей', () => {
  const grain = P.LAWS.find(law => law.key === 'grain');
  const reserve = grain.options.find(option => option.value === 'reserve');
  assert.equal(reserve.name, 'Ограничить вывоз зерна');
  assert.match(reserve.effect, /2 зерна/);
  assert.match(reserve.effect, /−3/);
  assert.match(reserve.effect, /Потребление жителей и армии не меняется/);
  assert.doesNotMatch(reserve.effect, /потребление.*−2/);
});

test('модуль запускается как обычный браузерный скрипт без require', () => {
  const sandbox = vm.createContext({});
  vm.runInContext(fs.readFileSync(path.join(__dirname, '../source/laws.js'), 'utf8'), sandbox);
  assert.ok(sandbox.PopLaws);
  assert.equal(sandbox.PopLaws.LAWS.length, 14);
  assert.equal(sandbox.PopLaws.validate(sandbox.PopLaws.normalize()), true);
});
