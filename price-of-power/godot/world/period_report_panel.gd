extends Control

signal dismiss_requested
signal secretary_requested
signal archive_step_requested(step: int)

var close_button: Button
var secretary_button: Button
var panel: PanelContainer
var date_label: Label
var pager: HBoxContainer
var page_label: Label
var previous_button: Button
var next_button: Button
var scroll: ScrollContainer
var content: VBoxContainer
var preferred_height: float = 250.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.018, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(_on_shade_input)
	add_child(shade)

	panel = PanelContainer.new()
	panel.name = "PeriodReportCard"
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pad.add_child(column)
	var heading := Label.new()
	heading.text = "Итоги периода"
	heading.add_theme_font_size_override("font_size", 25)
	column.add_child(heading)
	date_label = Label.new()
	date_label.add_theme_color_override("font_color", Color("dbbf83"))
	column.add_child(date_label)
	pager = HBoxContainer.new()
	pager.add_theme_constant_override("separation", 8)
	column.add_child(pager)
	previous_button = _action("PreviousPeriod", "← Раньше", func(): archive_step_requested.emit(-1))
	pager.add_child(previous_button)
	page_label = Label.new()
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_label.custom_minimum_size.x = 76
	pager.add_child(page_label)
	next_button = _action("NextPeriod", "Позже →", func(): archive_step_requested.emit(1))
	pager.add_child(next_button)
	column.add_child(HSeparator.new())

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	column.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	secretary_button = _action("PeriodReportSecretary", "К делам секретаря", func(): secretary_requested.emit())
	actions.add_child(secretary_button)
	close_button = _action("PeriodReportClose", "Продолжить", func(): dismiss_requested.emit())
	actions.add_child(close_button)
	resized.connect(_layout_panel)
	_layout_panel()

func show_report(report: Dictionary, page: int, total: int, campaign_finished: bool) -> void:
	if report.is_empty():
		return
	date_label.text = str(report.get("date", ""))
	pager.visible = total > 1
	page_label.text = "%d / %d" % [page, total]
	previous_button.disabled = page <= 1
	next_button.disabled = page >= total
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var changes: Array = report.get("changes", [])
	var notes: Array = report.get("notes", [])
	if not notes.is_empty():
		_add_heading("Новости")
		for value in notes:
			var note := Label.new()
			note.text = "•  " + str(value)
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(note)
	_add_changes(changes)
	var pager_height := 52.0 if pager.visible else 0.0
	preferred_height = clampf(175.0 + pager_height + changes.size() * 27.0 + notes.size() * 55.0, 230.0, 510.0)
	_layout_panel()
	secretary_button.visible = page == total and (campaign_finished or bool(report.get("has_secretary_items", false)))
	secretary_button.text = "Читать эпилог" if campaign_finished else "К делам секретаря"
	visible = true
	scroll.set_deferred("scroll_vertical", 0)
	_update_focus()
	close_button.grab_focus()

func _add_changes(changes: Array) -> void:
	if changes.is_empty():
		var empty := Label.new()
		empty.text = "При переходе показатели не изменились."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(empty)
		return
	_add_heading("Изменения при переходе")
	var rows := GridContainer.new()
	rows.columns = 2
	rows.add_theme_constant_override("h_separation", 14)
	rows.add_theme_constant_override("v_separation", 5)
	content.add_child(rows)
	for change: Dictionary in changes:
		var label := Label.new()
		label.text = str(change["label"])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rows.add_child(label)
		var before := int(change["before"])
		var after := int(change["after"])
		var value := Label.new()
		value.text = "%d → %d  (%+d)" % [before, after, after - before]
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rows.add_child(value)

func _add_heading(caption: String) -> void:
	var heading := Label.new()
	heading.text = caption
	heading.add_theme_font_size_override("font_size", 18)
	content.add_child(heading)

func _action(node_name: String, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = caption
	button.custom_minimum_size.y = 42
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	return button

func _update_focus() -> void:
	var focus_order: Array[Button] = []
	for button: Button in [previous_button, next_button, secretary_button, close_button]:
		if button.is_visible_in_tree() and not button.disabled:
			focus_order.append(button)
	for index in range(focus_order.size()):
		var button := focus_order[index]
		var previous := button.get_path_to(focus_order[posmod(index - 1, focus_order.size())])
		var next := button.get_path_to(focus_order[(index + 1) % focus_order.size()])
		button.focus_previous = previous
		button.focus_neighbor_left = previous
		button.focus_neighbor_top = previous
		button.focus_next = next
		button.focus_neighbor_right = next
		button.focus_neighbor_bottom = next

func _layout_panel() -> void:
	var target := Vector2(minf(580.0, maxf(0.0, size.x - 32.0)), minf(preferred_height, maxf(0.0, size.y - 32.0)))
	panel.size = target
	panel.position = (size - target) * 0.5

func _on_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		dismiss_requested.emit()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("12251e")
	style.border_color = Color("a89058")
	style.set_border_width_all(1)
	style.set_corner_radius_all(13)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	style.shadow_size = 14
	return style
