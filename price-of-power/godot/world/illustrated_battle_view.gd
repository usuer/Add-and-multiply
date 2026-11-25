class_name IllustratedBattleView
extends Control

signal friendly_unit_selected(unit_id: String)

const BATTLEFIELD: Texture2D = preload("res://assets/art/border_battlefield.png")
const FORMATIONS: Texture2D = preload("res://assets/art/battle_formations.png")
const FRIENDLY_CELLS: Dictionary = {"retinue": Vector2i(0, 0), "archers": Vector2i(1, 0), "cavalry": Vector2i(2, 0)}
const ENEMY_CELLS: Dictionary = {"spears": Vector2i(0, 1), "raiders": Vector2i(1, 1), "bows": Vector2i(2, 1)}
const FIGURE_REGIONS: Dictionary = {
	"retinue": Rect2(80, 9, 95, 180),
	"archers": Rect2(594, 11, 100, 174),
	"cavalry": Rect2(1107, 5, 107, 205),
	"spears": Rect2(77, 537, 92, 156),
	"raiders": Rect2(578, 521, 122, 157),
	"bows": Rect2(1104, 533, 110, 159),
}
# At most nine sprites represent a unit. The caption shows its actual headcount.
const MAX_FIGURES: int = 9
const CAPTION_HEIGHT: float = 56.0

var _army: ArmyState
var _friendly_buttons: Dictionary = {}
var _friendly_labels: Dictionary = {}
var _enemy_sprites: Dictionary = {}
var _enemy_labels: Dictionary = {}
var _figure_layers: Dictionary = {}
var _motion_tweens: Dictionary = {}
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
		button.ignore_texture_size = true
		button.tooltip_text = "Выбрать: %s" % ArmyState.UNIT_NAMES[unit_id]
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_select_unit.bind(unit_id))
		button.focus_entered.connect(_update_friendly_style.bind(unit_id))
		button.focus_exited.connect(_update_friendly_style.bind(unit_id))
		add_child(button)
		_friendly_buttons[unit_id] = button
		_make_figures(button, unit_id)
		var label := _make_label()
		button.add_child(label)
		_friendly_labels[unit_id] = label
	for unit_id: String in ENEMY_CELLS:
		var sprite := Control.new()
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_enemy_sprites[unit_id] = sprite
		_make_figures(sprite, unit_id)
		var label := _make_label()
		sprite.add_child(label)
		_enemy_labels[unit_id] = label

func _make_figures(unit: Control, unit_id: String) -> void:
	var texture := AtlasTexture.new()
	texture.atlas = FORMATIONS
	texture.region = FIGURE_REGIONS[unit_id]
	texture.filter_clip = true
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit.add_child(layer)
	_figure_layers[unit_id] = layer
	for index in range(MAX_FIGURES):
		var figure := TextureRect.new()
		figure.texture = texture
		figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(figure)

func _make_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 3
	label.add_theme_font_size_override("font_size", 14)
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
	var figures := _figure_layers.get(unit_id) as Control
	if figures == null or not figures.is_visible_in_tree():
		return
	var previous := _motion_tweens.get(unit_id) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	var offset := Vector2(0, -size.y * 0.13)
	if order == "flank":
		var group := figures.get_parent() as Control
		var right_clearance := size.x - group.position.x - group.size.x - 4.0
		offset = Vector2(clampf(right_clearance, 0.0, size.x * 0.05), -size.y * 0.12)
	if order == "charge":
		offset.y = -size.y * 0.18
	figures.position = Vector2.ZERO
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_motion_tweens[unit_id] = tween
	tween.tween_property(figures, "position", offset, 0.34)
	tween.tween_property(figures, "position", Vector2.ZERO, 0.34)

