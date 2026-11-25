class_name StoryTimeline
extends Resource

const COURT_AUTHORITY := preload("res://simulation/court_authority.gd")

const DEFINITIONS: Dictionary = {
	"granary_roof": {
		"cycle": 2, "title": "Вода в старом амбаре", "location": "Княжеский амбар",
		"summary": "Марта, смотрительница амбара, застала воду на верхних полках. Под течью лежат мешки зерна. В кладовке хранятся старые накладные: по ним можно проверить, сколько мешков отправили в деревни. До вечера всего не успеть. Нужно решить, куда сначала послать людей: на крышу, в кладовку или к мешкам.",
		"choices": {"repair": "Оплатить срочный ремонт и оставить зерно на месте", "inspect": "Спасти накладные и сверить их со сметой", "relocate": "Развезти зерно по сухим складам"}
	},
	"dead_prince_order": {
		"cycle": 3, "title": "Приказ, подписанный после смерти", "location": "Городская стража",
		"summary": "По грамоте Даренов караул передал заключённого Илью Луня для перевода. Илья пропал по дороге. На грамоте оттиск дорожной печати вашего отца, а дата стоит уже после его смерти. Марек не нашёл печать в футляре. Ильин брат, дворцовый писец Савва, сегодня не вышел на службу. Дарен спрашивает, объявлять ли розыск печати или сначала выяснить, кто принёс грамоту.",
		"choices": {"quiet": "Сверить приказы в канцелярии и найти Савву без огласки", "public": "Предупредить караулы и объявить розыск печати", "guard": "Отстранить караул и отдельно допросить его людей"}
	},
	"smiths_dispute": {
		"cycle": 4, "title": "Кузнецы закрыли ворота", "location": "Ремесленный квартал",
		"summary": "Кузнецы остановили работу: им неделю не платят, хотя в казначейской книге стоит отметка о выплате. Владелица мастерских Ярина Радич принесла расчёт с оружейного двора и просит дать ей сверить его с княжескими счетами. Караулы тем временем ждут готовую часть заказа.",
		"choices": {"mediate": "Дать Ярине сверить счета казны и мастерской", "pay": "Сразу выдать кузнецам задержанное жалованье", "seize": "Силами стражи забрать готовую часть заказа"}
	},
	"east_gate_witness": {
		"cycle": 4, "title": "Самуил видел, кто принял зерно у ворот", "location": "Восточные ворота",
		"summary": "В спасённой накладной стоит подпись возчика Самуила. Когда с моста на дороге в Долинную область снимали доски, кто-то взял его телегу. Самуил видел, кто встретил груз у Восточных ворот. Его семья в долгу у хозяина, у которого работает дочь. Самуил просит записать показания у Марека и сохранить его имя в тайне до суда.",
		"choices": {
			"seal": "Принять показания при Мареке и закрыть имя до суда",
			"public": "Попросить Самуила рассказать о грузе при старшинах",
			"refuse": "Отпустить Самуила и сохранить только бумагу"
		}
	},
	"aglaia_letter": {
		"cycle": 5, "title": "Письмо в рукаве", "location": "Дом семи фонарей",
		"summary": "Стража задержала Милену, работницу Дома семи фонарей. У неё было письмо с номерами накладных на зерно и припиской «принять второй рукой». Дарен хочет выяснить, кто собирал номера и о какой выдаче речь. Аглая говорит, что письмо оставил посетитель вместе с платой за комнату. Она просит выслушать Милену без стражников или отпустить девушку, пока сама ищет посетителя.",
		"choices": {"question": "Выслушать Милену и Аглаю по отдельности", "deal": "Отпустить Милену и дать Аглае ночь на поиски", "guard": "Поручить Дарену допрос и передать ему письмо"}
	},
	"market_speech": {
		"cycle": 7, "title": "Мирон на Рыночной площади", "location": "Городской рынок",
		"summary": "В княжеской книге часть зерна числится выданной Долинной области. Старосты говорят, что столько не получили. Бывший судья Мирон Светоч собрал людей на площади и просит вас сказать, что двор уже проверил и когда жители узнают, куда ушло зерно.",
		"choices": {"listen": "Прийти без знаков власти и сначала выслушать", "answer": "Выйти к людям и рассказать, что уже известно", "disperse": "Приказать страже прекратить собрание"}
	},
	"border_courier": {
		"cycle": 6, "title": "Гонец с северной дороги", "location": "Северные ворота",
		"summary": "Гонец с северной заставы видел незнакомых всадников без знамён. Они осматривали мосты и спрашивали у местных, сколько зерна лежит в амбарах. Гонец не знает, откуда они. Он ждёт ответа, проверять ли дорогу своим дозором или сначала запросить объяснение у северного соседа.",
		"choices": {"scouts": "Отправить дозор проверить северную дорогу", "envoy": "Спросить северного соседа о всадниках", "dismiss": "Отпустить гонца без нового поручения"}
	},
	"scout_report": {
		"cycle": 8, "title": "Карта чужого похода", "location": "Военный зал",
		"summary": "Посланный вами дозор нанёс на карту лагеря за границей. Там собрали обоз и лёгкую конницу. Ближайший путь от лагерей к Ардену идёт через дальнюю переправу. Воевода просит решить, укреплять ли её сейчас, оставить дорогу открытой под охраной или предложить встречу соседу.",
		"choices": {"fortify": "Укрепить переправы и поднять гарнизоны", "parley": "Предложить тайную встречу на границе", "trap": "Оставить путь открытым и готовить засаду"}
	},
	"border_consequence": {
		"cycle": 8, "title": "Север отвечает делом", "location": "Пограничная канцелярия",
		"summary": "Прошло два периода после первого донесения. Ответ соседа и состояние дальних застав требуют нового решения.",
		"choices": {"inspect": "Лично выехать к заставам с малой охраной", "local_watch": "Вооружить местных старост и создать цепь сигнальных костров", "reopen_talks": "Отправить второго посланника с предложением взаимной проверки границы"}
	},
	"savva_at_chapel": {
		"cycle": 9, "title": "Савва просит один разговор", "location": "Заброшенная часовня",
		"summary": "Дворцовый писец Савва Лунь передал Мареку записку. Он говорит, что знает, кто заплатил за вывод его брата Ильи из тюрьмы. Савва готов принести список подложных приказов в часовню, если там не будет городской стражи. Радомир предлагает незаметно охранять встречу, Дарен просит сначала задержать Савву.",
		"choices": {"meet": "Прийти со скрытым прикрытием Радомира", "arrest": "Послать Дарена взять Савву живым", "safe_passage": "Дать Савве письменное обещание безопасного допроса"}
	},
	"grain_restitution": {
		"cycle": 10, "title": "Нашли часть пропавшего зерна", "location": "Речной склад",
		"open_until_finale": true,
		"summary": "Савва узнал в накладной помету склада у реки. Марек проверил бирки на мешках и нашёл там шесть мер из старого обоза. Старосты просят отдать зерно деревням, которые тогда остались без него. Хозяин склада показывает расписку: по ней эти мешки полагались ему в счёт долга двора за помол.\n\nХозяин согласился не трогать мешки до конца лета. Ладе нужно знать, куда их везти: в деревни, в княжеский амбар или в кладовую судей, пока те проверяют расписку.",
		"choices": {
			"villages": "Вернуть найденное зерно пострадавшим деревням",
			"reserve": "Забрать зерно в общий запас княжеского амбара",
			"court": "Запечатать мешки у судей и проверить расписку о долге"
		}
	},
	"fever_outbreak": {
		"cycle": 10, "title": "Горячка в нижнем городе", "location": "Речной квартал",
		"summary": "За три дня слегли семьи кожевников и двое лодочников. Причина неизвестна; слухи уже называют воду, чужеземцев и Божий гнев.",
		"choices": {"quarantine": "Перекрыть квартал и доставлять пищу внутрь", "clinics": "Открыть временные лечебницы", "conceal": "Не объявлять тревогу до точного диагноза"}
	},
	"family_warning": {
		"cycle": 11, "title": "Печать в детской", "location": "Семейные покои",
		"summary": "Адела нашла у девятилетнего Всеволода кусок воска с оттиском второй печати. Сын говорит, что его дал «старый друг деда» и попросил спрятать до игры в тайного посланника. Незнакомец сумел пройти во внутренний двор, не вызвав тревоги охраны.",
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
		"choices": {"publish": "Открыть книгу совету и городским судьям", "inner_circle": "Ограничить доступ к книге близким советникам", "continue_scheme": "Сохранить тайну и использовать старые связи отца"}
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
		"summary": "Заговорщики больше не распоряжаются в столице. Цеховые старшины, судьи и военные ждут решения о том, кто сможет проверять княжеский приказ и как поступить с людьми, которые выполняли ложные грамоты.",
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
	if event_id == "grain_restitution":
		var witness: Dictionary = resolved.get("east_gate_witness", {})
		var meeting: Dictionary = resolved.get("savva_at_chapel", {})
		return maxi(first_cycle, maxi(int(witness.get("cycle", 0)), int(meeting.get("cycle", 0))) + 1)
	return first_cycle

func _is_unlocked(event_id: String) -> bool:
	var border: Dictionary = resolved.get("border_courier", {})
	if event_id == "scout_report":
		return str(border.get("choice", "")) == "scouts"
	if event_id == "border_consequence":
		return str(border.get("choice", "")) in ["envoy", "dismiss"]
	if event_id == "new_rule":
		return resolved.has("night_of_second_seal")
	if event_id == "divided_command":
		return not resolved.has("night_of_second_seal")
	if event_id == "east_gate_witness":
		return (resolved.get("granary_roof", {}) as Dictionary).get("choice") == "inspect"
	if event_id == "grain_restitution":
		var witness: Dictionary = resolved.get("east_gate_witness", {})
		var meeting: Dictionary = resolved.get("savva_at_chapel", {})
		return witness.get("choice") in ["seal", "public"] and meeting.get("choice") in ["meet", "safe_passage"]
	return true

func update(state: WorldState) -> void:
	_apply_delayed_results(state)
	_resolve_neglected_events(state)

func _apply_delayed_results(state: WorldState) -> void:
	_update_opening_dispatch(state)
	_resolve_vardan_exchange(state)
	_resolve_northern_reply(state)
	_resolve_pump_workshop(state)
	_resolve_grain_restitution(state)
	var roof: Dictionary = resolved.get("granary_roof", {})
	if roof.get("choice") == "inspect" and not roof.get("followup_applied", false) and state.calendar.cycle >= int(roof["cycle"]) + 2:
		roof["followup_applied"] = true
		if int(state.development.levels.get("granary", 0)) > 1:
			_add_report(state.calendar.cycle, "Накладные и зерно уцелели", "Мешки успели перенести в расширенное крыло амбара. Проверка бумаг закончилась, прежде чем следующая вода дошла до запасов.")
		else:
			state.resources["grain"] = maxi(0, int(state.resources["grain"]) - 6)
			state.facts["granary_roof"] = "water_damage"
			_add_report(state.calendar.cycle, "Дождь дошёл до зерна", "Пока разбирали накладные, над старой кладовкой снова потекло. Зерно с верхней полки отсырело. Спасённая бумага уже у Марека.")
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
			var link_text := "Ярина нашла перевод на несуществующий перевозочный двор. Получатель вписан после составления ведомости."
			if state.facts.get("second_seal_investigation") in ["quiet", "public", "guard_detained"]:
				state.facts["armory_order_mark_similarity"] = true
				link_text += " На копии приказа о переводе Ильи Марек нашёл похожий росчерк. Возможно, обе записи сделаны одной рукой. По такому сходству Марек не берётся опознать писца."
			_add_report(state.calendar.cycle, "Ярина закончила сверку счетов", link_text)
	if resolved.has("aglaia_letter"):
		var letter: Dictionary = resolved["aglaia_letter"]
		if not bool(letter.get("followup_applied", false)) and state.calendar.cycle >= int(letter.get("cycle", 0)) + 1:
			var choice := str(letter.get("choice", ""))
			if choice == "deal":
				state.facts["aglaia_grey_guest"] = true
				var guest_alias := "Мартен Каль"
				state.facts["aglaia_guest_alias"] = guest_alias
				_add_report(state.calendar.cycle, "Имя от Аглаи", "К утру Аглая передала имя, которым назвался приезжий: %s, торговец шерстью. Он расспрашивал о дворцовых писцах и платил новыми северными монетами. Аглая предупредила: его настоящее имя она не знает." % guest_alias)
			elif choice == "question":
				state.facts["aglaia_grey_guest"] = true
				_add_report(state.calendar.cycle, "Показания сошлись не полностью", "Милена и Аглая одинаково описали мужчину в сером плаще. Милена говорит, что он вложил письмо ей в рукав, Аглая — что передал его вместе с платой за комнату. Имени не назвала ни одна. Писец записал обе версии.")
			elif choice == "guard":
				state.facts["aglaia_witness_silent"] = true
				_add_report(state.calendar.cycle, "Задержанная изменила показания", "После ночи в управлении стражи девушка заявила, что сама украла письмо у неизвестного клиента. Дарен считает признание достаточным; имя посетителя так и не появилось в деле.")
			letter["followup_applied"] = true
			resolved["aglaia_letter"] = letter

func _update_opening_dispatch(state: WorldState) -> void:
	var dispatch := str(state.facts.get("opening_grain_dispatch", ""))
	if dispatch not in ["in_transit", "contracted"]:
		return
	var lag := 2 if dispatch == "contracted" else 1
	if state.calendar.cycle < state.opening_decision.resolved_cycle + lag:
		return
	state.facts["opening_grain_dispatch"] = "delivered"
	if dispatch == "contracted":
		_add_report(state.calendar.cycle, "Сарнский обоз прибыл", "Купцы привезли оплаченное зерно. Старосты расписались за мешки. Купленные запасы не выводили из княжеских амбаров.")
	elif state.opening_decision.grain_response == "partial":
		_add_report(state.calendar.cycle, "Первую помощь получили ближние деревни", "Восьми мер хватило на первую выдачу у южной дороги. Несколько дальних деревень всё ещё ждут. Лада просит не закрывать дело одной распиской.")
	else:
		_add_report(state.calendar.cycle, "Большой обоз дошёл до Долинной области", "Старосты приняли зерно, которое вы отправили под охраной. В старой книге всё ещё числится другой обоз. По записи он прошёл мост во вторник, хотя, по словам отца, доски сняли накануне.")

func _resolve_vardan_exchange(state: WorldState) -> void:
	var offer: Dictionary = resolved.get("vardan_offer", {})
	if offer.get("choice") != "counterfeit" or offer.get("followup_applied", false):
		return
	if state.calendar.cycle <= int(offer["cycle"]):
		return
	offer["followup_applied"] = true
	var warned: bool = state.facts.get("aglaia_evening") == "attended" or bool(state.facts.get("second_seal_order_proof", false))
	var has_space := state.justice.prisoners < state.justice.prison_capacity
	if warned and has_space:
		state.facts["vardan_stance"] = "in_custody"
		state.facts["second_seal_custody"] = "judges"
		state.facts.erase("second_seal_holder")
		state.justice.prisoners += 1
		_add_report(state.calendar.cycle, "Вардан в руках городских судей", "Дарен дождался встречи. Вардан принёс печать. Судьи приняли её при свидетелях, а Вардан под стражей ждёт разбирательства. Люди, которые ему подчинялись, в руки суда пока не попали.")
	else:
		state.facts["vardan_stance"] = "escaped_exchange"
		state.facts["second_seal_custody"] = "unknown"
		state.facts.erase("second_seal_holder")
		var result := "Вардан не пришёл на встречу. Пришедший от него возчик передал пустой футляр и сказал, что сделка отменена. Где печать, судьи не знают."
		if warned and not has_space:
			result = "Городские судьи не согласились принимать задержанного: в тюрьме не осталось места. Пока Дарен ждал другого распоряжения, Вардан отменил встречу. Где печать, пока неизвестно."
		_add_report(state.calendar.cycle, "Обмен сорвался", result)

func _resolve_northern_reply(state: WorldState) -> void:
	for event_id: String in ["scout_report", "border_consequence"]:
		var record: Dictionary = resolved.get(event_id, {})
		if record.get("choice") not in ["parley", "reopen_talks"] or record.get("followup_applied", false):
			continue
		if state.calendar.cycle < int(record["cycle"]) + 2:
			continue
		record["followup_applied"] = true
		var standing := int(state.diplomacy.relations.get("north_march", 0))
		var case_notes: bool = state.facts.get("envoy_meetings") == "written_first"
		if standing >= 0 or (case_notes and standing > -20):
			state.facts["northern_negotiation"] = "stand_down"
			state.diplomacy.relations["north_march"] = mini(100, standing + 4)
			_add_report(state.calendar.cycle, "Северная марка согласилась отвести обоз", "Маркграф обещал оставить войско за переправой до общего осмотра складов. Это касается его рот. За людей, нанятых частными баронами, он отвечать отказался.")
		else:
			state.facts["northern_negotiation"] = "refused"
			_add_report(state.calendar.cycle, "Посланник вернулся без соглашения", "Северная марка требует сначала признать спорные земли её владением. Илва привезла грамоту обратно, чтобы никто не принял молчание за согласие. Пока обозы остаются на дороге.")

func _resolve_pump_workshop(state: WorldState) -> void:
	var record: Dictionary = resolved.get("tikhon_pump", {})
	if record.get("choice") != "workshop" or record.get("followup_applied", false):
		return
	if state.calendar.cycle < int(record["cycle"]) + 3:
		return
	record["followup_applied"] = true
	state.facts["tikhon_pump"] = "workshop_ready"
	var prepared := bool(state.facts.get("tikhon_trial_prepared", false))
	state.public_health = mini(100, state.public_health + (5 if prepared else 3))
	_add_report(state.calendar.cycle, "Тихон закончил работу в литейной", "После месяца работы машину установили у красильни. Тихон показал дворовым, как менять клапан. Лекари подтверждают, что чистую воду теперь не приходится носить с нижнего берега." if prepared else "Механизм запустили у красильни. Он подаёт чистую воду в один двор. Тихон оставил там чертёж клапана: если мастер снова понадобится, ему смогут объяснить, какая деталь вышла из строя.")

func _resolve_grain_restitution(state: WorldState) -> void:
	var record: Dictionary = resolved.get("grain_restitution", {})
	if record.is_empty() or state.facts.has("grain_restitution_result") or state.calendar.cycle <= int(record["cycle"]):
		return
	var rural := state.factions["rural"] as FactionState
	var guilds := state.factions["guilds"] as FactionState
	var text := ""
	match str(record.get("choice", "")):
		"villages":
			state.facts["grain_restitution_result"] = "delivered"
			rural.react(state.calendar.cycle, 4, "Лада доставила найденное зерно в деревни по списку прежней недостачи.")
			guilds.react(state.calendar.cycle, -2, "Хозяин склада потерял казённое зерно, которое считал платой за помол.")
			text = "Лада привезла расписки от старост. Все шесть мер приняли деревни, которым их не довезли в прошлый раз. В этих расписках записано, сколько получил каждый двор. Хозяин склада принёс в канцелярию требование оплатить помол деньгами."
		"reserve":
			state.facts["grain_restitution_result"] = "in_reserve"
			state.resources["grain"] = int(state.resources["grain"]) + 6
			rural.react(state.calendar.cycle, -3, "Старосты увидели, что зерно со склада отправили в столичный резерв.")
			text = "В княжеском амбаре приняли и взвесили все шесть мер. Старосты увидели возы у городских ворот и попросили Ладу добиться отдельного решения о выдаче. Расписку хозяина склада Марек оставил в деле."
		"court":
			state.facts["grain_restitution_result"] = "registered"
			rural.react(state.calendar.cycle, -1, "Найденное зерно останется под печатью, пока судьи проверяют требование об оплате.")
			guilds.react(state.calendar.cycle, 2, "Судьи записали претензии сторон, прежде чем распоряжаться запасом.")
			text = "Судьи приняли шесть мер под свою печать. Лада получила копию описи и отнесла её старостам. Теперь суду нужно установить, действительно ли двор отдал эти мешки за помол. На выдачу зерно пока не пошло."
		_:
			return
	_add_report(state.calendar.cycle, "Что стало с зерном с речного склада", text)

func _resolve_neglected_events(state: WorldState) -> void:
	for event_id: String in DEFINITIONS:
		if resolved.has(event_id) or not _is_unlocked(event_id):
			continue
		if not state.calendar.is_demo_complete() and (DEFINITIONS[event_id].get("open_until_finale", false) or state.calendar.cycle < opening_cycle(event_id) + 2):
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
		var choice_title := "Оставлено без ответа" if choice_id == "neglected" else str(record.get("choice_title", (event.get("choices", {}) as Dictionary).get(choice_id, choice_id)))
		history.append({
			"event_id": event_id,
			"cycle": int(record.get("cycle", 0)),
			"title": str(record.get("title", event.get("title", event_id))),
			"choice": choice_title,
			"outcome": str(record.get("outcome", ""))
		})
	history.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["cycle"]) > int(b["cycle"]))
	if limit > 0 and history.size() > limit:
		history.resize(limit)
	return history

