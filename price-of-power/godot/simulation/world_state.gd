class_name WorldState
extends Resource

const CONVERSATIONS_SCRIPT := preload("res://simulation/character_conversations.gd")

const SAVE_VERSION: int = 1
const CORE_CAST: Dictionary = {
	"spouse": {"name": "Княгиня Элина", "affection": 34, "respect": 28, "trust": 24, "courage": 68, "conscience": 72, "ambition": 64, "violence": 12},
	"sister": {"name": "Лада, сестра князя", "affection": 48, "respect": 16, "trust": 31, "courage": 61, "conscience": 84, "ambition": 32, "violence": 8},
	"secretary": {"name": "Марек, секретарь", "affection": 8, "respect": 42, "trust": 37, "courage": 46, "conscience": 59, "ambition": 55, "violence": 18},
	"radomir": {"name": "Радомир Седой", "affection": 5, "respect": 24, "trust": 22, "courage": 86, "conscience": 63, "ambition": 38, "violence": 61},
	"borin": {"name": "Борин Вежа", "affection": 0, "respect": 26, "trust": 11, "courage": 42, "conscience": 39, "ambition": 67, "violence": 24},
	"daren": {"name": "Дарен Клин", "affection": 0, "respect": 17, "trust": 12, "courage": 72, "conscience": 48, "ambition": 58, "violence": 54},
	"zlata": {"name": "Злата Радич", "affection": 0, "respect": 6, "trust": 0, "courage": 65, "conscience": 57, "ambition": 82, "violence": 22},
	"miron": {"name": "Мирон Светоч", "affection": -2, "respect": 4, "trust": -6, "courage": 78, "conscience": 76, "ambition": 62, "violence": 16},
	"aglaia": {"name": "Аглая Лис", "affection": 0, "respect": 9, "trust": 0, "courage": 70, "conscience": 44, "ambition": 77, "violence": 31},
	"tikhon": {"name": "Тихон Лучин", "affection": 0, "respect": 5, "trust": 2, "courage": 35, "conscience": 79, "ambition": 48, "violence": 3},
	"vardan": {"name": "Вардан Речной", "affection": -4, "respect": 2, "trust": -14, "courage": 74, "conscience": 21, "ambition": 88, "violence": 73},
	"savva": {"name": "Савва Лунь", "affection": 0, "respect": 0, "trust": -4, "courage": 29, "conscience": 61, "ambition": 28, "violence": 7},
	"heir": {"name": "Всеволод, наследник", "affection": 62, "respect": 18, "trust": 56, "courage": 40, "conscience": 70, "ambition": 35, "violence": 5},
	"daughter": {"name": "Милица, дочь князя", "affection": 68, "respect": 4, "trust": 61, "courage": 37, "conscience": 78, "ambition": 18, "violence": 2}
}

@export var seed: String = "Арден-1248"
@export var calendar: CampaignCalendar = CampaignCalendar.new()
@export var state_treasury: int = 120
@export var family_treasury: int = 45
@export var ruler_fatigue: int = 8
@export var ruler_health: int = 82
@export var incapacitated_periods: int = 0
@export var public_health: int = 64
@export var public_order: int = 58
@export var grain_crisis: GrainCrisis = GrainCrisis.new()
@export var opening_decision: OpeningDecision = OpeningDecision.new()
@export var opening_followup: OpeningFollowup = OpeningFollowup.new()
@export var story_timeline: StoryTimeline = StoryTimeline.new()
@export var conversations: Resource = CONVERSATIONS_SCRIPT.new()
@export var campaign_outcome: CampaignOutcome = CampaignOutcome.new()
@export var council: CouncilState = CouncilState.new()
@export var policies: GovernancePolicy = GovernancePolicy.new()
@export var justice: JusticeState = JusticeState.new()
@export var diplomacy: DiplomacyState = DiplomacyState.new()
@export var development: DevelopmentState = DevelopmentState.new()
@export var army: ArmyState = ArmyState.new()
@export var guide: CampaignGuide = CampaignGuide.new()
@export var technology: TechnologyState = TechnologyState.new()
@export var population: PopulationState = PopulationState.new()
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
	_ensure_core_cast()
	if factions.is_empty():
		factions = {
			"nobility": _make_faction("nobility", "Знать", 5),
			"guilds": _make_faction("guilds", "Городские цехи", 2),
			"clergy": _make_faction("clergy", "Духовенство", 8),
			"military": _make_faction("military", "Войско", 7),
			"rural": _make_faction("rural", "Жители областей", -3)
		}