func _animate_arrows(target_id: String) -> void:
	var source: TextureButton = _friendly_buttons.get("archers")
	var target: Control = _enemy_sprites.get(target_id)
	if source == null or target == null or not source.visible or not target.visible: return
	var start := source.position + Vector2(source.size.x, source.size.y - CAPTION_HEIGHT) * 0.5
	var finish := target.position + Vector2(target.size.x, target.size.y - CAPTION_HEIGHT) * 0.5
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
	if size.x < 1.0 or size.y < 1.0:
		return
	var column := 0
	for unit_id: String in FRIENDLY_CELLS:
		var unit: Dictionary = _army.friendly.get(unit_id, {})
		var button: TextureButton = _friendly_buttons[unit_id]
		var label: Label = _friendly_labels[unit_id]
		var count := int(unit.get("count", 0))
		var depth := int(unit.get("depth", 2))
		_layout_group(button, label, unit_id, count, depth, column, true)
		var order := str(_army.pending_orders.get(unit_id, ""))
		var detail := "Бойцов: %d" % count
		if _army.status == ArmyState.BattleStatus.DEPLOYMENT:
			detail += " · рядов: %d" % depth
		elif not order.is_empty():
			detail += "\n✓ %s" % str(ArmyState.ORDERS[unit_id].get(order, "Приказ принят"))
		elif _army.status == ArmyState.BattleStatus.FIGHTING:
			detail += " · ждёт приказа"
		label.text = "%s\n%s" % [ArmyState.UNIT_NAMES[unit_id], detail]
		_update_friendly_style(unit_id)
		column += 1
	column = 0
	for unit_id: String in ENEMY_CELLS:
		var unit: Dictionary = _army.enemy.get(unit_id, {})
		var sprite: Control = _enemy_sprites[unit_id]
		var label: Label = _enemy_labels[unit_id]
		var count := int(unit.get("count", 0))
		_layout_group(sprite, label, unit_id, count, 3, column, false)
		label.text = "%s\nБойцов: %d" % [unit.get("name", unit_id), count]
		_set_caption_style(label, Color("662e26"), Color("cc8570"))
		column += 1

func _layout_group(group: Control, caption: Label, unit_id: String, count: int, depth: int, column: int, friendly: bool) -> void:
	group.visible = count > 0
	if count <= 0:
		return
	var column_width := (size.x - 24.0) / 3.0
	var sprites_height := clampf(size.y * 0.25, 68.0, 145.0)
	var lane_width := column_width - 12.0
	group.size = Vector2(lane_width, sprites_height + CAPTION_HEIGHT)
	var row_center := size.y * (0.72 if friendly else 0.23)
	group.position = Vector2(18.0 + column * column_width, clampf(row_center - sprites_height * 0.5, 4.0, size.y - group.size.y - 6.0))
	caption.position = Vector2(0.0, sprites_height)
	caption.size = Vector2(lane_width, CAPTION_HEIGHT)
	_layout_figures(unit_id, mini(count, MAX_FIGURES), depth, Vector2(lane_width, sprites_height))

func _layout_figures(unit_id: String, count: int, depth: int, available: Vector2) -> void:
	var figures: Control = _figure_layers[unit_id]
	figures.size = available
	var rows := clampi(depth, 1, count)
	var columns := ceili(float(count) / rows)
	var texture_size: Vector2 = FIGURE_REGIONS[unit_id].size
	var figure_width := maxf(1.0, minf(available.x / columns - 2.0, available.y / rows * texture_size.x / texture_size.y))
	var figure_size := Vector2(figure_width, figure_width * texture_size.y / texture_size.x)
	var spacing := figure_size + Vector2(2, 0)
	var index := 0
	for row in range(rows):
		var rank_count := floori(float(count) / rows) + int(row < count % rows)
		for column in range(rank_count):
			var figure := figures.get_child(index) as TextureRect
			figure.visible = true
			figure.size = figure_size
			figure.position = (available - Vector2(spacing.x * rank_count - 2.0, figure_size.y * rows)) * 0.5 + Vector2(column, row) * spacing
			index += 1
	for hidden in range(index, figures.get_child_count()):
		(figures.get_child(hidden) as TextureRect).visible = false

func _update_friendly_style(unit_id: String) -> void:
	if not _friendly_labels.has(unit_id):
		return
	var button: TextureButton = _friendly_buttons[unit_id]
	var caption: Label = _friendly_labels[unit_id]
	if unit_id == _selected_unit or button.has_focus():
		_set_caption_style(caption, Color("38513b"), Color("f3cb73"))
	elif _army != null and _army.pending_orders.has(unit_id):
		_set_caption_style(caption, Color("2d4735"), Color("8faf7c"))
	else:
		_set_caption_style(caption, Color("1d352c"), Color("789985"))

func _set_caption_style(caption: Label, background: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 3
	style.content_margin_right = 3
	caption.add_theme_stylebox_override("normal", style)

func _select_unit(unit_id: String) -> void:
	_selected_unit = unit_id
	_layout_units()
	friendly_unit_selected.emit(unit_id)
