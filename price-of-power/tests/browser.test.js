'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { chromium } = require('playwright');
const G = require('../source/core');
const root = path.resolve(__dirname, '..');
const artifacts = path.join(root, 'artifacts');
fs.mkdirSync(artifacts, {recursive:true});
let passed = 0;
async function check(name, fn) { await fn(); passed++; console.log(`PASS ${name}`); }
async function closeIntro(page, walk = false) {
  const dialog=page.locator('#prologue-dialog');
  if(await dialog.count() && await dialog.isVisible()) {
    if(walk) {
      for(let step=1;step<=3;step++) {
        assert.match(await page.locator('#prologue-dialog .prologue-dots').innerText(),new RegExp(step+' / 3'));
        assert.ok((await page.locator('#prologue-dialog h1').innerText()).trim().length>5);
        await page.locator('#prologue-dialog [data-action="intro-next"]').click();
      }
    } else await page.locator('#prologue-dialog [data-action="intro-skip"]').click();
    assert.equal(await dialog.isVisible(),false);
  }
}
async function nextMonth(page) {
  const before=await page.locator('#date').innerText();await page.click('#next-month');
  await page.waitForFunction(previous=>document.querySelector('#date').textContent!==previous,before);
  await page.locator('#month-transition [data-action="close-month"]').click();
  await page.waitForFunction(()=>!document.documentElement.hasAttribute('aria-busy'));
}
async function artworkLoaded(page) {
  await page.waitForFunction(() => {
    const pictures = [...document.querySelectorAll('#realm-home img')];
    return pictures.length > 0 && pictures.every(img => img.complete && img.naturalWidth > 300 && img.naturalHeight > 100);
  });
  assert.ok((await page.locator('#realm-home img').first().getAttribute('alt')).trim().length > 5);
}

