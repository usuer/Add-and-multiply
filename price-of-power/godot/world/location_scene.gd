class_name LocationScene
extends Control

const CHARACTER_ACTOR := preload("res://world/character_actor.gd")

signal back_requested
signal person_selected(person_id: String)
signal option_selected(person_id: String, option_id: String)
signal new_case_requested(person_id: String, case_id: String)
signal management_requested(location_id: String)

var location_id: String = ""
var location_title: String = ""
var background_texture: Texture2D
var background: TextureRect
var people_layer: Control
var person_actors: Dictionary = {}
var dialogue_layer: Control
var dialogue_panel: PanelContainer
var dialogue_portrait: Control
var dialogue_name: Label
var dialogue_role: Label
var dialogue_prompt: Label
var dialogue_response: Label
var dialogue_answer: Label
var dialogue_case_heading: Label
var dialogue_options: VBoxContainer
var dialogue_scroll: ScrollContainer
var dialogue_cost: Label
var active_person: String = ""
var active_case_id: String = ""
var person_hotspots: Dictionary = {}
var dialogue_close: Button
var portrait_actor: Control
var navigation_bar: HBoxContainer
var navigation_back: Button
var navigation_manage: Button
var navigation_enabled: bool = true

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	background = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.015, 0.03, 0.025, 0.12)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	people_layer = Control.new()
	people_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	people_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(people_layer)
	_create_navigation()
	_create_dialogue_layer()
	resized.connect(_layout_scene)
	visibility_changed.connect(_focus_on_entry)

func _create_navigation() -> void:
	var top := HBoxContainer.new()
	navigation_bar = top
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 18
	top.offset_bottom = 68
	top.add_theme_constant_override("separation", 16)
	top.z_index = 5
	add_child(top)
	var back := Button.new()
	navigation_back = back
	back.text = "← К карте города"
	back.custom_minimum_size.y = 50
	back.pressed.connect(func(): back_requested.emit())
	top.add_child(back)
	var title := Label.new()
	title.name = "LocationTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("f5e7ba"))
	top.add_child(title)
	var manage := Button.new()
	navigation_manage = manage
	manage.text = "Управление местом"
	manage.custom_minimum_size.y = 50
	manage.pressed.connect(func(): management_requested.emit(location_id))
	top.add_child(manage)

