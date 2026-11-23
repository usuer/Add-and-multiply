class_name CampaignGuide
extends Resource

@export var intro_seen: bool = false

func objectives(state: WorldState) -> Array[Dictionary]:
	return [
		{"title": "Принять первое составное решение", "done": state.opening_decision.status == OpeningDecision.Status.RESOLVED},
		{"title": "Поручить проверку зерновых книг", "done": state.grain_crisis.stage != GrainCrisis.Stage.REPORTED},
		{"title": "Разобрать первое городское происшествие", "done": state.story_timeline.resolved.has("granary_roof")},
		{"title": "Укомплектовать одну вакансию совета", "done": not state.council.appointment_history.is_empty()}
	]

func completed_count(state: WorldState) -> int:
	var result := 0
	for objective: Dictionary in objectives(state):
		if bool(objective["done"]): result += 1
	return result

func to_data() -> Dictionary:
	return {"intro_seen": intro_seen}

func load_data(data: Dictionary) -> void:
	intro_seen = bool(data.get("intro_seen", false))
