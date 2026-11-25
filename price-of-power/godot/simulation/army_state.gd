class_name ArmyState
extends Resource

enum BattleStatus { NONE, DEPLOYMENT, FIGHTING, VICTORY, DEFEAT, RETREATED }

const TURN_LIMIT: int = 6
const BROKEN_MORALE: int = 24
const BROKEN_UNITS_TO_WIN: int = 2
const DEFENCE_ROUNDS_TO_WIN: int = 4
const SURVIVING_DEFENDERS: int = 12

const UNIT_NAMES: Dictionary = {"retinue": "Княжеская дружина", "archers": "Стрелки перевала", "cavalry": "Конные дозорные"}
const ORDERS: Dictionary = {
	"retinue": {"shield": "Сомкнуть щиты", "advance": "Наступать строем", "hold": "Удерживать рубеж"},
	"archers": {"volley": "Прицельный залп", "suppress": "Подавляющий огонь", "withdraw": "Отойти за пехоту"},
	"cavalry": {"flank": "Обойти фланг", "charge": "Ударить в лоб", "reserve": "Остаться в резерве"}
}

@export var status: BattleStatus = BattleStatus.NONE
@export var turn: int = 0
@export var terrain: String = "лесная дорога у каменной переправы"
@export var friendly: Dictionary = {}
@export var enemy: Dictionary = {}
@export var pending_orders: Dictionary = {}
@export var battle_log: Array[Dictionary] = []
@export var supplies: int = 70
@export var defence_rounds: int = 0
@export var victory_reason: String = ""

func begin_border_battle(posture: String) -> bool:
	if status not in [BattleStatus.NONE, BattleStatus.VICTORY, BattleStatus.DEFEAT, BattleStatus.RETREATED]: return false
	status = BattleStatus.DEPLOYMENT
	turn = 0
	supplies = 70
	defence_rounds = 0
	victory_reason = ""
	pending_orders.clear()
	battle_log.clear()
	friendly = {
		"retinue": {"count": 36, "morale": 78, "fatigue": 8, "depth": 2},
		"archers": {"count": 28, "morale": 72, "fatigue": 5, "depth": 1},
		"cavalry": {"count": 18, "morale": 75, "fatigue": 10, "depth": 2}
	}
	enemy = {
		"spears": {"name": "Северные копейщики", "count": 42, "morale": 68},
		"raiders": {"name": "Лёгкие всадники", "count": 24, "morale": 64},
		"bows": {"name": "Лесные стрелки", "count": 22, "morale": 66}
	}
	if posture == "ambush": enemy["raiders"]["count"] = 18
	if posture == "fortified": friendly["retinue"]["morale"] = 84
	return true

func deploy(unit_id: String, depth: int) -> bool:
	if status != BattleStatus.DEPLOYMENT or not friendly.has(unit_id) or depth not in [1, 2, 3]: return false
	friendly[unit_id]["depth"] = depth
	return true

func start_combat() -> bool:
	if status != BattleStatus.DEPLOYMENT: return false
	status = BattleStatus.FIGHTING
	turn = 1
	return true

func issue_order(unit_id: String, order_id: String) -> bool:
	if status != BattleStatus.FIGHTING or not friendly.has(unit_id) or int(friendly[unit_id]["count"]) <= 0: return false
	if not (ORDERS[unit_id] as Dictionary).has(order_id): return false
	pending_orders[unit_id] = order_id
	return true

func ready_to_resolve() -> bool:
	if status != BattleStatus.FIGHTING: return false
	for unit_id: String in friendly:
		if int(friendly[unit_id]["count"]) > 0 and not pending_orders.has(unit_id): return false
	return true

func broken_enemy_units() -> int:
	var result := 0
	for unit: Dictionary in enemy.values():
		if int(unit.get("count", 0)) <= 0 or int(unit.get("morale", 0)) <= BROKEN_MORALE:
			result += 1
	return result

func objective_text() -> String:
	return "Сорвите нападение за %d ходов. Враг отступит, если два его отряда потеряют боевой дух. Оборона оценивается в конце боя.\nОтряды врага вне боя %d/%d · ходов в обороне %d/%d" % [
		TURN_LIMIT, broken_enemy_units(), BROKEN_UNITS_TO_WIN, defence_rounds, DEFENCE_ROUNDS_TO_WIN
	]

func defence_orders_text() -> String:
	return "Для зачёта обороны дружина держит рубеж или смыкает щиты, лучники стреляют, конница ждёт в резерве или прикрывает фланг. К концу боя нужно сохранить провиант и не меньше %d дружинников." % SURVIVING_DEFENDERS

