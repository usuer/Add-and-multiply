extends Node3D

const CAPITAL_CAMERA := preload("res://world/capital_camera.gd")
const CITY_BUILDING := preload("res://world/city_building.gd")
const ILLUSTRATED_MAP := preload("res://world/illustrated_capital_map.gd")
const CAPITAL_ART: Texture2D = preload("res://assets/art/arden_capital.png")
const FATHER_LAST_NIGHT_ART: Texture2D = preload("res://assets/art/fathers_last_night.png")
const USE_3D_PLACEHOLDERS: bool = false

var state: WorldState = WorldState.new()
var date_label: Label
var resource_label: Label
var notice_label: Label
var camera_rig: CapitalCamera
var selected_building: CityBuilding
var building_panel: PanelContainer
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
var secretary_introduction: Label
var funeral_choice_label: Label
var grain_choice_label: Label
var funding_choice_label: Label
var resolve_opening_button: Button
var cases_button: Button
var exit_button: Button
var castle_section: String = "council"
var selected_person: String = "spouse"
var intro_overlay: Control
var intro_title: Label
var intro_body: Label
var intro_page_label: Label
var intro_back_button: Button
var intro_next_button: Button
var intro_picture: TextureRect
var intro_page: int = 0
var objectives_label: Label
var illustrated_map: IllustratedCapitalMap
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
	"savva": "Дворцовый писец, связанный с похищением второй печати",
	"vardan": "Речной торговец и организатор собственной силовой сети"
}

const INTRO_PAGES: Array[Dictionary] = [
	{"title": "Последняя ночь старого князя", "body": "Отец зовёт вас незадолго до рассвета. Лекари уже вышли из комнаты. На столе лежат зерновые книги, сломанная печать и карта северных дорог. «Я оставляю тебе не трон, а множество обещаний, данных разным людям», — говорит он."},
	{"title": "Предупреждение, которое он не успел закончить", "body": "Отец просит защитить Ладу и проверить пропавшее зерно. Затем показывает на сломанную печать: «Кто-то в моём совете передавал северянам наши дороги. Не обвиняй первого, на кого укажут. Ищи того, кому выгодно…» Последнее имя он произнести не успевает."},
	{"title": "На рассвете власть переходит к вам", "body": "К полудню город узнаёт о смерти князя. Семья ждёт решения о похоронах, из Долинной области требуют открыть амбары, а старые советники уже спорят, какой приказ вы должны подписать первым. Отказ отвечать тоже станет решением."},
	{"title": "Арденское княжество · весна 1248 года", "body": "Вы наследуете действующее государство: укреплённую столицу, чиновников, ремесленные кварталы и области со своими интересами. Казна не пуста, но почти у каждого запаса есть прежнее назначение."},
	{"title": "Город — главное меню", "body": "Выбирайте здания на карте. Замок открывает совет, правила и суд; амбар — расследование; казармы — армию; двор послов — торговлю и разведку. Некоторые проблемы ухудшаются, если оставить их без ответа."}
]

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_create_environment()
	_create_capital_placeholder()
	_create_camera()
	_create_ui()
	_refresh_ui("Первая техническая сцена: укреплённый Арден")
	if not state.guide.prologue_seen or not state.guide.intro_seen:
		_show_intro()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.alt_pressed and event.keycode == KEY_ENTER:
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN] else Window.MODE_FULLSCREEN
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
	_create_modal_shade(layer)
	_create_building_panel(layer)
	_create_secretary_panel(layer)
	_create_intro_overlay(layer)

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

	var next_button := Button.new()
	next_button.text = "Завершить период"
	next_button.custom_minimum_size = Vector2(170, 44)
	next_button.pressed.connect(_on_advance_period)
	header_row.add_child(next_button)
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
	notice_label = Label.new()
	notice_label.text = "Перетаскивайте карту · колесо — масштаб · выберите здание для управления"
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(notice_label)

