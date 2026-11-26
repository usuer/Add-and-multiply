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
	if state.facts.get("second_seal_crisis") == "command_collapsed":
		title = "После ночи подложных приказов"
	elif rural.disposition >= 3 and guilds.disposition >= 0:
		title = "Княжество начинает отвечать вам доверием"
	elif state.state_treasury >= 90:
		title = "Казна полна, но страна ещё присматривается"
	else:
		title = "Арден удержался, впереди трудная осень"
	summary_lines.append(_realm_summary(state, rural, guilds))
	summary_lines.append(_family_summary(state))
	summary_lines.append(_border_summary(state))
	summary_lines.append(_power_summary(state))
	continuation_hook = _build_hook(state)

func _realm_summary(state: WorldState, rural: FactionState, guilds: FactionState) -> String:
	var result := "Столица работает, но области и цехи оценивают каждый приказ отдельно — наследованного авторитета оказалось недостаточно."
	if str(state.facts.get("granary_roof", "")) == "collapsed":
		result = "Области вступают в осень с потерей зерна. Старосты помнят, что двор так и не починил кровлю амбара."
	elif state.facts.get("granary_roof") == "water_damage":
		result = "В амбаре по-прежнему ждут плотников. Старосты помнят, сколько зерна отсырело под открытой кровлей."
	elif rural.disposition >= 3 and guilds.disposition >= 0:
		result = "В областях и цехах у нового князя появились сторонники. Пока те готовы отвечать лишь за решения, которые видели сами."
	match str(state.facts.get("grain_restitution_result", "")):
		"delivered": result += " В деревни довезли шесть мер зерна из старого обоза."
		"in_reserve": result += " Часть груза старого обоза поступила в княжеский запас."
		"registered":
			match str(state.facts.get("grain_debt_verdict", "")):
				"split": result += " Из найденного зерна три меры отдали деревням, три — в счёт старого долга."
				"villages": result += " Все шесть мер отдали деревням. Казна заплатила четыре монеты за подтверждённую работу мельницы."
				"creditor":
					result += " Все шесть мер отдали в счёт старого долга."
					match str(state.facts.get("rural_repair", "")):
						"public_receipts": result += " Деревням выдали три меры из княжеского запаса по открытым распискам."
						"winter_credit":
							if state.facts.has("autumn_grain_delivery"):
								var delivered := int(state.facts["autumn_grain_delivery"])
								match delivered:
									0: result += " На осеннюю выдачу для деревень зерна в княжеском запасе не осталось."
									3: result += " Осенью деревни первыми получили три меры зерна по грамоте."
									_: result += " Осенью по грамоте деревням выдали %d из трёх мер." % delivered
							else:
								result += " Двор и старосты подписали книгу, где за деревнями закрепили первую очередь на осеннее зерно."
						"missed": result += " К концу главы деревни так и не получили условий возмещения."
						_: result += " Ответ на требование деревень ещё предстоит дать."
				"unheard": result += " Дело о долге так и не рассмотрели. Найденное зерно осталось под печатью."
				_: result += " Найденные мешки опечатаны до решения судей о долге."
		"missed": result += " Деревни так и не получили ответа, что делать с найденным зерном."
	match str(state.facts.get("miron_grain_oversight", "")):
		"open_weighing": result += " Горожане сверили свою долю у весов."
		"ward_receipts": result += " Зерно развезли по кварталам. Две расписки ещё предстоит сверить с получателями."
	match str(state.facts.get("vardan_quay_terms", "")):
		"shared_warehouse": result += " Разгрузку на причале ведут городской писец и старшина Вардана."
		"city_only": result += " Ключи от причала остались у городского писца."
	match str(state.facts.get("fever_recovery", "")):
		"well_watch": result += " В Речном квартале проверили колодцы и пометили те, из которых нельзя брать воду."
		"bread_rosters": result += " В Речном квартале семьи с больными получили зерно на дому."
		"reopen_trade": result += " Для купцов вновь открыли погрузочную площадку в Речном квартале."
		"neglected": result += " В Речном квартале каждый двор сам решал, как помочь больным."
	match str(state.facts.get("pump_charter", "")):
		"open_plans": result += " Местным мастерам открыли чертежи Тихона для изготовления и ремонта насосов."
		"guild_license": result += " Цех заплатил казне за право делать насосы и взял на себя обслуживание уже установленного."
	return result