func _create_dialogue_layer() -> void:
	dialogue_layer = Control.new()
	dialogue_layer.visible = false
	dialogue_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_layer.z_index = 20
	add_child(dialogue_layer)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.012, 0.01, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(_on_dialogue_shade_input)
	dialogue_layer.add_child(shade)
	dialogue_panel = PanelContainer.new()
	dialogue_panel.add_theme_stylebox_override("panel", _dialogue_style())
	dialogue_layer.add_child(dialogue_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	dialogue_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	margin.add_child(row)
	dialogue_portrait = Control.new()
	dialogue_portrait.custom_minimum_size.x = 210
	dialogue_portrait.clip_contents = true
	dialogue_portrait.resized.connect(_layout_portrait)
	row.add_child(dialogue_portrait)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	row.add_child(content)
	var close := Button.new()
	dialogue_close = close
	close.text = "← Вернуться в локацию"
	close.tooltip_text = "Закрыть разговор (Esc)"
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(close_dialogue)
	content.add_child(close)
	dialogue_scroll = ScrollContainer.new()
	dialogue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialogue_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	dialogue_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_scroll.follow_focus = true
	content.add_child(dialogue_scroll)
	var conversation := VBoxContainer.new()
	conversation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conversation.add_theme_constant_override("separation", 8)
	dialogue_scroll.add_child(conversation)
	dialogue_name = Label.new()
	dialogue_name.add_theme_font_size_override("font_size", 28)
	dialogue_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conversation.add_child(dialogue_name)
	dialogue_role = Label.new()
	dialogue_role.modulate = Color("d9bd72")
	dialogue_role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conversation.add_child(dialogue_role)
	dialogue_case_heading = _dialogue_heading("")
	conversation.add_child(dialogue_case_heading)
	dialogue_prompt = Label.new()
	dialogue_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_prompt.modulate = Color("c7d0c3")
	conversation.add_child(dialogue_prompt)
	conversation.add_child(HSeparator.new())
	dialogue_response = Label.new()
	dialogue_response.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_response.add_theme_font_size_override("font_size", 17)
	conversation.add_child(dialogue_response)
	dialogue_answer = Label.new()
	dialogue_answer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_answer.modulate = Color("ddd0b2")
	conversation.add_child(dialogue_answer)
	dialogue_cost = Label.new()
	dialogue_cost.text = "Решение окончательное. Усталость +1."
	dialogue_cost.add_theme_color_override("font_color", Color("d9bd72"))
	dialogue_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conversation.add_child(dialogue_cost)
	dialogue_options = VBoxContainer.new()
	dialogue_options.add_theme_constant_override("separation", 8)
	conversation.add_child(dialogue_options)
	_layout_dialogue()

func configure(new_location_id: String, title: String, texture: Texture2D, hotspots: Dictionary, people: Array[String], characters: Dictionary, profiles: Dictionary) -> void:
	location_id = new_location_id
	location_title = title
	background_texture = texture
	person_hotspots = hotspots.duplicate(true)
	background.texture = texture
	var title_label := find_child("LocationTitle", true, false) as Label
	title_label.text = title
	for child in people_layer.get_children():
		people_layer.remove_child(child)
		child.queue_free()
	person_actors.clear()
	var focus_order: Array[Control] = [navigation_back, navigation_manage]
	for person_id: String in people:
		var character: CharacterState = characters[person_id]
		var profile: Dictionary = profiles.get(person_id, {})
		var actor := CHARACTER_ACTOR.new()
		actor.size = Vector2(150, 270)
		actor.configure(person_id, character.display_name, str(profile.get("role", "")))
		actor.tooltip_text = "%s · Поговорить" % character.display_name
		actor.selected.connect(func(id: String): person_selected.emit(id))
		people_layer.add_child(actor)
		person_actors[person_id] = actor
		focus_order.append(actor)
	_cycle_focus(focus_order)
	call_deferred("_layout_people")

func show_dialogue(person_id: String, character: CharacterState, profile: Dictionary, view: Dictionary) -> void:
	if active_person != person_id or portrait_actor == null:
		if portrait_actor != null:
			dialogue_portrait.remove_child(portrait_actor)
			portrait_actor.queue_free()
		var actor := CHARACTER_ACTOR.new()
		actor.configure(person_id, character.display_name, "", false)
		actor.set_speaking(true)
		portrait_actor = actor
		dialogue_portrait.add_child(portrait_actor)
		_layout_portrait()
	active_person = person_id
	var case_data: Dictionary = view.get("case", {})
	var receipt: Dictionary = view.get("receipt", {})
	var questions: Dictionary = view.get("questions", {})
	var can_reply: bool = view.get("can_reply", true)
	var options: Dictionary = case_data.get("options", {})
	active_case_id = str(case_data.get("id", ""))
	dialogue_name.text = character.display_name
	dialogue_role.text = str(profile.get("role", ""))
	var case_title := str(case_data.get("title", ""))
	dialogue_case_heading.text = "Решение принято" if not receipt.is_empty() else case_title
	dialogue_case_heading.visible = not dialogue_case_heading.text.is_empty()
	dialogue_prompt.text = str(case_data.get("brief", profile.get("prompt", ""))) if receipt.is_empty() else str(receipt.get("title", ""))
	dialogue_prompt.visible = not dialogue_prompt.text.is_empty()
	dialogue_response.text = str(receipt.get("response", ""))
	if case_data.is_empty() and receipt.is_empty() and not str(profile.get("opening", "")).is_empty():
		dialogue_response.text = "«%s»" % str(profile["opening"])
	dialogue_response.visible = not dialogue_response.text.is_empty()
	dialogue_answer.text = str(view.get("answer", ""))
	dialogue_answer.visible = not dialogue_answer.text.is_empty()
	for child in dialogue_options.get_children():
		dialogue_options.remove_child(child)
		child.queue_free()
	dialogue_cost.visible = can_reply and not options.is_empty()
	var focus_order: Array[Control] = [dialogue_close]
	if can_reply and not questions.is_empty():
		dialogue_options.add_child(_dialogue_heading("Вопросы · без последствий"))
		_add_dialogue_choices(questions, focus_order)
	if dialogue_cost.visible:
		dialogue_options.add_child(_dialogue_heading("Как распорядиться"))
		_add_dialogue_choices(options, focus_order)
	var other_cases: Array = view.get("other_cases", [])
	if can_reply and not other_cases.is_empty():
		dialogue_options.add_child(_dialogue_heading("Другие дела"))
		for other: Dictionary in other_cases:
			var next_case := Button.new()
			next_case.text = str(other["title"]) + " →"
			next_case.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			next_case.custom_minimum_size.y = 44
			next_case.pressed.connect(_open_other_case.bind(str(other["id"])))
			dialogue_options.add_child(next_case)
			focus_order.append(next_case)
	if not can_reply or (options.is_empty() and questions.is_empty() and receipt.is_empty()):
		var complete := Label.new()
		complete.text = "Сейчас у собеседника нет нового дела."
		if not can_reply:
			complete.text = "Князю сейчас нужен отдых. К разговору можно вернуться, когда он сможет заниматься делами."
		complete.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		complete.modulate = Color("b9c2b3")
		dialogue_options.add_child(complete)
	_cycle_focus(focus_order)
	dialogue_layer.visible = true
	dialogue_close.grab_focus()
	dialogue_scroll.scroll_vertical = 0

func _dialogue_heading(text: String) -> Label:
	var heading := Label.new()
	heading.text = text
	heading.modulate = Color("d9bd72")
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 17)
	return heading

