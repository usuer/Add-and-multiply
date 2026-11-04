'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const {chromium} = require('playwright');
const G = require('../source/core');
const root = path.resolve(__dirname, '..');
const artifacts = path.join(root, 'artifacts');
fs.mkdirSync(artifacts, {recursive:true});
let passed = 0;
async function check(name, run) { await run(); passed++; console.log('PASS ' + name); }
function rich(seed='v06-browser') {
  const state = G.createGame({seed});
  for(const values of [state.player,state.initial,state.monthStart,state.metrics[0].values]) {
    values.gold=1500; values.food=300;
  }
  return state;
}
async function closeIntro(page) { const dialog=page.locator('#prologue-dialog');if(await dialog.count()&&await dialog.isVisible())await page.locator('#prologue-dialog [data-action="intro-skip"]').click(); }
async function saved(page) { return page.evaluate(()=>JSON.parse(localStorage.getItem('priceOfPower.v04.auto')).state); }
async function load(page, state) {
  await page.locator('#save-file').setInputFiles({name:'fixture.json',mimeType:'application/json',buffer:Buffer.from(G.serialize(state))});
  await page.waitForFunction(seed=>JSON.parse(localStorage.getItem('priceOfPower.v04.auto'))?.state.seed===seed,state.seed);
  await page.waitForSelector('#realm-home:not([hidden])');
}
async function advance(page) {
  if(await page.locator('#chapter-dialog').isVisible()) await page.click('#continue-chapter');
  await page.click('nav [data-tab="council"]');
  const options=page.locator('#council-event [data-choice]:not([disabled])');
  if(await options.count()) {
    let chosen=false;
    for(const id of ['wait','talk','fair','ration','investigate']) {
      const option=page.locator(`#council-event [data-choice="${id}"]:not([disabled])`);
      if(await option.count()){await option.click();chosen=true;break;}
    }
    if(!chosen)await options.first().click();
  }
  assert.equal(await page.locator('#next-month').isEnabled(),true,'month can progress');
  const oldDate=await page.locator('#date').innerText();await page.click('#next-month');
  await page.waitForFunction(previous=>document.querySelector('#date').textContent!==previous,oldDate);
  await page.locator('#month-transition [data-action="close-month"]').click();
  await page.waitForFunction(()=>!document.documentElement.hasAttribute('aria-busy'));
}

