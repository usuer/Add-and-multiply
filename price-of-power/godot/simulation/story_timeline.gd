class_name StoryTimeline
extends Resource

const DEFINITIONS: Dictionary = {
	"granary_roof": {
		"cycle": 2, "title": "Вода в старом амбаре", "location": "Княжеский амбар",
		"summary": "После ночного дождя смотритель обнаружил мокрые балки. Зерно пока цело, но следующая непогода может пройти сквозь кровлю.",
		"choices": {"repair": "Послать плотников немедленно", "inspect": "Сначала проверить смету и виновных", "relocate": "Перенести зерно по соседним складам"}
	},
	"dead_prince_order": {
		"cycle": 3, "title": "Приказ, подписанный после смерти", "location": "Городская стража",
		"summary": "Дарен Клин принёс приказ о переводе заключённого Саввы Лунина. На документе стоит печать вашего отца, однако приказ датирован утром после его смерти. Заключённый по дороге бежал; писец Савва Лунь, его старший брат, сегодня не вышел на службу.",
		"choices": {"quiet": "Тихо проверить канцелярию и семью Саввы", "public": "Объявить печать поддельной и начать открытый розыск", "guard": "Задержать стражников, исполнивших невозможный приказ"}
	},
	"smiths_dispute": {
		"cycle": 4, "title": "Кузнецы закрыли ворота", "location": "Ремесленный квартал",
		"summary": "Оружейный двор Ратибора остановился: восемьдесят мастеров и работников не получили жалованье. Борин показывает ведомость об оплате, но денег у людей нет. Злата Радич предлагает независимо сверить книги казны и мастерских.",
		"choices": {"mediate": "Поручить Злате сверить обе книги", "pay": "Выплатить людям спорную сумму сейчас", "seize": "Ввести стражу и забрать государственный заказ"}
	},
	"aglaia_letter": {
		"cycle": 5, "title": "Письмо в рукаве", "location": "Дом семи фонарей",
		"summary": "Стража задержала работницу Аглаи Лис. В её рукаве нашли письмо о зерновых обозах, подписанное словами «вторая рука». Аглая утверждает, что письмо девушке подбросил один из посетителей, и требует разговора без посторонних.",
		"choices": {"question": "Отдельно допросить девушку и Аглаю", "deal": "Дать Аглае ночь, чтобы найти владельца письма", "guard": "Передать письмо и задержанную Дарену"}
	},
	"market_speech": {
		"cycle": 7, "title": "Мирон на Рыночной площади", "location": "Городской рынок",
		"summary": "Бывший судья Мирон Светоч собрал горожан и требует объяснить, почему в книгах Долинной области было зерно, которого не оказалось в амбарах. Толпа пока слушает спокойно; он предлагает князю ответить публично.",
		"choices": {"listen": "Прийти без знаков власти и сначала выслушать", "answer": "Выйти к людям и рассказать, что уже известно", "disperse": "Приказать страже прекратить собрание"}
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
	"border_consequence": {
		"cycle": 8, "title": "Север отвечает делом", "location": "Пограничная канцелярия",
		"summary": "Прошло два периода после первого донесения. Ответ соседа и состояние дальних застав требуют нового решения.",
		"choices": {"inspect": "Лично выехать к заставам с малой охраной", "local_watch": "Вооружить местных старост и создать цепь сигнальных костров", "reopen_talks": "Отправить второго посланника с предложением взаимной проверки границы"}
	},
	"savva_at_chapel": {
		"cycle": 9, "title": "Савва просит один разговор", "location": "Заброшенная часовня",
		"summary": "Марек получил записку от пропавшего писца Саввы Луня. Тот обещает вернуть вторую печать и назвать человека, оплатившего побег его брата, если князь придёт без городской стражи. Радомир готов дать скрытое прикрытие; Дарен настаивает на немедленном аресте.",
		"choices": {"meet": "Прийти со скрытым прикрытием Радомира", "arrest": "Послать Дарена взять Савву живым", "safe_passage": "Дать Савве письменное обещание безопасного допроса"}
	},
	"fever_outbreak": {
		"cycle": 10, "title": "Горячка в нижнем городе", "location": "Речной квартал",
		"summary": "За три дня слегли семьи кожевников и двое лодочников. Причина неизвестна; слухи уже называют воду, чужеземцев и Божий гнев.",
		"choices": {"quarantine": "Перекрыть квартал и доставлять пищу внутрь", "clinics": "Открыть временные лечебницы", "conceal": "Не объявлять тревогу до точного диагноза"}
	},
	"family_warning": {
		"cycle": 11, "title": "Печать в детской", "location": "Семейные покои",
		"summary": "Элина нашла у девятилетнего Всеволода кусок воска с оттиском второй печати. Сын говорит, что его дал «старый друг деда» и попросил спрятать до игры в тайного посланника. Незнакомец сумел пройти во внутренний двор, не вызвав тревоги охраны.",
		"choices": {"evacuate": "Тайно вывезти детей в загородную обитель", "double_guard": "Оставить семью во дворце и сменить внутреннюю охрану", "bait": "Попросить Всеволода продолжить игру под наблюдением"}
	},
	"tikhon_pump": {
		"cycle": 12, "title": "Тихон и машина против горячки", "location": "Двор старой красильни",
		"summary": "Изобретатель Тихон Лучин собрал ручной насос, который может подавать чистую воду выше речных стоков. Машина гремит, течёт на соединениях и пока обслуживает один двор. Тихон просит не верить ему на слово, а дать людей для открытого испытания.",
		"choices": {"field_test": "Испытать насос в больном квартале", "workshop": "Дать Тихону мастерскую и месяц на доработку", "dismiss": "Отказать: во время горячки нужны лекари, а не опытная машина"}
	},
	"fathers_ledger": {
		"cycle": 13, "title": "Книга отцовских платежей", "location": "Личный архив князя",
		"summary": "За фальшивой стенкой найден счёт вашего отца. В нём — выплаты северным офицерам, городским старостам и человеку с пометкой «В. Речной». Эти деньги, вероятно, сорвали прошлую войну, но часть зерновых недостач началась именно здесь.",
		"choices": {"publish": "Открыть книгу совету и городским судьям", "inner_circle": "Показать только Элине, Мареку и Радомиру", "continue_scheme": "Сохранить тайну и использовать старые связи отца"}
	},
	"aglaia_invitation": {
		"cycle": 14, "title": "Закрытый вечер у Аглаи", "location": "Дом семи фонарей",
		"summary": "Аглая приглашает вас на закрытый вечер без советников и знаков власти. Среди гостей будет управляющий Вардана и двое северных купцов. Она прямо предупреждает: вы получите возможность слушать, но само появление женатого князя в её доме станет оружием, если о нём узнают.",
		"choices": {"attend": "Прийти тайно и самому слушать гостей", "agent": "Послать подготовленного человека вместо себя", "decline": "Отказаться от визита и уделить время семье"}
	},
	"vardan_offer": {
		"cycle": 15, "title": "Предложение Вардана", "location": "Старый речной причал",
		"summary": "Вардан Речной больше не скрывается. Он предлагает вернуть вторую печать и остановить северные поставки оружия в обмен на место в совете и неприкосновенность своих людей. Он утверждает, что служил вашему отцу и лишь продолжил то, за что прежний князь ему платил.",
		"choices": {"accept": "Принять сделку и впустить Вардана в совет", "counterfeit": "Согласиться для вида и подготовить задержание", "refuse": "Отказаться и объявить его врагом княжества"}
	},
	"divided_command": {
		"cycle": 16, "title": "Два командира — один приказ", "location": "Военный двор",
		"summary": "Радомир требует подчинить городскую стражу военному штабу до конца угрозы. Дарен отвечает, что солдаты не знают переулков и спровоцируют город. Оба согласны служить, но каждый считает другого опасным для столицы. Без ясной цепи командования следующий общий приказ они истолкуют по-разному.",
		"choices": {"radomir": "Передать общее командование Радомиру", "daren": "Оставить столицу Дарену, а войско — Радомиру", "joint": "Создать совместный штаб с обязательной двойной подписью"}
	},
	"night_of_second_seal": {
		"cycle": 17, "title": "Ночь второй печати", "location": "Столица и северные ворота",
		"summary": "Одновременно звонят колокола у речных складов и северных ворот. По поддельным приказам часть стражи оставила посты, а вооружённые люди Вардана выводят зерно к реке. За границей показались огни военного обоза. Это не случайный налёт: противник проверяет, кому в столице ещё подчиняются.",
		"choices": {"capital": "Удержать столицу и склады, оставив границу Радомиру", "border": "Возглавить войско у ворот, доверив город Дарену", "expose": "Обнародовать книгу и приказы, призвав горожан не подчиняться печати"}
	},
	"new_rule": {
		"cycle": 18, "title": "Первое утро после второй печати", "location": "Большой зал совета",
		"summary": "Бой закончился, но прежний порядок уже не вернётся. В зале ждут пленные люди Вардана, цеховые старшины, военные и семьи погибших. Все хотят услышать не только кого накажут, но и кто отныне сможет проверять княжеский приказ.",
		"choices": {"law": "Учредить открытый суд и реестр всех княжеских приказов", "mercy": "Предложить рядовым участникам амнистию за показания", "purge": "Провести закрытую чистку двора и служб безопасности"}
	}
}

@export var resolved: Dictionary = {}
@export var reports: Array[Dictionary] = []

func available_events(cycle: int) -> Array[String]:
	var result: Array[String] = []
	for event_id: String in DEFINITIONS:
		if opening_cycle(event_id) <= cycle and not resolved.has(event_id) and _is_unlocked(event_id):
			result.append(event_id)
	result.sort_custom(func(a: String, b: String) -> bool: return opening_cycle(a) < opening_cycle(b))
	return result

func opening_cycle(event_id: String) -> int:
	var first_cycle := int(DEFINITIONS[event_id]["cycle"])
	if event_id in ["scout_report", "border_consequence"]:
		var border: Dictionary = resolved.get("border_courier", {})
		return maxi(first_cycle, int(border.get("cycle", first_cycle)) + 2)
	return first_cycle

func _is_unlocked(event_id: String) -> bool:
	var border: Dictionary = resolved.get("border_courier", {})
	if event_id == "scout_report":
		return str(border.get("choice", "")) == "scouts"
	if event_id == "border_consequence":
		return str(border.get("choice", "")) in ["envoy", "dismiss"]
	if event_id == "new_rule":
		return resolved.has("night_of_second_seal")
	return true

func update(state: WorldState) -> void:
	_apply_delayed_results(state)
	_resolve_neglected_events(state)

func _apply_delayed_results(state: WorldState) -> void:
	if resolved.has("border_courier"):
		var record: Dictionary = resolved["border_courier"]
		if str(record.get("choice", "")) == "scouts" and not bool(record.get("followup_applied", false)) and state.calendar.cycle >= int(record.get("cycle", 0)) + 2:
			state.facts["northern_scouts_returned"] = true
			record["followup_applied"] = true
			resolved["border_courier"] = record
			state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "scouts_returned"})
			_add_report(state.calendar.cycle, "Дозор вернулся", "Разведчики принесли карту чужих лагерей. В военном зале ждут вашего решения.")
	if resolved.has("smiths_dispute"):
		var smiths: Dictionary = resolved["smiths_dispute"]
		if str(smiths.get("choice", "")) == "mediate" and not bool(smiths.get("followup_applied", false)) and state.calendar.cycle >= int(smiths.get("cycle", 0)) + 1:
			smiths["followup_applied"] = true
			resolved["smiths_dispute"] = smiths
			state.facts["missing_armory_payment"] = true
			var link_text := "Злата нашла перевод на несуществующий перевозочный двор. Получатель вписан после составления ведомости."
			if not str(state.facts.get("second_seal_investigation", "")).is_empty():
				link_text += " Марек сравнил росчерк с приказом об освобождении заключённого: оба исправления сделаны одной рукой."
			_add_report(state.calendar.cycle, "Злата закончила сверку счетов", link_text)
	if resolved.has("aglaia_letter"):
		var letter: Dictionary = resolved["aglaia_letter"]
		if not bool(letter.get("followup_applied", false)) and state.calendar.cycle >= int(letter.get("cycle", 0)) + 1:
			var choice := str(letter.get("choice", ""))
			if choice == "deal":
				state.facts["aglaia_grey_guest"] = true
				_add_report(state.calendar.cycle, "Аглая выполнила обещание", "До рассвета она прислала имя: письмо оставил приезжий, называвший себя торговцем шерстью. Он расспрашивал о дворцовых писцах и платил новыми северными монетами.")
			elif choice == "question":
				state.facts["aglaia_grey_guest"] = true
				_add_report(state.calendar.cycle, "Показания сошлись не полностью", "Работница и Аглая одинаково описали приезжего в сером плаще, но назвали разное время его ухода. Либо одна из них ошибается, либо Аглая скрывает вторую встречу.")
			elif choice == "guard":
				state.facts["aglaia_witness_silent"] = true
				_add_report(state.calendar.cycle, "Задержанная изменила показания", "После ночи в управлении стражи девушка заявила, что сама украла письмо у неизвестного клиента. Дарен считает признание достаточным; имя посетителя так и не появилось в деле.")
			letter["followup_applied"] = true
			resolved["aglaia_letter"] = letter

