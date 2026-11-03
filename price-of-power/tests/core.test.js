'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const G = require('../source/core');
const { STORIES } = require('../source/stories');

function council(s) {
  while(G.getView(s).military?.battle) s=G.battleOrder(s,'guard');
  if (s.chapter && !s.chapter.acknowledged) s = G.acknowledgeChapter(s);
  if (s.pending) {
    const choices = G.getView(s).event.choices;
    const choice = choices.find(c => ['investigate', 'talk', 'fields', 'import'].includes(c.id) && !c.disabled) || choices.find(c => !c.disabled);
    s = G.chooseEvent(s, choice.id);
  }
  return s;
}
function turns(s, n) { for (let i = 0; i < n && !s.ended; i++) s = G.advanceMonth(council(s)); return s; }
function rich(seed = 'test') { const s = G.createGame({seed}); s.player.gold = 2000; s.monthStart.gold = 2000; s.initial.gold = 2000; s.metrics[0].values.gold = 2000; return s; }
function play(seed, count = 36) {
  let s = G.createGame({seed});
  for (let i = 0; i < count && !s.ended; i++) {
    s = council(s);
    if(s.ended) break;
    for (const id of ['farm', 'orchard', 'road', 'well', 'school', 'clinic', 'granary', 'university']) {
      const cost = G.getView(s).commands.find(c => c.id === id).gold;
      if (!G.orderBlocker(s, id, 'val') && s.player.gold > cost + 22) { s = G.queueOrder(s, id); break; }
    }
    for (const e of G.getView(s).encounters.slice(0, 2)) {
      const option = e.choices.find(c => !c.disabled && c.gold <= 6) || e.choices.find(c => !c.disabled);
      if (option && s.attention) s = G.resolveEncounter(s, e.id, option.id);
    }
    if(s.ended) break;
    s = G.advanceMonth(s); G.validateState(s);
  }
  return s;
}
function withStory(id) {
  for (let i = 0; i < 100; i++) { const s = G.createGame({seed: `story-${i}`}); const e = s.encounters.find(e => e.template === id); if (e) return [s, e]; }
  throw new Error('Не найдено начальное событие ' + id);
}

