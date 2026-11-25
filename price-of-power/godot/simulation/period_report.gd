extends RefCounted

const METRIC_LABELS: Dictionary = {
	"state_treasury": "Казна",
	"family_treasury": "Личные средства",
	"grain": "Зерно",
	"wood": "Древесина",
	"stone": "Камень",
	"iron_ore": "Железная руда",
	"worked_iron": "Железо",
	"tools": "Инструменты",
	"weapons": "Оружие",
	"residents": "Жители",
	"public_health": "Здоровье жителей",
	"public_order": "Порядок",
	"unrest": "Недовольство",
	"ruler_health": "Здоровье князя",
	"ruler_fatigue": "Усталость князя"
}

static func capture(state: WorldState) -> Dictionary:
	return {
		"metrics": _metrics(state),
		"report_count": state.story_timeline.reports.size(),
		"cases": state.story_timeline.available_events(state.calendar.cycle),
		"topics": state.conversations.pending_story_topics(state),
		"grain_stage": state.grain_crisis.stage,
		"projects": state.development.active_projects.duplicate(true),
		"research_progress": state.technology.progress
	}

static func build(state: WorldState, before: Dictionary, income: Dictionary = {}) -> Dictionary:
	var changes: Array[Dictionary] = []
	var current := _metrics(state)
	for key: String in METRIC_LABELS:
		var prior_value := int(before["metrics"][key])
		var after_value := int(current[key])
		if prior_value != after_value:
			changes.append({"id": key, "label": METRIC_LABELS[key], "before": prior_value, "after": after_value})
	var notes: Array[String] = []
	var timeline := state.story_timeline
	for index in range(int(before["report_count"]), timeline.reports.size()):
		var report: Dictionary = timeline.reports[index]
		notes.append("%s. %s" % [report["title"], report["text"]])
	var cases := timeline.available_events(state.calendar.cycle)
	for event_id: String in cases:
		if event_id not in before["cases"]:
			var definition := timeline.contextual_definition(state, event_id)
			notes.append("Новое дело у секретаря — «%s»." % definition["title"])
	var topics: Array[Dictionary] = state.conversations.pending_story_topics(state)
	for topic: Dictionary in topics:
		if topic not in before["topics"]:
			notes.append("Новый разговор. %s." % topic["label"])
	if state.grain_crisis.stage == GrainCrisis.Stage.FINDINGS_READY and int(before["grain_stage"]) != GrainCrisis.Stage.FINDINGS_READY:
		notes.append("Расследование недостачи завершено. Итоги доступны в управлении княжескими амбарами.")
	if not income.is_empty():
		var sources := PackedStringArray()
		for label: String in income:
			if int(income[label]) != 0:
				sources.append("%s %+d" % [label, int(income[label])])
		notes.append("Месячный расчёт казны: %s." % ", ".join(sources))
	_append_work_progress(state, before, notes)
	if state.campaign_outcome.generated:
		notes.append("Первая глава завершена. Можно прочитать её итог.")
	return {
		"cycle": state.calendar.cycle,
		"date": state.calendar.display_date(),
		"changes": changes,
		"notes": notes,
		"has_secretary_items": not cases.is_empty() or not topics.is_empty() or not timeline.unread_reports().is_empty() or state.campaign_outcome.generated,
		"dismissed": false
	}

static func _metrics(state: WorldState) -> Dictionary:
	var metrics: Dictionary = {}
	for key: String in ["grain", "wood", "stone", "iron_ore", "worked_iron", "tools", "weapons"]:
		metrics[key] = int(state.resources.get(key, 0))
	metrics.merge({
		"state_treasury": state.state_treasury,
		"family_treasury": state.family_treasury,
		"residents": state.population.residents,
		"public_health": state.public_health,
		"public_order": state.public_order,
		"unrest": state.population.unrest,
		"ruler_health": state.ruler_health,
		"ruler_fatigue": state.ruler_fatigue
	})
	return metrics

static func _append_work_progress(state: WorldState, before: Dictionary, notes: Array[String]) -> void:
	var projects := state.development.active_projects
	var research_id := state.technology.active_research
	if state.calendar.period != CampaignCalendar.Period.BEGINNING:
		if not projects.is_empty() or not research_id.is_empty():
			notes.append("Ход строек и исследований обновляется в начале месяца.")
		return
	for project_id: String in projects:
		var project: Dictionary = projects[project_id]
		var old: Dictionary = before["projects"].get(project_id, {})
		var title: String = DevelopmentState.PROJECTS[project_id]["title"]
		if int(project["progress"]) != int(old.get("progress", 0)):
			notes.append("%s: %d из %d ед. работ." % [title, project["progress"], project["target"]])
		elif int(project["workers"]) == 0:
			notes.append("%s не продвинулась. Назначьте работников в управлении зданием." % title)
	if not research_id.is_empty() and state.technology.progress != int(before["research_progress"]):
		var research: Dictionary = TechnologyState.TECHNOLOGIES[research_id]
		notes.append("%s: %d из %d очков исследования." % [research["title"], state.technology.progress, research["cost"]])
