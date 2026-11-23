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
@export var opening_followup: OpeningFollowup = OpeningFollowup.new()
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
@export var characters: Dictionary = {}
@export var factions: Dictionary = {}

func _init() -> void:
	if characters.is_empty():
		characters = {
			"spouse": _make_character("spouse", "Княгиня Элина", 34, 28, 24),
			"sister": _make_character("sister", "Лада, сестра князя", 48, 16, 31),
			"secretary": _make_character("secretary", "Марек, секретарь", 8, 42, 37)
		}
	if factions.is_empty():
		factions = {
			"nobility": _make_faction("nobility", "Знать", 5),
			"guilds": _make_faction("guilds", "Городские цехи", 2),
			"clergy": _make_faction("clergy", "Духовенство", 8),
			"military": _make_faction("military", "Войско", 7),
			"rural": _make_faction("rural", "Жители областей", -3)
		}

func _make_character(id: String, title: String, affection_value: int, respect_value: int, trust_value: int) -> CharacterState:
	var character := CharacterState.new()
	character.character_id = id
	character.display_name = title
	character.affection = affection_value
	character.respect = respect_value
	character.trust = trust_value
	return character

func _make_faction(id: String, title: String, disposition_value: int) -> FactionState:
	var faction := FactionState.new()
	faction.faction_id = id
	faction.display_name = title
	faction.disposition = disposition_value
	return faction

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
		"opening_followup": opening_followup.to_data(),
		"resources": resources.duplicate(true),
		"facts": facts.duplicate(true),
		"consequence_log": consequence_log.duplicate(true),
		"characters": _resources_to_data(characters),
		"factions": _resources_to_data(factions)
	}

func _resources_to_data(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for id: String in source:
		result[id] = source[id].to_data()
	return result

static func from_data(data: Dictionary) -> WorldState:
	var state := WorldState.new()
	state.seed = str(data.get("seed", "Арден-1248"))
	state.calendar.load_data(data.get("calendar", {}))
	state.state_treasury = maxi(0, int(data.get("state_treasury", 120)))
	state.family_treasury = maxi(0, int(data.get("family_treasury", 45)))
	state.ruler_fatigue = clampi(int(data.get("ruler_fatigue", 8)), 0, 100)
	state.grain_crisis.load_data(data.get("grain_crisis", {}))
	state.opening_decision.load_data(data.get("opening_decision", {}))
	state.opening_followup.load_data(data.get("opening_followup", {}))
	state.resources = (data.get("resources", {}) as Dictionary).duplicate(true)
	state.facts = (data.get("facts", {}) as Dictionary).duplicate(true)
	state.consequence_log.assign(data.get("consequence_log", []))
	state.characters.clear()
	for id: String in (data.get("characters", {}) as Dictionary):
		state.characters[id] = CharacterState.from_data(data["characters"][id])
	state.factions.clear()
	for id: String in (data.get("factions", {}) as Dictionary):
		state.factions[id] = FactionState.from_data(data["factions"][id])
	if state.characters.is_empty() or state.factions.is_empty():
		state._init()
	return state

