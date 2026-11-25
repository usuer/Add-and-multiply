class_name PrologueScene
extends Control

signal finished
signal contact_met(person_id: String)
signal burial_finished

const SCENES: Array[Dictionary] = [
	{
		"location": "Арденский замок · перед рассветом",
		"title": "Последняя просьба",
		"body": "Отец просит открыть книгу зерновых выдач. На странице лежит письмо о ремонте переправы и крошка воска с оттиском малого княжеского знака.\n\n«По книге обоз перешёл мост во вторник. А настил сняли ещё в понедельник. Спроси Ладу, кто там был».",
		"next": "Остаться у кровати"
	},
	{
		"location": "Арденский замок · рассвет",
		"title": "Старый князь умер",
		"body": "Отец пытается назвать имя и замолкает. Лекарь касается его руки, потом закрывает ему глаза. Адела ждёт, пока вы сами отпустите его ладонь.\n\nЗа дверью уже стоит Марек. Весть скоро услышит весь город.",
		"next": "Проводить отца в храм"
	},
	{
		"location": "Дорога к храму · раннее утро",
		"title": "Первый колокол",
		"body": "Дружинники несут отца через замковый двор. Вы идёте за ними. На пороге храма священник принимает носилки, чтобы семья могла проститься в тишине.\n\nЭто частное прощание. Как пройдут публичные похороны, предстоит решить вам.",
		"next": "Выйти к тем, кто ждёт"
	},
	{
		"location": "У дверей храма · после прощания",
		"title": "Люди отца",
		"body": "У дверей вас ждут Адела и двое людей, служивших отцу. С ними можно поговорить сейчас или встретиться позже, когда вернётесь в город.",
		"next": "Вернуться в замок"
	},
	{
		"location": "Арден · полдень",
		"title": "Теперь решаете вы",
		"body": "Марек передаёт вам большую печать Ардена. До полудня он ждёт двух распоряжений: как проводить отца и что ответить старостам из Долинной области.\n\nОба дела лежат в канцелярии. На карте можно зайти к людям в замок, на рынок и в другие места.",
		"next": "Войти в город"
	}
]

const CONTACTS: Dictionary = {
	"spouse": {
		"name": "Адела", "role": "Ваша жена",
		"speech": "«Я скажу детям сама. Всеволод всё ещё ждёт, что дед позовёт его после обеда. Приходи, когда сможешь. Им надо тебя увидеть»."
	},
	"secretary": {
		"name": "Марек", "role": "Секретарь старого князя",
		"speech": "«Примите мои соболезнования. Я Марек, вёл переписку вашего отца. Старосты из Долинной области уже в замке. Я попрошу их подождать до полудня»."
	},
	"radomir": {
		"name": "Радомир", "role": "Воевода",
		"speech": "«Радомир. Мы с вашим отцом лет двадцать на одной дороге. Мне его будет не хватать. Стража у ворот на месте. Когда понадоблюсь, ищите меня в казармах»."
	}
}

const BURIALS: Dictionary = {
	"modest": {
		"location": "Храм Ардена · день похорон",
		"title": "Прощание в кругу семьи",
		"body": "У алтаря стоят родные и несколько старых товарищей отца. Когда заканчивается молитва, Всеволод кладёт на крышку деревянного коня, которого дед вырезал для него. В тишине слышен первый удар лопаты.",
		"next": "Вернуться в канцелярию"
	},
	"solemn": {
		"location": "Храм Ардена · день похорон",
		"title": "Город провожает князя",
		"body": "Улицы вдоль процессии опустели. Люди стоят у дверей домов, пока гроб несут к храму. Вы встречаете вассалов у входа. Один из них снимает перчатку, прежде чем пожать руку: когда-то отец сделал для него то же самое.",
		"next": "Вернуться в канцелярию"
	},
	"grand": {
		"location": "Храм Ардена · день похорон",
		"title": "Похороны при всех землях",
		"body": "Представители областей оставляют знамёна у ступеней. Перед последней молитвой один староста выходит из строя и кладёт горсть земли на крышку. Остальные молча следуют за ним. После обряда вам придётся услышать каждого.",
		"next": "Вернуться в канцелярию"
	}
}

