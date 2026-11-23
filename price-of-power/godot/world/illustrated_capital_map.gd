class_name IllustratedCapitalMap
extends Control

signal building_selected(building_id: StringName)

const CAPITAL_TEXTURE: Texture2D = preload("res://assets/art/arden_capital.png")
const MAP_SIZE := Vector2(1586, 992)
const HOTSPOTS: Dictionary = {
	"castle": {"title": "Замок", "position": Vector2(365, 205)},
	"embassy": {"title": "Двор послов", "position": Vector2(345, 430)},
	"market": {"title": "Рынок", "position": Vector2(760, 450)},
	"temple": {"title": "Храм", "position": Vector2(1010, 215)},
	"school": {"title": "Школа", "position": Vector2(1100, 320)},
	"granary": {"title": "Амбары", "position": Vector2(1170, 500)},
	"smithy": {"title": "Кузница", "position": Vector2(985, 705)},
	"barracks": {"title": "Казармы", "position": Vector2(640, 715)}
}

var map_root: Control
var _zoom_factor: float = 1.0
var _base_scale: float = 1.0
var _dragging: bool = false
var _last_pointer: Vector2
var _focus_tween: Tween

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	map_root = Control.new()
	map_root.size = MAP_SIZE
	map_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_root)
	var picture := TextureRect.new()
	picture.texture = CAPITAL_TEXTURE
	picture.size = MAP_SIZE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_root.add_child(picture)
	for building_id: String in HOTSPOTS:
		var hotspot: Dictionary = HOTSPOTS[building_id]
		var button := Button.new()
		button.text = "◆  %s" % hotspot["title"]
		button.position = hotspot["position"] - Vector2(72, 23)
		button.size = Vector2(144, 46)
		button.pivot_offset = button.size * 0.5
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", Color("f5e7ba"))
		button.add_theme_color_override("font_hover_color", Color("fff4cf"))
		button.add_theme_stylebox_override("normal", _marker_style(Color(0.025, 0.075, 0.06, 0.92), Color("b99b54"), 1))
		button.add_theme_stylebox_override("hover", _marker_style(Color(0.08, 0.18, 0.12, 0.98), Color("e0bd68"), 2))
		button.add_theme_stylebox_override("pressed", _marker_style(Color(0.12, 0.24, 0.15, 0.98), Color("f0cf7a"), 2))
		button.tooltip_text = "Открыть: %s" % hotspot["title"]
		button.pressed.connect(_select_building.bind(StringName(building_id)))
		button.mouse_entered.connect(_animate_marker.bind(button, 1.045))
		button.mouse_exited.connect(_animate_marker.bind(button, 1.0))
		map_root.add_child(button)
	call_deferred("_fit_map")

func _marker_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.58)
	style.shadow_size = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	return style

func _animate_marker(button: Button, target_scale: float) -> void:
	var tween := button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * target_scale, 0.12)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and map_root != null:
		_fit_map()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and mouse.pressed:
			var old_scale := _current_scale()
			_zoom_factor = clampf(_zoom_factor * (1.08 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else 0.92), 1.0, 2.2)
			var new_scale := _current_scale()
			var local_anchor := (mouse.position - map_root.position) / old_scale
			map_root.position = mouse.position - local_anchor * new_scale
			_apply_transform()
			accept_event()
		elif mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			_dragging = mouse.pressed
			_last_pointer = mouse.position
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		map_root.position += motion.position - _last_pointer
		_last_pointer = motion.position
		_apply_transform()
		accept_event()

func _fit_map() -> void:
	if size.x <= 1.0 or size.y <= 1.0: return
	_base_scale = maxf(size.x / MAP_SIZE.x, size.y / MAP_SIZE.y)
	_zoom_factor = maxf(1.0, _zoom_factor)
	map_root.position = (size - MAP_SIZE * _current_scale()) * 0.5
	_apply_transform()

func _current_scale() -> float:
	return _base_scale * _zoom_factor

func _apply_transform() -> void:
	var scale_value := _current_scale()
	map_root.scale = Vector2.ONE * scale_value
	var rendered := MAP_SIZE * scale_value
	if rendered.x <= size.x:
		map_root.position.x = (size.x - rendered.x) * 0.5
	else:
		map_root.position.x = clampf(map_root.position.x, size.x - rendered.x, 0.0)
	if rendered.y <= size.y:
		map_root.position.y = (size.y - rendered.y) * 0.5
	else:
		map_root.position.y = clampf(map_root.position.y, size.y - rendered.y, 0.0)

func focus_on(building_id: StringName) -> void:
	if not HOTSPOTS.has(String(building_id)) or size.x <= 1.0: return
	if _focus_tween != null and _focus_tween.is_running(): _focus_tween.kill()
	_zoom_factor = 1.55
	var target_scale := _current_scale()
	var hotspot: Vector2 = HOTSPOTS[String(building_id)]["position"]
	var target_position := _clamped_position(size * 0.5 - hotspot * target_scale, target_scale)
	_focus_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_focus_tween.tween_property(map_root, "scale", Vector2.ONE * target_scale, 0.38)
	_focus_tween.parallel().tween_property(map_root, "position", target_position, 0.38)

func reset_overview() -> void:
	if _focus_tween != null and _focus_tween.is_running(): _focus_tween.kill()
	_zoom_factor = 1.0
	var target_scale := _current_scale()
	var target_position := _clamped_position((size - MAP_SIZE * target_scale) * 0.5, target_scale)
	_focus_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_focus_tween.tween_property(map_root, "scale", Vector2.ONE * target_scale, 0.38)
	_focus_tween.parallel().tween_property(map_root, "position", target_position, 0.38)

func preview_for(building_id: StringName) -> Texture2D:
	if not HOTSPOTS.has(String(building_id)):
		return CAPITAL_TEXTURE
	var center: Vector2 = HOTSPOTS[String(building_id)]["position"]
	var preview_size := Vector2(560, 300)
	var origin := center - preview_size * 0.5
	origin.x = clampf(origin.x, 0.0, MAP_SIZE.x - preview_size.x)
	origin.y = clampf(origin.y, 0.0, MAP_SIZE.y - preview_size.y)
	var atlas := AtlasTexture.new()
	atlas.atlas = CAPITAL_TEXTURE
	atlas.region = Rect2(origin, preview_size)
	return atlas

func _clamped_position(candidate: Vector2, scale_value: float) -> Vector2:
	var result := candidate
	var rendered := MAP_SIZE * scale_value
	result.x = (size.x - rendered.x) * 0.5 if rendered.x <= size.x else clampf(result.x, size.x - rendered.x, 0.0)
	result.y = (size.y - rendered.y) * 0.5 if rendered.y <= size.y else clampf(result.y, size.y - rendered.y, 0.0)
	return result

func _select_building(building_id: StringName) -> void:
	building_selected.emit(building_id)
