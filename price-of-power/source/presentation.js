/* Вступление, отклик интерфейса и видимая смена месяца. Игровую модель не меняет. */
(function(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.PopPresentation = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function() {
  'use strict';
  const esc = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'})[c]);
  const PREF = 'priceOfPower.presentation.sound';
  let initialized = false, enabled = true, audio = null, onIntroDone = null;
  let introView = null, introStep = 0, turnTimer = null, turnResolve = null;
  const reducedMotion = () => typeof window !== 'undefined' && window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  const byId = id => typeof document === 'undefined' ? null : document.getElementById(id);

  function updateSoundButtons() {
    if (typeof document === 'undefined') return;
    for (const b of document.querySelectorAll('#sound-toggle, [data-action="sound"]')) {
      b.textContent = enabled ? '♫ Звук: вкл.' : '♪ Звук: выкл.';
      b.setAttribute('aria-pressed', String(enabled));
      b.setAttribute('aria-label', enabled ? 'Выключить звуковой отклик' : 'Включить звуковой отклик');
    }
  }
  function soundEnabled() { return enabled; }
  function toggleSound() {
    enabled = !enabled;
    try { localStorage.setItem(PREF, enabled ? 'on' : 'off'); } catch {}
    updateSoundButtons();
    if (enabled) play('success');
    return enabled;
  }
  function audioContext() {
    if (!enabled || typeof window === 'undefined') return null;
    try {
      const Audio = window.AudioContext || window.webkitAudioContext;
      if (!Audio) return null;
      if (!audio || audio.state === 'closed') audio = new Audio();
      if (audio.state === 'suspended') audio.resume().catch(() => {});
      return audio;
    } catch { return null; }
  }
  function tone(context, start, frequency, duration, volume, type = 'sine', endFrequency = frequency) {
    const wave = context.createOscillator(), gain = context.createGain();
    wave.type = type; wave.frequency.setValueAtTime(frequency, start);
    wave.frequency.exponentialRampToValueAtTime(Math.max(1, endFrequency), start + duration);
    gain.gain.setValueAtTime(0.0001, start);
    gain.gain.exponentialRampToValueAtTime(volume, start + Math.min(0.025, duration / 4));
    gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
    wave.connect(gain); gain.connect(context.destination);
    wave.start(start); wave.stop(start + duration + 0.01);
    wave.onended = () => { wave.disconnect(); gain.disconnect(); };
  }
  function play(name = 'click') {
    try {
      const context = audioContext(); if (!context) return;
      const now = context.currentTime + 0.005;
      if (name === 'month') {
        tone(context, now, 110, 0.42, 0.055, 'triangle', 165);
        tone(context, now + 0.08, 330, 0.58, 0.026, 'sine', 220);
        tone(context, now + 0.23, 440, 0.42, 0.018);
      } else if (name === 'success') {
        [330, 415.3, 493.9].forEach((hz, i) => tone(context, now + i * 0.045, hz, 0.27, 0.018));
      } else if (name === 'warning') {
        tone(context, now, 220, 0.16, 0.035, 'triangle', 165);
      } else {
        tone(context, now, 640, 0.065, 0.026, 'triangle', 440);
      }
    } catch { /* Ограничение аудио в браузере не должно мешать игре. */ }
  }
  function ensureDialog(id, className, label) {
    let node = byId(id);
    if (!node) {
      node = document.createElement('dialog'); node.id = id; node.className = className;
      node.setAttribute('aria-label', label); document.body.append(node);
      if (id === 'prologue-dialog') node.addEventListener('cancel', e => { e.preventDefault(); closeIntro(); });
      if (id === 'month-transition') node.addEventListener('cancel', e => e.preventDefault());
    }
    return node;
  }
  function openDialog(node) {
    if (node.open) return;
    if (typeof node.showModal === 'function') node.showModal(); else node.setAttribute('open', '');
  }
  function closeDialog(node) {
    if (!node?.open) return;
    if (typeof node.close === 'function') node.close(); else node.removeAttribute('open');
  }
  function init(options = {}) {
    if (typeof document === 'undefined') return;
    if (typeof options.onIntroDone === 'function') onIntroDone = options.onIntroDone;
    if (!initialized) {
      initialized = true;
      try { enabled = localStorage.getItem(PREF) !== 'off'; } catch {}
      document.addEventListener('click', e => {
        const button = e.target.closest?.('button'); if (!button || button.disabled) return;
        const action = button.dataset.action;
        if (action === 'sound') { e.preventDefault(); e.stopPropagation(); toggleSound(); return; }
        if (action === 'intro-next' || action === 'intro-back' || action === 'intro-skip') {
          e.preventDefault(); e.stopPropagation(); play('click');
          if (action === 'intro-skip' || action === 'intro-next' && introStep === 2) closeIntro();
          else { introStep += action === 'intro-back' ? -1 : 1; renderIntro(); }
          return;
        }
        if (action !== 'next' && !button.hasAttribute('data-battle-tactic')) play('click');
      }, true);
    }
    updateSoundButtons();
  }
  function closeIntro() {
    closeDialog(byId('prologue-dialog'));
    if (onIntroDone) onIntroDone();
  }
  function panorama() {
    return '<img class="prologue-panorama" src="assets/arden-panorama.png" alt="Речная долина, город и замок Арденского княжества">';
  }
  function renderIntro() {
    if (!introView) return;
    const v = introView, people = v.characters || [];
    const views = [
      `<div class="prologue-picture">${panorama()}<div class="prologue-shade"></div></div><div class="prologue-copy"><span class="eyebrow">1248 ГОД · ВЫМЫШЛЕННАЯ СТРАНА НА ПЕРЕКРЁСТКЕ ДОРОГ</span><h1>Цена власти</h1><h2>Ваша летопись начинается в Ардене.</h2><p>Старый князь умер. Совет передал вам печать, казну и страну, которая слишком долго ждала решений. Здесь живут люди со своими надеждами. За рекой правят те, кто ничего вам не должен.</p><div class="prologue-facts"><span><b>${v.player.population} тыс.</b>жителей</span><span><b>${v.player.gold}</b>монет в казне</span><span><b>3</b>соседних государства</span></div></div>`,
      `<div class="prologue-people-backdrop">${panorama()}</div><div class="prologue-copy prologue-copy--people"><span class="eyebrow">ЛЮДИ, КОТОРЫЕ ВСТРЕТЯТ ВАС У ПРЕСТОЛА</span><h1>Они хотят разного.</h1><p>Выслушивайте просьбы, задавайте вопросы и проверяйте слухи. У каждого есть характер, близкие и собственный взгляд на справедливое решение. Верность нельзя купить одним удобным ответом.</p><div class="prologue-people">${['treasurer','marshal','doctor','governor'].map(id => {const p = people.find(p=>p.id===id); if (!p) return ''; return `<article><span class="portrait portrait--${esc(id)}" role="img" aria-label="${esc(p.name)}"></span><div><strong>${esc(p.name)}</strong><small>${esc(p.role)}</small><p>${esc(p.values || p.description)}</p></div></article>`;}).join('')}</div></div>`,
      `<div class="prologue-picture prologue-battle-art battlefield"><div class="prologue-shade"></div></div><div class="prologue-copy"><span class="eyebrow">ПРАВЛЕНИЕ ПРОДОЛЖАЕТСЯ ЗА СТЕНАМИ ЗАМКА</span><h1>За каждым приказом — дорога.</h1><p>Собирайте сведения о соседях. Устраняйте угрозы на дорогах и берегите дружину: провиант, усталость и местность влияют на бой. Укрепляйте княжество и следите за последствиями своих решений.</p><div class="prologue-route" aria-label="Путь от решения к результату"><span>♜<b>Замок</b></span><i></i><span>⚑<b>Поход</b></span><i></i><span>⚔<b>Столкновение</b></span></div><p class="prologue-note">Первый год завершится своей главой. После неё история может продолжиться.</p></div>`,
    ];
    const dialog = ensureDialog('prologue-dialog', 'prologue-dialog', 'Вступление: ваше княжество и роль правителя');
    dialog.innerHTML = `<section class="prologue-slide prologue-slide--${introStep}" aria-live="polite">${views[introStep]}<header class="prologue-top"><span>АРДЕНСКАЯ ЛЕТОПИСЬ</span><button class="button quiet" data-action="intro-skip">Пропустить вступление</button></header><footer class="prologue-navigation"><div class="prologue-dots" aria-label="Экран ${introStep + 1} из 3">${[0,1,2].map(i=>`<span class="${i===introStep?'active':''}"></span>`).join('')}<small>${introStep + 1} / 3</small></div><div><button class="button prologue-back" data-action="intro-back" ${introStep === 0 ? 'disabled' : ''}>← Назад</button><button class="button primary" data-action="intro-next">${introStep === 2 ? 'Принять печать →' : 'Далее →'}</button></div></footer></section>`;
  }
  function showIntro(v) {
    if (typeof document === 'undefined') return;
    init(); introView = v; introStep = 0; renderIntro();
    openDialog(byId('prologue-dialog'));
  }
  function cancelTurn() {
    if (turnTimer !== null) clearTimeout(turnTimer); turnTimer = null;
    closeDialog(byId('month-transition'));
    if (typeof document !== 'undefined') document.documentElement.removeAttribute('aria-busy');
    if (turnResolve) { const resolve = turnResolve; turnResolve = null; resolve(); }
  }
  function beginTurn(date) {
    if (typeof document === 'undefined') return;
    init(); cancelTurn();
    const dialog = ensureDialog('month-transition', 'month-transition', 'Смена месяца');
    dialog.innerHTML = `<div class="month-scene"><span class="eyebrow">ЛЕТОПИСЕЦ ПОДВОДИТ ИТОГИ</span><div class="month-seal" aria-hidden="true">♜</div><h2>${esc(date)}</h2><p>Поручения, люди и дороги. Мир отвечает на ваши решения.</p><div class="month-progress" role="progressbar" aria-label="Завершение месяца"><span></span></div><small>Месяц завершается…</small></div>`;
    document.documentElement.setAttribute('aria-busy', 'true'); openDialog(dialog); play('month');
  }
  function finishTurn(v, previousView) {
    if (typeof document === 'undefined') return Promise.resolve();
    const dialog = ensureDialog('month-transition', 'month-transition', 'Наступил следующий месяц');
    const before = previousView?.player || v.lastTurn?.before || v.player;
    const metrics = [['gold','Казна'],['food','Зерно'],['stability','Стабильность']];
    dialog.innerHTML = `<div class="month-scene month-scene--finished"><span class="eyebrow">НАСТУПИЛ НОВЫЙ МЕСЯЦ</span><div class="month-seal" aria-hidden="true">♛</div><h2>${esc(v.date)}</h2><p>${v.military?.battle ? 'На рубежах идёт столкновение. Войско ждёт вашего приказа.' : v.ended ? 'Летописец записал последние решения этого правления.' : 'Прочитайте отчёт и узнайте, какие дела появились при дворе.'}</p><div class="month-deltas">${metrics.map(([key,title])=>{const delta=v.player[key]-before[key];return `<span><small>${title}</small><b class="${delta<0?'negative':'positive'}">${delta>0?'+':''}${delta}</b><em>${before[key]} → ${v.player[key]}</em></span>`;}).join('')}</div><small>Подробные причины остались в месячном отчёте.</small></div>`;
    openDialog(dialog); play(v.ended ? 'warning' : 'success');
    return new Promise(resolve => {
      if (turnResolve) turnResolve();
      turnResolve = resolve;
      turnTimer = setTimeout(() => { turnTimer = null; closeDialog(dialog); document.documentElement.removeAttribute('aria-busy'); const done=turnResolve;turnResolve=null;done?.(); }, reducedMotion() ? 300 : 850);
    });
  }
  return { init, showIntro, play, toggleSound, soundEnabled, beginTurn, finishTurn, cancelTurn };
});
