extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_test_calendar_has_eighteen_cycles()
	_test_failed_spending_is_atomic()
	_test_grain_investigation_uses_delegate_method()
	_test_opening_decision_is_composite_and_atomic()
	_test_opening_decision_creates_social_memory()
	_test_followup_conversation_remembers_response()
	_test_story_events_unlock_and_resolve_once()
	_test_neglected_events_and_border_branch()
	_test_campaign_generates_a_stateful_outcome()
	_test_council_appointments_affect_government()
	_test_physician_changes_epidemic_outcome()
	_test_governance_policies_change_monthly_results()
	_test_save_round_trip()
	if failures.is_empty():
		print("PASS Godot foundation: 13 checks")
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
	_expect(state.campaign_outcome.summary_lines.size() == 3, "Итог должен охватывать страну, семью и границу")
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