const TEXT_COLOR := Color("f2e8d6")
const MUTED := Color("b8c2b4")
const GOLD := Color("d9bc7d")

var beat_index: int = 0
var history: Dictionary = {}
var contact_buttons: Dictionary = {}
var stage: CinematicStage
var panel: PanelContainer
var title_label: Label
var location_label: Label
var body_label: Label
var contact_list: VBoxContainer
var speaker: Label
var speech: Label
var scroll: ScrollContainer
var back_button: Button
var next_button: Button
var skip_button: Button
var running := false
var selected_contact: String = ""
var burial_plan: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	hide()
	var backing := ColorRect.new()
	backing.color = Color("111a18")
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backing)
	stage = CinematicStage.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.clip_contents = true
	add_child(stage)
	_create_panel()
	resized.connect(_layout_scene)
	_layout_scene()

func restart() -> void:
	beat_index = 0
	history.clear()
	selected_contact = ""
	burial_plan = ""
	running = true
	show()
	_update_beat()

func show_burial(plan_id: String) -> void:
	if running or not BURIALS.has(plan_id):
		return
	burial_plan = plan_id
	running = true
	show()
	_update_beat()

func advance() -> void:
	if not running:
		return
	if not burial_plan.is_empty() or beat_index == SCENES.size() - 1:
		_complete()
		return
	beat_index += 1
	_update_beat()

func back() -> void:
	if not running or not burial_plan.is_empty() or beat_index < 1:
		return
	beat_index -= 1
	_update_beat()

func skip() -> void:
	if running:
		_complete()

func _complete() -> void:
	running = false
	hide()
	if burial_plan.is_empty():
		finished.emit()
	else:
		burial_plan = ""
		burial_finished.emit()

func _create_panel() -> void:
	panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("1a2a25")
	box.border_color = Color("66543a")
	box.set_border_width_all(1)
	box.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", box)
	add_child(panel)
	var padding := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(padding)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	padding.add_child(column)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	column.add_child(scroll)
	var reading := VBoxContainer.new()
	reading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading.add_theme_constant_override("separation", 14)
	scroll.add_child(reading)
	location_label = _label(15, GOLD)
	reading.add_child(location_label)
	title_label = _label(31, TEXT_COLOR)
	reading.add_child(title_label)
	body_label = _label(19, TEXT_COLOR)
	reading.add_child(body_label)
	contact_list = VBoxContainer.new()
	contact_list.add_theme_constant_override("separation", 7)
	reading.add_child(contact_list)
	for person_id: String in CONTACTS:
		var contact: Dictionary = CONTACTS[person_id]
		var button := _button(str(contact["name"]))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_meet.bind(person_id))
		contact_list.add_child(button)
		contact_buttons[person_id] = button
	speaker = _label(16, GOLD)
	reading.add_child(speaker)
	speech = _label(18, TEXT_COLOR)
	reading.add_child(speech)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 8)
	column.add_child(navigation)
	back_button = _button("Назад")
	back_button.pressed.connect(back)
	navigation.add_child(back_button)
	next_button = _button("")
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.pressed.connect(advance)
	navigation.add_child(next_button)
	skip_button = _button("Пропустить вступление")
	skip_button.custom_minimum_size.y = 32
	skip_button.flat = true
	skip_button.add_theme_color_override("font_color", MUTED)
	skip_button.pressed.connect(skip)
	column.add_child(skip_button)

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 44
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var button_styles := {
		"normal": Color("33443b"), "hover": Color("40564a"),
		"pressed": Color("243a30"), "disabled": Color("25352e")
	}
	for state: String in button_styles:
		var box := StyleBoxFlat.new()
		box.bg_color = button_styles[state]
		box.border_color = Color("786346")
		box.set_border_width_all(1)
		box.set_corner_radius_all(6)
		box.content_margin_left = 10
		box.content_margin_right = 10
		button.add_theme_stylebox_override(state, box)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	return button

