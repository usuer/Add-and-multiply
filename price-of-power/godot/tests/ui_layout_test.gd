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
	app.call("_on_advance_period")
	await process_frame
	_check_header(app, "после завершения периода")
	app.call("_open_secretary")
	await process_frame
	_check_header(app, "при повторном открытии секретаря")
	if failures.is_empty():
		print("PASS UI layout: header remains usable at 1024x700")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

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
