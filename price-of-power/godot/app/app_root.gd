extends Node3D

const CAPITAL_CAMERA := preload("res://world/capital_camera.gd")
const CITY_BUILDING := preload("res://world/city_building.gd")
const ILLUSTRATED_MAP := preload("res://world/illustrated_capital_map.gd")
const LOCATION_SCENE := preload("res://world/location_scene.gd")
const LOCATION_CATALOG := preload("res://world/location_catalog.gd")
const PERIOD_REPORT := preload("res://world/period_report_panel.gd")
const PROLOGUE := preload("res://world/prologue_scene.gd")
const COURT_AUTHORITY := preload("res://simulation/court_authority.gd")
const SEAL_CASE_FILE := preload("res://simulation/seal_case_file.gd")
const FAMILY_CORRESPONDENCE := preload("res://simulation/family_correspondence.gd")
const COUNCIL_VERDICT := preload("res://simulation/council_verdict.gd")
const USE_3D_PLACEHOLDERS: bool = false
const SETTINGS_PATH: String = "user://settings.cfg"

var state: WorldState = WorldState.new()
var autosave_path: String = CampaignSaveService.AUTOSAVE_PATH
var date_label: Label
var resource_label: Label
var notice_label: Label
var camera_rig: CapitalCamera
var selected_building: CityBuilding
var building_panel: PanelContainer
var building_scroll: ScrollContainer
var building_close_button: Button
var battle_primary_button: Button
var authority_confirmation: ConfirmationDialog
var authority_selected_person: String
var authority_selected_action: String
var building_title: Label
var building_context: Label
var building_picture: TextureRect
var building_description: Label
var building_status: Label
var building_actions: VBoxContainer
var secretary_panel: PanelContainer
var secretary_case_body: VBoxContainer
var secretary_scroll: ScrollContainer
var secretary_title: Label
var secretary_close_button: Button
var secretary_introduction: Label
var funeral_choice_label: Label
var grain_choice_label: Label
var funding_choice_label: Label
var resolve_opening_button: Button
var cases_button: Button
var advance_button: Button
var period_report_button: Button
var period_report_panel: Control
var period_report_index: int = 0
var exit_button: Button
var menu_button: Button
var pause_overlay: Control
var pause_panel: PanelContainer
var pause_exit_button: Button
var pause_resume_button: Button
var pause_previous_focus: Control
var pause_fullscreen_button: Button
var sound_button: Button
var ui_audio: AudioStreamPlayer
var sound_streams: Dictionary = {}
var sound_enabled: bool = true
var castle_section: String = "council"
var selected_person: String = "spouse"
var people_list_open: bool = false
var intro_overlay: Control
var objectives_label: Label
var illustrated_map: IllustratedCapitalMap
var location_scene: Control
var selected_location_id: String = ""
var management_from_location: bool = false
var selected_story_record: Dictionary = {}
var secretary_page: String = "agenda"
var dossier_return_page: String = "agenda"
var battle_view: Control
var interface_root: VBoxContainer
var modal_shade: ColorRect
var panel_tween: Tween
var selected_army_unit: String = "retinue"
var new_campaign_confirmation: bool = false
var exit_confirmation: bool = false

const PEOPLE_ORDER: Array[String] = ["spouse", "sister", "secretary", "radomir", "daren", "borin", "zlata", "miron", "aglaia", "tikhon", "savva", "vardan"]
const PEOPLE_ROLES: Dictionary = {
	"spouse": "Княгиня, жена и распорядительница семейного двора",
	"sister": "Сестра князя, связанная с областными старостами",
	"secretary": "Личный секретарь и хранитель канцелярских дел",
	"radomir": "Воевода полевого войска",
	"daren": "Начальник городской стражи",
	"borin": "Казначей и распорядитель государственных счетов",
	"zlata": "Владелица мастерских и представитель городских нанимателей",
	"miron": "Бывший судья и влиятельный публичный оратор",
	"aglaia": "Хозяйка Дома семи фонарей и сети частных знакомств",
	"tikhon": "Изобретатель и мастер опытных механизмов",
	"savva": "Дворцовый писец",
	"vardan": "Речной торговец"
}

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_create_audio_feedback()
	_create_environment()
	_create_capital_placeholder()
	_create_camera()
	_create_ui()
	_refresh_ui("Выберите место на карте Ардена.")
	if not state.guide.prologue_seen or not state.guide.intro_seen:
		_show_intro()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if pause_overlay.visible:
			_hide_pause_menu()
		elif intro_overlay.visible:
			get_viewport().set_input_as_handled()
			return
		elif period_report_panel.visible:
			_close_period_report()
		elif building_panel.visible:
			_close_building_panel()
		elif secretary_panel.visible:
			_close_secretary()
		elif location_scene != null and location_scene.visible and location_scene.dialogue_layer.visible:
			location_scene.close_dialogue()
		elif location_scene != null and location_scene.visible:
			_close_location_scene()
		else:
			_toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.alt_pressed and event.keycode == KEY_ENTER:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()

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

func _create_audio_feedback() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		sound_enabled = bool(settings.get_value("audio", "enabled", true))
	ui_audio = AudioStreamPlayer.new()
	ui_audio.volume_db = -8.0
	add_child(ui_audio)
	sound_streams = {
		"click": _make_ui_tone(520.0, 0.045, 0.22),
		"decision": _make_ui_tone(690.0, 0.13, 0.28),
		"period": _make_ui_tone(430.0, 0.2, 0.3, 1.5),
		"alert": _make_ui_tone(190.0, 0.28, 0.34, 1.33),
		"battle": _make_ui_tone(120.0, 0.34, 0.4, 1.5)
	}

func _make_ui_tone(frequency: float, duration: float, volume: float, second_ratio: float = 2.0) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := maxi(1, int(duration * mix_rate))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / float(mix_rate)
		var progress := float(index) / float(sample_count)
		var attack := minf(1.0, progress * 18.0)
		var release := pow(1.0 - progress, 2.2)
		var wave := sin(TAU * frequency * time) * 0.72 + sin(TAU * frequency * second_ratio * time) * 0.28
		var sample := clampi(int(wave * attack * release * volume * 32767.0), -32768, 32767)
		data.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream

func _play_ui_sound(sound_id: String) -> void:
	if not sound_enabled or DisplayServer.get_name() == "headless" or not sound_streams.has(sound_id):
		return
	ui_audio.stream = sound_streams[sound_id]
	ui_audio.play()

func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	var settings := ConfigFile.new()
	settings.set_value("audio", "enabled", sound_enabled)
	settings.save(SETTINGS_PATH)
	_refresh_sound_caption()
	if sound_enabled:
		_play_ui_sound("decision")

func _refresh_sound_caption() -> void:
	if is_instance_valid(sound_button):
		sound_button.text = "Звук: включён" if sound_enabled else "Звук: выключен"

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
	_add_building(&"embassy", "Двор иностранных послов", "Здесь принимают соседские миссии, заключают сделки и собирают сведения о чужих дворах.", Vector3(-14.0, 0.0, 9.0), Vector3(5.0, 3.5, 4.0), Color("8d765f"))
	_add_building(&"school", "Старая приходская школа", "Небольшая школа уже работает при писцовой палате, но ей не хватает учителей и отдельного здания.", Vector3(-7.0, 0.0, 11.0), Vector3(4.0, 2.7, 3.0), Color("9a8567"))

	# Quarry remains outside the defended city.
	_add_box("Quarry", Vector3(10.0, 0.7, 8.0), Vector3(-26.0, 0.0, 17.0), Color("807b70"))

func _add_building(id: StringName, title: String, details: String, ground_position: Vector3, size: Vector3, color: Color) -> void:
	var building := CITY_BUILDING.new() as CityBuilding
	building.configure(id, title, details, size, color, USE_3D_PLACEHOLDERS)
	building.position = ground_position
	building.selected.connect(_on_building_selected)
	add_child(building)

func _add_box(node_name: String, size: Vector3, world_position: Vector3, color: Color) -> void:
	if not USE_3D_PLACEHOLDERS:
		return
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

	var root := VBoxContainer.new()
	interface_root = root
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 126)
	root.add_child(header)

	var header_content := VBoxContainer.new()
	header_content.add_theme_constant_override("separation", 5)
	header.add_child(header_content)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	header_content.add_child(header_row)

	var title_column := VBoxContainer.new()
	title_column.custom_minimum_size = Vector2(240, 0)
	header_row.add_child(title_column)

	var title := Label.new()
	title.text = "АРДЕНСКОЕ КНЯЖЕСТВО"
	title.add_theme_font_size_override("font_size", 15)
	title_column.add_child(title)

	date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 22)
	title_column.add_child(date_label)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_spacer)
	cases_button = Button.new()
	cases_button.text = "Дела секретаря · 1"
	cases_button.custom_minimum_size = Vector2(145, 44)
	cases_button.pressed.connect(_open_secretary)
	header_row.add_child(cases_button)

	advance_button = Button.new()
	advance_button.text = "Завершить период"
	advance_button.custom_minimum_size = Vector2(170, 44)
	advance_button.pressed.connect(_on_advance_period)
	header_row.add_child(advance_button)
	for item: Dictionary in [
		{"text": "Новая", "callable": _on_new_campaign},
		{"text": "Сохр.", "callable": _on_save},
		{"text": "Загр.", "callable": _on_load}
	]:
		var button := Button.new()
		button.text = item["text"]
		button.custom_minimum_size = Vector2(64, 44)
		button.pressed.connect(item["callable"])
		header_row.add_child(button)
	exit_button = Button.new()
	exit_button.text = "Выход"
	exit_button.custom_minimum_size = Vector2(68, 44)
	exit_button.tooltip_text = "Сохранить текущую кампанию и выйти из игры"
	exit_button.pressed.connect(_on_exit_requested)
	header_row.add_child(exit_button)
	menu_button = Button.new()
	menu_button.text = "Меню"
	menu_button.custom_minimum_size = Vector2(64, 44)
	menu_button.tooltip_text = "Игровое меню · Esc"
	menu_button.pressed.connect(_toggle_pause_menu)
	header_row.add_child(menu_button)

	resource_label = Label.new()
	resource_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_label.custom_minimum_size = Vector2(0, 48)
	resource_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resource_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resource_label.add_theme_font_size_override("font_size", 14)
	header_content.add_child(resource_label)

	illustrated_map = ILLUSTRATED_MAP.new() as IllustratedCapitalMap
	illustrated_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	illustrated_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	illustrated_map.custom_minimum_size = Vector2(0, 420)
	illustrated_map.building_selected.connect(_on_illustrated_building_selected)
	root.add_child(illustrated_map)

	var objectives_panel := PanelContainer.new()
	objectives_panel.custom_minimum_size = Vector2(0, 42)
	root.add_child(objectives_panel)
	objectives_label = Label.new()
	objectives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objectives_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objectives_panel.add_child(objectives_label)

	var footer := PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 62)
	root.add_child(footer)
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 14)
	footer.add_child(footer_row)
	notice_label = Label.new()
	notice_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notice_label.text = "Перетаскивайте карту · колесо — масштаб · выберите здание для управления"
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer_row.add_child(notice_label)
	period_report_button = Button.new()
	period_report_button.text = "Итоги периода"
	period_report_button.custom_minimum_size = Vector2(145, 42)
	period_report_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	period_report_button.pressed.connect(_open_period_report)
	footer_row.add_child(period_report_button)
	location_scene = LOCATION_SCENE.new()
	location_scene.visible = false
	location_scene.z_index = 50
	location_scene.back_requested.connect(_close_location_scene)
	location_scene.person_selected.connect(_open_character_dialogue)
	location_scene.option_selected.connect(_choose_character_dialogue)
	location_scene.new_case_requested.connect(_open_character_dialogue)
	location_scene.management_requested.connect(_open_location_management)
	layer.add_child(location_scene)
	# Godot uses sibling order for GUI hit testing, regardless of z_index.
	_create_modal_shade(layer)
	_create_building_panel(layer)
	_create_secretary_panel(layer)
	period_report_panel = PERIOD_REPORT.new()
	period_report_panel.z_index = 80
	period_report_panel.dismiss_requested.connect(_close_period_report)
	period_report_panel.secretary_requested.connect(_open_secretary)
	period_report_panel.archive_step_requested.connect(_step_period_report)
	layer.add_child(period_report_panel)
	_create_intro_overlay(layer)
	_create_pause_menu(layer)

