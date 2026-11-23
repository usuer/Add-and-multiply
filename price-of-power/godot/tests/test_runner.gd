extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_test_calendar_has_eighteen_cycles()
	_test_failed_spending_is_atomic()
	_test_save_round_trip()
	if failures.is_empty():
		print("PASS Godot foundation: 3 checks")
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

func _test_save_round_trip() -> void:
	var state := WorldState.new()
	state.advance_period()
	state.spend_state(7, "ремонт ворот")
	var path := "user://test_campaign.json"
	_expect(CampaignSaveService.save_campaign(state, path) == OK, "Тестовое сохранение должно записываться")
	var loaded := CampaignSaveService.load_campaign(path)
	_expect(loaded != null, "Тестовое сохранение должно загружаться")
	if loaded != null:
		_expect(loaded.calendar.cycle == state.calendar.cycle, "Цикл должен сохраняться")
		_expect(loaded.state_treasury == state.state_treasury, "Казна должна сохраняться")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

