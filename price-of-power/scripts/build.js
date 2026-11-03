'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'source');
const assets = new Map();
function asset(filename) {
  const file = path.resolve(source, filename);
  if (!file.startsWith(path.join(source, 'assets') + path.sep)) throw new Error('Недопустимый путь изображения');
  const mime = {'.png':'image/png','.jpg':'image/jpeg','.webp':'image/webp'}[path.extname(file)];
  if (!mime) throw new Error('Неизвестный формат изображения');
  if (!assets.has(filename)) assets.set(filename,{variable:`--pop-asset-${assets.size}`,mime,data:fs.readFileSync(file).toString('base64')});
  return assets.get(filename);
}
let html = fs.readFileSync(path.join(source,'index.html'),'utf8');
html = html.replace(/<link rel="stylesheet" href="([\w.-]+)">/g,(_,filename)=> {
  let css = fs.readFileSync(path.join(source,filename),'utf8');
  css=css.replace(/url\((['"]?)(assets\/[\w./-]+)\1\)/g,(_,quote,filename)=>`var(${asset(filename).variable})`);
  return `<style>\n${css}\n</style>`;
});
html = html.replace(/<script src="([\w.-]+)" defer><\/script>/g,(_,filename)=>`<script>\n${fs.readFileSync(path.join(source,filename),'utf8').replace(/<\/script/gi,'<\\/script')}\n</script>`);
// Both ordinary HTML and template strings create images through one local registry.
html=html.replace(/(<img\b[^>]*?)\bsrc="(assets\/[^"<>]+)"/g,(_,prefix,filename)=>{asset(filename);return `${prefix}data-pop-asset="${filename}"`;});
const scripts=[...html.matchAll(/<script>[\s\S]*?<\/script>/g)].map(m=>m[0]).join('\n');
html=html.replace(/<script>[\s\S]*?<\/script>/g,'');
const manifest=Object.fromEntries(assets);
const loader=`<script>(function(){'use strict';const data=${JSON.stringify(manifest)};const urls={};for(const [name,item] of Object.entries(data)){const raw=atob(item.data);const bytes=new Uint8Array(raw.length);for(let i=0;i<raw.length;i++)bytes[i]=raw.charCodeAt(i);const url=URL.createObjectURL(new Blob([bytes],{type:item.mime}));urls[name]=url;document.documentElement.style.setProperty(item.variable,'url("'+url+'")');}window.PopAssets=urls;function fill(root){if(root.nodeType!==1&&root.nodeType!==9)return;if(root.matches?.('img[data-pop-asset]'))root.src=urls[root.dataset.popAsset]||'';for(const img of root.querySelectorAll('img[data-pop-asset]'))if(!img.getAttribute('src'))img.src=urls[img.dataset.popAsset]||'';}fill(document);new MutationObserver(records=>{for(const record of records)for(const node of record.addedNodes)fill(node);}).observe(document.body,{childList:true,subtree:true});})();</script>`;
html=html.replace('</body>',`${loader}\n${scripts}\n</body>`);
if (/<script src=|<link rel="stylesheet"|src="assets\/|url\(['"]?assets\//.test(html)) throw new Error('В сборке остались внешние ресурсы');
fs.mkdirSync(path.join(root,'dist'),{recursive:true});fs.writeFileSync(path.join(root,'dist','price-of-power.html'),html);
console.log(`Собрано dist/price-of-power.html: ${Buffer.byteLength(html)} байт; ${assets.size} иллюстраций, без повторного встраивания. Сервер и сеть не нужны.`);
