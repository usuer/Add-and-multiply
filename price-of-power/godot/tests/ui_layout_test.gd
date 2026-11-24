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
	app.call("_show_pause_menu")
	await process_frame
	_check_pause_menu(app)
	app.call("_hide_pause_menu")
	await process_frame
	app.call("_on_illustrated_building_selected", &"granary")
	await process_frame
	_check_building_panel(app)
	app.call("_close_building_panel")
	await process_frame
	app.call("_on_illustrated_building_selected", &"castle")
	await process_frame
	await _check_location_sizes(app, 4)
	app.call("_open_character_dialogue", "spouse")
	await process_frame
	_check_character_dialogue(app)
	var outside_click := InputEventMouseButton.new()
	outside_click.button_index = MOUSE_BUTTON_LEFT
	outside_click.pressed = true
	(app.get("location_scene") as Control).call("_on_dialogue_shade_input", outside_click)
	if (app.get("location_scene") as Control).get("dialogue_layer").visible:
		failures.append("Нажатие по затемнённой области должно закрывать разговор")
	app.call("_open_location_management", "castle")
	await process_frame
	_check_council_cards(app)
	app.call("_appoint_councillor", "steward", "vesna")
	await process_frame
	var council_state: WorldState = app.get("state") as WorldState
	if str(council_state.council.appointments["steward"]) != "vesna":
		failures.append("Назначение из карточки совета должно менять управляющего")
	app.call("_set_castle_section", "people")
	await process_frame
	_check_people_dossier(app)
	app.call("_set_castle_section", "policies")
	await process_frame
	_check_policy_cards(app)
	app.call("_enact_policy", "labor", "protected")
	await process_frame
	if str(council_state.policies.active["labor"]) != "protected":
		failures.append("Изменение правила через карточку должно вступать в силу")
	app.call("_close_building_panel")
	await process_frame
	app.call("_close_location_scene")
	app.call("_on_illustrated_building_selected", &"barracks")
	await process_frame
	_check_location_scene(app, 2)
	app.call("_close_location_scene")
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
	_check_story_history(app)
	app.call("_close_secretary")
	app.call("_on_advance_period")
	await process_frame
	_check_header(app, "после следующего периода")
	app.call("_open_secretary")
	await process_frame
	_check_header(app, "при повторном открытии секретаря")
	await _check_common_desktop_sizes(app)
	_check_exit_confirmation(app)
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

func _check_location_scene(app: Node, expected_people: int) -> void:
	var scene := app.get("location_scene") as Control
	if scene == null or not scene.visible or not root.get_visible_rect().encloses(scene.get_global_rect()):
		failures.append("Локация должна открываться отдельной полноэкранной игровой сценой")
		return
	var background := scene.get("background") as TextureRect
	if background == null or background.texture == null:
		failures.append("У отдельной локации должен быть собственный фон")
	var actors: Dictionary = scene.get("person_actors")
	if actors.size() != expected_people:
		failures.append("В локации ожидалось %d отдельных персонажей, найдено %d" % [expected_people, actors.size()])
	var actor_rects: Array[Rect2] = []
	for person_id: String in actors:
		var actor := actors[person_id] as Control
		if not root.get_visible_rect().encloses(actor.get_global_rect()):
			failures.append("Персонаж %s вышел за границы экрана" % person_id)
		for other_rect: Rect2 in actor_rects:
			if actor.get_global_rect().intersects(other_rect):
				failures.append("Персонажи в локации перекрывают друг друга")
		actor_rects.append(actor.get_global_rect())

