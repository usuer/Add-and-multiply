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
		title = "Адела спрашивает, кто распоряжается семейным сундуком"
		var expense := "похороны"
		if decision.grain_response == "purchase":
			expense = "похороны и покупку зерна у купцов"
		elif decision.grain_response == "full":
			expense = "похороны, подводы и охрану обоза"
		spoken_text = "Адела кладёт перед вами расписку казначея. «Здесь %d монет за %s, и сняли их не из казны, а из сундука, из которого я содержу наш дом. Я не спорю с расходом. Я спрашиваю, почему узнала о нём от казначея»." % [decision.required_gold(), expense]
		response_ids.assign(["apologize", "duty", "promise"])
	else:
		actor_id = "sister"
		if decision.grain_response == "defer":
			title = "Лада спрашивает о просителях из Долинной области"
			spoken_text = "После совета Лада догоняет вас в коридоре. «Старосты уехали без зерна. Я сама ночевала у одной из тех семей: кашу там уже варят пополам с отрубями. Ты сказал ждать, пока проверят книги. Когда ты пошлёшь кого-нибудь к амбарам?»"
			response_ids.assign(["verify_first", "reserve_fear", "admit_delay"])
		else:
			title = "Лада спрашивает о помощи Долинной области"
			spoken_text = _after_aid_speech(decision.grain_response)
			response_ids.assign(["investigate", "relief_first", "delegate"])
	status = Status.AVAILABLE

func _after_aid_speech(grain_response: String) -> String:
	var opening := "Я слышала, что ты отправляешь зерно в Долинную область."
	match grain_response:
		"partial": opening += " Восьми мер хватит двум ближним деревням. Дальние всё равно ждут."
		"full": opening += " Большой обоз накормит и дальние деревни. Но часть дороги проходит мимо тех же складов, где зерно не сошлось по книгам."
		"purchase": opening = "Я слышала, что ты купил зерно у сарнцев. Купцы обещают привезти его из-за рубежа, а пока старосты вернутся домой с одной грамотой."
	return "После совета Лада остаётся у двери. «%s В областной книге сказано, что хлеб выдали ещё зимой. У старост нет ни хлеба, ни расписок. Ты поручишь кому-нибудь проверить, где он пропал?»" % opening

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
			closing_text = "Адела не улыбается, но напряжение в её голосе ослабевает. «Тогда в следующий раз войди сюда до того, как поставишь печать»."
		"duty":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы поставили княжеский долг выше семейного согласия.", {"respect": 2, "trust": -3, "resentment": 2})
			closing_text = "«Я услышала князя», — отвечает Адела. Слово “муж” она не произносит."
		"promise":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы пообещали возместить семейные средства.", {"trust": 2})
			state.facts["debt_to_family"] = state.opening_decision.required_gold()
			closing_text = "Адела кладёт расписку обратно в сундук. «Хорошо. Верни %s, когда сможешь. На следующий расход давай договоримся до совета»." % _coin_amount(int(state.facts["debt_to_family"]))
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
			closing_text = "Лада кивает. «Марта в городских амбарах знает, кто принимал зимние обозы. Начни с неё. Я тем временем узнаю, сколько хлеба осталось у каждой деревни»."
		"reserve_fear":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы признались, что боитесь оставить княжество без резерва.", {"trust": 1})
			closing_text = "«Этого я хотя бы понимаю», — отвечает Лада. «Но старостам нужно было сказать то же самое, а не отправлять их молча»."
		"admit_delay":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы признали, что сомнения могли оставить людей без помощи.", {"trust": 3, "resentment": -1})
			closing_text = "Лада выдыхает. «Тогда ещё можно исправить. Только не жди, пока они снова приедут просить»."
		"investigate":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы пообещали расследовать недостачу после отправки помощи.", {"trust": 3, "respect": 1})
			state.facts["grain_investigation_promised"] = true
			closing_text = "«Хорошо. Я попрошу старост записать, сколько зерна дошло. У Марты в княжеских амбарах остались записи о выдаче. Поговори с ней, прежде чем выбирать, кто займётся проверкой»."
		"relief_first":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы поставили доставку помощи выше немедленного поиска виновных.", {"affection": 2})
			closing_text = "Лада кивает. «Тогда я встречу обоз у южной дороги и попрошу возчиков привезти обратно расписки от старост»."
		"delegate":
			actor.remember(state.calendar.cycle, "private_conversation", "Вы решили провести независимую проверку зерновых книг.", {"respect": 3})
			state.facts["independent_grain_audit_promised"] = true
			closing_text = "«Только не Борину», — сразу говорит Лада. «В городских амбарах можно поручить проверку управляющему, капитану, агенту или мне. Марта покажет, какие книги ещё целы»."
	status = Status.RESOLVED
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "opening_followup_resolved", "actor": actor_id, "response": response_id})
	state.add_fatigue(2)
	return true

