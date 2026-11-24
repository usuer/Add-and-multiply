extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_test_calendar_has_eighteen_cycles()
	_test_failed_spending_is_atomic()
	_test_grain_investigation_uses_delegate_method()
	_test_opening_decision_is_composite_and_atomic()
	_test_opening_decision_creates_social_memory()
	_test_followup_conversation_remembers_response()
	_test_opening_context_branches_into_second_seal_story()
	_test_story_events_unlock_and_resolve_once()
	_test_act_two_characters_remember_causal_choices()
	_test_middle_act_connects_clues_family_and_fathers_legacy()
	_test_neglected_events_and_border_branch()
	_test_campaign_generates_a_stateful_outcome()
	_test_council_appointments_affect_government()
	_test_council_candidates_have_visible_tradeoffs()
	_test_physician_changes_epidemic_outcome()
	_test_governance_policies_change_monthly_results()
	_test_governance_rules_explain_each_choice()
	_test_justice_cases_use_evidence_and_capacity()
	_test_diplomacy_prices_intelligence_and_pressure()
	_test_neighbors_have_distinct_political_interests()
	_test_development_projects_use_workers_and_complete()
	_test_army_uses_unit_specific_simultaneous_orders()
	_test_campaign_guide_tracks_real_actions()
	_test_technology_progress_and_practical_bonuses()
	_test_population_migration_and_rebellion_pressure()
	_test_ruler_overwork_causes_temporary_incapacity()
	_test_atomic_autosave_fallback()
	_test_battle_view_builds_animated_formations()
	_test_save_round_trip()
	if failures.is_empty():
		print("PASS Godot foundation: 29 checks")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_calendar_has_eighteen_cycles() -> void:
	var calendar := CampaignCalendar.new()
	var advances := 0
	while calendar.advance():
		advances += 1
	_expect(advances == 18, "Демоверсия должна содержать 18 переходов, получено %d" % advances)
	_expect(calendar.is_demo_complete(), "Календарь должен завершить демоверсию")

func _test_failed_spending_is_atomic() -> void:
	var state := WorldState.new()
	var before := state.state_treasury
	_expect(not state.spend_state(before + 1, "невозможный расход"), "Недоступный расход должен быть отклонён")
	_expect(state.state_treasury == before, "Отклонённый расход не должен менять казну")
	_expect(state.consequence_log.is_empty(), "Отклонённый расход не должен попадать в журнал")

func _test_grain_investigation_uses_delegate_method() -> void:
	var state := WorldState.new()
	_expect(state.assign_grain_investigation("captain"), "Капитан должен принимать поручение")
	_expect(not state.assign_grain_investigation("agent"), "Одно дело нельзя одновременно поручить второму человеку")
	_expect(state.grain_crisis.stage == GrainCrisis.Stage.INVESTIGATING, "Расследование должно начаться")
	state.advance_period()
	_expect(state.grain_crisis.stage == GrainCrisis.Stage.FINDINGS_READY, "Капитан должен вернуться через один цикл")
	_expect(state.grain_crisis.findings.back().contains("дорога"), "Военный должен сообщить о дороге и охране")

func _test_opening_decision_is_composite_and_atomic() -> void:
	var state := WorldState.new()
	var decision := state.opening_decision
	_expect(decision.choose_funeral("solemn"), "Должен приниматься план похорон")
	_expect(decision.choose_grain("full"), "Должен приниматься способ помощи")
	decision.choose_funding("state")
	var gold_before := state.state_treasury
	var grain_before := int(state.resources["grain"])
	_expect(decision.resolve(state), "Составное решение с достаточными ресурсами должно выполняться")
	_expect(state.state_treasury == gold_before - 12, "Казна должна оплатить церемонию и обоз")
	_expect(int(state.resources["grain"]) == grain_before - 18, "Большой обоз должен расходовать зерно")
	_expect(not decision.resolve(state), "Решение нельзя выполнить повторно")
	_expect(state.state_treasury == gold_before - 12, "Повтор не должен списывать деньги")

	var poor_state := WorldState.new()
	poor_state.family_treasury = 2
	poor_state.opening_decision.choose_funeral("grand")
	poor_state.opening_decision.choose_grain("purchase")
	poor_state.opening_decision.choose_funding("family")
	var family_before := poor_state.family_treasury
	_expect(not poor_state.opening_decision.resolve(poor_state), "Недостаток личных денег должен блокировать подпись")
	_expect(poor_state.family_treasury == family_before, "Отклонённое решение не должно менять личные средства")