func _create_modal_shade(layer: CanvasLayer) -> void:
	modal_shade = ColorRect.new()
	modal_shade.visible = false
	modal_shade.color = Color(0.01, 0.02, 0.018, 0.78)
	modal_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_shade.z_index = 60
	modal_shade.gui_input.connect(_on_modal_shade_input)
	layer.add_child(modal_shade)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.065, 0.052, 0.995)
	style.border_color = Color("b99b54")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0, 0, 0, 0.72)
	style.shadow_size = 18
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style

func _create_intro_overlay(layer: CanvasLayer) -> void:
	intro_overlay = PROLOGUE.new()
	intro_overlay.z_index = 110
	intro_overlay.finished.connect(_finish_intro)
	intro_overlay.burial_finished.connect(_finish_burial)
	intro_overlay.contact_met.connect(_meet_in_prologue)
	layer.add_child(intro_overlay)

func _create_pause_menu(layer: CanvasLayer) -> void:
	pause_overlay = Control.new()
	pause_overlay.visible = false
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.z_index = 120
	layer.add_child(pause_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.018, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(shade)
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-220, -300)
	pause_panel.size = Vector2(440, 600)
	pause_panel.add_theme_stylebox_override("panel", _panel_style())
	pause_overlay.add_child(pause_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	pause_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var marker := Label.new()
	marker.text = "ЦЕНА ВЛАСТИ"
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.modulate = Color("d9bd72")
	column.add_child(marker)
	var title := Label.new()
	title.text = "Игровое меню"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	var hint := Label.new()
	hint.text = "Esc — вернуться в игру · Alt+Enter — полный экран"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color("b9c2b3")
	column.add_child(hint)
	column.add_child(HSeparator.new())
	for item: Dictionary in [
		{"text": "Продолжить", "callable": _hide_pause_menu},
		{"text": "Сохранить кампанию", "callable": _pause_save},
		{"text": "Загрузить сохранение", "callable": _pause_load}
	]:
		var button := Button.new()
		button.text = item["text"]
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(item["callable"])
		column.add_child(button)
	pause_fullscreen_button = Button.new()
	pause_fullscreen_button.custom_minimum_size = Vector2(0, 48)
	pause_fullscreen_button.pressed.connect(_toggle_fullscreen)
	column.add_child(pause_fullscreen_button)
	sound_button = Button.new()
	sound_button.custom_minimum_size = Vector2(0, 48)
	sound_button.pressed.connect(_toggle_sound)
	column.add_child(sound_button)
	_refresh_sound_caption()
	pause_exit_button = Button.new()
	pause_exit_button.text = "Сохранить и выйти"
	pause_exit_button.custom_minimum_size = Vector2(0, 48)
	pause_exit_button.pressed.connect(_on_exit_requested)
	column.add_child(pause_exit_button)
	var focus_order: Array[Button] = []
	for control: Node in column.get_children():
		if control is Button:
			focus_order.append(control)
	pause_resume_button = focus_order[0]
	for index in range(focus_order.size()):
		var button := focus_order[index]
		var previous := button.get_path_to(focus_order[posmod(index - 1, focus_order.size())])
		var next := button.get_path_to(focus_order[(index + 1) % focus_order.size()])
		button.focus_previous = previous
		button.focus_neighbor_top = previous
		button.focus_next = next
		button.focus_neighbor_bottom = next

func _toggle_pause_menu() -> void:
	if pause_overlay.visible:
		_hide_pause_menu()
	else:
		_show_pause_menu()

func _show_pause_menu() -> void:
	_cancel_exit_confirmation()
	_refresh_fullscreen_caption()
	pause_previous_focus = get_viewport().gui_get_focus_owner()
	pause_overlay.visible = true
	pause_resume_button.grab_focus()

func _hide_pause_menu() -> void:
	_cancel_exit_confirmation()
	pause_overlay.visible = false
	if is_instance_valid(pause_previous_focus) and pause_previous_focus.is_visible_in_tree():
		pause_previous_focus.grab_focus()
	pause_previous_focus = null

func _pause_save() -> void:
	_on_save()

func _pause_load() -> void:
	_on_load()
	_hide_pause_menu()

func _toggle_fullscreen() -> void:
	var window := get_window()
	window.mode = Window.MODE_WINDOWED if window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN] else Window.MODE_FULLSCREEN
	_refresh_fullscreen_caption()

func _refresh_fullscreen_caption() -> void:
	if not is_instance_valid(pause_fullscreen_button):
		return
	var fullscreen := get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
	pause_fullscreen_button.text = "Оконный режим" if fullscreen else "На весь экран"

func _show_intro() -> void:
	interface_root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	intro_overlay.restart()

func _intro_next() -> void:
	intro_overlay.advance()

func _meet_in_prologue(person_id: String) -> void:
	state.facts["prologue_met_%s" % person_id] = true

func _finish_intro() -> void:
	state.guide.intro_seen = true
	state.guide.prologue_seen = true
	state.facts["father_warned_of_traitor"] = true
	intro_overlay.visible = false
	interface_root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	_refresh_ui("Первое дело ждёт в канцелярии. Откройте «Дела секретаря».")
	cases_button.grab_focus()

func _create_building_panel(layer: CanvasLayer) -> void:
	building_panel = PanelContainer.new()
	building_panel.visible = false
	building_panel.add_theme_stylebox_override("panel", _panel_style())
	building_panel.z_index = 70
	layer.add_child(building_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 22)
	panel_margin.add_theme_constant_override("margin_top", 20)
	panel_margin.add_theme_constant_override("margin_right", 22)
	panel_margin.add_theme_constant_override("margin_bottom", 20)
	building_panel.add_child(panel_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	panel_margin.add_child(column)

	var top_row := HBoxContainer.new()
	column.add_child(top_row)
	building_context = Label.new()
	building_context.text = "ГОРОДСКОЙ ОБЪЕКТ"
	building_context.modulate = Color("d9bd72")
	building_context.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	building_context.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(building_context)
	building_close_button = Button.new()
	building_close_button.pressed.connect(_close_building_panel)
	top_row.add_child(building_close_button)
	battle_primary_button = Button.new()
	battle_primary_button.visible = false
	battle_primary_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_primary_button.custom_minimum_size.y = 44
	battle_primary_button.pressed.connect(_use_battle_primary_action)
	column.add_child(battle_primary_button)
	building_scroll = ScrollContainer.new()
	building_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	building_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	building_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	building_scroll.follow_focus = true
	column.add_child(building_scroll)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 9)
	building_scroll.add_child(details)
	building_picture = TextureRect.new()
	building_picture.custom_minimum_size = Vector2(0, 170)
	building_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	building_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	building_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(building_picture)
	building_title = Label.new()
	building_title.add_theme_font_size_override("font_size", 25)
	building_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(building_title)
	building_status = Label.new()
	building_status.modulate = Color("d9bd72")
	building_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(building_status)
	building_description = Label.new()
	building_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_description.custom_minimum_size = Vector2(0, 54)
	details.add_child(building_description)
	building_actions = VBoxContainer.new()
	building_actions.add_theme_constant_override("separation", 7)
	building_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(building_actions)
	get_viewport().size_changed.connect(_layout_building_panel)
	_layout_building_panel()

func _layout_building_panel() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var panel_size := Vector2(minf(460, viewport_rect.size.x - 56), minf(650, viewport_rect.size.y - 32))
	building_picture.custom_minimum_size.y = minf(170, panel_size.y * 0.26)
	building_panel.size = panel_size
	building_panel.position = viewport_rect.position + Vector2(viewport_rect.size.x - panel_size.x - 28, (viewport_rect.size.y - panel_size.y) * 0.5)
	building_panel.pivot_offset = panel_size * 0.5

