class_name LocationScene
extends Control

const CHARACTER_ACTOR := preload("res://world/character_actor.gd")

signal back_requested
signal person_selected(person_id: String)
signal option_selected(person_id: String, option_id: String)
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
var dialogue_options: VBoxContainer
var active_person: String = ""
var person_hotspots: Dictionary = {}

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

func _create_navigation() -> void:
	var top := HBoxContainer.new()
	top.position = Vector2(26, 24)
	top.size = Vector2(900, 54)
	top.z_index = 5
	add_child(top)
	var back := Button.new()
	back.text = "← К карте города"
	back.custom_minimum_size = Vector2(190, 50)
	back.pressed.connect(func(): back_requested.emit())
	top.add_child(back)
	var title := Label.new()
	title.name = "LocationTitle"
	title.custom_minimum_size = Vector2(360, 50)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("f5e7ba"))
	top.add_child(title)
	var manage := Button.new()
	manage.text = "Управление местом"
	manage.custom_minimum_size = Vector2(190, 50)
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
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER)
	dialogue_panel.add_theme_stylebox_override("panel", _dialogue_style())
	dialogue_layer.add_child(dialogue_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	dialogue_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	margin.add_child(row)
	dialogue_portrait = Control.new()
	dialogue_portrait.custom_minimum_size = Vector2(330, 0)
	row.add_child(dialogue_portrait)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	row.add_child(content)
	var close := Button.new()
	close.text = "← Вернуться в локацию"
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(close_dialogue)
	content.add_child(close)
	dialogue_name = Label.new()
	dialogue_name.add_theme_font_size_override("font_size", 28)
	content.add_child(dialogue_name)
	dialogue_role = Label.new()
	dialogue_role.modulate = Color("d9bd72")
	dialogue_role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(dialogue_role)
	dialogue_prompt = Label.new()
	dialogue_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_prompt.modulate = Color("c7d0c3")
	content.add_child(dialogue_prompt)
	content.add_child(HSeparator.new())
	dialogue_response = Label.new()
	dialogue_response.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_response.add_theme_font_size_override("font_size", 17)
	dialogue_response.custom_minimum_size = Vector2(0, 80)
	content.add_child(dialogue_response)
	dialogue_options = VBoxContainer.new()
	dialogue_options.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_options.add_theme_constant_override("separation", 8)
	content.add_child(dialogue_options)
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
		child.queue_free()
	person_actors.clear()
	for person_id: String in people:
		var character: CharacterState = characters[person_id]
		var profile: Dictionary = profiles.get(person_id, {})
		var actor := CHARACTER_ACTOR.new()
		actor.size = Vector2(150, 270)
		actor.configure(person_id, character.display_name, str(profile.get("role", "")))
		actor.tooltip_text = str(profile.get("prompt", "Поговорить"))
		actor.selected.connect(func(id: String): person_selected.emit(id))
		people_layer.add_child(actor)
		person_actors[person_id] = actor
	call_deferred("_layout_people")

func show_dialogue(person_id: String, character: CharacterState, profile: Dictionary, options: Dictionary, response: String = "") -> void:
	active_person = person_id
	dialogue_name.text = character.display_name
	dialogue_role.text = str(profile.get("role", ""))
	dialogue_prompt.text = str(profile.get("prompt", ""))
	dialogue_response.text = response if not response.is_empty() else "«%s»" % str(profile.get("opening", ""))
	for child in dialogue_portrait.get_children():
		child.queue_free()
	var portrait_actor := CHARACTER_ACTOR.new()
	portrait_actor.position = Vector2(70, 70)
	portrait_actor.size = Vector2(190, 430)
	portrait_actor.configure(person_id, character.display_name, "", false)
	portrait_actor.set_speaking(true)
	dialogue_portrait.add_child(portrait_actor)
	for child in dialogue_options.get_children():
		child.queue_free()
	if options.is_empty():
		var complete := Label.new()
		complete.text = "Все доступные сейчас темы уже обсуждены. Новые обстоятельства могут открыть другой разговор."
		complete.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		complete.modulate = Color("b9c2b3")
		dialogue_options.add_child(complete)
	else:
		for option_id: String in options:
			var choice := Button.new()
			choice.text = str((options[option_id] as Dictionary).get("title", option_id))
			choice.custom_minimum_size = Vector2(0, 46)
			choice.pressed.connect(func(): option_selected.emit(person_id, option_id))
			dialogue_options.add_child(choice)
	dialogue_layer.visible = true

func close_dialogue() -> void:
	dialogue_layer.visible = false
	active_person = ""

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
	var panel_size := Vector2(minf(960.0, size.x - 40.0), minf(620.0, size.y - 40.0))
	panel_size.x = maxf(panel_size.x, 720.0 if size.x >= 760.0 else size.x - 16.0)
	panel_size.y = maxf(panel_size.y, 520.0 if size.y >= 560.0 else size.y - 16.0)
	dialogue_panel.size = panel_size
	dialogue_panel.position = (size - panel_size) * 0.5

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