test('начальное состояние, три соседа и три личных дела валидны', () => {
  const s = G.createGame(); assert.equal(G.validateState(s), true); assert.equal(s.neighbors.length, 3); assert.equal(s.encounters.length, 3); assert.equal(s.reports.length, 3);
});
test('один ключ и одинаковая политика дают идентичные 36 месяцев', () => {
  const a = play('deterministic'), b = play('deterministic'); assert.equal(a.month, 36); assert.equal(G.serialize(a), G.serialize(b));
});
test('разные ключи меняют наблюдения и события', () => { assert.notEqual(G.serialize(G.createGame({seed:'a'})), G.serialize(G.createGame({seed:'b'}))); });
test('модель не зависит от Math.random', () => {
  const original = Math.random; Math.random = () => { throw new Error('Недетерминированный вызов'); };
  try { assert.equal(turns(G.createGame(), 4).month, 4); } finally { Math.random = original; }
});
test('команды и решения не изменяют входное состояние', () => {
  const s = G.createGame(), raw = G.serialize(s); G.queueOrder(s, 'farm'); G.chooseEvent(s, 'investigate'); assert.equal(G.serialize(s), raw);
});
test('неудачная команда не тратит деньги, случайность или очки действий', () => {
  const s = G.createGame(), raw = G.serialize(s); assert.throws(() => G.queueOrder(s, 'missing')); assert.throws(() => G.queueOrder(s, 'scout', 'invalid')); assert.equal(G.serialize(s), raw);
});
test('недостаток денег и занятый исполнитель реально блокируют приказы', () => {
  let s = G.createGame(); s.player.gold = 0; assert.throws(() => G.queueOrder(s, 'farm'), /монет/);
  s = G.queueOrder(G.createGame(), 'scout', 'val'); assert.throws(() => G.queueOrder(s, 'network'), /заняты/);
});
test('стоимость вычитается сразу; лимит новых приказов равен двум', () => {
  let s = G.createGame();const before=s.player.gold,cost=G.getView(s).commands.find(c=>c.id==='farm').gold+14;s = G.queueOrder(s, 'farm'); s = G.queueOrder(s, 'scout', 'mer'); assert.equal(s.player.gold,before-cost); assert.equal(s.ap, 0); assert.throws(() => G.queueOrder(s, 'aid'), /Лимит/);
});
test('разведка и поле идут параллельно и завершаются в разные месяцы', () => {
  let s = council(G.createGame()); s = G.queueOrder(s, 'scout', 'mer'); s = G.queueOrder(s, 'farm');
  s = turns(s, 1); assert.deepEqual(s.orders.map(o => o.remaining), [1,2]);
  s = turns(s, 1); assert.equal(s.orders.length, 1); assert.equal(s.completed[0].type, 'scout'); assert.equal(s.player.farms,1);
  s = turns(s, 1); assert.equal(s.player.farms,2); assert.equal(s.orders.length, 0);
});
test('соседи действуют шесть месяцев без приказов игрока', () => {
  const initial = G.createGame(); const s = turns(initial, 6); assert.equal(s.aiHistory.length, 18); assert.ok(s.neighbors.every(n => n.turns === 6)); assert.ok(s.neighbors.some((n,i) => n.gold !== initial.neighbors[i].gold)); assert.ok(new Set(s.aiHistory.map(h => h.action)).size >= 2);assert.equal(new Set(s.aiHistory.map(h => h.id)).size,3);
});
test('ИИ может направить набег против другой страны, а не игрока', () => {
  let s = council(G.createGame()); const n = s.neighbors.find(n => n.id === 'nor'); n.relations.val = -90; n.relation = 50; n.beliefs.val.army = 5; n.beliefs.val.defense = 0;
  assert.deepEqual({action:G.decideNeighbor(n).action,target:G.decideNeighbor(n).target}, {action:'raid',target:'val'});
});
test('решение ИИ зависит от собственной оценки силы и бюджета', () => {
  const n = G.createGame().neighbors.find(n => n.id === 'nor'); n.relation = -80; n.relations.val = 90; n.relations.mer = 90; n.beliefs.player = {army:1,defense:0,month:0};
  assert.equal(G.decideNeighbor(n).action, 'raid'); n.beliefs.player.army = 1000; assert.notEqual(G.decideNeighbor(n).action, 'raid'); n.gold = 5; assert.equal(G.decideNeighbor(n).action, 'trade');
});
test('публичная проекция не раскрывает реальные ресурсы или планы соседей', () => {
  const s = G.createGame(), v = G.getView(s); for(const n of v.neighbors) for(const key of ['army','gold','food','intent','beliefs','aggression']) assert.equal(Object.hasOwn(n,key),false);
  assert.equal(Object.hasOwn(v,'aiHistory'),false); v.player.gold = 0; assert.equal(s.player.gold,110);
});
test('донесения действительно бывают ошибочными, но не помечают ложь игроку', () => {
  let wrong = 0;
  for(let i=0;i<40;i++){const s=G.createGame({seed:String(i)});wrong+=s.reports.filter(r=>r.intent!==s.neighbors.find(n=>n.id===r.target).intent).length; assert.ok(s.reports.every(r=>!Object.hasOwn(r,'truth')));}
  assert.ok(wrong > 25);
});
test('старые сведения теряют актуальность на шесть пунктов за месяц', () => {
  const s = turns(G.createGame(),3), r = G.getView(s).neighbors[0].reports[0]; assert.equal(r.age,3); assert.equal(r.effectiveConfidence,30);
});
test('разведчик может быть пойман или доставить новое донесение', () => {
  let captured=0, delivered=0;
  for(let i=0;i<60;i++){let s=council(G.createGame({seed:`agent-${i}`}));s=G.queueOrder(s,'scout','val');s=turns(s,2);if(s.reports.some(r=>r.source==='Тайная канцелярия'))delivered++;else captured++;}
  assert.ok(captured>0);assert.ok(delivered>0);
});
test('пограничная цепочка имеет продолжение и разные последствия', () => {
  const a = G.chooseEvent(G.createGame(),'investigate'), b = G.chooseEvent(G.createGame(),'mobilize');
  const aa=turns(a,2),bb=turns(b,2);assert.equal(aa.pending.kind,'border_followup');assert.equal(bb.pending.kind,'border_followup');
  const peace=G.chooseEvent(aa,'talk'),force=G.chooseEvent(bb,'guard');assert.ok(peace.neighbors[0].relation>force.neighbors[0].relation);assert.ok(force.player.defense>peace.player.defense);
});
test('продовольственная цепочка возникает из запасов и даёт последующее решение', () => {
  let s=G.createGame({scenario:'scarcity'});assert.equal(s.pending.kind,'grain');s=G.chooseEvent(s,'import');s=turns(s,3);assert.equal(s.pending.kind,'grain_followup');const fields=s.player.farms;s=G.chooseEvent(s,'fields');assert.equal(s.player.farms,fields+1);
});
test('нормирование длится ровно три расчёта месяца', () => {
  let s=G.createGame({scenario:'scarcity'});s=G.chooseEvent(s,'ration');assert.equal(s.player.rationUntil,3);assert.equal(G.economy({...s,month:2}).consumption+4,G.economy({...s,month:3}).consumption);
});
test('школы открывают университет, уровни дорожают и требуют времени', () => {
  let s=rich();assert.match(G.orderBlocker(s,'university'),/2 школы/);s=G.queueOrder(s,'school');assert.throws(()=>G.queueOrder(s,'school'),/уже строится/);s=turns(s,3);assert.equal(s.player.schools,1);
  assert.equal(G.getView(s).commands.find(c=>c.id==='school').gold,27);s=G.queueOrder(s,'school');s=turns(s,3);assert.equal(s.player.schools,2);assert.equal(s.player.science,4);
  assert.equal(G.orderBlocker(s,'university'),'');s=G.queueOrder(s,'university');s=turns(s,4);assert.equal(s.player.universities,1);assert.equal(s.player.science,6);assert.equal(s.player.intel,2);
});
test('сады, колодцы, склады и лечебницы меняют действующие расчёты', () => {
  let s=rich();const before=G.economy(s),initialWells=s.player.wells;s=G.queueOrder(s,'orchard');s=G.queueOrder(s,'well');s=turns(s,3);assert.equal(s.player.orchards,1);assert.equal(s.player.wells,initialWells+1);assert.ok(s.player.health>68);
  const other=structuredClone(s);other.player.orchards=0;assert.equal(G.economy(s).production-G.economy(other).production,3);
  s=G.queueOrder(s,'granary');s=G.queueOrder(s,'clinic');s=turns(s,3);const without=structuredClone(s);without.player.granaries=0;without.player.clinics=0;assert.ok(G.economy(s).losses<=G.economy(without).losses);assert.equal(G.economy(s).upkeep-G.economy(without).upkeep,2);assert.ok(before.upkeep>0);
});
test('закон вступает в силу после работы канцелярии и меняет доход и общество', () => {
  let s=council(G.createGame());const before=G.economy(s);s=G.queueOrder(s,'law_tax_high');assert.equal(s.laws.tax,'balanced');s=turns(s,1);assert.equal(s.laws.tax,'high');assert.equal(G.economy(s).income-before.income,7);assert.equal(s.player.stability,66);
});
test('общественное обучение требует школы и развивает науку раз в полгода', () => {
  let s=rich();assert.match(G.orderBlocker(s,'law_education_public'),/школу/);s=G.queueOrder(s,'school');s=turns(s,3);s=G.queueOrder(s,'law_education_public');s=turns(s,3);assert.equal(s.laws.education,'public');assert.equal(s.player.science,4);
});
test('торговый договор истекает до нового дохода и допускает продление без двойного счёта', () => {
  let s=rich();s.neighbors[1].pactUntil=1;s.player.trade=1;
  s=turns(s,1);assert.equal(s.player.trade,0);assert.equal(s.neighbors[1].pactUntil,0);
  const without=G.economy(s).income;assert.equal(s.lastTurn.entries.find(h=>h.kind==='economy').changes.gold,without-G.economy(s).upkeep);
  s=rich();s.neighbors[1].pactUntil=2;s.player.trade=1;s.player.diplomacy=20;s.neighbors[1].relation=80;s=G.queueOrder(s,'envoy','mer');s=turns(s,2);assert.equal(s.player.trade,1);assert.equal(s.neighbors[1].pactUntil,8);
});
test('поддержка деревень на максимальном уровне даёт зерно вместо фиктивной стройки', () => {
  let s=rich();s.player.farms=5;s.pending={kind:'grain_followup',target:null,created:0,origin:0,approach:'import',secret:null};const food=s.player.food;s=G.chooseEvent(s,'fields');assert.equal(s.player.farms,5);assert.equal(s.player.food,food+20);assert.equal(s.history[0].changes.food,20);
});
test('личная встреча расходует внимание, меняет доверие и не расходует государственный приказ', () => {
  let [s,e]=withStory('doctor');const before=s.player.gold;s=G.resolveEncounter(s,e.id,'supplies');assert.equal(s.attention,1);assert.equal(s.ap,2);assert.equal(s.player.gold,before-10);assert.equal(s.player.health,76);assert.equal(s.characters.find(p=>p.id==='doctor').trust,59);assert.throws(()=>G.resolveEncounter(s,e.id,'supplies'),/завершена/);
});
test('интрига возвращается через два месяца и получает работающую развязку', () => {
  let [s,e]=withStory('accounts');s=G.resolveEncounter(s,e.id,'audit');assert.equal(s.futureStories[0].template,'audit_return');s=turns(s,2);const follow=s.encounters.find(e=>e.template==='audit_return');assert.ok(follow);const before=s.player.food;s=G.resolveEncounter(s,follow.id,'trial');assert.equal(s.player.food,before+15);assert.ok(s.history[0].changes.food===15);
});
test('не более двух личных дел; встречи не мешают параллельной стройке', () => {
  let s=G.createGame();s=G.queueOrder(s,'farm');for(const e of [...s.encounters].slice(0,2)){const c=G.getView(s).encounters.find(x=>x.id===e.id).choices.find(c=>!c.disabled);s=G.resolveEncounter(s,e.id,c.id);}assert.equal(s.attention,0);assert.equal(s.orders.length,1);const third=s.encounters.find(e=>!e.resolved);assert.throws(()=>G.resolveEncounter(s,third.id,STORIES.find(t=>t.id===third.template).choices[0].id),/внимания/);
});
test('высокое доверие даёт реальные административные преимущества', () => {
  const s=G.createGame(),base=G.economy(s),full=G.getView(s).commands.find(c=>c.id==='farm').gold;s.characters.find(p=>p.id==='treasurer').trust=75;s.characters.find(p=>p.id==='marshal').trust=75;s.characters.find(p=>p.id==='engineer').trust=75;assert.equal(G.economy(s).income-base.income,2);assert.equal(G.economy(s).upkeep-base.upkeep,-1);assert.equal(G.getView(s).commands.find(c=>c.id==='farm').gold,Math.floor(full*.9));
});
test('к двенадцатому месяцу есть развязка, а после неё — второй год', () => {
  let s=turns(rich(),12);while(G.getView(s).military?.battle)s=G.battleOrder(s,'guard');assert.equal(s.ended,false);assert.equal(s.chapter.year,1);assert.ok(s.chapter.story.length>100);assert.equal(s.chapter.acknowledged,false);s=council(s);s=G.advanceMonth(s);assert.equal(s.month,13);assert.match(G.getView(s).date,/1249/);
});
test('итоги и графики отражают реальные изменения каждого показателя', () => {
  let s=G.queueOrder(council(G.createGame()),'farm');s=turns(s,3);assert.equal(s.metrics.length,4);assert.equal(s.metrics[3].values.farms,2);assert.equal(s.lastTurn.month,3);
  for(const [k,v] of Object.entries(s.lastTurn.changes))assert.equal(v,s.lastTurn.after[k]-s.lastTurn.before[k]);
  for(const k of Object.keys(G.METRICS)){const sum=s.lastTurn.entries.reduce((sum,h)=>sum+(h.changes[k]||0),0);assert.equal(sum,s.lastTurn.changes[k]||0,`ledger ${k}`);}
});
test('сохранение сохраняет очереди, сюжеты, доверие и следующее случайное решение', () => {
  let [s,e]=withStory('accounts');s=G.resolveEncounter(s,e.id,'audit');s=G.queueOrder(s,'school');s=turns(s,1);const loaded=G.deserialize(G.serialize(s));assert.deepEqual(loaded,s);assert.equal(G.serialize(turns(s,6)),G.serialize(turns(loaded,6)));
});
test('повреждённые и несовместимые сохранения отвергаются до использования', () => {
  assert.throws(()=>G.deserialize('{bad'));assert.throws(()=>G.deserialize('{}'),/версии/);
  const cases=[s=>s.rng=-1,s=>s.player.food=-10,s=>s.player.health=null,s=>s.neighbors[0].beliefs={},s=>s.laws.tax='infinite',s=>s.metrics=[],s=>s.characters=[],s=>s.encounters[0].template='unknown',s=>s.monthStart=null,s=>s.history[0].changes={gold:'NaN'}];
  for(const corrupt of cases){const s=G.createGame();corrupt(s);assert.throws(()=>G.deserialize(JSON.stringify({format:'price-of-power',version:4,state:s})));}
});
test('поражение получает причину, итог и блокировку новых приказов', () => {
  let s=G.createGame({scenario:'scarcity'});s.player.stability=3;s=G.chooseEvent(s,'ration');assert.equal(s.ended,true);assert.equal(s.chapter.final,true);assert.match(s.chapter.title,/Печать/);assert.throws(()=>G.queueOrder(s,'aid'),/завершено/);
});
test('40 кампаний по 36 месяцев сохраняют инварианты и конечные ресурсы', () => {
  for(let i=0;i<40;i++){const s=play(`stress-${i}`);G.validateState(s);assert.equal(G.serialize(G.deserialize(G.serialize(s))),G.serialize(s));for(const v of Object.values(s.player))assert.ok(Number.isFinite(v)&&v>=0);}
});
test('все встречи сначала объясняют просьбу и скрывают награды и последствия', () => {
  for (const template of STORIES) {
    const s=G.createGame();s.encounters[0].template=template.id;delete s.encounters[0].choiceOrder;
    const view=G.getView(s).encounters[0];
    assert.ok(view.request.length>35,`Просьба ${template.id}`);
    assert.equal(Object.hasOwn(view,'result'),false);
    for(const c of view.choices){
      assert.doesNotMatch(c.description,/[+−-]\s*\d|\d+\s*%/);
      for(const hidden of ['change','trust','relation','future','aftermath','result'])assert.equal(Object.hasOwn(c,hidden),false,`${template.id}/${c.id}/${hidden}`);
      assert.ok(Number.isInteger(c.gold)&&Number.isInteger(c.food),'Известные затраты остаются видимыми');
    }
  }
});
test('итог встречи показывает фактические изменения с учётом пределов и сохраняется', () => {
  let [s,e]=withStory('doctor');s.player.health=99;s.characters.find(p=>p.id==='doctor').trust=98;
  s=G.resolveEncounter(s,e.id,'supplies');
  const view=G.getView(s).encounters.find(v=>v.id===e.id);
  assert.equal(view.result.changes.gold,-10);assert.equal(view.result.changes.health,1);assert.equal(view.result.trustChange,2);
  assert.match(view.result.narrative,/Лада вернулась/);assert.ok(view.result.narrative.length>100);
  const loaded=G.deserialize(G.serialize(s));assert.deepEqual(G.getView(loaded).encounters.find(v=>v.id===e.id).result,view.result);
  view.result.changes.gold=-999;assert.equal(G.getView(s).encounters.find(v=>v.id===e.id).result.changes.gold,-10);
});
test('дипломатический итог описывает наблюдаемое изменение отношений без раскрытия скрытой оценки', () => {
  let [s,e]=withStory('envoy_guest');s.neighbors.find(n=>n.id==='mer').relation=15;
  s=G.resolveEncounter(s,e.id,'meal');const result=G.getView(s).encounters.find(v=>v.id===e.id).result;
  assert.deepEqual(result.relations,[{id:'mer',name:'Мерсия',before:'Сдержанные',after:'Доброжелательные',direction:'improved'}]);
});
test('будущие встречи не раскрывают название развязки до прибытия вестей', () => {
  let [s,e]=withStory('night_letter');s=G.resolveEncounter(s,e.id,'check');
  const pending=G.getView(s).futureStories[0];assert.doesNotMatch(pending.title,/Кому был нужен заговор/);assert.match(pending.title,/Ожидаются вести/);
  s=turns(s,2);assert.ok(G.getView(s).encounters.some(v=>v.title==='Кому был нужен заговор'));
});
test('сохранения прежней версии 0.4 восстанавливают итог из журнала без выдуманного доверия', () => {
  let [s,e]=withStory('garrison');s=G.resolveEncounter(s,e.id,'pay');const actual=structuredClone(s.encounters.find(v=>v.id===e.id).result.changes);
  delete s.encounters.find(v=>v.id===e.id).result;
  s.history[0].text='Ветеран и слишком новый меч: Оплатить обучение и обещанное жалование.';
  const old=G.deserialize(G.serialize(s)),view=G.getView(old).encounters.find(v=>v.id===e.id);
  assert.equal(view.result.trustChange,null);assert.deepEqual(view.result.changes,actual);
  assert.match(view.title,/Жалование/);assert.match(view.request,/задержанное жалование/);
  old.history=[];const withoutRecord=G.getView(G.deserialize(G.serialize(old))).encounters.find(v=>v.id===e.id);
  assert.equal(withoutRecord.result.changes,null);assert.equal(withoutRecord.result.trustChange,null);
});
test('итог встречи валидируется и не допускается для непринятого решения', () => {
  let [s,e]=withStory('doctor');s=G.resolveEncounter(s,e.id,'supplies');
  const altered=structuredClone(s);altered.encounters.find(v=>v.id===e.id).result.changes.health='8';assert.throws(()=>G.serialize(altered),/итог встречи/);
  const premature=structuredClone(s);premature.encounters.find(v=>v.id===e.id).resolved=false;assert.throws(()=>G.serialize(premature),/итог встречи/);
});
test('совет не раскрывает точные последствия до решения, но журнал фиксирует реальный итог', () => {
  for(const kind of ['border','border_followup','grain','grain_followup']){
    const s=G.createGame();s.pending={kind,target:kind.startsWith('border')?'val':null,secret:kind.startsWith('border')?'bandits':null,created:0,origin:0,approach:kind.startsWith('border')?'investigate':'import'};
    for(const c of G.getView(s).event.choices)assert.doesNotMatch(c.description,/[+−-]\s*\d|\d+\s*%/);
  }
  const s=G.chooseEvent(G.createGame(),'mobilize');assert.equal(s.history[0].changes.gold,-12);assert.equal(s.history[0].changes.defense,8);assert.match(s.history[0].text,/Гарнизон занял новые позиции/);
});
test('семейный конфликт проходит от непроверенной связи через расследование к доказательствам и развязке', () => {
  let [s,e]=withStory('accounts');let scene=G.getView(s).encounters.find(v=>v.id===e.id);
  assert.match(scene.request,/брата Радана Веля/);assert.match(scene.text,/Чья подпись скрывает недостачу, из книг неясно/);assert.match(scene.text,/Остену Риду/);
  s=G.resolveEncounter(s,e.id,'audit');assert.match(s.history[0].reason,/пока не объявили виновным/);
  s=turns(s,2);const follow=s.encounters.find(v=>v.template==='audit_return');scene=G.getView(s).encounters.find(v=>v.id===follow.id);
  assert.match(scene.text,/Арендные записи подтверждают/);assert.match(scene.text,/Писец показал распоряжение/);assert.match(scene.text,/ещё не доказывает, что Радан знал о подлоге/);
  s=G.resolveEncounter(s,follow.id,'trial');const result=G.getView(s).encounters.find(v=>v.id===follow.id).result;
  assert.match(result.narrative,/Суд проверил записи аренды и распоряжение Рида/);assert.equal(result.changes.gold,12);assert.equal(result.changes.food,15);
  const restored=G.deserialize(G.serialize(s));assert.deepEqual(G.getView(restored).encounters.find(v=>v.id===follow.id).result,result);
});
test('десять персонажей имеют отдельные характеры и по две темы без раскрытого ответа', () => {
  const view=G.getView(G.createGame());assert.equal(view.characters.length,10);
  assert.equal(new Set(view.characters.map(p=>p.id)).size,10);
  for(const person of view.characters){
    for(const key of ['bio','temperament','values','blindSpot','personalStake'])assert.ok(person[key].length>30,`${person.id}/${key}`);
    assert.ok(person.ties.length>=2);assert.equal(person.topics.length,2);assert.equal(person.bonus.includes('undefined'),false);
    for(const topic of person.topics){assert.equal(topic.asked,false);assert.equal(Object.hasOwn(topic,'response'),false);}
  }
  assert.ok(STORIES.length>=21);assert.equal(view.conversationNotes.length,0);
});
test('бесплатный разговор доступен без денег, внимания и приказов и не даёт скрытых бонусов', () => {
  const s=G.createGame();s.player.gold=0;s.ap=0;s.attention=0;
  const player=structuredClone(s.player),characters=structuredClone(s.characters),rng=s.rng;
  const after=G.talkToCharacter(s,'citizen','work');
  assert.deepEqual(after.player,player);assert.deepEqual(after.characters,characters);assert.equal(after.rng,rng);assert.equal(after.ap,0);assert.equal(after.attention,0);
  assert.equal(s.conversations.length,0);assert.equal(after.conversations.length,1);assert.equal(after.history[0].kind,'conversation');assert.deepEqual(after.history[0].changes,{});
  const person=G.getView(after).characters.find(p=>p.id==='citizen');assert.equal(person.topics[0].asked,true);assert.ok(person.topics[0].response.length>200);assert.equal(Object.hasOwn(person.topics[1],'response'),false);
  assert.equal(G.getView(after).conversationNotes[0].name,'Эна Рейн');assert.equal(G.validateState(after),true);
});
test('повтор темы перечитывает запись без повторного журнала и изменения состояния', () => {
  const s=G.talkToCharacter(G.createGame(),'merchant','person');const raw=G.serialize(s);
  const again=G.talkToCharacter(s,'merchant','person');assert.equal(G.serialize(again),raw);
  assert.notEqual(again,s);assert.equal(again.conversations.length,1);
});
test('неизвестная тема или собеседник не меняют кампанию', () => {
  const s=G.createGame(),raw=G.serialize(s);assert.throws(()=>G.talkToCharacter(s,'missing','work'),/Неизвестный/);assert.throws(()=>G.talkToCharacter(s,'elder','missing'),/Неизвестный/);assert.equal(G.serialize(s),raw);
});
test('разговор не открывает скрытые сведения соседей и не меняет будущую случайность', () => {
  const initial=G.createGame();const a=turns(initial,2),b=turns(G.talkToCharacter(initial,'envoy','work'),2);
  assert.deepEqual(a.player,b.player);assert.deepEqual(a.neighbors,b.neighbors);assert.equal(a.rng,b.rng);
  const response=G.getView(b).characters.find(p=>p.id==='envoy').topics[0].response;assert.ok(response.includes('догадка'));for(const n of G.getView(b).neighbors)assert.equal(Object.hasOwn(n,'army'),false);
});
test('все двадцать записей разговора сохраняются без изменения игровых ресурсов', () => {
  let s=G.createGame();const before=structuredClone(s.player),rng=s.rng;
  for(const person of G.getView(s).characters)for(const topic of person.topics)s=G.talkToCharacter(s,person.id,topic.id);
  assert.equal(s.conversations.length,20);assert.deepEqual(s.player,before);assert.equal(s.rng,rng);assert.equal(s.attention,2);
  const loaded=G.deserialize(G.serialize(s));assert.deepEqual(loaded,s);assert.equal(G.getView(loaded).conversationNotes.length,20);assert.ok(G.getView(loaded).characters.every(p=>p.topics.every(t=>t.asked&&t.response)));
});
test('старое сохранение с шестью героями дополняется без потери доверия, ресурсов и очереди', () => {
  let s=G.queueOrder(G.createGame(),'school');s.characters.find(p=>p.id==='treasurer').trust=73;
  const originalIds=['treasurer','marshal','doctor','engineer','envoy','governor'];s.characters=s.characters.filter(p=>originalIds.includes(p.id));delete s.conversations;
  const loaded=G.deserialize(JSON.stringify({format:'price-of-power',version:4,state:s}));
  assert.equal(loaded.characters.length,10);assert.equal(loaded.characters.find(p=>p.id==='treasurer').trust,73);assert.deepEqual(loaded.player,s.player);assert.deepEqual(loaded.orders,s.orders);assert.deepEqual(loaded.history,s.history);assert.equal(loaded.rng,s.rng);assert.equal(loaded.nextId,s.nextId);assert.deepEqual(loaded.conversations,[]);
  assert.deepEqual(s.characters.length,6);assert.equal(Object.hasOwn(s,'conversations'),false);G.validateState(loaded);
});
test('повреждённый состав и записи разговоров не маскируются миграцией', () => {
  const mutations=[s=>s.characters.pop(),s=>{s.characters=s.characters.slice(0,6);s.characters[0].id='missing';},s=>s.conversations=null,s=>s.conversations=[{personId:'elder',topicId:'missing',month:0,response:'bad'}],s=>s.conversations=[{personId:'elder',topicId:'work',month:2,response:'bad'}]];
  for(const mutate of mutations){const s=G.createGame();mutate(s);assert.throws(()=>G.deserialize(JSON.stringify({format:'price-of-power',version:4,state:s})));}
  let s=G.talkToCharacter(G.createGame(),'elder','work');s.conversations.push({...s.conversations[0]});assert.throws(()=>G.deserialize(JSON.stringify({format:'price-of-power',version:4,state:s})),/разговоры/);
});
test('каждый новый персонаж появляется в работающей сцене с бесплатным вариантом', () => {
  for(const template of STORIES.filter(t=>['merchant','citizen','captain','elder'].includes(t.person))){
    let s=G.createGame();s.encounters=[{id:s.nextId++,template:template.id,created:0,resolved:false,origin:null}];const encounter=G.getView(s).encounters[0];
    const choice=encounter.choices.find(c=>!c.disabled&&c.gold===0&&c.food===0);assert.ok(choice,template.id);assert.ok(encounter.request.length>40);const gold=s.player.gold;
    s=G.resolveEncounter(s,encounter.id,choice.id);assert.ok(s.player.gold>=gold,`${template.id}: бесплатный выбор не должен списывать золото`);assert.ok(G.getView(s).encounters[0].result.narrative.length>100);G.validateState(s);
  }
});