func _create_modal_shade(layer: CanvasLayer) -> void:
	modal_shade = ColorRect.new()
	modal_shade.visible = false
	modal_shade.color = Color(0.01, 0.02, 0.018, 0.78)
	modal_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	intro_overlay = Control.new()
	intro_overlay.visible = false
	intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(intro_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.045, 0.04, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-410, -350)
	panel.size = Vector2(820, 700)
	intro_overlay.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	intro_page_label = Label.new()
	intro_page_label.modulate = Color("d9bd72")
	column.add_child(intro_page_label)
	intro_picture = TextureRect.new()
	intro_picture.texture = FATHER_LAST_NIGHT_ART
	intro_picture.custom_minimum_size = Vector2(0, 285)
	intro_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intro_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	intro_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(intro_picture)
	intro_title = Label.new()
	intro_title.add_theme_font_size_override("font_size", 28)
	intro_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(intro_title)
	intro_body = Label.new()
	intro_body.add_theme_font_size_override("font_size", 18)
	intro_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(intro_body)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 10)
	column.add_child(navigation)
	intro_back_button = Button.new()
	intro_back_button.text = "Назад"
	intro_back_button.pressed.connect(_intro_back)
	navigation.add_child(intro_back_button)
	var nav_spacer := Control.new()
	nav_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(nav_spacer)
	intro_next_button = Button.new()
	intro_next_button.custom_minimum_size = Vector2(190, 46)
	intro_next_button.pressed.connect(_intro_next)
	navigation.add_child(intro_next_button)

func _show_intro() -> void:
	intro_page = 0
	intro_overlay.visible = true
	_refresh_intro()

func _refresh_intro() -> void:
	var page: Dictionary = INTRO_PAGES[intro_page]
	intro_page_label.text = "ВВЕДЕНИЕ · %d/%d" % [intro_page + 1, INTRO_PAGES.size()]
	intro_title.text = page["title"]
	intro_body.text = page["body"]
	intro_picture.texture = FATHER_LAST_NIGHT_ART if intro_page < 3 else CAPITAL_ART
	intro_back_button.disabled = intro_page == 0
	intro_next_button.text = "Начать правление" if intro_page == INTRO_PAGES.size() - 1 else "Далее"

func _intro_back() -> void:
	intro_page = maxi(0, intro_page - 1)
	_refresh_intro()

func _intro_next() -> void:
	if intro_page < INTRO_PAGES.size() - 1:
		intro_page += 1
		_refresh_intro()
		return
	state.guide.intro_seen = true
	state.guide.prologue_seen = true
	state.facts["father_warned_of_traitor"] = true
	intro_overlay.visible = false
	_refresh_ui("Первое дело ждёт в канцелярии. Откройте «Дела секретаря».")

func _create_building_panel(layer: CanvasLayer) -> void:
	building_panel = PanelContainer.new()
	building_panel.visible = false
	building_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	building_panel.position = Vector2(-488, -325)
	building_panel.size = Vector2(460, 650)
	building_panel.add_theme_stylebox_override("panel", _panel_style())
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
	building_context.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(building_context)
	var close_button := Button.new()
	close_button.text = "← К городу"
	close_button.pressed.connect(_close_building_panel)
	top_row.add_child(close_button)
	building_picture = TextureRect.new()
	building_picture.custom_minimum_size = Vector2(0, 170)
	building_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	building_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	building_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(building_picture)
	building_title = Label.new()
	building_title.add_theme_font_size_override("font_size", 25)
	building_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(building_title)
	building_status = Label.new()
	building_status.modulate = Color("d9bd72")
	column.add_child(building_status)
	building_description = Label.new()
	building_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_description.custom_minimum_size = Vector2(0, 54)
	column.add_child(building_description)
	var actions_scroll := ScrollContainer.new()
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(actions_scroll)
	building_actions = VBoxContainer.new()
	building_actions.add_theme_constant_override("separation", 7)
	building_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_scroll.add_child(building_actions)