func _test_opening_decision_creates_social_memory() -> void:
	var state := WorldState.new()
	var spouse: CharacterState = state.characters["spouse"]
	var sister: CharacterState = state.characters["sister"]
	var rural: FactionState = state.factions["rural"]
	var spouse_trust_before := spouse.trust
	var rural_before := rural.disposition
	state.opening_decision.choose_funeral("grand")
	state.opening_decision.choose_grain("defer")
	state.opening_decision.choose_funding("family")
	_expect(state.opening_decision.resolve(state), "Решение из личных средств должно выполняться")
	_expect(spouse.memories.size() == 2, "Супруга должна помнить похороны и расход семейных денег")
	_expect(spouse.trust < spouse_trust_before, "Расход семейных денег без отдельного согласования должен снижать доверие")
	_expect(sister.memories.size() == 1, "Сестра должна запомнить ответ голодающей области")
	_expect(rural.disposition < rural_before, "Откладывание помощи должно ухудшать отношение области")
	_expect(state.opening_decision.observed_reactions(state).size() == 3, "Игрок должен получить краткие наблюдаемые реакции")

func _test_followup_conversation_remembers_response() -> void:
	var state := WorldState.new()
	state.opening_decision.choose_funeral("solemn")
	state.opening_decision.choose_grain("partial")
	state.opening_decision.choose_funding("family")
	state.opening_decision.resolve(state)
	_expect(state.opening_followup.status == OpeningFollowup.Status.AVAILABLE, "После решения должен открыться личный разговор")
	_expect(state.opening_followup.actor_id == "spouse", "Расход семейных средств должна обсудить супруга")
	var before := (state.characters["spouse"] as CharacterState).memories.size()
	_expect(state.opening_followup.choose(state, "apologize"), "Доступный ответ должен завершать разговор")
	_expect((state.characters["spouse"] as CharacterState).memories.size() == before + 1, "Ответ должен остаться в памяти собеседника")
	_expect(not state.opening_followup.choose(state, "duty"), "Нельзя ответить в завершённом разговоре второй раз")

func _test_opening_context_branches_into_second_seal_story() -> void:
	for choice_id: String in OpeningDecision.FUNERAL_PLANS:
		_expect(not str(OpeningDecision.FUNERAL_PLANS[choice_id].get("description", "")).is_empty(), "План похорон %s должен объяснять содержание решения" % choice_id)
	for choice_id: String in OpeningDecision.GRAIN_RESPONSES:
		_expect(not str(OpeningDecision.GRAIN_RESPONSES[choice_id].get("description", "")).is_empty(), "Ответ области %s должен объяснять практический смысл" % choice_id)

	var delayed := WorldState.new()
	delayed.opening_decision.choose_funeral("solemn")
	delayed.opening_decision.choose_grain("defer")
	delayed.opening_decision.choose_funding("state")
	_expect(delayed.opening_decision.resolve(delayed), "Решение дождаться проверки должно выполняться")
	_expect(delayed.opening_followup.spoken_text.contains("уехали без зерна"), "Лада должна обсуждать конкретный отказ в помощи")
	_expect("verify_first" in delayed.opening_followup.response_ids, "Ответы Ладе должны соответствовать задержке обоза")

	var relieved := WorldState.new()
	relieved.opening_decision.choose_funeral("solemn")
	relieved.opening_decision.choose_grain("partial")
	relieved.opening_decision.choose_funding("state")
	_expect(relieved.opening_decision.resolve(relieved), "Частичная помощь должна выполняться")
	_expect(relieved.opening_followup.spoken_text.contains("отправляешь зерно"), "Лада должна признавать уже принятое решение о помощи")
	_expect("investigate" in relieved.opening_followup.response_ids, "После помощи разговор должен вести к расследованию недостачи")
	relieved.advance_period()
	relieved.advance_period()
	_expect("dead_prince_order" in relieved.story_timeline.available_events(relieved.calendar.cycle), "На третьем цикле должен появляться приказ с печатью умершего князя")
	_expect(relieved.story_timeline.choose(relieved, "dead_prince_order", "quiet"), "Должно быть можно начать тихое расследование второй печати")
	_expect(str(relieved.facts.get("second_seal_investigation", "")) == "quiet", "Выбор должен сохранять направление расследования")