func _create_secretary_panel(layer: CanvasLayer) -> void:
	secretary_panel = PanelContainer.new()
	secretary_panel.visible = false
	secretary_panel.set_anchors_preset(Control.PRESET_CENTER)
	secretary_panel.position = Vector2(-430, -350)
	secretary_panel.size = Vector2(860, 700)
	secretary_panel.add_theme_stylebox_override("panel", _panel_style())
	secretary_panel.z_index = 70
	layer.add_child(secretary_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	secretary_panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var heading := Label.new()
	heading.text = "СЕКРЕТАРЬ КНЯЗЯ"
	heading.add_theme_font_size_override("font_size", 14)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	secretary_close_button = Button.new()
	secretary_close_button.text = "Вернуться к карте"
	secretary_close_button.pressed.connect(_close_secretary)
	top.add_child(secretary_close_button)

	secretary_title = Label.new()
	secretary_title.text = "Похороны князя и просьба об открытии амбаров"
	secretary_title.add_theme_font_size_override("font_size", 27)
	secretary_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(secretary_title)
	secretary_introduction = Label.new()
	secretary_introduction.text = "Два срочных решения требуют вашей печати."
	secretary_introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secretary_introduction.modulate = Color("b9c2b3")
	root.add_child(secretary_introduction)

	secretary_scroll = ScrollContainer.new()
	secretary_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	secretary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(secretary_scroll)
	secretary_case_body = VBoxContainer.new()
	secretary_case_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	secretary_case_body.add_theme_constant_override("separation", 12)
	secretary_scroll.add_child(secretary_case_body)

	resolve_opening_button = Button.new()
	resolve_opening_button.text = "Скрепить решение печатью"
	resolve_opening_button.custom_minimum_size = Vector2(0, 48)
	resolve_opening_button.pressed.connect(_resolve_opening_decision)
	root.add_child(resolve_opening_button)

func _open_secretary() -> void:
	_play_ui_sound("click")
	_close_period_report()
	building_panel.visible = false
	if battle_view != null: battle_view.visible = false
	illustrated_map.visible = true
	illustrated_map.reset_overview()
	secretary_panel.visible = true
	interface_root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	secretary_close_button.grab_focus()
	modal_shade.visible = true
	selected_story_record.clear()
	secretary_page = "epilogue" if state.campaign_outcome.generated else "agenda"
	dossier_return_page = "agenda"
	_reveal_panel(secretary_panel)
	_refresh_secretary_case()
	secretary_scroll.set_deferred("scroll_vertical", 0)

func _close_secretary() -> void:
	var was_open := secretary_panel.visible
	secretary_panel.visible = false
	modal_shade.visible = building_panel.visible
	if was_open:
		interface_root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
		cases_button.grab_focus()

func _refresh_secretary_case() -> void:
	for child in secretary_case_body.get_children():
		secretary_case_body.remove_child(child)
		child.queue_free()
	match secretary_page:
		"dossier":
			_add_seal_dossier()
			return
		"epilogue":
			_add_campaign_outcome()
			return
		"hearing":
			_add_council_hearing()
			return
	_add_selected_story_result()
	if state.campaign_outcome.generated:
		_add_secretary_page_link("Читать итог первой главы", "epilogue")
	_add_council_hearing_link()
	_add_unread_reports()
	var decision := state.opening_decision
	if decision.status == OpeningDecision.Status.RESOLVED:
		var available_count := state.story_timeline.available_events(state.calendar.cycle).size()
		secretary_title.text = "Дела княжеской канцелярии"
		secretary_introduction.text = "Новых дел: %d · последствия принятых решений появляются здесь по мере поступления донесений." % available_count
		if state.army.status in [ArmyState.BattleStatus.DEPLOYMENT, ArmyState.BattleStatus.FIGHTING]:
			var battle_route := Button.new()
			battle_route.text = "К полю боя"
			battle_route.custom_minimum_size.y = 44
			battle_route.pressed.connect(_open_active_battle)
			secretary_case_body.add_child(battle_route)
		if not state.campaign_outcome.generated and state.opening_followup.status == OpeningFollowup.Status.AVAILABLE:
			_add_opening_followup()
		_add_family_debt()
		_add_family_letter()
		if not SEAL_CASE_FILE.entries(state).is_empty():
			var file := Button.new()
			file.text = "Материалы дела о печати"
			file.pressed.connect(_set_seal_dossier.bind(true))
			secretary_case_body.add_child(file)
		_add_pending_story_topics()
		_add_available_story_events()
		_add_story_history()
		_add_read_reports()
		resolve_opening_button.visible = false
		return
	secretary_title.text = "Первые решения нового князя"
	secretary_introduction.text = "Определите церемонию, помощь области и источник средств. Точные последствия заранее неизвестны."

	var funeral_context := Label.new()
	funeral_context.text = "Ночью близкие простились с отцом. Марек ждёт вашего распоряжения о самих похоронах: кого позвать и сколько людей готовить к церемонии."
	funeral_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	funeral_context.modulate = Color("c7d0c3")
	secretary_case_body.add_child(funeral_context)
	_add_choice_section("1 · Похороны старого князя", OpeningDecision.FUNERAL_PLANS, decision.funeral_plan, _choose_funeral)
	funeral_choice_label = Label.new()
	funeral_choice_label.text = _chosen_title(OpeningDecision.FUNERAL_PLANS, decision.funeral_plan)
	secretary_case_body.add_child(funeral_choice_label)
	var grain_context := Label.new()
	grain_context.text = "Лада привела трёх старост из Долинной области. Они просят выдать зерно: в нескольких деревнях его осталось на две недели. По книге один обоз уже дошёл. Отец перед смертью говорил, что в тот день с моста сняли настил. Сейчас нужно решить, отправлять ли помощь до сверки."
	grain_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grain_context.modulate = Color("c7d0c3")
	secretary_case_body.add_child(grain_context)
	_add_choice_section("2 · Что ответить Долинной области", OpeningDecision.GRAIN_RESPONSES, decision.grain_response, _choose_grain)
	grain_choice_label = Label.new()
	grain_choice_label.text = _chosen_title(OpeningDecision.GRAIN_RESPONSES, decision.grain_response)
	secretary_case_body.add_child(grain_choice_label)

	var funding_heading := Label.new()
	funding_heading.text = "3 · Кто оплатит денежные расходы"
	funding_heading.add_theme_font_size_override("font_size", 18)
	secretary_case_body.add_child(funding_heading)
	var funding_explanation := Label.new()
	funding_explanation.text = "Выбранный источник оплатит похороны, а также покупку зерна или перевозку обоза, если они предусмотрены решением. Само зерно для обоза берётся из государственных амбаров."
	funding_explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	funding_explanation.modulate = Color("b9c2b3")
	secretary_case_body.add_child(funding_explanation)
	var funding_row := VBoxContainer.new()
	funding_row.add_theme_constant_override("separation", 6)
	secretary_case_body.add_child(funding_row)
	for source: String in ["state", "family"]:
		var button := Button.new()
		button.text = "Государственная казна" if source == "state" else "Личные средства семьи"
		button.custom_minimum_size = Vector2(0, 44)
		button.disabled = decision.funding_source == source
		button.pressed.connect(_choose_funding.bind(source))
		funding_row.add_child(button)
	funding_choice_label = Label.new()
	funding_choice_label.text = "Выбрано: %s" % ("государственная казна" if decision.funding_source == "state" else "личные средства семьи")
	secretary_case_body.add_child(funding_choice_label)
	var warning := Label.new()
	warning.text = "Секретарь проверит наличие средств перед подписью. Будущая реакция людей и скрытые последствия заранее не показываются."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.modulate = Color("aebbad")
	secretary_case_body.add_child(warning)
	resolve_opening_button.visible = true
	resolve_opening_button.disabled = not decision.can_resolve(state)

func _add_unread_reports() -> void:
	var reports := state.story_timeline.unread_reports()
	if reports.is_empty():
		return
	var heading := Label.new()
	heading.text = "ПОСЛЕДСТВИЯ · %d" % reports.size()
	heading.modulate = Color("e0a96b")
	secretary_case_body.add_child(heading)
	for report: Dictionary in reports:
		var title := Label.new()
		title.text = str(report.get("title", "Новый отчёт"))
		title.add_theme_font_size_override("font_size", 19)
		secretary_case_body.add_child(title)
		var body := Label.new()
		body.text = str(report.get("text", ""))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		secretary_case_body.add_child(body)
	var read := Button.new()
	read.text = "Отметить отчёты прочитанными"
	read.pressed.connect(func():
		state.story_timeline.mark_reports_read()
		_refresh_secretary_case()
	)
	secretary_case_body.add_child(read)
	secretary_case_body.add_child(HSeparator.new())

func _add_opening_followup() -> void:
	var followup := state.opening_followup
	if followup.status != OpeningFollowup.Status.AVAILABLE:
		return
	var divider := HSeparator.new()
	secretary_case_body.add_child(divider)
	var actor: CharacterState = state.characters[followup.actor_id]
	var heading := Label.new()
	heading.text = "%s · %s" % [followup.title, actor.display_name]
	heading.add_theme_font_size_override("font_size", 20)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secretary_case_body.add_child(heading)
	var speech := Label.new()
	speech.text = followup.spoken_text
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secretary_case_body.add_child(speech)
	for response_id: String in followup.response_ids:
		var response := Button.new()
		response.text = followup.response_title(response_id)
		response.custom_minimum_size = Vector2(0, 42)
		response.pressed.connect(_choose_opening_followup.bind(response_id))
		secretary_case_body.add_child(response)

func _choose_opening_followup(response_id: String) -> void:
	if state.opening_followup.choose(state, response_id):
		_show_story_record({"title": state.opening_followup.title, "outcome": state.opening_followup.closing_text})

func _add_available_story_events() -> void:
	var available := state.story_timeline.available_events(state.calendar.cycle)
	if available.is_empty():
		return
	var divider := HSeparator.new()
	secretary_case_body.add_child(divider)
	var agenda_heading := Label.new()
	agenda_heading.text = "НОВЫЕ ДЕЛА · %d" % available.size()
	agenda_heading.modulate = Color("d9bd72")
	secretary_case_body.add_child(agenda_heading)
	for event_id: String in available:
		var event := state.story_timeline.contextual_definition(state, event_id)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_style())
		secretary_case_body.add_child(card)
		var card_margin := MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 16)
		card_margin.add_theme_constant_override("margin_top", 12)
		card_margin.add_theme_constant_override("margin_right", 16)
		card_margin.add_theme_constant_override("margin_bottom", 14)
		card.add_child(card_margin)
		var card_content := VBoxContainer.new()
		card_content.add_theme_constant_override("separation", 8)
		card_margin.add_child(card_content)
		var event_title := Label.new()
		event_title.text = "%s · %s" % [event["title"], event["location"]]
		event_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		event_title.add_theme_font_size_override("font_size", 20)
		card_content.add_child(event_title)
		var summary := Label.new()
		summary.text = event["summary"]
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary.modulate = Color("c7d0c3")
		card_content.add_child(summary)
		var last_cycle := mini(state.story_timeline.opening_cycle(event_id) + 1, CampaignCalendar.MONTH_NAMES.size() * 3)
		if state.calendar.cycle >= last_cycle:
			var deadline := Label.new()
			deadline.text = "Последний период для ответа"
			deadline.modulate = Color("e0a96b")
			card_content.add_child(deadline)
		for choice_id: String in event["choices"]:
			var choice := Button.new()
			choice.text = str(event["choices"][choice_id])
			var cost := state.story_timeline.choice_gold_cost(event_id, choice_id)
			if cost > 0:
				choice.text += " · %d монет" % cost
				if state.state_treasury < cost:
					choice.tooltip_text = "В казне не хватает денег на это распоряжение."
			choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
			choice.custom_minimum_size = Vector2(0, 40)
			choice.disabled = not state.story_timeline.can_choose(state, event_id, choice_id)
			choice.pressed.connect(_choose_story_event.bind(event_id, choice_id))
			card_content.add_child(choice)

func _add_story_history() -> void:
	var history := state.story_timeline.resolved_history(6)
	history.append_array(state.conversations.decision_history())
	history.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["cycle"]) > int(b["cycle"]))
	var verdict: Dictionary = state.facts.get("council_verdict", {})
	if not verdict.is_empty():
		history.push_front({"cycle": int(verdict["cycle"]), "title": "Дело о подложных приказах", "choice": verdict["title"], "outcome": verdict["outcome"]})
	if history.size() > 6:
		history.resize(6)
	if state.opening_followup.status == OpeningFollowup.Status.RESOLVED:
		history.append({"cycle": 1, "title": state.opening_followup.title, "choice": "Личный разговор", "outcome": state.opening_followup.closing_text})
	history.append({"cycle": 1, "title": "Первые решения нового князя", "choice": "Похороны и помощь области", "outcome": _opening_result_text()})
	secretary_case_body.add_child(HSeparator.new())
	var heading := Label.new()
	heading.text = "ЛЕТОПИСЬ РЕШЕНИЙ · ПОСЛЕДНИЕ %d" % history.size()
	heading.modulate = Color("d9bd72")
	secretary_case_body.add_child(heading)
	var explanation := Label.new()
	explanation.text = "Нажмите запись, чтобы снова увидеть уже известный результат."
	explanation.modulate = Color("aebbad")
	secretary_case_body.add_child(explanation)
	for record: Dictionary in history:
		var entry := Button.new()
		entry.text = "Ход %d · %s\n%s" % [int(record["cycle"]), str(record["title"]), str(record["choice"])]
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.custom_minimum_size = Vector2(0, 58)
		entry.tooltip_text = str(record["outcome"])
		entry.pressed.connect(_show_story_record.bind(record))
		secretary_case_body.add_child(entry)

