class_name GrainCrisis
extends Resource

enum Stage { REPORTED, INVESTIGATING, FINDINGS_READY, RESOLVED }

const DELEGATES: Dictionary = {
	"steward": {
		"name": "Управляющий землями",
		"duration": 2,
		"finding": "В книгах амбара расходятся приход и выдача. Часть зерна исчезла ещё до неурожая."
	},
	"sister": {
		"name": "Младшая сестра князя",
		"duration": 2,
		"finding": "Несколько семей покинули деревни. Староста скрывает, насколько тяжело положение бедняков."
	},
	"captain": {
		"name": "Капитан гарнизона",
		"duration": 1,
		"finding": "Мост выдержит телеги, но разбитая дорога задержит обоз. Охрана склада недостаточна."
	},
	"agent": {
		"name": "Агент тайной службы",
		"duration": 3,
		"finding": "Купцы скупали зерно через подставных людей и вывозили его ночью в соседнюю область."
	}
}

@export var stage: Stage = Stage.REPORTED
@export var delegate_id: String = ""
@export var assigned_cycle: int = 0
@export var due_cycle: int = 0
@export var findings: Array[String] = []

func assign(delegate: String, current_cycle: int) -> bool:
	if stage != Stage.REPORTED or not DELEGATES.has(delegate):
		return false
	delegate_id = delegate
	assigned_cycle = current_cycle
	due_cycle = current_cycle + int(DELEGATES[delegate]["duration"])
	stage = Stage.INVESTIGATING
	return true

func update(current_cycle: int) -> bool:
	if stage != Stage.INVESTIGATING or current_cycle < due_cycle:
		return false
	findings.append(str(DELEGATES[delegate_id]["finding"]))
	stage = Stage.FINDINGS_READY
	return true

func status_text() -> String:
	match stage:
		Stage.REPORTED:
			return "Область просит открыть княжеские амбары. Причины нехватки противоречивы."
		Stage.INVESTIGATING:
			return "%s ведёт расследование. Донесение ожидается к циклу %d." % [DELEGATES[delegate_id]["name"], due_cycle]
		Stage.FINDINGS_READY:
			return findings.back()
		Stage.RESOLVED:
			return "Дело завершено."
	return ""

func to_data() -> Dictionary:
	return {
		"stage": int(stage), "delegate_id": delegate_id,
		"assigned_cycle": assigned_cycle, "due_cycle": due_cycle,
		"findings": findings.duplicate()
	}

func load_data(data: Dictionary) -> void:
	stage = clampi(int(data.get("stage", 0)), 0, Stage.size() - 1) as Stage
	delegate_id = str(data.get("delegate_id", ""))
	assigned_cycle = maxi(0, int(data.get("assigned_cycle", 0)))
	due_cycle = maxi(0, int(data.get("due_cycle", 0)))
	findings.assign(data.get("findings", []))