func _test_story_events_unlock_and_resolve_once() -> void:
	var state := WorldState.new()
	_expect(state.story_timeline.available_events(state.calendar.cycle).is_empty(), "Событие не должно открываться раньше срока")
	state.advance_period()
	var available := state.story_timeline.available_events(state.calendar.cycle)
	_expect(available == ["granary_roof"], "На втором цикле должна открыться протечка амбара")
	var treasury_before := state.state_treasury
	_expect(state.story_timeline.choose(state, "granary_roof", "repair"), "Доступное событие должно принимать решение")
	_expect(state.state_treasury == treasury_before - 5, "Срочный ремонт должен оплачиваться из казны")
	_expect(not state.story_timeline.choose(state, "granary_roof", "inspect"), "Решённое событие нельзя разыграть повторно")
	_expect(state.story_timeline.available_events(state.calendar.cycle).is_empty(), "Решённое событие должно исчезать из очереди")
	var poor_state := WorldState.new()
	poor_state.state_treasury = 2
	poor_state.advance_period()
	_expect(not poor_state.story_timeline.choose(poor_state, "granary_roof", "repair"), "Недоступный платный вариант должен блокироваться")
	_expect(poor_state.state_treasury == 2, "Отклонённый вариант не должен списывать часть суммы")
	_expect(poor_state.story_timeline.choose(poor_state, "granary_roof", "inspect"), "При нехватке денег должен оставаться осмысленный бесплатный путь")

func _test_act_two_characters_remember_causal_choices() -> void:
	var workshop := WorldState.new()
	while workshop.calendar.cycle < 4:
		workshop.advance_period()
	_expect(workshop.story_timeline.choose(workshop, "smiths_dispute", "mediate"), "На четвёртом цикле должна открываться проверка оружейного двора")
	_expect(bool(workshop.facts.get("zlata_met", false)), "Проверка счетов должна знакомить игрока со Златой")
	_expect((workshop.characters["zlata"] as CharacterState).respect == 10, "Злата должна запомнить доверенную ей независимую проверку")
	workshop.facts["second_seal_investigation"] = "quiet"
	workshop.advance_period()
	_expect(bool(workshop.facts.get("missing_armory_payment", false)), "Проверка Златы должна через ход найти пропавший платёж")
	_expect(_reports_contain(workshop.story_timeline, "одной рукой"), "Отчёт Златы должен логично связать платёж с поддельным приказом")

	var letter := WorldState.new()
	while letter.calendar.cycle < 5:
		letter.advance_period()
	_expect(letter.story_timeline.choose(letter, "aglaia_letter", "deal"), "Дело письма должно позволять заключить частную сделку с Аглаей")
	_expect((letter.characters["aglaia"] as CharacterState).trust == 4, "Аглая должна помнить оказанное доверие")
	letter.advance_period()
	_expect(bool(letter.facts.get("aglaia_grey_guest", false)), "Аглая должна через ход передать обещанное имя")
	_expect(_reports_contain(letter.story_timeline, "северными монетами"), "Сведения Аглаи должны давать конкретную зацепку, а не абстрактную награду")

	var speech := WorldState.new()
	while speech.calendar.cycle < 7:
		speech.advance_period()
	_expect(speech.story_timeline.choose(speech, "market_speech", "disperse"), "Мирное собрание должно допускать силовой разгон")
	var miron := speech.characters["miron"] as CharacterState
	_expect(miron.grievance == 8 and miron.resentment == 8, "Мирон должен накапливать конкретную обиду после разгона")
	var restored := WorldState.from_data(speech.to_data())
	var restored_miron := restored.characters["miron"] as CharacterState
	_expect(restored_miron.grievance == 8, "Причина будущего конфликта Мирона должна сохраняться")
	_expect(restored.characters.size() >= WorldState.CORE_CAST.size(), "Сохранение должно содержать полный постоянный состав персонажей")

func _reports_contain(timeline: StoryTimeline, fragment: String) -> bool:
	for report: Dictionary in timeline.reports:
		if str(report.get("title", "")).contains(fragment) or str(report.get("text", "")).contains(fragment):
			return true
	return false