func _neglect_consequence(state: WorldState, event_id: String) -> String:
	match event_id:
		"grain_restitution":
			state.facts["grain_restitution_result"] = "missed"
			(state.factions["rural"] as FactionState).react(state.calendar.cycle, -2, "Двор не распорядился вернуть найденное зерно, пока оно было на складе.")
			return "Хозяин склада пустил найденные мешки в помол по своей расписке. Лада увезла старостам только копию накладной. По бумаге можно разбираться с долгом, а вернуть эти шесть мер уже нельзя."
		"granary_roof":
			state.resources["grain"] = maxi(0, int(state.resources.get("grain", 0)) - 12)
			state.facts["granary_roof"] = "collapsed"
			return "После нового ливня часть кровли рухнула. Намокшее зерно пришлось выбросить."
		"dead_prince_order":
			state.facts["second_seal_investigation"] = "trail_cold"
			return "Пока двор не отвечал, семья Саввы исчезла из дома. В печи канцелярии нашли обгоревшие черновики приказов, но самого писца уже никто не видел."
		"east_gate_witness":
			return "К утру Самуил забрал дочь и уехал из Ардена. Подпись на накладной осталась, но возчик больше не может подтвердить, что видел у ворот."
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
			return "Адела сама увезла детей из столицы и отказалась сообщить маршрут дворцовой канцелярии. Во внутренних покоях она больше не доверяет вашей охране."
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
			return "Противоречивые приказы задержали гарнизон. Часть зерна успели увезти. " + _settle_northern_front(state, "neglected")
		"new_rule":
			state.facts["new_rule"] = "old_order_survived"
			return "Совет разошёлся без нового порядка. Печать заменили, но право проверять княжеский приказ так и осталось неясным."
	return "Дело слишком долго оставалось без решения, и обстоятельства решили его за вас."

