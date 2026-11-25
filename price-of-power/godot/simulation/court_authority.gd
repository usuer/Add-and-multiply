extends RefCounted

const OFFICIALS := {
	"borin": {"role": "казна", "faction": "nobility", "context": "Борин хранит расписки и ведёт расчёты. Без него управление казной придётся передать другому."},
	"granary_keeper": {"role": "амбары", "faction": "rural", "context": "Марта знает, кто принимал обозы. Если её отстранить, выдачей займутся писцы, а устные показания придётся искать заново."},
	"forge_master": {"role": "кузница", "faction": "guilds", "context": "Глеб ведёт очередь работ. Его подмастерья могут продолжить заказ, но цех потребует объяснений."}
}

static func eligible_people(state: WorldState) -> Array[String]:
	var result: Array[String] = []
	if state.opening_decision.status == OpeningDecision.Status.RESOLVED:
		for person_id: String in OFFICIALS:
			if state.characters.has(person_id):
				result.append(person_id)
	return result

static func _record(state: WorldState, person_id: String) -> Dictionary:
	var records: Dictionary = state.facts.get("court_authority", {})
	return records.get(person_id, {})

static func _put_record(state: WorldState, person_id: String, record: Dictionary) -> void:
	var records: Dictionary = state.facts.get("court_authority", {})
	records[person_id] = record
	state.facts["court_authority"] = records

static func is_present(state: WorldState, person_id: String) -> bool:
	return _record(state, person_id).get("status", "") not in ["detained", "dead"]

static func _vacate(state: WorldState, person_id: String) -> void:
	for role_id: String in state.council.appointments:
		if state.council.appointments[role_id] == person_id:
			state.council.appointments[role_id] = ""

static func status_text(state: WorldState, person_id: String) -> String:
	match str(_record(state, person_id).get("status", "")):
		"detained": return "Под стражей"
		"released": return "На свободе после разбирательства"
		"ordered": return "Секретное распоряжение передано"
		"dead": return "Смерть подтверждена"
	return "На службе"

static func options(state: WorldState, person_id: String) -> Dictionary:
	if person_id not in eligible_people(state) or not state.can_govern() or state.calendar.is_demo_complete():
		return {}
	var context := str(OFFICIALS[person_id]["context"])
	var status := str(_record(state, person_id).get("status", ""))
	if status == "detained":
		return {"release": {"title": "Освободить из-под стражи", "context": "Место в тюрьме освободится. На прежнюю должность нужно назначить отдельным решением.", "enabled": true}}
	if status != "":
		return {}
	return {
		"detain": {
			"title": "Взять под стражу", "context": context + " Задержание займёт одно место. На следующий период судьи представят доклад.",
			"enabled": state.justice.prisoners < state.justice.prison_capacity
		},
		"secret_removal": {
			"title": "Отдать тайный приказ о смерти", "context": context + " Последствия станут известны в следующий период. Если приказ вскроется, отвечать придётся перед двором.",
			"enabled": true
		}
	}

static func choose(state: WorldState, person_id: String, action_id: String) -> String:
	var action: Dictionary = options(state, person_id).get(action_id, {})
	if not action.get("enabled", false):
		return ""
	var person := state.characters[person_id] as CharacterState
	var name := person.display_name
	var due := state.calendar.cycle + 1
	var result := ""
	match action_id:
		"detain":
			_put_record(state, person_id, {"status": "detained", "due": due})
			state.justice.prisoners += 1
			_vacate(state, person_id)
			person.remember(state.calendar.cycle, "ordered_detention", "Вы приказали взять этого человека под стражу.", {"trust": -9, "resentment": 7})
			result = "%s теперь под стражей. Судьи соберут документы к следующему периоду." % name
		"release":
			_put_record(state, person_id, {"status": "released"})
			state.justice.prisoners = maxi(0, state.justice.prisoners - 1)
			person.remember(state.calendar.cycle, "released_after_inquiry", "Вы прекратили задержание, но не вернули человека на должность.", {"trust": 2})
			result = "Стража выпустила задержанного: %s. Прежние обязанности теперь можно вернуть отдельным решением." % name
		"secret_removal":
			_put_record(state, person_id, {"status": "ordered", "due": due})
			result = "Распоряжение передано. Что станет известно об исчезновении чиновника, покажет следующий период."
	state.add_fatigue(2)
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "court_authority", "person": person_id, "action": action_id})
	return result

static func update(state: WorldState) -> void:
	for person_id: String in OFFICIALS:
		var record := _record(state, person_id)
		var due := int(record.get("due", 0))
		if due == 0 or due > state.calendar.cycle:
			continue
		var person := state.characters[person_id] as CharacterState
		var name := person.display_name
		var faction_id := str(OFFICIALS[person_id]["faction"])
		var faction := state.factions[faction_id] as FactionState
		var message := ""
		var title := "Доклад судей"
		if record["status"] == "detained":
			var report := "Судьи сверили бумаги. Они просят решить, удерживать ли чиновника дальше. Доказательств личного участия в подлоге пока нет."
			if person_id == "borin" and state.facts.get("missing_armory_payment", false):
				report = "Ярина принесла ведомость со спорным платежом. Подпись в строке получателя вписана позже, но пока не установлено, кто её поставил."
			message = "%s остаётся под стражей. %s" % [name, report]
			faction.react(state.calendar.cycle, -2, "Служащие ждут, предъявят ли задержанному обвинение.")
		elif record["status"] == "ordered":
			record["status"] = "dead"
			_vacate(state, person_id)
			title = "Чиновник не вернулся на службу"
			var daren := state.characters["daren"] as CharacterState
			var exposed := daren.trust < 18 or faction.disposition < 0
			if exposed:
				state.public_order = maxi(0, state.public_order - 5)
				faction.react(state.calendar.cycle, -8, "По городу разошёлся слух о тайном приказе двора.")
				state.facts["court_order_exposed"] = true
				message = "Известие о смерти: %s. В городе говорят о приказе из замка. Родные требуют открытого разбирательства, а несколько писцов отказались подписывать новые бумаги." % name
			else:
				faction.react(state.calendar.cycle, -3, "Смерть чиновника оставила ведомство без руководителя.")
				message = "Известие о смерти: %s. Связь с распоряжением пока не установили. Семья просит вернуть бумаги, а в ведомстве ждут назначения преемника." % name
		record["due"] = 0
		_put_record(state, person_id, record)
		if not message.is_empty():
			state.story_timeline.reports.append({"cycle": state.calendar.cycle, "title": title, "text": message, "read": false})
