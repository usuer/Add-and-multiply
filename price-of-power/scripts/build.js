'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'source');
let html = fs.readFileSync(path.join(source, 'index.html'), 'utf8');
html = html.replace(/<link rel="stylesheet" href="([\w.-]+)">/g, (_, filename) => `<style>\n${fs.readFileSync(path.join(source, filename), 'utf8')}\n</style>`);
html = html.replace(/<script src="([\w.-]+)" defer><\/script>/g, (_, filename) => `<script>\n${fs.readFileSync(path.join(source, filename), 'utf8').replace(/<\/script/gi, '<\\/script')}\n</script>`);
function embedAsset(filename) {
  const file = path.resolve(source, filename);
  if (!file.startsWith(path.join(source, 'assets') + path.sep)) throw new Error('Недопустимый путь изображения');
  const mime = { '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp' }[path.extname(file)];
  if (!mime) throw new Error('Неподдерживаемое изображение');
  return `data:${mime};base64,${fs.readFileSync(file).toString('base64')}`;
}
html = html.replace(/url\((['"]?)(assets\/[\w./-]+)\1\)/g, (_, quote, filename) => `url('${embedAsset(filename)}')`);
html = html.replace(/(<img\b[^>]*\bsrc=)"(assets\/[^"<>]+)"/g, (_, prefix, filename) => `${prefix}"${embedAsset(filename)}"`);
// Inline-скрипты должны запускаться после создания DOM, как исходные defer-скрипты.
const scripts = [...html.matchAll(/<script>[\s\S]*?<\/script>/g)].map(m => m[0]).join('\n');
html = html.replace(/<script>[\s\S]*?<\/script>/g, '').replace('</body>', `${scripts}\n</body>`);
if (/<script src=|<link rel="stylesheet"|src="assets\/|url\(['"]?assets\//.test(html)) throw new Error('В сборке остались внешние ресурсы');
fs.mkdirSync(path.join(root, 'dist'), { recursive: true });
fs.writeFileSync(path.join(root, 'dist', 'price-of-power.html'), html);
console.log(`Собрано dist/price-of-power.html (${Buffer.byteLength(html)} байт). Сервер и сеть не нужны.`);
