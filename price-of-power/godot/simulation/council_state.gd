class_name CouncilState
extends Resource

const ROLES: Dictionary = {
	"steward": "Управляющий казной",
	"marshal": "Воевода",
	"physician": "Глава лекарской службы",
	"intelligence": "Глава тайной канцелярии"
}

const CANDIDATES: Dictionary = {
	"borin": {"name": "Борин Вежа", "role": "steward", "profile": "Опытный сборщик податей; знает землевладельцев, но привык скрывать ошибки подчинённых.", "economy": 2, "grain": 0},
	"vesna": {"name": "Весна Ратич", "role": "steward", "profile": "Купеческая вдова; быстро находит деньги, но городские цехи ждут от неё ответных услуг.", "economy": 4, "grain": -1},
	"radomir": {"name": "Радомир Седой", "role": "marshal", "profile": "Ветеран отцовских походов; верен дому, осторожен и не любит молодых командиров.", "economy": -1, "grain": 0},
	"yaropolk": {"name": "Ярополк Лис", "role": "marshal", "profile": "Смелый полевой командир; умеет действовать быстро, но имеет долги перед знатью.", "economy": -2, "grain": 0},
	"mira": {"name": "Мира Травница", "role": "physician", "profile": "Лечила деревни во время прошлой горячки; опытна, но духовенство не доверяет её методам.", "economy": 0, "grain": 1, "medicine": 4},
	"severin": {"name": "Брат Северин", "role": "physician", "profile": "Храмовый лекарь с сетью приходов; дисциплинирован, но ставит церковный порядок выше скорости.", "economy": -1, "grain": 1, "medicine": 3},
	"tibor": {"name": "Тибор Безгербовый", "role": "intelligence", "profile": "Знает контрабандистов и трактиры; приносит сведения быстро, но никто не знает его настоящей верности.", "economy": -1, "grain": 0},
	"elena": {"name": "Елена Ворон", "role": "intelligence", "profile": "Дворянка и опытная посланница; имеет доступ к соседним дворам, зато связана семейными обещаниями.", "economy": -2, "grain": 0}
}

@export var appointments: Dictionary = {"steward": "borin", "marshal": "radomir", "physician": "", "intelligence": ""}
@export var appointment_history: Array[Dictionary] = []

func candidates_for(role_id: String) -> Array[String]:
	var result: Array[String] = []
	for candidate_id: String in CANDIDATES:
		if str(CANDIDATES[candidate_id]["role"]) == role_id:
			result.append(candidate_id)
	return result

func appoint(state: WorldState, role_id: String, candidate_id: String) -> bool:
	if not state.can_govern() or not ROLES.has(role_id) or not CANDIDATES.has(candidate_id):
		return false
	if str(CANDIDATES[candidate_id]["role"]) != role_id or str(appointments.get(role_id, "")) == candidate_id:
		return false
	var previous := str(appointments.get(role_id, ""))
	appointments[role_id] = candidate_id
	appointment_history.append({"cycle": state.calendar.cycle, "role": role_id, "candidate": candidate_id, "previous": previous})
	state.add_fatigue(2)
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "council_appointment", "role": role_id, "candidate": candidate_id, "previous": previous})
	return true

func monthly_economy_bonus() -> int:
	var result := 0
	for candidate_id: String in appointments.values():
		if CANDIDATES.has(candidate_id):
			result += int(CANDIDATES[candidate_id].get("economy", 0))
	return result

func monthly_grain_bonus() -> int:
	var result := 0
	for candidate_id: String in appointments.values():
		if CANDIDATES.has(candidate_id):
			result += int(CANDIDATES[candidate_id].get("grain", 0))
	return result

func medicine_skill() -> int:
	var physician_id := str(appointments.get("physician", ""))
	return int(CANDIDATES.get(physician_id, {}).get("medicine", 0))

func to_data() -> Dictionary:
	return {"appointments": appointments.duplicate(true), "appointment_history": appointment_history.duplicate(true)}

func load_data(data: Dictionary) -> void:
	appointments = (data.get("appointments", appointments) as Dictionary).duplicate(true)
	appointment_history.assign(data.get("appointment_history", []))