func _check_location_sizes(app: Node, expected_people: int) -> void:
	for window_size in [Vector2i(1024, 700), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = window_size
		await process_frame
		await process_frame
		_check_location_scene(app, expected_people)
	root.size = Vector2i(1024, 700)
	await process_frame

func _check_character_dialogue(app: Node) -> void:
	var scene := app.get("location_scene") as Control
	var layer := scene.get("dialogue_layer") as Control
	var panel := scene.get("dialogue_panel") as PanelContainer
	if layer == null or not layer.visible:
		failures.append("Нажатие на персонажа должно открывать разговор")
	if panel == null or not root.get_visible_rect().encloses(panel.get_global_rect()):
		failures.append("Диалог должен полностью помещаться на экране")
	var actors: Dictionary = scene.get("person_actors")
	var spouse := actors.get("spouse") as Control
	if spouse == null or spouse.get("display_name") == "":
		failures.append("Персонаж в локации должен иметь видимое имя и отдельное состояние")

func _check_secretary_summary(app: Node, expected_cases: int) -> void:
	var title := app.get("secretary_title") as Label
	var introduction := app.get("secretary_introduction") as Label
	var scroll := app.get("secretary_scroll") as ScrollContainer
	if title == null or title.text != "Дела княжеской канцелярии":
		failures.append("После вступления секретарь должен показывать актуальную повестку, а не старый заголовок")
	if introduction == null or not introduction.text.contains("Новых дел: %d" % expected_cases):
		failures.append("Канцелярия должна кратко показывать число новых дел: ожидалось %d" % expected_cases)
	if scroll == null or scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		failures.append("Канцелярия не должна требовать горизонтальной прокрутки")

func _check_council_cards(app: Node) -> void:
	var labels: Array[String] = []
	_collect_label_text(app.get("building_actions") as Node, labels)
	for marker in ["Сильная сторона:", "Риск:", "Связи:"]:
		var found := false
		for value in labels:
			if value.begins_with(marker):
				found = true
				break
		if not found:
			failures.append("Карточки советников должны показывать раздел «%s»" % marker)

func _check_people_dossier(app: Node) -> void:
	var labels: Array[String] = []
	_collect_label_text(app.get("building_actions") as Node, labels)
	var joined := "\n".join(labels)
	if not joined.contains("ЛЮДИ ВОКРУГ ВЛАСТИ"):
		failures.append("В замке должен открываться отдельный раздел персонажей")
	if not joined.contains("Наблюдаемое отношение:") or not joined.contains("ЧТО ЭТОТ ЧЕЛОВЕК ПОМНИТ"):
		failures.append("Досье персонажа должно объяснять отношение и память без скрытых чисел")

func _check_story_history(app: Node) -> void:
	var labels: Array[String] = []
	_collect_label_text(app.get("secretary_case_body") as Node, labels)
	var found := false
	for value: String in labels:
		if value.begins_with("ЛЕТОПИСЬ РЕШЕНИЙ"):
			found = true
	if not found:
		failures.append("После решения канцелярия должна показывать компактную летопись")

func _collect_label_text(node: Node, output: Array[String]) -> void:
	if node is Label:
		output.append((node as Label).text)
	for child in node.get_children():
		_collect_label_text(child, output)

func _check_policy_cards(app: Node) -> void:
	var labels: Array[String] = []
	_collect_label_text(app.get("building_actions") as Node, labels)
	var has_active_rule := false
	for value in labels:
		if value.begins_with("Действует:"):
			has_active_rule = true
			break
	if not has_active_rule:
		failures.append("Экран правил должен явно отделять действующий указ от альтернатив")

func _check_header(app: Node, stage: String) -> void:
	var visible_rect := root.get_visible_rect()
	var buttons: Array[Button] = []
	for caption in ["Дела секретаря", "Завершить период", "Новая", "Сохр.", "Загр.", "Выход", "Меню"]:
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

func _check_exit_confirmation(app: Node) -> void:
	app.call("_on_exit_requested")
	var button := app.get("exit_button") as Button
	if not bool(app.get("exit_confirmation")) or button == null or button.text != "Точно?":
		failures.append("Первое нажатие выхода должно запрашивать подтверждение, а не закрывать игру")
	app.call("_cancel_exit_confirmation")
	if bool(app.get("exit_confirmation")) or button.text != "Выход":
		failures.append("Отмена подтверждения должна возвращать обычную кнопку выхода")

func _check_pause_menu(app: Node) -> void:
	var overlay := app.get("pause_overlay") as Control
	var panel := app.get("pause_panel") as PanelContainer
	if overlay == null or not overlay.visible:
		failures.append("Игровое меню должно открываться поверх игры")
	if panel == null or not root.get_visible_rect().encloses(panel.get_global_rect()):
		failures.append("Игровое меню должно полностью помещаться на минимальном экране")
	for caption in ["Продолжить", "Сохранить кампанию", "Загрузить сохранение", "На весь экран", "Звук:", "Сохранить и выйти"]:
		if _find_button(overlay, caption) == null:
			failures.append("В игровом меню нет действия «%s»" % caption)
	var sound_before := bool(app.get("sound_enabled"))
	app.call("_toggle_sound")
	var sound_button := app.get("sound_button") as Button
	if bool(app.get("sound_enabled")) == sound_before or sound_button == null or not sound_button.text.begins_with("Звук:"):
		failures.append("Переключатель звука должен менять состояние и сразу обновлять подпись")
	app.call("_toggle_sound")
	var streams: Dictionary = app.get("sound_streams")
	for sound_id in ["click", "decision", "period", "alert", "battle"]:
		var stream := streams.get(sound_id) as AudioStreamWAV
		if stream == null or stream.data.is_empty():
			failures.append("Звуковой сигнал «%s» должен содержать реальные аудиоданные" % sound_id)

func _find_button(node: Node, caption: String) -> Button:
	if node is Button and (node as Button).text.begins_with(caption):
		return node as Button
	for child in node.get_children():
		var result := _find_button(child, caption)
		if result != null:
			return result
	return null