func _family_summary(state: WorldState) -> String:
	var result: String
	match str(state.facts.get("family_security", "")):
		"country_cloister":
			result = "Адела с детьми в загородной обители. Она ждёт, пока двор сможет объяснить, кто входил в детскую и кому поручат её охрану."
		"breached":
			result = "Адела увезла детей по своему решению. Двор всё ещё не знает, где они: она согласна говорить о возвращении только через Ладу."
		"child_bait":
			result = "Всеволод всё ещё принимает случай в детской за собственную вину. Адела просит, чтобы объяснение он услышал от вас."
			match str(state.facts.get("family_bait_repair", "")):
				"owned": result = "Всеволод услышал от вас, чьим решением было оставить его в детской. Он снова приходит к вам сам, но просит больше не давать ему тайных поручений."
				"deferred": result = "Адела объяснила Всеволоду, что он ни в чём не виноват. С вами мальчик об этом ещё не говорил."
		_:
			var spouse: CharacterState = state.characters["spouse"]
			if spouse.trust < 20:
				result = "Адела остаётся во дворце. Она обсуждает с вами безопасность детей, но личные разговоры всё чаще откладывает."
			else:
				result = "Адела и дети остаются в замке. Адела просит заранее познакомить их с теми, кто будет дежурить за дверью."
	if int(state.facts.get("debt_to_family", 0)) > 0:
		result += " Обещание вернуть семейные деньги остаётся в силе."
	match str(state.facts.get("family_guard_handoff", "")):
		"introduced": result += " Милица уже знает караульных по именам и сама относит им ключ."
		"delegated": result += " Адела знает обе смены у детской и сама утверждает замену дежурных."
	match str(state.facts.get("family_letter_reply", "")):
		"ready_to_discuss": result += " Собственного свидетеля она уже согласилась прислать к караулу."
		"awaiting_guards": result += " Условия, присланные вами в письме, она ещё не смогла проверить."
		"trust_through_lada": result += " Через Ладу вы снова начали переписываться, и место укрытия осталось в семье."
	return result

func _border_summary(state: WorldState) -> String:
	var result := _border_situation(state)
	match str(state.facts.get("northern_terms", "")):
		"joint_ledger": result += " Книги грузов обеих сторон сверили при осмотре складов."
		"sealed_manifests": result += " Арден и Марка договорились обмениваться запечатанными списками грузов."
		"refused_access": result += " Двор отказался от общего осмотра складов."
		"ignored": result += " Условия проверки остались без вашей подписи."
	var shelter := str(state.facts.get("north_shelter_result", ""))
	var waiting_place := " в укрытии у северных ворот" if shelter.is_empty() else ""
	match str(state.facts.get("north_gate_followup", "")):
		"cargo_cleared": result += " Семьи впустили первыми. Следующая смена проверила бумаги и пропустила обоз с мукой."
		"cargo_on_hold": result += " Семьи уже в городе. Обоз с мукой держат у ворот, пока сверяют противоречивые бумаги."
		"families_sheltered": result += " Обоз с мукой прошёл первым. Семьи впустили, когда свидетели подтвердили их имена."
		"families_waiting": result += " Муку пропустили в город. Семьи всё ещё ждут проверки%s." % waiting_place
		_:
			match str(state.facts.get("north_gate_relief", "")):
				"families": result += " Семьи прошли через северные ворота первыми. Обоз приняли после отдельной проверки."
				"cargo": result += " Муку пропустили в город, а семьи остались ждать проверки%s." % waiting_place
				"missed":
					result += " Семьи и обоз остались ждать у северных ворот." if shelter.is_empty() else " Обоз остался ждать у северных ворот."
	match shelter:
		"city_yard": result += " Семьям дали место в гостевом дворе и выдали хлеб."
		"outer_yard": result += " За воротами для семей отвели сухой двор и доставили туда хлеб."
		"parish_homes": result += " Семьям дали кров жители нескольких соседних приходов."
		"unassigned": result += " Семьи остались во временном укрытии без решения о жилье."
	return result