func _add_read_reports() -> void:
	var recent: Array[Dictionary] = []
	var reports := state.story_timeline.reports
	for index in range(reports.size() - 1, -1, -1):
		if bool(reports[index].get("read", false)):
			recent.append(reports[index])
		if recent.size() >= 6:
			break
	if recent.is_empty():
		return
	var heading := Label.new()
	heading.text = "ПРОЧИТАННЫЕ ОТЧЁТЫ"
	heading.modulate = Color("d9bd72")
	secretary_case_body.add_child(heading)
	for report: Dictionary in recent:
		var title := str(report.get("title", "Отчёт"))
		var entry := Button.new()
		entry.text = "Ход %d · %s" % [int(report.get("cycle", 0)), title]
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry.custom_minimum_size.y = 40
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.pressed.connect(_show_story_record.bind({"title": title, "outcome": str(report.get("text", ""))}))
		secretary_case_body.add_child(entry)

func _show_story_record(record: Dictionary) -> void:
	selected_story_record = record.duplicate()
	_refresh_secretary_case()
	secretary_scroll.set_deferred("scroll_vertical", 0)

func _add_selected_story_result() -> void:
	if selected_story_record.is_empty():
		return
	var title := Label.new()
	title.text = str(selected_story_record["title"])
	title.add_theme_font_size_override("font_size", 20)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secretary_case_body.add_child(title)
	var result := Label.new()
	result.name = "StoryResult"
	result.text = str(selected_story_record["outcome"])
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secretary_case_body.add_child(result)

func _add_pending_story_topics() -> void:
	var topics: Array[Dictionary] = state.conversations.pending_story_topics(state)
	if topics.is_empty():
		return
	var heading := Label.new()
	heading.text = "С кем можно поговорить"
	heading.modulate = Color("d9bd72")
	secretary_case_body.add_child(heading)
	for topic: Dictionary in topics:
		var visit := Button.new()
		visit.text = str(topic["label"])
		visit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		visit.alignment = HORIZONTAL_ALIGNMENT_LEFT
		visit.custom_minimum_size = Vector2(0, 40)
		var requested_topic := str(topic.get("option_id", ""))
		if requested_topic.is_empty():
			requested_topic = str(topic.get("city_case", ""))
		visit.pressed.connect(_visit_story_contact.bind(str(topic["location_id"]), str(topic["person_id"]), requested_topic))
		secretary_case_body.add_child(visit)

func _add_family_debt() -> void:
	var terms := state.opening_followup.family_debt_terms(state)
	if terms.is_empty():
		return
	var title := Label.new()
	title.text = str(terms["title"])
	title.add_theme_font_size_override("font_size", 19)
	secretary_case_body.add_child(title)
	var context := Label.new()
	context.text = str(terms["context"])
	context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secretary_case_body.add_child(context)
	for choice_id: String in terms["options"]:
		var option: Dictionary = terms["options"][choice_id]
		var button := Button.new()
		button.text = str(option["title"])
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not option["enabled"]
		button.pressed.connect(_settle_family_debt.bind(choice_id))
		secretary_case_body.add_child(button)

func _settle_family_debt(choice_id: String) -> void:
	var outcome := state.opening_followup.settle_family_debt(state, choice_id)
	if not outcome.is_empty():
		_refresh_ui(outcome)
		_show_story_record({"title": "Семейное обещание", "outcome": outcome})

func _add_family_letter() -> void:
	var terms := FAMILY_CORRESPONDENCE.terms(state)
	if terms.is_empty():
		return
	var heading := Label.new()
	heading.text = str(terms["title"])
	heading.add_theme_font_size_override("font_size", 19)
	secretary_case_body.add_child(heading)
	var context := Label.new()
	context.text = str(terms["context"])
	context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secretary_case_body.add_child(context)
	for choice_id: String in terms["options"]:
		var choice := Button.new()
		choice.text = str(terms["options"][choice_id])
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice.custom_minimum_size.y = 40
		choice.disabled = not state.can_govern()
		choice.pressed.connect(_reply_to_family_letter.bind(choice_id))
		secretary_case_body.add_child(choice)

func _reply_to_family_letter(choice_id: String) -> void:
	var response := FAMILY_CORRESPONDENCE.choose(state, choice_id)
	if response.is_empty():
		return
	_refresh_ui("Ответ Аделе передан через Ладу.")
	_show_story_record({"title": "Ответ Аделе", "outcome": response})

func _set_seal_dossier(open: bool, return_page: String = "agenda") -> void:
	dossier_return_page = return_page
	_set_secretary_page("dossier" if open else return_page)

func _set_secretary_page(page: String) -> void:
	secretary_page = page
	secretary_close_button.grab_focus()
	_refresh_secretary_case()
	secretary_scroll.set_deferred("scroll_vertical", 0)

func _add_secretary_page_link(caption: String, page: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 40
	if page == "dossier":
		button.pressed.connect(_set_seal_dossier.bind(true, secretary_page))
	else:
		button.pressed.connect(_set_secretary_page.bind(page))
	secretary_case_body.add_child(button)

func _add_council_hearing_link() -> void:
	var terms := COUNCIL_VERDICT.terms(state)
	if terms.is_empty():
		return
	_add_secretary_page_link("Дело о подложных приказах · решение до конца главы", "hearing")

func _add_council_hearing() -> void:
	var terms := COUNCIL_VERDICT.terms(state)
	var verdict: Dictionary = state.facts.get("council_verdict", {})
	secretary_title.text = str(terms.get("title", "Дело о подложных приказах"))
	secretary_introduction.text = "Марек записывает, что вы поручили сделать с делом." if verdict.is_empty() else "Распоряжение внесено в летопись."
	resolve_opening_button.visible = false
	_add_secretary_page_link("← К делам канцелярии", "agenda")
	if not verdict.is_empty():
		_add_hearing_text(str(verdict["title"]), Color("d9bd72"))
		_add_hearing_text(str(verdict["outcome"]))
		return
	if terms.is_empty():
		_add_hearing_text("Сейчас дело недоступно.")
		return
	_add_hearing_text(str(terms["context"]))
	if not SEAL_CASE_FILE.entries(state).is_empty():
		_add_secretary_page_link("Свериться с материалами дела", "dossier")
	for choice_id: String in terms["options"]:
		var option: Dictionary = terms["options"][choice_id]
		var choice := Button.new()
		choice.text = str(option["title"])
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.custom_minimum_size.y = 44
		choice.disabled = not bool(option.get("enabled", true))
		choice.pressed.connect(_choose_council_verdict.bind(choice_id))
		secretary_case_body.add_child(choice)

func _add_hearing_text(text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = color
	secretary_case_body.add_child(label)

func _choose_council_verdict(choice_id: String) -> void:
	var outcome := COUNCIL_VERDICT.choose(state, choice_id)
	if not outcome.is_empty():
		_play_ui_sound("decision")
		_refresh_ui(outcome)
		_set_secretary_page("hearing")

func _add_seal_dossier() -> void:
	secretary_title.text = "Дело о второй печати"
	secretary_introduction.text = "Собранные сведения и то, что по ним пока нельзя установить."
	resolve_opening_button.visible = false
	var back := Button.new()
	back.text = "← К распоряжению о деле" if dossier_return_page == "hearing" else "← К делам канцелярии"
	back.pressed.connect(_set_secretary_page.bind(dossier_return_page))
	secretary_case_body.add_child(back)
	back.grab_focus()
	for entry: Dictionary in SEAL_CASE_FILE.entries(state):
		var heading := Label.new()
		heading.text = "%s · %s" % [entry["title"], entry["status"]]
		heading.modulate = Color("d9bd72")
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		secretary_case_body.add_child(heading)
		var detail := Label.new()
		detail.text = str(entry["text"])
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		secretary_case_body.add_child(detail)

func _visit_story_contact(location_id: String, person_id: String, requested_topic: String) -> void:
	_close_secretary()
	_open_location_scene(location_id)
	_open_character_dialogue(person_id, requested_topic)

func _open_active_battle() -> void:
	_close_secretary()
	_on_illustrated_building_selected(&"barracks")

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.105, 0.078, 0.96)
	style.border_color = Color(0.38, 0.48, 0.32, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	return style

func _choose_story_event(event_id: String, choice_id: String) -> void:
	if state.story_timeline.choose(state, event_id, choice_id):
		_play_ui_sound("decision")
		var outcome := state.story_timeline.outcome(event_id)
		_refresh_ui(outcome)
		_show_story_record({"title": state.story_timeline.definition(event_id)["title"], "outcome": outcome})

func _add_campaign_outcome() -> void:
	var outcome := state.campaign_outcome
	secretary_title.text = "Итог первой главы"
	secretary_introduction.text = outcome.title
	resolve_opening_button.visible = false
	const TOPICS := ["Княжество", "Семья", "Северная граница", "Порядок у власти"]
	for index in outcome.summary_lines.size():
		if index < TOPICS.size():
			var subject := Label.new()
			subject.text = TOPICS[index]
			subject.modulate = Color("d9bd72")
			secretary_case_body.add_child(subject)
		var summary := Label.new()
		summary.text = outcome.summary_lines[index]
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		secretary_case_body.add_child(summary)
	secretary_case_body.add_child(HSeparator.new())
	var hook := Label.new()
	hook.text = outcome.continuation_hook
	hook.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hook.modulate = Color("e0a96b")
	secretary_case_body.add_child(hook)
	_add_secretary_page_link("Открыть летопись и донесения", "agenda")

func _add_choice_section(title: String, choices: Dictionary, selected_id: String, callback: Callable) -> void:
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 18)
	secretary_case_body.add_child(heading)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	secretary_case_body.add_child(row)
	for choice_id: String in choices:
		var button := Button.new()
		button.text = "%s\n%s" % [choices[choice_id]["title"], choices[choice_id].get("description", "")]
		button.custom_minimum_size = Vector2(0, 62)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = selected_id == choice_id
		button.pressed.connect(callback.bind(choice_id))
		row.add_child(button)

func _chosen_title(choices: Dictionary, selected_id: String) -> String:
	if selected_id.is_empty() or not choices.has(selected_id):
		return "Решение пока не выбрано"
	return "Выбрано: %s" % choices[selected_id]["title"]

func _choose_funeral(plan_id: String) -> void:
	state.opening_decision.choose_funeral(plan_id)
	_refresh_secretary_case()

func _choose_grain(response_id: String) -> void:
	state.opening_decision.choose_grain(response_id)
	_refresh_secretary_case()

func _choose_funding(source: String) -> void:
	state.opening_decision.choose_funding(source)
	_refresh_secretary_case()

func _resolve_opening_decision() -> void:
	if not state.opening_decision.resolve(state):
		_refresh_ui("Не хватает выбранного источника средств или зерна")
		_refresh_secretary_case()
		return
	_refresh_ui("Печать поставлена. Секретарь передал распоряжения исполнителям.")
	_show_story_record({"title": "Решения скреплены печатью", "outcome": _opening_result_text()})
	intro_overlay.show_burial(state.opening_decision.funeral_plan)

func _finish_burial() -> void:
	state.facts["burial_seen"] = true
	if secretary_panel.visible:
		secretary_close_button.grab_focus()

func _opening_result_text() -> String:
	var lines: Array[String] = [state.opening_decision.observed_outcome]
	lines.append_array(state.opening_decision.observed_reactions(state))
	return "\n".join(lines)

func _on_building_selected(building: CityBuilding) -> void:
	if selected_building != null:
		selected_building.set_highlighted(false)
	selected_building = building
	if building.building_id == &"castle":
		castle_section = "council"
		people_list_open = false
	selected_building.set_highlighted(true)
	camera_rig.focus_on(building.focus_point())
	building_panel.visible = true
	secretary_panel.visible = false
	modal_shade.visible = true
	interface_root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	var show_battle := building.building_id == &"barracks" and state.army.status != ArmyState.BattleStatus.NONE
	if show_battle:
		_ensure_battle_view()
		battle_view.refresh(state.army, selected_army_unit)
	if battle_view != null:
		battle_view.visible = show_battle
	building_picture.visible = not show_battle
	building_status.visible = not show_battle
	building_description.visible = not show_battle
	building_close_button.text = "← В локацию" if management_from_location else "← К городу"
	building_close_button.grab_focus()
	building_title.text = "Пограничное столкновение" if show_battle else building.display_name
	building_context.text = _building_context(building.building_id)
	building_picture.texture = illustrated_map.preview_for(building.building_id)
	building_status.text = building.building_status
	building_description.text = building.description
	_refresh_building_actions()
	_layout_building_panel()
	building_scroll.scroll_vertical = 0
	_reveal_panel(building_panel)

func _reveal_panel(panel: Control) -> void:
	if panel_tween != null and panel_tween.is_running():
		panel_tween.kill()
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.975, 0.975)
	panel.modulate.a = 0.0
	panel_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 0.18)
	panel_tween.tween_property(panel, "modulate:a", 1.0, 0.16)

