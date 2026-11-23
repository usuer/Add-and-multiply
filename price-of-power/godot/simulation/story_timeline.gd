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
	},
	"scout_report": {
		"cycle": 8, "title": "Карта чужого похода", "location": "Военный зал",
		"summary": "Дозор вернулся с зарисовками лагерей. За границей собирают обоз и лёгкую конницу. Это ещё не объявление войны, но уже не случайная разведка.",
		"choices": {"fortify": "Укрепить переправы и поднять гарнизоны", "parley": "Предложить тайную встречу на границе", "trap": "Оставить путь открытым и готовить засаду"}
	},
	"fever_outbreak": {
		"cycle": 10, "title": "Горячка в нижнем городе", "location": "Речной квартал",
		"summary": "За три дня слегли семьи кожевников и двое лодочников. Причина неизвестна; слухи уже называют воду, чужеземцев и Божий гнев.",
		"choices": {"quarantine": "Перекрыть квартал и доставлять пищу внутрь", "clinics": "Открыть временные лечебницы", "conceal": "Не объявлять тревогу до точного диагноза"}
	}
}

@export var resolved: Dictionary = {}
@export var reports: Array[Dictionary] = []

func available_events(cycle: int) -> Array[String]:
	var result: Array[String] = []
	for event_id: String in DEFINITIONS:
		if int(DEFINITIONS[event_id]["cycle"]) <= cycle and not resolved.has(event_id) and _is_unlocked(event_id, cycle):
			result.append(event_id)
	result.sort_custom(func(a: String, b: String) -> bool: return int(DEFINITIONS[a]["cycle"]) < int(DEFINITIONS[b]["cycle"]))
	return result

func _is_unlocked(event_id: String, cycle: int) -> bool:
	if event_id != "scout_report":
		return true
	var border: Dictionary = resolved.get("border_courier", {})
	return str(border.get("choice", "")) == "scouts" and cycle >= int(border.get("cycle", 999)) + 2

func update(state: WorldState) -> void:
	_apply_delayed_results(state)
	_resolve_neglected_events(state)

func _apply_delayed_results(state: WorldState) -> void:
	if not resolved.has("border_courier"):
		return
	var record: Dictionary = resolved["border_courier"]
	if str(record.get("choice", "")) == "scouts" and not bool(record.get("followup_applied", false)) and state.calendar.cycle >= int(record.get("cycle", 0)) + 2:
		state.facts["northern_scouts_returned"] = true
		record["followup_applied"] = true
		resolved["border_courier"] = record
		state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "scouts_returned"})
		_add_report(state.calendar.cycle, "Дозор вернулся", "Разведчики принесли карту чужих лагерей. В военном зале ждут вашего решения.")

func _resolve_neglected_events(state: WorldState) -> void:
	for event_id: String in DEFINITIONS:
		if resolved.has(event_id) or not _is_unlocked(event_id, state.calendar.cycle):
			continue
		var event: Dictionary = DEFINITIONS[event_id]
		if state.calendar.cycle < int(event["cycle"]) + 2:
			continue
		var result := _neglect_consequence(state, event_id)
		resolved[event_id] = {"choice": "neglected", "cycle": state.calendar.cycle, "outcome": result}
		state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "story_event_neglected", "event": event_id})
		_add_report(state.calendar.cycle, "Дело решилось без вас", result)

func _add_report(cycle: int, title: String, text: String) -> void:
	reports.append({"cycle": cycle, "title": title, "text": text, "read": false})

func unread_reports() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for report: Dictionary in reports:
		if not bool(report.get("read", false)):
			result.append(report)
	return result

func mark_reports_read() -> void:
	for index in range(reports.size()):
		reports[index]["read"] = true