func _border_situation(state: WorldState) -> String:
	var northern_crossing := str(state.facts.get("northern_crossing", ""))
	var crisis := str(state.facts.get("second_seal_crisis", ""))
	var earlier := _battle_summary(state)
	if earlier.is_empty():
		match str(state.facts.get("northern_negotiation", "")):
			"stand_down": earlier = "После переговоров северный отряд отошёл от дороги."
			"refused": earlier = "На предложение прекратить столкновения север ответил отказом."
	var current := ""
	match northern_crossing:
		"held": current = "После ночной тревоги каменная переправа осталась за Арденом."
		"lost": current = "После ночной тревоги дальнюю переправу удерживают северяне."
		"contested": current = "После ночной тревоги обе стороны стоят у переправы. Перейти её свободно пока не может никто."
	if current.is_empty():
		match crisis:
			"capital_held", "command_collapsed": current = "После ночной тревоги дальнюю переправу удерживают северяне."
			"border_held": current = "Северный обоз не прошёл через городские ворота."
			"false_orders_rejected": current = "Городу удалось разобрать спорные приказы. С севера после тревоги ещё ждут надёжных вестей."
	if not current.is_empty():
		return current if earlier.is_empty() else "%s %s" % [earlier, current]
	if not earlier.is_empty():
		return earlier
	match str(state.facts.get("northern_posture", "")):
		"fortified": return "На северных дорогах укрепили заставы. У караулов есть приказ держать подступы, но ясного соглашения с соседом пока нет."
		"parley": return "Арден предложил тайные переговоры. Соглашение ещё не подписано."
		"ambush": return "Радомир готовил засаду у переправы. Подтверждения, что она сработала, в столице нет."
		"personally_inspected": return "После вашей поездки пограничники вернулись на заставы и теперь сверяют донесения с картой, которую привезли вы."
		"local_watch": return "На северной дороге дежурят люди местных старост. Те ждут ответа, кому сдавать оружие после тревоги."
		"mutual_inspection_offered": return "Грамота о взаимной проверке складов отправлена. До ответа старосты не знают, оставлять ли обозы под охраной."
	return "На северных дорогах нет общей службы донесений. О том, что происходит между заставами, двор по-прежнему узнаёт с опозданием."

func _battle_summary(state: WorldState) -> String:
	if bool(state.facts.get("northern_patrol_recalled", false)):
		if state.army.battle_log.is_empty():
			return "Отряд, выставленный у переправы, отозвали к воротам до первого завершённого хода боя."
		return "Первое столкновение у переправы прервал приказ вернуться к городским воротам."
	match state.army.status:
		ArmyState.BattleStatus.VICTORY:
			return "Первую вылазку северян у каменной переправы отбили."
		ArmyState.BattleStatus.DEFEAT:
			return "Первое столкновение у каменной переправы закончилось поражением дружины."
		ArmyState.BattleStatus.RETREATED:
			return "После первого боя у каменной переправы дружина отвела уцелевшие отряды к своим заставам."
		ArmyState.BattleStatus.DEPLOYMENT:
			return "По первой тревоге у каменной переправы войско вышло на позиции, но приказа начать бой не получило."
		ArmyState.BattleStatus.FIGHTING:
			return "У первого столкновения у каменной переправы так и нет подтверждённого исхода."
	return ""

func _power_summary(state: WorldState) -> String:
	var result := ""
	match str(state.facts.get("new_rule", "")):
		"public_law": result = "Совет открыл реестр приказов и назначил открытые слушания. Теперь даже княжескую печать можно оспорить по записи в книге."
		"conditional_amnesty": result = "Рядовым участникам дали срок вернуть похищенное и назвать организаторов. Прежние начальники ещё не ответили за свои приказы."
		"secret_purge": result = "Дарен ведёт закрытые разбирательства. Родные задержанных пока не могут узнать, на каком основании их увели."
		"old_order_survived": result = "Совет сменил печать, но разошёлся без нового порядка проверки. Кто отвечает за подложный приказ, так и не решили."
	if result.is_empty():
		result = _crisis_summary(state)
	var verdict: Dictionary = state.facts.get("council_verdict", {})
	if verdict.get("choice") != "handle_vardan":
		var vardan := _vardan_summary(state)
		if not vardan.is_empty():
			result += " " + vardan
	var note := str(verdict.get("epilogue", ""))
	if not note.is_empty():
		result += " " + note
	match str(state.facts.get("daren_watch_repair", "")):
		"paired_posts": result += " Ключи у ворот теперь передают при свидетелях обеих служб."
		"retained_shifts": result += " Прежние смены остались на постах до сверки книг."
	return result