func _test_middle_act_connects_clues_family_and_fathers_legacy() -> void:
	var state := WorldState.new()
	state.facts["missing_armory_payment"] = true
	state.facts["aglaia_grey_guest"] = true
	while state.calendar.cycle < 9:
		state.advance_period()
	var chapel := state.story_timeline.contextual_definition(state, "savva_at_chapel")
	_expect(str(chapel.get("summary", "")).contains("оружейной ведомости") and str(chapel.get("summary", "")).contains("северные монеты"), "Встреча с Саввой должна явно собирать ранее найденные улики")
	_expect(state.story_timeline.choose(state, "savva_at_chapel", "safe_passage"), "Савве должно быть можно гарантировать безопасный допрос")
	_expect(str(state.facts.get("second_seal_holder", "")) == "vardan", "Показания Саввы должны логично вывести расследование на Вардана")
	_expect((state.characters["savva"] as CharacterState).trust == 6, "Добровольная явка должна улучшать доверие Саввы с учётом исходного отношения")
	while state.calendar.cycle < 11:
		state.advance_period()
	_expect(state.story_timeline.choose(state, "family_warning", "double_guard"), "Угроза семье должна давать защитный вариант без использования ребёнка как приманки")
	_expect(str(state.facts.get("family_security", "")) == "new_guard", "Решение по семье должно сохраняться для дальнейшей развилки")
	while state.calendar.cycle < 13:
		state.advance_period()
	_expect(state.story_timeline.choose(state, "fathers_ledger", "inner_circle"), "Книгу отца должно быть можно передать узкому кругу")
	_expect((state.characters["spouse"] as CharacterState).trust == 31, "Доверие Элины должно учитывать и охрану семьи, и доверенную тайну")
	while state.calendar.cycle < 15:
		state.advance_period()
	var offer := state.story_timeline.contextual_definition(state, "vardan_offer")
	_expect(str(offer.get("summary", "")).contains("Савва готов опровергнуть"), "Защищённый Савва должен стать живым свидетелем в сцене с Варданом")
	_expect(state.story_timeline.choose(state, "vardan_offer", "refuse"), "Игрок должен иметь возможность отказаться легализовать власть Вардана")
	while state.calendar.cycle < 17:
		state.advance_period()
	var crisis := state.story_timeline.contextual_definition(state, "night_of_second_seal")
	_expect(str(crisis.get("summary", "")).contains("не случайный налёт"), "Финальный кризис должен объяснять политическую цель нападения")
	_expect(state.story_timeline.choose(state, "night_of_second_seal", "capital"), "В финальном кризисе должно быть можно разделить командование с Радомиром")
	_expect(str(state.facts.get("second_seal_crisis", "")) == "capital_held", "Финальный выбор должен сохранять конкретный исход для эпилога")
	_expect((state.characters["radomir"] as CharacterState).trust == 32, "Доверие Радомира должно учитывать и допуск к книге отца, и самостоятельное командование границей")

func _test_neglected_events_and_border_branch() -> void:
	var neglected := WorldState.new()
	var grain_before := int(neglected.resources["grain"])
	neglected.advance_period()
	neglected.advance_period()
	neglected.advance_period()
	_expect(str((neglected.story_timeline.resolved["granary_roof"] as Dictionary).get("choice")) == "neglected", "Просроченная авария должна разрешаться сама")
	_expect(int(neglected.resources["grain"]) < grain_before, "Игнорирование крыши должно портить зерно")
	_expect(neglected.story_timeline.unread_reports().size() == 1, "Просроченное дело должно создавать постоянный отчёт")
	neglected.story_timeline.mark_reports_read()
	_expect(neglected.story_timeline.unread_reports().is_empty(), "Открытый отчёт должен отмечаться прочитанным")

	var border := WorldState.new()
	for step in range(5): border.advance_period()
	_expect(border.calendar.cycle == 6, "Пограничный гонец должен появиться на шестом цикле")
	_expect(border.story_timeline.choose(border, "border_courier", "scouts"), "Должно быть можно отправить дозор")
	border.advance_period()
	border.advance_period()
	_expect(bool(border.facts.get("northern_scouts_returned", false)), "Дозор должен вернуться через два периода")
	_expect("scout_report" in border.story_timeline.available_events(border.calendar.cycle), "Возвращение дозора должно открыть новую военную развилку")
	_expect(border.story_timeline.unread_reports().size() >= 1, "Возвращение дозора должно сопровождаться видимым отчётом")

func _test_campaign_generates_a_stateful_outcome() -> void:
	var state := WorldState.new()
	state.facts["northern_posture"] = "ambush"
	while state.advance_period():
		pass
	_expect(state.calendar.is_demo_complete(), "Кампания должна дойти до эпилога")
	_expect(state.campaign_outcome.generated, "В конце кампании должен формироваться итог")
	_expect(state.campaign_outcome.summary_lines.size() == 4, "Итог должен охватывать страну, семью, границу и распределение власти")
	_expect(state.campaign_outcome.continuation_hook.contains("ловушка"), "Пограничная стратегия должна менять зацепку продолжения")
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.campaign_outcome.generated, "Сформированный эпилог должен сохраняться")
	_expect(restored.campaign_outcome.continuation_hook == state.campaign_outcome.continuation_hook, "Вариант продолжения не должен меняться после загрузки")