func _building_context(building_id: StringName) -> String:
	return {
		&"castle": "ВЛАСТЬ И УПРАВЛЕНИЕ",
		&"keep": "АРХИВ И ПОСЛЕДНИЙ РУБЕЖ",
		&"barracks": "ГАРНИЗОН И ОБОРОНА",
		&"smithy": "РЕМЕСЛО И ВООРУЖЕНИЕ",
		&"granary": "ЗАПАСЫ И СНАБЖЕНИЕ",
		&"market": "ТОРГОВЛЯ И ГОРОЖАНЕ",
		&"temple": "ОБЩИНА И ЗДОРОВЬЕ",
		&"embassy": "ДИПЛОМАТИЯ И РАЗВЕДКА",
		&"school": "ОБРАЗОВАНИЕ И ЗНАНИЯ"
	}.get(building_id, "ГОРОДСКОЙ ОБЪЕКТ")

func _on_illustrated_building_selected(building_id: StringName) -> void:
	_play_ui_sound("click")
	if LOCATION_CATALOG.has_location(String(building_id)) and not (building_id == &"barracks" and state.army.status != ArmyState.BattleStatus.NONE):
		_open_location_scene(String(building_id))
		return
	for child: Node in get_children():
		if child is CityBuilding and (child as CityBuilding).building_id == building_id:
			if building_id != &"barracks" or state.army.status == ArmyState.BattleStatus.NONE:
				illustrated_map.focus_on(building_id)
			_on_building_selected(child as CityBuilding)
			return

func _open_location_scene(location_id: String) -> void:
	var definition: Dictionary = LOCATION_CATALOG.definition(location_id)
	if definition.is_empty():
		return
	selected_location_id = location_id
	management_from_location = false
	building_panel.visible = false
	secretary_panel.visible = false
	modal_shade.visible = false
	var texture: Texture2D = illustrated_map.preview_for(StringName(location_id))
	if definition.has("texture"):
		texture = load(str(definition["texture"])) as Texture2D
	var title := str(definition["title"])
	var hotspots := definition.get("hotspots", {}) as Dictionary
	var people: Array[String] = state.conversations.people_at(location_id, state)
	var profiles: Dictionary = {}
	for person_id: String in people:
		profiles[person_id] = state.conversations.profile(person_id, state)
	location_scene.configure(location_id, title, texture, hotspots, people, state.characters, profiles)
	location_scene.visible = true
	_play_ui_sound("click")

func _close_location_scene() -> void:
	location_scene.close_dialogue()
	location_scene.visible = false
	location_scene.set_navigation_enabled(true)
	selected_location_id = ""
	management_from_location = false
	illustrated_map.visible = true
	illustrated_map.reset_overview()

func _open_character_dialogue(person_id: String, requested_topic: String = "") -> void:
	if not location_scene.visible or person_id not in state.conversations.people_at(selected_location_id, state):
		return
	var cases: Array[Dictionary] = state.conversations.decision_cases(person_id, state)
	var case_data := _find_dialogue_case(cases, requested_topic)
	if case_data.is_empty() and not cases.is_empty():
		case_data = cases[0]
	_show_character_dialogue(person_id, case_data, "", cases)
	_play_ui_sound("click")

func _choose_character_dialogue(person_id: String, option_id: String) -> void:
	if not location_scene.dialogue_layer.visible or location_scene.active_person != person_id:
		return
	var cases: Array[Dictionary] = state.conversations.decision_cases(person_id, state)
	var chosen_case := _find_dialogue_case(cases, option_id)
	if not chosen_case.is_empty() and str(chosen_case["id"]) != location_scene.active_case_id:
		return
	var response: String = state.conversations.choose(state, person_id, option_id)
	if response.is_empty():
		return
	if chosen_case.is_empty():
		_show_character_dialogue(person_id, _find_dialogue_case(cases, location_scene.active_case_id), response, cases)
		_play_ui_sound("click")
		return
	var remaining: Array[Dictionary] = state.conversations.decision_cases(person_id, state)
	_show_character_dialogue(person_id, {}, "", remaining)
	_play_ui_sound("decision")
	_refresh_ui("Решение принято и сохранено в летописи.")

func _find_dialogue_case(cases: Array[Dictionary], topic: String) -> Dictionary:
	if not topic.is_empty():
		for case_data: Dictionary in cases:
			if case_data["id"] == topic or case_data["options"].has(topic):
				return case_data
	return {}

func _show_character_dialogue(person_id: String, case_data: Dictionary, answer: String, cases: Array[Dictionary]) -> void:
	var receipt: Dictionary = state.conversations.latest_decision(person_id) if case_data.is_empty() else {}
	var other_cases: Array[Dictionary] = []
	for entry: Dictionary in cases:
		if entry["id"] != case_data.get("id", ""):
			other_cases.append(entry)
	var view := {
		"case": case_data,
		"questions": state.conversations.question_options(person_id, state),
		"receipt": receipt,
		"answer": answer,
		"can_reply": state.can_govern(),
		"other_cases": other_cases
	}
	var profile: Dictionary = state.conversations.profile(person_id, state).duplicate()
	if state.calendar.cycle <= 2 and state.facts.get("prologue_met_%s" % person_id, false):
		match person_id:
			"secretary":
				profile["prompt"] = "Марек, с которым вы говорили у храма, перенёс книгу отца в канцелярию. Он держит её под рукой, пока старосты ждут ответа."
			"radomir":
				profile["prompt"] = "Радомир сдержал слово, данное у храма. Караулы не меняются до конца похорон, а воевода принёс список людей на воротах."
			"spouse":
				profile["prompt"] = "Адела вернулась из храма к детям. Она ждёт, что вы исполните её просьбу и зайдёте к ним перед приёмом."
	location_scene.show_dialogue(person_id, state.characters[person_id], profile, view)

func _open_location_management(location_id: String) -> void:
	for child: Node in get_children():
		if child is CityBuilding and String((child as CityBuilding).building_id) == location_id:
			management_from_location = true
			location_scene.set_navigation_enabled(false)
			_on_building_selected(child as CityBuilding)
			return

func _on_modal_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if building_panel.visible:
			_close_building_panel()
		elif secretary_panel.visible:
			_close_secretary()

func _ensure_battle_view() -> void:
	if battle_view != null: return
	var battle_script := load("res://world/illustrated_battle_view.gd")
	battle_view = battle_script.new() as Control
	battle_view.visible = false
	battle_view.z_index = 65
	battle_view.connect("friendly_unit_selected", _on_battle_unit_selected)
	var layer := building_panel.get_parent()
	layer.add_child(battle_view)
	layer.move_child(battle_view, building_panel.get_index())
	battle_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_view.offset_left = 28
	battle_view.offset_right = -505
	battle_view.offset_top = 125
	battle_view.offset_bottom = -125

func _on_battle_unit_selected(unit_id: String) -> void:
	selected_army_unit = unit_id
	if building_panel.visible and selected_building != null and selected_building.building_id == &"barracks":
		_refresh_building_actions()

func _refresh_building_actions() -> void:
	battle_primary_button.visible = false
	for child in building_actions.get_children():
		building_actions.remove_child(child)
		child.queue_free()
	if selected_building == null:
		return
	if not state.can_govern():
		var illness := Label.new()
		illness.text = "Князь болен. Осматривать сведения можно после восстановления; действующие стройки, указы и поручения продолжают исполняться. Осталось периодов: %d." % state.incapacitated_periods
		illness.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		illness.modulate = Color("e0a96b")
		building_actions.add_child(illness)
		return
	if selected_building.building_id == &"castle":
		var show_overview := castle_section != "people"
		building_picture.visible = show_overview
		building_status.visible = show_overview
		building_description.visible = show_overview
		_add_castle_navigation()
		if castle_section == "council": _add_council_actions()
		elif castle_section == "policies": _add_policy_actions()
		elif castle_section == "justice": _add_justice_actions()
		else: _add_people_actions()
		return
	if selected_building.building_id == &"embassy":
		_add_diplomacy_actions()
		return
	if selected_building.building_id == &"barracks":
		_add_army_actions()
		return
	var project_id := _project_for_building(selected_building.building_id)
	if not project_id.is_empty():
		_add_development_actions(project_id)
	if selected_building.building_id == &"school":
		_add_technology_actions()
	if selected_building.building_id == &"granary":
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
		elif state.grain_crisis.stage == GrainCrisis.Stage.FINDINGS_READY:
			var record := Button.new()
			record.text = "Принять отчёт к сведению"
			record.pressed.connect(_read_grain_report)
			building_actions.add_child(record)
	else:
		var inspect_button := Button.new()
		inspect_button.text = "Осмотреть объект"
		inspect_button.pressed.connect(_inspect_selected_building)
		building_actions.add_child(inspect_button)

func _project_for_building(building_id: StringName) -> String:
	return {&"granary": "granary", &"smithy": "smithy", &"market": "housing", &"temple": "clinic", &"school": "school"}.get(building_id, "")

func _add_development_actions(project_id: String) -> void:
	var definition: Dictionary = DevelopmentState.PROJECTS[project_id]
	var level := int(state.development.levels.get(project_id, 0))
	var heading := Label.new()
	heading.text = "%s · уровень %d" % [definition["title"], level]
	heading.modulate = Color("d9bd72")
	building_actions.add_child(heading)
	if state.development.active_projects.has(project_id):
		var project: Dictionary = state.development.active_projects[project_id]
		var progress := Label.new()
		progress.text = "Ход работ: %d/%d · работников %d · свободно %d" % [project["progress"], project["target"], project["workers"], state.development.available_workers()]
		progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(progress)
		var workforce := HBoxContainer.new()
		building_actions.add_child(workforce)
		for delta: int in [-5, 5]:
			var button := Button.new()
			button.text = "−5 работников" if delta < 0 else "+5 работников"
			button.disabled = (delta < 0 and int(project["workers"]) < 5) or (delta > 0 and state.development.available_workers() < 5)
			button.pressed.connect(_change_project_workers.bind(project_id, delta))
			workforce.add_child(button)
	else:
		var cost := Label.new()
		cost.text = "Новый этап: %d монет · %d дерева · %d камня" % [definition["gold"], definition["wood"], definition["stone"]]
		cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(cost)
		var start := Button.new()
		start.text = "Начать строительство"
		start.disabled = not state.development.can_start(state, project_id)
		start.pressed.connect(_start_project.bind(project_id))
		building_actions.add_child(start)
	building_actions.add_child(HSeparator.new())