func definition(event_id: String) -> Dictionary:
	return DEFINITIONS.get(event_id, {})

func contextual_definition(state: WorldState, event_id: String) -> Dictionary:
	var event: Dictionary = definition(event_id).duplicate(true)
	if event_id == "granary_roof":
		if state.facts.get("father_warned_of_traitor", false):
			event["summary"] += " В кладовке может быть накладная того обоза, о котором говорил отец."
		var grain_response := str(state.facts.get("grain_response", ""))
		var dispatch := str(state.facts.get("opening_grain_dispatch", ""))
		if dispatch == "delivered" and grain_response == "partial":
			event["summary"] += " Восемь мер уже довезли до ближних деревень. Дальние ещё ждут. Если намокнет и этот запас, им будет труднее помочь."
		elif dispatch == "delivered" and grain_response == "full":
			event["summary"] += " Большой обоз уже приняли старосты. Теперь течь угрожает запасу, который остался в столице."
		elif dispatch == "in_transit":
			event["summary"] += " Обоз с помощью уже в пути. Под течью остался запас для следующих выдач."
		elif grain_response == "purchase":
			event["summary"] += " Для деревень заказали привозное зерно. В этом амбаре остался княжеский запас, который хотели сберечь."
		elif grain_response == "defer":
			event["summary"] += " Выдачу в деревни отложили до сверки книг. Дождь может испортить запас раньше, чем писцы закончат."
		if state.facts.get("granary_inspection") == "double_check":
			event["summary"] += " У Марты на руках вес последнего обоза. Теперь его можно сравнить со старыми накладными."
		if not COURT_AUTHORITY.is_present(state, "granary_keeper"):
			event["summary"] = str(event["summary"]).replace("Марта, смотрительница амбара, застала", "Дежурный писец заметил").replace("У Марты", "У писца")
	if event_id == "dead_prince_order" and bool(state.facts.get("bridge_receipt_found", false)):
		event["summary"] += " Марек сверил грамоту со спасённой накладной. В обеих бумагах есть приписка «через Восточные ворота». Это повод проверить записи у ворот. Кто написал приписки и куда ушло зерно, пока неизвестно."
	if event_id == "dead_prince_order" and state.facts.get("marek_briefing") == "evidence_first":
		event["summary"] += " По вашему распоряжению Марек вынес бумаги, прежде чем называть подозреваемых. Он показывает две даты и спрашивает, кого позвать свидетелем."
	if event_id == "smiths_dispute" and bool(state.facts.get("bridge_receipt_found", false)):
		event["summary"] += " В расчёте за кузнечный заказ и в спасённой накладной на зерно указаны Восточные ворота. Ярина предлагает спросить у караула, какие грузы там приняли."
	if event_id == "aglaia_letter" and bool(state.facts.get("missing_armory_payment", false)):
		event["summary"] += " Один номер Ярина узнаёт: под ним списали деньги за кузнечный заказ. Марек хочет сохранить письмо рядом с ведомостью."
	if event_id == "aglaia_letter" and state.facts.get("bridge_testimony") == "public":
		event["summary"] += " После открытого разговора у ворот на рынке уже называют один из номеров. Аглая предупреждает: его мог вписать и человек, слышавший Самуила, чтобы направить стражу по ложному следу."
	if event_id == "aglaia_letter" and state.facts.get("aglaia_interview_terms") == "witness":
		event["summary"] += " Аглая напоминает: вы уже согласились, что при первом разговоре будет знакомый девушкам писец."
	if event_id == "smiths_dispute" and state.facts.get("zlata_payroll_handling") == "copy_shared":
		event["summary"] += " У подмастерьев осталась обещанная им копия расчёта. Она позволяет сверить суммы, даже если придворный писец закроет книги."
	if event_id == "border_courier" and state.facts.get("envoy_meetings") == "written_first":
		event["summary"] += " Илва предлагает сверить объяснение соседа с письменными условиями, полученными при первом приёме."
	if event_id == "border_courier" and state.facts.get("grain_report_read") == "captain":
		event["summary"] += " В отчёте капитана уже отмечена разбитая дорога к мосту. Выезд лучше планировать по дороге через мельницу."
	if event_id == "fever_outbreak":
		match str(state.facts.get("temple_food_line", "")):
			"household_tokens": event["summary"] += " У отца Луки уже есть список дворов для доставки еды, но недавно приехавшие семьи в него не попали."
			"open_pots": event["summary"] += " К храмовой кухне привыкли ходить и новые жители. Отец Лука просит, чтобы на время горячки пищу развозили по дворам вместо общей очереди."
	if event_id == "border_consequence":
		var first_choice := str((resolved.get("border_courier", {}) as Dictionary).get("choice", ""))
		if first_choice == "envoy":
			event["title"] = "Ответ северного соседа"
			event["summary"] = "Северная марка ответила на вашу грамоту: её всадники якобы ловили конокрадов. По дороге посланник заметил свежие колеи тяжёлых телег и новые склады. Воевода просит решить, проверять ли заставы с вашей стороны или предложить соседу общий осмотр складов."
		elif first_choice == "dismiss":
			event["title"] = "Дальняя застава разоружена"
			event["summary"] = "Гонец вернулся: неизвестные разоружили дальнюю заставу, забрали списки караулов и ушли без знамён. Погибших нет. Пограничники ждут распоряжения: проверять, куда ушли нападавшие, или пока укрепить наблюдение за дорогами."
	if event_id == "savva_at_chapel":
		if bool(state.facts.get("missing_armory_payment", false)):
			event["summary"] += " Марек хочет спросить Савву об исправлении в оружейной ведомости."
		if bool(state.facts.get("aglaia_grey_guest", false)):
			var guest_alias := str(state.facts.get("aglaia_guest_alias", ""))
			if not guest_alias.is_empty():
				event["summary"] += " Марек также хочет спросить о приезжем, который назвался торговцем по имени %s." % guest_alias
			elif state.facts.get("aglaia_letter") == "statements_compared":
				event["summary"] += " У Марека есть описание мужчины в сером плаще. Как тот передал письмо, Аглая и Милена рассказали по-разному."
			else:
				event["summary"] += " Марек хочет узнать, видел ли Савва северные монеты, которыми расплачивался посетитель Аглаи."
		if bool(state.facts.get("marek_copy_saved", false)):
			event["summary"] += " У Марека есть копия книги приказов. Даже если сумка Саввы пропадёт, подлинные распоряжения будет с чем сверить."
		if bool(state.facts.get("bridge_receipt_found", false)):
			event["summary"] += " Савва просит принести накладную на зерно с Восточных ворот. Он говорит, что может объяснить, откуда в ней взялась подпись Самуила."
		if state.facts.get("bridge_testimony") == "sealed":
			event["summary"] += " У Марека есть закрытое показание Самуила о человеке, который встречал обоз. Именем возчика по-прежнему нельзя делиться без его согласия."
		elif state.facts.get("bridge_witness_refuge") == "safe_house":
			event["summary"] += " Лада сохранила связь с Самуилом через людей, которые укрыли его семью. Марек может сверить подробности показаний без новой встречи на площади."
		if state.facts.get("grain_report_read") == "agent":
			event["summary"] += " Путь телег совпал с тем, который указал агент в отчёте об амбарах. Пока это подтверждает маршрут, но не имя заказчика."
	if event_id == "market_speech":
		match str(state.facts.get("lowland_register", "")):
			"open": event["summary"] += " Мирон держит в руках копию сверки, которую Лада вывесила на площади. Он требует назвать владельцев амбаров, чьи записи расходятся с выдачами."
			"sealed": event["summary"] += " Марек принёс сверку Лады. По ней можно назвать размер недостачи, сохранив имена деревенских свидетелей в тайне."
		if state.facts.get("grain_report_read") in ["sister", "steward"]:
			event["summary"] += " Ответ можно начать с проверенных сведений из отчёта по Долинной области. Отдельно придётся признать, чего двор ещё не знает."
		if bool(state.facts.get("miron_hearing_promised", false)):
			event["summary"] += " Мирон считает, что это и есть открытый разговор, который вы ему ранее обещали."
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
			event["summary"] += " Марек свёл собранные свидетельства и бумаги по поддельным приказам. Судьи смогут проверить его выводы, даже если Савва не повторит показания публично."
	if event_id == "fathers_ledger" and _family_away(state):
		event["choices"]["inner_circle"] = "Показать книгу Мареку и Радомиру"
		event["summary"] += " Аделы и детей нет в столице. Отправлять семейные копии по дороге Марек пока не советует."
	if event_id == "divided_command" and state.facts.get("family_letter_reply") == "trust_through_lada":
		event["summary"] += " Из письма Аделы стало известно, в какую смену незнакомец прошёл к детской. Дарен и Радомир принесли две книги, и в них за один час отвечают разные люди."
	if event_id == "night_of_second_seal":
		event["summary"] = _night_brief(state)
		if not _has_full_ledger(state):
			event["choices"]["expose"] = "Показать горожанам сохранившиеся бумаги и предупредить о ложных приказах"
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
			"capital_held":
				if state.facts.get("northern_crossing") == "lost":
					event["summary"] += " Семьи с оставленного севера требуют ответить, почему столицу спасли за их счёт."
				else:
					event["summary"] += " Начальники складов просят закрепить проверку пропусков, пока дозоры остаются у переправы."
			"border_held": event["summary"] = str(event["summary"]) + " Владельцы сгоревших складов требуют возмещения за победу на границе."
			"false_orders_rejected": event["summary"] = str(event["summary"]) + " Цехи, отказавшиеся выполнять ложные приказы, требуют закрепить своё право на проверку власти."
			"command_collapsed": event["summary"] = "К утру гарнизон снова выполняет приказы из замка, но часть складов разграблена. Совет требует решить, кто отныне сможет проверять княжеские распоряжения."
		if state.facts.get("vardan_stance") == "in_custody":
			event["summary"] += " Судьи требуют решить, в каком порядке слушать дело Вардана. Его самого в зале нет."
		if _has_full_ledger(state) and bool(state.facts.get("second_seal_order_proof", false)):
			event["summary"] += " Марек разделил два дела: прежние выплаты, которые подписал ваш отец, и новые грамоты, которые канцелярия не выдавала. Суд может проверить оба дела по разным бумагам."
		if bool(state.facts.get("court_order_exposed", false)):
			event["summary"] += " Родные погибшего чиновника принесли прошение. Они спрашивают, сможет ли новый суд проверять и распоряжения самого князя."
	return event

