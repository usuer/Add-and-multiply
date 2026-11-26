extends SceneTree

const LOCATION_CATALOG := preload("res://world/location_catalog.gd")
const CITY_MAP := preload("res://world/illustrated_capital_map.gd")
const COURT_AUTHORITY := preload("res://simulation/court_authority.gd")
const SEAL_CASE_FILE := preload("res://simulation/seal_case_file.gd")
const FAMILY_CORRESPONDENCE := preload("res://simulation/family_correspondence.gd")
const COUNCIL_VERDICT := preload("res://simulation/council_verdict.gd")

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
	_test_every_story_choice_has_working_outcome()
	_test_story_history_preserves_choices_and_results()
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
	_test_location_conversations_are_stateful()
	_test_campaign_conversation_payoffs()
	_test_finale_resolves_before_epilogue()
	_test_delayed_border_reply_keeps_decision_window()
	_test_personal_choices_follow_location_and_health()
	_test_location_content_references()
	_test_city_dilemmas_offer_distinct_free_choices()
	_test_period_report_tracks_actual_changes()
	_test_questions_do_not_replace_decisions()
	_test_forge_request_changes_the_grain_route()
	_test_opening_evidence_creates_a_distinct_branch()
	_test_recovered_grain_reaches_its_chosen_destination_once()
	_test_grain_debt_hearing_has_distinct_settlements_and_deadlines()
	_test_authority_changes_cast_and_records_fallout()
	_test_opening_promises_have_followthrough()
	_test_exchange_resolves_before_the_crisis()
	_test_fighting_and_recall_have_distinct_endings()
	_test_diplomacy_and_workshop_issue_actual_reports()
	_test_case_file_only_contains_discovered_evidence()
	_test_renaming_preserves_save_roles_and_existing_text()
	_test_family_correspondence_tracks_promises_and_safeguards()
	_test_family_conversations_close_with_different_outcomes()
	_test_council_hearing_requires_evidence_to_keep_vardan_in_custody()
	_test_council_hearing_separates_charges_and_records_inaction()
	_test_late_audiences_reach_the_epilogue()
	_test_save_round_trip()
	if failures.is_empty():
		print("PASS Godot foundation: 56 checks")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_location_conversations_are_stateful() -> void:
	var state := WorldState.new()
	var people: Array[String] = state.conversations.people_at("castle", state)
	_expect(people == ["spouse", "sister", "secretary", "borin"], "В тронном зале должны находиться четыре постоянных собеседника")
	var trust_before := (state.characters["spouse"] as CharacterState).trust
	var response: String = state.conversations.choose(state, "spouse", "share")
	_expect(not response.is_empty(), "Личный разговор должен возвращать осмысленный ответ")
	_expect((state.characters["spouse"] as CharacterState).trust == trust_before + 2, "Разговор должен менять отношение персонажа")
	_expect("share" not in state.conversations.available_options("spouse"), "Обсуждённая тема не должна сразу повторяться")
	var restored := WorldState.from_data(state.to_data())
	_expect("share" not in restored.conversations.available_options("spouse"), "Память разговора должна сохраняться вместе с кампанией")
	_expect(restored.conversations.last_response("spouse") == response, "Повторная встреча после загрузки должна напоминать последний ответ")
	_expect(state.conversations.people_at("temple", state) == ["chaplain"], "До встречи в храме должен быть только настоятель")
	state.facts["savva_fate"] = "in_guard_custody"
	_expect("savva" not in state.conversations.people_at("temple", state), "Арестованный Савва не должен появляться во дворе храма")
	state.facts["savva_fate"] = "voluntary_witness"
	_expect("savva" in state.conversations.people_at("temple", state), "Добровольный свидетель должен быть доступен после встречи")
	state.facts["vardan_stance"] = "open_enemy"
	_expect(state.conversations.people_at("embassy", state) == ["envoy"], "Объявленный враг не должен ждать князя во дворе послов")
	state.facts["vardan_stance"] = "inside_council"
	_expect("vardan" in state.conversations.people_at("embassy", state), "После сделки Вардан должен быть доступен для разговора")
	_expect(state.conversations.choose(state, "aglaia", "guest").is_empty(), "Нельзя обсуждать приезжего до получения зацепки")
	state.facts["aglaia_grey_guest"] = true
	_expect(not state.conversations.choose(state, "aglaia", "guest").is_empty(), "Полученная зацепка должна открывать вопрос о приезжем")

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
	var roof := relieved.story_timeline.contextual_definition(relieved, "granary_roof")
	_expect(str(roof["summary"]).contains("уже довезли"), "Протечка должна угрожать оставшемуся запасу после доставки обоза")
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
	_expect(bool(workshop.facts.get("zlata_met", false)), "Проверка счетов должна знакомить игрока со Яриной")
	_expect((workshop.characters["zlata"] as CharacterState).respect == 10, "Ярина должна запомнить доверенную ей независимую проверку")
	var missing_order := WorldState.from_data(workshop.to_data())
	missing_order.facts["second_seal_investigation"] = "trail_cold"
	missing_order.advance_period()
	_expect(missing_order.facts.get("missing_armory_payment", false) and not _reports_contain(missing_order.story_timeline, "одной рукой"),
		"Без копии грамоты Ярина может найти платёж, но Мареку не с чем сверить росчерк")
	workshop.facts["second_seal_investigation"] = "quiet"
	workshop.advance_period()
	_expect(bool(workshop.facts.get("missing_armory_payment", false)), "Проверка Ярины должна через ход найти пропавший платёж")
	_expect(_reports_contain(workshop.story_timeline, "одной рукой"), "Отчёт Ярины должен логично связать платёж с поддельным приказом")

	var letter := WorldState.new()
	while letter.calendar.cycle < 5:
		letter.advance_period()
	var compared := WorldState.from_data(letter.to_data())
	compared.story_timeline.choose(compared, "aglaia_letter", "question")
	compared.advance_period()
	_expect(str(SEAL_CASE_FILE.entries(compared)).contains("Два показания") and not compared.facts.has("aglaia_guest_alias"),
		"Раздельные показания должны раскрывать расхождение без имени приезжего")
	_expect(letter.story_timeline.choose(letter, "aglaia_letter", "deal"), "Дело письма должно позволять заключить частную сделку с Аглаей")
	_expect((letter.characters["aglaia"] as CharacterState).trust == 4, "Аглая должна помнить оказанное доверие")
	letter.advance_period()
	_expect(bool(letter.facts.get("aglaia_grey_guest", false)), "Аглая должна через ход передать обещанное имя")
	_expect(_reports_contain(letter.story_timeline, "северными монетами"), "Сведения Аглаи должны давать конкретную зацепку, а не абстрактную награду")
	var alias := str(letter.facts.get("aglaia_guest_alias", ""))
	_expect(not alias.is_empty() and str(SEAL_CASE_FILE.entries(letter)).contains(alias), "Имя со слов Аглаи должно попадать в досье")

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
	state.advance_period()
	_expect(state.calendar.cycle == 12 and state.story_timeline.choose(state, "tikhon_pump", "field_test"), "Пустой период должен быть заполнен практическим испытанием Тихона")
	_expect(str(state.facts.get("tikhon_pump", "")) == "field_tested", "Испытание изобретения должно давать измеримый, но не идеальный результат")
	while state.calendar.cycle < 13:
		state.advance_period()
	_expect(state.story_timeline.choose(state, "fathers_ledger", "inner_circle"), "Книгу отца должно быть можно передать узкому кругу")
	_expect((state.characters["spouse"] as CharacterState).trust == 31, "Доверие Аделы должно учитывать и охрану семьи, и доверенную тайну")
	state.advance_period()
	_expect(state.calendar.cycle == 14 and state.story_timeline.choose(state, "aglaia_invitation", "decline"), "Личный соблазн должен позволять осознанно выбрать семью вместо разведывательной выгоды")
	_expect((state.characters["spouse"] as CharacterState).trust == 35, "Проведённый с семьёй вечер должен быть значимым для отношений, а не пустой кнопкой")
	while state.calendar.cycle < 15:
		state.advance_period()
	var offer := state.story_timeline.contextual_definition(state, "vardan_offer")
	_expect(str(offer.get("summary", "")).contains("Савва готов опровергнуть"), "Защищённый Савва должен стать живым свидетелем в сцене с Варданом")
	_expect(state.story_timeline.choose(state, "vardan_offer", "refuse"), "Игрок должен иметь возможность отказаться легализовать власть Вардана")
	state.advance_period()
	_expect(state.calendar.cycle == 16 and state.story_timeline.choose(state, "divided_command", "joint"), "Перед кризисом игрок должен сам определить цепь командования")
	while state.calendar.cycle < 17:
		state.advance_period()
	var crisis := state.story_timeline.contextual_definition(state, "night_of_second_seal")
	_expect(str(crisis.get("summary", "")).contains("не случайный налёт") and str(crisis.get("summary", "")).contains("двумя подписями"), "Финальный кризис должен объяснять цель нападения и учитывать выбранную цепь командования")
	_expect(state.story_timeline.choose(state, "night_of_second_seal", "capital"), "В финальном кризисе должно быть можно разделить командование с Радомиром")
	_expect(str(state.facts.get("second_seal_crisis", "")) == "capital_held", "Финальный выбор должен сохранять конкретный исход для эпилога")
	_expect((state.characters["radomir"] as CharacterState).trust == 32, "Доверие Радомира должно учитывать и допуск к книге отца, и самостоятельное командование границей")
	state.advance_period()
	_expect(state.calendar.cycle == 18 and state.story_timeline.choose(state, "new_rule", "law"), "Последний ход должен решать устройство власти после победы, а не обрываться сразу после боя")
	_expect(str(state.facts.get("new_rule", "")) == "public_law", "Финальное политическое решение должно попасть в эпилог")