func _update_beat() -> void:
	var is_burial := not burial_plan.is_empty()
	var data: Dictionary = BURIALS[burial_plan] if is_burial else SCENES[beat_index]
	location_label.text = str(data["location"])
	title_label.text = str(data["title"])
	body_label.text = str(data["body"])
	next_button.text = str(data["next"])
	back_button.visible = not is_burial
	back_button.disabled = beat_index == 0 or is_burial
	skip_button.visible = not is_burial
	contact_list.visible = beat_index == 3 and not is_burial
	_update_contact_display()
	stage.begin(5 if is_burial else beat_index, selected_contact, burial_plan)
	scroll.set_deferred("scroll_vertical", 0)
	_setup_focus()
	if contact_list.visible:
		(contact_buttons["spouse"] as Button).grab_focus()
	else:
		next_button.grab_focus()

func _meet(person_id: String) -> void:
	if not running or not burial_plan.is_empty() or beat_index != 3:
		return
	selected_contact = person_id
	if not history.has(person_id):
		history[person_id] = true
		contact_met.emit(person_id)
	_update_contact_display()
	stage.selected_contact = person_id
	# Keep the keyboard focus on a contact and make their reply visible below.
	scroll.call_deferred("ensure_control_visible", speech)

func _update_contact_display() -> void:
	var active := contact_list.visible and CONTACTS.has(selected_contact)
	speaker.visible = active
	speech.visible = active
	if active:
		var contact := CONTACTS[selected_contact] as Dictionary
		speaker.text = "%s · %s" % [contact["name"], contact["role"]]
		speech.text = str(contact["speech"])
	for id: String in contact_buttons:
		var button := contact_buttons[id] as Button
		button.text = str(CONTACTS[id]["name"])
		if history.has(id):
			button.text += "  ✓"

func _setup_focus() -> void:
	var controls: Array[Control] = []
	if contact_list.visible:
		for person_id: String in contact_buttons:
			controls.append(contact_buttons[person_id])
	if not back_button.disabled:
		controls.append(back_button)
	controls.append(next_button)
	if skip_button.visible:
		controls.append(skip_button)
	for index in range(controls.size()):
		var button := controls[index]
		var last := button.get_path_to(controls[posmod(index - 1, controls.size())])
		var next := button.get_path_to(controls[(index + 1) % controls.size()])
		button.focus_previous = last
		button.focus_next = next
		button.focus_neighbor_left = last
		button.focus_neighbor_right = next
		button.focus_neighbor_top = last
		button.focus_neighbor_bottom = next

func _layout_scene() -> void:
	var inset := 18.0
	if size.x >= 880:
		var panel_width := clampf(size.x * 0.35, 350.0, 500.0)
		stage.position = Vector2(inset, inset)
		stage.size = Vector2(maxf(0, size.x - panel_width - inset * 3), maxf(0, size.y - inset * 2))
		panel.position = Vector2(size.x - panel_width - inset, inset)
		panel.size = Vector2(panel_width, stage.size.y)
	else:
		var art_height := maxf(0, size.y * 0.40 - 2.0 * inset)
		stage.position = Vector2(inset, inset)
		stage.size = Vector2(maxf(0, size.x - 2.0 * inset), art_height)
		panel.position = Vector2(inset, art_height + 2.0 * inset)
		panel.size = Vector2(stage.size.x, maxf(0, size.y - art_height - 3.0 * inset))


