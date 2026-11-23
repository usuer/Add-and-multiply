extends Node3D

const CAPITAL_CAMERA := preload("res://world/capital_camera.gd")
const CITY_BUILDING := preload("res://world/city_building.gd")

var state: WorldState = WorldState.new()
var date_label: Label
var resource_label: Label
var notice_label: Label
var camera_rig: CapitalCamera
var selected_building: CityBuilding
var building_panel: PanelContainer
var building_title: Label
var building_description: Label
var building_status: Label
var building_actions: VBoxContainer

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
	_add_building(&"castle", "Замок Ардена", "Дворец княжеской семьи, канцелярия и последний рубеж обороны.", Vector3(-11.0, 0.0, -4.0), Vector3(9.0, 7.0, 8.0), Color("7d6d5d"))
	_add_building(&"keep", "Донжон", "Внутренняя башня, архив и защищённые запасы на случай прорыва стен.", Vector3(-11.0, 0.0, -4.0), Vector3(4.0, 11.0, 4.0), Color("66594c"))
	_add_building(&"barracks", "Казармы", "Гарнизон столицы, обучение ополчения и размещение военных запасов.", Vector3(-3.0, 0.0, 8.0), Vector3(7.0, 3.8, 4.0), Color("806b53"))
	_add_building(&"smithy", "Кузница", "Производит инструменты и вооружение, потребляя древесину и обработанное железо.", Vector3(6.0, 0.0, 8.0), Vector3(5.0, 3.0, 4.0), Color("624f42"))
	_add_building(&"granary", "Княжеский амбар", "Государственные запасы зерна. Недостача в областных книгах требует расследования.", Vector3(6.0, 0.0, -7.0), Vector3(6.0, 4.0, 4.0), Color("9b7b4f"))
	_add_building(&"market", "Городской рынок", "Главное место торговли, найма и распространения слухов.", Vector3(-1.0, 0.0, 0.0), Vector3(8.0, 1.4, 6.0), Color("b49568"))
	_add_building(&"temple", "Храм", "Центр прихода, помощи больным и регистрации семейных событий.", Vector3(7.0, 0.0, 1.0), Vector3(5.0, 6.0, 5.0), Color("aea287"))

	# Quarry remains outside the defended city.
	_add_box("Quarry", Vector3(10.0, 0.7, 8.0), Vector3(-26.0, 0.0, 17.0), Color("807b70"))

func _add_building(id: StringName, title: String, details: String, ground_position: Vector3, size: Vector3, color: Color) -> void:
	var building := CITY_BUILDING.new() as CityBuilding
	building.configure(id, title, details, size, color)
	building.position = ground_position
	building.selected.connect(_on_building_selected)
	add_child(building)

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
	camera_rig = CAPITAL_CAMERA.new()
	camera_rig.position = Vector3(-2.0, 0.0, 8.0)
	add_child(camera_rig)

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
	_create_building_panel(layer)

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

func _create_building_panel(layer: CanvasLayer) -> void:
	building_panel = PanelContainer.new()
	building_panel.visible = false
	building_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	building_panel.position = Vector2(-388, -210)
	building_panel.size = Vector2(360, 420)
	layer.add_child(building_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 22)
	panel_margin.add_theme_constant_override("margin_top", 20)
	panel_margin.add_theme_constant_override("margin_right", 22)
	panel_margin.add_theme_constant_override("margin_bottom", 20)
	building_panel.add_child(panel_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel_margin.add_child(column)

	var close_button := Button.new()
	close_button.text = "Вернуться к городу"
	close_button.pressed.connect(_close_building_panel)
	column.add_child(close_button)
	building_title = Label.new()
	building_title.add_theme_font_size_override("font_size", 25)
	building_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(building_title)
	building_status = Label.new()
	building_status.modulate = Color("d9bd72")
	column.add_child(building_status)
	building_description = Label.new()
	building_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(building_description)
	building_actions = VBoxContainer.new()
	building_actions.add_theme_constant_override("separation", 7)
	column.add_child(building_actions)

func _on_building_selected(building: CityBuilding) -> void:
	if selected_building != null:
		selected_building.set_highlighted(false)
	selected_building = building
	selected_building.set_highlighted(true)
	camera_rig.focus_on(building.focus_point())
	building_panel.visible = true
	building_title.text = building.display_name
	building_status.text = building.building_status
	building_description.text = building.description
	_refresh_building_actions()

func _refresh_building_actions() -> void:
	for child in building_actions.get_children():
		child.queue_free()
	if selected_building == null:
		return
	if selected_building.building_id in [&"castle", &"granary"]:
		var heading := Label.new()
		heading.text = "ДЕЛО О НЕХВАТКЕ ЗЕРНА"
		heading.modulate = Color("d9bd72")
		building_actions.add_child(heading)
		var crisis_text := Label.new()
		crisis_text.text = state.grain_crisis.status_text()
		crisis_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(crisis_text)
		if state.grain_crisis.stage == GrainCrisis.Stage.REPORTED:
			for delegate_id: String in GrainCrisis.DELEGATES:
				var delegate: Dictionary = GrainCrisis.DELEGATES[delegate_id]
				var button := Button.new()
				button.text = "Поручить: %s" % delegate["name"]
				button.pressed.connect(_assign_grain_investigation.bind(delegate_id))
				building_actions.add_child(button)
	else:
		var inspect_button := Button.new()
		inspect_button.text = "Осмотреть объект"
		inspect_button.pressed.connect(_inspect_selected_building)
		building_actions.add_child(inspect_button)

func _assign_grain_investigation(delegate_id: String) -> void:
	if state.assign_grain_investigation(delegate_id):
		_refresh_ui("Расследование поручено: %s" % GrainCrisis.DELEGATES[delegate_id]["name"])
	_refresh_building_actions()

func _inspect_selected_building() -> void:
	if selected_building != null:
		_refresh_ui("Осмотрено: %s. Новых срочных проблем не обнаружено." % selected_building.display_name)

func _close_building_panel() -> void:
	building_panel.visible = false
	if selected_building != null:
		selected_building.set_highlighted(false)
	selected_building = null
	camera_rig.overview()

func _on_advance_period() -> void:
	var advanced := state.advance_period()
	_refresh_ui("Период завершён" if advanced else "Демоверсия завершена — доступен эпилог")
	if building_panel.visible:
		_refresh_building_actions()

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
	if building_panel.visible:
		_refresh_building_actions()

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

