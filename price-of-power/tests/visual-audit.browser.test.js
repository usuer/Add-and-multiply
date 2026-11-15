'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const http=require('node:http');
const path=require('node:path');
const {chromium}=require('playwright');
const G=require('../source/core');
const root=path.resolve(__dirname,'..'),artifacts=path.join(root,'artifacts','visual-audit');
fs.mkdirSync(artifacts,{recursive:true});

function rich(){const s=G.createGame({seed:'full-visual-audit'});for(const v of [s.player,s.initial,s.monthStart,s.metrics[0].values]){v.gold=1500;v.food=300;}return s;}
async function closeIntro(page){const d=page.locator('#prologue-dialog');if(await d.count()&&await d.isVisible())await d.locator('[data-action="intro-skip"]').click();}
async function load(page,state){await page.locator('#save-file').setInputFiles({name:'audit.json',mimeType:'application/json',buffer:Buffer.from(G.serialize(state))});await page.waitForFunction(seed=>JSON.parse(localStorage.getItem('priceOfPower.v04.auto'))?.state.seed===seed,state.seed);if(await page.locator('#enter-reign').isVisible())await page.locator('#enter-reign').click();}
async function openTab(page,id){const panel=page.locator(`[data-page="${id}"]`);if(!await panel.isVisible())await page.locator(`nav [data-tab="${id}"]`).click();assert.equal(await panel.isVisible(),true,`${id} visible`);}
async function inspect(page,label){
  const result=await page.evaluate(()=>{
    const visible=n=>{const s=getComputedStyle(n),b=n.getBoundingClientRect();return s.display!=='none'&&s.visibility!=='hidden'&&b.width>2&&b.height>2&&b.right>0&&b.bottom>0&&b.left<innerWidth&&b.top<innerHeight;};
    const ignore=n=>n.closest('.portrait,.unit-formation,.home-hotspot,.chart,.dominion-map,.development-art,.audience-portrait,.battlefield')||n.matches('option');
    const clipped=[...document.querySelectorAll('h1,h2,h3,p,button,strong,small,span,label')].filter(n=>visible(n)&&!ignore(n)).filter(n=>{const s=getComputedStyle(n);return s.overflowX==='hidden'&&n.scrollWidth>n.clientWidth+3||s.overflowY==='hidden'&&n.scrollHeight>n.clientHeight+3;}).map(n=>({tag:n.tagName,class:n.className,text:(n.textContent||'').trim().slice(0,70),size:[n.clientWidth,n.clientHeight],scroll:[n.scrollWidth,n.scrollHeight]}));
    const docOverflow=document.documentElement.scrollWidth>innerWidth+1;
    const badButtons=[...document.querySelectorAll('button:not([disabled])')].filter(visible).filter(n=>{const b=n.getBoundingClientRect();return b.width<24||b.height<24;}).filter(n=>!n.closest('.battlefield')).map(n=>(n.textContent||n.getAttribute('aria-label')||'').trim().slice(0,50));
    const unnamed=[...document.querySelectorAll('button,a[href]')].filter(visible).filter(n=>!(n.textContent||'').trim()&&!n.getAttribute('aria-label')&&!n.getAttribute('title')).map(n=>n.outerHTML.slice(0,100));
    const unlabeled=[...document.querySelectorAll('input:not([type="hidden"]),select,textarea')].filter(visible).filter(n=>!n.closest('label')&&!n.getAttribute('aria-label')&&!n.getAttribute('aria-labelledby')).map(n=>n.id||n.outerHTML.slice(0,80));
    const ids=[...document.querySelectorAll('[id]')].map(n=>n.id),duplicates=[...new Set(ids.filter((id,i)=>ids.indexOf(id)!==i))];
    const activePanel=[...document.querySelectorAll('[data-page]')].find(n=>getComputedStyle(n).display!=='none');
    const activeHeadingVisible=!activePanel||activePanel.dataset.page==='home'||[...activePanel.querySelectorAll('h1,h2')].some(visible);
    const sidebar=document.querySelector('.sidebar')?.getBoundingClientRect();
    const mobileSidebarCompact=innerWidth>760||!sidebar||sidebar.height<80;
    const intersects=(a,b)=>Math.min(a.right,b.right)-Math.max(a.left,b.left)>1&&Math.min(a.bottom,b.bottom)-Math.max(a.top,b.top)>1;
    const choiceTextOverlaps=[...document.querySelectorAll('.council-card .choice')].filter(visible).some(choice=>{const title=choice.querySelector('strong'),description=choice.querySelector('.choice-description');return title&&description&&intersects(title.getBoundingClientRect(),description.getBoundingClientRect());});
    return {docOverflow,clipped:clipped.slice(0,20),badButtons:badButtons.slice(0,20),unnamed,unlabeled,duplicates,activeHeadingVisible,mobileSidebarCompact,choiceTextOverlaps};
  });
  assert.equal(result.docOverflow,false,`${label}: horizontal document overflow`);
  assert.deepEqual(result.clipped,[],`${label}: clipped text ${JSON.stringify(result.clipped)}`);
  assert.deepEqual(result.badButtons,[],`${label}: undersized controls ${JSON.stringify(result.badButtons)}`);
  assert.deepEqual(result.unnamed,[],`${label}: unnamed controls ${JSON.stringify(result.unnamed)}`);
  assert.deepEqual(result.unlabeled,[],`${label}: unlabeled fields ${JSON.stringify(result.unlabeled)}`);
  assert.deepEqual(result.duplicates,[],`${label}: duplicate ids ${JSON.stringify(result.duplicates)}`);
  assert.equal(result.activeHeadingVisible,true,`${label}: active page heading is hidden or covered`);
  assert.equal(result.mobileSidebarCompact,true,`${label}: mobile navigation covers the page`);
  assert.equal(result.choiceTextOverlaps,false,`${label}: council choice title overlaps its description`);
  await page.screenshot({path:path.join(artifacts,`${label}.png`)});
}

