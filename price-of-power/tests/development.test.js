'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const G = require('../source/core');
const D = require('../source/development');
const view = () => G.getView(G.createGame());

test('карта показывает восемь разных проектов и отдельную крепость', () => {
  const html = D.mapMarkup(view());
  assert.equal((html.match(/data-building-select=/g) || []).length, 8);
  for (const key of ['farms','orchards','roads','wells','granaries','schools','clinics','universities']) assert.ok(html.includes(`development-art--${key}`));
  assert.match(html, /Замок Ардена/);
  assert.match(html, /arden-city-map\.png/);
});
test('карточки сохраняют правильный приказ, цену, ограничения и категории', () => {
  const v = view();
  for (const key of ['granaries','schools','clinics','universities']) {
    const b = v.buildings.find(b => b.key === key), d = v.commands.find(d => d.id === b.command);
    const html = D.buildingCard(v, d, b, 'Не хватает монет.');
    assert.ok(html.includes(`data-order="${b.command}" disabled`));
    assert.ok(html.includes(`development-art--${key}`));
    assert.ok(html.includes(`${d.gold} монет`));
    assert.ok(html.includes(D.districtInfo(key).category));
  }
});
test('строительство и действующий уровень визуально различаются', () => {
  const v = view(), b = v.buildings.find(b => b.key === 'granaries');
  v.player.granaries=0;
  assert.equal(D.projectState(v,b).status,'unbuilt');
  v.orders.push({type:b.command,remaining:2});
  assert.equal(D.projectState(v,b).status,'building');
  assert.match(D.projectState(v,b).label,/2 мес/);
  v.orders=[];v.player.granaries=2;
  assert.equal(D.projectState(v,b).status,'operating');
  assert.match(D.projectState(v,b).label,/ур. 2/);
});
test('текст модели экранируется перед показом', () => {
  const v=view(),b={...v.buildings[0],name:'<img src=x onerror=alert(1)>',effect:'<script>bad</script>'},d=v.commands.find(d=>d.id===b.command);
  const html=D.buildingCard(v,d,b,'<b>blocked</b>');
  assert.ok(html.includes('&lt;img'));
  assert.ok(html.includes('&lt;script&gt;'));
  assert.ok(!html.includes('<script>bad'));
});
