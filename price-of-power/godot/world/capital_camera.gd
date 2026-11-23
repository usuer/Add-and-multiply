class_name CapitalCamera
extends Node3D

@export var move_speed: float = 14.0
@export var rotate_speed: float = 0.9
@export var zoom_speed: float = 3.0
@export var min_zoom: float = 16.0
@export var max_zoom: float = 52.0

var _zoom: float = 31.0
var _camera: Camera3D

func _ready() -> void:
	_camera = Camera3D.new()
	_camera.current = true
	_camera.position = Vector3(0.0, 20.0, _zoom)
	_camera.rotation_degrees.x = -36.0
	add_child(_camera)

func _process(delta: float) -> void:
	var direction := Input.get_vector("camera_left", "camera_right", "camera_forward", "camera_back")
	var forward := -global_transform.basis.z
	forward.y = 0.0
	var right := global_transform.basis.x
	right.y = 0.0
	position += (right.normalized() * direction.x + forward.normalized() * direction.y) * move_speed * delta
	var rotation_axis := Input.get_axis("camera_rotate_left", "camera_rotate_right")
	rotate_y(rotation_axis * rotate_speed * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_zoom = clampf(_zoom + (-zoom_speed if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP else zoom_speed), min_zoom, max_zoom)
			_camera.position.z = _zoom