func _test_every_story_choice_has_working_outcome() -> void:
	for event_id: String in StoryTimeline.DEFINITIONS:
		var event: Dictionary = StoryTimeline.DEFINITIONS[event_id]
		for choice_id: String in (event.get("choices", {}) as Dictionary):
			var state := WorldState.new()
			state.state_treasury = 999
			state.calendar.cycle = int(event.get("cycle", 1))
			if event_id == "scout_report":
				state.story_timeline.resolved["border_courier"] = {"choice": "scouts", "cycle": 6}
			if event_id == "border_consequence":
				state.story_timeline.resolved["border_courier"] = {"choice": "envoy", "cycle": 6}
			if event_id == "new_rule":
				state.story_timeline.resolved["night_of_second_seal"] = {"choice": "capital", "cycle": 17}
			if event_id == "east_gate_witness":
				state.story_timeline.resolved["granary_roof"] = {"choice": "inspect", "cycle": 2}
			if event_id == "grain_restitution":
				state.story_timeline.resolved["east_gate_witness"] = {"choice": "seal", "cycle": 4}
				state.story_timeline.resolved["savva_at_chapel"] = {"choice": "safe_passage", "cycle": 9}
			if event_id == "grain_debt_hearing":
				state.story_timeline.resolved["grain_restitution"] = {"choice": "court", "cycle": 10}
				state.facts["grain_restitution_result"] = "registered"
			_expect(state.story_timeline.choose(state, event_id, choice_id), "Ветка %s:%s должна разыгрываться без скрытой блокировки" % [event_id, choice_id])
			_expect(not state.story_timeline.outcome(event_id).is_empty(), "Ветка %s:%s должна давать понятный непосредственный итог" % [event_id, choice_id])

func _test_questions_do_not_replace_decisions() -> void:
	var state := WorldState.new()
	var reply: String = state.conversations.choose(state, "spouse", "share")
	var fatigue := state.ruler_fatigue
	var trust := (state.characters["spouse"] as CharacterState).trust
	_expect(not reply.is_empty(), "Адела должна ответить на принятое решение")
	_expect(state.conversations.choose(state, "spouse", "duty").is_empty(), "Противоположное решение после принятия первого должно блокироваться")
	_expect(not state.conversations.choose(state, "spouse", "listen").is_empty(), "Уточняющий вопрос должен остаться доступным")
	_expect(state.ruler_fatigue == fatigue and (state.characters["spouse"] as CharacterState).trust == trust,
		"Уточнение не должно тратить силы или менять отношения")
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.conversations.latest_decision("spouse").get("response") == reply, "Вопрос не должен стирать итог после загрузки")
	_expect(restored.conversations.decision_cases("spouse", restored).is_empty(), "Закрытое дело не должно открываться после загрузки")