func _resolve_neglected_events(state: WorldState) -> void:
	for event_id: String in DEFINITIONS:
		if resolved.has(event_id) or not _is_unlocked(event_id):
			continue
		if not state.calendar.is_demo_complete() and state.calendar.cycle < opening_cycle(event_id) + 2:
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

func resolved_history(limit: int = 6) -> Array[Dictionary]:
	var history: Array[Dictionary] = []
	for event_id: String in resolved:
		if not DEFINITIONS.has(event_id):
			continue
		var record: Dictionary = resolved[event_id]
		var event: Dictionary = DEFINITIONS[event_id]
		var choice_id := str(record.get("choice", ""))
		var choice_title := "Оставлено без ответа" if choice_id == "neglected" else str((event.get("choices", {}) as Dictionary).get(choice_id, choice_id))
		history.append({
			"event_id": event_id,
			"cycle": int(record.get("cycle", 0)),
			"title": str(event.get("title", event_id)),
			"choice": choice_title,
			"outcome": str(record.get("outcome", ""))
		})
	history.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["cycle"]) > int(b["cycle"]))
	if limit > 0 and history.size() > limit:
		history.resize(limit)
	return history

func _neglect_consequence(state: WorldState, event_id: String) -> String:
	match event_id:
		"granary_roof":
			state.resources["grain"] = maxi(0, int(state.resources.get("grain", 0)) - 12)
			state.facts["granary_roof"] = "collapsed"
			return "После нового ливня часть кровли рухнула. Намокшее зерно пришлось выбросить."
		"dead_prince_order":
			state.facts["second_seal_investigation"] = "trail_cold"
			return "Пока двор не отвечал, семья Саввы исчезла из дома. В печи канцелярии нашли обгоревшие черновики приказов, но самого писца уже никто не видел."
		"smiths_dispute":
			state.resources["tools"] = maxi(0, int(state.resources.get("tools", 0)) - 2)
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, -5, "Княжеский двор две недели не отвечал на остановку кузниц.")
			return "Спор оставался без ответа, и кузнецы разошлись по частным заказам."
		"aglaia_letter":
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "ignored_arrest", "Княжеский двор оставил её работницу в руках стражи и не выслушал объяснение.", {"trust": -4, "resentment": 4})
			state.facts["aglaia_letter"] = "lost"
			return "Задержанную перевели в городскую тюрьму. Через два дня письмо исчезло из описи, а девушка отказалась от прежних показаний."
		"market_speech":
			(state.characters["miron"] as CharacterState).remember(state.calendar.cycle, "ignored_speech", "Князь не ответил на публичный вопрос о пропавшем зерне.", {"respect": -2, "grievance": 3})
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, -2, "Вопрос Мирона о зерновых книгах остался без ответа двора.")
			return "Не получив ответа, Мирон повторил свои вопросы через неделю. На этот раз слушателей пришло вдвое больше."
		"savva_at_chapel":
			state.facts["savva_fate"] = "vanished"
			(state.characters["savva"] as CharacterState).remember(state.calendar.cycle, "abandoned_contact", "Князь не ответил на последнюю просьбу о разговоре.", {"trust": -8, "grievance": 5})
			return "У часовни нашли погасший костёр и кровь на камне, но не тело. Через день второй печатью заверили продажу княжеской земли на севере."
		"border_courier":
			(state.factions["military"] as FactionState).react(state.calendar.cycle, -3, "Пограничное донесение пролежало без приказа.")
			return "Пока донесение ждало решения, неизвестные всадники ушли с собранными сведениями."
		"border_consequence":
			state.facts["northern_posture"] = "unprepared"
			(state.factions["military"] as FactionState).react(state.calendar.cycle, -4, "Повторное сообщение с границы снова осталось без решения.")
			return "Пограничники оставили дальние посты и стянулись к ближайшей крепости. Северная дорога теперь никем не наблюдается."
		"fever_outbreak":
			state.public_health = maxi(0, state.public_health - 14)
			state.facts["fever_policy"] = "neglected"
			return "Пока совет ждал приказа, горячка вышла из речного квартала и добралась до городских казарм."
		"family_warning":
			state.facts["family_security"] = "breached"
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "children_left_exposed", "После находки в детской вы не изменили охрану семьи.", {"trust": -7, "resentment": 4})
			return "Элина сама увезла детей из столицы и отказалась сообщить маршрут дворцовой канцелярии. Во внутренних покоях она больше не доверяет вашей охране."
		"tikhon_pump":
			(state.characters["tikhon"] as CharacterState).remember(state.calendar.cycle, "proposal_ignored", "Княжеский двор не ответил на предложение испытать насос во время горячки.", {"trust": -3, "respect": -2})
			return "Тихон разобрал насос, чтобы расплатиться с помощниками. Один кожевник выкупил трубы для своей мастерской; проверить устройство теперь невозможно."
		"fathers_ledger":
			state.facts["fathers_ledger"] = "stolen_page"
			return "До решения из книги вырвали страницу с последними выплатами. Доступ к архиву имели трое слуг и члены княжеской семьи."
		"aglaia_invitation":
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "invitation_ignored", "Вы оставили личное приглашение без ответа.", {"respect": -2})
			return "Вечер прошёл без людей князя. Утром управляющий Вардана покинул город вместе с северными купцами; о содержании разговора двор знает только по слухам."
		"vardan_offer":
			state.facts["vardan_stance"] = "unanswered"
			(state.characters["vardan"] as CharacterState).remember(state.calendar.cycle, "offer_ignored", "Князь не ответил на предложение и оставил ему свободу действовать первым.", {"respect": -3})
			return "Не получив ответа, Вардан исчез с причала. В ту же ночь с речного склада вывезли оружие по приказу со второй печатью."
		"divided_command":
			state.facts["command_structure"] = "unclear"
			return "Спор закончился без решения. Радомир усилил ворота, Дарен — дворец; городские склады остались между двумя зонами ответственности."
		"night_of_second_seal":
			state.facts["second_seal_crisis"] = "command_collapsed"
			state.public_order = maxi(0, state.public_order - 18)
			return "Противоречивые приказы парализовали гарнизон. Люди Вардана ушли с зерном, а северный отряд занял переправу без большого боя."
		"new_rule":
			state.facts["new_rule"] = "old_order_survived"
			return "Совет разошёлся без нового порядка. Печать заменили, но право проверять княжеский приказ так и осталось неясным."
	return "Дело слишком долго оставалось без решения, и обстоятельства решили его за вас."

