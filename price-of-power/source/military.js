/* Военный срез: местности, снабжение походов и пошаговое столкновение. */
(function(root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.PopMilitary = api;
})(typeof globalThis === 'undefined' ? this : globalThis, function() {
  'use strict';
  const LOCATIONS = [
    {id:'capital',name:'Арденская крепость',terrain:'fortress',x:56,y:56},
    {id:'forest',name:'Лесная дорога',terrain:'forest',x:24,y:31},
    {id:'west',name:'Западные деревни',terrain:'plain',x:17,y:71},
    {id:'north',name:'Северный перевал',terrain:'hill',x:52,y:15},
    {id:'ford',name:'Каменная переправа',terrain:'river',x:71,y:35},
    {id:'east',name:'Восточный тракт',terrain:'plain',x:85,y:74},
  ];
  const EDGES = [['capital','forest',2],['capital','west',2],['capital','north',3],['capital','ford',1],['capital','east',2],['forest','west',1],['forest','north',2],['north','ford',2],['ford','east',1]];
  const TERRAIN = {fortress:'Крепость',forest:'Лес',plain:'Равнина',hill:'Высоты',river:'Переправа'};
  const MISSIONS = {patrol:'Патруль',expedition:'Поход против разбойников',defend:'Защита местности',return:'Возвращение в крепость'};
  const TYPES = {infantry:'Пехота',archers:'Стрелки',cavalry:'Конница'};
  const TACTICS = [
    {id:'guard',name:'Сомкнуть щиты',description:'Пехота удерживает строй и прикрывает соседние части.',types:['infantry']},
    {id:'advance',name:'Наступать строем',description:'Пехота движется вперёд единой линией и вступает в ближний бой.',types:['infantry']},
    {id:'melee',name:'Вынуть мечи',description:'Стрелки отбиваются в ближнем бою. Это крайняя и опасная мера.',types:['archers']},
    {id:'ranged',name:'Прицельный залп',description:'Лучники стреляют по выбранному вражескому отряду с текущей позиции.',types:['archers']},
    {id:'fallback',name:'Отойти за пехоту',description:'Лучники разрывают ближний бой и ищут безопасную линию стрельбы.',types:['archers']},
    {id:'flank',name:'Обход с фланга',description:'Конница обходит строй и выбирает уязвимую цель.',types:['cavalry']},
    {id:'charge',name:'Конный наскок',description:'Конница быстро атакует выбранный отряд, рискуя попасть под встречный удар.',types:['cavalry']},
    {id:'withdraw',name:'Отступить всей армией',description:'Прекратить бой и сохранить оставшихся. Преследование всё ещё может принести потери.',types:['infantry','archers','cavalry']},
  ];
  const clamp=(n,a,b)=>Math.max(a,Math.min(b,n));
  const copy=o=>JSON.parse(JSON.stringify(o));
  const location=id=>LOCATIONS.find(l=>l.id===id);
  const nation=id=>({val:'Вальдория',nor:'Нордвик',mer:'Мерсия'})[id] || 'Чужой отряд';
  const snap=s=>Object.fromEntries(['gold','food','army','stability'].map(k=>[k,s.player[k]]));
  const diff=(a,s)=>Object.fromEntries(Object.keys(a).filter(k=>a[k]!==s.player[k]).map(k=>[k,s.player[k]-a[k]]));
  const entry=(text,reason='',changes={})=>({text,reason,kind:'military',changes});
  const total=m=>m.reserve+m.units.reduce((sum,u)=>sum+u.strength,0);
  const homeStrength=s=>s.military?s.military.reserve+s.military.units.filter(u=>u.status==='ready').reduce((n,u)=>n+u.strength,0):s.player.army;
  function returnSupplies(s,ids){let food=0;for(const id of ids){const u=s.military.units.find(u=>u.id===id);food+=u.food;u.food=0;}const actual=Math.min(food,9999-s.player.food);s.player.food+=actual;return actual;}
  function distance(from,to) {
    const d=Object.fromEntries(LOCATIONS.map(l=>[l.id,Infinity])); d[from]=0;
    for(let i=0;i<LOCATIONS.length;i++) for(const [a,b,w] of EDGES) {d[b]=Math.min(d[b],d[a]+w);d[a]=Math.min(d[a],d[b]+w);}
    return d[to];
  }
  function create(s) {
    const army=s.player.army,a=Math.floor(army*.45),b=Math.floor(army*.35);
    return {version:1,nextId:1,reserve:0,lastAdvanced:s.month,weather:'clear',
      units:[['infantry','Княжеская дружина',a],['archers','Стрелки перевала',b],['cavalry','Конные дозорные',army-a-b]].map(([type,name,strength])=>({id:type,name,type,strength,morale:75,fatigue:5,experience:10,location:'capital',status:'ready',food:0,supplied:true})),
      locations:LOCATIONS.map(l=>({id:l.id,bandits:({forest:28,west:15,north:7,ford:10,east:12,capital:0})[l.id],unrest:0,lastPatrol:-10})),
      marches:[],enemyMarches:[],pendingBattles:[],battle:null,lastBattle:null};
  }
  function syncArmy(s) {
    const m=s.military;if(!m)return;
    let delta=s.player.army-total(m);
    if(delta>0) {
      const home=m.units.filter(u=>u.status==='ready'&&u.location==='capital');
      if(!home.length)m.reserve+=delta;
      else {for(let i=0;i<delta;i++)home[i%home.length].strength++;}
    } else if(delta<0) {
      let needed=-delta,fromReserve=Math.min(needed,m.reserve);m.reserve-=fromReserve;needed-=fromReserve;
      const troops=[...m.units].sort((a,b)=>b.strength-a.strength);
      while(needed>0)for(const u of troops)if(needed&&u.strength){u.strength--;needed--;}
    }
    const home=m.units.filter(u=>u.status==='ready'&&u.location==='capital');
    if(home.length&&m.reserve){const count=m.reserve;m.reserve=0;for(let i=0;i<count;i++)home[i%home.length].strength++;}
  }
  const ration=u=>2+Math.ceil(u.strength/18);
  function quote(s, options={}) {
    const m=s.military;if(!m)throw new Error('Военные сведения ещё не подготовлены.');
    const mission=options.mission || 'expedition',target=mission==='return'?'capital':options.target,supply=options.supply || 'normal';
    if(!Object.hasOwn(MISSIONS,mission)||!location(target))throw new Error('Выберите местность и задачу похода.');
    if(mission==='expedition'&&m.locations.find(p=>p.id===target).bandits<20)throw new Error('В этой местности не обнаружено разбойничьего лагеря. Можно отправить патруль.');
    if(!['light','normal','full'].includes(supply))throw new Error('Неизвестный вариант снабжения.');
    const ids=options.unitIds===undefined?m.units.filter(u=>u.status==='ready'&&u.strength>0).map(u=>u.id):options.unitIds;
    if(!Array.isArray(ids)||!ids.length||new Set(ids).size!==ids.length)throw new Error('Выберите хотя бы один свободный отряд.');
    const units=ids.map(id=>m.units.find(u=>u.id===id));
    if(units.some(u=>!u||u.status!=='ready'||u.strength<=0))throw new Error('Выбранный отряд занят или потерял боеспособность.');
    const dist=Math.max(...units.map(u=>distance(u.location,target)));
    const duration=clamp(Math.ceil(dist/(1+s.player.roads*.3)),1,3);
    const factor={light:.55,normal:1,full:1.35}[supply];
    const allocations=units.map(u=>({id:u.id,food:Math.ceil(ration(u)*duration*factor)}));
    return {duration,food:allocations.reduce((n,a)=>n+a.food,0),unitIds:[...ids],target,mission,supply,distance:dist,allocations};
  }
  function launch(s, options) {
    if(s.ended)throw new Error('Правление завершено.');
    if(hasBattle(s))throw new Error('Сначала завершите начавшееся сражение.');
    const q=quote(s,options),m=s.military;
    if(m.marches.length>=3)throw new Error('Слишком много отдельных походов.');
    if(s.player.food<q.food)throw new Error(`Не хватает провианта: нужно ${q.food} зерна.`);
    s.player.food-=q.food;
    const march={id:'march-'+m.nextId++,target:q.target,unitIds:q.unitIds,mission:q.mission,supply:q.supply,duration:q.duration,remaining:q.duration,started:s.month,food:q.food};
    for(const allocation of q.allocations){const u=m.units.find(u=>u.id===allocation.id);u.status='marching';u.food=allocation.food;u.supplied=true;}
    m.marches.push(march);
    return [entry(`${MISSIONS[q.mission]}: цель — ${location(q.target).name}.`,`Расстояние ${q.distance}; путь ${q.duration} мес.; выдано ${q.food} зерна. Дороги сокращают время, лёгкий обоз может не прокормить людей до конца пути.`,{food:-q.food})];
  }
  function scheduleEnemyRaid(s,id,power,random) {
    const m=s.military;
    if(m.enemyMarches.some(e=>e.attackerId===id)||m.enemyMarches.length>=6)return [];
    const r=random || (()=>.5),target=r()<.2?'capital':({val:'ford',nor:'north',mer:'east'})[id] || 'ford';
    const strength=clamp(Math.round(power*.55),5,120),duration=target==='north'?3:2;
    const n=s.neighbors?.find(n=>n.id===id),need=Math.ceil(strength/15)+2,food=Math.min(n?.food ?? need*duration,need*duration);
    if(n)n.food-=food;
    m.enemyMarches.push({id:'enemy-'+m.nextId++,attackerId:id,target,power:strength,initialPower:strength,remaining:duration,duration,started:s.month,food,morale:70,fatigue:5});
    return [entry(`Пограничная стража заметила отряд: ${nation(id)}, цель — ${location(target).name}.`,`До подхода примерно ${duration} мес. Силы оценены приблизительно. Можно успеть выдвинуть защиту или сберечь войска.`)];
  }
  function beginBattle(s, spec) {
    const m=s.military;
    const battle={id:'battle-'+m.nextId++,location:spec.location,kind:spec.kind,attackerId:spec.attackerId || null,attackerName:spec.attackerName,
      unitIds:[...spec.unitIds],defending:Boolean(spec.defending),phase:0,enemyPower:spec.power,initialEnemyPower:spec.power,enemyMorale:spec.morale??65,enemyFatigue:spec.fatigue??10,
      startedArmy:s.player.army,startPlayer:snap(s),weather:m.weather,losses:0,enemyLosses:0,log:[`Столкновение: ${location(spec.location).name}. ${TERRAIN[location(spec.location).terrain]}.` ]};
    for(const id of battle.unitIds)m.units.find(u=>u.id===id).status='battle';
    if(m.battle)m.pendingBattles.push(battle);else m.battle=battle;
  }
  function raidWithoutDefenders(s, campaign) {
    const before=snap(s),m=s.military,place=m.locations.find(l=>l.id===campaign.target);
    const gold=Math.min(s.player.gold,14),food=Math.min(s.player.food,10);s.player.gold-=gold;s.player.food-=food;s.player.stability=Math.max(0,s.player.stability-5);place.bandits=clamp(place.bandits+4,0,100);
    const n=s.neighbors?.find(n=>n.id===campaign.attackerId);if(n){n.gold=Math.min(9999,n.gold+gold);n.food=Math.min(9999,n.food+food);}
    return entry(`${nation(campaign.attackerId)} совершила набег: ${location(campaign.target).name} осталась без полевой защиты.`,`Войска находились в других местах и не могли мгновенно оказаться у цели. Потеряно ${gold} монет и ${food} зерна.`,diff(before,s));
  }
  function advance(s, random) {
    const m=s.military,entries=[];if(!m||s.ended||s.month<=m.lastAdvanced)return entries;
    if(m.battle)throw new Error('Сначала завершите сражение.');
    m.lastAdvanced=s.month;m.weather=[11,0,1].includes(s.month%12)?'snow':[8,9,10].includes(s.month%12)?'rain':'clear';
    for(const u of m.units)if(u.status==='ready'){
      u.fatigue=Math.max(0,u.fatigue-12);u.morale=clamp(u.morale+(s.player.food>=15?5:-5),0,100);u.food=0;u.supplied=s.player.food>=15;
    }
    for(const p of m.locations){
      const guard=m.units.filter(u=>u.location===p.id&&u.status==='ready').reduce((n,u)=>n+u.strength,0);
      p.bandits=clamp(p.bandits+(s.month-p.lastPatrol<3?-5:guard>=12?-3:p.id==='capital'?1:2)+(s.player.stability<40?1:0),0,100);
      const beforeUnrest=p.unrest;
      p.unrest=clamp(p.unrest+(s.player.stability<40?7+(s.player.food<20?4:0):-6)-(guard>15?1:0),0,100);
      if(beforeUnrest<40&&p.unrest>=40)entries.push(entry(`Недовольство растёт: ${location(p.id).name}.`,'Жители жалуются на нестабильность и снабжение. Понижение налогов, помощь и продовольствие могут снять причины волнений.'));
      if(p.unrest>=80&&!m.battle&&!m.pendingBattles.length){
        const ids=m.units.filter(u=>u.location===p.id&&u.status==='ready'&&u.strength).map(u=>u.id);
        if(ids.length){beginBattle(s,{location:p.id,kind:'rebellion',attackerName:'Вооружённые мятежники',unitIds:ids,defending:true,power:clamp(Math.round(p.unrest*.3),12,40)});entries.push(entry(`В ${location(p.id).name} начался вооружённый мятеж.`,`Предупреждения о недовольстве не были устранены. Выберите действия войск на карте; дальнейшее правление требует разрешить столкновение.`));}
        else {const before=snap(s);s.player.stability=Math.max(0,s.player.stability-4);s.player.gold=Math.max(0,s.player.gold-8);p.unrest=55;entries.push(entry(`Мятежники разграбили сборную палату: ${location(p.id).name}.`,'Низкая устойчивость и длительное недовольство перешли в открытое сопротивление. Полевых войск рядом не оказалось.',diff(before,s)));}
      }
      if(p.bandits>=70&&guard<12&&random()<.2){const before=snap(s);s.player.gold=Math.max(0,s.player.gold-7);s.player.food=Math.max(0,s.player.food-5);s.player.stability=Math.max(0,s.player.stability-2);entries.push(entry(`Разбойники перехватили обоз: ${location(p.id).name}.`,'Дорога долго оставалась без патрулей; растущую угрозу можно пресечь походом.',diff(before,s)));}
    }
    const marching=[];
    for(const march of m.marches){
      if(march.started>=s.month){marching.push(march);continue;}
      const before=snap(s);let lacked=false;
      for(const id of march.unitIds){const u=m.units.find(u=>u.id===id),need=ration(u),available=Math.min(u.food,need);u.food-=available;u.supplied=available===need;
        u.fatigue=clamp(u.fatigue+6+(m.weather==='clear'?0:4),0,100);
        if(u.supplied&&march.supply==='full'&&u.food>=need)u.morale=clamp(u.morale+3,0,100);
        if(!u.supplied){lacked=true;u.morale=clamp(u.morale-12,0,100);u.fatigue=clamp(u.fatigue+12,0,100);if(u.fatigue>55&&u.strength>0)u.strength--;}
      }
      s.player.army=total(m);march.food=march.unitIds.reduce((n,id)=>n+m.units.find(u=>u.id===id).food,0);march.remaining--;
      if(lacked)entries.push(entry(`В походе к ${location(march.target).name} не хватило провианта.`,'Лёгкий или недостаточный обоз привёл к голоду, усталости и падению духа; истощённые отряды могут терять людей ещё до боя.',diff(before,s)));
      if(march.remaining>0){marching.push(march);continue;}
      for(const id of march.unitIds){const u=m.units.find(u=>u.id===id);u.location=march.target;u.status='ready';}
      const site=m.locations.find(l=>l.id===march.target);
      if((march.mission==='expedition'&&site.bandits>=20)||(march.mission==='patrol'&&site.bandits>=40)){
        if(march.unitIds.some(id=>m.units.find(u=>u.id===id).strength>0)){
          beginBattle(s,{location:site.id,kind:'bandits',attackerName:'Разбойничий отряд',unitIds:march.unitIds,defending:false,power:clamp(Math.round(site.bandits*.45),8,55)});
          entries.push(entry(`Отряды настигли разбойников: ${location(site.id).name}.`,'Поход завершён. Бой проходит в этой местности; сыграют роль дорога, провиант, усталость и построение.'));
        }
      }else if(march.mission==='expedition'){const refund=returnSupplies(s,march.unitIds);entries.push(entry(`Лагерь у ${location(site.id).name} опустел.`,`Пока войска шли, разбойники ушли или были рассеяны. Остаток провианта (${refund}) возвращён в запасы.`,refund?{food:refund}:{}));}
      else if(march.mission==='patrol'){site.bandits=Math.max(0,site.bandits-28);site.unrest=Math.max(0,site.unrest-5);site.lastPatrol=s.month;const refund=returnSupplies(s,march.unitIds);entries.push(entry(`Патруль обследовал ${location(site.id).name}.`,`Разбойники ушли с дороги. Отряды остаются в указанной местности; остаток провианта (${refund}) передан местным складам.`,refund?{food:refund}:{}));}
      else {const refund=returnSupplies(s,march.unitIds);entries.push(entry(`${MISSIONS[march.mission]}: войска прибыли в ${location(site.id).name}.`,`Они находятся на месте и могут принять новый приказ. Остаток провианта (${refund}) возвращён в запасы княжества.`,refund?{food:refund}:{}));}
    }
    m.marches=marching;
    const incoming=[];
    for(const campaign of m.enemyMarches){
      if(campaign.started>=s.month){incoming.push(campaign);continue;}
      const need=2+Math.ceil(campaign.power/15);campaign.fatigue=clamp(campaign.fatigue+7+(m.weather==='clear'?0:4),0,100);
      if(campaign.food<need){campaign.morale=Math.max(10,campaign.morale-12);campaign.fatigue=clamp(campaign.fatigue+10,0,100);}campaign.food=Math.max(0,campaign.food-need);campaign.remaining--;
      if(campaign.remaining>0){incoming.push(campaign);continue;}
      const ids=m.units.filter(u=>u.location===campaign.target&&u.status==='ready'&&u.strength>0).map(u=>u.id);
      if(ids.length){beginBattle(s,{location:campaign.target,kind:'invasion',attackerId:campaign.attackerId,attackerName:nation(campaign.attackerId),unitIds:ids,defending:true,power:campaign.power,morale:campaign.morale,fatigue:campaign.fatigue});entries.push(entry(`Сражение у ${location(campaign.target).name}: ${nation(campaign.attackerId)} подошла к вашим войскам.`,'До противника уже добрались последствия собственного похода; ваши отряды защищают местность, в которой находятся.'));}
      else entries.push(raidWithoutDefenders(s,campaign));
    }
    m.enemyMarches=incoming;syncArmy(s);
    return entries;
  }
  function playerPower(s,b=s.military.battle){
    if(!b)return 0;
    const terrain=location(b.location).terrain;
    let power=b.unitIds.reduce((n,id)=>{const u=s.military.units.find(u=>u.id===id);let factor=(.65+u.morale/200)*(1-u.fatigue/160)*(1+u.experience/250);if(terrain==='forest'&&u.type==='cavalry')factor*=.7;if((terrain==='forest'||terrain==='hill')&&u.type==='archers')factor*=1.15;return n+u.strength*factor;},0);
    if(b.defending){if(terrain==='river')power*=1.25;if(terrain==='hill')power*=1.15;if(terrain==='fortress')power*=1+Math.min(.6,s.player.defense/150);}
    return Math.max(0,power);
  }
  function takeLosses(s,b,count){
    const units=b.unitIds.map(id=>s.military.units.find(u=>u.id===id));let left=count,actual=0;
    while(left&&units.some(u=>u.strength))for(const u of units)if(left&&u.strength){u.strength--;left--;actual++;}
    s.player.army=total(s.military);return actual;
  }
  function finishBattle(s,b,outcome){
    const m=s.military,site=m.locations.find(l=>l.id===b.location),finishBefore=snap(s);let text,loot=0;
    if(outcome==='victory'){
      site.bandits=Math.max(0,site.bandits-55);site.unrest=Math.max(0,site.unrest-35);site.lastPatrol=s.month;
      loot=b.kind==='bandits'?12:8;s.player.gold=Math.min(9999,s.player.gold+loot);s.player.food=Math.min(9999,s.player.food+6);s.player.stability=Math.min(100,s.player.stability+(b.kind==='rebellion'?4:2));
      text=b.kind==='bandits'?'Разбойничий отряд рассеян, дорога вновь доступна обозам.':'Противник оставил поле. Позиция удержана, оставшиеся войска приведены в порядок.';
    }else{
      const gold=Math.min(s.player.gold,outcome==='retreat'?6:14),food=Math.min(s.player.food,outcome==='retreat'?4:10);s.player.gold-=gold;s.player.food-=food;s.player.stability=Math.max(0,s.player.stability-(outcome==='retreat'?3:6));site.bandits=clamp(site.bandits+8,0,100);
      text=outcome==='retreat'?'Войска вышли из боя, сохранив оставшийся состав. Противник остался у местности и перехватил часть припасов.':'Позиция потеряна. Остатки отрядов начали отход к крепости; разграбленные припасы и вести о поражении ударили по княжеству.';
    }
    for(const id of b.unitIds){const u=m.units.find(u=>u.id===id);u.status='ready';u.location=b.location;u.experience=clamp(u.experience+(outcome==='victory'?4:1),0,100);u.morale=clamp(u.morale+(outcome==='victory'?7:-8),0,100);}
    if(outcome==='victory')returnSupplies(s,b.unitIds);
    else {
      const survivors=b.unitIds.filter(id=>m.units.find(u=>u.id===id).strength>0);
      if(survivors.length){
        const duration=clamp(Math.ceil(distance(b.location,'capital')/(1+s.player.roads*.3)),1,3);
        for(const id of survivors){const u=m.units.find(u=>u.id===id),needed=Math.max(0,Math.ceil(ration(u)*duration*.7)-u.food),taken=Math.min(s.player.food,needed);s.player.food-=taken;u.food+=taken;u.status='marching';}
        m.marches.push({id:'march-'+m.nextId++,target:'capital',unitIds:survivors,mission:'return',supply:'light',duration,remaining:duration,started:s.month,food:survivors.reduce((n,id)=>n+m.units.find(u=>u.id===id).food,0)});
        text+=` Возвращение в Арден займёт ${duration} мес.; уцелевшие отряды ещё в дороге.`;
      }
      const fallen=b.unitIds.filter(id=>!survivors.includes(id));returnSupplies(s,fallen);
    }
    const n=s.neighbors?.find(n=>n.id===b.attackerId);if(n)n.army=Math.max(0,n.army-b.enemyLosses);
    const title=outcome==='victory'?'Победа':outcome==='retreat'?'Организованное отступление':'Поражение';
    const resultChanges=diff(finishBefore,s);if(b.losses)resultChanges.army=-b.losses;
    m.lastBattle={id:b.id,month:s.month,location:b.location,locationName:location(b.location).name,attackerName:b.attackerName,kind:b.kind,outcome,title,text,losses:b.losses,enemyLosses:b.enemyLosses,loot,changes:resultChanges,log:[...b.log,text]};
    m.battle=m.pendingBattles.shift() || null;if(m.battle){m.battle.startPlayer=snap(s);m.battle.startedArmy=s.player.army;}syncArmy(s);return `${title}: ${text}`;
  }
  function issueBattleOrder(s,tactic,random,unitId=null,targetId='enemy-main'){
    const m=s.military,b=m?.battle;if(!b)throw new Error('Сражение сейчас не идёт.');
    const tacticRule=TACTICS.find(t=>t.id===tactic);if(!tacticRule)throw new Error('Неизвестный боевой приказ.');
    const before=snap(s);let result;
    if(tactic==='withdraw'){
      const possible=b.unitIds.reduce((n,id)=>n+m.units.find(u=>u.id===id).strength,0);
      const loss=takeLosses(s,b,Math.ceil(possible*(.025+random()*.035)));b.losses+=loss;b.log.push(`Отступление под прикрытием: потери силы ${loss}.`);result=finishBattle(s,b,'retreat');
    }else{
      const terrain=location(b.location).terrain,acting=unitId?m.units.find(u=>u.id===unitId&&b.unitIds.includes(u.id)&&u.strength>0):null;
      if(unitId&&!acting)throw new Error('Выбранный отряд не может выполнить приказ.');
      if(acting&&!tacticRule.types.includes(acting.type))throw new Error('Этот отряд не умеет выполнять выбранный приказ.');
      const activeUnits=acting?[acting]:b.unitIds.map(id=>m.units.find(u=>u.id===id)),basePower=acting?acting.strength*(.65+acting.morale/200)*(1-acting.fatigue/160)*(1+acting.experience/250):playerPower(s,b);
      let power=basePower;
      const archers=b.unitIds.filter(id=>m.units.find(u=>u.id===id).type==='archers').reduce((n,id)=>n+m.units.find(u=>u.id===id).strength,0);
      let attack=1,defend=1;
      if(tactic==='guard'){attack=.8;defend=1.3;}
      if(tactic==='advance'){attack=1.17;defend=.9;}
      if(tactic==='flank'){attack=terrain==='river'?.8:['forest','hill'].includes(terrain)?1.2:1.08;defend=.95;}
      if(tactic==='ranged'){attack=archers>0?(b.phase<2?1.22:1.05):.7;defend=1.08;}
      if(tactic==='melee'){attack=.78;defend=.62;}
      if(tactic==='fallback'){attack=.55;defend=1.35;}
      if(tactic==='charge'){attack=1.35;defend=.72;}
      if(acting){
        if(acting.type==='archers'){if(tactic==='ranged'&&b.phase<1)attack*=1.45;else if(tactic==='melee'){attack*=.72;defend*=.7;}else if(tactic==='fallback'){defend*=1.25;}else if(b.phase>=1){attack*=.42;defend*=.45;}}
        if(acting.type==='cavalry'&&targetId==='enemy-ranged')attack*=1.45;
        if(acting.type==='cavalry'&&tactic==='charge')attack*=targetId==='enemy-guard'?.72:1.15;
        if(acting.type==='infantry'&&tactic==='guard')defend*=1.25;
        if(targetId==='enemy-guard')attack*=.82;if(targetId==='enemy-reserve')attack*=.9;
      }
      const hostile=b.enemyPower*(.65+b.enemyMorale/200)*(1-b.enemyFatigue/170),enemyMoraleBefore=b.enemyMorale;
      const enemyLoss=Math.min(b.enemyPower,Math.max(1,Math.round(power*.1*attack*(.8+random()*.4))));
      let ownLoss;if(acting){const requested=Math.max(1,Math.round(hostile*.035/defend*(.8+random()*.4)*(acting.type==='archers'&&b.phase>=1?1.8:1)));ownLoss=Math.min(acting.strength,requested);acting.strength-=ownLoss;s.player.army=total(m);}else ownLoss=takeLosses(s,b,Math.max(1,Math.round(hostile*.055/defend*(.8+random()*.4))));
      b.enemyPower-=enemyLoss;b.enemyLosses+=enemyLoss;b.losses+=ownLoss;b.enemyMorale=clamp(Math.round(b.enemyMorale-enemyLoss*1.2),0,100);b.enemyFatigue=clamp(b.enemyFatigue+6,0,100);
      for(const u of activeUnits){u.fatigue=clamp(u.fatigue+(['flank','charge'].includes(tactic)?10:tactic==='fallback'?7:5),0,100);u.morale=clamp(Math.round(u.morale-ownLoss*.65+(enemyLoss>ownLoss?2:0)),0,100);}
      const tacticName=TACTICS.find(t=>t.id===tactic).name,advantage=enemyLoss-ownLoss;
      const position=({guard:'Пехота сомкнула щиты и удерживает свою клетку.',advance:'Пехота перешла на следующую линию и вошла в соприкосновение.',ranged:'Лучники остались в дальней линии и выпустили залп по выбранной цели.',melee:'Лучники вынули мечи и приняли опасный ближний бой.',fallback:'Лучники отошли на одну линию за прикрытие пехоты.',flank:'Конница сместилась к краю поля и заходит во фланг.',charge:'Конница пересекла линию поля и ударила по выбранному строю.'})[tactic]||'Стороны сохранили отдельные линии строя.';
      b.lastAction={tactic,tacticName,unitId:acting?.id||null,unitName:acting?.name||'Все отряды',targetId,ownLoss,enemyLoss,enemyMoraleBefore,enemyMoraleAfter:b.enemyMorale,advantage,assessment:advantage>=3?'Наш приказ дал заметное преимущество.':advantage<=-3?'Противник выиграл этот обмен ударами.':'Обмен оказался примерно равным.',position};
      b.log.push(`${tacticName}: потеря силы наших войск ${ownLoss}, противника ${enemyLoss}.`);b.phase++;
      if(!b.unitIds.some(id=>m.units.find(u=>u.id===id).strength>0))result=finishBattle(s,b,'defeat');
      else if(b.enemyPower<=0||b.enemyMorale<22)result=finishBattle(s,b,'victory');
      else if(b.phase>=3)result=finishBattle(s,b,playerPower(s,b)>=b.enemyPower*.9?'victory':'defeat');
      else result=b.log[b.log.length-1];
    }
    return [entry(result,`Местность: ${TERRAIN[location(b.location).terrain]}. Учитывались численность, опыт, дух, усталость, снабжение, погода и приказ.`,diff(before,s))];
  }
  function hasBattle(s){return Boolean(s.military?.battle);}
  function battleFeatures(b,terrain){
    const common=[{id:'command',kind:'command',label:'Командный пункт',x:12,y:79,effect:'Отсюда передают приказы.'},{id:'supply',kind:'cart',label:'Обоз и провиант',x:88,y:78,effect:'Потеря обоза ухудшает снабжение.'},{id:'stakes',kind:'stakes',label:'Колья и заграждения',x:67,y:57,effect:'Сдерживают конницу и обход.'},{id:'reserve',kind:'reserve',label:'Резерв',x:83,y:67,effect:'Вводится в решающей фазе.'}];
    const terrainObjects={forest:[{id:'trees-a',kind:'trees',label:'Густой лес',x:12,y:32,effect:'Скрывает обходные группы.'},{id:'trees-b',kind:'trees',label:'Лесная опушка',x:84,y:36,effect:'Мешает конному разгону.'}],hill:[{id:'hill',kind:'hill',label:'Господствующая высота',x:48,y:30,effect:'Стрелки сверху опаснее.'},{id:'rocks',kind:'rocks',label:'Каменная гряда',x:18,y:51,effect:'Укрытие от стрел.'}],river:[{id:'river',kind:'river',label:'Река',x:50,y:48,effect:'Переправа сужает строй.'},{id:'bridge',kind:'bridge',label:'Каменный мост',x:54,y:48,effect:'Ключевая точка столкновения.'}],plain:[{id:'farm',kind:'farm',label:'Край полей',x:16,y:42,effect:'Открытая линия обзора.'},{id:'ditch',kind:'ditch',label:'Дорожная канава',x:72,y:43,effect:'Ломает быстрый натиск.'}],fort:[{id:'wall',kind:'wall',label:'Крепостная стена',x:50,y:61,effect:'Защитники получают преимущество.'},{id:'tower-a',kind:'tower',label:'Западная башня',x:25,y:53,effect:'Стрелковая позиция.'},{id:'tower-b',kind:'tower',label:'Надвратная башня',x:75,y:53,effect:'Защищает ворота.'},{id:'gate',kind:'gate',label:'Главные ворота',x:50,y:66,effect:'Если ворота падут, враг войдёт в город.'}]};
    const phase=b.phase||0,marks=phase?[{id:'arrows',kind:'arrows',label:'Залп стрел',x:42+phase*6,y:42,effect:'След последнего обмена ударами.'},{id:'wounded',kind:'wounded',label:'Перевязочный пункт',x:22,y:75,effect:'Сюда относят раненых.'}]:[];
    return [...common,...(terrainObjects[terrain]||terrainObjects.plain),...marks];
  }
  function view(s){
    const m=s.military || create(s),placeView=l=>{const p=m.locations.find(p=>p.id===l.id);return {...l,...copy(p),terrainLabel:TERRAIN[l.terrain],distance:distance('capital',l.id),friendlyUnits:m.units.filter(u=>u.location===l.id&&u.status==='ready').map(u=>u.id),threat:p.unrest>=60?'Волнения':p.bandits>=55?'Разбойники усилились':p.bandits>=25?'Неспокойная дорога':'Относительно спокойно'};};
    const battle=m.battle?{...copy(m.battle),locationName:location(m.battle.location).name,terrain:location(m.battle.location).terrain,terrainLabel:TERRAIN[location(m.battle.location).terrain],phaseName:['Сближение','Схватка','Развязка'][m.battle.phase],playerPower:Math.round(playerPower(s,m.battle)),enemyEstimate:{min:Math.max(0,Math.floor(m.battle.enemyPower*.85)),max:Math.ceil(m.battle.enemyPower*1.15)},enemyUnits:[{id:'enemy-main',name:m.battle.kind==='bandits'?'Главная шайка':'Главный строй',type:'Пехота',share:.38},{id:'enemy-ranged',name:m.battle.kind==='bandits'?'Стрелки в укрытии':'Передовые стрелки',type:'Стрелки',share:.2},{id:'enemy-mobile',name:m.battle.kind==='invasion'?'Конный резерв':'Обходная группа',type:m.battle.kind==='invasion'?'Конница':'Лёгкие бойцы',share:.18},{id:'enemy-guard',name:m.battle.kind==='bandits'?'Люди атамана':'Знамённая стража',type:'Тяжёлая пехота',share:.14},{id:'enemy-reserve',name:'Дальний резерв',type:'Резерв',share:.1}].map(u=>({...u,strength:Math.max(0,Math.round(m.battle.enemyPower*u.share))})),features:battleFeatures(m.battle,m.battle.location==='capital'?'fort':location(m.battle.location).terrain),tactics:copy(TACTICS)}:null;
    const profiles={infantry:{attack:7,armor:8,range:1,speed:4,melee:9,role:'Удерживает строй и защищает стрелков.'},archers:{attack:9,armor:3,range:8,speed:5,melee:2,role:'Силен на расстоянии, крайне уязвим в ближнем бою.'},cavalry:{attack:10,armor:7,range:1,speed:9,melee:8,role:'Быстрый удар, обход и атака стрелков.'}};
    return {locations:LOCATIONS.map(placeView),units:m.units.map(u=>({...copy(u),...profiles[u.type],typeLabel:TYPES[u.type],locationName:location(u.location).name,statusLabel:({ready:'На месте',marching:'В походе',battle:'В бою'})[u.status]})),reserve:m.reserve,
      marches:m.marches.map(p=>({...copy(p),targetName:location(p.target).name,missionLabel:MISSIONS[p.mission]})),
      enemyMarches:m.enemyMarches.map(p=>({id:p.id,attackerName:nation(p.attackerId),target:p.target,targetName:location(p.target).name,remaining:p.remaining,estimate:{min:Math.floor(p.power*.75),max:Math.ceil(p.power*1.25)}})),
      battle,lastBattle:copy(m.lastBattle),weather:m.weather,summary:{totalStrength:s.player.army,readyStrength:m.units.filter(u=>u.status==='ready').reduce((n,u)=>n+u.strength,0),banditSites:m.locations.filter(p=>p.bandits>=40).length,unrestSites:m.locations.filter(p=>p.unrest>=40).length}};
  }
  function validate(m,s){
    const obj=o=>o&&typeof o==='object'&&!Array.isArray(o),num=(n,a=0,b=9999)=>Number.isInteger(n)&&n>=a&&n<=b,arr=(a,n)=>Array.isArray(a)&&a.length<=n,str=t=>typeof t==='string'&&t.length<=1500;
    if(!obj(m)||m.version!==1||!num(m.nextId,1,1e9)||!num(m.reserve)||!num(m.lastAdvanced,0,s.month)||!['clear','rain','snow'].includes(m.weather))return false;
    if(!arr(m.units,3)||m.units.length!==3||new Set(m.units.map(u=>u?.id)).size!==3)return false;
    for(const u of m.units)if(!obj(u)||u.id!==u.type||!Object.hasOwn(TYPES,u.type)||!str(u.name)||!num(u.strength)||!num(u.morale,0,100)||!num(u.fatigue,0,100)||!num(u.experience,0,100)||!location(u.location)||!['ready','marching','battle'].includes(u.status)||!num(u.food,0,10000)||typeof u.supplied!=='boolean')return false;
    if(total(m)!==s.player.army)return false;
    if(!arr(m.locations,6)||m.locations.length!==6||new Set(m.locations.map(p=>p?.id)).size!==6||!m.locations.every(p=>obj(p)&&location(p.id)&&num(p.bandits,0,100)&&num(p.unrest,0,100)&&num(p.lastPatrol,-10,s.month)))return false;
    if(!arr(m.marches,3)||!arr(m.enemyMarches,6)||!arr(m.pendingBattles,6))return false;
    const ids=ids=>arr(ids,3)&&ids.length>0&&new Set(ids).size===ids.length&&ids.every(id=>m.units.some(u=>u.id===id));
    for(const p of m.marches)if(!obj(p)||!str(p.id)||!location(p.target)||!ids(p.unitIds)||!Object.hasOwn(MISSIONS,p.mission)||!['light','normal','full'].includes(p.supply)||!num(p.duration,1,3)||!num(p.remaining,1,p.duration)||!num(p.started,0,s.month)||!num(p.food,0,30000))return false;
    if(new Set(m.marches.flatMap(p=>p.unitIds)).size!==m.marches.flatMap(p=>p.unitIds).length)return false;
    for(const p of m.enemyMarches)if(!obj(p)||!str(p.id)||!['val','mer','nor'].includes(p.attackerId)||!location(p.target)||!num(p.power,1,120)||!num(p.initialPower,1,120)||!num(p.remaining,1,3)||!num(p.duration,1,3)||!num(p.started,0,s.month)||!num(p.food,0,30000)||!num(p.morale,0,100)||!num(p.fatigue,0,100))return false;
    const battleValid=b=>obj(b)&&str(b.id)&&location(b.location)&&['bandits','invasion','rebellion'].includes(b.kind)&&(b.attackerId===null||['val','mer','nor'].includes(b.attackerId))&&str(b.attackerName)&&ids(b.unitIds)&&typeof b.defending==='boolean'&&num(b.phase,0,2)&&num(b.enemyPower,0,9999)&&num(b.initialEnemyPower,1,9999)&&num(b.enemyMorale,0,100)&&num(b.enemyFatigue,0,100)&&num(b.startedArmy)&&obj(b.startPlayer)&&['gold','food','army','stability'].every(k=>num(b.startPlayer[k]))&&['clear','rain','snow'].includes(b.weather)&&num(b.losses)&&num(b.enemyLosses)&&arr(b.log,10)&&b.log.every(str);
    if(m.battle!==null&&!battleValid(m.battle))return false;
    if(!m.pendingBattles.every(battleValid))return false;
    const active=new Set([...m.marches.flatMap(p=>p.unitIds),...(m.battle?.unitIds||[]),...m.pendingBattles.flatMap(b=>b.unitIds)]);
    const allActive=[...m.marches.flatMap(p=>p.unitIds),...(m.battle?.unitIds||[]),...m.pendingBattles.flatMap(b=>b.unitIds)];
    if(active.size!==allActive.length)return false;
    if(m.marches.some(p=>p.unitIds.some(id=>m.units.find(u=>u.id===id).status!=='marching')))return false;
    if([...(m.battle?[m.battle]:[]),...m.pendingBattles].some(b=>b.unitIds.some(id=>m.units.find(u=>u.id===id).status!=='battle')))return false;
    if(m.units.some(u=>(u.status==='ready')===active.has(u.id)))return false;
    if(m.lastBattle!==null){const b=m.lastBattle;if(!obj(b)||!str(b.id)||!location(b.location)||!str(b.locationName)||!str(b.attackerName)||!['bandits','invasion','rebellion'].includes(b.kind)||!['victory','defeat','retreat'].includes(b.outcome)||!str(b.title)||!str(b.text)||!num(b.month,0,s.month)||!num(b.losses)||!num(b.enemyLosses)||!num(b.loot)||!obj(b.changes)||!Object.entries(b.changes).every(([k,v])=>['gold','food','army','stability'].includes(k)&&num(v,-9999,9999))||!arr(b.log,12)||!b.log.every(str))return false;}
    return true;
  }
  return {LOCATIONS:copy(LOCATIONS),TERRAIN:copy(TERRAIN),TACTICS:copy(TACTICS),create,syncArmy,homeStrength,quote,launch,advance,issueBattleOrder,scheduleEnemyRaid,view,validate,hasBattle};
});
