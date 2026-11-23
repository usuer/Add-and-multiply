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
var secretary_panel: PanelContainer
var secretary_case_body: VBoxContainer
var funeral_choice_label: Label
var grain_choice_label: Label
var funding_choice_label: Label
var resolve_opening_button: Button
var cases_button: Button

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
	_create_secretary_panel(layer)

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
	cases_button = Button.new()
	cases_button.text = "Дела секретаря · 1"
	cases_button.custom_minimum_size = Vector2(155, 44)
	cases_button.pressed.connect(_open_secretary)
	header_row.add_child(cases_button)

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

func _create_secretary_panel(layer: CanvasLayer) -> void:
	secretary_panel = PanelContainer.new()
	secretary_panel.visible = false
	secretary_panel.set_anchors_preset(Control.PRESET_CENTER)
	secretary_panel.position = Vector2(-390, -330)
	secretary_panel.size = Vector2(780, 660)
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

	var title := Label.new()
	title.text = "Похороны князя и просьба об открытии амбаров"
	title.add_theme_font_size_override("font_size", 27)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(title)
	var introduction := Label.new()
	introduction.text = "Милорд, двор ожидает решения о церемонии. Одновременно из Долинной области пришла просьба о зерне. Мы можем разделить источники средств и не обязаны ограничиваться простым отказом."
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(introduction)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	secretary_case_body = VBoxContainer.new()
	secretary_case_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	secretary_case_body.add_theme_constant_override("separation", 12)
	scroll.add_child(secretary_case_body)

	resolve_opening_button = Button.new()
	resolve_opening_button.text = "Скрепить решение печатью"
	resolve_opening_button.custom_minimum_size = Vector2(0, 48)
	resolve_opening_button.pressed.connect(_resolve_opening_decision)
	root.add_child(resolve_opening_button)

func _open_secretary() -> void:
	building_panel.visible = false
	secretary_panel.visible = true
	_refresh_secretary_case()

func _close_secretary() -> void:
	secretary_panel.visible = false

func _refresh_secretary_case() -> void:
	for child in secretary_case_body.get_children():
		child.queue_free()
	_add_unread_reports()
	var decision := state.opening_decision
	if decision.status == OpeningDecision.Status.RESOLVED:
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
		_add_campaign_outcome()
		resolve_opening_button.visible = false
		return

	_add_choice_section("1 · Церемония", OpeningDecision.FUNERAL_PLANS, decision.funeral_plan, _choose_funeral)
	funeral_choice_label = Label.new()
	funeral_choice_label.text = _chosen_title(OpeningDecision.FUNERAL_PLANS, decision.funeral_plan)
	secretary_case_body.add_child(funeral_choice_label)
	_add_choice_section("2 · Помощь области", OpeningDecision.GRAIN_RESPONSES, decision.grain_response, _choose_grain)
	grain_choice_label = Label.new()
	grain_choice_label.text = _chosen_title(OpeningDecision.GRAIN_RESPONSES, decision.grain_response)
	secretary_case_body.add_child(grain_choice_label)

	var funding_heading := Label.new()
	funding_heading.text = "3 · Источник средств"
	funding_heading.add_theme_font_size_override("font_size", 18)
	secretary_case_body.add_child(funding_heading)
	var funding_row := HBoxContainer.new()
	secretary_case_body.add_child(funding_row)
	for source: String in ["state", "family"]:
		var button := Button.new()
		button.text = "Государственная казна" if source == "state" else "Личные средства семьи"
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
		var event := state.story_timeline.definition(event_id)
		var event_title := Label.new()
		event_title.text = "%s · %s" % [event["title"], event["location"]]
		event_title.add_theme_font_size_override("font_size", 20)
		secretary_case_body.add_child(event_title)
		var summary := Label.new()
		summary.text = event["summary"]
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		secretary_case_body.add_child(summary)
		for choice_id: String in event["choices"]:
			var choice := Button.new()
			choice.text = str(event["choices"][choice_id])
			choice.custom_minimum_size = Vector2(0, 40)
			choice.disabled = not state.story_timeline.can_choose(state, event_id, choice_id)
			choice.pressed.connect(_choose_story_event.bind(event_id, choice_id))
			secretary_case_body.add_child(choice)

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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	secretary_case_body.add_child(row)
	for choice_id: String in choices:
		var button := Button.new()
		button.text = str(choices[choice_id]["title"])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

