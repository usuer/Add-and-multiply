class_name OpeningDecision
extends Resource

enum Status { WAITING, READY, RESOLVED }

const FUNERAL_PLANS: Dictionary = {
	"modest": {"title": "Сдержанная семейная церемония", "description": "Короткое прощание в храме без большого приёма и дальних гостей.", "cost": 4},
	"solemn": {"title": "Достойные княжеские похороны", "description": "Положенный обряд, городская процессия и поминальный стол для прибывших вассалов.", "cost": 10},
	"grand": {"title": "Большое прощание со старым князем", "description": "Созвать представителей всех областей и показать, что переход власти проходит без смуты.", "cost": 18}
}

const GRAIN_RESPONSES: Dictionary = {
	"partial": {"title": "Отправить восемь мер сейчас", "description": "Хватит ближайшим к городу деревням примерно на две недели; остальные продолжат ждать.", "grain": 8, "gold": 0},
	"full": {"title": "Отправить большой обоз", "description": "Выдать зерно из княжеского запаса и оплатить охрану с подводами.", "grain": 18, "gold": 2},
	"purchase": {"title": "Купить зерно за границей", "description": "Сохранить местный резерв, но срочно заплатить сарнским купцам за привозное зерно.", "grain": 0, "gold": 14},
	"defer": {"title": "Сначала проверить областные книги", "description": "Не выдавать зерно, пока писцы не выяснят, куда делся прежний запас. Деревни пока помощи не получат.", "grain": 0, "gold": 0}
}

const NOBILITY_REACTIONS := {
	"modest": "Часть знати сочла прощание с прежним князем слишком скромным.",
	"solemn": "Знать увидела в церемонии уважение к традиции без показной роскоши.",
	"grand": "Великая церемония укрепила представление о силе княжеского дома."
}
const RURAL_REACTIONS := {
	"partial": "Ближние деревни ждут обоз. Дальние старосты просят сообщить, когда помощь дойдёт и до них.",
	"full": "Старосты благодарят за большой обоз. В дальних деревнях пока сокращают порции в ожидании зерна.",
	"purchase": "Старосты получили грамоту об оплаченном заказе. Пока купцы не доставили зерно, раздавать нечего.",
	"defer": "Просителей отправили ждать проверки, пока в деревнях сокращают хлебные пайки."
}
const FAMILY_REACTIONS := {
	"modest": "Вы предпочли сдержанность во время семейного траура.",
	"solemn": "Вы устроили достойное прощание с отцом.",
	"grand": "Вы превратили семейный траур в событие всего княжества.",
	"family_funds": "Вы распорядились семейными средствами ради государственного решения."
}

@export var status: Status = Status.WAITING
@export var funeral_plan: String = ""
@export var grain_response: String = ""
@export var funding_source: String = "state"
@export var resolved_cycle: int = 0
@export var observed_outcome: String = ""
@export var reaction_snapshot: Array[String] = []

func choose_funeral(plan_id: String) -> bool:
	if status == Status.RESOLVED or not FUNERAL_PLANS.has(plan_id):
		return false
	funeral_plan = plan_id
	_update_readiness()
	return true

func choose_grain(response_id: String) -> bool:
	if status == Status.RESOLVED or not GRAIN_RESPONSES.has(response_id):
		return false
	grain_response = response_id
	_update_readiness()
	return true

func choose_funding(source: String) -> bool:
	if status == Status.RESOLVED or source not in ["state", "family"]:
		return false
	funding_source = source
	return true

func required_gold() -> int:
	if not FUNERAL_PLANS.has(funeral_plan) or not GRAIN_RESPONSES.has(grain_response):
		return 0
	return int(FUNERAL_PLANS[funeral_plan]["cost"]) + int(GRAIN_RESPONSES[grain_response]["gold"])

func required_grain() -> int:
	if not GRAIN_RESPONSES.has(grain_response):
		return 0
	return int(GRAIN_RESPONSES[grain_response]["grain"])

func can_resolve(state: WorldState) -> bool:
	if status != Status.READY or not state.can_govern():
		return false
	var available_gold := state.state_treasury if funding_source == "state" else state.family_treasury
	return available_gold >= required_gold() and int(state.resources.get("grain", 0)) >= required_grain()

func resolve(state: WorldState) -> bool:
	if not can_resolve(state):
		return false
	var gold := required_gold()
	if funding_source == "state":
		state.state_treasury -= gold
	else:
		state.family_treasury -= gold
	state.resources["grain"] = int(state.resources.get("grain", 0)) - required_grain()
	status = Status.RESOLVED
	resolved_cycle = state.calendar.cycle
	observed_outcome = _build_outcome()
	state.facts["father_funeral_completed"] = true
	state.facts["grain_response"] = grain_response
	state.facts["opening_grain_dispatch"] = {
		"partial": "in_transit", "full": "in_transit", "purchase": "contracted", "defer": "withheld"
	}[grain_response]
	state.facts["funeral_plan"] = funeral_plan
	state.add_fatigue(5)
	_apply_social_consequences(state)
	reaction_snapshot = _opening_reactions()
	state.opening_followup.prepare(self)
	state.consequence_log.append({
		"cycle": resolved_cycle,
		"kind": "opening_decision_resolved",
		"funeral": funeral_plan,
		"grain": grain_response,
		"funding": funding_source
	})
	return true

