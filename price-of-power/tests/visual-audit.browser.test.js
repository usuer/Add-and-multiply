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
    return {docOverflow,clipped:clipped.slice(0,20),badButtons:badButtons.slice(0,20)};
  });
  assert.equal(result.docOverflow,false,`${label}: horizontal document overflow`);
  assert.deepEqual(result.clipped,[],`${label}: clipped text ${JSON.stringify(result.clipped)}`);
  assert.deepEqual(result.badButtons,[],`${label}: undersized controls ${JSON.stringify(result.badButtons)}`);
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
    for(const tab of ['council','orders','intel','history']){await openTab(page,tab);await inspect(page,`desktop-${tab}`);}
    await openTab(page,'development');await inspect(page,'desktop-development-buildings');await page.locator('[data-development-view="laws"]').click();await inspect(page,'desktop-development-laws');
    await openTab(page,'court');await inspect(page,'desktop-court');const scene=page.locator('#encounters [data-scene]').first();if(await scene.count()){await scene.click();await inspect(page,'desktop-audience');await page.locator('[data-action="close-scene"]').first().click();}
    await openTab(page,'army');for(const view of ['map','troops','battle']){await page.locator(`[data-military-view="${view}"]`).click();await inspect(page,`desktop-army-${view}`);}
    await page.setViewportSize({width:390,height:844});
    for(const tab of ['home','council','development','court','army','intel','history']){await openTab(page,tab);await inspect(page,`mobile-${tab}`);}
    assert.deepEqual(errors,[]);console.log('PASS full visual audit: 23 screens, desktop and mobile');
  }finally{if(browser)await browser.close();await new Promise(r=>server.close(r));}
})().catch(e=>{console.error(e);process.exitCode=1;});