func _test_council_appointments_affect_government() -> void:
	var state := WorldState.new()
	_expect(state.council.appointments["steward"] == "borin", "Княжество должно начинать с унаследованным управляющим")
	_expect(state.council.appointments["physician"] == "", "Часть должностей должна быть вакантна")
	var fatigue_before := state.ruler_fatigue
	_expect(state.council.appoint(state, "steward", "vesna"), "Совместимого кандидата можно назначить")
	_expect(not state.council.appoint(state, "marshal", "mira"), "Лекаря нельзя назначить воеводой")
	_expect(state.ruler_fatigue == fatigue_before + 2, "Кадровое решение должно расходовать внимание правителя")
	var treasury_before := state.state_treasury
	state.calendar.period = CampaignCalendar.Period.END
	state.advance_period()
	_expect(state.state_treasury == treasury_before + 11, "Состав совета должен менять месячную экономику")
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.council.appointments["steward"] == "vesna", "Назначения должны сохраняться")

func _test_council_candidates_have_visible_tradeoffs() -> void:
	for candidate_id: String in CouncilState.CANDIDATES:
		var candidate: Dictionary = CouncilState.CANDIDATES[candidate_id]
		for field in ["temperament", "strength", "risk", "connections"]:
			_expect(not str(candidate.get(field, "")).is_empty(), "У кандидата %s должно быть заполнено поле %s" % [candidate_id, field])

func _test_physician_changes_epidemic_outcome() -> void:
	var prepared := WorldState.new()
	prepared.council.appoint(prepared, "physician", "mira")
	while prepared.calendar.cycle < 10: prepared.advance_period()
	var prepared_before := prepared.public_health
	_expect(prepared.story_timeline.choose(prepared, "fever_outbreak", "clinics"), "При эпидемии можно открыть лечебницы")
	_expect(prepared.public_health == prepared_before + 8, "Опытный лекарь должен повысить эффективность лечебниц")

	var unprepared := WorldState.new()
	while unprepared.calendar.cycle < 10: unprepared.advance_period()
	var unprepared_before := unprepared.public_health
	unprepared.story_timeline.choose(unprepared, "fever_outbreak", "clinics")
	_expect(unprepared.public_health == unprepared_before + 3, "Без главы службы лечебницы должны работать хуже, но не быть бесполезными")
	_expect(prepared.story_timeline.outcome("fever_outbreak") != unprepared.story_timeline.outcome("fever_outbreak"), "Игрок должен увидеть различие в ходе лечения")

func _test_governance_policies_change_monthly_results() -> void:
	var state := WorldState.new()
	var guilds_before := (state.factions["guilds"] as FactionState).disposition
	_expect(state.policies.enact(state, "labor", "extended"), "Рабочий режим должен изменяться указом")
	_expect(not state.policies.enact(state, "labor", "extended"), "Повтор уже действующего указа должен отклоняться")
	_expect((state.factions["guilds"] as FactionState).disposition < guilds_before, "Удлинение труда должно вызывать реакцию цехов")
	state.policies.enact(state, "mobilization", "total")
	var gold_before := state.state_treasury
	var health_before := state.public_health
	var weapons_before := int(state.resources["weapons"])
	state.calendar.period = CampaignCalendar.Period.END
	state.advance_period()
	_expect(state.state_treasury == gold_before + 6, "Трудовая и мобилизационная политика должны менять доход")
	_expect(state.public_health == health_before - 2, "Удлинённый труд должен постепенно снижать здоровье")
	_expect(int(state.resources["weapons"]) == weapons_before + 4, "Всеобщая мобилизация должна ускорять вооружение")
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.policies.active["mobilization"] == "total", "Действующие правила должны сохраняться")

func _test_governance_rules_explain_each_choice() -> void:
	for category_id: String in GovernancePolicy.CATEGORIES:
		var category: Dictionary = GovernancePolicy.CATEGORIES[category_id]
		_expect(not str(category.get("sphere", "")).is_empty(), "У правила %s должна быть указана сфера" % category_id)
		_expect(not str(category.get("question", "")).is_empty(), "У правила %s должен быть понятный вопрос" % category_id)
		for option_id: String in category["options"]:
			_expect(not str((category["descriptions"] as Dictionary).get(option_id, "")).is_empty(), "Вариант %s:%s должен иметь объяснение" % [category_id, option_id])

