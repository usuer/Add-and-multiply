class_name IllustratedBattleView
extends Control

signal friendly_unit_selected(unit_id: String)

const BATTLEFIELD: Texture2D = preload("res://assets/art/border_battlefield.png")
const FORMATIONS: Texture2D = preload("res://assets/art/battle_formations.png")
const FRIENDLY_CELLS: Dictionary = {"retinue": Vector2i(0, 0), "archers": Vector2i(1, 0), "cavalry": Vector2i(2, 0)}
const ENEMY_CELLS: Dictionary = {"spears": Vector2i(0, 1), "raiders": Vector2i(1, 1), "bows": Vector2i(2, 1)}
const FRIENDLY_X: Dictionary = {"retinue": 0.28, "archers": 0.52, "cavalry": 0.76}
const ENEMY_X: Dictionary = {"spears": 0.28, "raiders": 0.52, "bows": 0.76}

var _army: ArmyState
var _friendly_buttons: Dictionary = {}
var _friendly_labels: Dictionary = {}
var _enemy_sprites: Dictionary = {}
var _enemy_labels: Dictionary = {}
var _selected_unit: String = "retinue"

func _ready() -> void:
	clip_contents = true
	var background := TextureRect.new()
	background.texture = BATTLEFIELD
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	for unit_id: String in FRIENDLY_CELLS:
		var button := TextureButton.new()
		button.texture_normal = _atlas(FRIENDLY_CELLS[unit_id])
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.tooltip_text = "Выбрать: %s" % ArmyState.UNIT_NAMES[unit_id]
		button.pressed.connect(_select_unit.bind(unit_id))
		add_child(button)
		_friendly_buttons[unit_id] = button
		var label := _make_label()
		add_child(label)
		_friendly_labels[unit_id] = label
	for unit_id: String in ENEMY_CELLS:
		var sprite := TextureRect.new()
		sprite.texture = _atlas(ENEMY_CELLS[unit_id])
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_enemy_sprites[unit_id] = sprite
		var label := _make_label()
		add_child(label)
		_enemy_labels[unit_id] = label

func _atlas(cell: Vector2i) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = FORMATIONS
	texture.region = Rect2(cell.x * 512, cell.y * 512, 512, 512)
	return texture

func _make_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("fff1c2"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func refresh(army: ArmyState, selected_unit: String = "") -> void:
	_army = army
	if not selected_unit.is_empty(): _selected_unit = selected_unit
	_layout_units()

func play_turn(turn_record: Dictionary) -> void:
	if _army == null: return
	var orders: Dictionary = turn_record.get("orders", {})
	for unit_id: String in orders:
		var order := str(orders[unit_id])
		if order in ["advance", "flank", "charge"]:
			_animate_movement(unit_id, order)
		elif unit_id == "archers" and order in ["volley", "suppress"]:
			_animate_arrows("bows" if order == "suppress" else "spears")
	var friendly_losses: Dictionary = turn_record.get("friendly_losses", {})
	for unit_id: String in friendly_losses:
		if int(friendly_losses[unit_id]) > 0: _flash_casualties(_friendly_buttons.get(unit_id))
	var enemy_losses: Dictionary = turn_record.get("enemy_losses", {})
	for unit_id: String in enemy_losses:
		if int(enemy_losses[unit_id]) > 0: _flash_casualties(_enemy_sprites.get(unit_id))

func _animate_movement(unit_id: String, order: String) -> void:
	var button: TextureButton = _friendly_buttons.get(unit_id)
	if button == null or not button.visible: return
	var origin := button.position
	var offset := Vector2(0, -80)
	if order == "flank": offset = Vector2(90, -70)
	if order == "charge": offset = Vector2(0, -125)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "position", origin + offset, 0.34)
	tween.tween_property(button, "position", origin, 0.34)

func _animate_arrows(target_id: String) -> void:
	var source: TextureButton = _friendly_buttons.get("archers")
	var target: TextureRect = _enemy_sprites.get(target_id)
	if source == null or target == null or not source.visible or not target.visible: return
	var start := source.position + source.size * 0.5
	var finish := target.position + target.size * 0.5
	for index in range(7):
		var arrow := ColorRect.new()
		arrow.color = Color("d8c38e")
		arrow.size = Vector2(3, 24)
		arrow.pivot_offset = arrow.size * 0.5
		var spread := Vector2((index - 3) * 9, abs(index - 3) * 3)
		arrow.position = start + spread
		arrow.rotation = (finish - start).angle() + PI * 0.5
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(arrow)
		var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_interval(index * 0.035)
		tween.tween_property(arrow, "position", finish + spread, 0.48)
		tween.parallel().tween_property(arrow, "modulate:a", 0.15, 0.48)
		tween.tween_callback(arrow.queue_free)

func _flash_casualties(control: Control) -> void:
	if control == null or not control.visible: return
	var original := control.modulate
	var tween := create_tween()
	tween.tween_property(control, "modulate", Color(1.0, 0.3, 0.24, 0.72), 0.12)
	tween.tween_property(control, "modulate", original, 0.34)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _army != null:
		_layout_units()

func _layout_units() -> void:
	var formation_size := clampf(size.y * 0.24, 120.0, 210.0)
	for unit_id: String in _friendly_buttons:
		var unit: Dictionary = _army.friendly.get(unit_id, {})
		var button: TextureButton = _friendly_buttons[unit_id]
		var label: Label = _friendly_labels[unit_id]
		var living := int(unit.get("count", 0)) > 0
		button.visible = living
		label.visible = living
		if not living: continue
		var depth := int(unit.get("depth", 2))
		var center := Vector2(size.x * float(FRIENDLY_X[unit_id]), size.y * (0.59 + depth * 0.085))
		button.position = center - Vector2.ONE * formation_size * 0.5
		button.size = Vector2.ONE * formation_size
		button.modulate = Color.WHITE if unit_id == _selected_unit else Color(0.78, 0.78, 0.78, 0.92)
		label.position = Vector2(center.x - 110, center.y + formation_size * 0.34)
		label.size = Vector2(220, 34)
		label.text = "%s · %d" % [ArmyState.UNIT_NAMES[unit_id], unit["count"]]
	for unit_id: String in _enemy_sprites:
		var unit: Dictionary = _army.enemy.get(unit_id, {})
		var sprite: TextureRect = _enemy_sprites[unit_id]
		var label: Label = _enemy_labels[unit_id]
		var living := int(unit.get("count", 0)) > 0
		sprite.visible = living
		label.visible = living
		if not living: continue
		var center := Vector2(size.x * float(ENEMY_X[unit_id]), size.y * 0.17)
		sprite.position = center - Vector2.ONE * formation_size * 0.5
		sprite.size = Vector2.ONE * formation_size
		label.position = Vector2(center.x - 110, center.y + formation_size * 0.34)
		label.size = Vector2(220, 34)
		label.text = "%s · %d" % [unit.get("name", unit_id), unit["count"]]

func _select_unit(unit_id: String) -> void:
	_selected_unit = unit_id
	_layout_units()
	friendly_unit_selected.emit(unit_id)