func family_debt_terms(state: WorldState) -> Dictionary:
	var amount := int(state.facts.get("debt_to_family", 0))
	if amount <= 0 or state.calendar.is_demo_complete():
		return {}
	var context := ""
	if _family_away(state):
		context = "Лада привезла расписку из семейного сундука. Адела с детьми за городом. Деньги или ответ она примет через Ладу."
	else:
		context = "Адела открыла семейную книгу и показала расход, который вы обещали возместить после похорон."
	var options := {
		"repay": {"title": "Вернуть из государственной казны %s" % _coin_amount(amount), "enabled": state.can_govern() and state.state_treasury >= amount}
	}
	if state.state_treasury < amount:
		context += " Сейчас в казне не хватает всей суммы."
	if state.facts.get("family_debt_status") == "extended":
		context += " Семья уже согласилась ждать до конца лета. Обещание вернуть деньги остаётся в силе."
	else:
		options["renegotiate"] = {"title": "Попросить отсрочку до конца лета и дать Аделе выписки из казны", "enabled": state.can_govern()}
	return {"title": "Обещание вернуть семейные деньги", "amount": amount, "context": context, "options": options}

func settle_family_debt(state: WorldState, choice_id: String) -> String:
	var terms := family_debt_terms(state)
	var options: Dictionary = terms.get("options", {})
	if not options.has(choice_id) or not options[choice_id]["enabled"]:
		return ""
	var spouse := state.characters["spouse"] as CharacterState
	var cycle := state.calendar.cycle
	var amount := int(terms["amount"])
	var result := ""
	if choice_id == "repay":
		state.state_treasury -= amount
		state.family_treasury += amount
		state.facts["debt_to_family"] = 0
		state.facts["family_debt_status"] = "repaid"
		spouse.remember(cycle, "family_debt_repaid", "Вы сдержали обещание и вернули семье деньги.", {"trust": 5})
		if _family_away(state):
			result = "Лада отвезла деньги Аделе и вернулась с распиской. Адела отдельно написала, что записала возврат в семейную книгу."
		else:
			result = "Адела пересчитала деньги и перечеркнула долг в семейной книге. «В следующий раз я хочу знать о расходе до совета. Но это обещание ты сдержал»."
	else:
		state.facts["family_debt_status"] = "extended"
		spouse.remember(cycle, "family_debt_extended", "Семья согласилась отсрочить возврат в обмен на право видеть выписки казны.", {"trust": -1, "respect": 2})
		if _family_away(state):
			result = "Лада вернула подписанное Аделой письмо. Семья ждёт до конца лета. Адела просит присылать выписки из казны, пока сумма не будет возвращена."
		else:
			result = "«До конца лета», — повторила Адела и вписала срок в расписку. Отныне писцы будут показывать ей выписки. Деньги пока остались в казне, а долг — в семейной книге."
	state.add_fatigue(1)
	state.consequence_log.append({"cycle": cycle, "kind": "family_debt_settled", "choice": choice_id, "amount": amount})
	return result

func _family_away(state: WorldState) -> bool:
	return state.facts.get("family_security") in ["country_cloister", "breached"]

func _coin_amount(amount: int) -> String:
	var noun := "монет"
	if amount % 100 not in [11, 12, 13, 14]:
		if amount % 10 == 1:
			noun = "монету"
		elif amount % 10 in [2, 3, 4]:
			noun = "монеты"
	return "%d %s" % [amount, noun]

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
