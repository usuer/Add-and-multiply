class_name CampaignOutcome
extends Resource

@export var generated: bool = false
@export var title: String = ""
@export var summary_lines: Array[String] = []
@export var continuation_hook: String = ""

func generate(state: WorldState) -> void:
	if generated:
		return
	generated = true
	var rural: FactionState = state.factions["rural"]
	var guilds: FactionState = state.factions["guilds"]
	var northern_posture := str(state.facts.get("northern_posture", "unprepared"))
	if rural.disposition >= 3 and guilds.disposition >= 0:
		title = "Княжество начинает отвечать вам доверием"
	elif state.state_treasury >= 90:
		title = "Казна полна, но страна ещё присматривается"
	else:
		title = "Арден удержался — ценой новых долгов"
	summary_lines.append(_realm_summary(state, rural, guilds))
	summary_lines.append(_family_summary(state))
	summary_lines.append(_border_summary(northern_posture))
	summary_lines.append(_power_summary(state))
	continuation_hook = _build_hook(state, northern_posture)

func _realm_summary(state: WorldState, rural: FactionState, guilds: FactionState) -> String:
	if str(state.facts.get("granary_roof", "")) == "collapsed":
		return "Области вступают в осень с потерей зерна: рухнувшая кровля стала для людей символом запоздалой власти."
	if rural.disposition >= 3 and guilds.disposition >= 0:
		return "Помощь области и разговор с ремесленниками создали первое, ещё хрупкое доверие к новому правлению."
	return "Столица работает, но области и цехи оценивают каждый приказ отдельно — наследованного авторитета оказалось недостаточно."

func _family_summary(state: WorldState) -> String:
	var spouse: CharacterState = state.characters["spouse"]
	if int(state.facts.get("debt_to_family", 0)) > 0:
		return "В семье помнят обещание вернуть личные средства. Оно может стать опорой доверия или первым нарушенным словом."
	if spouse.trust < 20:
		return "Элина остаётся рядом как княгиня, но всё реже говорит с вами как с мужем."
	return "Княжеская семья пережила первые месяцы без открытого раскола, хотя память об отдельных решениях никуда не исчезла."

func _border_summary(posture: String) -> String:
	match posture:
		"fortified": return "Северные переправы укреплены. Сосед видит подготовку и теперь должен решить, отступить или ударить раньше."
		"parley": return "Тайный посланник ещё не вернулся с северной встречи. Мир возможен, но его цена пока неизвестна."
		"ambush": return "Дружина скрыта у переправы. Если чужая колонна войдёт в долину, первый большой бой начнётся на выбранной вами земле."
	return "Север остался без ясной политики. Чужие лазутчики знают о княжестве больше, чем княжество — об их хозяине."

func _power_summary(state: WorldState) -> String:
	match str(state.facts.get("second_seal_crisis", "unresolved")):
		"capital_held": return "Столица удержана, но северная земля оставлена ради неё. Радомир получил самостоятельную военную власть — и теперь отвечает не только перед вами, но и перед людьми, которых спас."
		"border_held": return "Северные ворота удержаны под вашим личным командованием. В столице победу помнят вместе с дымом сгоревших складов."
		"false_orders_rejected": return "Вторая печать потеряла силу, когда люди перестали верить одному оттиску. Цена этой победы — открытая правда о тайных сделках княжеского дома."
		"command_collapsed": return "Ночь поддельных приказов показала: одной печати оказалось достаточно, чтобы власть перестала понимать саму себя."
	return "Вторая печать остаётся не просто украденной вещью, а доказательством того, что приказ действует лишь пока люди признают стоящую за ним власть."

func _build_hook(state: WorldState, posture: String) -> String:
	var crisis := str(state.facts.get("second_seal_crisis", ""))
	var vardan := str(state.facts.get("vardan_stance", ""))
	if crisis == "capital_held":
		return "Продолжение: с оставленной северной земли прибывают семьи, обвиняющие столицу в спасении за их счёт; среди беженцев скрывается человек со второй печатью."
	if crisis == "border_held":
		return "Продолжение: на пепелище речного склада найден список дворцовых чиновников. Одно имя вписано рукой человека из ближайшего семейного круга."
	if crisis == "false_orders_rejected":
		return "Продолжение: город требует суда над участниками старой сети, но северный посол предлагает обменять Вардана на мир и возвращение захваченной переправы."
	if vardan == "inside_council":
		return "Продолжение: новый советник Вардан приносит доказательство измены одного из ваших людей — и требует право лично провести допрос."
	if posture == "ambush":
		return "Продолжение: ночной колокол у переправы — ловушка захлопнулась, но в колонне замечено знамя человека, которого считали союзником вашего отца."
	if posture == "parley":
		return "Продолжение: посланник возвращается один и просит разговора без секретаря — сосед предлагает мир в обмен на имя предателя при вашем дворе."
	if int(state.facts.get("debt_to_family", 0)) > 0:
		return "Продолжение: семейный управляющий требует исполнить обещание в тот же день, когда военный совет просит чрезвычайные расходы на границу."
	return "Продолжение: среди старых бумаг отца находят карту с печатью северного соседа и пометкой: «Не доверять тому, кто принесёт её обратно»."

func to_data() -> Dictionary:
	return {"generated": generated, "title": title, "summary_lines": summary_lines.duplicate(), "continuation_hook": continuation_hook}

func load_data(data: Dictionary) -> void:
	generated = bool(data.get("generated", false))
	title = str(data.get("title", ""))
	summary_lines.assign(data.get("summary_lines", []))
	continuation_hook = str(data.get("continuation_hook", ""))