(async()=>{
  const server=http.createServer((req,res)=>{
    let file;
    try { file=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname)); }
    catch { res.writeHead(400);res.end();return; }
    if(req.url==='/favicon.ico'){res.writeHead(204);res.end();return;}
    if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
    fs.readFile(file,(error,data)=>{
      if(error){res.writeHead(404);res.end();return;}
      const mime={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.webp':'image/webp','.jpg':'image/jpeg','.svg':'image/svg+xml'}[path.extname(file)]||'application/octet-stream';
      res.writeHead(200,{'Content-Type':mime,'Cache-Control':'no-store'});res.end(data);
    });
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const origin=`http://127.0.0.1:${server.address().port}`;
  let browser;
  try {
    browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||(fs.existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),headless:true,args:['--no-sandbox']});
    const context=await browser.newContext({viewport:{width:1440,height:1080},acceptDownloads:true});
    const page=await context.newPage(), errors=[], external=[];
    page.on('pageerror',error=>errors.push(error.message));
    page.on('request',req=>{if(/^https?:/.test(req.url())&&!req.url().startsWith(origin+'/'))external.push(req.url());});
    await page.goto(origin+'/dist/price-of-power.html');await closeIntro(page);
    await page.waitForSelector('#realm-home:not([hidden])');

    await check('звук можно выключить, и выбор сохраняется после перезагрузки',async()=>{
      const button=page.locator('#sound-toggle');const original=await button.getAttribute('aria-pressed');
      assert.ok(['true','false'].includes(original));await button.click();const changed=await button.getAttribute('aria-pressed');assert.notEqual(changed,original);
      await page.reload();await closeIntro(page);assert.equal(await page.locator('#sound-toggle').getAttribute('aria-pressed'),changed);
      await page.locator('#sound-toggle').click();assert.equal(await page.locator('#sound-toggle').getAttribute('aria-pressed'),original);
    });

    await check('сохранение 0.5 получает новых людей и системы без потери ресурсов',async()=>{
      const old=rich('legacy-browser'), originalIds=['treasurer','marshal','doctor','engineer','envoy','governor'];
      old.characters=old.characters.filter(p=>originalIds.includes(p.id));
      delete old.conversations;delete old.ruler;delete old.military;
      for(const key of ['health','justice','land'])delete old.laws[key];
      const rng=old.rng, player=structuredClone(old.player);
      const payload=JSON.stringify({format:'price-of-power',version:4,state:old});
      await page.locator('#save-file').setInputFiles({name:'legacy-05.json',mimeType:'application/json',buffer:Buffer.from(payload)});
      await page.waitForFunction(()=>JSON.parse(localStorage.getItem('priceOfPower.v04.auto'))?.state.seed==='legacy-browser');
      const after=await saved(page);assert.equal(after.characters.length,10);assert.equal(after.rng,rng);assert.deepEqual(after.player,player);assert.ok(after.ruler);assert.ok(after.military);assert.equal(Object.keys(after.laws).length,14);
      await page.click('nav [data-tab="court"]');assert.equal(await page.locator('#characters .person-card').count(),10);
    });

    await check('бесплатный разговор открывает сведения, не расходуя ресурсы или внимание',async()=>{
      await load(page,rich('free-talk'));
      const before=await saved(page);await page.click('nav [data-tab="court"]');await page.click('[data-chat="merchant"]');
      assert.equal(await page.locator('#chat-dialog').isVisible(),true);
      const topic=page.locator('#chat-dialog [data-talk-person="merchant"]').first();const topicId=await topic.getAttribute('data-talk-topic');
      await topic.click();await page.waitForFunction(()=>JSON.parse(localStorage.getItem('priceOfPower.v04.auto')).state.conversations.length===1);
      assert.ok((await page.locator('#chat-reply').innerText()).trim().length>80);
      const after=await saved(page);assert.deepEqual(after.player,before.player);assert.equal(after.ap,before.ap);assert.equal(after.attention,before.attention);assert.equal(after.rng,before.rng);assert.deepEqual(after.characters,before.characters);assert.equal(after.history.length,before.history.length+1);
      await page.screenshot({path:path.join(artifacts,'free-conversation.png'),fullPage:true});
      await page.locator(`#chat-dialog [data-talk-topic="${topicId}"]`).click();assert.deepEqual(await saved(page),after);
      await page.locator('#chat-dialog [data-action="close-chat"]').click();
      await page.click('.topbar [data-action="save"]');await load(page,rich('other-game'));await page.click('.topbar [data-action="load"]');
      await page.click('nav [data-tab="court"]');await page.click('[data-chat="merchant"]');await page.locator(`#chat-dialog [data-talk-topic="${topicId}"]`).click();assert.ok((await page.locator('#chat-reply').innerText()).length>80);assert.equal((await saved(page)).conversations.length,1);await page.locator('#chat-dialog [data-action="close-chat"]').click();
    });

    await check('десять персонажей имеют разные иллюстрированные аватары',async()=>{
      await page.click('nav [data-tab="court"]');
      const portraits=await page.evaluate(async()=>{
        const nodes=[...document.querySelectorAll('#characters .portrait')];
        const styles=nodes.map(n=>getComputedStyle(n));
        const sources=[...new Set(styles.map(s=>s.backgroundImage.match(/url\((['"]?)(.*?)\1\)/)?.[2]))];
        const dimensions=await Promise.all(sources.map(async src=>{const img=new Image();img.src=src;await img.decode();return img.naturalWidth;}));
        return {count:nodes.length,unique:new Set(styles.map(s=>s.backgroundImage+'|'+s.backgroundPosition)).size,embedded:sources.every(s=>/^(?:data:image\/|blob:)/.test(s)),dimensions};
      });
      assert.equal(portraits.count,10);assert.equal(portraits.unique,10);assert.ok(portraits.embedded);assert.ok(portraits.dimensions.every(w=>w>500));
    });

    await check('карта показывает восемь разных проектов и позволяет начать строительство',async()=>{
      await load(page,rich('map-browser'));await page.click('nav [data-tab="development"]');
      assert.equal(await page.locator('#town [data-building-select]').count(),8);
      await page.waitForFunction(()=>{const img=document.querySelector('#town img');return img?.complete&&img.naturalWidth>1000;});
      const positions=await page.locator('#buildings .development-building-picture .development-art').evaluateAll(nodes=>nodes.map(n=>getComputedStyle(n).backgroundPosition));
      assert.equal(positions.length,22);assert.ok(new Set(positions).size>=8);
      await page.locator('#town [data-building-select="granaries"]').click();assert.equal(await page.locator('#development-dialog').isVisible(),true);assert.match(await page.locator('#development-dialog').innerText(),/Зернохранилища/);
      const before=await saved(page),cost=G.getView(before).commands.find(c=>c.id==='granary').gold;await page.locator('#development-dialog [data-order="granary"]').click();assert.equal(await page.locator('#development-dialog').isVisible(),false);
      const after=await saved(page);assert.equal(after.orders.length,1);assert.equal(after.orders[0].type,'granary');assert.equal(after.player.gold,before.player.gold-cost);assert.match(await page.locator('#town [data-building-select="granaries"]').innerText(),/Строится|Строитель|Улучшение/);
      await page.screenshot({path:path.join(artifacts,'development-map-v06.png'),fullPage:true});
    });

    await check('ограничение вывоза принимается без платы и не уменьшает еду жителей',async()=>{
      await load(page,rich('grain-policy'));await page.click('nav [data-tab="development"]');await page.click('[data-development-view="laws"]');assert.equal(await page.locator('#laws .law-card').count(),14);
      assert.match(await page.locator('#laws').innerText(),/Потребление жителей и армии не меняется|Жители и армия продолжают есть/);
      const before=await saved(page);await page.locator('#laws [data-order="law_grain_reserve"]').click();const queued=await saved(page);assert.equal(queued.player.gold,before.player.gold);assert.equal(queued.ap,before.ap-1);assert.equal(queued.orders[0].paid,0);
      await advance(page);const after=await saved(page);assert.equal(after.laws.grain,'reserve');
      const market=structuredClone(after);market.laws.grain='market';const actual=G.economy(after),comparison=G.economy(market);
      assert.equal(actual.consumption,comparison.consumption);assert.equal(actual.exports,0);assert.equal(comparison.exports,2);assert.equal(actual.income,comparison.income-3);assert.equal(actual.food,comparison.food+2);assert.match(await page.locator('#policy-budget').innerText(),/вывоз/i);
    });

    await check('новая санитарная политика реально меняет здоровье и содержание',async()=>{
      const start=rich('health-policy');const budget=G.economy(start);await load(page,start);await page.click('nav [data-tab="development"]');await page.click('[data-development-view="laws"]');await page.locator('#laws [data-order="law_health_municipal"]').click();await advance(page);
      const after=await saved(page);assert.equal(after.laws.health,'municipal');assert.equal(after.player.health,start.player.health+3);assert.equal(G.economy(after).upkeep,budget.upkeep+3);
    });

    await check('быстрое двойное нажатие завершает ровно один месяц и показывает переход',async()=>{
      await load(page,rich('double-turn'));await page.click('nav [data-tab="council"]');
      await page.locator('#council-event [data-choice="wait"]').click();const before=await saved(page);
      await page.locator('#next-month').dblclick({delay:30});assert.equal(await page.locator('#month-transition').isVisible(),true);
      await page.locator('#month-transition [data-action="close-month"]').click();await page.waitForFunction(()=>!document.documentElement.hasAttribute('aria-busy'));
      const after=await saved(page);assert.equal(after.month,before.month+1);assert.equal(await page.locator('#month-transition').isVisible(),false);
    });

    await check('сверхурочная работа даёт дополнительный приём и предупреждает об усталости',async()=>{
      await load(page,rich('overtime-browser'));await page.click('nav [data-tab="court"]');await page.locator('details.ruler-fold > summary').click();const before=await saved(page);
      assert.equal(await page.locator('#ruler-status').isVisible(),true);await page.click('[data-action="overtime"]');const after=await saved(page);
      assert.equal(after.attention,before.attention+1);assert.ok(after.ruler.fatigue>before.ruler.fatigue);assert.equal(after.ruler.health<=before.ruler.health,true);assert.equal(G.getView(after).ruler.ill,false);assert.equal(after.player.gold,before.player.gold);
      assert.match(await page.locator('#ruler-status').innerText(),/устал|здоров|переработ|переутом/i);
      await page.screenshot({path:path.join(artifacts,'ruler-overtime.png'),fullPage:true});
      const fatigue=after.ruler.fatigue;await page.click('[data-action="rest-ruler"]');const rested=await saved(page);assert.ok(rested.ruler.fatigue<fatigue);assert.equal(rested.attention,0);
    });

    await check('игнорирование предупреждений приводит к болезни и временному прекращению приёмов',async()=>{
      let fixture;
      for(let i=0;i<100&&!fixture;i++){
        let state=rich('illness-'+i);
        for(let step=0;step<8;step++){
          const view=G.getView(state).ruler;if(!view.canOvertime)break;
          const before=state;state=G.workOvertime(state);
          if(G.getView(state).ruler.ill){fixture=before;break;}
        }
      }
      assert.ok(fixture,'seeded overwork can cause illness');await load(page,fixture);await page.click('nav [data-tab="court"]');if(!await page.locator('#ruler-status').isVisible())await page.locator('details.ruler-fold > summary').click();assert.match(await page.locator('#ruler-status').innerText(),/риск|опас|предупреж|отдых|истощ|болез/i);
      await page.click('[data-action="overtime"]');let after=await saved(page);assert.ok(G.getView(after).ruler.ill);assert.equal(after.attention,0);assert.equal(await page.locator('[data-action="overtime"]').isDisabled(),true);
      const storyButton=page.locator('#encounters [data-scene]').first();await storyButton.click();assert.equal(await page.locator('#scene-dialog [data-story-choice]:not([disabled])').count(),0);await page.click('[data-action="close-scene"]');
      await page.click('[data-chat="merchant"]');assert.equal(await page.locator('#chat-dialog [data-talk-topic]:not([disabled])').count(),0);await page.locator('#chat-dialog [data-action="close-chat"]').click();
      await page.screenshot({path:path.join(artifacts,'ruler-illness.png'),fullPage:true});
      for(let i=0;i<6&&G.getView(after).ruler.ill;i++){await advance(page);after=await saved(page);}
      assert.equal(G.getView(after).ruler.ill,false);assert.ok(after.attention>0);
    });

    await check('армия действительно идёт к лагерю бандитов и расходует походный провиант',async()=>{
      await load(page,rich('military-browser'));await page.click('nav [data-tab="army"]');assert.equal(await page.locator('#military-content').isVisible(),true);
      const before=await saved(page);const initial=G.getView(before).military;assert.equal(initial.units.length,3);assert.equal(initial.locations.length,6);
      await page.selectOption('#military-target','forest');await page.selectOption('#military-mission','expedition');await page.selectOption('#military-supply','full');
      assert.ok((await page.locator('#military-quote').innerText()).trim().length>15);await page.click('#military-launch');const moving=await saved(page);const view=G.getView(moving).military;
      assert.equal(view.marches.length,1);assert.equal(view.marches[0].target,'forest');assert.ok(view.marches[0].remaining>=1);assert.equal(view.battle,null);assert.ok(moving.player.food<before.player.food);assert.ok(view.marches[0].unitIds.length>0);assert.ok(view.units.filter(u=>view.marches[0].unitIds.includes(u.id)).every(u=>u.status==='marching'));
      assert.match(await page.locator('#military-marches').innerText(),/лес|Лес|бандит/i);await page.screenshot({path:path.join(artifacts,'army-march.png'),fullPage:true});
      let battleState=moving;
      for(let i=0;i<6&&!G.getView(battleState).military.battle;i++){await advance(page);battleState=await saved(page);}
      assert.ok(G.getView(battleState).military.battle,'expedition arrives at an actual battle');
      await page.click('nav [data-tab="army"]');assert.equal(await page.locator('#military-alert').isVisible(),true);await page.click('[data-battle-focus]');await page.waitForTimeout(80);assert.ok((await page.locator('#battle-area').boundingBox()).y<130);
      if(!await page.locator('#battle-area').isVisible())await page.click('nav [data-tab="army"]');assert.equal(await page.locator('#battle-area').isVisible(),true);assert.ok(await page.locator('#battle-area [data-battle-tactic]').count()>=3);assert.ok(await page.locator('#battle-area .unit-formation').count()>=8);assert.ok(await page.locator('#battle-area .battle-object').count()>=6);assert.equal(await page.locator('#battle-area .enemy-token').count(),5);assert.equal(await page.locator('#battle-unit option').count(),3);assert.equal(await page.locator('#battle-target option').count(),5);assert.match(await page.locator('.unit-profile').innerText(),/Атака.*Броня.*Дальность.*Скорость.*Ближний бой/is);assert.deepEqual((await page.locator('#battle-area [data-battle-tactic]').evaluateAll(nodes=>nodes.map(n=>n.dataset.battleTactic).sort())),['advance','guard','withdraw']);assert.equal(await page.locator('.battle-grid-overlay line').count(),1);
      await page.screenshot({path:path.join(artifacts,'battlefield-v06.png'),fullPage:true});
      await page.selectOption('#battle-unit','archers');assert.deepEqual((await page.locator('#battle-area [data-battle-tactic]').evaluateAll(nodes=>nodes.map(n=>n.dataset.battleTactic).sort())),['fallback','melee','ranged','withdraw']);await page.selectOption('#battle-target','enemy-ranged');const command=page.locator('#battle-area [data-battle-tactic="ranged"]');await command.click();const phase=await saved(page);assert.notDeepEqual(phase.military,battleState.military);assert.equal(await page.locator('.combat-effect.volley i').count(),9);assert.match(await page.locator('.battle-action-result').innerText(),/Стрелки перевала.*Стрелки в укрытии.*Наши потери.*Потери врага/is);const lines=await page.locator('#battle-area .battle-token').evaluateAll(nodes=>nodes.map(n=>({enemy:n.classList.contains('enemy-token'),top:parseFloat(n.style.top)})));assert.ok(Math.max(...lines.filter(x=>x.enemy).map(x=>x.top))<Math.min(...lines.filter(x=>!x.enemy).map(x=>x.top)),'боевые линии не проходят друг сквозь друга');
      if(G.getView(phase).military.battle)await page.click('#battle-area [data-battle-tactic="withdraw"]');
      const outcome=await saved(page);assert.equal(G.getView(outcome).military.battle,null);assert.ok(G.getView(outcome).military.lastBattle);assert.ok(outcome.player.army<=battleState.player.army);assert.equal(await page.locator('#military-result').isVisible(),true);
    });

    await check('новые страницы и диалоги доступны на мобильном экране',async()=>{
      await load(page,rich('mobile-v06'));await page.setViewportSize({width:390,height:844});
      for(const tab of ['court','development','army']){await page.click(`nav [data-tab="${tab}"]`);assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'mobile '+tab);}
      await page.click('nav [data-tab="development"]');await page.locator('#town [data-building-select="schools"]').click();assert.equal(await page.locator('#development-dialog').isVisible(),true);await page.screenshot({path:path.join(artifacts,'building-mobile-v06.png'),fullPage:true});await page.locator('#development-dialog [data-development-close]').first().click();
      await page.click('nav [data-tab="court"]');await page.click('[data-chat="citizen"]');assert.equal(await page.locator('#chat-dialog').isVisible(),true);await page.screenshot({path:path.join(artifacts,'conversation-mobile-v06.png'),fullPage:true});await page.locator('#chat-dialog [data-action="close-chat"]').click();
    });

    await check('три экрана вступления читаются и закрываются на телефоне',async()=>{
      await page.click('.topbar [data-action="new"]');await page.fill('#world-seed','mobile-introduction');await page.locator('#new-game-form button[type="submit"]').click();
      const dialog=page.locator('#prologue-dialog');assert.equal(await dialog.isVisible(),true);
      for(let step=1;step<=3;step++){
        assert.match(await page.locator('#prologue-dialog .prologue-dots').innerText(),new RegExp(step+' / 3'));
        assert.ok((await page.locator('#prologue-dialog h1').innerText()).length>5);
        await page.locator('#prologue-dialog [data-action="intro-next"]').click();
      }
      assert.equal(await dialog.isVisible(),false);assert.equal(await page.locator('#realm-home').isVisible(),true);
    });

    await check('новая сборка не делает внешних запросов и не вызывает ошибок JavaScript',async()=>{
      assert.deepEqual(errors,[]);assert.deepEqual(external,[]);
      const offline=await context.newPage(), offlineErrors=[], requests=[];offline.on('pageerror',e=>offlineErrors.push(e.message));offline.on('request',r=>{if(/^https?:/.test(r.url()))requests.push(r.url());});
      await offline.setContent(fs.readFileSync(path.join(root,'dist','price-of-power.html'),'utf8'));await closeIntro(offline);await offline.click('nav [data-tab="development"]');await offline.waitForFunction(()=>document.querySelector('#town img')?.naturalWidth>1000);await offline.click('nav [data-tab="army"]');assert.equal(await offline.locator('#military-content').isVisible(),true);assert.deepEqual(offlineErrors,[]);assert.deepEqual(requests,[]);await offline.close();
    });
    console.log(`${passed} v0.6 browser checks passed; 0 skipped.`);
  } finally { if(browser)await browser.close();await new Promise(resolve=>server.close(resolve)); }
})().catch(error=>{console.error(error);process.exitCode=1;});