func _test_forge_request_changes_the_grain_route() -> void:
	var state := WorldState.new()
	var cases: Array[Dictionary] = state.conversations.decision_cases("forge_master", state)
	_expect(cases.size() == 1 and str(cases[0]["brief"]).contains("ножи от плугов") and str(cases[0]["brief"]).contains("заслонка"),
		"Кузнец должен объяснить два заказа до того, как игрок выберет")
	var fatigue := state.ruler_fatigue
	_expect(state.conversations.choose(state, "forge_master", "damage").contains("дорогу к складам"), "Вопрос должен объяснять, чем может помешать поломка")
	_expect(state.ruler_fatigue == fatigue and not state.facts.has("forge_priorities"), "Уточнение не должно выбирать заказ или тратить силы")
	var dam := WorldState.from_data(state.to_data())
	var tools := WorldState.from_data(state.to_data())
	_expect(dam.conversations.choose(dam, "forge_master", "forge_water_parts").contains("заслонка поднимается"), "После ремонта плотины Глеб должен сообщить результат")
	_expect(tools.conversations.choose(tools, "forge_master", "forge_tools").contains("деревянный упор"), "После починки плугов Глеб должен сообщить, как плотники удержали заслонку")
	_expect(dam.conversations.choose(dam, "forge_master", "forge_tools").is_empty(), "Решение кузнеца нельзя заменить другим заказом")
	dam = WorldState.from_data(dam.to_data())
	_expect(dam.conversations.choose(dam, "forge_master", "forge_route_after_repair").contains("к сухим складам"), "Глеб должен помнить ремонт после загрузки")
	_expect(tools.conversations.choose(tools, "forge_master", "forge_route_after_repair").is_empty(), "В ветке с плугами нельзя узнать о несостоявшемся ремонте")
	for branch in [dam, tools]:
		branch.advance_period()
		_expect(branch.story_timeline.choose(branch, "granary_roof", "relocate"), "Из затопляемого амбара можно вывезти зерно после любого заказа")
	_expect(int(dam.resources["grain"]) - int(tools.resources["grain"]) == 2, "Проезд у плотины должен сберечь два мешка при перевозке")

func _test_opening_evidence_creates_a_distinct_branch() -> void:
	var state := WorldState.new()
	state.facts["father_warned_of_traitor"] = true
	var bridge: String = state.conversations.choose(state, "sister", "ask_bridge_closure")
	_expect(bridge.contains("понедельник") and bridge.contains("во вторник") and not state.facts.has("bridge_receipt_found"),
		"Лада должна объяснять расхождение дат, пока накладную ещё предстоит найти")
	state.advance_period()
	var repair := WorldState.from_data(state.to_data())
	state.story_timeline.choose(state, "granary_roof", "inspect")
	repair.story_timeline.choose(repair, "granary_roof", "repair")
	state.advance_period()
	repair.advance_period()
	_expect(str(state.story_timeline.contextual_definition(state, "dead_prince_order")["summary"]).contains("Восточные ворота"),
		"Улика из амбара должна менять рассказ о грамоте")
	state.advance_period()
	repair.advance_period()
	_expect("east_gate_witness" not in repair.story_timeline.available_events(4), "Путь к свидетелю должен зависеть от найденной бумаги")
	_expect(state.facts.get("granary_roof") == "water_damage" and int(state.resources["grain"]) < int(repair.resources["grain"]), "Спасение бумаги должно иметь цену при отсутствии ремонта")
	_expect(state.story_timeline.choose(state, "east_gate_witness", "seal"), "Найденного свидетеля должно быть можно выслушать")
	while state.calendar.cycle < 9:
		state.advance_period()
	_expect(state.story_timeline.choose(state, "savva_at_chapel", "safe_passage"), "После показаний должно быть можно встретиться с Саввой")
	_expect(state.facts.get("second_seal_order_proof") == true, "Независимые свидетельства должны давать альтернативный путь к доказательству")

func _test_recovered_grain_reaches_its_chosen_destination_once() -> void:
	const CASE_ID := "grain_restitution"
	var state := WorldState.new()
	state.advance_period()
	state.story_timeline.choose(state, "granary_roof", "inspect")
	while state.calendar.cycle < 4:
		state.advance_period()
	state.story_timeline.choose(state, "east_gate_witness", "seal")
	while state.calendar.cycle < 9:
		state.advance_period()
	var interrupted := WorldState.from_data(state.to_data())
	interrupted.story_timeline.choose(interrupted, "savva_at_chapel", "arrest")
	interrupted.advance_period()
	_expect(CASE_ID not in interrupted.story_timeline.available_events(10), "После ареста Саввы без сверки склад не должен появляться")
	state.story_timeline.choose(state, "savva_at_chapel", "safe_passage")
	_expect(CASE_ID not in state.story_timeline.available_events(9), "Мареку нужен период для проверки склада после встречи")
	state.advance_period()
	_expect(CASE_ID in state.story_timeline.available_events(10) and str(state.period_report["notes"]).contains("Нашли часть пропавшего зерна"),
		"Найденное зерно должно открыть дело и появиться в сводке")
	for choice_id: String in ["villages", "reserve", "court"]:
		var branch := WorldState.from_data(state.to_data())
		branch.state_treasury = 0
		var grain := int(branch.resources["grain"])
		_expect(branch.story_timeline.choose(branch, CASE_ID, choice_id), "Распоряжение должно быть доступно с пустой казной")
		_expect(not branch.facts.has("grain_restitution_result") and int(branch.resources["grain"]) == grain, "Подтверждение отправки не должно мгновенно менять запас")
		branch = WorldState.from_data(branch.to_data())
		_expect(not branch.story_timeline.choose(branch, CASE_ID, "reserve"), "Сохранённое распоряжение нельзя повторить")
		branch.advance_period()
		var expected: String = {"villages": "delivered", "reserve": "in_reserve", "court": "registered"}[choice_id]
		_expect(branch.facts.get("grain_restitution_result") == expected, "Каждый из трёх приказов должен дать собственный итог")
		_expect(int(branch.resources["grain"]) == grain + (6 if choice_id == "reserve" else 0), "Только решение об амбаре увеличивает княжеский запас")
		_expect(str(SEAL_CASE_FILE.entries(branch)).contains("Зерно со старого обоза"), "В досье должен остаться фактический исход")
		var report_count := branch.story_timeline.reports.filter(func(report: Dictionary) -> bool: return report["title"] == "Что стало с зерном с речного склада").size()
		branch.advance_period()
		_expect(report_count == 1 and branch.story_timeline.reports.filter(func(report: Dictionary) -> bool: return report["title"] == "Что стало с зерном с речного склада").size() == 1,
			"Донесение по одному приказу должно появиться ровно один раз")
	while state.calendar.cycle < 18:
		state.advance_period()
	var older_save := WorldState.from_data(state.to_data())
	_expect(older_save.story_timeline.choose(older_save, CASE_ID, "villages"), "Позднее сохранение должно позволять распорядиться зерном до конца главы")
	older_save.advance_period()
	_expect(str(older_save.campaign_outcome.summary_lines).contains("довезли шесть мер зерна"), "Последнее распоряжение должно успеть попасть в эпилог")
	state.advance_period()
	_expect(state.facts.get("grain_restitution_result") == "missed", "При пропуске до конца главы мешки должны выйти из распоряжения двора")

