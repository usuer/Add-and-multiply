extends RefCounted

static func entries(state: WorldState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var facts := state.facts
	if facts.get("father_warned_of_traitor", false):
		result.append(_entry("Слова отца", "Требуется проверка", "По книге обоз прошёл во вторник. Отец говорил, что мост разобрали ещё в понедельник."))
	if facts.get("bridge_receipt_found", false):
		result.append(_entry("Накладная у Восточных ворот", "Документ", "В амбаре сохранилась бумага с датой и подписью возчика. Она подтверждает запись о приёмке, но ещё не объясняет, где побывала телега."))
	match str(facts.get("bridge_testimony", "")):
		"sealed":
			result.append(_entry("Показание возчика", "Закрытое показание", "Самуил описал телегу и человека у ворот. Марек хранит запись. Имя свидетеля обещали не оглашать до суда."))
		"public":
			result.append(_entry("Объяснение возчика", "Публичное показание", "Самуил подтвердил расхождение при старшинах. Его слова известны в городе, поэтому совпадение с ними само по себе не делает новое письмо подлинным."))
	if facts.get("grain_report_read", "") != "" and not state.grain_crisis.findings.is_empty():
		result.append(_entry("Отчёт по амбарам", "Донесение", state.grain_crisis.findings.back()))
	if facts.get("second_seal_investigation") in ["quiet", "public", "guard_detained"]:
		result.append(_entry("Грамота о переводе Ильи", "Документ", "Приказ датирован утром после смерти князя. На воске малая дорожная печать. Ею обычно заверяли пропуска для обозов. Кто ею воспользовался, пока неизвестно."))
	elif facts.get("second_seal_investigation") == "trail_cold":
		result.append(_entry("Грамота о переводе Ильи", "След оборвался", "Семья писца ушла, а черновики сожгли. Показаний о том, кто готовил приказ, пока нет."))
	if facts.get("missing_armory_payment", false):
		result.append(_entry("Платёж за кузнечный заказ", "Сверка двух книг", "Ярина нашла перевод на несуществующий перевозочный двор. Запись о получателе появилась позже расчёта."))
	if facts.get("aglaia_grey_guest", false):
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

static func _entry(title: String, status: String, text: String) -> Dictionary:
	return {"title": title, "status": status, "text": text}