class CinematicStage extends Control:
	const CHAMBER := preload("res://assets/art/fathers_last_night.png")
	const CAPITAL := preload("res://assets/art/arden_capital.png")
	const DESIGN := Vector2(900, 680)
	const CLOTH := Color("482c31")
	const TRIM := Color("b19763")
	var beat: int = 0
	var elapsed: float = 0.0
	var selected_contact: String = ""
	var burial: String = ""

	func begin(new_beat: int, contact_id: String, plan_id: String) -> void:
		beat = new_beat
		elapsed = 0.0
		selected_contact = contact_id
		burial = plan_id
		queue_redraw()

	func _process(delta: float) -> void:
		if is_visible_in_tree():
			elapsed += delta
			queue_redraw()

	func _draw() -> void:
		if size.x < 1 or size.y < 1:
			return
		var framing := minf(size.x / DESIGN.x, size.y / DESIGN.y)
		var art_inset := (size - DESIGN * framing) * 0.5
		var view := Rect2(Vector2.ZERO, size)
		draw_rect(view, Color("0c1516"))
		match beat:
			0:
				_cover(CHAMBER, 1.04 + minf(elapsed * 0.012, 0.15), Vector2(0.33, 0.50), Color.WHITE)
			1:
				var falloff := 0.47 * smoothstep(0.10, 2.6, elapsed)
				_cover(CHAMBER, 1.12 + minf(elapsed * 0.006, 0.07), Vector2(0.24, 0.56), Color.WHITE)
				draw_rect(view, Color(0.016, 0.022, 0.033, 0.20 + falloff))
			2, 3, 5:
				_draw_hall(framing, art_inset)
			4:
				_cover(CAPITAL, 1.14 - minf(elapsed * 0.023, 0.14), Vector2(0.45, 0.48), Color.WHITE)
		var fade := 0.70 * (1.0 - smoothstep(0.0, 0.57, elapsed))
		if fade > 0.0:
			draw_rect(view, Color(0.02, 0.03, 0.03, fade))
		draw_rect(view.grow(-0.5), Color("756b50"), false, 1.0)

	func _cover(texture: Texture2D, zoom: float, focus: Vector2, tint: Color) -> void:
		var source := texture.get_size()
		var factor := maxf(size.x / source.x, size.y / source.y) * zoom
		var rendered := source * factor
		draw_texture_rect(texture, Rect2((size - rendered) * focus, rendered), false, tint)

	func _draw_hall(framing: float, art_inset: Vector2) -> void:
		draw_set_transform(art_inset, 0.0, Vector2.ONE * framing)
		draw_rect(Rect2(Vector2.ZERO, DESIGN), Color("172321"))
		_polygon([Vector2(50, 680), Vector2(290, 363), Vector2(610, 363), Vector2(850, 680)], Color("2a3834"))
		_polygon([Vector2(260, 680), Vector2(382, 366), Vector2(520, 366), Vector2(651, 680)], Color("49332e"))
		for layer in range(8):
			var y := 372.0 + pow(float(layer) / 7.0, 1.8) * 307.0
			draw_line(Vector2(0, y), Vector2(900, y), Color(0.025, 0.04, 0.04, 0.64), 2.0, true)
		_draw_apse()
		for index in range(3):
			var x := 42.0 + index * 95.0
			var base := 650.0 - index * 92.0
			_draw_column(x, base)
			_draw_column(900.0 - x, base)
		_draw_torch(Vector2(330, 292), 0.0)
		_draw_torch(Vector2(570, 292), 1.8)
		_draw_torch(Vector2(133, 462), 0.9)
		_draw_torch(Vector2(767, 462), 2.4)
		if beat == 2:
			_draw_procession()
		elif beat == 5:
			_draw_burial()
		else:
			_draw_mourners()
		draw_set_transform(Vector2.ZERO)

	func _draw_apse() -> void:
		# The outer arch is a single masonry silhouette. A second opening lets the dawn through.
		draw_rect(Rect2(311, 217, 278, 149), Color("394842"))
		draw_circle(Vector2(450, 216), 139, Color("394842"), true, -1.0, true)
		draw_rect(Rect2(331, 217, 238, 149), Color("121e1e"))
		draw_circle(Vector2(450, 216), 119, Color("121e1e"), true, -1.0, true)
		draw_rect(Rect2(386, 230, 128, 143), Color("ab9b75"))
		draw_circle(Vector2(450, 230), 64, Color("ab9b75"), true, -1.0, true)
		draw_rect(Rect2(391, 232, 118, 137), Color("6d8079"))
		draw_circle(Vector2(450, 232), 59, Color("6d8079"), true, -1.0, true)
		_polygon([Vector2(407, 370), Vector2(492, 370), Vector2(564, 680), Vector2(297, 680)], Color(0.84, 0.72, 0.51, 0.10))
		draw_line(Vector2(450, 173), Vector2(450, 370), Color("282f2c"), 5, true)
		draw_line(Vector2(391, 238), Vector2(509, 238), Color("282f2c"), 5, true)

	func _draw_column(x: float, base: float) -> void:
		var width := 34.0 + (base - 466.0) * 0.10
		draw_rect(Rect2(x - width * 0.5, 0, width, base), Color("202b29"))
		draw_rect(Rect2(x - width * 0.5, 0, width * 0.30, base), Color("33403a"))
		draw_rect(Rect2(x - width * 0.62, base - 20, width * 1.24, 15), Color("4a5144"))
		draw_rect(Rect2(x - width * 0.75, base - 5, width * 1.50, 12), Color("151d1c"))

	func _draw_torch(point: Vector2, phase: float) -> void:
		var shimmer := 0.8 + 0.16 * sin(elapsed * 8.0 + phase) + 0.06 * sin(elapsed * 19.0 + phase)
		for radius in [56.0, 42.0, 29.0, 17.0]:
			draw_circle(point, radius * shimmer, Color(0.76, 0.42, 0.19, 0.037), true, -1.0, true)
		draw_line(point + Vector2(0, 18), point + Vector2(0, 2), Color("84694b"), 3.0, true)
		var tilt := sin(elapsed * 12.0 + phase) * 2.0
		_polygon([point + Vector2(-4, 1), point + Vector2(tilt, -15.0 * shimmer), point + Vector2(5, 2), point + Vector2(0, 5)], Color("edaa54"))
		draw_circle(point, 2.3, Color("ffe1a2"), true, -1.0, true)

	func _draw_procession() -> void:
		var passage := smoothstep(0.0, 5.2, elapsed)
		var stride := sin(elapsed * 9.2) * (1.0 - smoothstep(4.2, 5.2, elapsed))
		var center := Vector2(lerpf(245.0, 450.0, passage), lerpf(586.0, 417.0, passage))
		var scale_factor := lerpf(1.13, 0.62, passage)
		var leading := center + Vector2(95.0, -17.0) * scale_factor
		var rear := center + Vector2(-94.0, 13.0) * scale_factor
		_draw_figure(leading, scale_factor, Color("323f3a"), stride, false)
		_draw_bier(center + Vector2(0, -78) * scale_factor, scale_factor, stride * 1.8)
		_draw_figure(rear, scale_factor, Color("374541"), -stride, false)
		_draw_figure(rear + Vector2(-62, 16) * scale_factor, scale_factor * 0.92, Color("404a46"), stride, false)

	func _draw_bier(center: Vector2, scale_factor: float, sway: float) -> void:
		var p := center + Vector2(0, sway)
		_polygon([p + Vector2(-108, 5) * scale_factor, p + Vector2(89, -38) * scale_factor, p + Vector2(107, -16) * scale_factor, p + Vector2(-89, 30) * scale_factor], Color("362b23"))
		_polygon([p + Vector2(-92, 1) * scale_factor, p + Vector2(63, -42) * scale_factor, p + Vector2(90, -24) * scale_factor, p + Vector2(-66, 29) * scale_factor], CLOTH)
		_polygon([p + Vector2(-30, -13) * scale_factor, p + Vector2(-18, -17) * scale_factor, p + Vector2(9, 2) * scale_factor, p + Vector2(-4, 8) * scale_factor], TRIM)
		draw_line(p + Vector2(-101, 12) * scale_factor, p + Vector2(98, -24) * scale_factor, Color("ad8651"), 2.0, true)

	func _draw_mourners() -> void:
		var ids := ["spouse", "secretary", "radomir"]
		var garb := [Color("46423f"), Color("384641"), Color("4d4637")]
		for index in range(ids.size()):
			var point := Vector2(275.0 + index * 175.0, 556.0 + (0 if index == 1 else 20))
			var pace := smoothstep(0.1 + index * 0.13, 1.5 + index * 0.13, elapsed)
			point.x += (index - 1) * (1.0 - pace) * 38.0
			var highlighted: bool = selected_contact == ids[index]
			_draw_figure(point, 1.45, garb[index], 0.18 * sin(elapsed * 1.4 + index), highlighted)

	func _draw_burial() -> void:
		var pairs: int = {"modest": 1, "solemn": 3, "grand": 5}.get(burial, 1)
		for index in range(pairs):
			var y := 455.0 + index * 31.0
			var x := 335.0 - index * 22.0
			var lean := 0.18 * sin(elapsed * 1.5 + index)
			_draw_figure(Vector2(x, y), 0.72 + index * 0.12, Color("3e4944"), lean, false)
			_draw_figure(Vector2(900.0 - x, y + 12), 0.74 + index * 0.12, Color("4b4440"), -lean, false)
		var walk := smoothstep(0.15, 2.7, elapsed)
		var clergy := Vector2(450, lerpf(350.0, 424.0, walk))
		var stride := sin(elapsed * 8.0) * (1.0 - walk)
		_draw_figure(clergy, 0.87, Color("675e46"), stride, false)
		_draw_bier(Vector2(450, 394), 0.85, 0.0)

	func _draw_figure(foot: Vector2, factor: float, cloth: Color, stride: float, lit: bool) -> void:
		var outline := Color("171b19")
		var head := foot + Vector2(0.0, -111.0 - absf(stride) * 1.1) * factor
		var shoulder := head + Vector2(0, 19) * factor
		var cloak_end := foot + Vector2(0, -14) * factor
		draw_line(foot + Vector2(-22, 0) * factor, foot + Vector2(26, 0) * factor, Color(0.01, 0.02, 0.02, 0.40), 5.0 * factor, true)
		draw_line(foot + Vector2(-9, -25) * factor, foot + Vector2(-13 - stride * 12.0, 0) * factor, outline, 7.0 * factor, true)
		draw_line(foot + Vector2(9, -25) * factor, foot + Vector2(13 + stride * 12.0, 0) * factor, outline, 7.0 * factor, true)
		var silhouette := PackedVector2Array([shoulder + Vector2(-16, 0) * factor, shoulder + Vector2(16, 0) * factor, cloak_end + Vector2(20, 0) * factor, cloak_end + Vector2(-21, 0) * factor])
		_polygon(silhouette, cloth.lightened(0.23) if lit else cloth)
		draw_line(shoulder + Vector2(-13, 7) * factor, cloak_end + Vector2(-7, -8) * factor, outline, 2.0 * factor, true)
		draw_line(shoulder + Vector2(10, 7) * factor, cloak_end + Vector2(13, -8) * factor, outline, 2.0 * factor, true)
		draw_circle(head, 10.5 * factor, Color("987962") if lit else Color("766452"), true, -1.0, true)
		draw_arc(head, 11.0 * factor, PI, TAU, 14, outline, 3.0 * factor, true)
		if lit:
			draw_line(foot + Vector2(-35, 7) * factor, foot + Vector2(35, 7) * factor, Color("d9bc7d"), 2.0, true)

	func _polygon(points: PackedVector2Array, color: Color) -> void:
		draw_colored_polygon(points, color)
