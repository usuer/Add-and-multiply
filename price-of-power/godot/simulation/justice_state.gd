class_name JusticeState
extends Resource

const CASES: Dictionary = {
	"market_thief": {
		"name": "Олек, подмастерье", "charge": "Кража кошеля на рынке", "evidence": "Один свидетель; кошель не найден.",
		"options": {"release": "Освободить за недостатком улик", "restitution": "Назначить возмещение потерпевшему", "labor": "Отправить на общественные работы"}
	},
	"river_smuggler": {
		"name": "Вардан Лодочник", "charge": "Перевозка товара мимо княжеской пошлины", "evidence": "Товар найден в лодке; двое стражников подтверждают досмотр.",
		"options": {"prison": "Заключить в городскую тюрьму", "exile": "Изгнать из княжества", "informant": "Предложить свободу за работу осведомителем"}
	}
}

@export var prison_capacity: int = 18
@export var prisoners: int = 7
@export var resolved_cases: Dictionary = {}
@export var informants: Array[String] = []

func available_cases() -> Array[String]:
	var result: Array[String] = []
	for case_id: String in CASES:
		if not resolved_cases.has(case_id): result.append(case_id)
	return result

func can_judge(case_id: String, option_id: String) -> bool:
	if case_id not in available_cases() or not (CASES[case_id]["options"] as Dictionary).has(option_id):
		return false
	return not (case_id == "river_smuggler" and option_id == "prison" and prisoners >= prison_capacity)

func judge(state: WorldState, case_id: String, option_id: String) -> bool:
	if not can_judge(case_id, option_id): return false
	var outcome := ""
	match "%s:%s" % [case_id, option_id]:
		"market_thief:release":
			outcome = "Олека отпустили. Купеческий старшина недоволен, но суд не стал заменять доказательства подозрением."
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, -1, "Суд отпустил обвинённого в рыночной краже из-за слабых улик.")
		"market_thief:restitution":
			outcome = "Семья Олека возместит стоимость кошеля частями. Вина не доказана полностью, зато спор закрыт без тюрьмы."
			state.public_order = mini(100, state.public_order + 1)
		"market_thief:labor":
			outcome = "Олека отправили ремонтировать городские канавы. Его цех считает наказание поспешным."
			state.public_order = mini(100, state.public_order + 2)
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, -3, "Подмастерья осудили на работы по показанию одного свидетеля.")
		"river_smuggler:prison":
			prisoners += 1
			state.public_order = mini(100, state.public_order + 2)
			outcome = "Вардан заключён в тюрьму. Речные перевозчики стали осторожнее, но его связи остались на свободе."
		"river_smuggler:exile":
			outcome = "Вардана вывели за границу. Теперь он свободен предложить знание ваших речных постов соседнему правителю."
			state.public_order = mini(100, state.public_order + 1)
		"river_smuggler:informant":
			informants.append("vardan")
			state.facts["river_informant"] = true
			outcome = "Вардан вернулся к лодке под тайным надзором. Он назовёт заказчиков, только если поверит, что уговор соблюдают."
	resolved_cases[case_id] = {"cycle": state.calendar.cycle, "option": option_id, "outcome": outcome}
	state.ruler_fatigue = mini(100, state.ruler_fatigue + 2)
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "court_judgment", "case": case_id, "option": option_id})
	return true

func outcome(case_id: String) -> String:
	return str((resolved_cases.get(case_id, {}) as Dictionary).get("outcome", ""))

func to_data() -> Dictionary:
	return {"prison_capacity": prison_capacity, "prisoners": prisoners, "resolved_cases": resolved_cases.duplicate(true), "informants": informants.duplicate()}

func load_data(data: Dictionary) -> void:
	prison_capacity = maxi(1, int(data.get("prison_capacity", 18)))
	prisoners = clampi(int(data.get("prisoners", 7)), 0, prison_capacity)
	resolved_cases = (data.get("resolved_cases", {}) as Dictionary).duplicate(true)
	informants.assign(data.get("informants", []))