func _create_secretary_panel(layer: CanvasLayer) -> void:
	secretary_panel = PanelContainer.new()
	secretary_panel.visible = false
	secretary_panel.set_anchors_preset(Control.PRESET_CENTER)
	secretary_panel.position = Vector2(-430, -350)
	secretary_panel.size = Vector2(860, 700)
	secretary_panel.add_theme_stylebox_override("panel", _panel_style())
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
	var close := Button.new()
	close.text = "Вернуться к карте"
	close.pressed.connect(_close_secretary)
	top.add_child(close)

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
	building_panel.visible = false
	if battle_view != null: battle_view.visible = false
	illustrated_map.visible = true
	illustrated_map.reset_overview()
	secretary_panel.visible = true
	modal_shade.visible = true
	_reveal_panel(secretary_panel)
	_refresh_secretary_case()

func _close_secretary() -> void:
	secretary_panel.visible = false
	modal_shade.visible = building_panel.visible

func _refresh_secretary_case() -> void:
	for child in secretary_case_body.get_children():
		child.queue_free()
	_add_unread_reports()
	var decision := state.opening_decision
	if decision.status == OpeningDecision.Status.RESOLVED:
		var available_count := state.story_timeline.available_events(state.calendar.cycle).size()
		secretary_title.text = "Дела княжеской канцелярии"
		secretary_introduction.text = "Новых дел: %d · последствия принятых решений появляются здесь по мере поступления донесений." % available_count
		var result_heading := Label.new()
		result_heading.text = "РЕШЕНИЕ ПРИНЯТО"
		result_heading.modulate = Color("d9bd72")
		secretary_case_body.add_child(result_heading)
		var result := Label.new()
		result.text = decision.observed_outcome
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		secretary_case_body.add_child(result)
		var reactions_heading := Label.new()
		reactions_heading.text = "Что уже заметно"
		reactions_heading.add_theme_font_size_override("font_size", 20)
		secretary_case_body.add_child(reactions_heading)
		for reaction: String in decision.observed_reactions(state):
			var reaction_label := Label.new()
			reaction_label.text = "• " + reaction
			reaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			secretary_case_body.add_child(reaction_label)
		_add_opening_followup()
		_add_available_story_events()
		_add_story_history()
		_add_campaign_outcome()
		resolve_opening_button.visible = false
		return
	secretary_title.text = "Первые решения нового князя"
	secretary_introduction.text = "Определите церемонию, помощь области и источник средств. Точные последствия заранее неизвестны."

	var funeral_context := Label.new()
	funeral_context.text = "Отец умер этой ночью. До полудня нужно решить, как простится с ним княжеский дом и приглашать ли представителей дальних областей."
	funeral_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	funeral_context.modulate = Color("c7d0c3")
	secretary_case_body.add_child(funeral_context)
	_add_choice_section("1 · Похороны старого князя", OpeningDecision.FUNERAL_PLANS, decision.funeral_plan, _choose_funeral)
	funeral_choice_label = Label.new()
	funeral_choice_label.text = _chosen_title(OpeningDecision.FUNERAL_PLANS, decision.funeral_plan)
	secretary_case_body.add_child(funeral_choice_label)
	var grain_context := Label.new()
	grain_context.text = "Из Долинной области приехали трое старост. После двух слабых урожаев, паводка и падежа скота запасов нескольких деревень хватит примерно на две недели. В областных книгах зерно числится, но старосты утверждают, что амбары почти пусты."
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
	state.story_timeline.mark_reports_read()
	secretary_case_body.add_child(HSeparator.new())

