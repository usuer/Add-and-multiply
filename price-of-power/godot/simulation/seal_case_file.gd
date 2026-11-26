extends RefCounted

static func entries(state: WorldState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var facts := state.facts
	if facts.get("father_warned_of_traitor", false):
		result.append(_entry("Слова отца", "Требуется проверка", "Старый обоз с зерном числится прошедшим по мосту в Долинную область во вторник. Отец говорил, что доски с моста сняли ещё в понедельник. Если он прав, запись о маршруте требует проверки."))
	if facts.get("bridge_receipt_found", false):
		result.append(_entry("Накладная у Восточных ворот", "Документ", "В спасённой из амбара накладной сказано, что обоз приняли у Восточных ворот во вторник. Подпись возчика Самуила даёт возможность его расспросить. Попало ли зерно в деревни, в накладной не сказано."))
	match str(facts.get("bridge_testimony", "")):
		"sealed":
			result.append(_entry("Показание возчика", "Закрытое показание", "Самуил описал телегу и человека у ворот. Марек хранит запись. Имя свидетеля обещали не оглашать до суда."))
		"public":
			result.append(_entry("Объяснение возчика", "Публичное показание", "Самуил подтвердил расхождение при старшинах. Его слова известны в городе, поэтому совпадение с ними само по себе не делает новое письмо подлинным."))
	var grain_restitution := _grain_restitution_entry(str(facts.get("grain_restitution_result", "")), str(facts.get("grain_debt_verdict", "")))
	if not grain_restitution.is_empty():
		result.append(grain_restitution)
	if facts.get("grain_report_read", "") != "" and not state.grain_crisis.findings.is_empty():
		result.append(_entry("Отчёт по амбарам", "Донесение", state.grain_crisis.findings.back()))
	if facts.get("second_seal_investigation") in ["quiet", "public", "guard_detained"]:
		result.append(_entry("Грамота о переводе Ильи", "Документ", "Приказ датирован утром после смерти князя. На воске малая дорожная печать. Ею обычно заверяли пропуска для обозов. Кто ею воспользовался, пока неизвестно."))
	elif facts.get("second_seal_investigation") == "trail_cold":
		result.append(_entry("Грамота о переводе Ильи", "След оборвался", "Семья писца ушла, а черновики сожгли. Показаний о том, кто готовил приказ, пока нет."))
	if facts.get("missing_armory_payment", false):
		var payment := "Ярина нашла перевод на несуществующий перевозочный двор. Запись о получателе появилась позже расчёта."
		if facts.get("armory_order_mark_similarity", false):
			payment += " Росчерк похож на росчерк в грамоте о переводе Ильи. Это сходство не устанавливает автора."
		result.append(_entry("Платёж за кузнечный заказ", "Сверка двух книг", payment))
	if facts.get("aglaia_grey_guest", false):
		var guest_alias := str(facts.get("aglaia_guest_alias", ""))
		if not guest_alias.is_empty():
			result.append(_entry("Приезжий из дома Аглаи", "Со слов Аглаи", "Посетитель назвался торговцем по имени %s, расспрашивал о писцах и платил северными монетами. Имя и происхождение не проверены." % guest_alias))
		elif facts.get("aglaia_letter") == "statements_compared":
			result.append(_entry("Приезжий из дома Аглаи", "Два показания", "Милена и Аглая одинаково описали серый плащ приезжего, но по-разному рассказали, как он передал письмо. Писец сохранил обе версии. Имя неизвестно."))
		else:
			result.append(_entry("Приезжий из дома Аглаи", "Зацепка", "Посетитель платил северными монетами и расспрашивал о писцах. Монеты не устанавливают, от кого он пришёл."))
	if facts.get("family_letter_reply") == "trust_through_lada":
		result.append(_entry("Смена у детской", "Со слов Аделы", "Незнакомца заметили, пока двое сменщиков спорили у кухни. Их имена должен подтвердить журнал караульных смен."))
	if facts.get("second_seal_order_proof", false):
		result.append(_entry("Подложные приказы", "Подтверждено сверкой", "Марек сопоставил независимые записи. Есть основания представить судьям, какие распоряжения канцелярия не выдавала."))
	match str(facts.get("fathers_ledger", "")):
		"stolen_page":
			result.append(_entry("Архив старого князя", "Часть утрачена", "Последняя страница вырвана. Уцелевшие записи показывают выплаты, но не раскрывают всю цепочку получателей."))
		"published", "inner_circle", "network_reactivated":
			result.append(_entry("Книга отцовских выплат", "Документ", "В книге есть выплаты северным офицерам, старостам и «В. Речному». Сам счёт не говорит, кто готовил новые приказы."))
	match str(facts.get("second_seal_custody", "")):
		"crown": result.append(_entry("Вторая печать", "Предмет возвращён", "Вардан передал печать при свидетелях. Она находится в замке."))
		"judges": result.append(_entry("Вторая печать", "В описи судей", "Печать приняли при свидетелях после задержания Вардана."))
		"unknown": result.append(_entry("Вторая печать", "Местонахождение неизвестно", "После сорванной сделки никто не подтвердил, у кого она сейчас."))
		_:
			if facts.get("second_seal_holder") == "vardan" or facts.get("savva_named_vardan", false):
				result.append(_entry("Вторая печать", "Со слов Саввы", "Савва говорит, что печать перешла к Вардану. Саму печать пока не видели."))
	if facts.has("second_seal_crisis") and facts.get("second_seal_order_proof", false):
		result.append(_entry("Перед слушаниями", "Вывод по новому делу", "По прежним платежам и ночным приказам нужны разные слушания. То, что отец платил людям Вардана, само по себе не доказывает, что он давал им право действовать после его смерти."))
	return result

static func _grain_restitution_entry(outcome: String, verdict: String) -> Dictionary:
	const TITLE := "Зерно со старого обоза"
	const EVIDENCE := "Метки на мешках и складские расписки помогли найти у реки шесть мер из груза старого обоза."
	match outcome:
		"delivered": return _entry(TITLE, "Доставка подтверждена", EVIDENCE + " Старосты расписались за зерно в деревнях.")
		"in_reserve": return _entry(TITLE, "Принято в запас", EVIDENCE + " Княжеский амбар записал зерно в свои запасы.")
		"registered":
			match verdict:
				"split": return _entry(TITLE, "Разделено по решению суда", EVIDENCE + " По решению суда деревням выдали три меры, ещё три отдали в счёт старого долга.")
				"villages": return _entry(TITLE, "Выдано деревням по решению суда", EVIDENCE + " Деревни получили все шесть мер. Казна выплатила четыре монеты за подтверждённую работу мельницы.")
				"creditor": return _entry(TITLE, "Выдано в счёт долга", EVIDENCE + " Все шесть мер получил держатель долговой расписки. Просьбу деревень о возмещении отложили.")
				"unheard": return _entry(TITLE, "Слушание не состоялось", EVIDENCE + " Документы приняли, зерно осталось под печатью. Распоряжение о выдаче так и не поступило.")
			return _entry(TITLE, "Передано на рассмотрение", EVIDENCE + " Судьи оставили мешки под печатью и приняли документы по спору о долге.")
		"missed": return _entry(TITLE, "Распоряжение не принято", EVIDENCE + " Канцелярия не получила решения, куда передать зерно.")
	return {}

static func _entry(title: String, status: String, text: String) -> Dictionary:
	return {"title": title, "status": status, "text": text}