func _open_other_case(case_id: String) -> void:
	new_case_requested.emit(active_person, case_id)

func _add_dialogue_choices(options: Dictionary, focus_order: Array[Control]) -> void:
	for option_id: String in options:
		var choice := Button.new()
		var option: Dictionary = options[option_id]
		choice.text = str(option.get("title", option_id))
		if option.get("asked", false):
			choice.text += " · ответ уже известен"
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.custom_minimum_size.y = 42
		choice.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		choice.pressed.connect(func(): option_selected.emit(active_person, option_id))
		dialogue_options.add_child(choice)
		focus_order.append(choice)

func _cycle_focus(focus_order: Array[Control]) -> void:
	for index in range(focus_order.size()):
		var control := focus_order[index]
		var previous := control.get_path_to(focus_order[posmod(index - 1, focus_order.size())])
		var next := control.get_path_to(focus_order[(index + 1) % focus_order.size()])
		control.focus_previous = previous
		control.focus_next = next
		control.focus_neighbor_top = previous
		control.focus_neighbor_bottom = next
		control.focus_neighbor_left = NodePath(".")
		control.focus_neighbor_right = NodePath(".")

func _focus_on_entry() -> void:
	if navigation_enabled and is_visible_in_tree() and not dialogue_layer.visible:
		navigation_back.grab_focus()

func set_navigation_enabled(enabled: bool) -> void:
	navigation_enabled = enabled
	var focus_behavior := Control.FOCUS_BEHAVIOR_INHERITED if enabled else Control.FOCUS_BEHAVIOR_DISABLED
	navigation_bar.focus_behavior_recursive = focus_behavior
	people_layer.focus_behavior_recursive = focus_behavior
	if enabled and is_visible_in_tree() and not dialogue_layer.visible:
		navigation_manage.grab_focus()

func close_dialogue() -> void:
	var actor := person_actors.get(active_person) as Control
	dialogue_layer.visible = false
	active_person = ""
	active_case_id = ""
	if navigation_enabled and actor != null and actor.is_visible_in_tree():
		actor.grab_focus()

func _layout_people() -> void:
	if background_texture == null or size.x < 2.0 or size.y < 2.0:
		return
	var source := background_texture.get_size()
	var scale_value := maxf(size.x / source.x, size.y / source.y)
	var rendered := source * scale_value
	var offset := (size - rendered) * 0.5
	for person_id: String in person_actors:
		var actor: Control = person_actors[person_id]
		var normalized: Vector2 = person_hotspots.get(person_id, Vector2(0.5, 0.6))
		var point := offset + normalized * rendered
		actor.size = Vector2(clampf(size.x * 0.12, 125, 180), clampf(size.y * 0.34, 220, 330))
		actor.position = point - Vector2(actor.size.x * 0.5, actor.size.y * 0.54)
		actor.position.x = clampf(actor.position.x, 18.0, size.x - actor.size.x - 18.0)
		actor.position.y = clampf(actor.position.y, 88.0, size.y - actor.size.y - 18.0)

func _layout_scene() -> void:
	_layout_people()
	_layout_dialogue()

func _layout_dialogue() -> void:
	if dialogue_panel == null:
		return
	var panel_size := Vector2(clampf(size.x - 40.0, 0.0, 900.0), clampf(size.y - 40.0, 0.0, 590.0))
	dialogue_portrait.visible = panel_size.x >= 700.0 and panel_size.y >= 360.0
	dialogue_panel.size = panel_size
	dialogue_panel.position = (size - panel_size) * 0.5

func _layout_portrait() -> void:
	if portrait_actor == null:
		return
	portrait_actor.size = Vector2(minf(190.0, dialogue_portrait.size.x), minf(430.0, dialogue_portrait.size.y))
	portrait_actor.position = (dialogue_portrait.size - portrait_actor.size) * 0.5

func _on_dialogue_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_dialogue()

func _dialogue_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.055, 0.043, 0.995)
	style.border_color = Color("b99b54")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 24
	return style