func _crisis_summary(state: WorldState) -> String:
	match str(state.facts.get("second_seal_crisis", "unresolved")):
		"capital_held": return "К утру склады снова подчинились замку. Старшины требуют установить, у кого было право отдавать ночные приказы."
		"border_held": return "Северные ворота удержаны под вашим личным командованием. В столице победу помнят вместе с дымом сгоревших складов."
		"false_orders_rejected": return "На площади огласили спорные грамоты. Теперь старшины хотят знать, кто будет проверять и новые распоряжения."
		"command_collapsed": return "Приказы из дворца снова доходят до караулов. У стражи и дружины пока нет общего ответа, почему ночью они разошлись."
	return "Совет ещё не подвёл итог делу второй печати."

func _vardan_summary(state: WorldState) -> String:
	match str(state.facts.get("vardan_stance", "")):
		"inside_council": return "Вардан вернул печать и сохраняет место в совете по условиям сделки."
		"in_custody":
			if state.facts.get("second_seal_custody") == "judges":
				return "Вардан под стражей, печать передали судьям."
			return "Вардан под стражей. Обвинение ещё предстоит доказать."
		"escaped_exchange": return "После сорванного обмена Вардан скрылся. Его связи не исчезли вместе с ним."
		"released_for_hearing": return "Вардан освобождён под обязательство явиться к судьям."
		"open_enemy": return "Вардан объявлен врагом. Ареста никто не подтвердил."
		"false_bargain": return "Согласованный с Варданом обмен остался без подтверждённого итога."
	return ""