func _family_away(state: WorldState) -> bool:
	return state.facts.get("family_security") in ["country_cloister", "breached"]

func _has_full_ledger(state: WorldState) -> bool:
	return state.facts.get("fathers_ledger") in ["published", "inner_circle", "network_reactivated"]

func _night_brief(state: WorldState) -> String:
	var text := "Одновременно звонят колокола у речных складов и северных ворот. "
	match str(state.facts.get("vardan_stance", "")):
		"inside_council":
			text += "Возвращённая Варданом печать остаётся в замке. Его бывшие люди предъявляют копии грамоты, подписанной до сделки. Первые телеги уже у складов."
			if state.facts.get("vardan_river_manifest") == "listed":
				text += " Вардан принёс обещанный список перевозчиков. Имена помогут отличить новые телеги от обычного обоза."
		"in_custody":
			text += "Вардан под стражей, печать у судей. Люди, которые остались на свободе, поднимают складские караулы по заранее заготовленным грамотам."
		"escaped_exchange":
			text += "После сорванного обмена Вардан не появлялся. Его возчики уже у складов, а городской караул не может проверить, откуда взялись их грамоты."
		_:
			if state.facts.get("command_structure") == "joint":
				text += "У складов задержали возчиков с грамотами без второй подписи. Но такие же бумаги разнесли по всему городу, и штаб ещё не знает, кто успел поверить им."
			else:
				text += "По ложным распоряжениям часть городской стражи снялась с постов. У складов ждут незнакомые возчики."
	match state.army.status:
		ArmyState.BattleStatus.VICTORY:
			text += " Дружина выиграла сражение на северной дороге. Гонец просит людей, чтобы удержать переправу на случай нового удара."
		ArmyState.BattleStatus.DEFEAT, ArmyState.BattleStatus.RETREATED:
			text += " Дружина уже отошла с северной дороги. Угроза теперь дошла до городских ворот."
		ArmyState.BattleStatus.DEPLOYMENT:
			text += " Полевой отряд ещё на исходных позициях. Если сейчас выбрать приоритет для столицы, Радомир отведёт его к воротам."
		ArmyState.BattleStatus.FIGHTING:
			text += " Полевой бой не закончен. Для нового приказа Радомиру придётся вывести этот отряд к воротам."
		_:
			if state.facts.get("northern_negotiation") == "stand_down":
				text += " Основной обоз отвели по соглашению. У заставы всё равно заметили людей без знамён."
			else:
				text += " За границей показались огни военного обоза."
	return text + " Это не случайный налёт: кто-то проверяет, кому ещё подчиняются оба караула."

