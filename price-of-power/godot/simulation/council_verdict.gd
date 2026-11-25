extends RefCounted

const TITLE := "Слушание о второй печати"
const HEARING_RULES := ["public_law", "conditional_amnesty", "secret_purge"]

static func terms(state: WorldState) -> Dictionary:
	if state.calendar.is_demo_complete() or state.facts.has("council_verdict") or not _hearing_ordered(state):
		return {}
	var evidence := _evidence(state)
	var enabled := state.can_govern()
	var publication := "Огласить, что установлено о ночных грамотах"
	if state.facts.get("new_rule") == "secret_purge":
		publication = "Опубликовать вывод о грамотах без имён свидетелей"
	var separation := "Отдельно передать судьям бумаги о прежних выплатах"
	if evidence["petition"]:
		separation = "Передать судьям и прошение семьи погибшего чиновника"
	elif not evidence["ledger_complete"]:
		separation = "Выделить проверку прежних выплат в отдельное дело"
	return {
		"title": TITLE,
		"context": _brief(evidence),
		"options": {
			"publish_record": {"title": publication, "enabled": enabled},
			"handle_vardan": {"title": _vardan_action(evidence), "enabled": enabled},
			"separate_claims": {"title": separation, "enabled": enabled}
		}
	}

static func choose(state: WorldState, choice_id: String) -> String:
	var hearing := terms(state)
	var choices: Dictionary = hearing.get("options", {})
	var choice: Dictionary = choices.get(choice_id, {})
	if not choice.get("enabled", false):
		return ""
	var evidence := _evidence(state)
	var result := ""
	match choice_id:
		"publish_record": result = _publish(state, evidence)
		"handle_vardan": result = _hear_vardan(state, evidence)
		"separate_claims": result = _separate_claims(state, evidence)
	state.add_fatigue(2)
	_record(state, choice_id, str(choice["title"]), result)
	return result

static func update(state: WorldState) -> void:
	if not state.calendar.is_demo_complete() or state.facts.has("council_verdict") or not _hearing_ordered(state):
		return
	var result := "Совет разошёлся, так и не распорядившись об уликах. Марек записал, что суд пока не установил, кто заверил ночные грамоты."
	match str(state.facts.get("vardan_stance", "")):
		"in_custody": result += " Вардан остаётся под стражей в ожидании отдельного решения о слушании."
		"inside_council": result += " Условия сделки с Варданом остаются в силе."
	_record(state, "passed_over", "Не назначать дальнейшее слушание", result)

static func _hearing_ordered(state: WorldState) -> bool:
	return state.facts.get("new_rule") in HEARING_RULES

static func _evidence(state: WorldState) -> Dictionary:
	return {
		"proof": bool(state.facts.get("second_seal_order_proof", false)),
		"ledger": str(state.facts.get("fathers_ledger", "")),
		"ledger_complete": state.facts.get("fathers_ledger") in ["published", "inner_circle", "network_reactivated"],
		"petition": bool(state.facts.get("court_order_exposed", false)),
		"stance": str(state.facts.get("vardan_stance", "")),
		"seal": str(state.facts.get("second_seal_custody", ""))
	}

static func _brief(evidence: Dictionary) -> String:
	var result := "Марек положил на стол бумаги по ночным грамотам."
	if evidence["proof"]:
		result += " Сверка установила, какие приказы канцелярия не выдавала. Кто распорядился их разослать, ещё предстоит установить."
	else:
		result += " Расписки и показания расходятся. Одних этих бумаг пока недостаточно, чтобы установить, кто отдавал приказы."
	match str(evidence["ledger"]):
		"published", "inner_circle", "network_reactivated":
			result += " Отцовская книга подтверждает прежние выплаты. По ней нельзя судить о действиях людей после его смерти."
		"stolen_page":
			result += " В отцовской книге не хватает последней страницы."
	match str(evidence["stance"]):
		"in_custody":
			result += " Вардан ждёт под стражей."
			if evidence["seal"] == "judges":
				result += " Печать внесена в опись судей."
		"inside_council":
			result += " Вардан пришёл как советник. Сделка с ним обещает неприкосновенность его людям."
		"escaped_exchange":
			result += " После сорванного обмена никто не подтвердил, где Вардан."
		_:
			result += " Вардана на слушании нет."
	if evidence["petition"]:
		result += " У двери ждут родные погибшего чиновника. Они просят суд проверить и приказ, отданный из замка."
	return result

static func _vardan_action(evidence: Dictionary) -> String:
	match str(evidence["stance"]):
		"in_custody":
			return "Оставить Вардана под стражей до проверки передачи печати" if evidence["proof"] else "Освободить Вардана под обязательство явиться к судьям"
		"inside_council":
			return "Соблюсти сделку и попросить Вардана дать показания добровольно"
	return "Вызвать Вардана на слушание по ночным грамотам" if evidence["proof"] else "Сначала вызвать свидетелей по ночным грамотам"

static func _publish(state: WorldState, evidence: Dictionary) -> String:
	var result := ""
	if state.facts.get("new_rule") == "secret_purge":
		result = "Писцы выпустили короткую выписку без имён свидетелей. Судебные бумаги пока остались закрытыми."
	else:
		result = "Глашатай зачитал протокол при старшинах."
	if evidence["proof"]:
		result += " Судьи указали, какие грамоты не выходили из канцелярии. Обвинение против конкретного человека в протокол не внесли."
	else:
		result += " Марек велел записать расхождения и указать, какие подлинники ещё ищут. Несколько старшин потребовали назвать виновных, но такого вывода судьи не подписали."
	if evidence["petition"]:
		result += " Родные чиновника услышали оглашение, однако ответа на своё прошение в выписке не нашли."
	_react(state, "guilds", 3 if evidence["proof"] else 1, "Двор огласил, какие распоряжения проверены и какие ещё требуют сверки.")
	return result