func definition(event_id: String) -> Dictionary:
	return DEFINITIONS.get(event_id, {})

func contextual_definition(state: WorldState, event_id: String) -> Dictionary:
	var event: Dictionary = definition(event_id).duplicate(true)
	if event_id == "border_consequence":
		var first_choice := str((resolved.get("border_courier", {}) as Dictionary).get("choice", ""))
		if first_choice == "envoy":
			event["title"] = "Северный ответ без ответа"
			event["summary"] = "Сосед вернул вашу грамоту с учтивой припиской: всадники якобы ловили конокрадов. Однако посланник заметил свежие колеи тяжёлых телег и новые склады у дороги. Официальное объяснение не совпадает с увиденным."
		elif first_choice == "dismiss":
			event["title"] = "Застава, которой не поверили"
			event["summary"] = "Гонец вернулся: ночью неизвестные разоружили дальнюю заставу, забрали списки караулов и ушли без знамён. Погибших нет, но пограничники уверены, что столица снова сочтёт их слова выдумкой."
	if event_id == "savva_at_chapel":
		var clues: Array[String] = []
		if bool(state.facts.get("missing_armory_payment", false)):
			clues.append("исправление в оружейной ведомости")
		if bool(state.facts.get("aglaia_grey_guest", false)):
			clues.append("северные монеты приезжего Аглаи")
		if not clues.is_empty():
			event["summary"] = str(event["summary"]) + " С его запиской совпадает %s." % " и ".join(clues)
		if bool(state.facts.get("marek_copy_saved", false)):
			event["summary"] += " У Марека есть копия книги приказов. Даже если сумка Саввы пропадёт, подлинные распоряжения будет с чем сверить."
	if event_id == "market_speech":
		match str(state.facts.get("lowland_register", "")):
			"open": event["summary"] += " Мирон держит в руках копию сверки, которую Лада вывесила на площади. Он требует назвать владельцев амбаров, чьи записи расходятся с выдачами."
			"sealed": event["summary"] += " Марек принёс сверку Лады. По ней можно назвать размер недостачи, сохранив имена деревенских свидетелей в тайне."
	if event_id == "family_warning" and str(state.facts.get("second_seal_investigation", "")) == "public":
		event["summary"] = str(event["summary"]) + " Это произошло несмотря на объявленный по всему городу розыск печати."
	if event_id == "tikhon_pump":
		match str(state.facts.get("fever_policy", "")):
			"clinics": event["summary"] = str(event["summary"]) + " Лекари из временных лечебниц согласны записывать результаты испытания."
			"quarantine": event["summary"] = str(event["summary"]) + " Для испытания придётся пропустить его помощников через оцепление."
			"concealed": event["summary"] = str(event["summary"]) + " Тихон вслух называет квартал больным, хотя двор официально не объявлял о горячке."
		if bool(state.facts.get("tikhon_trial_prepared", false)):
			event["summary"] += " После разговора в школе лекари приготовили посуду для проб, а Тихон отметил место для забора воды выше по реке."
	if event_id == "aglaia_invitation" and (state.characters["aglaia"] as CharacterState).trust < 0:
		event["summary"] = str(event["summary"]) + " После истории с задержанной работницей нет уверенности, что она предупреждает вас из доброй воли."
	if event_id == "vardan_offer":
		if str(state.facts.get("savva_fate", "")) in ["protected_witness", "voluntary_witness"]:
			event["summary"] = str(event["summary"]) + " Савва готов опровергнуть его слова, но только если вы гарантируете защиту его брату."
		if str(state.facts.get("fathers_ledger", "")) == "published":
			event["summary"] = str(event["summary"]) + " После публикации книги Вардан уже потерял часть покровителей."
		if bool(state.facts.get("second_seal_order_proof", false)):
			event["summary"] += " Список поддельных приказов Марек сверил со своей копией. Его выводы можно показать судьям, даже если Савва откажется повторить показания."
	if event_id == "night_of_second_seal":
		if str(state.facts.get("vardan_stance", "")) == "inside_council":
			event["summary"] = "Колокола звонят у речных складов и северных ворот. Вардан принёс возвращённую печать в совет: новые приказы разослали его бывшие люди, которые отказались подчиниться сделке. Часть стражи уже снялась с постов. За границей показались огни военного обоза."
		var posture := str(state.facts.get("northern_posture", "unprepared"))
		if posture == "fortified":
			event["summary"] = str(event["summary"]) + " Укреплённые переправы задержат чужой обоз, но гарнизоны ждут команды."
		elif posture == "ambush":
			event["summary"] = str(event["summary"]) + " Засада у переправы ещё не раскрыта, и Радомир просит не выдавать её преждевременно."
		match str(state.facts.get("command_structure", "")):
			"joint": event["summary"] = str(event["summary"]) + " Совместный штаб уже сверяет спорные приказы двумя подписями."
			"split": event["summary"] = str(event["summary"]) + " Заранее разделённые зоны ответственности позволяют обоим командирам действовать без нового совещания."
			"unclear": event["summary"] = str(event["summary"]) + " Радомир и Дарен уже прислали противоречащие друг другу требования."
		if bool(state.facts.get("radomir_handover_ready", false)):
			event["summary"] += " Связные, которых заранее подготовил Радомир, уже носят донесения между воротами и складами."
		if bool(state.facts.get("miron_public_witnesses", false)):
			event["summary"] += " Двое цеховых старшин ждут Мирона на площади. Они готовы при всех сравнить подлинные бумаги с приказами, которые принесли ночью."
		if bool(state.facts.get("second_seal_order_proof", false)):
			event["summary"] += " Марек принёс проверенные записи из книги приказов. Ими можно подтвердить подлог, не раскрывая, где находится Савва."
		match str(state.facts.get("market_watch", "")):
			"neighbors": event["summary"] += " Лавочники с рынка узнали одного из возчиков, приехавших за зерном по ночной грамоте. Они готовы повторить это перед глашатаем."
			"inspectors": event["summary"] += " Вечерняя смена Дарена уже стоит у выезда с рынка и знает, как отправить задержанный груз обратно к складам."
	if event_id == "new_rule":
		match str(state.facts.get("second_seal_crisis", "")):
			"capital_held": event["summary"] = str(event["summary"]) + " Семьи с оставленного севера требуют ответить, почему столицу спасли за их счёт."
			"border_held": event["summary"] = str(event["summary"]) + " Владельцы сгоревших складов требуют возмещения за победу на границе."
			"false_orders_rejected": event["summary"] = str(event["summary"]) + " Цехи, отказавшиеся выполнять ложные приказы, требуют закрепить своё право на проверку власти."
			"command_collapsed": event["summary"] = "К утру гарнизон снова выполняет приказы из замка, но склады разграблены, а северная переправа потеряна. Совет требует решить, кто отныне сможет проверять княжеские распоряжения."
	return event

