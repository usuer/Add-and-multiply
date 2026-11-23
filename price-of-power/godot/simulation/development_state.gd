class_name DevelopmentState
extends Resource

const PROJECTS: Dictionary = {
	"granary": {"title": "Расширение зернохранилища", "gold": 12, "wood": 8, "stone": 4, "work": 45},
	"smithy": {"title": "Новые горны кузницы", "gold": 16, "wood": 4, "stone": 7, "work": 55},
	"housing": {"title": "Жилые дома нижнего города", "gold": 10, "wood": 12, "stone": 3, "work": 50},
	"clinic": {"title": "Городская лечебница", "gold": 18, "wood": 6, "stone": 9, "work": 65},
	"school": {"title": "Земская школа", "gold": 14, "wood": 10, "stone": 5, "work": 60}
}

@export var workforce_total: int = 90
@export var levels: Dictionary = {"granary": 1, "smithy": 1, "housing": 1, "clinic": 0, "school": 0}
@export var active_projects: Dictionary = {}
@export var completed_history: Array[Dictionary] = []

func available_workers() -> int:
	var assigned := 0
	for project: Dictionary in active_projects.values(): assigned += int(project.get("workers", 0))
	return maxi(0, workforce_total - assigned)

func can_start(state: WorldState, project_id: String) -> bool:
	if not state.can_govern() or not PROJECTS.has(project_id) or active_projects.has(project_id): return false
	var project: Dictionary = PROJECTS[project_id]
	return state.state_treasury >= int(project["gold"]) and int(state.resources.get("wood", 0)) >= int(project["wood"]) and int(state.resources.get("stone", 0)) >= int(project["stone"])

func start(state: WorldState, project_id: String) -> bool:
	if not can_start(state, project_id): return false
	var project: Dictionary = PROJECTS[project_id]
	state.state_treasury -= int(project["gold"])
	state.resources["wood"] = int(state.resources["wood"]) - int(project["wood"])
	state.resources["stone"] = int(state.resources["stone"]) - int(project["stone"])
	var initial_workers := mini(10, available_workers())
	active_projects[project_id] = {"progress": 0, "workers": initial_workers, "target": int(project["work"]) * (int(levels.get(project_id, 0)) + 1)}
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "project_started", "project": project_id})
	state.add_fatigue(2)
	return true

func change_workers(project_id: String, delta: int) -> bool:
	if not active_projects.has(project_id): return false
	var project: Dictionary = active_projects[project_id]
	var current := int(project["workers"])
	var next := current + delta
	if next < 0 or (delta > 0 and delta > available_workers()): return false
	project["workers"] = next
	active_projects[project_id] = project
	return true

func advance_month(state: WorldState) -> void:
	var completed: Array[String] = []
	for project_id: String in active_projects:
		var project: Dictionary = active_projects[project_id]
		project["progress"] = int(project["progress"]) + int(project["workers"])
		active_projects[project_id] = project
		if int(project["progress"]) >= int(project["target"]): completed.append(project_id)
	for project_id: String in completed:
		levels[project_id] = int(levels.get(project_id, 0)) + 1
		active_projects.erase(project_id)
		completed_history.append({"cycle": state.calendar.cycle, "project": project_id, "level": levels[project_id]})
		state.story_timeline.reports.append({"cycle": state.calendar.cycle, "title": "Строительство завершено", "text": "%s теперь имеет уровень %d." % [PROJECTS[project_id]["title"], levels[project_id]], "read": false})

func monthly_gold_bonus() -> int:
	return maxi(0, int(levels.get("housing", 0)) - 1) * 2 + int(levels.get("school", 0))

func monthly_grain_bonus() -> int:
	return maxi(0, int(levels.get("granary", 0)) - 1) * 2

func monthly_health_bonus() -> int:
	return int(levels.get("clinic", 0))

func monthly_tools_bonus() -> int:
	return maxi(0, int(levels.get("smithy", 0)) - 1) * 2

func to_data() -> Dictionary:
	return {"workforce_total": workforce_total, "levels": levels.duplicate(true), "active_projects": active_projects.duplicate(true), "completed_history": completed_history.duplicate(true)}

func load_data(data: Dictionary) -> void:
	workforce_total = maxi(0, int(data.get("workforce_total", 90)))
	levels = (data.get("levels", levels) as Dictionary).duplicate(true)
	active_projects = (data.get("active_projects", {}) as Dictionary).duplicate(true)
	completed_history.assign(data.get("completed_history", []))