func _neglect_consequence(state: WorldState, event_id: String) -> String:
	match event_id:
		"granary_roof":
			state.resources["grain"] = maxi(0, int(state.resources.get("grain", 0)) - 12)
			state.facts["granary_roof"] = "collapsed"
			return "После нового ливня часть кровли рухнула. Намокшее зерно пришлось выбросить."
		"smiths_dispute":
			state.resources["tools"] = maxi(0, int(state.resources.get("tools", 0)) - 2)
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, -5, "Княжеский двор две недели не отвечал на остановку кузниц.")
			return "Спор оставался без ответа, и кузнецы разошлись по частным заказам."
		"border_courier":
			(state.factions["military"] as FactionState).react(state.calendar.cycle, -3, "Пограничное донесение пролежало без приказа.")
			return "Пока донесение ждало решения, неизвестные всадники ушли с собранными сведениями."
		"fever_outbreak":
			state.public_health = maxi(0, state.public_health - 14)
			state.facts["fever_policy"] = "neglected"
			return "Пока совет ждал приказа, горячка вышла из речного квартала и добралась до городских казарм."
	return "Дело слишком долго оставалось без решения, и обстоятельства решили его за вас."

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
	if event_id == "scout_report" and choice_id == "fortify": required_gold = 12
	if event_id == "fever_outbreak" and choice_id == "quarantine": required_gold = 6
	if event_id == "fever_outbreak" and choice_id == "clinics": required_gold = 10
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
		"scout_report:fortify":
			state.state_treasury -= 12
			state.facts["northern_posture"] = "fortified"
			state.army.begin_border_battle("fortified")
			state.army.supplies += state.technology.campaign_supply_bonus()
			return "К переправам выступили сапёры и гарнизонные роты. Скрыть приготовления от соседских лазутчиков не получится."
		"scout_report:parley":
			state.facts["northern_posture"] = "parley"
			return "Посланник повёз предложение о встрече без свидетелей. Если это уловка, он окажется в руках противника."
		"scout_report:trap":
			state.facts["northern_posture"] = "ambush"
			state.army.begin_border_battle("ambush")
			state.army.supplies += state.technology.campaign_supply_bonus()
			(state.factions["military"] as FactionState).react(state.calendar.cycle, 3, "Князь доверил войску подготовку скрытой обороны переправы.")
			return "На вид переправа осталась беззащитной. Ночью дружина начала занимать лесные балки по обе стороны дороги."
		"fever_outbreak:quarantine":
			state.state_treasury -= 6
			state.public_health = mini(100, state.public_health + 2)
			(state.factions["rural"] as FactionState).react(state.calendar.cycle, -2, "Стража перекрыла больной квартал вместе со здоровыми семьями.")
			state.facts["fever_policy"] = "quarantine"
			return "Стража закрыла улицы до рассвета. Болезнь распространяется медленнее, но запертые жители требуют лекаря и ясного срока."
		"fever_outbreak:clinics":
			state.state_treasury -= 10
			var treatment := 8 if state.council.medicine_skill() >= 3 else 3
			state.public_health = mini(100, state.public_health + treatment)
			state.facts["fever_policy"] = "clinics"
			return "Лечебницы приняли первых больных. %s" % ("Назначенный лекарь разделил пациентов и наладил учёт симптомов." if treatment > 3 else "Без главы лекарской службы помощники спорят о методах, и часть коек остаётся без надзора.")
		"fever_outbreak:conceal":
			state.public_health = maxi(0, state.public_health - 9)
			state.facts["fever_policy"] = "concealed"
			return "Рынок продолжил работу. Через несколько дней похожий жар обнаружили уже за пределами речного квартала."
	return "Распоряжение принято. Его последствия станут понятны позже."

func outcome(event_id: String) -> String:
	return str((resolved.get(event_id, {}) as Dictionary).get("outcome", ""))

func to_data() -> Dictionary:
	return {"resolved": resolved.duplicate(true), "reports": reports.duplicate(true)}

func load_data(data: Dictionary) -> void:
	resolved = (data.get("resolved", {}) as Dictionary).duplicate(true)
	reports.assign(data.get("reports", []))