func can_choose(state: WorldState, event_id: String, choice_id: String) -> bool:
	if state.calendar.is_demo_complete() or not state.can_govern() or event_id not in available_events(state.calendar.cycle):
		return false
	if not (definition(event_id).get("choices", {}) as Dictionary).has(choice_id):
		return false
	var required_gold := 0
	if event_id == "granary_roof" and choice_id == "repair": required_gold = 5
	if event_id == "smiths_dispute" and choice_id == "pay": required_gold = 8
	if event_id == "scout_report" and choice_id == "fortify": required_gold = 12
	if event_id == "fever_outbreak" and choice_id == "quarantine": required_gold = 6
	if event_id == "fever_outbreak" and choice_id == "clinics": required_gold = 10
	if event_id == "fathers_ledger" and choice_id == "continue_scheme": required_gold = 6
	if event_id == "tikhon_pump" and choice_id == "field_test": required_gold = 3
	if event_id == "tikhon_pump" and choice_id == "workshop": required_gold = 8
	return state.state_treasury >= required_gold

func choose(state: WorldState, event_id: String, choice_id: String) -> bool:
	if not can_choose(state, event_id, choice_id):
		return false
	var outcome := _apply_choice(state, event_id, choice_id)
	if event_id == "savva_at_chapel" and bool(state.facts.get("marek_copy_saved", false)):
		state.facts["second_seal_order_proof"] = true
		outcome += " Марек сверил показания Саввы со своей копией книги и нашёл номера двух приказов, которых канцелярия не выдавала. Свидетельство можно проверить и без печати."
	state.add_fatigue(4)
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
		"dead_prince_order:quiet":
			state.facts["second_seal_investigation"] = "quiet"
			state.facts["savva_family_watched"] = true
			return "Дарен оставил двух людей наблюдать за домом Саввы, а Марек поднял списки тех, кто имел доступ к кабинету старого князя. О пропавшей печати в городе пока не знают."
		"dead_prince_order:public":
			state.facts["second_seal_investigation"] = "public"
			(state.factions["nobility"] as FactionState).react(state.calendar.cycle, -2, "Двор узнал, что от имени умершего князя продолжают выходить приказы.")
			return "На воротах вывесили описание Саввы и предупреждение о поддельной печати. Теперь старые приказы будут проверять внимательнее — и тот, у кого находится печать, тоже знает о розыске."
		"dead_prince_order:guard":
			state.facts["second_seal_investigation"] = "guard_detained"
			state.public_order = maxi(0, state.public_order - 2)
			return "Троих стражников заперли до допроса. Они настаивают, что исполнили безупречный документ; остальные караулы теперь требуют письменного подтверждения даже обычных распоряжений."
		"smiths_dispute:mediate":
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, 3, "Князь лично выслушал спор ремесленников с казной.")
			(state.characters["zlata"] as CharacterState).remember(state.calendar.cycle, "first_commission", "Вы доверили ей независимо сверить счета оружейного двора и казны.", {"respect": 4, "trust": 2})
			state.facts["zlata_met"] = true
			state.facts["smith_payment_audit"] = true
			return "Злата согласилась проверить обе книги при представителях работников. Она сразу нашла странность: казна отмечает выплату на два дня раньше, чем Ратибор выставил окончательный счёт."
		"smiths_dispute:pay":
			state.state_treasury -= 8
			state.resources["tools"] = int(state.resources.get("tools", 0)) + 4
			(state.characters["zlata"] as CharacterState).remember(state.calendar.cycle, "workmen_paid", "Вы предпочли немедленно заплатить работникам, не дожидаясь спора чиновников.", {"respect": 2})
			state.facts["zlata_met"] = true
			return "Людям выдали жалованье, и горны снова зажгли. Злата предупреждает: повторная выплата спасла заказ, но не ответила, куда ушли первые деньги."
		"smiths_dispute:seize":
			state.resources["tools"] = int(state.resources.get("tools", 0)) + 5
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, -8, "Княжеская стража изъяла товар из кузниц во время спора об оплате.")
			(state.characters["zlata"] as CharacterState).remember(state.calendar.cycle, "workshop_seizure", "Вы забрали заказ силой, пока рабочие требовали жалованье.", {"trust": -5, "resentment": 6})
			state.facts["zlata_met"] = true
			return "Стража забрала заказ без драки. К вечеру погасли почти все горны, а Злата начала собирать владельцев мастерских на отдельное совещание."
		"aglaia_letter:question":
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "first_audience", "Вы выслушали её и задержанную раздельно, не обещая освобождения.", {"respect": 3})
			state.facts["aglaia_met"] = true
			state.facts["aglaia_letter"] = "statements_compared"
			return "Девушка сказала, что письмо сунул ей в рукав пьяный посетитель, когда в зал вошла стража. Аглая назвала его приметы, но отказалась назвать постоянного клиента, который может их подтвердить."
		"aglaia_letter:deal":
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "private_deal", "Вы дали ей одну ночь самой найти человека, оставив свободу её работнице.", {"trust": 4, "respect": 2})
			state.facts["aglaia_met"] = true
			state.facts["aglaia_letter"] = "aglaia_searching"
			return "Аглая забрала девушку и пообещала имя до рассвета. Дарен считает, что вы отпустили единственного свидетеля; Аглая теперь обязана вам ответом."
		"aglaia_letter:guard":
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "letter_case", "Вы передали ему письмо и полную власть вести допрос.", {"trust": 3, "respect": 2})
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "worker_imprisoned", "Вы отказались разговаривать и оставили её работницу у стражи.", {"trust": -4, "resentment": 4})
			state.facts["aglaia_met"] = true
			state.facts["aglaia_letter"] = "with_guard"
			return "Дарен увёз письмо и задержанную в управление стражи. Аглая ушла без спора, но до вечера трое её постоянных гостей отменили встречи с дворцовыми чиновниками."
		"market_speech:listen":
			(state.characters["miron"] as CharacterState).remember(state.calendar.cycle, "market_listener", "Неизвестный ему человек выслушал речь до конца и не попытался её сорвать.", {"respect": 2})
			state.facts["miron_met_in_disguise"] = true
			return "Без княжеских знаков вы услышали не только Мирона, но и ответы толпы. Людей злит не сама нехватка зерна, а то, что никто не назвал виновного. Мирон пока не показал, узнал ли вас."
		"market_speech:answer":
			(state.characters["miron"] as CharacterState).remember(state.calendar.cycle, "public_answer", "Вы пришли на площадь и ответили перед толпой, не приказывая ему замолчать.", {"respect": 5, "trust": 2})
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, 3, "Князь лично ответил на вопросы о пропавшем зерне.")
			state.facts["miron_public_debate"] = true
			match str(state.facts.get("lowland_register", "")):
				"open":
					return "Мирон прочитал расхождение вслух. Староста уже не мог спорить, сколько зерна дошло до деревень. Когда Мирон потребовал назвать всех, кто давал показания, Лада попросила оставить эти имена суду."
				"sealed":
					return "Вы назвали размер недостачи по сверке Лады. Мирон попросил показать подписи. Марек предъявил итоговый лист, оставив имена свидетелей закрытыми. Площадь разошлась, но Мирон пообещал вернуться к вопросу после суда."
			return "Вы рассказали о проверке книг и приказе с печатью умершего князя. Мирон признал ответ, но спросил, почему двор сообщил об этом только после публичного требования."
		"market_speech:disperse":
			(state.characters["miron"] as CharacterState).remember(state.calendar.cycle, "speech_dispersed", "Вы разогнали мирное собрание вместо ответа.", {"trust": -7, "resentment": 8, "grievance": 8})
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, -7, "Стража разогнала людей, требовавших объяснить недостачу зерна.")
			state.public_order = maxi(0, state.public_order - 3)
			state.facts["miron_speech_dispersed"] = true
			return "Стража очистила площадь без серьёзной драки. Мирон ушёл сам, прежде чем его схватили; к вечеру по городу разошёлся список вопросов, на которые князь не ответил."
		"border_courier:scouts":
			state.facts["northern_scouts_sent"] = true
			return "Дозор ушёл налегке и вернётся с ответом позже. Капитан просит пока не распускать слухи в городе."
		"border_courier:envoy":
			state.facts["northern_envoy_sent"] = true
			return "Посольская грамота отправлена. Теперь сосед знает, что всадников заметили, но ещё не знает, насколько вы встревожены."
		"border_courier:dismiss":
			(state.factions["military"] as FactionState).react(state.calendar.cycle, -4, "Сообщение пограничного гонца оставили без проверки.")
			return "Гонца отпустили обратно. Он поклонился по уставу, но у ворот рассказал часовым, что в столице ему не поверили."
		"border_consequence:inspect":
			state.facts["northern_posture"] = "personally_inspected"
			(state.characters["radomir"] as CharacterState).remember(state.calendar.cycle, "frontier_ride", "Вы сами выехали проверить слова пограничников вместо нового спора в совете.", {"respect": 4})
			return "На месте вы увидели пустые кострища на двести человек и следы телег к северу. Пограничники снова заняли посты: теперь их донесение подтверждено вашим собственным словом."
		"border_consequence:local_watch":
			state.facts["northern_posture"] = "local_watch"
			(state.factions["rural"] as FactionState).react(state.calendar.cycle, 2, "Пограничным старостам доверили защищать дороги и подавать сигнал столице.")
			return "Старостам выдали луки, трубы и порядок сигнальных огней. Это дёшево и быстро, но оружие останется в деревнях даже после окончания угрозы."
		"border_consequence:reopen_talks":
			state.facts["northern_posture"] = "mutual_inspection_offered"
			return "Вторая грамота предлагает обеим сторонам одновременно показать приграничные склады. Честный сосед согласится; готовящий нападение должен будет отказаться или выиграть время ложным показом."
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
		"savva_at_chapel:meet":
			state.facts["savva_fate"] = "protected_witness"
			state.facts["second_seal_holder"] = "vardan"
			(state.characters["savva"] as CharacterState).remember(state.calendar.cycle, "chapel_meeting", "Вы пришли выслушать его и не отдали городской страже.", {"trust": 8, "respect": 3})
			(state.characters["radomir"] as CharacterState).remember(state.calendar.cycle, "hidden_cover", "Вы доверили ему незаметно прикрыть опасную встречу.", {"trust": 3})
			return "Савва признался: печать он взял, чтобы освободить брата, но побег оплатил Вардан Речной. Когда Савва попытался вернуть печать, она уже была у людей Вардана. Стрела из темноты ранила Савву; люди Радомира вынесли его живым."
		"savva_at_chapel:arrest":
			state.facts["savva_fate"] = "in_guard_custody"
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "chapel_arrest", "Вы поручили ему взять похитителя печати живым.", {"trust": 4, "respect": 2})
			(state.characters["savva"] as CharacterState).remember(state.calendar.cycle, "chapel_arrest", "Вместо разговора вы прислали стражу.", {"trust": -8, "resentment": 5})
			return "Дарен взял Савву без боя, но неизвестный стрелок убил одного стражника и унёс сумку писца. На допросе Савва назвал Вардана Речного, однако доказательство осталось в украденной сумке."
		"savva_at_chapel:safe_passage":
			state.facts["savva_fate"] = "voluntary_witness"
			state.facts["second_seal_holder"] = "vardan"
			(state.characters["savva"] as CharacterState).remember(state.calendar.cycle, "safe_passage", "Вы дали ему возможность явиться самому и отвечать без пытки.", {"trust": 10, "respect": 5})
			return "Савва пришёл во дворец через кухонные ворота и отдал список поддельных приказов. Печать у Вардана Речного; тот купил побег брата, чтобы заставить Савву изготовить ещё два документа."
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
		"family_warning:evacuate":
			state.facts["family_security"] = "country_cloister"
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "children_evacuated", "Вы поставили безопасность детей выше видимости спокойствия во дворце.", {"trust": 4, "affection": 2})
			return "Элина уехала с детьми под видом паломничества. Во дворце никто не знает точного места, но отсутствие наследника скоро заметят послы и знать."
		"family_warning:double_guard":
			state.facts["family_security"] = "new_guard"
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "palace_guard_replaced", "Вы потребовали заменить его людей во внутренних покоях после провала охраны.", {"respect": -2, "resentment": 3})
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "family_guarded", "Вы оставили семью рядом, но полностью сменили внутреннюю охрану.", {"trust": 2})
			return "Ночную смену разоружили прямо во дворе. У одного стражника нашли серебро северной чеканки; он клянётся, что получил его за карточный долг."
		"family_warning:bait":
			state.facts["family_security"] = "child_bait"
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "son_used_as_bait", "Вы сознательно оставили сына приманкой для человека, проникшего во дворец.", {"trust": -10, "affection": -5, "resentment": 7})
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "nursery_trap", "Вы позволили ему устроить ловушку во внутренних покоях.", {"trust": 3})
			return "Всеволоду велели вести себя как обычно. Ночью за восковой фигуркой пришла дворцовая прачка; при задержании она назвала имя Вардана и попросила защитить её сына. Элина не простила способ, которым добыто признание."
		"tikhon_pump:field_test":
			state.state_treasury -= 3
			state.facts["tikhon_pump"] = "field_tested"
			var inventor := state.characters["tikhon"] as CharacterState
			var prepared := bool(state.facts.get("tikhon_trial_prepared", false))
			var reluctant := inventor.trust < 0
			var health_gain := 1 if reluctant else 3
			if prepared:
				health_gain = 5
			state.public_health = mini(100, state.public_health + health_gain)
			inventor.remember(state.calendar.cycle, "first_trial", "Вы дали ему людей и позволили проверить несовершенную машину там, где она нужна.", {"trust": 5, "respect": 4})
			if prepared:
				return "Когда насос заклинило, лекари остановили подачу и проверили оба ведра, как договорились в школе. Тихон исправил забор воды до открытия бака, и к вечеру чистой воды хватило и на соседний двор."
			if reluctant:
				return "Тихон привёз насос по приказу, но не стал спорить, когда помощники поставили забор слишком низко. Лекари вовремя заметили грязь. Насос переставили, однако большую часть дня вода так и не поступала."
			return "За первый день насос дважды заклинило, зато вода в верхнем баке осталась чистой. Тихон сам признал поломки и предложил заменить кожаные клапаны; лекари просят продолжить наблюдение."
		"tikhon_pump:workshop":
			state.state_treasury -= 8
			state.facts["tikhon_pump"] = "workshop_funded"
			(state.characters["tikhon"] as CharacterState).remember(state.calendar.cycle, "own_workshop", "Вы дали ему мастерскую и время исправить машину до публичного испытания.", {"trust": 7, "respect": 5})
			return "Тихон получил пустую литейную и троих подмастерьев. Немедленной пользы кварталу не будет, но впервые его работа зависит не от случайного покровителя, а от измеримого результата."
		"tikhon_pump:dismiss":
			state.facts["tikhon_pump"] = "dismissed"
			(state.characters["tikhon"] as CharacterState).remember(state.calendar.cycle, "machine_dismissed", "Вы отказались испытывать его насос и велели полагаться на лекарей.", {"trust": -5, "respect": -3, "resentment": 3})
			return "Тихон не спорил и попросил лишь вернуть чертежи. Лекари получили двор и помощников без конкурирующего опыта; насос остался непроверенной идеей."
		"fathers_ledger:publish":
			state.facts["fathers_ledger"] = "published"
			(state.characters["miron"] as CharacterState).remember(state.calendar.cycle, "ledger_disclosed", "Вы добровольно открыли суду доказательства тайных сделок собственной семьи.", {"respect": 8, "trust": 5})
			(state.factions["nobility"] as FactionState).react(state.calendar.cycle, -7, "Князь открыл суду тайные платежи прежнего правителя и влиятельных домов.")
			return "Судьи сняли копии книги. Мирон публично признал, что вы не спрятали вину отца; знать требует закрыть разбирательство ради безопасности государства."
		"fathers_ledger:inner_circle":
			state.facts["fathers_ledger"] = "inner_circle"
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "ledger_confidence", "Вы доверили ей опасную правду о наследии отца.", {"trust": 5})
			(state.characters["radomir"] as CharacterState).remember(state.calendar.cycle, "ledger_confidence", "Вы включили его в узкий круг, решающий судьбу старой сети.", {"trust": 4})
			return "Марек составил список живых получателей. Элина заметила, что три выплаты совпадают с поездками Вардана, а Радомир узнал имя северного офицера, которого встречал на прошлой войне."
		"fathers_ledger:continue_scheme":
			state.facts["fathers_ledger"] = "network_reactivated"
			state.state_treasury = maxi(0, state.state_treasury - 6)
			(state.characters["borin"] as CharacterState).remember(state.calendar.cycle, "secret_fund", "Вы поручили ему возобновить скрытые выплаты из старой книги.", {"trust": 5, "respect": 3})
			return "Борин отправил первые шесть монет старым путём. Один адресат ответил условной фразой отца: сеть ещё жива, но теперь её участники знают, что вы приняли правила прежнего князя."
		"aglaia_invitation:attend":
			state.facts["aglaia_evening"] = "attended"
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "private_evening", "Вы приняли риск и пришли лично слушать людей Вардана.", {"trust": 5, "affection": 3})
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "night_absence", "Вы солгали об отсутствии и провели закрытый вечер в доме Аглаи.", {"trust": -5, "resentment": 3})
			return "За игрой в кости управляющий Вардана проговорился: северный обоз ждёт сигнала из столицы, а не наоборот. Аглая отвела вас через задний двор. Утром Элина спросила, почему ваша дорожная обувь пахнет благовониями Семи фонарей."
		"aglaia_invitation:agent":
			state.facts["aglaia_evening"] = "agent_sent"
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "agent_received", "Вы не пришли сами, но доверили ей принять вашего наблюдателя.", {"respect": 3})
			return "Человек Марека услышал условную фразу о колоколах и речных складах, но северные купцы заметили его вопросы. Сведения получены; Вардан, вероятно, знает о слежке."
		"aglaia_invitation:decline":
			state.facts["aglaia_evening"] = "family_evening"
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "invitation_declined", "Вы прямо отказались от личного визита, не пытаясь использовать её дом.", {"respect": 2})
			if str(state.facts.get("family_security", "")) in ["country_cloister", "breached"]:
				(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "letter_to_family", "Вместо визита к Аглае вы написали ей и детям.", {"trust": 2})
				return "Вы отказались от вечера и написали Элине и детям. Письмо оставили у сестры: ей известен безопасный путь передачи. Люди Вардана тем временем закончили встречу без ваших свидетелей."
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "family_evening", "В опасный вечер вы остались с ней и детьми, не превращая семью в остаток свободного времени.", {"trust": 4, "affection": 4})
			return "Вы впервые за несколько недель ужинали с детьми без раскрытых донесений на столе. Политические сведения потеряны, зато Элина сама рассказала о слуге, который расспрашивал Всеволода о распорядке охраны."
		"vardan_offer:accept":
			state.facts["vardan_stance"] = "inside_council"
			(state.characters["vardan"] as CharacterState).remember(state.calendar.cycle, "council_bargain", "Вы признали его силу и дали место у власти вместо суда.", {"respect": 8, "trust": 3})
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "vardan_accepted", "Вы впустили в совет человека, чьи люди проникли к детям.", {"trust": -7, "resentment": 5})
			return "Вардан вернул печать при свидетелях и занял кресло советника по речной торговле. Его люди прекратили вывоз зерна, но уже к вечеру к нему потянулись просители, прежде ожидавшие княжеской аудиенции."
		"vardan_offer:counterfeit":
			state.facts["vardan_stance"] = "false_bargain"
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "vardan_trap", "Вы доверили ему тайную подготовку задержания Вардана.", {"trust": 4})
			(state.characters["vardan"] as CharacterState).remember(state.calendar.cycle, "false_bargain", "Вы согласились на сделку, намереваясь арестовать его после передачи печати.", {"grievance": 8})
			return "Вардан принял согласие слишком спокойно и назначил обмен через два дня. Дарен готовит людей, но предупреждает: если Вардан ждёт обмана, место встречи станет ловушкой для обеих сторон."
		"vardan_offer:refuse":
			state.facts["vardan_stance"] = "open_enemy"
			(state.characters["vardan"] as CharacterState).remember(state.calendar.cycle, "declared_enemy", "Вы отвергли сделку и публично назвали его врагом княжества.", {"resentment": 10, "grievance": 10})
			(state.characters["miron"] as CharacterState).remember(state.calendar.cycle, "vardan_refused", "Вы отказались узаконить власть Вардана ценой прекращения кризиса.", {"respect": 3})
			return "Объявление зачитали на площадях и у ворот. Вардан лишился возможности действовать открыто, зато теперь его людям нечего терять."
		"divided_command:radomir":
			state.facts["command_structure"] = "military"
			(state.characters["radomir"] as CharacterState).remember(state.calendar.cycle, "supreme_command", "Вы подчинили ему и войско, и городскую стражу на время угрозы.", {"trust": 5, "respect": 4})
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "command_removed", "Вы передали его стражу военному командиру, не знающему городских связей.", {"trust": -5, "resentment": 5})
			return "Радомир установил единый пароль и цепь приказов. Дарен подчинился перед строем, затем предупредил: его люди выполнят приказ, но перестанут делиться с военными негласными сведениями города."
		"divided_command:daren":
			state.facts["command_structure"] = "split"
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "capital_command", "Вы сохранили за ним самостоятельное командование городской стражей.", {"trust": 4, "respect": 3})
			(state.characters["radomir"] as CharacterState).remember(state.calendar.cycle, "split_command", "Вы оставили ему войско и границу, но не дали власти над столицей.", {"respect": 2})
			return "Карту разделили по городской стене: Дарен отвечает внутри, Радомир — снаружи. Это быстрее совместного штаба, но любой удар сразу по обе стороны потребует вашего личного решения."
		"divided_command:joint":
			state.facts["command_structure"] = "joint"
			(state.characters["radomir"] as CharacterState).remember(state.calendar.cycle, "joint_staff", "Вы заставили его сверять общие приказы с городской стражей.", {"respect": 2})
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "joint_staff", "Вы дали ему равную подпись в совместном штабе.", {"respect": 3, "trust": 2})
			return "Оба поставили подписи под первым общим приказом и назначили связных. Решения станут медленнее, зато подделать распоряжение одной печатью теперь недостаточно."
		"night_of_second_seal:capital":
			state.facts["second_seal_crisis"] = "capital_held"
			state.public_order = mini(100, state.public_order + 4)
			(state.characters["radomir"] as CharacterState).remember(state.calendar.cycle, "border_command", "Вы доверили ему самостоятельно удержать северную границу, пока спасали столицу.", {"trust": 6, "respect": 4})
			if bool(state.facts.get("radomir_handover_ready", false)):
				return "К рассвету склады отбиты. Связные Радомира вовремя предупредили дальнюю переправу: люди отвели обоз под прикрытие гарнизона до отхода с берега. Столицу удержали, обоз уцелел, но переправа осталась за северянами."
			if state.facts.get("market_watch") == "inspectors":
				return "Вечерняя смена Дарена остановила первые телеги у рынка и вернула зерно под охрану. Радомир удержал северные ворота, но отступил от дальней переправы и оставил там часть обоза."
			return "К рассвету склады отбиты, а поддельные приказы собраны. Радомир удержал ворота, но отступил от дальней переправы и потерял часть обоза: столицу спасли ценой земли на севере."
		"night_of_second_seal:border":
			state.facts["second_seal_crisis"] = "border_held"
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "capital_command", "Вы оставили ему столицу и семью, пока лично повели войско к воротам.", {"trust": 6, "respect": 5})
			if bool(state.facts.get("radomir_handover_ready", false)):
				state.resources["grain"] = maxi(0, int(state.resources.get("grain", 0)) - 4)
				return "Северный обоз остановлен у ворот. Один из связных Радомира успел предупредить Дарена о поддельном приказе. Прежде чем загорелся речной склад, стража успела вывезти большую часть зерна."
			state.resources["grain"] = maxi(0, int(state.resources.get("grain", 0)) - 10)
			return "Ваше появление остановило колебание гарнизона, и северный обоз не прошёл ворота. Дарен удержал дворец, но заговорщики сожгли речной склад и увели часть зерна."
		"night_of_second_seal:expose":
			state.facts["second_seal_crisis"] = "false_orders_rejected"
			if bool(state.facts.get("miron_public_witnesses", false)):
				state.public_order = mini(100, state.public_order + 8)
				return "Мирон привёл на площадь двух цеховых старшин. Они показали, какие распоряжения получали раньше, и при всех сверили их с ночными приказами. Даже те, кто не поверил княжескому глашатаю, отнесли ложные грамоты старшинам и оставили склады под охраной."
			var miron_support := (state.characters["miron"] as CharacterState).respect >= 8
			if miron_support:
				state.public_order = mini(100, state.public_order + 8)
				return "Мирон прочитал имена из книги на Рыночной площади, а цеховые старшины отказались выполнять приказы со второй печатью. Заговор лишился толпы и укрытий; у ворот ещё идёт бой, но столица выбрала сторону."
			if bool(state.facts.get("second_seal_order_proof", false)):
				state.public_order = mini(100, state.public_order + 2)
				return "Марек разложил на столе ночные приказы и копию реестра. Старшины увидели, что номера повторяются, а писец, чьё имя стояло под приказом, в тот день был в отъезде. Склады остались под охраной. О старых платежах княжеского дома спорят до утра."
			if state.facts.get("market_watch") == "neighbors":
				state.public_order = mini(100, state.public_order + 2)
				return "Лавочники привели на площадь возчика, которого знали по караульному списку. Он показал грамоту, полученную уже после закрытия склада. Люди разобрались, какие приказы поддельные. Спор о роли вашего отца продолжался до утра."
			state.public_order = maxi(0, state.public_order - 5)
			return "Книгу читали вслух прямо под колоколами. Одни горожане отказались подчиняться печати, другие увидели доказательство, что княжеский дом годами покупал их вождей. Заговор расколот, но вместе с ним расколота и площадь."
		"new_rule:law":
			state.facts["new_rule"] = "public_law"
			(state.characters["miron"] as CharacterState).remember(state.calendar.cycle, "public_registry", "Вы согласились ограничить собственный приказ открытым реестром и судом.", {"trust": 8, "respect": 8})
			return "С нового месяца каждый чрезвычайный приказ получает номер, запись писца и подпись ответственного советника. Мирон возглавит открытые слушания, включая дела людей вашего отца."
		"new_rule:mercy":
			state.facts["new_rule"] = "conditional_amnesty"
			state.public_order = mini(100, state.public_order + 5)
			return "Рядовым участникам дали три дня назвать вербовщиков и вернуть похищенное. Камеры начали пустеть, а список организаторов — расти; семьи погибших называют это торговлей вместо правосудия."
		"new_rule:purge":
			state.facts["new_rule"] = "secret_purge"
			state.public_order = mini(100, state.public_order + 2)
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "secret_purge", "Вы дали ему право без открытого суда удалить подозрительных людей из дворца и служб.", {"trust": 7, "respect": 4})
			(state.characters["miron"] as CharacterState).remember(state.calendar.cycle, "secret_purge", "После победы вы заменили поддельные приказы закрытыми списками задержаний.", {"trust": -8, "grievance": 6})
			return "До рассвета задержали писцов, кладовщиков и двух офицеров. Приказы снова исполняются быстро, но никто вне кабинета Дарена не знает, кто признан виновным и на каком основании."
	return "Распоряжение принято. Его последствия станут понятны позже."

func outcome(event_id: String) -> String:
	return str((resolved.get(event_id, {}) as Dictionary).get("outcome", ""))

func to_data() -> Dictionary:
	return {"resolved": resolved.duplicate(true), "reports": reports.duplicate(true)}

func load_data(data: Dictionary) -> void:
	resolved = (data.get("resolved", {}) as Dictionary).duplicate(true)
	reports.assign(data.get("reports", []))
