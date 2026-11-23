class_name OpeningDecision
extends Resource

enum Status { WAITING, READY, RESOLVED }

const FUNERAL_PLANS: Dictionary = {
	"modest": {"title": "Сдержанная церемония", "cost": 4},
	"solemn": {"title": "Достойные княжеские похороны", "cost": 10},
	"grand": {"title": "Великая церемония для всего региона", "cost": 18}
}

const GRAIN_RESPONSES: Dictionary = {
	"partial": {"title": "Открыть часть амбаров", "grain": 8, "gold": 0},
	"full": {"title": "Отправить большой обоз", "grain": 18, "gold": 2},
	"purchase": {"title": "Купить зерно у купеческой республики", "grain": 0, "gold": 14},
	"defer": {"title": "Дождаться результатов проверки", "grain": 0, "gold": 0}
}

@export var status: Status = Status.WAITING
@export var funeral_plan: String = ""
@export var grain_response: String = ""
@export var funding_source: String = "state"
@export var resolved_cycle: int = 0
@export var observed_outcome: String = ""

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
	if status != Status.READY:
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
	state.facts["funeral_plan"] = funeral_plan
	state.consequence_log.append({
		"cycle": resolved_cycle,
		"kind": "opening_decision_resolved",
		"funeral": funeral_plan,
		"grain": grain_response,
		"funding": funding_source
	})
	return true

func _build_outcome() -> String:
	var funeral_text := str(FUNERAL_PLANS[funeral_plan]["title"])
	var grain_text := str(GRAIN_RESPONSES[grain_response]["title"])
	var source_text := "государственной казны" if funding_source == "state" else "личных средств семьи"
	return "%s проведены за счёт %s. Решение по области: %s. Реакции людей проявятся в следующих периодах." % [funeral_text, source_text, grain_text]

func _update_readiness() -> void:
	status = Status.READY if not funeral_plan.is_empty() and not grain_response.is_empty() else Status.WAITING

func to_data() -> Dictionary:
	return {
		"status": int(status), "funeral_plan": funeral_plan,
		"grain_response": grain_response, "funding_source": funding_source,
		"resolved_cycle": resolved_cycle, "observed_outcome": observed_outcome
	}

func load_data(data: Dictionary) -> void:
	status = clampi(int(data.get("status", 0)), 0, Status.size() - 1) as Status
	funeral_plan = str(data.get("funeral_plan", ""))
	grain_response = str(data.get("grain_response", ""))
	funding_source = str(data.get("funding_source", "state"))
	resolved_cycle = maxi(0, int(data.get("resolved_cycle", 0)))
	observed_outcome = str(data.get("observed_outcome", ""))

