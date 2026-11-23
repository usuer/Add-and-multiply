class_name StoryTimeline
extends Resource

const DEFINITIONS: Dictionary = {
	"granary_roof": {
		"cycle": 2, "title": "Вода в старом амбаре", "location": "Княжеский амбар",
		"summary": "После ночного дождя смотритель обнаружил мокрые балки. Зерно пока цело, но следующая непогода может пройти сквозь кровлю.",
		"choices": {"repair": "Послать плотников немедленно", "inspect": "Сначала проверить смету и виновных", "relocate": "Перенести зерно по соседним складам"}
	},
	"smiths_dispute": {
		"cycle": 4, "title": "Кузнецы закрыли ворота", "location": "Ремесленный квартал",
		"summary": "Мастера отказываются выдавать заказанные инструменты. Старшина говорит о долгах казны, канцлер — о завышенных счетах.",
		"choices": {"mediate": "Собрать обе стороны за одним столом", "pay": "Погасить спорную часть долга", "seize": "Изъять заказ по княжескому праву"}
	},
	"border_courier": {
		"cycle": 6, "title": "Гонец с северной дороги", "location": "Северные ворота",
		"summary": "Пограничный гонец видел чужих всадников без знамён. Они считали мосты и расспрашивали о зимних запасах.",
		"choices": {"scouts": "Отправить скрытный дозор", "envoy": "Запросить объяснение у соседа", "dismiss": "Не поднимать тревогу без доказательств"}
	}
}

@export var resolved: Dictionary = {}

func available_events(cycle: int) -> Array[String]:
	var result: Array[String] = []
	for event_id: String in DEFINITIONS:
		if int(DEFINITIONS[event_id]["cycle"]) <= cycle and not resolved.has(event_id):
			result.append(event_id)
	result.sort_custom(func(a: String, b: String) -> bool: return int(DEFINITIONS[a]["cycle"]) < int(DEFINITIONS[b]["cycle"]))
	return result

func definition(event_id: String) -> Dictionary:
	return DEFINITIONS.get(event_id, {})

func can_choose(state: WorldState, event_id: String, choice_id: String) -> bool:
	if event_id not in available_events(state.calendar.cycle):
		return false
	if not (definition(event_id).get("choices", {}) as Dictionary).has(choice_id):
		return false
	var required_gold := 0
	if event_id == "granary_roof" and choice_id == "repair": required_gold = 5
	if event_id == "smiths_dispute" and choice_id == "pay": required_gold = 8
	return state.state_treasury >= required_gold

func choose(state: WorldState, event_id: String, choice_id: String) -> bool:
	if not can_choose(state, event_id, choice_id):
		return false
	var outcome := _apply_choice(state, event_id, choice_id)
	resolved[event_id] = {"choice": choice_id, "cycle": state.calendar.cycle, "outcome": outcome}
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "story_event_resolved", "event": event_id, "choice": choice_id})
	return true

func _apply_choice(state: WorldState, event_id: String, choice_id: String) -> String:
	match "%s:%s" % [event_id, choice_id]:
		"granary_roof:repair":
			state.state_treasury -= 5
			state.facts["granary_roof"] = "repaired"
			return "Плотники заменили прогнившие стропила до следующего дождя. Смотритель просит позже разобраться, почему ремонт откладывали годами."
		"granary_roof:inspect":
			state.facts["granary_roof"] = "inspecting"
			return "Проверка нашла старые подложные отметки о ремонте. Крыша всё ещё требует работы, зато у дела появился виновник."
		"granary_roof:relocate":
			state.resources["grain"] = maxi(0, int(state.resources["grain"]) - 2)
			state.facts["granary_roof"] = "grain_relocated"
			return "Зерно разнесли по частным складам. Часть просыпали в дороге, а купцы теперь знают точный размер княжеских запасов."
		"smiths_dispute:mediate":
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, 3, "Князь лично выслушал спор ремесленников с казной.")
			return "Стороны согласились открыть книги. Работа возобновилась на три дня, пока писцы сверяют счета."
		"smiths_dispute:pay":
			state.state_treasury -= 8
			state.resources["tools"] = int(state.resources.get("tools", 0)) + 4
			return "Кузницы снова дымят, и первая партия инструментов уже ушла в мастерские. Канцлер считает, что вы создали опасный пример."
		"smiths_dispute:seize":
			state.resources["tools"] = int(state.resources.get("tools", 0)) + 5
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, -8, "Княжеская стража изъяла товар из кузниц во время спора об оплате.")
			return "Стража забрала заказ без драки. К вечеру в ремесленном квартале погасли почти все горны."
		"border_courier:scouts":
			state.facts["northern_scouts_sent"] = true
			return "Дозор ушёл налегке и вернётся с ответом позже. Капитан просит пока не распускать слухи в городе."
		"border_courier:envoy":
			state.facts["northern_envoy_sent"] = true
			return "Посольская грамота отправлена. Теперь сосед знает, что всадников заметили, но ещё не знает, насколько вы встревожены."
		"border_courier:dismiss":
			(state.factions["military"] as FactionState).react(state.calendar.cycle, -4, "Сообщение пограничного гонца оставили без проверки.")
			return "Гонца отпустили обратно. Он поклонился по уставу, но у ворот рассказал часовым, что в столице ему не поверили."
	return "Распоряжение принято. Его последствия станут понятны позже."

func outcome(event_id: String) -> String:
	return str((resolved.get(event_id, {}) as Dictionary).get("outcome", ""))

func to_data() -> Dictionary:
	return {"resolved": resolved.duplicate(true)}

func load_data(data: Dictionary) -> void:
	resolved = (data.get("resolved", {}) as Dictionary).duplicate(true)
