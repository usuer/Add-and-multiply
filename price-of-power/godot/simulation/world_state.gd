class_name WorldState
extends Resource

const SAVE_VERSION: int = 1

@export var seed: String = "Арден-1248"
@export var calendar: CampaignCalendar = CampaignCalendar.new()
@export var state_treasury: int = 120
@export var family_treasury: int = 45
@export var ruler_fatigue: int = 8
@export var grain_crisis: GrainCrisis = GrainCrisis.new()
@export var opening_decision: OpeningDecision = OpeningDecision.new()
@export var resources: Dictionary = {
	"grain": 82,
	"wood": 46,
	"stone": 31,
	"iron_ore": 18,
	"worked_iron": 9,
	"tools": 13,
	"weapons": 22
}
@export var facts: Dictionary = {}
@export var consequence_log: Array[Dictionary] = []

func advance_period() -> bool:
	if not calendar.advance():
		return false
	if grain_crisis.update(calendar.cycle):
		consequence_log.append({
			"cycle": calendar.cycle,
			"kind": "grain_findings_ready",
			"delegate": grain_crisis.delegate_id
		})
	if calendar.period == CampaignCalendar.Period.BEGINNING:
		_apply_monthly_economy()
	consequence_log.append({
		"cycle": calendar.cycle,
		"kind": "period_advanced",
		"date": calendar.display_date()
	})
	return true

func assign_grain_investigation(delegate_id: String) -> bool:
	if not grain_crisis.assign(delegate_id, calendar.cycle):
		return false
	consequence_log.append({
		"cycle": calendar.cycle,
		"kind": "grain_investigation_assigned",
		"delegate": delegate_id
	})
	return true

func spend_state(amount: int, reason: String) -> bool:
	if amount < 0 or state_treasury < amount:
		return false
	state_treasury -= amount
	consequence_log.append({"cycle": calendar.cycle, "kind": "state_spending", "amount": amount, "reason": reason})
	return true

func _apply_monthly_economy() -> void:
	state_treasury += 8
	resources["grain"] = maxi(0, int(resources.get("grain", 0)) - 5)
	resources["iron_ore"] = int(resources.get("iron_ore", 0)) + 3
	resources["worked_iron"] = int(resources.get("worked_iron", 0)) + 1

func to_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"seed": seed,
		"calendar": calendar.to_data(),
		"state_treasury": state_treasury,
		"family_treasury": family_treasury,
		"ruler_fatigue": ruler_fatigue,
		"grain_crisis": grain_crisis.to_data(),
		"opening_decision": opening_decision.to_data(),
		"resources": resources.duplicate(true),
		"facts": facts.duplicate(true),
		"consequence_log": consequence_log.duplicate(true)
	}

static func from_data(data: Dictionary) -> WorldState:
	var state := WorldState.new()
	state.seed = str(data.get("seed", "Арден-1248"))
	state.calendar.load_data(data.get("calendar", {}))
	state.state_treasury = maxi(0, int(data.get("state_treasury", 120)))
	state.family_treasury = maxi(0, int(data.get("family_treasury", 45)))
	state.ruler_fatigue = clampi(int(data.get("ruler_fatigue", 8)), 0, 100)
	state.grain_crisis.load_data(data.get("grain_crisis", {}))
	state.opening_decision.load_data(data.get("opening_decision", {}))
	state.resources = (data.get("resources", {}) as Dictionary).duplicate(true)
	state.facts = (data.get("facts", {}) as Dictionary).duplicate(true)
	state.consequence_log.assign(data.get("consequence_log", []))
	return state