func _start_project(project_id: String) -> void:
	if state.development.start(state, project_id):
		_refresh_ui("Строительство начато. Рабочих можно перераспределять прямо здесь.")
		_refresh_building_actions()

func _change_project_workers(project_id: String, delta: int) -> void:
	if state.development.change_workers(project_id, delta):
		_refresh_ui("Число работников на проекте изменено.")
		_refresh_building_actions()

func _add_technology_actions() -> void:
	var heading := Label.new()
	heading.text = "ИССЛЕДОВАНИЯ"
	heading.modulate = Color("d9bd72")
	building_actions.add_child(heading)
	if not state.technology.active_research.is_empty():
		var technology_id := state.technology.active_research
		var technology: Dictionary = TechnologyState.TECHNOLOGIES[technology_id]
		var active := Label.new()
		active.text = "%s · %d/%d знаний · +%d в месяц" % [technology["title"], state.technology.progress, technology["cost"], state.technology.monthly_output(state)]
		active.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(active)
	else:
		for technology_id: String in TechnologyState.TECHNOLOGIES:
			if technology_id in state.technology.unlocked: continue
			var technology: Dictionary = TechnologyState.TECHNOLOGIES[technology_id]
			var description := Label.new()
			description.text = "%s — %s" % [technology["title"], technology["description"]]
			description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			description.modulate = Color("b9c2b3")
			building_actions.add_child(description)
			var start := Button.new()
			start.text = "Исследовать · %d знаний" % technology["cost"]
			start.pressed.connect(_start_research.bind(technology_id))
			building_actions.add_child(start)
	if not state.technology.unlocked.is_empty():
		var unlocked := Label.new()
		var names: Array[String] = []
		for technology_id: String in state.technology.unlocked: names.append(str(TechnologyState.TECHNOLOGIES[technology_id]["title"]))
		unlocked.text = "Внедрено: " + ", ".join(names)
		unlocked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(unlocked)
	building_actions.add_child(HSeparator.new())

func _start_research(technology_id: String) -> void:
	if state.technology.start(state, technology_id):
		_refresh_ui("Исследование начато. Его скорость зависит от уровня школы.")
		_refresh_building_actions()

func _add_castle_navigation() -> void:
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 6)
	building_actions.add_child(navigation)
	for section: String in ["council", "people", "policies", "justice"]:
		var button := Button.new()
		button.text = {"council": "Совет", "people": "Люди", "policies": "Правила", "justice": "Суд"}[section]
		button.disabled = castle_section == section
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_set_castle_section.bind(section))
		navigation.add_child(button)
	building_actions.add_child(HSeparator.new())

func _set_castle_section(section: String) -> void:
	castle_section = section
	people_list_open = false
	_refresh_building_actions()
	if section == "people":
		building_actions.get_node("PeoplePicker").call_deferred("grab_focus")

func _add_people_actions() -> void:
	var heading := Label.new()
	heading.text = "ЛЮДИ ВОКРУГ ВЛАСТИ"
	heading.modulate = Color("d9bd72")
	building_actions.add_child(heading)
	if not state.characters.has(selected_person) or selected_person not in PEOPLE_ORDER:
		selected_person = "spouse"
	var person: CharacterState = state.characters[selected_person]
	var picker := _people_button("Свернуть список ↑" if people_list_open else "Выбрать человека ↓")
	picker.name = "PeoplePicker"
	picker.pressed.connect(_toggle_people_list)
	building_actions.add_child(picker)
	if people_list_open:
		for person_id: String in PEOPLE_ORDER:
			if not state.characters.has(person_id):
				continue
			var candidate := state.characters[person_id] as CharacterState
			var item := _people_button(candidate.display_name + (" · открыта карточка" if person_id == selected_person else ""))
			item.pressed.connect(_select_person.bind(person_id))
			building_actions.add_child(item)
		return

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	building_actions.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var name_label := Label.new()
	name_label.text = person.display_name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(name_label)
	var role := Label.new()
	role.text = str(PEOPLE_ROLES.get(selected_person, "Участник княжеского двора"))
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role.modulate = Color("c7d0c3")
	content.add_child(role)
	var relation := Label.new()
	relation.text = "Наблюдаемое отношение: %s" % _visible_relationship(person)
	relation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	relation.modulate = Color("d9bd72")
	content.add_child(relation)
	content.add_child(HSeparator.new())
	var memory_heading := Label.new()
	memory_heading.text = "ЧТО ЭТОТ ЧЕЛОВЕК ПОМНИТ"
	memory_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory_heading.modulate = Color("b9c2b3")
	content.add_child(memory_heading)
	if person.memories.is_empty():
		var empty := Label.new()
		empty.text = "Заметных личных решений между вами пока не было."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(empty)
	else:
		var first := maxi(0, person.memories.size() - 3)
		for index in range(person.memories.size() - 1, first - 1, -1):
			var memory: Dictionary = person.memories[index]
			var line := Label.new()
			line.text = "Ход %d · %s" % [int(memory.get("cycle", 0)), str(memory.get("summary", ""))]
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(line)

func _people_button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 44
	return button

func _toggle_people_list() -> void:
	people_list_open = not people_list_open
	_refresh_building_actions()
	building_actions.get_node("PeoplePicker").call_deferred("grab_focus")

func _select_person(person_id: String) -> void:
	selected_person = person_id
	people_list_open = false
	_refresh_building_actions()
	building_actions.get_node("PeoplePicker").call_deferred("grab_focus")

func _visible_relationship(person: CharacterState) -> String:
	if person.resentment >= 15 or person.trust <= -12:
		return "Открытое недоверие. У этого человека есть причины действовать против вас."
	if person.resentment >= 6 or person.trust < 0:
		return "Настороженность. Прежние решения ещё помнят."
	if person.trust >= 28 and person.respect >= 25:
		return "Устойчивая личная и политическая опора."
	if person.trust >= 12 or person.respect >= 18:
		return "Рабочее доверие, которое ещё можно потерять."
	return "Вы присматриваетесь друг к другу."

func _add_policy_actions() -> void:
	var heading := Label.new()
	heading.text = "ПРАВИЛА КНЯЖЕСТВА"
	heading.modulate = Color("d9bd72")
	building_actions.add_child(heading)
	var note := Label.new()
	note.text = "Указы действуют со следующего месячного расчёта. Реакции людей зависят от их положения и интересов."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_actions.add_child(note)
	for category_id: String in GovernancePolicy.CATEGORIES:
		var category: Dictionary = GovernancePolicy.CATEGORIES[category_id]
		var current := str(state.policies.active[category_id])
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_style())
		building_actions.add_child(card)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_bottom", 14)
		card.add_child(margin)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 7)
		margin.add_child(content)
		var sphere := Label.new()
		sphere.text = str(category["sphere"])
		sphere.modulate = Color("d9bd72")
		content.add_child(sphere)
		var category_label := Label.new()
		category_label.text = str(category["title"])
		category_label.add_theme_font_size_override("font_size", 19)
		category_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(category_label)
		var question := Label.new()
		question.text = str(category["question"])
		question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		question.modulate = Color("b9c2b3")
		content.add_child(question)
		var active_rule := Label.new()
		active_rule.text = "Действует: %s\n%s" % [category["options"][current], category["descriptions"][current]]
		active_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		active_rule.add_theme_stylebox_override("normal", _active_rule_style())
		content.add_child(active_rule)
		for option_id: String in category["options"]:
			if option_id == current: continue
			var button := Button.new()
			button.text = "%s\n%s" % [category["options"][option_id], category["descriptions"][option_id]]
			button.custom_minimum_size = Vector2(0, 58)
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.pressed.connect(_enact_policy.bind(category_id, option_id))
			content.add_child(button)

func _active_rule_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.18, 0.10, 0.92)
	style.border_color = Color("8da567")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style

func _enact_policy(category_id: String, option_id: String) -> void:
	if state.policies.enact(state, category_id, option_id):
		_refresh_ui("Новый указ вступил в силу: %s" % GovernancePolicy.CATEGORIES[category_id]["options"][option_id])
		_refresh_building_actions()

func _add_justice_actions() -> void:
	var heading := Label.new()
	heading.text = "СУД И ТЮРЬМА · %d/%d МЕСТ" % [state.justice.prisoners, state.justice.prison_capacity]
	heading.modulate = Color("d9bd72")
	building_actions.add_child(heading)
	_add_authority_actions()
	var cases := state.justice.available_cases()
	if cases.is_empty():
		var empty := Label.new()
		empty.text = "Неразобранных дел сейчас нет."
		building_actions.add_child(empty)
		return
	for case_id: String in cases:
		var court_case: Dictionary = JusticeState.CASES[case_id]
		var title := Label.new()
		title.text = "%s · %s" % [court_case["name"], court_case["charge"]]
		title.add_theme_font_size_override("font_size", 17)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(title)
		var evidence := Label.new()
		evidence.text = "Доказательства: %s" % court_case["evidence"]
		evidence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		evidence.modulate = Color("b9c2b3")
		building_actions.add_child(evidence)
		for option_id: String in court_case["options"]:
			var button := Button.new()
			button.text = str(court_case["options"][option_id])
			button.disabled = not state.justice.can_judge(case_id, option_id)
			button.pressed.connect(_judge_case.bind(case_id, option_id))
			building_actions.add_child(button)
		building_actions.add_child(HSeparator.new())

func _add_authority_actions() -> void:
	var eligible := COURT_AUTHORITY.eligible_people(state)
	if eligible.is_empty():
		return
	var heading := Label.new()
	heading.text = "Распоряжения о чиновниках"
	heading.add_theme_font_size_override("font_size", 18)
	building_actions.add_child(heading)
	for person_id: String in eligible:
		var person := state.characters[person_id] as CharacterState
		var label := Label.new()
		label.text = "%s · %s" % [person.display_name, COURT_AUTHORITY.status_text(state, person_id)]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(label)
		var actions := COURT_AUTHORITY.options(state, person_id)
		for action_id: String in actions:
			var action: Dictionary = actions[action_id]
			var button := Button.new()
			button.text = str(action["title"])
			button.tooltip_text = str(action["context"])
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.disabled = not action["enabled"]
			button.pressed.connect(_confirm_authority_action.bind(person_id, action_id))
			building_actions.add_child(button)
		building_actions.add_child(HSeparator.new())

func _confirm_authority_action(person_id: String, action_id: String) -> void:
	var action: Dictionary = COURT_AUTHORITY.options(state, person_id).get(action_id, {})
	if not action.get("enabled", false):
		return
	if authority_confirmation == null:
		authority_confirmation = ConfirmationDialog.new()
		authority_confirmation.ok_button_text = "Подтвердить приказ"
		authority_confirmation.cancel_button_text = "Отмена"
		authority_confirmation.confirmed.connect(_apply_authority_action)
		add_child(authority_confirmation)
	authority_selected_person = person_id
	authority_selected_action = action_id
	var person := state.characters[person_id] as CharacterState
	authority_confirmation.title = str(action["title"])
	authority_confirmation.dialog_text = "%s\n%s" % [person.display_name, action["context"]]
	authority_confirmation.popup_centered(Vector2i(520, 200))