func _test_justice_cases_use_evidence_and_capacity() -> void:
	var state := WorldState.new()
	var guilds_before := (state.factions["guilds"] as FactionState).disposition
	_expect(state.justice.judge(state, "market_thief", "release"), "Суд должен позволять освободить человека при слабых уликах")
	_expect(not state.justice.judge(state, "market_thief", "labor"), "Одно дело нельзя решить дважды")
	_expect((state.factions["guilds"] as FactionState).disposition == guilds_before - 1, "Решение суда должно вызывать объяснимую реакцию")
	state.justice.prisoners = state.justice.prison_capacity
	_expect(not state.justice.judge(state, "river_smuggler", "prison"), "Переполненная тюрьма должна блокировать заключение")
	_expect(state.justice.judge(state, "river_smuggler", "informant"), "При переполнении должен оставаться альтернативный путь")
	_expect(bool(state.facts.get("river_informant", false)), "Вербовка должна создавать разведывательный ресурс")
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.justice.informants == ["vardan"], "Осведомители должны сохраняться")

func _test_diplomacy_prices_intelligence_and_pressure() -> void:
	var state := WorldState.new()
	var grain_before := int(state.resources["grain"])
	var price_before := state.diplomacy.pack_price("velgrad", "grain")
	_expect(state.diplomacy.buy_pack(state, "velgrad", "grain"), "С соседом должна заключаться реальная товарная сделка")
	_expect(int(state.resources["grain"]) == grain_before + 10, "Сделка должна доставлять оговорённый товар")
	_expect(state.diplomacy.pack_price("velgrad", "grain") <= price_before, "Успешная торговля не должна ухудшать следующую цену")

	var weak := WorldState.new()
	weak.resources["weapons"] = 0
	weak.public_order = 0
	weak.diplomacy.threaten(weak, "velgrad")
	_expect(weak.diplomacy.last_action("velgrad") == "threat_failed", "Пустая угроза сильному соседу должна проваливаться")

	state.council.appoint(state, "intelligence", "tibor")
	_expect(state.diplomacy.spy(state, "velgrad"), "Глава тайной канцелярии должен открывать разведку")
	_expect(state.diplomacy.spy(state, "velgrad"), "Повторная разведка должна уточнять сведения")
	_expect(state.diplomacy.can_sabotage(state, "velgrad"), "Диверсия должна требовать достаточной разведки")
	_expect(state.diplomacy.sabotage(state, "velgrad"), "Подготовленная диверсия должна выполняться")
	var restored := WorldState.from_data(state.to_data())
	_expect(bool(restored.facts.get("sabotage_velgrad", false)), "Проведённая операция должна сохраняться в мире")

func _test_neighbors_have_distinct_political_interests() -> void:
	var leaders: Dictionary = {}
	for neighbor_id: String in DiplomacyState.NEIGHBORS:
		var neighbor: Dictionary = DiplomacyState.NEIGHBORS[neighbor_id]
		for field in ["leader", "goal", "fear", "character"]:
			_expect(not str(neighbor.get(field, "")).is_empty(), "У соседа %s должно быть заполнено поле %s" % [neighbor_id, field])
		leaders[str(neighbor["leader"])] = true
	_expect(leaders.size() == DiplomacyState.NEIGHBORS.size(), "У соседних государств должны быть разные правители")

func _test_development_projects_use_workers_and_complete() -> void:
	var state := WorldState.new()
	var gold_before := state.state_treasury
	_expect(state.development.start(state, "granary"), "Доступный проект должен начинаться прямо из объекта")
	_expect(state.state_treasury == gold_before - 12, "Строительство должно сразу резервировать утверждённую стоимость")
	_expect(state.development.change_workers("granary", 20), "Свободных работников можно направить на стройку")
	_expect(int(state.development.active_projects["granary"]["workers"]) == 30, "Назначение работников должно быть явным")
	for month in range(3): state.development.advance_month(state)
	_expect(not state.development.active_projects.has("granary"), "Набравший объём работ проект должен завершаться")
	_expect(state.development.levels["granary"] == 2, "Завершение должно повышать реальный уровень объекта")
	_expect(state.story_timeline.unread_reports().size() >= 1, "О завершении должен приходить постоянный отчёт")
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.development.levels["granary"] == 2, "Уровни построек должны сохраняться")

	var poor := WorldState.new()
	poor.state_treasury = 0
	var wood_before := int(poor.resources["wood"])
	_expect(not poor.development.start(poor, "school"), "Недоступное строительство должно блокироваться")
	_expect(int(poor.resources["wood"]) == wood_before, "Отклонённый проект не должен частично списывать материалы")

