class_name GovernancePolicy
extends Resource

const CATEGORIES: Dictionary = {
	"labor": {"title": "Режим труда", "options": {"seasonal": "Сезонный распорядок", "extended": "Удлинённая рабочая неделя", "protected": "Ограничение тяжёлых работ"}},
	"work_age": {"title": "Возраст работы", "options": {"twelve": "С двенадцати лет", "fourteen": "С четырнадцати лет", "sixteen": "С шестнадцати лет"}},
	"mobilization": {"title": "Воинская повинность", "options": {"peace": "Мирный набор", "levy": "Ополчение по дворам", "total": "Всеобщая мобилизация"}},
	"identity": {"title": "Учёт жителей", "options": {"parish": "Приходские книги", "registry": "Княжеский реестр", "travel_charters": "Именные дорожные грамоты"}},
	"justice": {"title": "Уголовное наказание", "options": {"restitution": "Возмещение пострадавшему", "strict": "Строгие сроки и тюрьма", "exemplary": "Показательные наказания"}}
}

@export var active: Dictionary = {"labor": "seasonal", "work_age": "fourteen", "mobilization": "peace", "identity": "parish", "justice": "restitution"}
@export var history: Array[Dictionary] = []

func enact(state: WorldState, category_id: String, option_id: String) -> bool:
	if not state.can_govern() or not CATEGORIES.has(category_id) or not (CATEGORIES[category_id]["options"] as Dictionary).has(option_id):
		return false
	var previous := str(active.get(category_id, ""))
	if previous == option_id:
		return false
	active[category_id] = option_id
	history.append({"cycle": state.calendar.cycle, "category": category_id, "previous": previous, "option": option_id})
	state.add_fatigue(3)
	_apply_immediate_reaction(state, category_id, option_id)
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "policy_changed", "category": category_id, "option": option_id})
	return true

func _apply_immediate_reaction(state: WorldState, category_id: String, option_id: String) -> void:
	match "%s:%s" % [category_id, option_id]:
		"labor:extended": (state.factions["guilds"] as FactionState).react(state.calendar.cycle, -3, "Князь разрешил удлинить рабочую неделю в мастерских.")
		"labor:protected": (state.factions["guilds"] as FactionState).react(state.calendar.cycle, 2, "Тяжёлые работы получили ограничения по времени.")
		"work_age:twelve": (state.factions["clergy"] as FactionState).react(state.calendar.cycle, -4, "Детям разрешили раньше выходить на полный рабочий день.")
		"work_age:sixteen": (state.factions["rural"] as FactionState).react(state.calendar.cycle, 2, "Подростков до шестнадцати лет освободили от обязательного труда.")
		"mobilization:total": (state.factions["military"] as FactionState).react(state.calendar.cycle, 5, "Княжество перешло ко всеобщей мобилизации.")
		"identity:travel_charters": (state.factions["guilds"] as FactionState).react(state.calendar.cycle, -2, "Для поездок и торговли потребовали именные грамоты.")
		"justice:exemplary": (state.factions["rural"] as FactionState).react(state.calendar.cycle, -4, "Суды перешли к публичным показательным наказаниям.")

func monthly_gold_modifier() -> int:
	var result := 0
	if active["labor"] == "extended": result += 3
	if active["labor"] == "protected": result -= 2
	if active["work_age"] == "twelve": result += 2
	if active["work_age"] == "sixteen": result -= 2
	if active["mobilization"] == "total": result -= 6
	if active["identity"] == "travel_charters": result -= 1
	return result

func monthly_health_modifier() -> int:
	var result := 0
	if active["labor"] == "extended": result -= 2
	if active["labor"] == "protected": result += 2
	if active["work_age"] == "twelve": result -= 2
	if active["work_age"] == "sixteen": result += 1
	return result

func monthly_order_modifier() -> int:
	var result := 0
	if active["identity"] == "registry": result += 1
	if active["identity"] == "travel_charters": result += 3
	if active["justice"] == "strict": result += 2
	if active["justice"] == "exemplary": result += 3
	if active["mobilization"] == "total": result -= 2
	return result

func monthly_weapon_modifier() -> int:
	if active["mobilization"] == "total": return 4
	if active["mobilization"] == "levy": return 1
	return 0

func to_data() -> Dictionary:
	return {"active": active.duplicate(true), "history": history.duplicate(true)}

func load_data(data: Dictionary) -> void:
	active = (data.get("active", active) as Dictionary).duplicate(true)
	history.assign(data.get("history", []))