func _test_grain_debt_hearing_has_distinct_settlements_and_deadlines() -> void:
	const HEARING := "grain_debt_hearing"
	var state := WorldState.new()
	while state.calendar.cycle < 10:
		state.advance_period()
	state.story_timeline.resolved["east_gate_witness"] = {"choice": "seal", "cycle": 4}
	state.story_timeline.resolved["savva_at_chapel"] = {"choice": "safe_passage", "cycle": 9}
	var late := WorldState.from_data(state.to_data())
	var direct := WorldState.from_data(state.to_data())
	direct.story_timeline.choose(direct, "grain_restitution", "villages")
	direct.advance_period()
	direct.advance_period()
	_expect(HEARING not in direct.story_timeline.available_events(12), "Прямая выдача не должна открывать суд о ещё опечатанном зерне")
	state.story_timeline.choose(state, "grain_restitution", "court")
	state.advance_period()
	_expect(state.facts.get("grain_restitution_result") == "registered" and HEARING not in state.story_timeline.available_events(11), "Сначала судьи должны принять зерно и проверить расписку")
	state = WorldState.from_data(state.to_data())
	state.advance_period()
	_expect(HEARING in state.story_timeline.available_events(12) and state.story_timeline.deadline_cycle(HEARING) == 18,
		"Слушание должно открыться после проверки и оставаться доступным до эпилога")
	_expect(str(state.period_report["notes"]).contains("Кому отдать зерно со спорного склада"), "Сводка должна сообщить о готовности судей")
	for option: String in ["split", "villages", "creditor"]:
		var branch := WorldState.from_data(state.to_data())
		branch.state_treasury = 0
		var rural := branch.factions["rural"] as FactionState
		var approval := rural.disposition
		var grain := int(branch.resources["grain"])
		if option == "villages":
			_expect(not branch.story_timeline.choose(branch, HEARING, option) and not branch.facts.has("grain_debt_verdict"), "Оплату при пустой казне следует блокировать без побочных эффектов")
			branch.state_treasury = 4
		_expect(branch.story_timeline.choose(branch, HEARING, option) and branch.facts.get("grain_debt_verdict") == option, "Каждое решение суда должно записывать отдельный итог")
		_expect(branch.state_treasury == 0 and int(branch.resources["grain"]) == grain, "Монеты списываются только при оплате, найденное зерно уходит сторонам")
		var impact: int = {"split": 2, "villages": 4, "creditor": -4}[option]
		_expect(rural.disposition == approval + impact, "Отношение деревень должно зависеть от их доли")
		var reloaded := WorldState.from_data(branch.to_data())
		_expect(not reloaded.story_timeline.choose(reloaded, HEARING, "split") and reloaded.facts.get("grain_debt_verdict") == option, "После загрузки решение должно сохраняться без повторной выплаты")
	while state.calendar.cycle < 19:
		state.advance_period()
	_expect(state.facts.get("grain_debt_verdict") == "unheard", "Если слушание успело открыться, пропуск должен остаться в летописи")
	while late.calendar.cycle < 18:
		late.advance_period()
	_expect(str(late.story_timeline.contextual_definition(late, "grain_restitution")["summary"]).contains("после конца лета"), "Последний период должен предупредить, что суд не успеет заслушать дело")
	late.story_timeline.choose(late, "grain_restitution", "court")
	late.advance_period()
	_expect(late.facts.get("grain_restitution_result") == "registered" and not late.facts.has("grain_debt_verdict"), "Если дело только зарегистрировали, эпилог не должен считать слушание пропущенным")

func _test_authority_changes_cast_and_records_fallout() -> void:
	var state := WorldState.new()
	state.opening_decision.choose_funeral("modest")
	state.opening_decision.choose_grain("partial")
	state.opening_decision.resolve(state)
	var occupied := state.justice.prisoners
	var custody := COURT_AUTHORITY.choose(state, "borin", "detain")
	_expect(not custody.is_empty() and state.justice.prisoners == occupied + 1, "Задержание должно занимать реальную камеру")
	_expect("borin" not in state.conversations.people_at("castle", state) and state.council.appointments["steward"] == "",
		"Задержанный казначей должен исчезнуть из зала и совета")
	_expect(not state.council.appoint(state, "steward", "borin"), "Задержанного нельзя назначить на должность")
	state.advance_period()
	_expect(_reports_contain(state.story_timeline, "Доклад судей"), "Доклад о задержании должен прийти в следующем периоде")
	COURT_AUTHORITY.choose(state, "borin", "release")
	_expect(state.justice.prisoners == occupied and "borin" in state.conversations.people_at("castle", state), "Освобождение должно вернуть персонажа в город")
	COURT_AUTHORITY.choose(state, "forge_master", "secret_removal")
	state = WorldState.from_data(state.to_data())
	state.advance_period()
	_expect("forge_master" not in state.conversations.people_at("smithy", state) and state.facts.get("court_order_exposed", false),
		"Тайный приказ должен пережить загрузку, менять состав локации и допускать огласку")

func _test_opening_promises_have_followthrough() -> void:
	var state := WorldState.new()
	state.opening_decision.choose_funeral("solemn")
	state.opening_decision.choose_grain("purchase")
	state.opening_decision.choose_funding("family")
	state.opening_decision.resolve(state)
	var reactions := state.opening_decision.observed_reactions(state)
	var local_grain := int(state.resources["grain"])
	state.opening_followup.choose(state, "promise")
	var debt := int(state.facts.get("debt_to_family", 0))
	var treasury := state.state_treasury
	var family := state.family_treasury
	_expect(debt > 0 and not state.opening_followup.settle_family_debt(state, "repay").is_empty(), "Семейное обещание должно позволять вернуть заём")
	_expect(state.state_treasury == treasury - debt and state.family_treasury == family + debt, "Выплата семейного долга должна переводить ровно сумму долга")
	state.advance_period()
	_expect(state.facts.get("opening_grain_dispatch") == "contracted", "Покупка не должна мгновенно считаться доставкой")
	state.advance_period()
	_expect(state.facts.get("opening_grain_dispatch") == "delivered" and _reports_contain(state.story_timeline, "Сарнский обоз прибыл"),
		"О прибытии купленного обоза должен сообщить отдельный отчёт")
	_expect(int(state.resources["grain"]) == local_grain and state.opening_decision.observed_reactions(state) == reactions,
		"Покупка не тратит местное зерно, поздние решения не переписывают летопись похорон")