func resolve_turn() -> bool:
	if not ready_to_resolve(): return false
	var enemy_losses := {"spears": 0, "raiders": 0, "bows": 0}
	var friendly_losses := {"retinue": 0, "archers": 0, "cavalry": 0}
	_apply_friendly_orders(enemy_losses, friendly_losses)
	_apply_enemy_response(friendly_losses)
	for unit_id: String in friendly:
		friendly_losses[unit_id] = mini(int(friendly[unit_id]["count"]), int(friendly_losses[unit_id]))
		friendly[unit_id]["count"] = int(friendly[unit_id]["count"]) - int(friendly_losses[unit_id])
		friendly[unit_id]["fatigue"] = mini(100, int(friendly[unit_id]["fatigue"]) + 7)
	for unit_id: String in enemy:
		var unit: Dictionary = enemy[unit_id]
		var before := int(unit["count"])
		var loss := mini(before, int(enemy_losses[unit_id]))
		enemy_losses[unit_id] = loss
		unit["count"] = before - loss
		if loss > 0:
			var shock := 4 + ceili(float(loss) * 60.0 / before)
			unit["morale"] = maxi(0, int(unit["morale"]) - shock)
	if int(friendly["retinue"]["count"]) > 0 and _has_defence_orders(pending_orders):
		defence_rounds += 1
	supplies = maxi(0, supplies - 8)
	battle_log.append({
		"turn": turn, "friendly_losses": friendly_losses.duplicate(), "enemy_losses": enemy_losses.duplicate(),
		"orders": pending_orders.duplicate(), "enemy_broken": broken_enemy_units(), "defence_rounds": defence_rounds
	})
	pending_orders.clear()
	if _total(friendly) <= 0 or _average_morale() <= 18:
		status = BattleStatus.DEFEAT
	elif broken_enemy_units() >= BROKEN_UNITS_TO_WIN:
		status = BattleStatus.VICTORY
		victory_reason = "enemy_broke"
	elif turn >= TURN_LIMIT and supplies > 0 and defence_rounds >= DEFENCE_ROUNDS_TO_WIN and int(friendly["retinue"]["count"]) >= SURVIVING_DEFENDERS:
		status = BattleStatus.VICTORY
		victory_reason = "position_held"
	elif turn >= TURN_LIMIT or supplies <= 0:
		status = BattleStatus.RETREATED
	else:
		turn += 1
	return true

func _apply_friendly_orders(enemy_losses: Dictionary, friendly_losses: Dictionary) -> void:
	for unit_id: String in pending_orders:
		var order := str(pending_orders[unit_id])
		var count := int(friendly[unit_id]["count"])
		match "%s:%s" % [unit_id, order]:
			"retinue:shield": friendly_losses["retinue"] = maxi(0, int(friendly_losses["retinue"]) - 2)
			"retinue:advance": enemy_losses["spears"] += maxi(2, count / 9)
			"retinue:hold": enemy_losses["raiders"] += maxi(1, count / 15)
			"archers:volley": enemy_losses["spears"] += maxi(2, count / 6)
			"archers:suppress": enemy_losses["bows"] += maxi(2, count / 8)
			"archers:withdraw": friendly_losses["archers"] = maxi(0, int(friendly_losses["archers"]) - 3)
			"cavalry:flank": enemy_losses["bows"] += maxi(3, count / 4)
			"cavalry:charge":
				enemy_losses["spears"] += maxi(3, count / 5)
				friendly_losses["cavalry"] += 3
			"cavalry:reserve": friendly["cavalry"]["morale"] = mini(100, int(friendly["cavalry"]["morale"]) + 3)

func _apply_enemy_response(friendly_losses: Dictionary) -> void:
	var spear_pressure := _active_enemy_count("spears") / 12
	var rider_pressure := _active_enemy_count("raiders") / 10
	var bow_pressure := _active_enemy_count("bows") / 11
	friendly_losses["retinue"] += spear_pressure + bow_pressure
	friendly_losses["archers"] += rider_pressure
	if str(pending_orders.get("archers", "")) == "withdraw": friendly_losses["archers"] = maxi(0, int(friendly_losses["archers"]) - 2)
	if str(pending_orders.get("retinue", "")) == "shield": friendly_losses["retinue"] = maxi(0, int(friendly_losses["retinue"]) - 3)
	friendly_losses["cavalry"] += maxi(0, bow_pressure - 1)

func _active_enemy_count(unit_id: String) -> int:
	var unit: Dictionary = enemy[unit_id]
	return int(unit["count"]) if int(unit["morale"]) > BROKEN_MORALE else 0

func _has_defence_orders(orders: Dictionary) -> bool:
	return (
		orders.get("retinue") in ["hold", "shield"]
		and orders.get("archers") in ["volley", "suppress"]
		and orders.get("cavalry") in ["reserve", "flank"]
	)

func _total(units: Dictionary) -> int:
	var result := 0
	for unit: Dictionary in units.values(): result += int(unit.get("count", 0))
	return result

func _average_morale() -> int:
	var total := 0
	var living := 0
	for unit: Dictionary in friendly.values():
		if int(unit["count"]) > 0:
			total += int(unit["morale"])
			living += 1
	return total / maxi(1, living)

func to_data() -> Dictionary:
	return {
		"status": int(status), "turn": turn, "terrain": terrain, "friendly": friendly.duplicate(true),
		"enemy": enemy.duplicate(true), "pending_orders": pending_orders.duplicate(true),
		"battle_log": battle_log.duplicate(true), "supplies": supplies, "defence_rounds": defence_rounds,
		"victory_reason": victory_reason
	}

func load_data(data: Dictionary) -> void:
	status = clampi(int(data.get("status", 0)), 0, BattleStatus.size() - 1) as BattleStatus
	turn = maxi(0, int(data.get("turn", 0)))
	terrain = str(data.get("terrain", terrain))
	friendly = (data.get("friendly", {}) as Dictionary).duplicate(true)
	enemy = (data.get("enemy", {}) as Dictionary).duplicate(true)
	pending_orders = (data.get("pending_orders", {}) as Dictionary).duplicate(true)
	battle_log.assign(data.get("battle_log", []))
	supplies = maxi(0, int(data.get("supplies", 70)))
	defence_rounds = clampi(int(data.get("defence_rounds", 0)), 0, TURN_LIMIT)
	if not data.has("defence_rounds"):
		for record: Dictionary in battle_log:
			if _has_defence_orders(record.get("orders", {})):
				defence_rounds += 1
		defence_rounds = mini(defence_rounds, TURN_LIMIT)
	victory_reason = str(data.get("victory_reason", ""))