func _test_army_uses_unit_specific_simultaneous_orders() -> void:
	var state := WorldState.new()
	_expect(state.army.begin_border_battle("ambush"), "Пограничное решение должно запускать боевую сцену")
	_expect(state.army.status == ArmyState.BattleStatus.DEPLOYMENT, "Перед боем должна быть отдельная расстановка")
	_expect(state.army.deploy("archers", 1), "Лучников можно растянуть в одну линию")
	_expect(not state.army.deploy("archers", 4), "Глубина строя не должна выходить за сетку расстановки")
	state.army.start_combat()
	_expect(not state.army.issue_order("archers", "advance"), "Лучникам нельзя отдавать пехотную команду")
	_expect(state.army.issue_order("archers", "volley"), "Лучникам доступен прицельный залп")
	_expect(state.army.issue_order("retinue", "shield"), "Дружине доступен щитовой строй")
	_expect(not state.army.ready_to_resolve(), "Ход не должен завершаться, пока конница ждёт приказа")
	_expect(state.army.issue_order("cavalry", "flank"), "Коннице доступен обход фланга")
	var enemy_before := int(state.army.enemy["spears"]["count"]) + int(state.army.enemy["bows"]["count"])
	_expect(state.army.resolve_turn(), "Все приказы должны исполняться одним тактическим ходом")
	var enemy_after := int(state.army.enemy["spears"]["count"]) + int(state.army.enemy["bows"]["count"])
	_expect(enemy_after < enemy_before, "Залп и фланговый удар должны наносить видимые потери")
	_expect(state.army.battle_log.size() == 1, "Ход должен оставлять понятный журнал потерь и приказов")
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.army.battle_log.size() == 1, "Состояние незавершённого боя должно сохраняться")

func _test_campaign_guide_tracks_real_actions() -> void:
	var state := WorldState.new()
	_expect(state.guide.completed_count(state) == 0, "Новая кампания должна начинаться с понятных невыполненных целей")
	state.assign_grain_investigation("captain")
	_expect(state.guide.completed_count(state) == 1, "Поручение расследования должно автоматически закрывать соответствующую цель")
	state.council.appoint(state, "physician", "mira")
	_expect(state.guide.completed_count(state) == 2, "Назначение чиновника должно учитываться без отдельной галочки")
	state.guide.intro_seen = true
	state.guide.prologue_seen = true
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.guide.intro_seen, "Просмотр введения должен сохраняться")
	_expect(restored.guide.prologue_seen, "Сцена передачи власти должна показываться только один раз за кампанию")
	_expect(restored.guide.completed_count(restored) == 2, "Цели должны восстанавливаться из реального состояния мира")

func _test_technology_progress_and_practical_bonuses() -> void:
	var state := WorldState.new()
	_expect(state.technology.start(state, "crop_rotation"), "Школа должна начинать выбранное исследование")
	_expect(not state.technology.start(state, "sanitation"), "Нельзя вести два крупных исследования одновременно")
	for month in range(6): state.technology.advance_month(state)
	_expect("crop_rotation" in state.technology.unlocked, "Накопленные знания должны завершать исследование")
	var grain_before := int(state.resources["grain"])
	state.calendar.period = CampaignCalendar.Period.END
	state.advance_period()
	_expect(int(state.resources["grain"]) == grain_before - 2, "Аграрная технология должна уменьшать месячные потери зерна")
	var restored := WorldState.from_data(state.to_data())
	_expect("crop_rotation" in restored.technology.unlocked, "Открытые технологии должны сохраняться")

	var logistics := WorldState.new()
	logistics.technology.unlocked.append("field_logistics")
	logistics.army.begin_border_battle("fortified")
	logistics.army.supplies += logistics.technology.campaign_supply_bonus()
	_expect(logistics.army.supplies == 90, "Походные ведомости должны давать армии дополнительный провиант")

func _test_population_migration_and_rebellion_pressure() -> void:
	var stable := WorldState.new()
	stable.public_health = 80
	stable.public_order = 80
	(stable.factions["rural"] as FactionState).disposition = 20
	var stable_before := stable.population.residents
	stable.population.advance_month(stable)
	_expect(stable.population.residents > stable_before, "Безопасное и здоровое княжество должно привлекать переселенцев")

	var harsh := WorldState.new()
	harsh.public_health = 30
	harsh.public_order = 25
	(harsh.factions["rural"] as FactionState).disposition = -25
	harsh.policies.active["mobilization"] = "total"
	harsh.policies.active["labor"] = "extended"
	var harsh_before := harsh.population.residents
	for month in range(7): harsh.population.advance_month(harsh)
	_expect(harsh.population.residents < harsh_before, "Болезни, мобилизация и тяжёлый труд должны вызывать эмиграцию")
	_expect(harsh.population.rebellion_active, "Длительное высокое давление должно приводить к организованному бунту")
	_expect(harsh.story_timeline.unread_reports().size() >= 1, "Начало бунта должно сопровождаться постоянным отчётом")
	var restored := WorldState.from_data(harsh.to_data())
	_expect(restored.population.rebellion_active, "Состояние бунта должно сохраняться")

