class_name TechnologyState
extends Resource

const TECHNOLOGIES: Dictionary = {
	"crop_rotation": {"title": "Чередование посевов", "cost": 24, "description": "Полевые писцы сравнивают урожайность и вводят трёхпольный порядок."},
	"standard_tools": {"title": "Единые кузнечные меры", "cost": 30, "description": "Шаблоны деталей позволяют чинить инструменты в разных мастерских."},
	"sanitation": {"title": "Чистая вода и отвод нечистот", "cost": 34, "description": "Лекари и строители составляют правила для колодцев, канав и боен."},
	"field_logistics": {"title": "Походные ведомости", "cost": 38, "description": "Обозы учитывают путь, корм, сменных лошадей и дневной расход войска."},
	"state_records": {"title": "Единая писцовая книга", "cost": 42, "description": "Областные реестры приводятся к одному формату и сверяются со столицей."}
}

@export var active_research: String = ""
@export var progress: int = 0
@export var unlocked: Array[String] = []

func can_start(technology_id: String) -> bool:
	return active_research.is_empty() and TECHNOLOGIES.has(technology_id) and technology_id not in unlocked

func start(state: WorldState, technology_id: String) -> bool:
	if not state.can_govern() or not can_start(technology_id): return false
	active_research = technology_id
	progress = 0
	state.add_fatigue(2)
	return true

func monthly_output(state: WorldState) -> int:
	return 4 + int(state.development.levels.get("school", 0)) * 3

func advance_month(state: WorldState) -> void:
	if active_research.is_empty(): return
	progress += monthly_output(state)
	if progress < int(TECHNOLOGIES[active_research]["cost"]): return
	var completed := active_research
	unlocked.append(completed)
	active_research = ""
	progress = 0
	state.story_timeline.reports.append({"cycle": state.calendar.cycle, "title": "Исследование завершено", "text": "%s теперь применяется в княжестве." % TECHNOLOGIES[completed]["title"], "read": false})
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "technology_unlocked", "technology": completed})

func grain_bonus() -> int:
	return 3 if "crop_rotation" in unlocked else 0

func tools_bonus() -> int:
	return 2 if "standard_tools" in unlocked else 0

func health_bonus() -> int:
	return 2 if "sanitation" in unlocked else 0

func gold_bonus() -> int:
	return 3 if "state_records" in unlocked else 0

func campaign_supply_bonus() -> int:
	return 20 if "field_logistics" in unlocked else 0

func to_data() -> Dictionary:
	return {"active_research": active_research, "progress": progress, "unlocked": unlocked.duplicate()}

func load_data(data: Dictionary) -> void:
	active_research = str(data.get("active_research", ""))
	progress = maxi(0, int(data.get("progress", 0)))
	unlocked.assign(data.get("unlocked", []))