(async () => {
  // Локальный HTTP нужен только тестовому браузеру: корпоративная политика Chromium
  // в cloud запрещает file://. Готовый HTML не делает запросов и не требует сервера.
  const server = http.createServer((req,res) => {
    const url = new URL(req.url, 'http://localhost');
    if (url.pathname === '/favicon.ico') { res.writeHead(204); res.end(); return; }
    let pathname;
    try { pathname = path.resolve(root, '.' + decodeURIComponent(url.pathname)); } catch { res.writeHead(400); res.end(); return; }
    if (!pathname.startsWith(root + path.sep)) { res.writeHead(403); res.end(); return; }
    fs.readFile(pathname, (error, data) => {
      if (error) { res.writeHead(404); res.end(); return; }
      const mime = {'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.webp':'image/webp','.jpg':'image/jpeg','.svg':'image/svg+xml'}[path.extname(pathname)] || 'application/octet-stream';
      res.writeHead(200, {'Content-Type':mime, 'Cache-Control':'no-store'});res.end(data);
    });
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = `http://127.0.0.1:${server.address().port}`;
  let browser;
  try {
    browser = await chromium.launch({executablePath:process.env.CHROMIUM_PATH || (fs.existsSync('/usr/bin/chromium') ? '/usr/bin/chromium' : undefined),headless:true,args:['--no-sandbox']});
    const context = await browser.newContext({viewport:{width:1440,height:1080},acceptDownloads:true});
    const page = await context.newPage();
    const errors = [], externalRequests = [];
    page.on('pageerror',e=>errors.push(e.message));
    page.on('request',req=>{if(/^https?:/.test(req.url()) && !req.url().startsWith(origin+'/')) externalRequests.push(req.url());});
    await check('модульная версия встречает историей и описанием государства',async()=>{
      await page.goto(origin+'/source/index.html');await closeIntro(page,true);await page.waitForSelector('[data-page="home"]:not([hidden])');await artworkLoaded(page);assert.equal((await page.locator('#realm-title').innerText()).replace(/\s+/g,' ').trim(),'Арденское княжество');assert.equal(await page.locator('#date').innerText(),'Январь 1248');assert.ok((await page.locator('#realm-home').innerText()).length>350);assert.ok((await page.locator('#home-scenario').innerText()).length>50);assert.match(await page.locator('#enter-reign').innerText(),/Вступить/);assert.equal(await page.locator('#next-month').isVisible(),false);await page.click('#enter-reign');assert.equal(await page.locator('[data-page="council"]').isVisible(),true);assert.equal(await page.locator('#encounter-preview button').count(),3);
    });
    await check('однофайловая версия открывает главный экран и позволяет вступить в правление',async()=>{
      await page.evaluate(()=>localStorage.clear());await page.goto(origin+'/dist/price-of-power.html');await closeIntro(page);await page.waitForSelector('[data-page="home"]:not([hidden])');await artworkLoaded(page);assert.match(await page.locator('#realm-home img').first().getAttribute('src'),/^(?:data:image\/|blob:)/);assert.equal(await page.locator('[data-stat="gold"] .stat-value').innerText(),'110');assert.equal(await page.locator('nav [data-tab="home"]').getAttribute('aria-current'),'page');assert.deepEqual(errors,[]);await page.screenshot({path:path.join(artifacts,'home.png'),fullPage:true});await page.click('#enter-reign');await page.waitForSelector('#council-event .choice');await page.screenshot({path:path.join(artifacts,'desktop.png'),fullPage:true});
    });
    await check('просьба воеводы понятна, а характеры десяти людей раскрываются в профилях',async()=>{
      let originalState = G.createGame();
      if (!originalState.encounters.some(e => e.template === 'garrison')) {
        let fixture;
        for (let i=0;i<100 && !fixture;i++) { const candidate=G.createGame({seed:'garrison-'+i}); if(candidate.encounters.some(e=>e.template==='garrison')) fixture=candidate; }
        assert.ok(fixture, 'seed with garrison scene');
        await page.locator('#save-file').setInputFiles({name:'garrison.json',mimeType:'application/json',buffer:Buffer.from(G.serialize(fixture))});
        await page.waitForFunction(seed=>JSON.parse(localStorage.getItem('priceOfPower.v04.auto')).state.seed===seed,fixture.seed);
      }
      await page.click('nav [data-tab="court"]');
      const drill=page.locator('#encounters .story-card').filter({hasText:'Жалование и подготовка дружины'});
      assert.equal(await drill.count(),1);await drill.locator('[data-scene]').click();
      const request=await page.locator('#scene-dialog .scene-request').innerText();
      assert.match(request,/Борис/);assert.match(request,/жалован/);assert.match(request,/подготов|обучен/);assert.doesNotMatch(await page.locator('#scene-content').innerText(),/слишком новый меч/);
      await page.screenshot({path:path.join(artifacts,'meeting-brief.png'),fullPage:true});await page.click('[data-action="close-scene"]');
      const profiles=page.locator('#characters .character-profile');assert.equal(await profiles.count(),10);
      for(let i=0;i<10;i++){
        const profile=profiles.nth(i);await profile.locator('summary').click();const text=await profile.innerText();
        for(const heading of ['Ценит','Слабость','Личный интерес'])assert.ok(text.includes(heading));
        assert.ok((await profile.locator('p').innerText()).trim().length>50);
        assert.equal(await profile.locator('dd').count(),3);
        assert.ok((await profile.locator('dd').allInnerTexts()).every(description=>description.trim().length>12));
        assert.ok(await profile.locator('li').count()>0);await profile.locator('summary').click();
      }
      assert.match(await page.locator('#attention').innerText(),/Осталось личных дел: 2/);assert.equal(await page.locator('[data-stat="gold"] .stat-value').innerText(),'110');
      await page.locator('#save-file').setInputFiles({name:'start.json',mimeType:'application/json',buffer:Buffer.from(G.serialize(originalState))});
      await page.waitForFunction(seed=>JSON.parse(localStorage.getItem('priceOfPower.v04.auto')).state.seed===seed,originalState.seed);
      await page.click('nav [data-tab="council"]');
    });
    await check('совет не предсказывает числовые награды до выбора',async()=>{
      assert.equal(await page.locator('#council-result').isVisible(),false);
      for(const description of await page.locator('#council-event .choice-description').allInnerTexts()) {assert.ok(description.trim().length>10);assert.doesNotMatch(description,/[+−-]\s*\d|\d+\s*%/);}
      assert.match(await page.locator('[data-choice="investigate"] small').innerText(),/8.*монет/);
    });
    await check('решение, разведка и стройка списывают средства и идут параллельно',async()=>{
      await page.click('[data-choice="investigate"]');assert.equal(await page.locator('#council-result').isVisible(),true);assert.match(await page.locator('#council-result').innerText(),/Казна\s*[−-]8/);await page.click('nav [data-tab="orders"]');await page.selectOption('#order-target','mer');await page.click('#command-catalog [data-order="scout"]');await page.click('nav [data-tab="development"]');await page.click('#buildings [data-order="farm"]');assert.equal(await page.locator('[data-stat="gold"] .stat-value').innerText(),'64');await page.click('nav [data-tab="council"]');assert.equal(await page.locator('#active-orders .order').count(),2);assert.equal(await page.locator('#queue-count').innerText(),'2 / 6');
    });
    await check('главный экран доступен повторно и не начинает кампанию заново',async()=>{
      await page.click('nav [data-tab="home"]');assert.equal(await page.locator('#realm-home').isVisible(),true);assert.equal(await page.locator('.dominion-map').isVisible(),true);assert.equal(await page.locator('[data-stat="gold"] .stat-value').innerText(),'64');assert.equal(await page.locator('#date').innerText(),'Январь 1248');await page.click('.home-hotspot.capital');assert.equal(await page.locator('#active-orders .order').count(),2);assert.equal(await page.locator('#queue-count').innerText(),'2 / 6');
    });
    await check('карту можно двигать и масштабировать, детали появляются постепенно, активная вкладка закрывается повторным нажатием',async()=>{
      await page.click('nav [data-tab="home"]');const visible=()=>page.locator('.home-hotspot').evaluateAll(nodes=>nodes.filter(n=>getComputedStyle(n).visibility!=='hidden').length);assert.equal(await visible(),5);await page.click('[data-map-action="in"]');await page.click('[data-map-action="in"]');assert.equal(await page.locator('.dominion-map').getAttribute('data-zoom'),'0.9');assert.equal(await visible(),10);const map=page.locator('.dominion-map'),vp=page.viewportSize(),before=await map.getAttribute('style');await page.mouse.move(vp.width*.5,vp.height*.82);await page.mouse.down();await page.mouse.move(vp.width*.38,vp.height*.72,{steps:4});await page.mouse.up();assert.notEqual(await map.getAttribute('style'),before);await page.click('[data-map-action="reset"]');assert.equal(await map.getAttribute('data-zoom'),'0.36');await page.click('.home-hotspot.capital');assert.equal(await page.locator('[data-page="council"]').isVisible(),true);await page.click('nav [data-tab="council"]');assert.equal(await page.locator('[data-page="council"]').isVisible(),false);assert.equal(await page.locator('.dominion-map').isVisible(),true);await page.click('.home-hotspot.capital');
    });
    await check('завершение месяца показывает результат и причины изменения показателей',async()=>{
      await nextMonth(page);assert.equal(await page.locator('#date').innerText(),'Февраль 1248');assert.equal(await page.locator('#monthly-report').isVisible(),true);assert.match(await page.locator('#monthly-report').innerText(),/110 →/);await page.locator('#monthly-report summary').click();assert.match(await page.locator('#monthly-report').innerText(),/Месячный баланс: казна \+17/);await page.locator('#monthly-report summary').click();
    });
    await check('ручное сохранение восстанавливает месяц и незавершённые поручения',async()=>{
      await page.click('.topbar [data-action="save"]');await nextMonth(page);assert.equal(await page.locator('#date').innerText(),'Март 1248');await page.click('.topbar [data-action="load"]');assert.equal(await page.locator('#date').innerText(),'Февраль 1248');assert.equal(await page.locator('#realm-home').isVisible(),true);assert.equal(await page.locator('.dominion-map').isVisible(),true);await page.click('.home-hotspot.capital');assert.equal(await page.locator('#active-orders .order').count(),2);
    });
    let resolvedSceneId, resolvedSceneText;
    await check('встреча скрывает последствия и показывает фактический исход после решения',async()=>{
      await page.click('nav [data-tab="court"]');
      const portraits=await page.evaluate(async()=>{
        const faces=[...document.querySelectorAll('#characters .portrait')];
        const backgrounds=faces.map(el=>getComputedStyle(el).backgroundImage);
        const positions=faces.map(el=>getComputedStyle(el).backgroundPosition);
        const source=backgrounds[0]?.match(/url\((['"]?)(.*?)\1\)/)?.[2];
        if(!source)return {count:faces.length,embedded:false,positions:[],width:0};
        const image=new Image();image.src=source;await image.decode();
        return {count:faces.length,embedded:backgrounds.every(bg=>/data:image\/|blob:/.test(bg)),positions,distinct:new Set(backgrounds.map((bg,i)=>bg+'|'+positions[i])).size,width:image.naturalWidth};
      });
      assert.equal(portraits.count,10);assert.equal(portraits.embedded,true);assert.equal(portraits.distinct,10);assert.ok(portraits.width>=1000);
      const sceneButton=page.locator('#encounters [data-scene]').first();resolvedSceneId=await sceneButton.getAttribute('data-scene');await sceneButton.click();assert.equal(await page.locator('#scene-dialog').isVisible(),true);assert.ok((await page.locator('.scene-story').innerText()).length>200);assert.equal(await page.locator('#scene-result').isVisible(),false);
      const paidButton=page.locator('#scene-dialog [data-story-choice]:not([disabled])').filter({hasText:/Необходимо: \d+ монет/}).first();assert.ok(await paidButton.count(),'affordable meeting choice with known monetary cost');const paidChoice={id:await paidButton.getAttribute('data-story-choice')};
      for(const description of await page.locator('#scene-dialog .choice-description').allInnerTexts()){assert.ok(description.trim().length>10);assert.doesNotMatch(description,/[+−-]\s*\d|\d+\s*%|доверие[^.]*\d/i);}
      await page.screenshot({path:path.join(artifacts,'meeting-before.png'),fullPage:true});await page.locator(`#scene-dialog [data-story-choice="${paidChoice.id}"]`).click();assert.match(await page.locator('#scene-content').innerText(),/РЕШЕНИЕ ПРИНЯТО/);assert.match(await page.locator('#attention').innerText(),/Осталось личных дел: 1/);assert.equal(await page.locator('#scene-result').isVisible(),true);resolvedSceneText=await page.locator('#scene-result').innerText();assert.match(resolvedSceneText,/Доверие/i);assert.match(resolvedSceneText,/[+−-]\s*\d/);assert.ok((await page.locator('#scene-result .changes').innerText()).length>5);await page.screenshot({path:path.join(artifacts,'meeting-after.png'),fullPage:true});await page.click('[data-action="close-scene"]');
    });
    let savePayload;
    await check('скачанный файл — валидное полное сохранение',async()=>{
      await page.click('nav [data-tab="history"]');const pending=page.waitForEvent('download');await page.locator('[data-page="history"] [data-action="export"]').click();const download=await pending;const file=path.join(artifacts,'browser-save.json');await download.saveAs(file);savePayload=fs.readFileSync(file);const state=G.deserialize(savePayload.toString());assert.equal(state.month,1);assert.equal(state.orders.length,2);assert.equal(state.attention,1);
    });
    await check('ошибочный импорт не уничтожает текущую кампанию',async()=>{
      await page.locator('#save-file').setInputFiles({name:'invalid.json',mimeType:'application/json',buffer:Buffer.from('{"version":0}')});await page.waitForFunction(()=>document.querySelector('#status').classList.contains('error'));assert.equal(await page.locator('#date').innerText(),'Февраль 1248');
    });
    await check('новая кампания и импорт возвращают точное состояние',async()=>{
      await page.click('.topbar [data-action="new"]');await page.fill('#world-seed','browser-new');await page.selectOption('#scenario','scarcity');await page.locator('#new-game-form button[type="submit"]').click();await closeIntro(page);assert.equal(await page.locator('#date').innerText(),'Январь 1248');assert.equal(await page.locator('#realm-home').isVisible(),true);assert.match(await page.locator('#home-scenario').innerText(),/Недород|неурожай|зерн|урожая/i);await page.click('#enter-reign');assert.match(await page.locator('#council-event').innerText(),/амбары/);await page.locator('#save-file').setInputFiles({name:'valid.json',mimeType:'application/json',buffer:savePayload});await page.waitForFunction(()=>document.querySelector('#date').textContent==='Февраль 1248');assert.equal(await page.locator('#realm-home').isVisible(),true);assert.equal(await page.locator('#attention').innerText(),'Осталось личных дел: 1');
    });
    await check('исход завершённой встречи сохраняется после переноса кампании',async()=>{
      await page.click('nav [data-tab="court"]');await page.locator(`#encounters [data-scene="${resolvedSceneId}"]`).click();assert.equal(await page.locator('#scene-result').innerText(),resolvedSceneText);assert.equal(await page.locator('#scene-dialog [data-story-choice]').count(),0);await page.click('[data-action="close-scene"]');
    });
    await check('стройка, законы и закрытый университет показаны с условиями',async()=>{
      await page.click('nav [data-tab="development"]');assert.equal(await page.locator('#buildings .command-card').count(),22);assert.equal(await page.locator('#laws .law-card').count(),14);assert.equal(await page.locator('[data-order="university"]').isDisabled(),true);assert.match(await page.locator('#buildings').innerText(),/2 школы и наука/);await page.screenshot({path:path.join(artifacts,'development.png'),fullPage:true});
    });
    await check('12 месяцев дают развязку, после которой можно играть дальше',async()=>{
      await page.click('nav [data-tab="council"]');let chapterSeen=false;
      for(let i=0;i<48;i++){
        if(await page.locator('#chapter-dialog').isVisible()){
          assert.match(await page.locator('#chapter-content').innerText(),/ГЛАВА 1/);await page.screenshot({path:path.join(artifacts,'year-ending.png'),fullPage:true});chapterSeen=true;await page.click('#continue-chapter');
        }
        const stored=await page.evaluate(()=>JSON.parse(localStorage.getItem('priceOfPower.v04.auto')).state);const now=stored.month;if(now>=13)break;
        if(stored.military?.battle){await page.click('nav [data-tab="army"]');await page.click('[data-battle-tactic="withdraw"]');await page.click('nav [data-tab="council"]');continue;}
        const choices=page.locator('#council-event [data-choice]:not([disabled])');
        if(await choices.count()){
          let chosen=false;for(const id of ['investigate','talk','fields','import','ration']){const option=page.locator(`#council-event [data-choice="${id}"]:not([disabled])`);if(await option.count()){await option.click();chosen=true;break;}}if(!chosen)await choices.first().click();
        }
        assert.equal(await page.locator('#next-month').isEnabled(),true);await nextMonth(page);
      }
      assert.equal(chapterSeen,true);assert.match(await page.locator('#date').innerText(),/1249/);const month=await page.evaluate(()=>JSON.parse(localStorage.getItem('priceOfPower.v04.auto')).state.month);assert.equal(month,13);
    });
    await check('график переключается между реальными показателями',async()=>{
      await page.click('nav [data-tab="history"]');await page.selectOption('#chart-metric','food');assert.match(await page.locator('#metric-chart').innerText(),/Зерно/);assert.equal(await page.locator('#metric-chart circle').count(),13);await page.selectOption('#chart-range','24');assert.equal(await page.locator('#metric-chart circle').count(),14);await page.screenshot({path:path.join(artifacts,'history.png'),fullPage:true});
    });
    await check('широкий и мобильный интерфейсы не выходят за экран',async()=>{
      assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));await page.setViewportSize({width:390,height:844});
      for(const tab of ['home','council','development','court','army','intel','orders','history']){await page.click(`nav [data-tab="${tab}"]`);assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),`mobile overflow ${tab}`);if(tab==='home'){assert.equal(await page.locator('#realm-home').isVisible(),true);await page.screenshot({path:path.join(artifacts,'home-mobile.png'),fullPage:true});}}
      await page.click('nav [data-tab="council"]');await page.screenshot({path:path.join(artifacts,'mobile.png'),fullPage:true});await page.click('nav [data-tab="court"]');await page.locator('#encounters [data-scene]').first().click();await page.screenshot({path:path.join(artifacts,'meeting-mobile.png'),fullPage:true});await page.click('[data-action="close-scene"]');
    });
    await check('нет ошибок JavaScript и запросов к внешним сервисам',async()=>{assert.deepEqual(errors,[]);assert.deepEqual(externalRequests,[]);});
    // Оpaque origin лишён localStorage: проверяем и этот реальный режим браузера.
    await check('однофайловая игра исполняется без загрузки ресурсов и без localStorage',async()=>{
      const offline=await context.newPage();const requests=[];const offlineErrors=[];offline.on('request',r=>{if(/^https?:/.test(r.url()))requests.push(r.url());});offline.on('pageerror',e=>offlineErrors.push(e.message));await offline.setContent(fs.readFileSync(path.join(root,'dist','price-of-power.html'),'utf8'));await closeIntro(offline);assert.equal(await offline.locator('#realm-home').isVisible(),true);await artworkLoaded(offline);await offline.click('#enter-reign');assert.equal(await offline.locator('#council-event .choice').count(),3);await offline.click('[data-choice="investigate"]');await nextMonth(offline);assert.equal(await offline.locator('#date').innerText(),'Февраль 1248');assert.deepEqual(requests,[]);assert.deepEqual(offlineErrors,[]);await offline.close();
    });
    console.log(`${passed} browser checks passed; 0 skipped.`);
  } finally {
    if(browser)await browser.close();await new Promise(resolve=>server.close(resolve));
  }
})().catch(error=>{console.error(error);process.exitCode=1;});