func _test_family_correspondence_tracks_promises_and_safeguards() -> void:
	var evacuated := WorldState.new()
	while evacuated.calendar.cycle < 11:
		evacuated.advance_period()
	evacuated.story_timeline.choose(evacuated, "family_warning", "evacuate")
	_expect(FAMILY_CORRESPONDENCE.terms(evacuated).is_empty(), "Письмо не должно появляться в момент отъезда")
	evacuated.advance_period()
	var listened := WorldState.from_data(evacuated.to_data())
	_expect(not FAMILY_CORRESPONDENCE.choose(listened, "listen").is_empty(), "Уехавшую семью должно быть можно выслушать через Ладу")
	_expect(FAMILY_CORRESPONDENCE.choose(listened, "guarantee").is_empty(), "Ответ на письмо нельзя заменить другим после отправки")
	listened = WorldState.from_data(listened.to_data())
	listened.advance_period()
	_expect(listened.facts.get("family_letter_reply") == "trust_through_lada" and str(SEAL_CASE_FILE.entries(listened)).contains("Смена у детской"),
		"Выслушав Аделу, игрок получает её показание после доставки ответа")
	FAMILY_CORRESPONDENCE.choose(evacuated, "guarantee")
	evacuated.advance_period()
	_expect(evacuated.facts.get("family_letter_reply") == "awaiting_guards", "Обещание без проверяемых условий не должно возвращать семью")
	while evacuated.calendar.cycle < 16:
		evacuated.advance_period()
	evacuated.story_timeline.choose(evacuated, "divided_command", "joint")
	evacuated.advance_period()
	_expect(evacuated.facts.get("family_letter_reply") == "ready_to_discuss", "После решения о совместной проверке Адела должна пересмотреть ответ")
	_expect("spouse" not in evacuated.conversations.people_at("castle", evacuated), "Согласие на проверку не должно переносить семью во дворец")

func _test_family_conversations_close_with_different_outcomes() -> void:
	var state := WorldState.new()
	while state.calendar.cycle < 11:
		state.advance_period()
	var guards := WorldState.from_data(state.to_data())
	guards.story_timeline.choose(guards, "family_warning", "double_guard")
	_expect(not guards.conversations.choose(guards, "spouse", "introduce_guards").is_empty(), "После смены охраны князь должен иметь возможность познакомить детей с караулом")
	_expect(guards.conversations.choose(guards, "spouse", "ask_adela_to_introduce_guards").is_empty() and guards.facts.get("family_guard_handoff") == "introduced",
		"Знакомство должно закрывать противоположное распоряжение")
	_expect(not guards.conversations.choose(guards, "spouse", "new_guard_at_home").is_empty(), "Вопрос о реакции детей должен остаться доступным")
	state.story_timeline.choose(state, "family_warning", "bait")
	_expect(not state.conversations.choose(state, "spouse", "apologize_to_elina").is_empty() and state.facts.get("family_bait_repair") == "owned",
		"Последствие должно фиксировать личное признание ответственности")
	_expect(state.conversations.choose(state, "spouse", "defer_explaining_to_child").is_empty(), "Последствия разговора с ребёнком должны быть взаимоисключающими")

func _test_council_hearing_requires_evidence_to_keep_vardan_in_custody() -> void:
	var state := WorldState.new()
	while state.calendar.cycle < 14:
		state.advance_period()
	state.story_timeline.choose(state, "aglaia_invitation", "attend")
	state.advance_period()
	state.story_timeline.choose(state, "vardan_offer", "counterfeit")
	state.advance_period()
	_expect(state.facts.get("vardan_stance") == "in_custody" and not state.facts.get("second_seal_order_proof", false),
		"Вечер у Аглаи позволяет задержать Вардана даже без доказательств подделки")
	state.advance_period()
	state.story_timeline.choose(state, "night_of_second_seal", "capital")
	state.advance_period()
	_expect(COUNCIL_VERDICT.terms(state).is_empty(), "Слушание должно открываться только после принятия порядка разбирательства")
	state.story_timeline.choose(state, "new_rule", "law")
	var prisoners := state.justice.prisoners
	var restored := WorldState.from_data(state.to_data())
	restored.facts["second_seal_order_proof"] = true
	_expect(not COUNCIL_VERDICT.choose(restored, "handle_vardan").is_empty() and restored.facts.get("vardan_stance") == "in_custody" and restored.justice.prisoners == prisoners,
		"Доказанная подделка оставляет Вардана под стражей до проверки передачи печати")
	_expect(not COUNCIL_VERDICT.choose(state, "handle_vardan").is_empty() and state.facts.get("vardan_stance") == "released_for_hearing",
		"При недостатке улик Вардана отпускают под обязательство явиться")
	_expect(state.facts.get("second_seal_custody") == "judges" and state.justice.prisoners == prisoners - 1,
		"Освобождение уменьшает число задержанных и оставляет улику в описи судей")
	var reloaded := WorldState.from_data(state.to_data())
	_expect(COUNCIL_VERDICT.choose(reloaded, "publish_record").is_empty(), "После загрузки выбранное распоряжение нельзя заменить")
	reloaded.advance_period()
	_expect(str(reloaded.campaign_outcome.summary_lines).contains("Вардан освобождён до слушания"), "Книга главы должна помнить исход слушания после загрузки")

func _test_council_hearing_separates_charges_and_records_inaction() -> void:
	var state := WorldState.new()
	while state.calendar.cycle < 17:
		state.advance_period()
	state.story_timeline.choose(state, "night_of_second_seal", "capital")
	state.advance_period()
	state.story_timeline.choose(state, "new_rule", "law")
	var published := WorldState.from_data(state.to_data())
	_expect(COUNCIL_VERDICT.choose(published, "publish_record").contains("расхожд"), "Без надёжной сверки нужно огласить только расхождения")
	var petition := WorldState.from_data(state.to_data())
	petition.facts["court_order_exposed"] = true
	_expect(not COUNCIL_VERDICT.choose(petition, "separate_claims").is_empty() and petition.facts.get("court_petition_referred") == true,
		"Прошение семьи должно получить отдельную запись о княжеском приказе")
	petition.advance_period()
	_expect(petition.campaign_outcome.continuation_hook.contains("приняли прошение"), "В эпилоге должно быть видно, дошло ли прошение до судей")
	state.advance_period()
	var verdict: Dictionary = state.facts.get("council_verdict", {})
	_expect(verdict.get("choice") == "passed_over" and COUNCIL_VERDICT.terms(state).is_empty(), "Глава должна записать, если совет разошёлся без распоряжения")