func _ensure_core_cast() -> void:
	for character_id: String in CORE_CAST:
		if characters.has(character_id):
			continue
		var profile: Dictionary = CORE_CAST[character_id]
		var character := _make_character(character_id, str(profile["name"]), int(profile["affection"]), int(profile["respect"]), int(profile["trust"]))
		character.courage = int(profile["courage"])
		character.conscience = int(profile["conscience"])
		character.ambition = int(profile["ambition"])
		character.violence_acceptance = int(profile["violence"])
		characters[character_id] = character

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
	_update_ruler_condition()
	story_timeline.update(self)
	if calendar.is_demo_complete():
		campaign_outcome.generate(self)
	if grain_crisis.update(calendar.cycle):
		consequence_log.append({
			"cycle": calendar.cycle,
			"kind": "grain_findings_ready",
			"delegate": grain_crisis.delegate_id
		})
	if calendar.period == CampaignCalendar.Period.BEGINNING:
		_apply_monthly_economy()
		development.advance_month(self)
		technology.advance_month(self)
		population.advance_month(self)
	consequence_log.append({
		"cycle": calendar.cycle,
		"kind": "period_advanced",
		"date": calendar.display_date()
	})
	return true

func can_govern() -> bool:
	return incapacitated_periods <= 0

func add_fatigue(amount: int) -> void:
	ruler_fatigue = clampi(ruler_fatigue + amount, 0, 100)
	if ruler_fatigue >= 75 and not bool(facts.get("overwork_warning", false)):
		facts["overwork_warning"] = true
		story_timeline.reports.append({"cycle": calendar.cycle, "title": "Лекарь предупреждает о переутомлении", "text": "Вы слишком долго работаете без отдыха. Новые аудиенции и личные решения могут привести к болезни.", "read": false})

func _update_ruler_condition() -> void:
	if incapacitated_periods > 0:
		incapacitated_periods -= 1
		ruler_fatigue = maxi(0, ruler_fatigue - 12)
		ruler_health = mini(100, ruler_health + 3)
		if incapacitated_periods == 0:
			story_timeline.reports.append({"cycle": calendar.cycle, "title": "Князь возвращается к делам", "text": "Лекарь разрешил снова принимать решения, но советует не возвращаться сразу к прежнему темпу.", "read": false})
		return
	if ruler_fatigue >= 80:
		ruler_health = maxi(0, ruler_health - 10)
	elif ruler_fatigue >= 65:
		ruler_health = maxi(0, ruler_health - 4)
	else:
		ruler_health = mini(100, ruler_health + 1)
	ruler_fatigue = maxi(0, ruler_fatigue - 6)
	if ruler_health <= 30:
		incapacitated_periods = 2
		story_timeline.reports.append({"cycle": calendar.cycle, "title": "Князь слёг", "text": "Переутомление перешло в болезнь. Два периода новые личные решения принимать нельзя; текущие распоряжения продолжат исполняться.", "read": false})
		consequence_log.append({"cycle": calendar.cycle, "kind": "ruler_incapacitated", "periods": 2})

func assign_grain_investigation(delegate_id: String) -> bool:
	if not can_govern() or not grain_crisis.assign(delegate_id, calendar.cycle):
		return false
	consequence_log.append({
		"cycle": calendar.cycle,
		"kind": "grain_investigation_assigned",
		"delegate": delegate_id
	})
	add_fatigue(2)
	return true

