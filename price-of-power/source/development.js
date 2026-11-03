/* Карта княжеских проектов и иллюстрированные карточки построек. */
(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.PopDevelopment = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function () {
  'use strict';
  const DISTRICTS = {
    farms: { title: 'Западные поля', category: 'Хозяйство', className: 'land', x: 14, y: 68, atlas: 0 },
    orchards: { title: 'Плодовые сады', category: 'Хозяйство', className: 'land', x: 28, y: 40, atlas: 1 },
    roads: { title: 'Речная переправа', category: 'Пути и снабжение', className: 'routes', x: 15, y: 24, atlas: 2 },
    wells: { title: 'Водный двор', category: 'Городские службы', className: 'civic', x: 49, y: 42, atlas: 3 },
    granaries: { title: 'Амбарный посад', category: 'Запасы и торговля', className: 'stores', x: 41, y: 76, atlas: 4 },
    schools: { title: 'Земская слобода', category: 'Знания', className: 'knowledge', x: 64, y: 72, atlas: 5 },
    clinics: { title: 'Лекарский двор', category: 'Городские службы', className: 'civic', x: 68, y: 36, atlas: 6 },
    universities: { title: 'Учёный квартал', category: 'Знания', className: 'knowledge', x: 84, y: 58, atlas: 7 },
  };
  const esc = value => String(value).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  let latestView = null, selectedKey = null, zoom = 1, listening = false;

  function districtInfo(key) { return DISTRICTS[key] || { title: 'Городской проект', category: 'Развитие', className: 'civic', x: 50, y: 50, atlas: 0 }; }
  function projectState(v, b) {
    const level = Number(v.player[b.key]) || 0;
    const order = v.orders.find(o => o.type === b.command);
    return { level, order, label: order ? `${level ? 'Улучшение' : 'Строится'} · ${order.remaining} мес.` : level ? `Работает · ур. ${level}` : 'Не построено', status: order ? 'building' : level ? 'operating' : 'unbuilt' };
  }
  function illustration(key, extraClass = '', decorative = false) {
    const info = districtInfo(key);
    return `<span class="development-art development-art--${esc(key)} ${esc(extraClass)}"${decorative ? ' aria-hidden="true"' : ` role="img" aria-label="${esc(info.title)} — вид постройки"`}></span>`;
  }
  function buildingCard(v, d, b, blocker = '') {
    const info = districtInfo(b.key), project = projectState(v, b);
    const level = Number.isFinite(d.level) ? d.level : project.level;
    const max = Number.isFinite(d.maxLevel) ? d.maxLevel : b.max;
    const complete = level >= max;
    return `<article class="command-card development-building development-building--${info.className}" data-building-card="${esc(b.key)}">
      <div class="development-building-picture">${illustration(b.key)}<span class="development-building-category">${esc(info.category)}</span><span class="development-state development-state--${project.status}">${esc(project.label)}</span></div>
      <div class="development-building-copy"><div class="development-building-top"><span class="eyebrow">${esc(info.title)}</span><span class="development-level">${level} / ${max}</span></div>
      <h2>${esc(b.name)}</h2><div class="levels" aria-label="Уровень ${level} из ${max}">${Array.from({ length: max }, (_, i) => `<span class="${i < level ? 'filled' : ''}"></span>`).join('')}</div>
      <p class="command-description">${esc(b.effect)}</p>
      <div class="command-cost">${complete ? '<span>Максимальный уровень</span>' : `<span>◉ ${d.gold} монет</span><span>◷ ${d.duration} мес.</span>`}</div>
      <button class="button secondary" data-order="${esc(d.id)}" ${blocker || complete ? 'disabled' : ''}>${complete ? 'Полностью развито' : level ? 'Повысить уровень' : 'Начать строительство'}</button>
      <p class="command-blocker">${esc(blocker || d.executor || '')}</p></div>
    </article>`;
  }
  function mapMarkup(v) {
    const total = v.buildings.reduce((n, b) => n + (Number(v.player[b.key]) || 0), 0);
    const active = v.buildings.filter(b => projectState(v, b).order).length;
    return `<div class="development-map-heading"><div><span class="eyebrow">ГОРОД, ЗЕМЛИ И ПЕРЕПРАВЫ</span><h2>Арден: карта развития</h2></div><div class="development-map-totals"><span><b>${total}</b> уровней построено</span><span><b>${active}</b> проектов в работе</span></div></div>
      <div class="development-map-toolbar"><div class="development-map-legend" aria-label="Обозначения карты"><span><i class="legend-dot operating"></i>Действует</span><span><i class="legend-dot building"></i>Строительство</span><span><i class="legend-dot unbuilt"></i>Проект</span></div><div class="development-map-controls" aria-label="Масштаб карты"><button type="button" data-development-zoom="out" aria-label="Уменьшить карту">−</button><button type="button" data-development-zoom="reset">Весь город</button><button type="button" data-development-zoom="in" aria-label="Увеличить карту">+</button></div></div>
      <div class="development-map-viewport" tabindex="0" aria-label="Карта проектов Ардена. На небольшом экране карту можно прокручивать в стороны."><div class="development-map-board" style="width:${zoom * 100}%;min-width:${760 * zoom}px">
      <img class="development-landscape" src="assets/arden-city-map.png" alt="Город Арден с замком, речной переправой, дорогами и окрестными землями" width="1600" height="1000">
      <div class="development-map-vignette" aria-hidden="true"></div><div class="development-castle"><span>♜ Замок Ардена</span><small>Оборона княжества ${v.player.defense}</small></div>
      ${v.buildings.map(b => {
        const info = districtInfo(b.key), project = projectState(v, b);
        return `<button type="button" class="development-district development-district--${project.status}" data-building-select="${esc(b.key)}" style="left:${info.x}%;top:${info.y}%" aria-label="${esc(b.name)}. ${esc(project.label)}. Открыть сведения о проекте.">${illustration(b.key, 'development-district-art', true)}<span class="development-district-name">${esc(b.name)}</span><span class="development-district-status">${esc(project.label)}</span></button>`;
      }).join('')}<span class="development-compass" aria-hidden="true">С<br>◇</span></div></div>
      <p class="development-map-caption">Выберите объект на карте, чтобы увидеть его назначение, уровень и стоимость. Значки показывают княжеские проекты; на телефоне карту можно двигать в стороны.</p>`;
  }

  function ensureDialog() {
    let dialog = document.querySelector('#development-dialog');
    if (!dialog) {
      dialog = document.createElement('dialog'); dialog.id = 'development-dialog';
      dialog.setAttribute('aria-label', 'Проект развития княжества');
      document.body.append(dialog);
    }
    return dialog;
  }
  function refreshDialog() {
    if (!selectedKey || !latestView) return;
    const b = latestView.buildings.find(b => b.key === selectedKey);
    if (!b) return;
    const card = document.querySelector(`#buildings [data-building-card="${b.key}"]`);
    const dialog = ensureDialog();
    const info = districtInfo(b.key);
    dialog.innerHTML = `<div class="development-dialog-top"><div><span class="eyebrow">ПРОЕКТ КНЯЖЕСТВА</span><p>${esc(info.category)}</p></div><button type="button" class="icon-button" data-development-close aria-label="Закрыть сведения о проекте">×</button></div>${card ? card.outerHTML : '<p class="muted">Сведения об объекте обновляются. Вернитесь к карте.</p>'}<div class="dialog-actions"><button type="button" class="button quiet" data-development-close>Вернуться к карте</button></div>`;
  }
  function applyZoom() {
    const board = document.querySelector('.development-map-board');
    if (!board) return;
    board.style.width = `${zoom * 100}%`; board.style.minWidth = `${760 * zoom}px`;
    const viewport = document.querySelector('.development-map-viewport');
    if (zoom === 1 && viewport) viewport.scrollTo({ left: 0, top: 0, behavior: 'auto' });
  }
  function listen() {
    if (listening || typeof document === 'undefined') return;
    listening = true;
    document.addEventListener('click', event => {
      const target = event.target.closest?.('button'); if (!target || target.disabled) return;
      if (target.hasAttribute('data-development-close')) { ensureDialog().close(); return; }
      if (target.dataset.buildingSelect) {
        selectedKey = target.dataset.buildingSelect; refreshDialog();
        const dialog = ensureDialog(); if (!dialog.open) dialog.showModal(); return;
      }
      if (target.dataset.developmentZoom) {
        const action = target.dataset.developmentZoom;
        zoom = action === 'reset' ? 1 : Math.max(1, Math.min(1.6, Math.round((zoom + (action === 'in' ? 0.2 : -0.2)) * 10) / 10));
        applyZoom(); return;
      }
      // Закрываем до обработчика модели: data-order обработает общий интерфейс.
      if (target.dataset.order && target.closest('#development-dialog')) ensureDialog().close();
    }, true);
  }
  function renderTown(v) {
    if (typeof document === 'undefined') return;
    latestView = v; listen();
    const container = document.querySelector('#town'); if (!container) return;
    container.classList.add('development-town'); container.innerHTML = mapMarkup(v);
    const dialog = document.querySelector('#development-dialog');
    if (dialog?.open) refreshDialog();
  }
  return { renderTown, buildingCard, mapMarkup, projectState, districtInfo };
});
