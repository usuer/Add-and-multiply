extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1024, 700)
	var scene := load("res://app/app_root.tscn") as PackedScene
	var app := scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	for page in range(5):
		app.call("_intro_next")
	await process_frame
	_check_header(app, "при запуске")
	app.call("_on_illustrated_building_selected", &"granary")
	await process_frame
	_check_building_panel(app)
	app.call("_close_building_panel")
	await process_frame
	var state: WorldState = app.get("state") as WorldState
	state.opening_decision.choose_funeral("solemn")
	state.opening_decision.choose_grain("partial")
	state.opening_decision.choose_funding("state")
	if not state.opening_decision.resolve(state):
		failures.append("Не удалось подготовить вступительное решение для UI-сценария")
	app.call("_on_advance_period")
	await process_frame
	_check_header(app, "после завершения периода")
	app.call("_open_secretary")
	await process_frame
	_check_header(app, "при открытии протечки амбара")
	_check_secretary_summary(app, 1)
	app.call("_choose_story_event", "granary_roof", "repair")
	await process_frame
	_check_header(app, "после отправки плотников")
	_check_secretary_summary(app, 0)
	app.call("_close_secretary")
	app.call("_on_advance_period")
	await process_frame
	_check_header(app, "после следующего периода")
	app.call("_open_secretary")
	await process_frame
	_check_header(app, "при повторном открытии секретаря")
	await _check_common_desktop_sizes(app)
	if failures.is_empty():
		print("PASS UI layout: header remains usable at 1024x700")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_common_desktop_sizes(app: Node) -> void:
	for window_size in [Vector2i(1024, 700), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = window_size
		await process_frame
		await process_frame
		_check_header(app, "при размере %dx%d" % [window_size.x, window_size.y])
	var shade := app.get("modal_shade") as ColorRect
	if shade == null or not shade.visible or shade.color.a < 0.7:
		failures.append("Окно секретаря должно отделяться от карты плотным затемнением")

func _check_building_panel(app: Node) -> void:
	var panel := app.get("building_panel") as PanelContainer
	var picture := app.get("building_picture") as TextureRect
	var context := app.get("building_context") as Label
	if panel == null or not panel.visible or not root.get_visible_rect().encloses(panel.get_global_rect()):
		failures.append("Карточка городского объекта должна полностью помещаться на экране")
	if picture == null or picture.texture == null:
		failures.append("Карточка здания должна показывать художественное приближение объекта")
	if context == null or context.text != "ЗАПАСЫ И СНАБЖЕНИЕ":
		failures.append("Карточка амбара должна объяснять назначение места")

func _check_secretary_summary(app: Node, expected_cases: int) -> void:
	var title := app.get("secretary_title") as Label
	var introduction := app.get("secretary_introduction") as Label
	if title == null or title.text != "Дела княжеской канцелярии":
		failures.append("После вступления секретарь должен показывать актуальную повестку, а не старый заголовок")
	if introduction == null or not introduction.text.contains("Новых дел: %d" % expected_cases):
		failures.append("Канцелярия должна кратко показывать число новых дел: ожидалось %d" % expected_cases)

func _check_header(app: Node, stage: String) -> void:
	var visible_rect := root.get_visible_rect()
	var buttons: Array[Button] = []
	for caption in ["Дела секретаря", "Завершить период", "Новая", "Сохр.", "Загр."]:
		var button := _find_button(app, caption)
		if button == null:
			failures.append("Нет кнопки «%s» %s" % [caption, stage])
			continue
		buttons.append(button)
		var rect := button.get_global_rect()
		if not button.visible or not visible_rect.encloses(rect):
			failures.append("Кнопка «%s» вышла за экран %s: %s" % [caption, stage, rect])
	for index in range(buttons.size() - 1):
		if buttons[index].get_global_rect().intersects(buttons[index + 1].get_global_rect()):
			failures.append("Кнопки «%s» и «%s» пересекаются %s" % [buttons[index].text, buttons[index + 1].text, stage])

func _find_button(node: Node, caption: String) -> Button:
	if node is Button and (node as Button).text.begins_with(caption):
		return node as Button
	for child in node.get_children():
		var result := _find_button(child, caption)
		if result != null:
			return result
	return null