func _apply_authority_action() -> void:
	var result := COURT_AUTHORITY.choose(state, authority_selected_person, authority_selected_action)
	if result.is_empty():
		return
	_refresh_ui(result)
	_refresh_building_actions()
	var outcome := Label.new()
	outcome.text = result
	outcome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outcome.modulate = Color("e8ca8b")
	building_actions.add_child(outcome)
	building_actions.move_child(outcome, 0)

func _judge_case(case_id: String, option_id: String) -> void:
	if state.justice.judge(state, case_id, option_id):
		_refresh_ui(state.justice.outcome(case_id))
		_refresh_building_actions()

func _add_diplomacy_actions() -> void:
	var heading := Label.new()
	heading.text = "СОСЕДНИЕ ГОСУДАРСТВА"
	heading.modulate = Color("d9bd72")
	building_actions.add_child(heading)
	for neighbor_id: String in DiplomacyState.NEIGHBORS:
		var neighbor: Dictionary = DiplomacyState.NEIGHBORS[neighbor_id]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_style())
		building_actions.add_child(card)
		var card_margin := MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 14)
		card_margin.add_theme_constant_override("margin_top", 12)
		card_margin.add_theme_constant_override("margin_right", 14)
		card_margin.add_theme_constant_override("margin_bottom", 14)
		card.add_child(card_margin)
		var card_content := VBoxContainer.new()
		card_content.add_theme_constant_override("separation", 7)
		card_margin.add_child(card_content)
		var title := Label.new()
		title.text = "%s · %s" % [neighbor["name"], state.diplomacy.relation_label(neighbor_id)]
		title.add_theme_font_size_override("font_size", 18)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_content.add_child(title)
		var leader := Label.new()
		leader.text = str(neighbor["leader"])
		leader.modulate = Color("d9bd72")
		card_content.add_child(leader)
		var profile := Label.new()
		profile.text = "%s\nИзвестно о войске: %s" % [neighbor["character"], state.diplomacy.known_strength(neighbor_id)]
		profile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		profile.modulate = Color("b9c2b3")
		card_content.add_child(profile)
		if int(state.diplomacy.intelligence.get(neighbor_id, 0)) >= 1:
			var intent := Label.new()
			intent.text = "Их интерес: %s\nИх опасение: %s" % [neighbor["goal"], neighbor["fear"]]
			intent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			intent.modulate = Color("c7d0c3")
			card_content.add_child(intent)
		var trade_heading := Label.new()
		trade_heading.text = "ТОРГОВЫЕ ПРЕДЛОЖЕНИЯ"
		trade_heading.modulate = Color("d9bd72")
		card_content.add_child(trade_heading)
		for good_id: String in neighbor["goods"]:
			var trade := Button.new()
			trade.text = "Купить 10 %s · %d монет" % [_resource_name(good_id), state.diplomacy.pack_price(neighbor_id, good_id)]
			trade.disabled = state.state_treasury < state.diplomacy.pack_price(neighbor_id, good_id)
			trade.pressed.connect(_buy_diplomatic_pack.bind(neighbor_id, good_id))
			card_content.add_child(trade)
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 4)
		card_content.add_child(actions)
		var spy := Button.new()
		spy.text = "Разведать"
		spy.disabled = not state.diplomacy.can_spy(state, neighbor_id)
		spy.pressed.connect(_spy_neighbor.bind(neighbor_id))
		actions.add_child(spy)
		var threaten := Button.new()
		threaten.text = "Надавить"
		threaten.pressed.connect(_threaten_neighbor.bind(neighbor_id))
		actions.add_child(threaten)
		var sabotage := Button.new()
		sabotage.text = "Диверсия"
		sabotage.disabled = not state.diplomacy.can_sabotage(state, neighbor_id)
		sabotage.pressed.connect(_sabotage_neighbor.bind(neighbor_id))
		actions.add_child(sabotage)

func _resource_name(good_id: String) -> String:
	return {"grain": "зерна", "wood": "древесины", "tools": "инструментов", "worked_iron": "железа", "weapons": "оружия"}.get(good_id, good_id)

func _buy_diplomatic_pack(neighbor_id: String, good_id: String) -> void:
	if state.diplomacy.buy_pack(state, neighbor_id, good_id):
		_refresh_ui("Сделка заключена. Цена следующих переговоров уже учитывает новые отношения.")
		_refresh_building_actions()

func _spy_neighbor(neighbor_id: String) -> void:
	if state.diplomacy.spy(state, neighbor_id):
		_refresh_ui("Разведка вернулась с более точной оценкой сил соседа.")
		_refresh_building_actions()

func _threaten_neighbor(neighbor_id: String) -> void:
	if state.diplomacy.threaten(state, neighbor_id):
		var succeeded := state.diplomacy.last_action(neighbor_id) == "threat_succeeded"
		_refresh_ui("Сосед уступил и снизил цены." if succeeded else "Угроза не подкреплена достаточной силой; отношения ухудшились.")
		_refresh_building_actions()

func _sabotage_neighbor(neighbor_id: String) -> void:
	if state.diplomacy.sabotage(state, neighbor_id):
		_refresh_ui("Операция проведена. Её политическая цена проявится, если исполнителей раскроют.")
		_refresh_building_actions()

func _add_army_actions() -> void:
	if state.army.status == ArmyState.BattleStatus.NONE:
		var quiet := Label.new()
		quiet.text = "Боевого приказа нет. Разведка и решения на северной границе могут открыть столкновение."
		quiet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(quiet)
		return
	var active_units: Array[String] = []
	for unit_id: String in state.army.friendly:
		if int(state.army.friendly[unit_id]["count"]) > 0:
			active_units.append(unit_id)
	if selected_army_unit not in active_units and not active_units.is_empty():
		selected_army_unit = active_units[0]
	battle_view.refresh(state.army, selected_army_unit)
	var stage: String = {
		ArmyState.BattleStatus.DEPLOYMENT: "Расстановка",
		ArmyState.BattleStatus.FIGHTING: "Ход %d" % state.army.turn,
		ArmyState.BattleStatus.VICTORY: "Победа",
		ArmyState.BattleStatus.DEFEAT: "Поражение",
		ArmyState.BattleStatus.RETREATED: "Войско отступило"
	}.get(state.army.status, "")
	var terrain := Label.new()
	terrain.text = "%s · провиант %d\n%s" % [stage, state.army.supplies, state.army.terrain.capitalize()]
	terrain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_actions.add_child(terrain)
	if state.army.status in [ArmyState.BattleStatus.DEPLOYMENT, ArmyState.BattleStatus.FIGHTING]:
		var objective := Label.new()
		objective.text = state.army.objective_text()
		objective.tooltip_text = state.army.defence_orders_text()
		objective.mouse_filter = Control.MOUSE_FILTER_PASS
		objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		objective.modulate = Color("c7d0c3")
		building_actions.add_child(objective)
	if state.army.status == ArmyState.BattleStatus.DEPLOYMENT:
		battle_primary_button.text = "Начать бой"
		battle_primary_button.disabled = false
		battle_primary_button.visible = true
		_add_selected_army_orders()
	elif state.army.status == ArmyState.BattleStatus.FIGHTING:
		battle_primary_button.text = "Завершить ход"
		battle_primary_button.disabled = not state.army.ready_to_resolve()
		battle_primary_button.visible = true
		if battle_primary_button.disabled:
			battle_primary_button.text += " · приказы %d/%d" % [state.army.pending_orders.size(), active_units.size()]
		_add_selected_army_orders()
	if not state.army.battle_log.is_empty():
		var last: Dictionary = state.army.battle_log.back()
		var log := Label.new()
		log.text = "Итог хода %d · наши потери: %s · потери врага: %s" % [last["turn"], _loss_total(last["friendly_losses"]), _loss_total(last["enemy_losses"])]
		log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(log)

func _add_selected_army_orders() -> void:
	var unit: Dictionary = state.army.friendly.get(selected_army_unit, {})
	if unit.is_empty() or int(unit["count"]) <= 0:
		return
	var caption := Label.new()
	caption.text = "%s\n%d бойцов · дух %d · усталость %d" % [ArmyState.UNIT_NAMES[selected_army_unit], unit["count"], unit["morale"], unit["fatigue"]]
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.modulate = Color("d9bd72")
	building_actions.add_child(caption)
	var hint := Label.new()
	hint.text = "Выберите отряд на поле. Каждый отряд получает свой приказ."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_actions.add_child(hint)
	if state.army.status == ArmyState.BattleStatus.DEPLOYMENT:
		var deployment := HBoxContainer.new()
		building_actions.add_child(deployment)
		for depth: int in [1, 2, 3]:
			var depth_button := Button.new()
			depth_button.text = "%d %s" % [depth, "линия" if depth == 1 else "линии"]
			depth_button.disabled = int(unit["depth"]) == depth
			depth_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			depth_button.pressed.connect(_deploy_unit.bind(selected_army_unit, depth))
			deployment.add_child(depth_button)
		return
	for order_id: String in ArmyState.ORDERS[selected_army_unit]:
		var order := Button.new()
		order.text = str(ArmyState.ORDERS[selected_army_unit][order_id])
		order.disabled = str(state.army.pending_orders.get(selected_army_unit, "")) == order_id
		if order.disabled:
			order.text = "✓ " + order.text
		order.custom_minimum_size.y = 40
		order.pressed.connect(_issue_army_order.bind(selected_army_unit, order_id))
		building_actions.add_child(order)

func _loss_total(losses: Dictionary) -> int:
	var result := 0
	for value: int in losses.values(): result += value
	return result

func _use_battle_primary_action() -> void:
	if state.army.status == ArmyState.BattleStatus.DEPLOYMENT:
		_start_army_combat()
	elif state.army.status == ArmyState.BattleStatus.FIGHTING:
		_resolve_army_turn()

func _deploy_unit(unit_id: String, depth: int) -> void:
	if state.army.deploy(unit_id, depth): _refresh_building_actions()

func _start_army_combat() -> void:
	if state.army.start_combat():
		_play_ui_sound("battle")
		_refresh_ui("Бой начался. Выдайте отдельный приказ каждому боеспособному отряду.")
		_refresh_building_actions()

func _issue_army_order(unit_id: String, order_id: String) -> void:
	if state.army.issue_order(unit_id, order_id):
		_refresh_ui("Приказ записан. Ход не завершится, пока остальные отряды не получат команды.")
		_refresh_building_actions()

func _resolve_army_turn() -> void:
	if state.army.resolve_turn():
		_play_ui_sound("battle")
		_refresh_ui("Все приказы выполнены одновременно. Потери показаны в журнале боя.")
		_refresh_building_actions()
		if not state.army.battle_log.is_empty():
			battle_view.call("play_turn", state.army.battle_log.back())