test('четырнадцать областей законов бесплатны, а гибкие правила меняются немедленно', () => {
  let s=G.createGame(); assert.equal(G.getView(s).lawOptions.length,14);
  const before=s.player.gold; s=G.queueOrder(s,'law_justice_open');
  assert.equal(s.player.gold,before);assert.equal(s.ap,1);assert.equal(s.orders[0].paid,0);assert.equal(s.orders[0].duration,1);
  assert.ok(G.getView(s).commands.filter(c=>c.law).every(c=>c.gold===0));
  s.ap=2;const defense=s.player.defense;s=G.queueOrder(s,'law_conscription_total');assert.equal(s.laws.conscription,'total');assert.equal(s.player.defense,defense+20);assert.equal(s.orders.length,1);
  s=G.queueOrder(s,'law_conscription_retinue');assert.equal(s.player.defense,defense);
});
test('ограничение вывоза сохраняет зерно, не урезая еду жителей и армии', () => {
  const s=G.createGame(), market=G.economy(s);s.laws.grain='reserve';const reserve=G.economy(s);
  assert.equal(market.exports,2);assert.equal(reserve.exports,0);assert.equal(market.consumption,reserve.consumption);
  assert.equal(reserve.food-market.food,2);assert.equal(reserve.income-market.income,-3);
});
test('новые законы меняют фактические здоровье, порядок, производство и содержание', () => {
  const base=G.createGame();
  for(const [key,value] of [['health','municipal'],['justice','open'],['land','commons']]){
    const changed=structuredClone(base);changed.laws[key]=value;
    const a=turns(base,1),b=turns(changed,1);
    if(key==='health'){assert.equal(b.player.health-a.player.health,2);assert.equal(b.player.gold-a.player.gold,-3);}
    if(key==='justice'){assert.equal(b.player.stability-a.player.stability,2);assert.equal(b.player.gold-a.player.gold,-2);}
    if(key==='land'){assert.equal(b.player.food-a.player.food,3);assert.equal(b.player.gold-a.player.gold,-3);assert.equal(b.player.stability-a.player.stability,1);}
    G.validateState(b);
  }
});
test('назначения дают осмысленный компромисс и сохраняются',()=>{
  let s=G.createGame(),before=s.player.gold;s=G.appointOfficial(s,'justice','milan');assert.equal(s.appointments.justice,'milan');assert.equal(s.ap,1);assert.equal(G.economy(s).income,G.economy(G.createGame()).income+2);assert.equal(s.player.gold,before);G.validateState(s);
  assert.throws(()=>G.appointOfficial(s,'justice','milan'),/уже занимает/);
});
test('эпидемия длится несколько месяцев, а службы и врач меняют потери',()=>{
  const weak=G.createGame({seed:'epidemic'}),strong=structuredClone(weak);weak.epidemic={name:'Красная горячка',remaining:3,severity:3};strong.epidemic=structuredClone(weak.epidemic);strong.player.clinics=2;strong.player.sanitation=2;strong.specialists.physicians=3;
  const a=turns(weak,1),b=turns(strong,1);assert.ok(a.epidemic&&a.epidemic.remaining===2);assert.ok(b.player.health>a.player.health);assert.ok(b.player.population>=a.player.population);assert.ok(a.history.some(h=>h.kind==='epidemic'));G.validateState(a);G.validateState(b);
});
test('первая сверхурочная работа даёт дополнительную встречу без внезапной болезни', () => {
  const original=G.createGame(), s=G.workOvertime(original);
  assert.equal(s.attention,3);assert.equal(s.ruler.fatigue,18);assert.equal(s.ruler.health,100);assert.equal(G.getView(s).ruler.ill,false);
  assert.deepEqual(s.player,original.player);assert.equal(s.ap,original.ap);assert.equal(s.rng,original.rng);assert.equal(original.ruler.fatigue,0);
  G.validateState(s);
});
test('после обычного приёма можно продлить работу и принять третьего посетителя', () => {
  let s=rich();for(const e of [...s.encounters].slice(0,2)){const c=G.getView(s).encounters.find(x=>x.id===e.id).choices.find(c=>!c.disabled);s=G.resolveEncounter(s,e.id,c.id);}
  assert.equal(s.attention,0);const third=s.encounters.find(e=>!e.resolved);assert.ok(G.getView(s).encounters.find(e=>e.id===third.id).choices.every(c=>c.disabled));
  s=G.workOvertime(s);const c=G.getView(s).encounters.find(e=>e.id===third.id).choices.find(c=>!c.disabled);assert.ok(c);s=G.resolveEncounter(s,third.id,c.id);assert.equal(s.attention,0);assert.ok(s.encounters.every(e=>e.resolved));
});
function overworked(seed='overtime') {
  let s=G.createGame({seed});
  for(let i=0;i<5&&!G.getView(s).ruler.ill;i++)s=G.workOvertime(s);
  return s;
}
test('предупреждения появляются до болезни, а игнорирование может остановить приём', () => {
  let s=G.createGame();s=G.workOvertime(s);s=G.workOvertime(s);assert.equal(s.ruler.fatigue,40);assert.match(G.getView(s).ruler.warning,/устал|отдохнуть/i);
  s=G.workOvertime(s);assert.equal(s.ruler.fatigue,66);assert.match(G.getView(s).ruler.warning,/опасн|болезн/i);assert.equal(G.getView(s).ruler.ill,false);
  for(let i=0;i<2&&!G.getView(s).ruler.ill;i++)s=G.workOvertime(s);
  assert.equal(G.getView(s).ruler.ill,true);assert.equal(s.attention,0);assert.equal(s.ruler.illUntil,2);assert.ok(s.ruler.health<=45);assert.equal(G.getView(s).ruler.canOvertime,false);
});
test('во время болезни приём и новые разговоры закрыты, а прежние заметки можно перечитать', () => {
  let s=G.createGame();const p=G.getView(s).characters[0],topic=p.topics[0],other=p.topics[1];s=G.talkToCharacter(s,p.id,topic.id);
  for(let i=0;i<5&&!G.getView(s).ruler.ill;i++)s=G.workOvertime(s);
  assert.throws(()=>G.workOvertime(s),/болен/);assert.throws(()=>G.talkToCharacter(s,p.id,other.id),/отдых|выздоровлен/);
  const encounter=G.getView(s).encounters[0];assert.ok(encounter.choices.every(c=>c.disabled));assert.throws(()=>G.resolveEncounter(s,encounter.id,encounter.choices[0].id),/болен/);
  assert.deepEqual(G.talkToCharacter(s,p.id,topic.id),s);assert.equal(G.getView(s).characters[0].topics[1].disabled,true);
});
test('отдых отнимает оставшийся приём, сохраняет государственные поручения и не фармится', () => {
  let s=G.workOvertime(G.createGame());s=G.workOvertime(s);const ap=s.ap,player=structuredClone(s.player);s=G.restRuler(s);
  assert.equal(s.attention,0);assert.equal(s.ap,ap);assert.deepEqual(s.player,player);assert.equal(s.ruler.fatigue,10);assert.throws(()=>G.restRuler(s),/уже/);assert.equal(G.getView(s).ruler.canRest,false);
});
test('болезнь не блокирует дела совета и завершается через два месяца отдыха', () => {
  let s=overworked();assert.ok(s.pending);s=council(s);s=G.advanceMonth(s);assert.equal(G.getView(s).ruler.ill,true);assert.equal(s.attention,0);
  s=G.advanceMonth(council(s));assert.equal(s.month,2);assert.equal(G.getView(s).ruler.ill,false);assert.equal(s.attention,2);assert.ok(s.history.some(h=>h.text.includes('выздоровел')));G.validateState(s);
});
test('переутомление воспроизводимо, переносится между месяцами и сохраняется', () => {
  const a=overworked('same-ruler'),b=overworked('same-ruler');assert.equal(G.serialize(a),G.serialize(b));const restored=G.deserialize(G.serialize(a));assert.deepEqual(restored.ruler,a.ruler);assert.equal(G.serialize(turns(restored,2)),G.serialize(turns(a,2)));
  const once=turns(G.workOvertime(G.createGame()),1);assert.equal(once.ruler.fatigue,6);assert.equal(once.ruler.overtimeThisMonth,0);
});
test('сохранения 0.5 дополняются законами и здоровьем правителя без изменения случайности', () => {
  const s=G.createGame();s.characters=s.characters.slice(0,6);delete s.conversations;delete s.ruler;delete s.laws.health;delete s.laws.justice;delete s.laws.land;
  const rng=s.rng,player=structuredClone(s.player);const restored=G.deserialize(JSON.stringify({format:'price-of-power',version:4,state:s}));
  assert.equal(restored.rng,rng);assert.deepEqual(restored.player,player);assert.equal(restored.ruler.fatigue,0);assert.equal(restored.laws.health,'household');assert.equal(restored.characters.length,10);
  const broken=G.createGame();broken.ruler.fatigue=-1;assert.throws(()=>G.deserialize(JSON.stringify({format:'price-of-power',version:4,state:broken})),/здоровье правителя/);
});