func _apply_social_consequences(state: WorldState) -> void:
	var cycle := state.calendar.cycle
	var spouse: CharacterState = state.characters["spouse"]
	var sister: CharacterState = state.characters["sister"]
	var nobility: FactionState = state.factions["nobility"]
	var clergy: FactionState = state.factions["clergy"]
	var rural: FactionState = state.factions["rural"]
	match funeral_plan:
		"modest":
			nobility.react(cycle, -4, NOBILITY_REACTIONS[funeral_plan])
			clergy.react(cycle, -1, "Духовенство приняло церемонию, но ожидало большего почтения.")
			spouse.remember(cycle, "father_funeral", FAMILY_REACTIONS[funeral_plan], {"respect": 1})
		"solemn":
			nobility.react(cycle, 3, NOBILITY_REACTIONS[funeral_plan])
			clergy.react(cycle, 3, "Духовенство отметило достойное соблюдение обряда.")
			spouse.remember(cycle, "father_funeral", FAMILY_REACTIONS[funeral_plan], {"affection": 2, "respect": 2})
		"grand":
			nobility.react(cycle, 7, NOBILITY_REACTIONS[funeral_plan])
			clergy.react(cycle, 5, "Щедрый обряд возвысил храм и память покойного князя.")
			spouse.remember(cycle, "father_funeral", FAMILY_REACTIONS[funeral_plan], {"respect": 4})
	match grain_response:
		"partial": rural.react(cycle, 3, RURAL_REACTIONS[grain_response])
		"full": rural.react(cycle, 8, RURAL_REACTIONS[grain_response])
		"purchase": rural.react(cycle, 6, RURAL_REACTIONS[grain_response])
		"defer": rural.react(cycle, -6, RURAL_REACTIONS[grain_response])
	if grain_response in ["partial", "full", "purchase"]:
		sister.remember(cycle, "grain_relief", "Вы распорядились отправить помощь жителям области.", {"trust": 3})
	else:
		sister.remember(cycle, "grain_relief", "Вы поставили проверку выше немедленной помощи голодающим.", {"trust": -3, "resentment": 2})
	if funding_source == "family":
		spouse.remember(cycle, "family_funds", FAMILY_REACTIONS["family_funds"], {"trust": -2, "resentment": 2})
	state.facts["opening_social_consequences_applied"] = true

func observed_reactions(_state: WorldState) -> Array[String]:
	if status != Status.RESOLVED:
		return []
	return reaction_snapshot.duplicate()

func _opening_reactions() -> Array[String]:
	var family_key := "family_funds" if funding_source == "family" else funeral_plan
	return [str(NOBILITY_REACTIONS[funeral_plan]), str(RURAL_REACTIONS[grain_response]), str(FAMILY_REACTIONS[family_key])]

func _build_outcome() -> String:
	var funeral_text := str(FUNERAL_PLANS[funeral_plan]["title"])
	var source_text := "государственной казны" if funding_source == "state" else "семейного сундука"
	var delivery := ""
	match grain_response:
		"partial", "full":
			delivery = "Из княжеских амбаров выделили %d мер для обоза. Деревни ещё ждут доставку." % required_grain()
		"purchase":
			delivery = "Сарнские купцы приняли оплату за привозное зерно. Заказ ещё в пути, княжеский запас не тронули."
		"defer":
			delivery = "Зерно оставили в княжеских амбарах. Старосты ушли ждать проверки и пока не получат продовольствия."
	return "Утверждён порядок похорон «%s». Распоряжения оплачены из %s.\n%s" % [funeral_text, source_text, delivery]

func _update_readiness() -> void:
	status = Status.READY if not funeral_plan.is_empty() and not grain_response.is_empty() else Status.WAITING

func to_data() -> Dictionary:
	return {
		"status": int(status), "funeral_plan": funeral_plan,
		"grain_response": grain_response, "funding_source": funding_source,
		"resolved_cycle": resolved_cycle, "observed_outcome": observed_outcome,
		"reaction_snapshot": reaction_snapshot.duplicate()
	}

func load_data(data: Dictionary) -> void:
	status = clampi(int(data.get("status", 0)), 0, Status.size() - 1) as Status
	funeral_plan = str(data.get("funeral_plan", ""))
	grain_response = str(data.get("grain_response", ""))
	funding_source = str(data.get("funding_source", "state"))
	resolved_cycle = maxi(0, int(data.get("resolved_cycle", 0)))
	observed_outcome = str(data.get("observed_outcome", ""))
	reaction_snapshot.assign(data.get("reaction_snapshot", []))
	if status == Status.RESOLVED and reaction_snapshot.is_empty() and FUNERAL_PLANS.has(funeral_plan) and GRAIN_RESPONSES.has(grain_response):
		reaction_snapshot = _opening_reactions()
		observed_outcome = _build_outcome()