func _add_opening_followup() -> void:
	var followup := state.opening_followup
	if followup.status == OpeningFollowup.Status.LOCKED:
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
	if followup.status == OpeningFollowup.Status.RESOLVED:
		var closing := Label.new()
		closing.text = followup.closing_text
		closing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		secretary_case_body.add_child(closing)
		return
	for response_id: String in followup.response_ids:
		var response := Button.new()
		response.text = followup.response_title(response_id)
		response.custom_minimum_size = Vector2(0, 42)
		response.pressed.connect(_choose_opening_followup.bind(response_id))
		secretary_case_body.add_child(response)

func _choose_opening_followup(response_id: String) -> void:
	if state.opening_followup.choose(state, response_id):
		_refresh_secretary_case()

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
		event_title.add_theme_font_size_override("font_size", 20)
		card_content.add_child(event_title)
		var summary := Label.new()
		summary.text = event["summary"]
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary.modulate = Color("c7d0c3")
		card_content.add_child(summary)
		for choice_id: String in event["choices"]:
			var choice := Button.new()
			choice.text = str(event["choices"][choice_id])
			choice.custom_minimum_size = Vector2(0, 40)
			choice.disabled = not state.story_timeline.can_choose(state, event_id, choice_id)
			choice.pressed.connect(_choose_story_event.bind(event_id, choice_id))
			card_content.add_child(choice)

func _add_story_history() -> void:
	var history := state.story_timeline.resolved_history(6)
	if history.is_empty():
		return
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
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.custom_minimum_size = Vector2(0, 58)
		entry.tooltip_text = str(record["outcome"])
		entry.pressed.connect(_show_story_record.bind(record))
		secretary_case_body.add_child(entry)