func _settle_northern_front(state: WorldState, choice_id: String) -> String:
	var recalled := state.army.status in [ArmyState.BattleStatus.DEPLOYMENT, ArmyState.BattleStatus.FIGHTING]
	var victory := state.army.status == ArmyState.BattleStatus.VICTORY
	var defeated := state.army.status in [ArmyState.BattleStatus.DEFEAT, ArmyState.BattleStatus.RETREATED]
	var posture := str(state.facts.get("northern_posture", ""))
	var prepared := posture in ["fortified", "local_watch"]
	var crossing := "contested"
	if state.facts.get("northern_negotiation") == "stand_down" and choice_id != "neglected":
		crossing = "held"
	elif (victory and choice_id != "neglected") or (prepared and choice_id == "border" and not defeated and not recalled):
		crossing = "held"
	elif defeated or (choice_id in ["capital", "neglected"] and not victory):
		crossing = "lost"
	state.facts["northern_crossing"] = crossing
	var text := ""
	if recalled:
		state.army.status = ArmyState.BattleStatus.RETREATED
		state.army.pending_orders.clear()
		state.facts["northern_patrol_recalled"] = true
		text = "Радомир отозвал полевой отряд к городским воротам. "
	match crossing:
		"held":
			return text + "Дальняя переправа осталась за Арденом."
		"lost":
			return text + "Северяне заняли дальнюю переправу, но за городские ворота не прошли."
	return text + "К рассвету ни одна сторона не удерживает оба берега переправы."

