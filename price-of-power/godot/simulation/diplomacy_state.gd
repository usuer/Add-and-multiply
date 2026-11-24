class_name DiplomacyState
extends Resource

const NEIGHBORS: Dictionary = {
	"velgrad": {"name": "Велеградское княжество", "leader": "Князь Мстислав Зубр", "character": "Старая военная знать; уважает силу и исполненные договоры.", "goal": "Получить безопасный путь к южным рынкам", "fear": "Оказаться окружённым союзом соседей", "strength": 68, "goods": {"grain": 10, "wood": 8}},
	"sarna": {"name": "Сарнская торговая республика", "leader": "Первая консул Агата Вельс", "character": "Совет купеческих домов; ищет прибыль и избегает открытой войны.", "goal": "Закрепить привилегии своих купцов в Ардене", "fear": "Потерять караванные пути из-за войны", "strength": 42, "goods": {"tools": 5, "worked_iron": 6}},
	"north_march": {"name": "Северная марка", "leader": "Маркграф Отмар Ренн", "character": "Пограничные бароны спорят между собой, но быстро объединяются перед угрозой.", "goal": "Расширить влияние на спорные северные земли", "fear": "Что слабость баронов станет известна чужой разведке", "strength": 57, "goods": {"weapons": 4, "wood": 10}}
}

@export var relations: Dictionary = {"velgrad": 4, "sarna": 16, "north_march": -12}
@export var intelligence: Dictionary = {"velgrad": 0, "sarna": 1, "north_march": 0}
@export var coerced_discount: Dictionary = {}
@export var action_history: Array[Dictionary] = []

func relation_label(neighbor_id: String) -> String:
	var value := int(relations.get(neighbor_id, 0))
	if value >= 25: return "дружественные"
	if value >= 5: return "деловые"
	if value > -15: return "настороженные"
	return "враждебные"

func known_strength(neighbor_id: String) -> String:
	var level := int(intelligence.get(neighbor_id, 0))
	if level <= 0: return "силы неизвестны"
	var strength := int(NEIGHBORS[neighbor_id]["strength"])
	if level == 1: return "примерно %d–%d" % [maxi(0, strength - 12), strength + 12]
	return "оценка разведки: %d" % strength

func pack_price(neighbor_id: String, good_id: String) -> int:
	if not NEIGHBORS.has(neighbor_id) or not (NEIGHBORS[neighbor_id]["goods"] as Dictionary).has(good_id): return -1
	var base := int(NEIGHBORS[neighbor_id]["goods"][good_id])
	var relation_adjustment := -int(relations.get(neighbor_id, 0)) / 10
	var pressure_discount := int(coerced_discount.get(neighbor_id, 0))
	return maxi(2, base + relation_adjustment - pressure_discount)

func buy_pack(state: WorldState, neighbor_id: String, good_id: String) -> bool:
	var price := pack_price(neighbor_id, good_id)
	if not state.can_govern() or price < 0 or state.state_treasury < price: return false
	state.state_treasury -= price
	state.resources[good_id] = int(state.resources.get(good_id, 0)) + 10
	relations[neighbor_id] = clampi(int(relations[neighbor_id]) + 1, -100, 100)
	_log(state, neighbor_id, "trade_%s" % good_id)
	state.add_fatigue(1)
	return true

func can_spy(state: WorldState, neighbor_id: String) -> bool:
	if not state.can_govern() or not NEIGHBORS.has(neighbor_id) or state.state_treasury < 5: return false
	return not str(state.council.appointments.get("intelligence", "")).is_empty() or not state.justice.informants.is_empty()

func spy(state: WorldState, neighbor_id: String) -> bool:
	if not can_spy(state, neighbor_id): return false
	state.state_treasury -= 5
	intelligence[neighbor_id] = mini(3, int(intelligence.get(neighbor_id, 0)) + 1)
	_log(state, neighbor_id, "spy")
	state.add_fatigue(2)
	return true

func threaten(state: WorldState, neighbor_id: String) -> bool:
	if not state.can_govern() or not NEIGHBORS.has(neighbor_id): return false
	var our_power := int(state.resources.get("weapons", 0)) * 2 + state.public_order / 2
	var their_power := int(NEIGHBORS[neighbor_id]["strength"])
	relations[neighbor_id] = clampi(int(relations[neighbor_id]) - 10, -100, 100)
	if our_power >= their_power:
		coerced_discount[neighbor_id] = 3
		_log(state, neighbor_id, "threat_succeeded")
	else:
		coerced_discount.erase(neighbor_id)
		_log(state, neighbor_id, "threat_failed")
	state.add_fatigue(3)
	return true

func can_sabotage(state: WorldState, neighbor_id: String) -> bool:
	return state.can_govern() and NEIGHBORS.has(neighbor_id) and int(intelligence.get(neighbor_id, 0)) >= 2 and state.state_treasury >= 9

func sabotage(state: WorldState, neighbor_id: String) -> bool:
	if not can_sabotage(state, neighbor_id): return false
	state.state_treasury -= 9
	intelligence[neighbor_id] = maxi(0, int(intelligence[neighbor_id]) - 1)
	relations[neighbor_id] = clampi(int(relations[neighbor_id]) - 15, -100, 100)
	state.facts["sabotage_%s" % neighbor_id] = true
	_log(state, neighbor_id, "sabotage")
	state.add_fatigue(3)
	return true

func last_action(neighbor_id: String) -> String:
	for index in range(action_history.size() - 1, -1, -1):
		if action_history[index]["neighbor"] == neighbor_id: return str(action_history[index]["kind"])
	return ""

func _log(state: WorldState, neighbor_id: String, kind: String) -> void:
	action_history.append({"cycle": state.calendar.cycle, "neighbor": neighbor_id, "kind": kind})
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "diplomacy", "neighbor": neighbor_id, "action": kind})

func to_data() -> Dictionary:
	return {"relations": relations.duplicate(true), "intelligence": intelligence.duplicate(true), "coerced_discount": coerced_discount.duplicate(true), "action_history": action_history.duplicate(true)}

func load_data(data: Dictionary) -> void:
	relations = (data.get("relations", relations) as Dictionary).duplicate(true)
	intelligence = (data.get("intelligence", intelligence) as Dictionary).duplicate(true)
	coerced_discount = (data.get("coerced_discount", {}) as Dictionary).duplicate(true)
	action_history.assign(data.get("action_history", []))