func _build_hook(state: WorldState) -> String:
	if bool(state.facts.get("court_order_exposed", false)):
		if bool(state.facts.get("court_petition_referred", false)):
			return "Судьи приняли прошение семьи погибшего чиновника. Для следующего слушания Марек оставляет рядом два экземпляра ночного реестра. В одном имя того, кто отдал приказ, вычеркнуто."
		return "У дверей совета Марек ждёт с прошением семьи погибшего чиновника. Родные просят внести в летопись имя человека, отдавшего приказ. Рядом осталось место для вашей подписи."
	var verdict: Dictionary = state.facts.get("council_verdict", {})
	match str(verdict.get("choice", "")):
		"publish_record":
			return "После оглашения старшина принёс собственный экземпляр ночной грамоты. Оттиск тот же, а имя получателя другое. Он просит выслушать его до встречи с другими старшинами."
		"handle_vardan":
			match str(state.facts.get("vardan_stance", "")):
				"released_for_hearing":
					return "Расписку Вардана положили в реестр. Под ней Марек оставил строку для свидетеля, который подтвердит его явку."
				"in_custody":
					return "Вардан прислал судьям список тех, кто присутствовал при передаче печати. Два имени перечёркнуты старой рукой. Суд просит установить, кто внёс поправку."
				"inside_council":
					return "Вардан пришёл к судьям с двумя служащими пристани. Прежде чем назвать имена, он попросил вслух прочесть условия сделки."
		"separate_claims":
			return "Когда разложили старые и новые бумаги, в обоих делах оказался один и тот же возчик. Марек просит послать за ним двух писцов и записать показания отдельно."
	match str(state.facts.get("new_rule", "")):
		"public_law":
			if state.facts.get("second_seal_custody") == "judges":
				return "Судьи кладут изъятую печать рядом с ночными грамотами. Первый вызов выписан на человека, который служил ещё вашему отцу."
			if bool(state.facts.get("bridge_receipt_found", false)):
				return "Первое открытое слушание назначили на рассвет. Судьи просят принести спасённую накладную и вызвать тех, кто строил временный настил через реку."
			return "Первое открытое слушание назначили на рассвет. Судьи начинают с зерна и просят Марека принести старые книги выдач."
		"conditional_amnesty":
			return "До конца срока амнистии к Мареку приходит лодочник. Он готов дать показания, если суд выслушает его раньше, чем родные узнают, у кого он служил."
		"secret_purge":
			return "Дарен кладёт на стол список задержанных. Марек просит расписаться за получение и оставляет у себя вторую копию."
	match str(state.facts.get("vardan_stance", "")):
		"in_custody":
			return "Из камеры Вардан просит бумагу. Он готов назвать людей, которым платил ваш отец, но требует, чтобы его выслушали при судьях."
		"escaped_exchange":
			return "На причале осталась ключевая ведомость. Её принесли во двор без последней страницы. Дарен просит охрану для человека, который видел, кто забрал лист."
	if state.facts.get("vardan_stance") == "inside_council":
		return "Новый советник Вардан принёс прошение своих людей. Он просит назвать при дворе тех, кого сделка защищает, прежде чем Дарен начнёт новые задержания."
	var posture := str(state.facts.get("northern_posture", ""))
	var ambush_waited := state.army.status in [ArmyState.BattleStatus.NONE, ArmyState.BattleStatus.DEPLOYMENT]
	var ambush_recalled := bool(state.facts.get("northern_patrol_recalled", false)) and state.army.battle_log.is_empty()
	if posture == "ambush" and (ambush_waited or ambush_recalled):
		return "На стол вернули карту Радомира, где всё ещё отмечена ловушка. Рядом положили список застав, от которых не пришло ответа."
	if str(state.facts.get("northern_crossing", "")) == "lost" or state.facts.get("second_seal_crisis") == "command_collapsed":
		var relief := str(state.facts.get("north_gate_relief", ""))
		match str(state.facts.get("north_gate_followup", "")):
			"cargo_on_hold":
				return "Староста принёс копию накладной от обозника. Марек хочет сверить её с записью караула, прежде чем распорядиться мукой."
			"families_sheltered":
				relief = "families"
		match str(state.facts.get("north_shelter_result", "")):
			"city_yard":
				return "В гостевом дворе староста записал, у кого за переправой остались родные. Он просит помочь передать им письма."
			"outer_yard":
				return "В сухом дворе за воротами семьям раздали хлеб. Писарь просит старосту привести свидетелей, чтобы закончить проверку."
			"parish_homes":
				return "Староста принёс списки семей, которых приняли в приходах. Теперь он просит договориться, как передавать им вести с севера."
		match relief:
			"families":
				return "Семьи с северной дороги уже в городе. Староста принёс список прибывших и просит помочь им найти кров на зиму."
			"cargo":
				return "Пекари, принявшие муку, готовы отправить хлеб семьям в укрытии у северных ворот. Они просят записать, за чей счёт его испекут."
		return "Семьи с северной дороги просят пропустить их в город. У пограничных ворот с ними спорит чиновник: в его книге эти дворы всё ещё числятся у переправы."
	if state.facts.get("second_seal_crisis") == "border_held":
		return "Смотритель речного склада принёс уцелевшую книгу караула. Одного из подписавших ночной приказ он видел в городе уже после тревоги."
	if posture == "parley":
		match str(state.facts.get("northern_negotiation", "")):
			"stand_down":
				return "Старосты принесли первую просьбу после отхода северного отряда. Они хотят открыть дорогу к зимней ярмарке и спрашивают, кто ответит за обещанную безопасность."
			"refused":
				return "У Марека остался письменный отказ. Староста последней северной заставы просит решить, эвакуировать ли семьи перед холодами."
		return "Посланник вернулся с устным ответом. Сосед готов обсуждать мир, если Арден сначала назовёт человека, который обещал пропустить северный обоз."
	if str(state.facts.get("family_security", "")) in ["country_cloister", "breached"]:
		return "Лада принесла письмо, в котором Адела перечислила условия возвращения детей. Первое она просит прочитать вслух при начальниках обеих страж."
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
