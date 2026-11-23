extends Node3D

const CAPITAL_CAMERA := preload("res://world/capital_camera.gd")

var state: WorldState = WorldState.new()
var date_label: Label
var resource_label: Label
var notice_label: Label

func _ready() -> void:
	_create_environment()
	_create_capital_placeholder()
	_create_camera()
	_create_ui()
	_refresh_ui("Первая техническая сцена: укреплённый Арден")

func _create_environment() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("8fb2bd")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("d9e1d0")
	settings.ambient_light_energy = 0.62
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -34.0, 0.0)
	sun.light_color = Color("fff0ca")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

func _create_capital_placeholder() -> void:
	_add_box("Valley", Vector3(62.0, 0.8, 48.0), Vector3(0.0, -0.6, 0.0), Color("6f8a55"))
	_add_box("River", Vector3(8.0, 0.18, 52.0), Vector3(17.0, 0.0, 0.0), Color("4c8da0"))

	# Unified stone perimeter.
	_add_box("NorthWall", Vector3(34.0, 2.5, 1.2), Vector3(-4.0, 1.25, -15.0), Color("a99b7e"))
	_add_box("SouthWall", Vector3(34.0, 2.5, 1.2), Vector3(-4.0, 1.25, 15.0), Color("a99b7e"))
	_add_box("WestWall", Vector3(1.2, 2.5, 31.0), Vector3(-21.0, 1.25, 0.0), Color("a99b7e"))
	_add_box("EastWallTop", Vector3(1.2, 2.5, 12.0), Vector3(13.0, 1.25, -9.5), Color("a99b7e"))
	_add_box("EastWallBottom", Vector3(1.2, 2.5, 12.0), Vector3(13.0, 1.25, 9.5), Color("a99b7e"))

	# Palace-castle and functional city blocks.
	_add_building("Castle", Vector3(-11.0, 0.0, -4.0), Vector3(9.0, 7.0, 8.0), Color("7d6d5d"))
	_add_building("Keep", Vector3(-11.0, 0.0, -4.0), Vector3(4.0, 11.0, 4.0), Color("66594c"))
	_add_building("Barracks", Vector3(-3.0, 0.0, 8.0), Vector3(7.0, 3.8, 4.0), Color("806b53"))
	_add_building("Smithy", Vector3(6.0, 0.0, 8.0), Vector3(5.0, 3.0, 4.0), Color("624f42"))
	_add_building("Granary", Vector3(6.0, 0.0, -7.0), Vector3(6.0, 4.0, 4.0), Color("9b7b4f"))
	_add_building("Market", Vector3(-1.0, 0.0, 0.0), Vector3(8.0, 1.4, 6.0), Color("b49568"))
	_add_building("Temple", Vector3(7.0, 0.0, 1.0), Vector3(5.0, 6.0, 5.0), Color("aea287"))

	# Quarry remains outside the defended city.
	_add_box("Quarry", Vector3(10.0, 0.7, 8.0), Vector3(-26.0, 0.0, 17.0), Color("807b70"))

func _add_building(label_text: String, ground_position: Vector3, size: Vector3, color: Color) -> void:
	_add_box(label_text, size, ground_position + Vector3(0.0, size.y * 0.5, 0.0), color)

func _add_box(node_name: String, size: Vector3, world_position: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.position = world_position
	add_child(mesh_instance)

func _create_camera() -> void:
	var rig := CAPITAL_CAMERA.new()
	rig.position = Vector3(-2.0, 0.0, 8.0)
	add_child(rig)

func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	layer.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 92)
	root.add_child(header)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 24)
	header.add_child(header_row)

	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_column)

	var title := Label.new()
	title.text = "АРДЕНСКОЕ КНЯЖЕСТВО"
	title.add_theme_font_size_override("font_size", 15)
	title_column.add_child(title)

	date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 25)
	title_column.add_child(date_label)

	resource_label = Label.new()
	resource_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(resource_label)

	var actions := VBoxContainer.new()
	header_row.add_child(actions)
	var next_button := Button.new()
	next_button.text = "Завершить период"
	next_button.custom_minimum_size = Vector2(190, 44)
	next_button.pressed.connect(_on_advance_period)
	actions.add_child(next_button)
	var save_row := HBoxContainer.new()
	actions.add_child(save_row)
	for item: Dictionary in [
		{"text": "Сохранить", "callable": _on_save},
		{"text": "Загрузить", "callable": _on_load}
	]:
		var button := Button.new()
		button.text = item["text"]
		button.pressed.connect(item["callable"])
		save_row.add_child(button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var footer := PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 62)
	root.add_child(footer)
	notice_label = Label.new()
	notice_label.text = "WASD — перемещение · Q/E — вращение · колесо — масштаб"
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(notice_label)

func _on_advance_period() -> void:
	var advanced := state.advance_period()
	_refresh_ui("Период завершён" if advanced else "Демоверсия завершена — доступен эпилог")

func _on_save() -> void:
	var error := CampaignSaveService.save_campaign(state)
	_refresh_ui("Сохранение создано" if error == OK else "Не удалось сохранить: %s" % error_string(error))

func _on_load() -> void:
	var loaded := CampaignSaveService.load_campaign()
	if loaded == null:
		_refresh_ui("Сохранение ещё не создано")
		return
	state = loaded
	_refresh_ui("Сохранение загружено")

func _refresh_ui(message: String) -> void:
	date_label.text = state.calendar.display_date()
	resource_label.text = "Казна %d    Личные средства %d\nЗерно %d    Железо %d    Оружие %d" % [
		state.state_treasury,
		state.family_treasury,
		int(state.resources.get("grain", 0)),
		int(state.resources.get("worked_iron", 0)),
		int(state.resources.get("weapons", 0))
	]
	notice_label.text = message + "    ·    WASD — перемещение · Q/E — вращение · колесо — масштаб"