static func _hear_vardan(state: WorldState, evidence: Dictionary) -> String:
	match str(evidence["stance"]):
		"in_custody":
			if evidence["proof"]:
				_react(state, "guilds", 2, "Судьи назначили проверку обстоятельств передачи печати и сохранили меру задержания.")
				return "Судьи записали, какие документы проверят о передаче печати. До этого слушания Вардан остаётся под стражей. Установленная подделка ещё не доказывает, что именно он разослал грамоты."
			state.facts["vardan_stance"] = "released_for_hearing"
			state.justice.prisoners = maxi(0, state.justice.prisoners - 1)
			_react(state, "guilds", -2, "Вардана освободили до слушания. Владельцы разграбленных складов требуют объяснений.")
			var release := "Вардан покинул тюрьму и расписался, что явится по вызову."
			if evidence["seal"] == "judges":
				release += " Изъятый предмет остаётся в описи судей."
			return release + " Старшины со складов требуют, чтобы дата разбирательства появилась в реестре."
		"inside_council":
			state.facts["vardan_hearing"] = "voluntary_testimony"
			var vardan := state.characters["vardan"] as CharacterState
			vardan.remember(state.calendar.cycle, "council_hearing", "Вы сохранили условия сделки и предложили ему ответить на вопросы о печати.", {"trust": 2})
			_react(state, "guilds", -1, "Вардан сохранит место в совете, пока судьи спрашивают его об условиях передачи печати.")
			return "Вардан согласился ответить на вопросы о передаче печати. За ним сохранили место в совете, а за его людьми — обещанные гарантии. Несколько старшин всё равно потребовали обвинить его немедленно."
	if evidence["proof"]:
		state.facts["vardan_hearing"] = "summons_issued"
		return "Судьи выписали Вардану вызов. Старостам сообщили дату, но никто пока не подтвердил, что он получил грамоту или явится."
	state.facts["vardan_hearing"] = "witnesses_first"
	return "Марек попросил горожан принести свои экземпляры ночных распоряжений. Прежде чем вызвать Вардана, судьи сверят книги с показаниями."

static func _separate_claims(state: WorldState, evidence: Dictionary) -> String:
	if evidence["petition"]:
		state.facts["court_petition_referred"] = true
		var miron := state.characters["miron"] as CharacterState
		miron.remember(state.calendar.cycle, "council_hearing", "Вы позволили судьям проверить приказ из собственного замка.", {"respect": 4})
		_react(state, "guilds", 3, "Судьи приняли отдельное прошение семьи погибшего чиновника, не закрыв дело о ночных грамотах.")
		return "Судьи приняли прошение семьи и открыли отдельную запись о приказе из замка. Марек положил ночные грамоты в другой ящик. Приговора пока нет, но родные получили расписку с именами судей."
	var result := "Марек разделил бумаги на два дела. Одно касается ночных грамот, другое — старых выплат."
	if evidence["ledger_complete"]:
		result += " Судьи внесли книгу в опись. Строки о прежних платежах оставили в отдельном томе, чтобы в новом деле не принять запись о найме за приказ."
	else:
		result += " Прежние расписки закажут из архивов. Утраченные записи пока не заменяют догадками."
	_react(state, "nobility", -2, "Суд проверит прежние выплаты отдельно от подложных грамот.")
	return result

static func _react(state: WorldState, faction_id: String, amount: int, reason: String) -> void:
	var faction := state.factions[faction_id] as FactionState
	faction.react(state.calendar.cycle, amount, reason)

static func _record(state: WorldState, choice: String, title: String, outcome: String) -> void:
	var stance := str(state.facts.get("vardan_stance", ""))
	state.facts["council_verdict"] = {
		"cycle": state.calendar.cycle, "choice": choice, "title": title, "outcome": outcome,
		"epilogue": _ending_note(state, choice, stance), "vardan_stance": stance
	}
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "council_verdict", "choice": choice, "outcome": outcome})

static func _ending_note(state: WorldState, choice: String, stance: String) -> String:
	match choice:
		"publish_record":
			if state.facts.get("second_seal_order_proof", false):
				return "Судьи огласили, какие ночные грамоты были подложными. Имя заказчика ещё не установлено."
			return "Судьи огласили расхождения в бумагах. Дело осталось без обвинения."
		"handle_vardan":
			match stance:
				"released_for_hearing": return "Вардан освобождён до слушания. Он обязался явиться по вызову."
				"in_custody": return "Вардан остаётся под стражей до слушания о передаче печати."
				"inside_council": return "Вардан согласился дать показания, сохранив место и условия сделки."
			if state.facts.get("vardan_hearing") == "summons_issued":
				return "Вардану выписали вызов. Его явка пока не подтверждена."
			return "Суд сначала собирает свидетельства о ночных грамотах. Вардана ещё не вызвали."
		"separate_claims":
			if state.facts.get("court_petition_referred", false):
				return "Судьи приняли отдельное прошение о приказе из княжеского замка."
			return "Прежние платежи и ночные грамоты записаны как два разных дела."
	return "Совет не распорядился об уликах. Марек пока оставил протокол без вывода."