(async()=>{
  const server=http.createServer((req,res)=>{const file=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));if(!file.startsWith(root+path.sep)){res.writeHead(403);return res.end();}fs.readFile(file,(e,data)=>{if(e){res.writeHead(404);return res.end();}res.writeHead(200,{'Content-Type':path.extname(file)==='.html'?'text/html; charset=utf-8':'application/octet-stream','Cache-Control':'no-store'});res.end(data);});});
  await new Promise(r=>server.listen(0,'127.0.0.1',r));let browser;
  try{
    browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||(fs.existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),headless:true,args:['--no-sandbox']});
    const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
    await page.goto(`http://127.0.0.1:${server.address().port}/dist/price-of-power.html`);await closeIntro(page);await load(page,rich());
    await openTab(page,'home');await inspect(page,'desktop-home');
    await openTab(page,'council');await inspect(page,'desktop-council');const councilChoice=page.locator('#council-event [data-choice]:not([disabled])').first();if(await councilChoice.count()){await councilChoice.click();await page.locator('#next-month').click();await page.locator('#month-transition [data-action="close-month"]').click();await page.waitForFunction(()=>!document.documentElement.hasAttribute('aria-busy'));await openTab(page,'council');await inspect(page,'desktop-council-with-month-report');}
    for(const tab of ['orders','intel','history']){await openTab(page,tab);await inspect(page,`desktop-${tab}`);}
    await openTab(page,'development');await inspect(page,'desktop-development-buildings');const building=page.locator('#town [data-building-select]').first();if(await building.count()){await building.click();await inspect(page,'desktop-development-dialog');await page.locator('#development-dialog [data-development-close]').first().click();}await page.locator('#buildings').scrollIntoViewIfNeeded();await inspect(page,'desktop-development-catalog');await page.locator('[data-development-view="laws"]').click();await inspect(page,'desktop-development-laws');
    await openTab(page,'court');await inspect(page,'desktop-court');const scene=page.locator('#encounters [data-scene]').first();if(await scene.count()){await scene.click();await inspect(page,'desktop-audience');await page.locator('[data-action="close-scene"]').first().click();}
    await openTab(page,'army');for(const view of ['map','troops','battle']){await page.locator(`[data-military-view="${view}"]`).click();await inspect(page,`desktop-army-${view}`);}
    await page.setViewportSize({width:1024,height:768});
    for(const tab of ['home','council','development','court','army','intel','orders','history']){await openTab(page,tab);await inspect(page,`tablet-${tab}`);}
    await page.setViewportSize({width:768,height:900});
    for(const tab of ['home','council','development','court','army','intel','orders','history']){await openTab(page,tab);await inspect(page,`narrow-${tab}`);}
    await page.setViewportSize({width:390,height:844});
    for(const tab of ['home','council','development','court','army','intel','history']){await openTab(page,tab);await inspect(page,`mobile-${tab}`);}
    await page.setViewportSize({width:360,height:740});await openTab(page,'council');await inspect(page,'small-phone-council');await openTab(page,'court');await inspect(page,'small-phone-court');
    assert.deepEqual(errors,[]);console.log('PASS full visual audit: 44 screens across desktop, tablet and mobile');
  }finally{if(browser)await browser.close();await new Promise(r=>server.close(r));}
})().catch(e=>{console.error(e);process.exitCode=1;});