func _test_late_audiences_reach_the_epilogue() -> void:
	var state := WorldState.new()
	while state.calendar.cycle < 15:
		state.advance_period()
	state.story_timeline.choose(state, "vardan_offer", "accept")
	state.advance_period()
	state.story_timeline.choose(state, "divided_command", "radomir")
	state.advance_period()
	state.story_timeline.choose(state, "night_of_second_seal", "capital")
	_expect(not state.conversations.choose(state, "miron", "weigh_grain_in_public").is_empty(), "После тревоги Мирон должен принять распоряжение о выдаче зерна")
	_expect(state.conversations.choose(state, "miron", "issue_ward_grain_receipts").is_empty(), "Выбранный порядок выдачи должен закрыть альтернативное решение")
	_expect(not state.conversations.choose(state, "daren", "pair_night_watch").is_empty(), "Дарен должен выслушать распоряжение о карауле")
	_expect(not state.conversations.choose(state, "vardan", "keep_city_quay_keys").is_empty(), "Вардан после сделки должен выслушать распоряжение о причале")
	while state.calendar.cycle < 19:
		state.advance_period()
	var ending := str(state.campaign_outcome.summary_lines)
	for detail in ["у весов", "у городского писца", "свидетелях обеих служб"]:
		_expect(ending.contains(detail), "Эпилог должен учитывать распоряжение из личного разговора: %s" % detail)

func _test_exchange_resolves_before_the_crisis() -> void:
	var base := WorldState.new()
	while base.calendar.cycle < 15:
		base.advance_period()
	var snapshots := base.to_data()
	var accepted := WorldState.from_data(snapshots)
	accepted.facts["second_seal_holder"] = "vardan"
	accepted.story_timeline.choose(accepted, "vardan_offer", "accept")
	_expect(accepted.facts.get("second_seal_custody") == "crown" and not accepted.facts.has("second_seal_holder"),
		"Возвращённая печать не должна одновременно считаться у Вардана")
	for prepared in [true, false]:
		var state := WorldState.from_data(snapshots)
		state.facts["second_seal_order_proof"] = prepared
		_expect(state.story_timeline.choose(state, "vardan_offer", "counterfeit"), "Обмен должен быть доступен по сюжету")
		state = WorldState.from_data(state.to_data())
		state.advance_period()
		var expected := "in_custody" if prepared else "escaped_exchange"
		_expect(state.facts.get("vardan_stance") == expected, "Обмен должен завершаться после загрузки, учитывая собранные улики")
		var night := state.story_timeline.contextual_definition(state, "night_of_second_seal")
		var expected_note := "под стражей" if prepared else "сорванного обмена"
		_expect(str(night["summary"]).contains(expected_note), "Кризис должен учитывать исход обмена")

func _test_fighting_and_recall_have_distinct_endings() -> void:
	var base := WorldState.new()
	while base.calendar.cycle < 17:
		base.advance_period()
	var recalled := WorldState.from_data(base.to_data())
	recalled.army.begin_border_battle("ambush")
	recalled.story_timeline.choose(recalled, "night_of_second_seal", "capital")
	_expect(recalled.facts.get("northern_patrol_recalled") == true and recalled.army.turn == 0,
		"Армия на позициях должна быть отозвана без выдуманного боя")
	var won := WorldState.from_data(base.to_data())
	won.army.begin_border_battle("ambush")
	won.army.start_combat()
	for turn in range(6):
		if won.army.status != ArmyState.BattleStatus.FIGHTING:
			break
		won.army.issue_order("retinue", "advance")
		won.army.issue_order("archers", "volley")
		won.army.issue_order("cavalry", "flank")
		won.army.resolve_turn()
	_expect(won.army.status == ArmyState.BattleStatus.VICTORY, "Победа должна быть достижима обычными приказами")
	won.story_timeline.choose(won, "night_of_second_seal", "capital")
	_expect(won.facts.get("northern_crossing") == "held" and not won.facts.get("northern_patrol_recalled", false),
		"Стратегический выбор не должен стирать выигранное столкновение")

func _test_diplomacy_and_workshop_issue_actual_reports() -> void:
	var state := WorldState.new()
	state.facts["envoy_meetings"] = "written_first"
	while state.calendar.cycle < 6:
		state.advance_period()
	state.story_timeline.choose(state, "border_courier", "envoy")
	while state.calendar.cycle < 8:
		state.advance_period()
	state.story_timeline.choose(state, "border_consequence", "reopen_talks")
	while state.calendar.cycle < 12:
		state.advance_period()
	_expect(state.facts.get("northern_negotiation") == "stand_down", "Подготовленные переговоры должны закончиться ответом соседа")
	state.story_timeline.choose(state, "tikhon_pump", "workshop")
	while state.calendar.cycle < 15:
		state.advance_period()
	_expect(state.facts.get("tikhon_pump") == "workshop_ready" and _reports_contain(state.story_timeline, "Тихон закончил"),
		"Оплата литейной должна через месяц давать готовый результат")

func _test_case_file_only_contains_discovered_evidence() -> void:
	var state := WorldState.new()
	_expect(SEAL_CASE_FILE.entries(state).is_empty(), "Папка расследования не должна заранее раскрывать зацепки")
	state.facts["father_warned_of_traitor"] = true
	state.advance_period()
	state.story_timeline.choose(state, "granary_roof", "inspect")
	var entries := SEAL_CASE_FILE.entries(state)
	_expect(entries.size() == 2 and entries[0]["status"] == "Требуется проверка" and entries[1]["status"] == "Документ",
		"Необходимо различать рассказ отца и спасённый документ")
	_expect("Вардан" not in str(entries), "К ранним уликам нельзя добавлять ещё не раскрытые имена")

func _test_renaming_preserves_save_roles_and_existing_text() -> void:
	var state := WorldState.new()
	var data := state.to_data()
	data.erase("text_revision")
	var old_spouse := WorldState.LEGACY_NAMES.find_key("Адела") as String
	var old_craftswoman := WorldState.LEGACY_NAMES.find_key("Ярина") as String
	data["characters"]["spouse"]["display_name"] = "Княгиня " + old_spouse
	data["characters"]["zlata"]["display_name"] = old_craftswoman + " Радич"
	data["opening_followup"]["spoken_text"] = old_spouse + " ждёт, когда " + old_craftswoman + " вернётся."
	var loaded := WorldState.from_data(data)
	_expect(loaded.characters["spouse"].display_name == "Княгиня Адела" and loaded.characters["zlata"].display_name == "Ярина Радич",
		"В старых сохранениях заменяются отображаемые имена, а идентификаторы остаются")
	_expect(loaded.opening_followup.spoken_text == "Адела ждёт, когда Ярина вернётся.", "Имена должны обновляться и в уже записанном диалоге")
	data["text_revision"] = 2
	data["characters"]["spouse"]["display_name"] = "Княгиня Анна"
	data["opening_followup"]["spoken_text"] = "Лада отвезёт письмо Анне."
	var previous_revision := WorldState.from_data(data)
	_expect(previous_revision.characters["spouse"].display_name == "Княгиня Адела" and previous_revision.opening_followup.spoken_text == "Лада отвезёт письмо Аделе.",
		"Предыдущий вариант имени и его падежи тоже должны обновляться при загрузке")

