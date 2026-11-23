extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_test_calendar_has_eighteen_cycles()
	_test_failed_spending_is_atomic()
	_test_grain_investigation_uses_delegate_method()
	_test_opening_decision_is_composite_and_atomic()
	_test_save_round_trip()
	if failures.is_empty():
		print("PASS Godot foundation: 5 checks")
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

func _test_save_round_trip() -> void:
	var state := WorldState.new()
	state.advance_period()
	state.assign_grain_investigation("agent")
	state.opening_decision.choose_funeral("modest")
	state.opening_decision.choose_grain("partial")
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
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