func _add_council_actions() -> void:
	var heading := Label.new()
	heading.text = "СОВЕТ КНЯЗЯ"
	heading.modulate = Color("d9bd72")
	building_actions.add_child(heading)
	var explanation := Label.new()
	explanation.text = "Каждый кандидат полезен по-своему и приносит собственные обязательства. Точные последствия проявятся в работе."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.modulate = Color("b9c2b3")
	building_actions.add_child(explanation)
	for role_id: String in CouncilState.ROLES:
		var current_id := str(state.council.appointments.get(role_id, ""))
		var role_card := PanelContainer.new()
		role_card.add_theme_stylebox_override("panel", _card_style())
		building_actions.add_child(role_card)
		var role_margin := MarginContainer.new()
		role_margin.add_theme_constant_override("margin_left", 14)
		role_margin.add_theme_constant_override("margin_top", 12)
		role_margin.add_theme_constant_override("margin_right", 14)
		role_margin.add_theme_constant_override("margin_bottom", 14)
		role_card.add_child(role_margin)
		var role_content := VBoxContainer.new()
		role_content.add_theme_constant_override("separation", 7)
		role_margin.add_child(role_content)
		var role_label := Label.new()
		role_label.text = str(CouncilState.ROLES[role_id]).to_upper()
		role_label.modulate = Color("d9bd72")
		role_content.add_child(role_label)
		var incumbent := Label.new()
		incumbent.text = "Сейчас: %s" % [CouncilState.CANDIDATES[current_id]["name"] if CouncilState.CANDIDATES.has(current_id) else "должность свободна"]
		incumbent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		role_content.add_child(incumbent)
		for candidate_id: String in state.council.candidates_for(role_id):
			if candidate_id == current_id:
				continue
			var candidate: Dictionary = CouncilState.CANDIDATES[candidate_id]
			role_content.add_child(HSeparator.new())
			var identity := HBoxContainer.new()
			identity.add_theme_constant_override("separation", 10)
			role_content.add_child(identity)
			var initials := Label.new()
			initials.text = _candidate_initials(str(candidate["name"]))
			initials.custom_minimum_size = Vector2(46, 46)
			initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			initials.add_theme_font_size_override("font_size", 18)
			initials.add_theme_stylebox_override("normal", _portrait_badge_style())
			identity.add_child(initials)
			var identity_text := VBoxContainer.new()
			identity_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			identity.add_child(identity_text)
			var name_label := Label.new()
			name_label.text = str(candidate["name"])
			name_label.add_theme_font_size_override("font_size", 18)
			identity_text.add_child(name_label)
			var temperament := Label.new()
			temperament.text = str(candidate["temperament"])
			temperament.modulate = Color("b9c2b3")
			identity_text.add_child(temperament)
			for line in ["Сильная сторона: %s" % candidate["strength"], "Риск: %s" % candidate["risk"], "Связи: %s" % candidate["connections"]]:
				var detail := Label.new()
				detail.text = line
				detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				detail.modulate = Color("c7d0c3")
				role_content.add_child(detail)
			var button := Button.new()
			button.text = "Назначить на должность"
			button.custom_minimum_size = Vector2(0, 42)
			button.tooltip_text = str(candidate["profile"])
			if not COURT_AUTHORITY.is_present(state, candidate_id):
				button.text = COURT_AUTHORITY.status_text(state, candidate_id)
				button.disabled = true
			button.pressed.connect(_appoint_councillor.bind(role_id, candidate_id))
			role_content.add_child(button)

func _candidate_initials(candidate_name: String) -> String:
	var parts := candidate_name.split(" ", false)
	var result := ""
	for part in parts.slice(0, 2):
		result += part.left(1).to_upper()
	return result

func _portrait_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263d31")
	style.border_color = Color("b99b54")
	style.set_border_width_all(2)
	style.set_corner_radius_all(23)
	return style

func _appoint_councillor(role_id: String, candidate_id: String) -> void:
	if state.council.appoint(state, role_id, candidate_id):
		_refresh_ui("Назначение утверждено: %s" % CouncilState.CANDIDATES[candidate_id]["name"])
		_refresh_building_actions()

func _assign_grain_investigation(delegate_id: String) -> void:
	if state.assign_grain_investigation(delegate_id):
		_refresh_ui("Расследование поручено: %s" % GrainCrisis.DELEGATES[delegate_id]["name"])
	_refresh_building_actions()

func _read_grain_report() -> void:
	if state.read_grain_report():
		_refresh_ui("Отчёт по амбарам принят. Его сведения пригодятся в связанных делах.")
		_refresh_building_actions()

func _inspect_selected_building() -> void:
	if selected_building != null:
		_refresh_ui("Осмотрено: %s. Новых срочных проблем не обнаружено." % selected_building.display_name)

func _close_building_panel() -> void:
	building_panel.visible = false
	interface_root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	if battle_view != null: battle_view.visible = false
	if selected_building != null:
		selected_building.set_highlighted(false)
	selected_building = null
	if management_from_location and location_scene.visible:
		management_from_location = false
		modal_shade.visible = false
		location_scene.set_navigation_enabled(true)
		return
	modal_shade.visible = secretary_panel.visible
	illustrated_map.visible = true
	illustrated_map.reset_overview()
	camera_rig.overview()

func _on_advance_period() -> void:
	if period_report_panel.visible or pause_overlay.visible or intro_overlay.visible:
		return
	if state.opening_decision.status != OpeningDecision.Status.RESOLVED and state.can_govern():
		_open_secretary()
		secretary_introduction.text = "Перед первым переходом скрепите печатью решения о похоронах и помощи области."
		return
	var advanced := state.advance_period()
	var save_error := OK
	if advanced:
		save_error = CampaignSaveService.save_campaign(state, autosave_path)
	var unread := state.story_timeline.unread_reports().size()
	var advance_message := "Период завершён"
	if unread > 0:
		advance_message = "Получено новых отчётов: %d — откройте дела секретаря" % unread
	if save_error != OK:
		advance_message = "Период завершён. Автосохранение не записалось: %s" % error_string(save_error)
	_play_ui_sound("alert" if unread > 0 else "period")
	_refresh_ui(advance_message if advanced else "Демоверсия завершена — доступен эпилог")
	if building_panel.visible:
		_refresh_building_actions()
	if advanced:
		_open_period_report()

func _open_period_report() -> void:
	if state.period_report.is_empty():
		return
	interface_root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	period_report_index = state.period_archive.size()
	_step_period_report(0)

func _step_period_report(step: int) -> void:
	var latest_index := state.period_archive.size()
	period_report_index = clampi(period_report_index + step, 0, latest_index)
	var report: Dictionary = state.period_report if period_report_index == latest_index else state.period_archive[period_report_index]
	period_report_panel.show_report(report, period_report_index + 1, latest_index + 1, state.campaign_outcome.generated)

func _close_period_report() -> void:
	if not period_report_panel.visible:
		return
	state.dismiss_period_report()
	period_report_panel.visible = false
	interface_root.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	period_report_button.grab_focus()

func _on_save() -> void:
	var error := CampaignSaveService.save_campaign(state)
	_refresh_ui("Сохранение создано" if error == OK else "Не удалось сохранить: %s" % error_string(error))

func _on_load() -> void:
	var loaded := CampaignSaveService.load_latest(CampaignSaveService.SAVE_PATH, autosave_path)
	if loaded == null:
		_refresh_ui("Сохранение ещё не создано")
		return
	_reset_city_view()
	state = loaded
	_refresh_ui("Сохранение загружено")
	intro_overlay.visible = not state.guide.prologue_seen or not state.guide.intro_seen
	if intro_overlay.visible:
		_show_intro()
	elif not state.period_report.is_empty() and not state.period_report.get("dismissed", false):
		_open_period_report()

func _on_new_campaign() -> void:
	if not new_campaign_confirmation:
		new_campaign_confirmation = true
		_refresh_ui("Нажмите «Новая» ещё раз, чтобы начать заново. Текущее ручное сохранение останется доступно.")
		return
	new_campaign_confirmation = false
	_reset_city_view()
	state = WorldState.new()
	_show_intro()
	_refresh_ui("Начата новая кампания. Предыдущее ручное сохранение не удалено.")

func _reset_city_view() -> void:
	if authority_confirmation != null:
		authority_confirmation.hide()
	_close_period_report()
	_close_secretary()
	_close_location_scene()
	_close_building_panel()

func _on_exit_requested() -> void:
	if not exit_confirmation:
		exit_confirmation = true
		exit_button.text = "Точно?"
		if is_instance_valid(pause_exit_button):
			pause_exit_button.text = "Точно сохранить и выйти?"
		_refresh_ui("Нажмите «Точно?» ещё раз в течение четырёх секунд. Перед выходом игра создаст автосохранение.")
		get_tree().create_timer(4.0).timeout.connect(_cancel_exit_confirmation)
		return
	var error := CampaignSaveService.save_campaign(state, autosave_path)
	if error != OK:
		_cancel_exit_confirmation()
		_refresh_ui("Не удалось создать автосохранение. Выход отменён: %s" % error_string(error))
		return
	get_tree().quit()

func _cancel_exit_confirmation() -> void:
	exit_confirmation = false
	if is_instance_valid(exit_button):
		exit_button.text = "Выход"
	if is_instance_valid(pause_exit_button):
		pause_exit_button.text = "Сохранить и выйти"

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
		if not pause_overlay.visible:
			_show_pause_menu()
		_on_exit_requested()

func _refresh_ui(message: String) -> void:
	date_label.text = state.calendar.display_date()
	resource_label.text = "Казна %d · Личные %d · Жители %d · Зерно %d · Железо %d · Оружие %d\nЗдоровье князя %d · Усталость %d · Здоровье жителей %d · Порядок %d · Недовольство %d" % [
		state.state_treasury,
		state.family_treasury,
		state.population.residents,
		int(state.resources.get("grain", 0)),
		int(state.resources.get("worked_iron", 0)),
		int(state.resources.get("weapons", 0)),
		state.ruler_health,
		state.ruler_fatigue,
		state.public_health,
		state.public_order,
		state.population.unrest
	]
	notice_label.text = message + "    ·    перетаскивание — движение карты · колесо — масштаб"
	advance_button.disabled = state.calendar.is_demo_complete()
	var final_period := state.calendar.month_index == CampaignCalendar.MONTH_NAMES.size() - 1 and state.calendar.period == CampaignCalendar.Period.END
	advance_button.text = "Завершить главу" if final_period or advance_button.disabled else "Завершить период"
	advance_button.tooltip_text = "После этого откроется эпилог. Оставшиеся решения можно принять сейчас." if final_period else ""
	period_report_button.visible = not state.period_report.is_empty()
	var topics: Array[Dictionary] = []
	if state.can_govern() and not state.calendar.is_demo_complete():
		topics = state.conversations.pending_story_topics(state)
	illustrated_map.update_conversation_markers(topics)
	if objectives_label != null:
		var completed := state.guide.completed_count(state)
		var next_goal := "Все вводные цели выполнены"
		for objective: Dictionary in state.guide.objectives(state):
			if not bool(objective["done"]):
				next_goal = str(objective["title"])
				break
		objectives_label.text = "Первые шаги %d/4 · %s" % [completed, next_goal]
	if cases_button != null:
		var open_cases := state.story_timeline.available_events(state.calendar.cycle).size()
		if state.opening_decision.status != OpeningDecision.Status.RESOLVED:
			open_cases += 1
		if state.opening_followup.status == OpeningFollowup.Status.AVAILABLE:
			open_cases += 1
		if not FAMILY_CORRESPONDENCE.terms(state).is_empty():
			open_cases += 1
		if not COUNCIL_VERDICT.terms(state).is_empty():
			open_cases += 1
		open_cases += state.story_timeline.unread_reports().size()
		if state.campaign_outcome.generated:
			cases_button.text = "Эпилог"
		else:
			cases_button.text = "Дела секретаря · %d" % open_cases

