class_name OpeningFollowup
extends Resource

enum Status { LOCKED, AVAILABLE, RESOLVED }

@export var status: Status = Status.LOCKED
@export var actor_id: String = ""
@export var title: String = ""
@export var spoken_text: String = ""
@export var response_ids: Array[String] = []
@export var chosen_response: String = ""
@export var closing_text: String = ""

func prepare(decision: OpeningDecision) -> void:
	if status != Status.LOCKED:
		return
	if decision.funding_source == "family":
		actor_id = "spouse"
		title = "Разговор после совета"
		spoken_text = "Элина ждёт вас у погасшего камина. «Я не спорю с самим решением. Но семейная казна — это безопасность детей и дома. Мне важно знать: ты всё ещё считаешь меня частью таких решений?»"
		response_ids.assign(["apologize", "duty", "promise"])
	else:
		actor_id = "sister"
		title = "Сестра просит объяснения"
		spoken_text = "Лада задерживается после совета. «Люди запомнят не сумму расходов, а то, кого ты услышал первым. Скажи честно: что для тебя было главным?»"
		response_ids.assign(["people", "order", "family"])
	status = Status.AVAILABLE

func response_title(response_id: String) -> String:
	return {
		"apologize": "Признать, что следовало обсудить это вместе",
		"duty": "Напомнить, что долг князя выше семейного покоя",
		"promise": "Пообещать вернуть средства семье",
		"people": "Люди не должны платить за нашу медлительность",
		"order": "Сначала нужно сохранить порядок",
		"family": "Я хотел достойно проводить отца"
	}.get(response_id, "")

func choose(state: WorldState, response_id: String) -> bool:
	if status != Status.AVAILABLE or response_id not in response_ids:
		return false
	chosen_response = response_id
	var actor: CharacterState = state.characters[actor_id]
	match response_id:
		"apologize":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы признали, что должны были посоветоваться.", {"trust": 4, "resentment": -2})
			closing_text = "Элина не улыбается, но напряжение в её голосе ослабевает. «Тогда в следующий раз войди сюда до того, как поставишь печать»."
		"duty":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы поставили княжеский долг выше семейного согласия.", {"respect": 2, "trust": -3, "resentment": 2})
			closing_text = "«Я услышала князя», — отвечает Элина. Слово “муж” она не произносит."
		"promise":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы пообещали возместить семейные средства.", {"trust": 2})
			state.facts["debt_to_family"] = 12
			closing_text = "Элина кивает. Теперь это не просто утешение: у семьи появилось обещание, которое она запомнит."
		"people":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы назвали защиту жителей первым долгом правителя.", {"trust": 3, "respect": 2})
			closing_text = "Лада отвечает не сразу. «Тогда не отворачивайся, когда выяснится, почему они дошли до голода»."
		"order":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы поставили порядок и проверку выше порыва.", {"respect": 2, "affection": -1})
			closing_text = "«Порядок — хорошее слово», — говорит Лада. «Особенно для тех, кто сегодня ужинает»."
		"family":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы признались, что думали прежде всего о семье и памяти отца.", {"affection": 3})
			closing_text = "Лада берёт вас за руку. «Это честный ответ. Только княжество не даст нам долго оставаться просто детьми своего отца»."
	status = Status.RESOLVED
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "opening_followup_resolved", "actor": actor_id, "response": response_id})
	return true

func to_data() -> Dictionary:
	return {"status": int(status), "actor_id": actor_id, "title": title, "spoken_text": spoken_text, "response_ids": response_ids.duplicate(), "chosen_response": chosen_response, "closing_text": closing_text}

func load_data(data: Dictionary) -> void:
	status = clampi(int(data.get("status", 0)), 0, Status.size() - 1) as Status
	actor_id = str(data.get("actor_id", ""))
	title = str(data.get("title", ""))
	spoken_text = str(data.get("spoken_text", ""))
	response_ids.assign(data.get("response_ids", []))
	chosen_response = str(data.get("chosen_response", ""))
	closing_text = str(data.get("closing_text", ""))