func can_choose(state: WorldState, event_id: String, choice_id: String) -> bool:
	if state.calendar.is_demo_complete() or not state.can_govern() or event_id not in available_events(state.calendar.cycle):
		return false
	if not (definition(event_id).get("choices", {}) as Dictionary).has(choice_id):
		return false
	return state.state_treasury >= choice_gold_cost(event_id, choice_id)

func choice_gold_cost(event_id: String, choice_id: String) -> int:
	match "%s:%s" % [event_id, choice_id]:
		"granary_roof:repair": return 5
		"smiths_dispute:pay": return 8
		"scout_report:fortify": return 12
		"fever_outbreak:quarantine", "fathers_ledger:continue_scheme": return 6
		"fever_outbreak:clinics": return 10
		"tikhon_pump:field_test": return 3
		"tikhon_pump:workshop": return 8
	return 0

func choose(state: WorldState, event_id: String, choice_id: String) -> bool:
	if not can_choose(state, event_id, choice_id):
		return false
	var presented := contextual_definition(state, event_id)
	if event_id == "night_of_second_seal" and not resolved.has("divided_command"):
		var missed := _neglect_consequence(state, "divided_command")
		resolved["divided_command"] = {"choice": "neglected", "cycle": state.calendar.cycle, "outcome": missed}
		_add_report(state.calendar.cycle, "Решение штаба опоздало", missed)
	var outcome := _apply_choice(state, event_id, choice_id)
	if event_id == "night_of_second_seal":
		outcome += " " + _settle_northern_front(state, choice_id)
	if event_id == "granary_roof" and not COURT_AUTHORITY.is_present(state, "granary_keeper"):
		outcome = outcome.replace("Марта нашла", "Писец нашёл").replace("Марта подняла", "Писец поднял").replace("Марта вывела", "Писец вывел").replace("Марта отправила", "Писец отправил")
	if event_id == "savva_at_chapel" and bool(state.facts.get("marek_copy_saved", false)):
		state.facts["second_seal_order_proof"] = true
		outcome += " Марек сверил показания Саввы со своей копией книги и нашёл номера двух приказов, которых канцелярия не выдавала. Свидетельство можно проверить и без печати."
	if event_id == "savva_at_chapel":
		state.facts["savva_named_vardan"] = true
	var verified_witness: bool = state.facts.get("bridge_testimony") == "sealed" or state.facts.get("bridge_witness_refuge") == "safe_house"
	if event_id == "savva_at_chapel" and choice_id != "arrest" and verified_witness:
		state.facts["second_seal_order_proof"] = true
		outcome += " Марек сверил записи двух свидетелей. Оба назвали одну и ту же телегу и человека, который встречал её у ворот. Каждый сообщил деталь, которой не мог знать со слов другого."
	state.add_fatigue(4)
	resolved[event_id] = {"choice": choice_id, "cycle": state.calendar.cycle, "outcome": outcome, "title": presented["title"], "choice_title": presented["choices"][choice_id]}
	state.consequence_log.append({"cycle": state.calendar.cycle, "kind": "story_event_resolved", "event": event_id, "choice": choice_id})
	return true

