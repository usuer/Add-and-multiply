class_name CityBuilding
extends StaticBody3D

signal selected(building: CityBuilding)

@export var building_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var building_status: String = "Работает"

var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D

func configure(id: StringName, title: String, details: String, size: Vector3, color: Color, create_visual: bool = true) -> void:
	building_id = id
	display_name = title
	description = details
	name = String(id)
	if not create_visual:
		return

	_mesh_instance = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.roughness = 0.9
	mesh.material = _material
	_mesh_instance.mesh = mesh
	_mesh_instance.position.y = size.y * 0.5
	add_child(_mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y * 0.5
	add_child(collision)
	input_ray_pickable = true
	input_event.connect(_on_input_event)

func set_highlighted(enabled: bool) -> void:
	if _material == null:
		return
	_material.emission_enabled = enabled
	_material.emission = Color("d9bd72") if enabled else Color.BLACK
	_material.emission_energy_multiplier = 0.55 if enabled else 0.0

func focus_point() -> Vector3:
	return global_position + Vector3(0.0, 1.0, 0.0)

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selected.emit(self)

