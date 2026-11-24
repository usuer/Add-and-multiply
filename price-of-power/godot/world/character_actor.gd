class_name CharacterActor
extends Control

signal selected(person_id: String)

const COLORS: Dictionary = {
	"spouse": Color("284d49"), "sister": Color("6a3438"), "secretary": Color("303a43"),
	"borin": Color("6b5538"), "radomir": Color("334c3d"), "daren": Color("57343b"),
	"zlata": Color("75502f"), "miron": Color("424d59"), "aglaia": Color("663d5f"),
	"tikhon": Color("57604a"), "savva": Color("4f4a48"), "vardan": Color("493f35")
}

var person_id: String = ""
var display_name: String = ""
var role: String = ""
var phase: float = 0.0
var hovered: bool = false
var speaking: bool = false
var interactive: bool = true
var name_label: Label
var role_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	pivot_offset = size * 0.5
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color("f7eac0"))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(name_label)
	role_label = Label.new()
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 12)
	role_label.add_theme_color_override("font_color", Color("d2c79e"))
	role_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	role_label.add_theme_constant_override("shadow_offset_x", 2)
	role_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(role_label)
	name_label.text = display_name
	role_label.text = role
	_layout_labels()

func configure(id: String, title: String, public_role: String, can_select: bool = true) -> void:
	person_id = id
	display_name = title
	role = public_role
	interactive = can_select
	if is_node_ready():
		mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
		name_label.text = display_name
		role_label.text = role
		queue_redraw()

func set_speaking(value: bool) -> void:
	speaking = value

func _process(delta: float) -> void:
	phase += delta * (2.2 if speaking else 1.25)
	var breath := sin(phase) * 0.012
	var attention := 1.055 if hovered else 1.0
	scale = Vector2(attention + breath * 0.35, attention + breath)
	rotation = sin(phase * 0.47) * (0.008 if speaking else 0.003)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5
		_layout_labels()

func _layout_labels() -> void:
	if name_label == null:
		return
	name_label.position = Vector2(-20, size.y - 50)
	name_label.size = Vector2(size.x + 40, 25)
	role_label.position = Vector2(-35, size.y - 26)
	role_label.size = Vector2(size.x + 70, 22)

func _draw() -> void:
	var base := COLORS.get(person_id, Color("405449")) as Color
	var outline := Color("d7bb72") if hovered else Color(0.08, 0.11, 0.09, 0.95)
	var center_x := size.x * 0.5
	var foot_y := size.y - 56.0
	var body_top := size.y * 0.30
	var shoulder := size.x * 0.30
	var sway := sin(phase * 0.8) * size.x * (0.018 if speaking else 0.008)
	# Shadow anchors the animated figure to the location.
	_draw_ellipse_polygon(Vector2(center_x, foot_y + 10), Vector2(size.x * 0.31, 12), Color(0, 0, 0, 0.38))
	# Cloak/body, arms and head are separate shapes so later sprites can replace this node directly.
	var body := PackedVector2Array([
		Vector2(center_x - shoulder + sway, body_top + 20), Vector2(center_x + shoulder + sway, body_top + 20),
		Vector2(center_x + size.x * 0.25 + sway, foot_y), Vector2(center_x - size.x * 0.25 + sway, foot_y)
	])
	draw_colored_polygon(body, base)
	var body_outline := body.duplicate()
	body_outline.append(body[0])
	draw_polyline(body_outline, outline, 3.0, true)
	var arm_l := Vector2(center_x - shoulder + sway, body_top + 36)
	var arm_r := Vector2(center_x + shoulder + sway, body_top + 36)
	var gesture := sin(phase * 1.7) * 8.0 if speaking else 0.0
	draw_line(arm_l, Vector2(center_x - size.x * 0.34 + sway, body_top + 112 - gesture), outline, 10.0, true)
	draw_line(arm_r, Vector2(center_x + size.x * 0.34 + sway, body_top + 108 + gesture), outline, 10.0, true)
	var head := Vector2(center_x + sway, body_top - 12 + sin(phase) * 1.5)
	draw_circle(head, size.x * 0.125, Color("c99f7a"))
	draw_arc(head, size.x * 0.125, 0, TAU, 32, outline, 3.0, true)
	var hair := Color("2b241f") if person_id not in ["radomir", "borin"] else Color("b9b0a1")
	draw_arc(head + Vector2(0, -2), size.x * 0.105, PI, TAU, 20, hair, 8.0, true)
	var blink := absf(sin(phase * 0.73)) > 0.985
	var eye_y := head.y + 2
	for direction in [-1.0, 1.0]:
		var eye := head + Vector2(direction * size.x * 0.042, 2)
		if blink:
			draw_line(eye - Vector2(3, 0), eye + Vector2(3, 0), Color("30251f"), 2.0)
		else:
			draw_circle(Vector2(eye.x, eye_y), 2.2, Color("30251f"))

func _draw_ellipse_polygon(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _on_mouse_entered() -> void:
	if interactive:
		hovered = true

func _on_mouse_exited() -> void:
	hovered = false

func _on_gui_input(event: InputEvent) -> void:
	if interactive and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(person_id)
		accept_event()
