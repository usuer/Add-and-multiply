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

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	map_root = Control.new()
	map_root.size = MAP_SIZE
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
		button.text = str(hotspot["title"])
		button.position = hotspot["position"] - Vector2(62, 22)
		button.size = Vector2(124, 44)
		button.add_theme_font_size_override("font_size", 16)
		button.tooltip_text = "Открыть: %s" % hotspot["title"]
		button.pressed.connect(_select_building.bind(StringName(building_id)))
		map_root.add_child(button)
	call_deferred("_fit_map")

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

func _select_building(building_id: StringName) -> void:
	building_selected.emit(building_id)