func _test_campaign_conversation_payoffs() -> void:
	var state := WorldState.new()
	while state.calendar.cycle < 3:
		state.advance_period()
	_expect(state.conversations.pending_story_topics(state).is_empty(), "Марек не должен звать на разговор до решения о печати")
	_expect(state.story_timeline.choose(state, "dead_prince_order", "quiet"), "Тихая проверка должна открыть разговор с Мареком")
	_expect(not state.conversations.choose(state, "secretary", "keep_copy").is_empty(), "Марек должен подготовить копию книги")
	while state.calendar.cycle < 6:
		state.advance_period()
	state.story_timeline.choose(state, "border_courier", "envoy")
	_expect(not state.conversations.choose(state, "radomir", "handover").is_empty(), "Радомир должен подготовить связных")
	state.advance_period()
	state.story_timeline.choose(state, "market_speech", "listen")
	_expect(not state.conversations.choose(state, "miron", "public_witnesses").is_empty(), "После встречи на площади Мирон должен найти свидетелей")
	while state.calendar.cycle < 9:
		state.advance_period()
	state = WorldState.from_data(state.to_data())
	state.story_timeline.choose(state, "savva_at_chapel", "arrest")
	_expect(bool(state.facts.get("second_seal_order_proof", false)), "Копия Марека должна сохранить проверяемую улику после исчезновения сумки Саввы")
	while state.calendar.cycle < 17:
		state.advance_period()
	var night := state.story_timeline.contextual_definition(state, "night_of_second_seal")
	_expect(str(night["summary"]).contains("Связные") and str(night["summary"]).contains("цеховых старшин"), "Подготовка в городе должна быть заметна во время кризиса")
	var border := WorldState.from_data(state.to_data())
	var grain := int(border.resources["grain"])
	_expect(border.story_timeline.choose(border, "night_of_second_seal", "border"), "Оборона границы должна разрешаться")
	_expect(int(border.resources["grain"]) == maxi(0, grain - 4), "Связные должны уменьшить потери зерна")
	var without_witnesses := WorldState.from_data(state.to_data())
	without_witnesses.facts.erase("miron_public_witnesses")
	(without_witnesses.characters["miron"] as CharacterState).respect = 0
	without_witnesses.story_timeline.choose(without_witnesses, "night_of_second_seal", "expose")
	_expect(without_witnesses.story_timeline.outcome("night_of_second_seal").contains("копию реестра"), "Улика Марека должна влиять на огласку и без поддержки Мирона")
	(state.characters["miron"] as CharacterState).respect = 0
	_expect(state.story_timeline.choose(state, "night_of_second_seal", "expose"), "У игрока должна оставаться возможность обнародовать улики")
	_expect(state.story_timeline.outcome("night_of_second_seal").contains("двух цеховых старшин"), "Свидетели должны изменить исход даже при низком уважении Мирона")

func _test_finale_resolves_before_epilogue() -> void:
	var state := WorldState.new()
	while state.calendar.cycle < 18:
		state.advance_period()
	_expect("new_rule" not in state.story_timeline.available_events(18), "Совет о послевоенном устройстве не должен открываться до исхода кризиса")
	state.advance_period()
	_expect(state.campaign_outcome.generated and state.facts.get("new_rule") == "old_order_survived", "Пропущенный финал должен разрешиться до эпилога")
	_expect(not state.story_timeline.can_choose(state, "new_rule", "law"), "Нельзя менять исход после эпилога")

func _test_delayed_border_reply_keeps_decision_window() -> void:
	var state := WorldState.new()
	while state.calendar.cycle < 7:
		state.advance_period()
	_expect(state.story_timeline.choose(state, "border_courier", "envoy"), "Гонцу можно ответить во втором периоде")
	state.advance_period()
	_expect("border_consequence" not in state.story_timeline.available_events(8), "Посольство не должно возвращаться раньше срока")
	state.advance_period()
	state.advance_period()
	_expect("border_consequence" in state.story_timeline.available_events(10), "После возвращения посольства у князя должно быть два периода для решения")
	state.advance_period()
	_expect(state.story_timeline.resolved.get("border_consequence", {}).get("choice") == "neglected", "Просрочка должна наступить по истечении обоих периодов")

func _test_personal_choices_follow_location_and_health() -> void:
	var state := WorldState.new()
	while state.calendar.cycle < 10:
		state.advance_period()
	_expect(state.story_timeline.choose(state, "fever_outbreak", "clinics"), "Лечебницы должны открыть возможность подготовить испытание")
	var prepared := WorldState.from_data(state.to_data())
	var discouraged := WorldState.from_data(state.to_data())
	_expect(not prepared.conversations.choose(prepared, "tikhon", "prepare_trial").is_empty(), "Подготовка насоса должна быть доступна через разговор в школе")
	_expect(not discouraged.conversations.choose(discouraged, "tikhon", "mock").is_empty(), "Тихон должен запомнить насмешку")
	for trial: WorldState in [state, prepared, discouraged]:
		while trial.calendar.cycle < 12:
			trial.advance_period()
		trial.public_health = 50
		_expect(trial.story_timeline.choose(trial, "tikhon_pump", "field_test"), "Испытание должно работать при разных отношениях с Тихоном")
	_expect(prepared.public_health == 55 and state.public_health == 53 and discouraged.public_health == 51, "Подготовка и недоверие должны давать разные результаты испытания")
	var family := WorldState.new()
	while family.calendar.cycle < 11:
		family.advance_period()
	_expect(family.story_timeline.choose(family, "family_warning", "evacuate"), "Семью должно быть можно вывезти из столицы")
	_expect("spouse" not in family.conversations.people_at("castle", family), "Адела не должна оставаться во дворце после отъезда")
	while family.calendar.cycle < 14:
		family.advance_period()
	family.story_timeline.choose(family, "aglaia_invitation", "decline")
	_expect(family.story_timeline.outcome("aglaia_invitation").contains("написали Аделе"), "После отъезда отказ от вечера должен возвращать к семье через письмо")