func _show_story_record(record: Dictionary) -> void:
	var result := str(record.get("outcome", ""))
	if result.is_empty():
		result = "Подробный результат этого решения пока не известен."
	_refresh_ui(result)

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.105, 0.078, 0.96)
	style.border_color = Color(0.38, 0.48, 0.32, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	return style

func _choose_story_event(event_id: String, choice_id: String) -> void:
	if state.story_timeline.choose(state, event_id, choice_id):
		var outcome := state.story_timeline.outcome(event_id)
		_refresh_ui(outcome)
		_refresh_secretary_case()

func _add_campaign_outcome() -> void:
	var outcome := state.campaign_outcome
	if not outcome.generated:
		return
	secretary_case_body.add_child(HSeparator.new())
	var marker := Label.new()
	marker.text = "ИТОГ ПЕРВОЙ ГЛАВЫ"
	marker.modulate = Color("d9bd72")
	secretary_case_body.add_child(marker)
	var title := Label.new()
	title.text = outcome.title
	title.add_theme_font_size_override("font_size", 23)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secretary_case_body.add_child(title)
	for line: String in outcome.summary_lines:
		var summary := Label.new()
		summary.text = line
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		secretary_case_body.add_child(summary)
	var hook := Label.new()
	hook.text = outcome.continuation_hook
	hook.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hook.modulate = Color("e0a96b")
	secretary_case_body.add_child(hook)

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
	else:
		_refresh_ui("Печать поставлена. Секретарь передал распоряжения исполнителям.")
	_refresh_secretary_case()

func _on_building_selected(building: CityBuilding) -> void:
	if selected_building != null:
		selected_building.set_highlighted(false)
	selected_building = building
	if building.building_id == &"castle": castle_section = "council"
	selected_building.set_highlighted(true)
	camera_rig.focus_on(building.focus_point())
	building_panel.visible = true
	secretary_panel.visible = false
	modal_shade.visible = true
	_reveal_panel(building_panel)
	building_title.text = building.display_name
	building_context.text = _building_context(building.building_id)
	building_picture.texture = illustrated_map.preview_for(building.building_id)
	building_status.text = building.building_status
	building_description.text = building.description
	_refresh_building_actions()

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
	for child: Node in get_children():
		if child is CityBuilding and (child as CityBuilding).building_id == building_id:
			var show_battle := building_id == &"barracks" and state.army.status != ArmyState.BattleStatus.NONE
			illustrated_map.visible = not show_battle
			if show_battle:
				_ensure_battle_view()
				battle_view.visible = true
				battle_view.call("refresh", state.army, selected_army_unit)
			else:
				illustrated_map.focus_on(building_id)
				if battle_view != null: battle_view.visible = false
			_on_building_selected(child as CityBuilding)
			return

func _ensure_battle_view() -> void:
	if battle_view != null: return
	var battle_script := load("res://world/illustrated_battle_view.gd")
	battle_view = battle_script.new() as Control
	battle_view.visible = false
	battle_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_view.custom_minimum_size = Vector2(0, 420)
	battle_view.connect("friendly_unit_selected", _on_battle_unit_selected)
	interface_root.add_child(battle_view)
	interface_root.move_child(battle_view, illustrated_map.get_index() + 1)

func _on_battle_unit_selected(unit_id: String) -> void:
	selected_army_unit = unit_id
	if building_panel.visible and selected_building != null and selected_building.building_id == &"barracks":
		_refresh_building_actions()

func _refresh_building_actions() -> void:
	for child in building_actions.get_children():
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
	_refresh_building_actions()

func _add_people_actions() -> void:
	var heading := Label.new()
	heading.text = "ЛЮДИ ВОКРУГ ВЛАСТИ"
	heading.modulate = Color("d9bd72")
	building_actions.add_child(heading)
	var note := Label.new()
	note.text = "Здесь показано только то, что князь уже мог заметить. Скрытые цели и будущие поступки персонажей не раскрываются."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate = Color("b9c2b3")
	building_actions.add_child(note)
	if not state.characters.has(selected_person) or selected_person not in PEOPLE_ORDER:
		selected_person = "spouse"
	var selector := OptionButton.new()
	selector.custom_minimum_size = Vector2(0, 44)
	var selected_index := 0
	for person_id: String in PEOPLE_ORDER:
		if not state.characters.has(person_id):
			continue
		var index := selector.item_count
		selector.add_item((state.characters[person_id] as CharacterState).display_name)
		selector.set_item_metadata(index, person_id)
		if person_id == selected_person:
			selected_index = index
	selector.select(selected_index)
	selector.item_selected.connect(_select_person.bind(selector))
	building_actions.add_child(selector)

	var person: CharacterState = state.characters[selected_person]
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
	content.add_child(name_label)
	var role := Label.new()
	role.text = str(PEOPLE_ROLES.get(selected_person, "Участник княжеского двора"))
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role.modulate = Color("c7d0c3")
	content.add_child(role)
	var relation := Label.new()
	relation.text = "Наблюдаемое отношение: %s" % _visible_relationship(person)
	relation.modulate = Color("d9bd72")
	content.add_child(relation)
	content.add_child(HSeparator.new())
	var memory_heading := Label.new()
	memory_heading.text = "ЧТО ЭТОТ ЧЕЛОВЕК ПОМНИТ"
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

func _select_person(index: int, selector: OptionButton) -> void:
	selected_person = str(selector.get_item_metadata(index))
	_refresh_building_actions()

func _visible_relationship(person: CharacterState) -> String:
	if person.resentment >= 15 or person.trust <= -12:
		return "открытое недоверие; у него есть причины действовать против вас"
	if person.resentment >= 6 or person.trust < 0:
		return "настороженность; прежние решения не забыты"
	if person.trust >= 28 and person.respect >= 25:
		return "устойчивая личная и политическая опора"
	if person.trust >= 12 or person.respect >= 18:
		return "рабочее доверие, которое ещё можно потерять"
	return "вы присматриваетесь друг к другу"

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
	var heading := Label.new()
	heading.text = "ПОГРАНИЧНОЕ ВОЙСКО"
	heading.modulate = Color("d9bd72")
	building_actions.add_child(heading)
	if state.army.status == ArmyState.BattleStatus.NONE:
		var quiet := Label.new()
		quiet.text = "Боевого приказа нет. Разведка и решения на северной границе могут открыть столкновение."
		quiet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(quiet)
		return
	battle_view.call("refresh", state.army, selected_army_unit)
	var terrain := Label.new()
	terrain.text = "%s · провиант %d" % [state.army.terrain, state.army.supplies]
	terrain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	building_actions.add_child(terrain)
	var enemy_heading := Label.new()
	enemy_heading.text = "Противник"
	building_actions.add_child(enemy_heading)
	for enemy_id: String in state.army.enemy:
		var enemy_unit: Dictionary = state.army.enemy[enemy_id]
		var enemy_label := Label.new()
		enemy_label.text = "%s · %d бойцов · дух %d" % [enemy_unit["name"], enemy_unit["count"], enemy_unit["morale"]]
		building_actions.add_child(enemy_label)
	building_actions.add_child(HSeparator.new())
	for unit_id: String in state.army.friendly:
		var unit: Dictionary = state.army.friendly[unit_id]
		var unit_label := Label.new()
		unit_label.text = "%s · %d бойцов · дух %d · усталость %d" % [ArmyState.UNIT_NAMES[unit_id], unit["count"], unit["morale"], unit["fatigue"]]
		unit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(unit_label)
		if unit_id != selected_army_unit:
			continue
		var selected_marker := Label.new()
		selected_marker.text = "ВЫБРАННЫЙ ОТРЯД · приказы ниже"
		selected_marker.modulate = Color("d9bd72")
		building_actions.add_child(selected_marker)
		if state.army.status == ArmyState.BattleStatus.DEPLOYMENT:
			var deployment := HBoxContainer.new()
			building_actions.add_child(deployment)
			for depth: int in [1, 2, 3]:
				var depth_button := Button.new()
				depth_button.text = "%d %s" % [depth, "линия" if depth == 1 else "линии"]
				depth_button.disabled = int(unit["depth"]) == depth
				depth_button.pressed.connect(_deploy_unit.bind(unit_id, depth))
				deployment.add_child(depth_button)
		elif state.army.status == ArmyState.BattleStatus.FIGHTING and int(unit["count"]) > 0:
			for order_id: String in ArmyState.ORDERS[unit_id]:
				var order := Button.new()
				order.text = str(ArmyState.ORDERS[unit_id][order_id])
				order.disabled = str(state.army.pending_orders.get(unit_id, "")) == order_id
				order.pressed.connect(_issue_army_order.bind(unit_id, order_id))
				building_actions.add_child(order)
		building_actions.add_child(HSeparator.new())
	if state.army.status == ArmyState.BattleStatus.DEPLOYMENT:
		var start := Button.new()
		start.text = "Подтвердить расстановку и начать бой"
		start.pressed.connect(_start_army_combat)
		building_actions.add_child(start)
	elif state.army.status == ArmyState.BattleStatus.FIGHTING:
		var resolve := Button.new()
		resolve.text = "Завершить ход и выполнить все приказы"
		resolve.disabled = not state.army.ready_to_resolve()
		resolve.pressed.connect(_resolve_army_turn)
		building_actions.add_child(resolve)
	if not state.army.battle_log.is_empty():
		var last: Dictionary = state.army.battle_log.back()
		var log := Label.new()
		log.text = "Итог хода %d · наши потери: %s · потери врага: %s" % [last["turn"], _loss_total(last["friendly_losses"]), _loss_total(last["enemy_losses"])]
		log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		building_actions.add_child(log)

func _loss_total(losses: Dictionary) -> int:
	var result := 0
	for value: int in losses.values(): result += value
	return result

func _deploy_unit(unit_id: String, depth: int) -> void:
	if state.army.deploy(unit_id, depth): _refresh_building_actions()

func _start_army_combat() -> void:
	if state.army.start_combat():
		_refresh_ui("Бой начался. Выдайте отдельный приказ каждому боеспособному отряду.")
		_refresh_building_actions()

func _issue_army_order(unit_id: String, order_id: String) -> void:
	if state.army.issue_order(unit_id, order_id):
		_refresh_ui("Приказ записан. Ход не завершится, пока остальные отряды не получат команды.")
		_refresh_building_actions()

func _resolve_army_turn() -> void:
	if state.army.resolve_turn():
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

func _inspect_selected_building() -> void:
	if selected_building != null:
		_refresh_ui("Осмотрено: %s. Новых срочных проблем не обнаружено." % selected_building.display_name)

func _close_building_panel() -> void:
	building_panel.visible = false
	if selected_building != null:
		selected_building.set_highlighted(false)
	selected_building = null
	modal_shade.visible = secretary_panel.visible
	if battle_view != null: battle_view.visible = false
	illustrated_map.visible = true
	illustrated_map.reset_overview()
	camera_rig.overview()

func _on_advance_period() -> void:
	var advanced := state.advance_period()
	if advanced:
		CampaignSaveService.save_campaign(state, CampaignSaveService.AUTOSAVE_PATH)
	var unread := state.story_timeline.unread_reports().size()
	var advance_message := "Период завершён"
	if unread > 0:
		advance_message = "Получено новых отчётов: %d — откройте дела секретаря" % unread
	_refresh_ui(advance_message if advanced else "Демоверсия завершена — доступен эпилог")
	if building_panel.visible:
		_refresh_building_actions()

func _on_save() -> void:
	var error := CampaignSaveService.save_campaign(state)
	_refresh_ui("Сохранение создано" if error == OK else "Не удалось сохранить: %s" % error_string(error))

func _on_load() -> void:
	var loaded := CampaignSaveService.load_latest()
	if loaded == null:
		_refresh_ui("Сохранение ещё не создано")
		return
	state = loaded
	_refresh_ui("Сохранение загружено")
	intro_overlay.visible = not state.guide.prologue_seen or not state.guide.intro_seen
	if intro_overlay.visible:
		intro_page = 0
		_refresh_intro()
	if building_panel.visible:
		_refresh_building_actions()

func _on_new_campaign() -> void:
	if not new_campaign_confirmation:
		new_campaign_confirmation = true
		_refresh_ui("Нажмите «Новая» ещё раз, чтобы начать заново. Текущее ручное сохранение останется доступно.")
		return
	new_campaign_confirmation = false
	building_panel.visible = false
	secretary_panel.visible = false
	state = WorldState.new()
	_show_intro()
	_refresh_ui("Начата новая кампания. Предыдущее ручное сохранение не удалено.")

func _on_exit_requested() -> void:
	if not exit_confirmation:
		exit_confirmation = true
		exit_button.text = "Точно?"
		_refresh_ui("Нажмите «Точно?» ещё раз в течение четырёх секунд. Перед выходом игра создаст автосохранение.")
		get_tree().create_timer(4.0).timeout.connect(_cancel_exit_confirmation)
		return
	var error := CampaignSaveService.save_campaign(state, CampaignSaveService.AUTOSAVE_PATH)
	if error != OK:
		_cancel_exit_confirmation()
		_refresh_ui("Не удалось создать автосохранение. Выход отменён: %s" % error_string(error))
		return
	get_tree().quit()

func _cancel_exit_confirmation() -> void:
	exit_confirmation = false
	if is_instance_valid(exit_button):
		exit_button.text = "Выход"

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
		_on_exit_requested()

func _refresh_ui(message: String) -> void:
	date_label.text = state.calendar.display_date()
	resource_label.text = "Казна %d · Личные %d · Жители %d · Зерно %d · Железо %d · Оружие %d\nКнязь %d · Усталость %d · Здоровье земель %d · Порядок %d · Недовольство %d" % [
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
		open_cases += state.story_timeline.unread_reports().size()
		if state.campaign_outcome.generated:
			open_cases += 1
		cases_button.text = "Дела секретаря · %d" % open_cases