func _test_ruler_overwork_causes_temporary_incapacity() -> void:
	var state := WorldState.new()
	state.ruler_fatigue = 95
	state.ruler_health = 35
	state.advance_period()
	_expect(not state.can_govern(), "Переутомлённый князь с низким здоровьем должен временно слечь")
	_expect(state.incapacitated_periods == 2, "Болезнь должна иметь понятный срок восстановления")
	_expect(not state.council.appoint(state, "physician", "mira"), "Во время болезни нельзя лично назначать чиновников")
	_expect(state.story_timeline.unread_reports().size() >= 1, "Болезнь должна сопровождаться постоянным объяснением")
	state.advance_period()
	state.advance_period()
	_expect(state.can_govern(), "После восстановления личное управление должно возвращаться")
	_expect(state.ruler_fatigue < 75, "Вынужденный отдых должен заметно снижать усталость")
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.ruler_health == state.ruler_health, "Здоровье правителя должно сохраняться")

func _test_atomic_autosave_fallback() -> void:
	var state := WorldState.new()
	state.state_treasury = 77
	var auto_path := CampaignSaveService.AUTOSAVE_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CampaignSaveService.SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(auto_path))
	_expect(CampaignSaveService.save_campaign(state, auto_path) == OK, "Автосохранение должно записываться атомарно")
	var loaded := CampaignSaveService.load_latest()
	_expect(loaded != null and loaded.state_treasury == 77, "Автосохранение должно полностью восстанавливать состояние")
	_expect(not FileAccess.file_exists(auto_path + ".tmp"), "После успешной записи не должен оставаться временный файл")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(auto_path))

func _test_battle_view_builds_animated_formations() -> void:
	var army := ArmyState.new()
	army.begin_border_battle("ambush")
	army.start_combat()
	army.issue_order("retinue", "advance")
	army.issue_order("archers", "volley")
	army.issue_order("cavalry", "flank")
	army.resolve_turn()
	_expect(IllustratedBattleView.FRIENDLY_CELLS.size() == 3, "Боевое поле должно содержать три отдельные наши формации")
	_expect(IllustratedBattleView.ENEMY_CELLS.size() == 3, "Боевое поле должно содержать три отдельные вражеские формации")
	_expect((army.battle_log.back()["orders"] as Dictionary).get("archers") == "volley", "Анимация должна получать фактически выполненный приказ лучников")

func _test_save_round_trip() -> void:
	var state := WorldState.new()
	state.advance_period()
	state.assign_grain_investigation("agent")
	state.opening_decision.choose_funeral("modest")
	state.opening_decision.choose_grain("partial")
	state.opening_decision.choose_funding("state")
	state.opening_decision.resolve(state)
	state.story_timeline.choose(state, "granary_roof", "inspect")
	state.spend_state(7, "ремонт ворот")
	var path := "user://test_campaign.json"
	_expect(CampaignSaveService.save_campaign(state, path) == OK, "Тестовое сохранение должно записываться")
	var loaded := CampaignSaveService.load_campaign(path)
	_expect(loaded != null, "Тестовое сохранение должно загружаться")
	if loaded != null:
		_expect(loaded.calendar.cycle == state.calendar.cycle, "Цикл должен сохраняться")
		_expect(loaded.state_treasury == state.state_treasury, "Казна должна сохраняться")
		_expect(loaded.grain_crisis.delegate_id == "agent", "Назначенный расследователь должен сохраняться")
		_expect(loaded.grain_crisis.stage == GrainCrisis.Stage.INVESTIGATING, "Состояние расследования должно сохраняться")
		_expect(loaded.opening_decision.funeral_plan == "modest", "Выбор церемонии должен сохраняться")
		_expect(loaded.opening_decision.grain_response == "partial", "Выбор помощи должен сохраняться")
		_expect((loaded.characters["spouse"] as CharacterState).memories.size() == 1, "Память персонажа должна сохраняться")
		_expect((loaded.factions["rural"] as FactionState).known_reasons.size() == 1, "Причина реакции группы должна сохраняться")
		_expect(loaded.opening_followup.status == OpeningFollowup.Status.AVAILABLE, "Незавершённый личный разговор должен сохраняться")
		_expect(loaded.story_timeline.resolved.has("granary_roof"), "Решённое календарное событие должно сохраняться")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

