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
		title = "Элина ждёт объяснения о семейных деньгах"
		spoken_text = "После совета Элина закрывает дверь в семейные покои. «Ты оплатил из наших денег похороны и всё, что потребовалось для решения по зерну. Я не говорю, что людям не надо помогать. Я спрашиваю, почему узнала об этом после того, как ты поставил печать»."
		response_ids.assign(["apologize", "duty", "promise"])
	else:
		actor_id = "sister"
		if decision.grain_response == "defer":
			title = "Лада спрашивает о просителях из Долинной области"
			spoken_text = "После совета Лада догоняет вас в коридоре. «Старосты уехали без зерна. Ты сказал ждать, пока проверят книги. Сколько, по-твоему, они смогут ждать?»"
			response_ids.assign(["verify_first", "reserve_fear", "admit_delay"])
		else:
			title = "Лада спрашивает о помощи Долинной области"
			spoken_text = "После совета Лада остаётся у двери. «Я слышала, что ты отправляешь зерно в Долинную область. Хорошо. Но в книгах всё равно недостача. Ты будешь искать, кто её устроил?»"
			response_ids.assign(["investigate", "relief_first", "delegate"])
	status = Status.AVAILABLE

func response_title(response_id: String) -> String:
	return {
		"apologize": "Признать, что следовало обсудить это вместе",
		"duty": "Напомнить, что долг князя выше семейного покоя",
		"promise": "Пообещать вернуть средства семье",
		"people": "Люди не должны платить за нашу медлительность",
		"order": "Сначала нужно сохранить порядок",
		"family": "Я хотел достойно проводить отца",
		"verify_first": "Если запас уже украли, новый обоз тоже может не дойти",
		"reserve_fear": "Я не могу опустошить амбары, не зная, сколько зерна осталось",
		"admit_delay": "Я не знаю. Возможно, я слишком долго сомневаюсь",
		"investigate": "Да. Помощь не отменяет расследования",
		"relief_first": "Сначала обоз должен дойти до людей",
		"delegate": "Поручу проверку тому, кто не связан с казной"
	}.get(response_id, "")

func choose(state: WorldState, response_id: String) -> bool:
	if not state.can_govern() or status != Status.AVAILABLE or response_id not in response_ids:
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
		"verify_first":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы объяснили задержку опасением новой кражи зерна.", {"respect": 2})
			state.facts["grain_investigation_promised"] = true
			closing_text = "Лада кивает. «Тогда найди виновного быстро. Пустая миска не становится полнее от правильного расследования»."
		"reserve_fear":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы признались, что боитесь оставить княжество без резерва.", {"trust": 1})
			closing_text = "«Этого я хотя бы понимаю», — отвечает Лада. «Но старостам нужно было сказать то же самое, а не отправлять их молча»."
		"admit_delay":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы признали, что сомнения могли оставить людей без помощи.", {"trust": 3, "resentment": -1})
			closing_text = "Лада выдыхает. «Тогда ещё можно исправить. Только не жди, пока они снова приедут просить»."
		"investigate":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы пообещали расследовать недостачу после отправки помощи.", {"trust": 3, "respect": 1})
			state.facts["grain_investigation_promised"] = true
			closing_text = "«Хорошо. Я попрошу старост записать, сколько зерна действительно дошло до каждой деревни»."
		"relief_first":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы поставили доставку помощи выше немедленного поиска виновных.", {"affection": 2})
			closing_text = "Лада кивает. «Тогда я дождусь обоз у южной дороги и пришлю тебе весть»."
		"delegate":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы решили провести независимую проверку зерновых книг.", {"respect": 3})
			state.facts["independent_grain_audit_promised"] = true
			closing_text = "«Только не Борину», — сразу говорит Лада. «Если ошиблись его люди, они же не должны проверять сами себя»."
	status = Status.RESOLVED
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "opening_followup_resolved", "actor": actor_id, "response": response_id})
	state.add_fatigue(2)
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