func _test_location_content_references() -> void:
	var state := WorldState.new()
	for location_id: String in CITY_MAP.HOTSPOTS:
		_expect(LOCATION_CATALOG.has_location(location_id), "Для точки %s нужна сцена" % location_id)
	for location_id: String in state.conversations.LOCATION_CAST:
		var location := LOCATION_CATALOG.definition(location_id)
		var hotspots: Dictionary = location.get("hotspots", {})
		for person_id: String in state.conversations.LOCATION_CAST[location_id]:
			_expect(state.characters.has(person_id) and hotspots.has(person_id), "Для %s нужны персонаж и место в сцене %s" % [person_id, location_id])
			_expect(not state.conversations.profile(person_id).is_empty(), "У %s должен быть профиль для разговора" % person_id)
			for data: Dictionary in state.conversations.OPTIONS.get(person_id, {}).values():
				var required_event := str(data.get("requires_event", ""))
				var closing_event := str(data.get("closes_after", ""))
				if not required_event.is_empty():
					var choices: Dictionary = state.story_timeline.definition(required_event).get("choices", {})
					_expect(not choices.is_empty(), "У реплики %s нет исходного события %s" % [person_id, required_event])
					for choice: String in data.get("requires_choices", []):
						_expect(choice == "neglected" or choices.has(choice), "Реплика %s ссылается на неизвестное решение %s" % [person_id, choice])
				if not closing_event.is_empty():
					_expect(not state.story_timeline.definition(closing_event).is_empty(), "У реплики %s неизвестное событие закрытия %s" % [person_id, closing_event])

func _test_city_dilemmas_offer_distinct_free_choices() -> void:
	var sample := WorldState.new()
	for person_id: String in sample.conversations.CITY_CASES:
		var definition: Dictionary = sample.conversations.CITY_CASES[person_id]
		for option_id: String in definition["options"]:
			var state := WorldState.new()
			state.state_treasury = 0
			state.calendar.cycle = int(definition["start_cycle"])
			state.facts.merge(definition.get("requires_facts", {}))
			var event_id := str(definition.get("requires_event", ""))
			if not event_id.is_empty():
				state.story_timeline.resolved[event_id] = {"choice": definition["requires_choices"][0]}
			var option: Dictionary = definition["options"][option_id]
			_expect(not state.conversations.city_case_brief(person_id, state).is_empty(), "Игроку должен быть понятен повод для разговора с %s" % person_id)
			var before_fatigue := state.ruler_fatigue
			var response: String = state.conversations.choose(state, person_id, option_id)
			_expect(not response.is_empty() and state.state_treasury == int(option.get("gold_change", 0)), "При пустой казне должен работать вариант %s" % option_id)
			_expect(state.ruler_fatigue == before_fatigue + 1, "Разговор должен расходовать один пункт усталости")
			_expect(state.facts.get(definition["fact"]) == option["outcome"], "Ответ должен сохранять свой исход")
			var loaded := WorldState.from_data(state.to_data())
			_expect(loaded.conversations.last_response(person_id) == response, "Избранный вариант разговора должен сохраняться")
			_expect(str(loaded.conversations.city_case_brief(person_id, loaded)).is_empty(), "Завершённое дело не должно предлагать противоположный выбор после загрузки")

func _test_period_report_tracks_actual_changes() -> void:
	var state := WorldState.new()
	_expect(state.period_report.is_empty(), "У новой кампании не должно быть отчёта за несыгранный период")
	state.advance_period()
	_expect(str(state.period_report["notes"]).contains("Вода в старом амбаре"), "В сводке должно появляться доступное после перехода дело")
	state.advance_period()
	var gold_before := state.state_treasury
	state.advance_period()
	var exact_delta := false
	for change: Dictionary in state.period_report["changes"]:
		if change["id"] == "state_treasury":
			exact_delta = change["before"] == gold_before and change["after"] == state.state_treasury
	_expect(exact_delta and state.period_report["cycle"] == state.calendar.cycle, "Сводка должна показывать фактическую разницу за последний переход")
	_expect(str(state.period_report["notes"]).contains("обычные сборы +8"), "Рядом с итогом казны должны быть видны источники месячного расчёта")
	state.dismiss_period_report()
	var data := state.to_data()
	var restored := WorldState.from_data(data)
	_expect(restored.period_report.get("dismissed") == true and restored.period_report.get("cycle") == state.calendar.cycle, "Сводка и факт закрытия должны сохраняться")
	_expect(restored.period_archive.size() == 2 and restored.period_archive[0]["cycle"] == 2, "Должны сохраняться прежние сводки в порядке ходов")
	data.erase("period_report")
	data.erase("period_archive")
	_expect(WorldState.from_data(data).period_report.is_empty(), "Старые сохранения без сводки должны загружаться")

func _test_story_history_preserves_choices_and_results() -> void:
	var state := WorldState.new()
	state.calendar.cycle = 2
	_expect(state.story_timeline.choose(state, "granary_roof", "inspect"), "Первое решение должно попасть в летопись")
	state.calendar.cycle = 3
	_expect(state.story_timeline.choose(state, "dead_prince_order", "public"), "Второе решение должно попасть в летопись")
	var history := state.story_timeline.resolved_history(6)
	_expect(history.size() == 2, "Летопись должна показывать все решения в пределах установленного лимита")
	_expect(str(history[0].get("event_id", "")) == "dead_prince_order", "Летопись должна начинаться с самого свежего решения")
	_expect(history[0].get("choice") == state.story_timeline.definition("dead_prince_order")["choices"]["public"], "Летопись должна хранить понятный текст выбранного действия")
	_expect(not str(history[0].get("outcome", "")).is_empty(), "Из летописи должен повторно открываться фактический результат")
	_expect(state.story_timeline.resolved_history(1).size() == 1, "Компактная летопись должна соблюдать лимит и не превращаться в полотно")
	var restored := WorldState.from_data(state.to_data())
	_expect(restored.story_timeline.resolved_history(6).size() == 2, "Летопись решений должна сохраняться вместе с кампанией")

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
	var auto_path := "user://test_autosave_%d.json" % OS.get_process_id()
	var manual_path := "user://test_absent_manual_%d.json" % OS.get_process_id()
	_expect(CampaignSaveService.save_campaign(state, auto_path) == OK, "Автосохранение должно записываться атомарно")
	var loaded := CampaignSaveService.load_latest(manual_path, auto_path)
	_expect(loaded != null and loaded.state_treasury == 77, "Автосохранение должно полностью восстанавливать состояние")
	state.state_treasury = 85
	_expect(CampaignSaveService.save_campaign(state, auto_path) == OK, "Новый файл должен заменить старое автосохранение")
	_expect(not FileAccess.file_exists(auto_path + ".tmp"), "После успешной записи не должен оставаться временный файл")
	var temp_as_dir := ProjectSettings.globalize_path(auto_path + ".tmp")
	_expect(DirAccess.make_dir_absolute(temp_as_dir) == OK, "Тест должен смоделировать занятый временный путь")
	state.state_treasury = 99
	_expect(CampaignSaveService.save_campaign(state, auto_path) != OK, "Запись в занятый временный путь должна вернуть ошибку")
	loaded = CampaignSaveService.load_latest(manual_path, auto_path)
	_expect(loaded != null and loaded.state_treasury == 85, "Неудачная запись должна оставить предыдущее сохранение")
	DirAccess.remove_absolute(temp_as_dir)
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

