class_name CouncilState
extends Resource

const ROLES: Dictionary = {
	"steward": "Управляющий казной",
	"marshal": "Воевода",
	"physician": "Глава лекарской службы",
	"intelligence": "Глава тайной канцелярии"
}

const CANDIDATES: Dictionary = {
	"borin": {"name": "Борин Вежа", "role": "steward", "profile": "Опытный сборщик податей; знает землевладельцев, но привык скрывать ошибки подчинённых.", "temperament": "Осторожный хранитель порядка", "strength": "Знает старые книги и владельцев земель", "risk": "Прикрывает ошибки своей службы", "connections": "Старые чиновники · землевладельцы", "economy": 2, "grain": 0},
	"vesna": {"name": "Весна Ратич", "role": "steward", "profile": "Купеческая вдова; быстро находит деньги, но городские цехи ждут от неё ответных услуг.", "temperament": "Решительная и практичная", "strength": "Быстро находит деньги и поставщиков", "risk": "Цехи потребуют ответных уступок", "connections": "Купцы · городские мастерские", "economy": 4, "grain": -1},
	"radomir": {"name": "Радомир Седой", "role": "marshal", "profile": "Ветеран отцовских походов; верен дому, осторожен и не любит молодых командиров.", "temperament": "Сдержанный ветеран", "strength": "Держит строй и бережёт людей", "risk": "Подавляет инициативу молодых офицеров", "connections": "Старая дружина · гарнизоны", "economy": -1, "grain": 0},
	"yaropolk": {"name": "Ярополк Лис", "role": "marshal", "profile": "Смелый полевой командир; умеет действовать быстро, но имеет долги перед знатью.", "temperament": "Азартный полевой командир", "strength": "Быстро принимает решение в походе", "risk": "Зависит от знатных кредиторов", "connections": "Молодые офицеры · дворянская конница", "economy": -2, "grain": 0},
	"mira": {"name": "Мира Травница", "role": "physician", "profile": "Лечила деревни во время прошлой горячки; опытна, но духовенство не доверяет её методам.", "temperament": "Прямая и сострадательная", "strength": "Имеет опыт полевых эпидемий", "risk": "Её методы раздражают духовенство", "connections": "Деревенские лекари · повитухи", "economy": 0, "grain": 1, "medicine": 4},
	"severin": {"name": "Брат Северин", "role": "physician", "profile": "Храмовый лекарь с сетью приходов; дисциплинирован, но ставит церковный порядок выше скорости.", "temperament": "Строгий организатор", "strength": "Может опереться на сеть приходов", "risk": "Обряд и иерархия замедляют помощь", "connections": "Храмы · монастырские лечебницы", "economy": -1, "grain": 1, "medicine": 3},
	"tibor": {"name": "Тибор Безгербовый", "role": "intelligence", "profile": "Знает контрабандистов и трактиры; приносит сведения быстро, но никто не знает его настоящей верности.", "temperament": "Обаятельный приспособленец", "strength": "Проникает в низы и теневые рынки", "risk": "Его настоящая верность неизвестна", "connections": "Контрабандисты · трактиры · воры", "economy": -1, "grain": 0},
	"elena": {"name": "Елена Ворон", "role": "intelligence", "profile": "Дворянка и опытная посланница; имеет доступ к соседним дворам, зато связана семейными обещаниями.", "temperament": "Холодная и наблюдательная", "strength": "Имеет доступ к иностранным дворам", "risk": "Связана семейными обещаниями", "connections": "Посольства · пограничная знать", "economy": -2, "grain": 0}
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