func _apply_choice(state: WorldState, event_id: String, choice_id: String) -> String:
	match "%s:%s" % [event_id, choice_id]:
		"grain_restitution:villages":
			return "Лада забрала у хозяина список мешков и послала за телегами. У старост она попросит расписки о получении. Хозяину велели оставить в канцелярии свою расписку о долге."
		"grain_restitution:reserve":
			return "В княжеский амбар послали приказ принять мешки в общий запас, взвесить их отдельно и отметить, с какого склада они приехали. Лада предупредит старост, что зерно пока отвезут в город."
		"grain_restitution:court":
			return "Марек позвал судебного писца. Тот сверит бирки и опечатает мешки. Лада просит копию описи для старост и записку, когда судьи смогут выслушать обе стороны."
		"granary_roof:repair":
			state.state_treasury -= 5
			state.facts["granary_roof"] = "repaired"
			return "Плотники перекрыли течь до следующего дождя. Зерно сухое. Марта нашла под лестницей пломбу с одной из старых телег, но накладные из кладовки ещё не разобрали."
		"granary_roof:inspect":
			state.facts["granary_roof"] = "inspecting"
			state.facts["bridge_receipt_found"] = true
			return "Марта подняла накладную с пола кладовки. В ней записано, что во вторник обоз приняли у Восточных ворот. Книга говорит, что в тот же день он прошёл по мосту в Долинную область. Отец же говорил, что доски с моста сняли ещё в понедельник. В накладной есть подпись возчика, которого можно расспросить. Крыша всё ещё течёт."
		"granary_roof:relocate":
			var water_gate_repaired: bool = state.facts.get("forge_priorities") == "water_parts"
			state.resources["grain"] = maxi(0, int(state.resources["grain"]) - (0 if water_gate_repaired else 2))
			state.facts["granary_roof"] = "grain_relocated"
			if water_gate_repaired:
				return "Крепление, которое выковал Глеб, выдержало. Плотники подняли заслонку плотины и спустили лишнюю воду. Дорога к частным складам осталась сухой, все мешки доехали. Купцы теперь знают размер княжеского запаса."
			if state.facts.get("forge_priorities") == "tools":
				return "Временное крепление на заслонке плотины ещё не заменили. Марта вывела телеги в объезд размокшей дороги. Два мешка рассыпались. Остальные довезли до частных складов, где купцы увидели размер княжеского запаса."
			return "Марта вывела обоз к трём частным складам. Два мешка рассыпались, но остальные теперь под крышей. Купцы увидели размер запаса и к вечеру начали спрашивать, сколько зерна князь сможет продать."
		"dead_prince_order:quiet":
			state.facts["second_seal_investigation"] = "quiet"
			state.facts["savva_family_watched"] = true
			return "Дарен оставил двух людей наблюдать за домом Саввы, а Марек поднял списки тех, кто имел доступ к кабинету старого князя. О пропавшей печати в городе пока не знают."
		"dead_prince_order:public":
			state.facts["second_seal_investigation"] = "public"
			(state.factions["nobility"] as FactionState).react(state.calendar.cycle, -2, "Двор узнал, что от имени умершего князя продолжают выходить приказы.")
			return "На воротах велели сверять грамоты с реестром. Подлинный дорожный знак на воске больше не пропускал людей сам по себе. Теперь и тот, кто унес печать, знает о розыске."
		"dead_prince_order:guard":
			state.facts["second_seal_investigation"] = "guard_detained"
			state.public_order = maxi(0, state.public_order - 2)
			return "Троих стражников заперли до допроса. Они настаивают, что исполнили безупречный документ; остальные караулы теперь требуют письменного подтверждения даже обычных распоряжений."
		"east_gate_witness:seal":
			state.facts["bridge_testimony"] = "sealed"
			return "Самуил описал телегу и человека у ворот, но отказался назвать его хозяина без подтверждения. Марек убрал показание в книгу и дал Самуилу копию обещания не оглашать имя до суда."
		"east_gate_witness:public":
			state.facts["bridge_testimony"] = "public"
			var guilds := state.factions["guilds"] as FactionState
			guilds.react(state.calendar.cycle, 2, "Возчик подтвердил разницу между княжеской книгой и реальной выдачей.")
			return "При старшинах Самуил рассказал, чью телегу видел и кто ждал её у ворот. Горожане теперь могут спросить об этом у него и у караула. К вечеру хозяин, которому задолжала семья, разыскал их. Самуил попросил Марека убрать из записи имена родных."
		"east_gate_witness:refuse":
			state.facts["bridge_testimony"] = "document_only"
			return "Самуил уехал домой с дочерью. Марек оставил в деле накладную с подписью. Кто принимал груз у ворот, теперь придётся выяснять по другим документам."
		"smiths_dispute:mediate":
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, 3, "Князь лично выслушал спор ремесленников с казной.")
			(state.characters["zlata"] as CharacterState).remember(state.calendar.cycle, "first_commission", "Вы доверили ей независимо сверить счета оружейного двора и казны.", {"respect": 4, "trust": 2})
			state.facts["zlata_met"] = true
			state.facts["smith_payment_audit"] = true
			return "Ярина согласилась проверить обе книги при представителях работников. Она сразу нашла странность: казна отмечает выплату на два дня раньше, чем Ратибор выставил окончательный счёт."
		"smiths_dispute:pay":
			state.state_treasury -= 8
			state.resources["tools"] = int(state.resources.get("tools", 0)) + 4
			(state.characters["zlata"] as CharacterState).remember(state.calendar.cycle, "workmen_paid", "Вы предпочли немедленно заплатить работникам, не дожидаясь спора чиновников.", {"respect": 2})
			state.facts["zlata_met"] = true
			return "Людям выдали жалованье, и горны снова зажгли. Ярина предупреждает: повторная выплата спасла заказ, но не ответила, куда ушли первые деньги."
		"smiths_dispute:seize":
			state.resources["tools"] = int(state.resources.get("tools", 0)) + 5
			(state.factions["guilds"] as FactionState).react(state.calendar.cycle, -8, "Княжеская стража изъяла товар из кузниц во время спора об оплате.")
			(state.characters["zlata"] as CharacterState).remember(state.calendar.cycle, "workshop_seizure", "Вы забрали заказ силой, пока рабочие требовали жалованье.", {"trust": -5, "resentment": 6})
			state.facts["zlata_met"] = true
			return "Стража забрала заказ без драки. К вечеру погасли почти все горны, а Ярина начала собирать владельцев мастерских на отдельное совещание."
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
			if state.facts.get("second_seal_investigation") == "public":
				return "Вы рассказали о проверке книг и о грамоте, которую уже объявили подложной. Мирон признал ответ, но спросил, почему о зерне двор сообщил только после публичного требования."
			return "Вы рассказали, какие выдачи подтверждены, а каких расписок не хватает. Мирон признал, что это ответ, но попросил назначить день, когда писцы покажут расчёт старшинам."
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
			if state.facts.get("temple_food_line") == "open_pots":
				state.public_order = mini(100, state.public_order + 2)
				return "Оцепление закрыли. Списки на казённой кухне заменили обходом дворов, как просил Лука. Пища дошла и до семей, которых не успели записать в приход. Лавочники всё ещё требуют открыть улицу."
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
			return "Адела уехала с детьми под видом паломничества. Во дворце никто не знает точного места, но отсутствие наследника скоро заметят послы и знать."
		"family_warning:double_guard":
			state.facts["family_security"] = "new_guard"
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "palace_guard_replaced", "Вы потребовали заменить его людей во внутренних покоях после провала охраны.", {"respect": -2, "resentment": 3})
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "family_guarded", "Вы оставили семью рядом, но полностью сменили внутреннюю охрану.", {"trust": 2})
			return "Ночную смену разоружили прямо во дворе. У одного стражника нашли серебро северной чеканки; он клянётся, что получил его за карточный долг."
		"family_warning:bait":
			state.facts["family_security"] = "child_bait"
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "son_used_as_bait", "Вы сознательно оставили сына приманкой для человека, проникшего во дворец.", {"trust": -10, "affection": -5, "resentment": 7})
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "nursery_trap", "Вы позволили ему устроить ловушку во внутренних покоях.", {"trust": 3})
			return "Всеволоду велели вести себя как обычно. Ночью за восковой фигуркой пришла дворцовая прачка; при задержании она назвала имя Вардана и попросила защитить её сына. Адела не простила способ, которым добыто признание."
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
			(state.characters["radomir"] as CharacterState).remember(state.calendar.cycle, "ledger_confidence", "Вы включили его в узкий круг, решающий судьбу старой сети.", {"trust": 4})
			if _family_away(state):
				return "Марек составил список получателей. Радомир узнал имя северного офицера, которого встречал на прошлой войне. Копию для Аделы оставили в замке, чтобы не выдавать её укрытие."
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "ledger_confidence", "Вы доверили ей опасную правду о наследии отца.", {"trust": 5})
			return "Марек составил список живых получателей. Адела заметила, что три выплаты совпадают с поездками Вардана, а Радомир узнал имя северного офицера, которого встречал на прошлой войне."
		"fathers_ledger:continue_scheme":
			state.facts["fathers_ledger"] = "network_reactivated"
			state.state_treasury = maxi(0, state.state_treasury - 6)
			if COURT_AUTHORITY.is_present(state, "borin"):
				(state.characters["borin"] as CharacterState).remember(state.calendar.cycle, "secret_fund", "Вы поручили ему возобновить скрытые выплаты из старой книги.", {"trust": 5, "respect": 3})
			var clerk := "Борин" if COURT_AUTHORITY.is_present(state, "borin") else "Дежурный писец"
			return "%s отправил первые шесть монет старым путём. Один адресат ответил условной фразой отца: сеть ещё жива, но её участники теперь знают, что вы приняли правила прежнего князя." % clerk
		"aglaia_invitation:attend":
			state.facts["aglaia_evening"] = "attended"
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "private_evening", "Вы приняли риск и пришли лично слушать людей Вардана.", {"trust": 5, "affection": 3})
			if _family_away(state):
				return "За игрой в кости управляющий Вардана проговорился: северный обоз ждёт сигнала из столицы. Утром Марек предупредил, что выезд из дома Аглаи заметили. До Аделы, которой сейчас нет в городе, этот слух ещё не дошёл."
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "night_absence", "Вы солгали об отсутствии и провели закрытый вечер в доме Аглаи.", {"trust": -5, "resentment": 3})
			return "За игрой в кости управляющий Вардана проговорился: северный обоз ждёт сигнала из столицы, а не наоборот. Аглая отвела вас через задний двор. Утром Адела спросила, почему ваша дорожная обувь пахнет благовониями Семи фонарей."
		"aglaia_invitation:agent":
			state.facts["aglaia_evening"] = "agent_sent"
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "agent_received", "Вы не пришли сами, но доверили ей принять вашего наблюдателя.", {"respect": 3})
			return "Человек Марека услышал условную фразу о колоколах и речных складах, но северные купцы заметили его вопросы. Сведения получены; Вардан, вероятно, знает о слежке."
		"aglaia_invitation:decline":
			state.facts["aglaia_evening"] = "family_evening"
			(state.characters["aglaia"] as CharacterState).remember(state.calendar.cycle, "invitation_declined", "Вы прямо отказались от личного визита, не пытаясь использовать её дом.", {"respect": 2})
			if str(state.facts.get("family_security", "")) in ["country_cloister", "breached"]:
				(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "letter_to_family", "Вместо визита к Аглае вы написали ей и детям.", {"trust": 2})
				return "Вы отказались от вечера и написали Аделе и детям. Письмо оставили у сестры: ей известен безопасный путь передачи. Люди Вардана тем временем закончили встречу без ваших свидетелей."
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "family_evening", "В опасный вечер вы остались с ней и детьми, не превращая семью в остаток свободного времени.", {"trust": 4, "affection": 4})
			return "Вы впервые за несколько недель ужинали с детьми без раскрытых донесений на столе. Политические сведения потеряны, зато Адела сама рассказала о слуге, который расспрашивал Всеволода о распорядке охраны."
		"vardan_offer:accept":
			state.facts["vardan_stance"] = "inside_council"
			state.facts["second_seal_custody"] = "crown"
			state.facts.erase("second_seal_holder")
			(state.characters["vardan"] as CharacterState).remember(state.calendar.cycle, "council_bargain", "Вы признали его силу и дали место у власти вместо суда.", {"respect": 8, "trust": 3})
			(state.characters["spouse"] as CharacterState).remember(state.calendar.cycle, "vardan_accepted", "Вы дали Вардану место в совете. Я всё ещё хочу знать, как к нему попала печать.", {"trust": -7, "resentment": 5})
			return "Вардан вернул печать при свидетелях и занял кресло советника по речной торговле. Его люди прекратили вывоз зерна, но уже к вечеру к нему потянулись просители, прежде ожидавшие княжеской аудиенции."
		"vardan_offer:counterfeit":
			state.facts["vardan_stance"] = "false_bargain"
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "vardan_trap", "Вы доверили ему тайную подготовку задержания Вардана.", {"trust": 4})
			return "Вардан принял согласие и назначил обмен до следующего доклада. Дарен просит принести на встречу то, что убедит судей принять и печать, и самого Вардана."
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
				return "К рассвету склады отбиты. Связные Радомира предупредили обоз на северной дороге. Возчики успели вывести груз под прикрытие гарнизона."
			if state.facts.get("market_watch") == "inspectors":
				return "Вечерняя смена Дарена остановила первые телеги у рынка и вернула зерно под охрану. Радомир держит северные ворота, пока городская стража проверяет склады."
			return "К рассвету склады отбиты, а поддельные приказы собраны. Пока вы возвращали караулы на посты, Радомир удерживал городские ворота без новых подкреплений."
		"night_of_second_seal:border":
			state.facts["second_seal_crisis"] = "border_held"
			(state.characters["daren"] as CharacterState).remember(state.calendar.cycle, "capital_command", "Вы доверили ему охрану столицы, пока сами отправились к воротам.", {"trust": 6, "respect": 5})
			if bool(state.facts.get("radomir_handover_ready", false)):
				state.resources["grain"] = maxi(0, int(state.resources.get("grain", 0)) - 4)
				return "Северный обоз остановлен у ворот. Один из связных Радомира успел предупредить Дарена о поддельном приказе. Прежде чем загорелся речной склад, стража успела вывезти большую часть зерна."
			if state.facts.get("command_structure") == "joint" or state.facts.get("aglaia_evening") in ["attended", "agent_sent"]:
				state.resources["grain"] = maxi(0, int(state.resources.get("grain", 0)) - 7)
				if state.facts.get("command_structure") == "joint":
					return "Пока вы удерживали ворота, общий штаб остановил подмену караула: в спорной грамоте не оказалось подписи Дарена. Один склад всё же загорелся, соседний успели отстоять."
				return "Сведения из дома Аглаи пригодились. Когда зазвонили колокола, Дарен уже ждал телеги у склада и вернул часть увезённых мешков. Городские ворота остались закрыты для чужого обоза."
			state.resources["grain"] = maxi(0, int(state.resources.get("grain", 0)) - 10)
			return "Ваше появление остановило колебание гарнизона, и северный обоз не прошёл ворота. Дарен удержал дворец, но заговорщики сожгли речной склад и увели часть зерна."
		"night_of_second_seal:expose":
			state.facts["second_seal_crisis"] = "false_orders_rejected"
			if bool(state.facts.get("miron_public_witnesses", false)):
				state.public_order = mini(100, state.public_order + 8)
				return "Мирон привёл на площадь двух цеховых старшин. Они показали, какие распоряжения получали раньше, и при всех сверили их с ночными приказами. Даже те, кто не поверил княжескому глашатаю, отнесли ложные грамоты старшинам и оставили склады под охраной."
			var miron := state.characters["miron"] as CharacterState
			var miron_support := miron.respect >= 8 and miron.grievance < 8
			if miron_support:
				state.public_order = mini(100, state.public_order + 8)
				if not _has_full_ledger(state):
					return "Мирон потребовал принести ночные грамоты на площадь. Горожане сравнили их с теми, что получали накануне, и цеховые старшины вернули охрану на склады. Об отцовских выплатах Мирон пока просит говорить только то, что подтверждается уцелевшими листами."
				return "Мирон прочитал имена из книги на Рыночной площади, а цеховые старшины отказались выполнять приказы со второй печатью. Заговор лишился толпы и укрытий; у ворот ещё идёт бой, но столица выбрала сторону."
			if bool(state.facts.get("second_seal_order_proof", false)):
				state.public_order = mini(100, state.public_order + 2)
				return "Марек разложил на столе ночные приказы и копию реестра. Старшины увидели, что номера повторяются, а писец, чьё имя стояло под приказом, в тот день был в отъезде. Склады остались под охраной. О старых платежах княжеского дома спорят до утра."
			if state.facts.get("market_watch") == "neighbors":
				state.public_order = mini(100, state.public_order + 2)
				return "Лавочники привели на площадь возчика, которого знали по караульному списку. Он показал грамоту, полученную уже после закрытия склада. Люди разобрались, какие приказы поддельные. Спор о роли вашего отца продолжался до утра."
			state.public_order = maxi(0, state.public_order - 5)
			if not _has_full_ledger(state):
				return "Глашатай зачитал ночные грамоты и уцелевшие бумаги из архива. Часть горожан вернула караулу ключи, другие говорят, что без утраченных страниц им снова предлагают поверить на слово. Склады удержали, но площадь не разошлась до утра."
			return "Книгу читали вслух прямо под колоколами. Одни горожане отказались подчиняться печати, другие увидели доказательство, что княжеский дом годами покупал их вождей. Заговор расколот, но вместе с ним расколота и площадь."
		"new_rule:law":
			state.facts["new_rule"] = "public_law"
			var miron := state.characters["miron"] as CharacterState
			if miron.grievance >= 8 or miron.trust < 0:
				miron.remember(state.calendar.cycle, "public_registry", "Вы учредили открытые слушания. Он запросил место для свидетелей от рынка.", {"respect": 4})
				return "Чрезвычайные приказы будут заносить в реестр. Первые слушания возглавят городские судьи. Мирон согласился привести свидетелей от рынка, но заявил, что не сядет за стол княжеского совета."
			(state.characters["miron"] as CharacterState).remember(state.calendar.cycle, "public_registry", "Вы согласились ограничить собственный приказ открытым реестром и судом.", {"trust": 8, "respect": 8})
			return "С нового месяца каждый чрезвычайный приказ получает номер, запись писца и подпись ответственного советника. Мирон возглавит открытые слушания, включая дела людей вашего отца."
		"new_rule:mercy":
			state.facts["new_rule"] = "conditional_amnesty"
			state.public_order = mini(100, state.public_order + 5)
			return "Глашатай обещает помилование тем, кто в течение трёх дней назовёт вербовщиков и вернёт похищенное. Первые участники уже пришли к судьям. Родные пострадавших ждут, заведут ли дело на тех, кто отдавал приказы."
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