test('слабое княжество может стать целью самостоятельного давления после наблюдения', () => {
  let s=turns(G.createGame({seed:'weak-frontier'}),3);s=council(s);s.player.army=8;require('../source/military').syncArmy(s);
  const n=s.neighbors.find(n=>n.id==='nor');n.army=110;n.gold=100;n.relation=0;n.beliefs.player={army:6,defense:15,month:s.month};
  assert.equal(G.decideNeighbor(n).target,'player');assert.equal(G.decideNeighbor(n).action,'raid');
  const before=s.player.army;s=G.advanceMonth(s);assert.ok(s.military.enemyMarches.some(m=>m.attackerId==='nor'));assert.equal(s.player.army,before);assert.ok(s.military.enemyMarches.find(m=>m.attackerId==='nor').remaining>=2);
});
test('ИИ уважает сильную защиту, тёплые отношения и действующий договор', () => {
  const n=G.createGame().neighbors.find(n=>n.id==='nor');n.turns=5;n.gold=100;n.army=110;n.relation=80;n.beliefs.player={army:5,defense:5,month:5};assert.notEqual(G.decideNeighbor(n).target,'player');
  n.relation=0;n.pactUntil=10;assert.notEqual(G.decideNeighbor(n).target,'player');n.pactUntil=0;n.beliefs.player.defense=200;assert.notEqual(G.decideNeighbor(n).target,'player');
});
test('военная цель соседей растёт вслед за предполагаемой силой игрока в рамках бюджета', () => {
  const n=G.createGame().neighbors.find(n=>n.id==='nor');n.army=125;n.gold=100;n.relation=80;n.beliefs.player={army:500,defense:100,month:0};assert.equal(G.decideNeighbor(n).action,'train');n.gold=5;assert.equal(G.decideNeighbor(n).action,'trade');
});
test('порядок новых решений воспроизводим и не делает левую карточку постоянной', () => {
  const orders=new Set();for(let i=0;i<12;i++){const s=G.createGame({seed:`choice-${i}`});orders.add(s.pending.choiceOrder.join(','));assert.deepEqual(G.getView(s).event.choices.map(c=>c.id),s.pending.choiceOrder);for(const e of G.getView(s).encounters)assert.deepEqual(e.choices.map(c=>c.id),s.encounters.find(x=>x.id===e.id).choiceOrder);}
  assert.ok(orders.size>=3);
  const s=G.createGame(),raw=G.serialize(s);for(let i=0;i<10;i++)G.getView(s);assert.equal(G.serialize(s),raw);assert.equal(G.serialize(G.deserialize(raw)),raw);
});
test('старый порядок карточек сохраняется, а повреждённый явный порядок отклоняется', () => {
  const s=G.createGame();delete s.pending.choiceOrder;for(const e of s.encounters)delete e.choiceOrder;
  const loaded=G.deserialize(G.serialize(s));assert.deepEqual(G.getView(loaded).event.choices.map(c=>c.id),['investigate','mobilize','wait']);
  loaded.pending.choiceOrder=['investigate','investigate','wait'];assert.throws(()=>G.serialize(loaded),/порядок решений/);
});
test('поход использует приказ и реальный провиант, снимая походные части с домашнего довольствия', () => {
  const s=G.createGame(),before=G.serialize(s),q=G.militaryQuote(s,{target:'forest',mission:'expedition',supply:'normal'});assert.equal(q.canLaunch,true);assert.equal(q.duration,2);assert.equal(G.serialize(s),before);
  const launched=G.launchMilitary(s,{target:'forest',mission:'expedition',supply:'normal'});assert.equal(launched.ap,1);assert.equal(launched.player.food,s.player.food-q.food);assert.equal(launched.military.marches.length,1);assert.equal(G.economy(launched).consumption,7);assert.ok(G.economy(s).consumption>G.economy(launched).consumption);G.validateState(launched);
});
test('военная экспедиция доходит до реального боя, который сохраняется и требует решения', () => {
  let s=G.launchMilitary(G.createGame(),{target:'forest',mission:'expedition',supply:'normal'});s=turns(s,1);assert.equal(G.getView(s).military.battle,null);s=G.advanceMonth(council(s));assert.ok(G.getView(s).military.battle);assert.throws(()=>G.advanceMonth(s),/столкновение/);
  const restored=G.deserialize(G.serialize(s));assert.deepEqual(restored.military,s.military);const start=s.player.army;s=G.battleOrder(s,'withdraw');assert.ok(s.player.army<start);assert.equal(s.military.lastBattle.outcome,'retreat');assert.ok(s.military.marches.some(m=>m.mission==='return'));G.validateState(s);
});
test('старые сохранения получают войска без изменения уже имеющейся армии и ресурсов', () => {
  const s=G.createGame();delete s.military;const player=structuredClone(s.player),rng=s.rng;const loaded=G.deserialize(JSON.stringify({format:'price-of-power',version:4,state:s}));assert.deepEqual(loaded.player,player);assert.equal(loaded.rng,rng);assert.equal(loaded.military.units.reduce((n,u)=>n+u.strength,loaded.military.reserve),player.army);G.validateState(loaded);
});