func spend_state(amount: int, reason: String) -> bool:
	if not can_govern() or amount < 0 or state_treasury < amount:
		return false
	state_treasury -= amount
	consequence_log.append({"cycle": calendar.cycle, "kind": "state_spending", "amount": amount, "reason": reason})
	return true

func _apply_monthly_economy() -> void:
	state_treasury += 8 + council.monthly_economy_bonus() + policies.monthly_gold_modifier() + development.monthly_gold_bonus() + technology.gold_bonus()
	resources["grain"] = maxi(0, int(resources.get("grain", 0)) - 5 + council.monthly_grain_bonus() + development.monthly_grain_bonus() + technology.grain_bonus())
	resources["iron_ore"] = int(resources.get("iron_ore", 0)) + 3
	resources["worked_iron"] = int(resources.get("worked_iron", 0)) + 1
	resources["tools"] = int(resources.get("tools", 0)) + development.monthly_tools_bonus() + technology.tools_bonus()
	resources["weapons"] = int(resources.get("weapons", 0)) + policies.monthly_weapon_modifier()
	public_health = clampi(public_health + policies.monthly_health_modifier() + development.monthly_health_bonus() + technology.health_bonus(), 0, 100)
	public_order = clampi(public_order + policies.monthly_order_modifier(), 0, 100)

func to_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"seed": seed,
		"calendar": calendar.to_data(),
		"state_treasury": state_treasury,
		"family_treasury": family_treasury,
		"ruler_fatigue": ruler_fatigue,
		"ruler_health": ruler_health,
		"incapacitated_periods": incapacitated_periods,
		"public_health": public_health,
		"public_order": public_order,
		"grain_crisis": grain_crisis.to_data(),
		"opening_decision": opening_decision.to_data(),
		"opening_followup": opening_followup.to_data(),
		"story_timeline": story_timeline.to_data(),
		"conversations": conversations.to_data(),
		"campaign_outcome": campaign_outcome.to_data(),
		"council": council.to_data(),
		"policies": policies.to_data(),
		"justice": justice.to_data(),
		"diplomacy": diplomacy.to_data(),
		"development": development.to_data(),
		"army": army.to_data(),
		"guide": guide.to_data(),
		"technology": technology.to_data(),
		"population": population.to_data(),
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
	state.ruler_health = clampi(int(data.get("ruler_health", 82)), 0, 100)
	state.incapacitated_periods = maxi(0, int(data.get("incapacitated_periods", 0)))
	state.public_health = clampi(int(data.get("public_health", 64)), 0, 100)
	state.public_order = clampi(int(data.get("public_order", 58)), 0, 100)
	state.grain_crisis.load_data(data.get("grain_crisis", {}))
	state.opening_decision.load_data(data.get("opening_decision", {}))
	state.opening_followup.load_data(data.get("opening_followup", {}))
	state.story_timeline.load_data(data.get("story_timeline", {}))
	state.conversations.load_data(data.get("conversations", {}))
	state.campaign_outcome.load_data(data.get("campaign_outcome", {}))
	state.council.load_data(data.get("council", {}))
	state.policies.load_data(data.get("policies", {}))
	state.justice.load_data(data.get("justice", {}))
	state.diplomacy.load_data(data.get("diplomacy", {}))
	state.development.load_data(data.get("development", {}))
	state.army.load_data(data.get("army", {}))
	state.guide.load_data(data.get("guide", {}))
	state.technology.load_data(data.get("technology", {}))
	state.population.load_data(data.get("population", {}))
	state.resources = (data.get("resources", {}) as Dictionary).duplicate(true)
	state.facts = (data.get("facts", {}) as Dictionary).duplicate(true)
	state.consequence_log.assign(data.get("consequence_log", []))
	state.characters.clear()
	for id: String in (data.get("characters", {}) as Dictionary):
		state.characters[id] = CharacterState.from_data(data["characters"][id])
	state._ensure_core_cast()
	state.factions.clear()
	for id: String in (data.get("factions", {}) as Dictionary):
		state.factions[id] = FactionState.from_data(data["factions"][id])
	if state.factions.is_empty():
		state._init()
	return state

