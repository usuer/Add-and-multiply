extends SceneTree

var failures: Array[String] = []
var autosave_path := "user://test_ui_autosave_%d.json" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1024, 700)
	var scene := load("res://app/app_root.tscn") as PackedScene
	var app := scene.instantiate()
	app.set("autosave_path", autosave_path)
	root.add_child(app)
	await process_frame
	await process_frame
	_press_key(KEY_ESCAPE)
	if app.get("pause_overlay").visible:
		failures.append("Escape не должен открывать меню позади вступления")
	await _check_playable_prologue(app)
	await process_frame
	_check_header(app, "при запуске")
	app.call("_show_pause_menu")
	await process_frame
	_check_pause_menu(app)
	_press_key(KEY_TAB)
	var pause_focus := root.gui_get_focus_owner()
	if pause_focus == null or not (app.get("pause_overlay") as Control).is_ancestor_of(pause_focus):
		failures.append("Tab не должен переключать фокус на карту из меню паузы")
	app.call("_hide_pause_menu")
	await process_frame
	app.call("_on_illustrated_building_selected", &"granary")
	await process_frame
	_check_location_scene(app, 1)
	var manage := _find_button(app.get("location_scene"), "Управление местом")
	if manage != null:
		_click(manage.get_global_rect().get_center())
	else:
		failures.append("В амбаре отсутствует кнопка управления")
	await process_frame
	_check_building_panel(app)
	var panel := app.get("building_panel") as Control
	var focus := root.gui_get_focus_owner()
	if focus == null or not panel.is_ancestor_of(focus):
		failures.append("Окно управления должно получать фокус после открытия")
	_click(Vector2(8, 8))
	if panel.visible:
		failures.append("Клик вне управления должен вернуться в локацию")
	if manage != null and not manage.has_focus():
		failures.append("При закрытии управления фокус должен вернуться к кнопке локации")
	await process_frame
	_check_location_scene(app, 1)
	app.call("_close_location_scene")
	await _check_forge_brief(app)
	app.call("_on_illustrated_building_selected", &"market")
	await process_frame
	await _check_location_sizes(app, 3)
	app.call("_close_location_scene")
	app.call("_on_illustrated_building_selected", &"castle")
	await process_frame
	await _check_location_sizes(app, 4)
	var location := app.get("location_scene") as Control
	var actors: Dictionary = location.get("person_actors")
	var spouse := actors["spouse"] as Control
	_click(spouse.get_global_rect().get_center())
	await process_frame
	_check_character_dialogue(app)
	var choices := location.get("dialogue_options") as Control
	var reply := _find_button(choices, "Рассказать, чего")
	if reply == null:
		failures.append("В разговоре отсутствует доступная реплика Аделе")
	else:
		_click(reply.get_global_rect().get_center())
		await process_frame
		if _find_button(choices, "Рассказать, чего") != null or _find_button(choices, "Попросить её пока") != null:
			failures.append("После ответа должны исчезнуть все варианты того же решения")
		if _find_button(choices, "Спросить, что сейчас тревожит") == null:
			failures.append("После решения вопрос о семье должен оставаться доступным")
	_click(Vector2(8, 8))
	if location.get("dialogue_layer").visible:
		failures.append("Нажатие по затемнённой области должно закрывать разговор")
	_click(spouse.get_global_rect().get_center())
	await process_frame
	if location.get("dialogue_case_heading").text != "Решение принято" or not location.get("dialogue_response").text.contains("Всеволод"):
		failures.append("Повторная встреча должна напомнить предыдущий ответ")
	_click(Vector2(8, 8))
	app.call("_open_location_management", "castle")
	await process_frame
	_check_council_cards(app)
	app.call("_appoint_councillor", "steward", "vesna")
	await process_frame
	var council_state: WorldState = app.get("state") as WorldState
	if str(council_state.council.appointments["steward"]) != "vesna":
		failures.append("Назначение из карточки совета должно менять управляющего")
	app.call("_set_castle_section", "people")
	await process_frame
	_check_people_dossier(app)
	app.call("_set_castle_section", "policies")
	await process_frame
	_check_policy_cards(app)
	app.call("_enact_policy", "labor", "protected")
	await process_frame
	if str(council_state.policies.active["labor"]) != "protected":
		failures.append("Изменение правила через карточку должно вступать в силу")
	app.call("_close_building_panel")
	await process_frame
	app.call("_close_location_scene")
	app.call("_on_illustrated_building_selected", &"barracks")
	await process_frame
	_check_location_scene(app, 2)
	app.call("_close_location_scene")
	var state: WorldState = app.get("state") as WorldState
	var advance := app.get("advance_button") as Button
	_click(advance.get_global_rect().get_center())
	if state.calendar.cycle != 1 or not app.get("secretary_panel").visible:
		failures.append("До подписания первого решения переход должен открывать дело без смены даты")
	app.call("_close_secretary")
	state.opening_decision.choose_funeral("solemn")
	state.opening_decision.choose_grain("partial")
	state.opening_decision.choose_funding("state")
	await _check_formal_burial(app, state)
	_click(advance.get_global_rect().get_center())
	await process_frame
	_check_header(app, "после завершения периода")
	await _check_period_report(app, state, advance)
	await _check_city_case_from_map(app, state)
	app.call("_open_secretary")
	await process_frame
	_check_header(app, "при открытии протечки амбара")
	_check_secretary_summary(app, 1)
	app.call("_choose_story_event", "granary_roof", "repair")
	await process_frame
	_check_header(app, "после отправки плотников")
	_check_secretary_summary(app, 0)
	_check_story_history(app)
	var story_body := app.get("secretary_case_body") as Control
	var displayed_result := story_body.get_node_or_null("StoryResult") as Label
	if displayed_result == null or displayed_result.text != state.story_timeline.outcome("granary_roof"):
		failures.append("Результат решения должен быть виден внутри открытой канцелярии")
	app.call("_close_secretary")
	app.call("_on_advance_period")
	await process_frame
	_check_header(app, "после следующего периода")
	await _check_period_archive(app, state)
	app.call("_open_secretary")
	await process_frame
	_check_header(app, "при повторном открытии секретаря")
	await _check_seal_dossier(app)
	await _check_campaign_contact(app, state)
	await _check_compact_dialogue(location, state)
	await _check_battle_clicks(app, state)
	await _check_castle_people_picker(app, state)
	await _check_authority_confirmation(app, state)
	await _check_family_letter_from_secretary(app, state)
	await _check_hearing_and_epilogue(app, state)
	app.call("_open_secretary")
	await _check_common_desktop_sizes(app)
	_check_exit_confirmation(app)
	app.call("_on_illustrated_building_selected", &"castle")
	app.call("_open_character_dialogue", "spouse")
	app.call("_on_new_campaign")
	app.call("_on_new_campaign")
	if location.visible or location.get("dialogue_layer").visible or app.get("modal_shade").visible:
		failures.append("Новая кампания должна закрывать окна и разговоры предыдущей")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(autosave_path))
	if failures.is_empty():
		print("PASS UI: current period, city choices, battle input, modal focus and desktop scaling")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_period_report(app: Node, state: WorldState, advance: Button) -> void:
	var overlay := app.get("period_report_panel") as Control
	var card := overlay.get("panel") as Control
	if not overlay.visible or not root.get_visible_rect().encloses(card.get_global_rect()):
		failures.append("Сводка должна открываться после перехода и помещаться целиком")
		return
	if state.period_report.get("cycle") != 2 or not str(state.period_report.get("notes")).contains("Вода в старом амбаре"):
		failures.append("Сводка должна показывать новый период и открывшееся дело")
	_click(advance.get_global_rect().get_center())
	if state.calendar.cycle != 2:
		failures.append("Клик из открытой сводки не должен повторно завершать период")
	if overlay.visible:
		_press_key(KEY_ESCAPE)
	await process_frame
	var reopen := app.get("period_report_button") as Button
	_click(reopen.get_global_rect().get_center())
	await process_frame
	var secretary := overlay.get("secretary_button") as Button
	_click(secretary.get_global_rect().get_center())
	if overlay.visible or not app.get("secretary_panel").visible:
		failures.append("Из повторно открытой сводки должен работать переход к секретарю")
	app.call("_close_secretary")

func _check_playable_prologue(app: Node) -> void:
	var intro := app.get("intro_overlay") as Control
	var stage := intro.get("stage") as Control
	var next := intro.get("next_button") as Button
	var began := float(stage.get("elapsed"))
	await create_timer(0.12).timeout
	if float(stage.get("elapsed")) <= began:
		failures.append("Графическая сцена вступления должна двигаться")
	for beat in range(3):
		_click(next.get_global_rect().get_center())
		await process_frame
	var contacts: Dictionary = intro.get("contact_buttons")
	var marek := contacts.get("secretary") as Button
	if marek == null or not marek.is_visible_in_tree():
		failures.append("У входа в храм должна быть возможность поговорить с Мареком")
	else:
		_click(marek.get_global_rect().get_center())
		await process_frame
		var state := app.get("state") as WorldState
		if not state.facts.get("prologue_met_secretary", false):
			failures.append("Знакомство в храме должно оставаться фактом кампании")
	for beat in range(2):
		_click(next.get_global_rect().get_center())
		await process_frame
	if intro.visible:
		failures.append("Последняя сцена должна выводить в город")
		intro.call("skip")

func _check_formal_burial(app: Node, state: WorldState) -> void:
	app.call("_open_secretary")
	await process_frame
	var seal := app.get("resolve_opening_button") as Button
	_click(seal.get_global_rect().get_center())
	await process_frame
	var intro := app.get("intro_overlay") as Control
	if state.opening_decision.status != OpeningDecision.Status.RESOLVED or not intro.visible or intro.get("burial_plan") != "solemn":
		failures.append("Только подпись должна открывать выбранные княжеские похороны")
	else:
		var next := intro.get("next_button") as Button
		_click(next.get_global_rect().get_center())
		await process_frame
		if intro.visible or not state.facts.get("burial_seen", false) or not app.get("secretary_panel").visible:
			failures.append("Из похорон нужно вернуться к итогам подписанного дела")
	app.call("_close_secretary")

func _check_city_case_from_map(app: Node, state: WorldState) -> void:
	var map := app.get("illustrated_map") as Control
	var marker := _find_button(map, "✦  Замок")
	if marker == null:
		failures.append("Новое дело Лады должно отмечаться на карте")
		return
	_click(marker.get_global_rect().get_center())
	await process_frame
	var location := app.get("location_scene") as Control
	var actors: Dictionary = location.get("person_actors")
	var sister := actors.get("sister") as Control
	if sister == null:
		failures.append("Отмеченная локация должна открывать сцену с Ладой")
		return
	_click(sister.get_global_rect().get_center())
	await process_frame
	var brief := location.get("dialogue_prompt") as Label
	var choices := location.get("dialogue_options") as Control
	if not brief.visible or not brief.text.contains("пять мер") or not brief.text.contains("сверить записи при свидетелях"):
		failures.append("В деле Лады должны быть понятны расхождение в выдаче зерна и её просьба о сверке")
	var reply := _find_button(choices, "Сверить списки")
	if reply == null:
		failures.append("В деле Лады должно быть доступно решение о публичной сверке")
	else:
		var funds := state.state_treasury
		var conversation_scroll := location.get("dialogue_scroll") as ScrollContainer
		conversation_scroll.ensure_control_visible(reply)
		await process_frame
		state.state_treasury = 0
		_click(reply.get_global_rect().get_center())
		await process_frame
		if state.facts.get("lowland_register") != "open" or state.state_treasury != 0:
			failures.append("Игрок должен иметь возможность решить городское дело с пустой казной")
		state.state_treasury = funds
	_press_key(KEY_ESCAPE)
	_press_key(KEY_ESCAPE)

func _check_period_archive(app: Node, state: WorldState) -> void:
	var overlay := app.get("period_report_panel") as Control
	var earlier := overlay.get("previous_button") as Button
	var later := overlay.get("next_button") as Button
	var date := overlay.get("date_label") as Label
	if not earlier.is_visible_in_tree() or earlier.disabled or not later.disabled:
		failures.append("Во второй сводке должна открываться навигация по истории")
		return
	_click(earlier.get_global_rect().get_center())
	await process_frame
	if date.text != state.period_archive[0]["date"] or later.disabled:
		failures.append("Кнопка «Раньше» должна показывать дату и сверку прошлого периода")
	_click(later.get_global_rect().get_center())
	await process_frame
	if date.text != state.period_report["date"]:
		failures.append("Кнопка «Позже» должна возвращать последнюю сводку")

func _check_battle_clicks(app: Node, state: WorldState) -> void:
	state.army.begin_border_battle("ambush")
	app.call("_on_illustrated_building_selected", &"barracks")
	await process_frame
	var field := app.get("battle_view") as Control
	var battle_controls := app.get("building_panel") as Control
	var orders := app.get("battle_primary_button") as Button
	var units: Dictionary = field.get("_friendly_buttons")
	if field.get_global_rect().intersects(battle_controls.get_global_rect()):
		failures.append("Поле и панель приказов должны иметь отдельные области")
	for unit_id in ["archers", "cavalry"]:
		var unit := units.get(unit_id) as Control
		if unit == null or not unit.is_visible_in_tree():
			failures.append("Отряд %s должен быть на поле" % unit_id)
			continue
		_click(unit.get_global_rect().get_center())
		if app.get("selected_army_unit") != unit_id or not field.visible:
			failures.append("Клик по отряду %s должен выбрать его и оставить бой открытым" % unit_id)
	var deployment_actions := app.get("building_actions") as Control
	for rank_count in [1, 2, 3]:
		await process_frame
		await process_frame
		var depth := _find_button(deployment_actions, str(rank_count) + " лини")
		if depth == null:
			failures.append("У конницы не найден переключатель глубины строя")
			continue
		_click(depth.get_global_rect().get_center())
		await process_frame
		if state.army.friendly["cavalry"]["depth"] != rank_count:
			failures.append("Кнопка %d рядов оставила глубину %d" % [rank_count, state.army.friendly["cavalry"]["depth"]])
		_check_formation_depth(field, "cavalry", rank_count)
	_click(orders.get_global_rect().get_center())
	await process_frame
	if not orders.visible or not orders.disabled or not orders.text.begins_with("Завершить ход"):
		failures.append("Команда завершения хода должна оставаться на виду и ждать приказов")
	var army_actions := app.get("building_actions") as Control
	for order: Array in [["retinue", "Наступать строем"], ["archers", "Прицельный залп"], ["cavalry", "Обойти фланг"]]:
		var unit := units[order[0]] as Control
		_click(unit.get_global_rect().get_center())
		await process_frame
		var command := _find_button(army_actions, order[1])
		if command == null:
			failures.append("На панели должен появиться приказ для %s" % order[0])
			continue
		_click(command.get_global_rect().get_center())
		await process_frame
	_click(orders.get_global_rect().get_center())
	if state.army.battle_log.size() != 1:
		failures.append("Видимая команда должна выполнить все три приказа одним ходом")
	app.call("_close_building_panel")

func _check_formation_depth(field: Control, unit_id: String, rank_count: int) -> void:
	var layers: Dictionary = field.get("_figure_layers")
	var formation := layers[unit_id] as Control
	var ranks: Dictionary = {}
	var count := 0
	for member: Control in formation.get_children():
		if member.visible:
			count += 1
			ranks[roundi(member.position.y * 100)] = true
			if not field.get_global_rect().encloses(member.get_global_rect()):
				failures.append("Фигура бойца вышла за пределы поля во время расстановки")
	if count != 9 or ranks.size() != rank_count:
		failures.append("Для %s ожидалось %d рядов и девять фигур, показано %d рядов и %d фигур" % [unit_id, rank_count, ranks.size(), count])

func _check_forge_brief(app: Node) -> void:
	app.call("_on_illustrated_building_selected", &"smithy")
	await process_frame
	var location := app.get("location_scene") as Control
	var forge_master := (location.get("person_actors") as Dictionary).get("forge_master") as Control
	if forge_master == null:
		failures.append("В кузнице должен быть мастер Глеб")
	else:
		_click(forge_master.get_global_rect().get_center())
		await process_frame
		await process_frame
		var prompt := location.get("dialogue_prompt") as Label
		var options := location.get("dialogue_options") as Control
		if not prompt.is_visible_in_tree() or not prompt.text.contains("Старосты трёх деревень") or not prompt.text.contains("До конца недели кузница успеет выполнить один заказ"):
			failures.append("До выбора Глеб должен объяснить, кто ждёт ремонта и почему нужно выбрать один заказ")
		if _find_button(options, "Сначала выковать крепление для плотины") == null or _find_button(options, "Сначала починить плуги для трёх деревень") == null:
			failures.append("Оба понятных распоряжения должны быть доступны в разговоре с Глебом")
	app.call("_close_location_scene")

func _check_castle_people_picker(app: Node, state: WorldState) -> void:
	var initial_size := root.size
	var initial_scale := root.content_scale_size
	var vardan := state.characters["vardan"] as CharacterState
	var initial_trust := vardan.trust
	vardan.trust = -15
	app.call("_on_illustrated_building_selected", &"castle")
	await process_frame
	var location := app.get("location_scene") as Control
	var manage := _find_button(location, "Управление местом")
	_click(manage.get_global_rect().get_center())
	await process_frame
	await process_frame
	var panel := app.get("building_panel") as Control
	var actions := app.get("building_actions") as Control
	var scroll := app.get("building_scroll") as ScrollContainer
	var people := _find_button(actions, "Люди")
	if people == null:
		failures.append("В управлении замком нужна вкладка «Люди»")
	else:
		_click(people.get_global_rect().get_center())
		await process_frame
		await process_frame
		var picker := _find_button(actions, "Выбрать человека")
		if picker == null:
			failures.append("Во вкладке «Люди» должен открываться выбор человека")
		else:
			_click(picker.get_global_rect().get_center())
			root.content_scale_size = Vector2i.ZERO
			for window_size in [Vector2i(1440, 900), Vector2i(1280, 720), Vector2i(720, 440)]:
				root.size = window_size
				await process_frame
				await process_frame
				if not root.get_visible_rect().encloses(panel.get_global_rect()) or actions.size.x > scroll.size.x:
					failures.append("Список людей вышел за границы окна при размере %s" % window_size)
			var item := _find_button(actions, vardan.display_name)
			if item == null:
				failures.append("Список должен включать последнего персонажа")
			else:
				scroll.ensure_control_visible(item)
				await process_frame
				if not scroll.get_global_rect().grow(2).encloses(item.get_global_rect()):
					failures.append("До последнего персонажа можно прокрутить, и его имя помещается целиком: %s / %s" % [item.get_global_rect(), scroll.get_global_rect()])
				_click(item.get_global_rect().get_center())
				await process_frame
				await process_frame
				var labels: Array[String] = []
				_collect_label_text(actions, labels)
				if not labels.has(vardan.display_name) or not str(labels).contains("Открытое недоверие"):
					failures.append("Выбор последнего персонажа должен открыть его карточку и текущее отношение")
				if not root.get_visible_rect().encloses(panel.get_global_rect()) or actions.size.x > scroll.size.x:
					failures.append("Длинное описание отношения не должно расширять панель за правый край")
				var current_picker := _find_button(actions, "Выбрать человека")
				if current_picker == null or not current_picker.has_focus():
					failures.append("После выбора фокус должен остаться на кнопке списка")
	root.content_scale_size = initial_scale
	root.size = initial_size
	vardan.trust = initial_trust
	_click(Vector2(8, 8))
	if panel.visible:
		failures.append("Клик по затемнению должен закрыть управление замком")
	app.call("_close_building_panel")
	app.call("_close_location_scene")
	await process_frame

func _check_authority_confirmation(app: Node, state: WorldState) -> void:
	app.call("_on_illustrated_building_selected", &"castle")
	app.call("_open_location_management", "castle")
	app.call("_set_castle_section", "justice")
	await process_frame
	await process_frame
	var actions := app.get("building_actions") as Control
	var detain := _find_button(actions, "Взять под стражу")
	if detain == null:
		failures.append("В суде должно быть распоряжение о задержании чиновника")
	else:
		var scroll := app.get("building_scroll") as ScrollContainer
		scroll.ensure_control_visible(detain)
		await process_frame
		var before := state.justice.prisoners
		_click(detain.get_global_rect().get_center())
		await process_frame
		var confirmation := app.get("authority_confirmation") as ConfirmationDialog
		if confirmation == null or not confirmation.visible or state.justice.prisoners != before:
			failures.append("Взятие под стражу должно требовать отдельного подтверждения")
		else:
			confirmation.confirmed.emit()
			confirmation.hide()
			if state.justice.prisoners != before + 1:
				failures.append("Подтверждённое задержание должно занимать место в тюрьме")
	app.call("_close_building_panel")
	app.call("_close_location_scene")

func _check_campaign_contact(app: Node, state: WorldState) -> void:
	# Set up the case, then use the same input as a player for the entire visit.
	app.call("_choose_story_event", "dead_prince_order", "quiet")
	await process_frame
	var contact := _find_button(app.get("secretary_case_body"), "Марек может найти")
	if contact == null:
		failures.append("После решения о проверке в канцелярии должна появиться ссылка на Марека")
		return
	var scroll := app.get("secretary_scroll") as ScrollContainer
	scroll.ensure_control_visible(contact)
	await process_frame
	_click(contact.get_global_rect().get_center())
	await process_frame
	var location := app.get("location_scene") as Control
	if not location.visible or str(location.get("active_person")) != "secretary" or app.get("secretary_panel").visible:
		failures.append("Ссылка из дела должна открывать разговор с Мареком поверх тронного зала")
		return
	var option: Dictionary = state.conversations.option("secretary", "keep_copy")
	var reply := _find_button(location.get("dialogue_options"), str(option["title"]))
	if reply == null:
		failures.append("У Марека должна быть доступна реплика о копии")
	else:
		var conversation_scroll := location.get("dialogue_scroll") as ScrollContainer
		conversation_scroll.ensure_control_visible(reply)
		await process_frame
		_click(reply.get_global_rect().get_center())
		await process_frame
		if not state.facts.get("marek_copy_saved", false):
			failures.append("Выбранная реплика должна сохранять сюжетную улику")
	_press_key(KEY_ESCAPE)
	if not location.visible or location.get("dialogue_layer").visible:
		failures.append("Первый Escape должен вернуть из разговора в тронный зал")
	_press_key(KEY_ESCAPE)
	if location.visible:
		failures.append("Второй Escape должен вернуть из тронного зала на карту")

func _check_seal_dossier(app: Node) -> void:
	var body := app.get("secretary_case_body") as Control
	var scroll := app.get("secretary_scroll") as ScrollContainer
	var link := _find_button(body, "Материалы дела о печати")
	if link == null:
		failures.append("Из канцелярии должны открываться материалы расследования")
		return
	scroll.ensure_control_visible(link)
	await process_frame
	_click(link.get_global_rect().get_center())
	await process_frame
	var title := app.get("secretary_title") as Label
	var back := _find_button(body, "← К делам канцелярии")
	if title.text != "Дело о второй печати" or back == null:
		failures.append("Папка должна открываться отдельной страницей с возвратом")
		return
	_click(back.get_global_rect().get_center())
	await process_frame
	if title.text != "Дела княжеской канцелярии":
		failures.append("Из папки нужно возвращаться к открытым делам")

func _check_family_letter_from_secretary(app: Node, original: WorldState) -> void:
	var family := WorldState.new()
	family.opening_decision.choose_funeral("modest")
	family.opening_decision.choose_grain("partial")
	family.opening_decision.resolve(family)
	while family.calendar.cycle < 11:
		family.advance_period()
	family.story_timeline.choose(family, "family_warning", "evacuate")
	family.advance_period()
	app.set("state", family)
	app.call("_open_secretary")
	await process_frame
	await process_frame
	var body := app.get("secretary_case_body") as Control
	var scroll := app.get("secretary_scroll") as ScrollContainer
	var choice := _find_button(body, "Спросить, что нужно семье")
	if choice == null:
		failures.append("Письмо из-за города должно появиться в открытых делах канцелярии")
	else:
		scroll.ensure_control_visible(choice)
		await process_frame
		_click(choice.get_global_rect().get_center())
		await process_frame
		var receipt := body.get_node_or_null("StoryResult") as Label
		if family.facts.get("family_letter") != "listen" or receipt == null or not receipt.text.contains("Ладу"):
			failures.append("Отправка письма должна показать результат и назначить ответ на следующий период")
		if _find_button(body, "Предложить письменные гарантии") != null:
			failures.append("После отправки из канцелярии оба ответа на письмо должны исчезнуть")
	app.call("_close_secretary")
	app.set("state", original)

func _check_hearing_and_epilogue(app: Node, original: WorldState) -> void:
	var chapter := WorldState.new()
	chapter.opening_decision.choose_funeral("modest")
	chapter.opening_decision.choose_grain("partial")
	chapter.opening_decision.resolve(chapter)
	while chapter.calendar.cycle < 17:
		chapter.advance_period()
	chapter.story_timeline.choose(chapter, "night_of_second_seal", "capital")
	chapter.advance_period()
	chapter.story_timeline.choose(chapter, "new_rule", "law")
	app.set("state", chapter)
	app.call("_open_secretary")
	var body := app.get("secretary_case_body") as Control
	var scroll := app.get("secretary_scroll") as ScrollContainer
	var title := app.get("secretary_title") as Label
	await _click_secretary_choice(body, scroll, "Дело о подложных приказах · решение")
	if title.text != "Слушание о второй печати":
		failures.append("Дело должно открывать отдельный экран слушания")
	await _click_secretary_choice(body, scroll, "Свериться с материалами дела")
	if title.text != "Дело о второй печати":
		failures.append("Из слушания должно открываться досье")
	await _click_secretary_choice(body, scroll, "← К распоряжению о деле")
	if title.text != "Слушание о второй печати":
		failures.append("Из досье нужно возвращаться к слушанию")
	await _click_secretary_choice(body, scroll, "Огласить, что установлено")
	var verdict: Dictionary = chapter.facts.get("council_verdict", {})
	if verdict.get("choice") != "publish_record" or _find_button(body, "Огласить, что установлено") != null:
		failures.append("Слушание должно сохранить выбранное распоряжение и скрыть варианты")
	if scroll.get_h_scroll_bar().visible:
		failures.append("Слушание должно помещаться без прокрутки вправо")
	app.call("_close_secretary")
	await process_frame
	var finish := app.get("advance_button") as Button
	if finish.text != "Завершить главу":
		failures.append("Последняя кнопка перехода должна предупреждать, что закончится глава")
	_click(finish.get_global_rect().get_center())
	await process_frame
	await process_frame
	var report := app.get("period_report_panel") as Control
	var open_ending := report.get("secretary_button") as Button
	if not report.visible or open_ending.text != "Читать эпилог":
		failures.append("Последняя сводка должна предложить перейти к эпилогу")
	else:
		_click(open_ending.get_global_rect().get_center())
		await process_frame
		if report.visible or title.text != "Итог первой главы":
			failures.append("Последняя сводка должна закрыться и открыть итог главы")
		if scroll.get_h_scroll_bar().visible:
			failures.append("Эпилог должен помещаться без прокрутки вправо")
		await _click_secretary_choice(body, scroll, "Открыть летопись и донесения")
		if _find_button(body, "Ход 18 · Дело о подложных приказах") == null:
			failures.append("Из эпилога игрок должен открыть летопись с принятым распоряжением")
	app.call("_close_period_report")
	app.call("_close_secretary")
	app.set("state", original)
	app.call("_refresh_ui", "Кампания продолжается")

func _click_secretary_choice(body: Control, scroll: ScrollContainer, caption: String) -> void:
	await process_frame
	await process_frame
	var button := _find_button(body, caption)
	if button == null:
		failures.append("В канцелярии должна быть доступна кнопка «%s»" % caption)
		return
	scroll.ensure_control_visible(button)
	await process_frame
	_click(button.get_global_rect().get_center())
	await process_frame

func _check_compact_dialogue(location: Control, state: WorldState) -> void:
	var normal_scale := root.content_scale_size
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(720, 440)
	location.visible = true
	var replies: Dictionary = {}
	for index in range(6):
		replies[str(index)] = {"title": ("Предложить обсудить следующий шаг без посторонних. ").repeat(7)}
	location.call("show_dialogue", "spouse", state.characters["spouse"], state.conversations.profile("spouse"), {"questions": replies})
	await process_frame
	await process_frame
	var panel := location.get("dialogue_panel") as Control
	var scroll := location.get("dialogue_scroll") as ScrollContainer
	var choices := location.get("dialogue_options") as Control
	if not root.get_visible_rect().encloses(panel.get_global_rect()) or scroll.get_h_scroll_bar().visible:
		failures.append("На 720×440 длинные реплики должны помещаться без горизонтальной прокрутки")
	if not scroll.get_v_scroll_bar().visible:
		failures.append("Шесть длинных реплик должны прокручиваться вертикально")
	var last_reply := choices.get_child(choices.get_child_count() - 1) as Control
	last_reply.grab_focus()
	await process_frame
	if scroll.scroll_vertical <= 0:
		failures.append("Фокус на последней реплике должен прокрутить её в поле зрения")
	_press_key(KEY_TAB)
	if root.gui_get_focus_owner() != location.get("dialogue_close"):
		failures.append("После последней реплики Tab должен вернуть фокус к закрытию диалога")
	location.call("close_dialogue")
	location.visible = false
	root.content_scale_size = normal_scale
	root.size = Vector2i(1024, 700)
	await process_frame

func _check_common_desktop_sizes(app: Node) -> void:
	for window_size in [Vector2i(1024, 700), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = window_size
		await process_frame
		await process_frame
		_check_header(app, "при размере %dx%d" % [window_size.x, window_size.y])
	var shade := app.get("modal_shade") as ColorRect
	if shade == null or not shade.visible or shade.color.a < 0.7:
		failures.append("Окно секретаря должно отделяться от карты плотным затемнением")

func _check_building_panel(app: Node) -> void:
	var panel := app.get("building_panel") as PanelContainer
	var picture := app.get("building_picture") as TextureRect
	var context := app.get("building_context") as Label
	if panel == null or not panel.visible or not root.get_visible_rect().encloses(panel.get_global_rect()):
		failures.append("Карточка городского объекта должна полностью помещаться на экране: %s / %s" % [panel.get_global_rect(), root.get_visible_rect()])
	if picture == null or picture.texture == null:
		failures.append("Карточка здания должна показывать художественное приближение объекта")
	if context == null or context.text != "ЗАПАСЫ И СНАБЖЕНИЕ":
		failures.append("Карточка амбара должна объяснять назначение места")

func _check_location_scene(app: Node, expected_people: int) -> void:
	var scene := app.get("location_scene") as Control
	if scene == null or not scene.visible or not root.get_visible_rect().encloses(scene.get_global_rect()):
		failures.append("Локация должна открываться отдельной полноэкранной игровой сценой")
		return
	var background := scene.get("background") as TextureRect
	if background == null or background.texture == null:
		failures.append("У отдельной локации должен быть собственный фон")
	var actors: Dictionary = scene.get("person_actors")
	if actors.size() != expected_people:
		failures.append("В локации ожидалось %d отдельных персонажей, найдено %d" % [expected_people, actors.size()])
	var actor_rects: Array[Rect2] = []
	for person_id: String in actors:
		var actor := actors[person_id] as Control
		if not root.get_visible_rect().encloses(actor.get_global_rect()):
			failures.append("Персонаж %s вышел за границы экрана" % person_id)
		for other_rect: Rect2 in actor_rects:
			if actor.get_global_rect().intersects(other_rect):
				failures.append("Персонажи в локации перекрывают друг друга")
		actor_rects.append(actor.get_global_rect())

func _check_location_sizes(app: Node, expected_people: int) -> void:
	for window_size in [Vector2i(1024, 700), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = window_size
		await process_frame
		await process_frame
		_check_location_scene(app, expected_people)
	root.size = Vector2i(1024, 700)
	await process_frame

func _check_character_dialogue(app: Node) -> void:
	var scene := app.get("location_scene") as Control
	var layer := scene.get("dialogue_layer") as Control
	var panel := scene.get("dialogue_panel") as PanelContainer
	if layer == null or not layer.visible:
		failures.append("Нажатие на персонажа должно открывать разговор")
	if panel == null or not root.get_visible_rect().encloses(panel.get_global_rect()):
		failures.append("Диалог должен полностью помещаться на экране")
	var actors: Dictionary = scene.get("person_actors")
	var spouse := actors.get("spouse") as Control
	if spouse == null or spouse.get("display_name") == "":
		failures.append("Персонаж в локации должен иметь видимое имя и отдельное состояние")

func _check_secretary_summary(app: Node, expected_cases: int) -> void:
	var title := app.get("secretary_title") as Label
	var introduction := app.get("secretary_introduction") as Label
	var scroll := app.get("secretary_scroll") as ScrollContainer
	if title == null or title.text != "Дела княжеской канцелярии":
		failures.append("После вступления секретарь должен показывать актуальную повестку, а не старый заголовок")
	if introduction == null or not introduction.text.contains("Новых дел: %d" % expected_cases):
		failures.append("Канцелярия должна кратко показывать число новых дел: ожидалось %d" % expected_cases)
	if scroll == null or scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		failures.append("Канцелярия не должна требовать горизонтальной прокрутки")

func _check_council_cards(app: Node) -> void:
	var labels: Array[String] = []
	_collect_label_text(app.get("building_actions") as Node, labels)
	for marker in ["Сильная сторона:", "Риск:", "Связи:"]:
		var found := false
		for value in labels:
			if value.begins_with(marker):
				found = true
				break
		if not found:
			failures.append("Карточки советников должны показывать раздел «%s»" % marker)

func _check_people_dossier(app: Node) -> void:
	var labels: Array[String] = []
	_collect_label_text(app.get("building_actions") as Node, labels)
	var joined := "\n".join(labels)
	if not joined.contains("ЛЮДИ ВОКРУГ ВЛАСТИ"):
		failures.append("В замке должен открываться отдельный раздел персонажей")
	if not joined.contains("Наблюдаемое отношение:") or not joined.contains("ЧТО ЭТОТ ЧЕЛОВЕК ПОМНИТ"):
		failures.append("Досье персонажа должно объяснять отношение и память без скрытых чисел")

func _check_story_history(app: Node) -> void:
	var labels: Array[String] = []
	_collect_label_text(app.get("secretary_case_body") as Node, labels)
	var found := false
	for value: String in labels:
		if value.begins_with("ЛЕТОПИСЬ РЕШЕНИЙ"):
			found = true
	if not found:
		failures.append("После решения канцелярия должна показывать компактную летопись")

func _collect_label_text(node: Node, output: Array[String]) -> void:
	if node is Label:
		output.append((node as Label).text)
	for child in node.get_children():
		_collect_label_text(child, output)

func _check_policy_cards(app: Node) -> void:
	var labels: Array[String] = []
	_collect_label_text(app.get("building_actions") as Node, labels)
	var has_active_rule := false
	for value in labels:
		if value.begins_with("Действует:"):
			has_active_rule = true
			break
	if not has_active_rule:
		failures.append("Экран правил должен явно отделять действующий указ от альтернатив")

func _check_header(app: Node, stage: String) -> void:
	var visible_rect := root.get_visible_rect()
	var buttons: Array[Button] = []
	for caption in ["Дела секретаря", "Завершить период", "Новая", "Сохр.", "Загр.", "Выход", "Меню"]:
		var button := _find_button(app, caption)
		if button == null:
			failures.append("Нет кнопки «%s» %s" % [caption, stage])
			continue
		buttons.append(button)
		var rect := button.get_global_rect()
		if not button.visible or not visible_rect.encloses(rect):
			failures.append("Кнопка «%s» вышла за экран %s: %s" % [caption, stage, rect])
	for index in range(buttons.size() - 1):
		if buttons[index].get_global_rect().intersects(buttons[index + 1].get_global_rect()):
			failures.append("Кнопки «%s» и «%s» пересекаются %s" % [buttons[index].text, buttons[index + 1].text, stage])

func _check_exit_confirmation(app: Node) -> void:
	app.call("_on_exit_requested")
	var button := app.get("exit_button") as Button
	if not bool(app.get("exit_confirmation")) or button == null or button.text != "Точно?":
		failures.append("Первое нажатие выхода должно запрашивать подтверждение, а не закрывать игру")
	app.call("_cancel_exit_confirmation")
	if bool(app.get("exit_confirmation")) or button.text != "Выход":
		failures.append("Отмена подтверждения должна возвращать обычную кнопку выхода")

func _check_pause_menu(app: Node) -> void:
	var overlay := app.get("pause_overlay") as Control
	var panel := app.get("pause_panel") as PanelContainer
	if overlay == null or not overlay.visible:
		failures.append("Игровое меню должно открываться поверх игры")
	if panel == null or not root.get_visible_rect().encloses(panel.get_global_rect()):
		failures.append("Игровое меню должно полностью помещаться на минимальном экране")
	for caption in ["Продолжить", "Сохранить кампанию", "Загрузить сохранение", "На весь экран", "Звук:", "Сохранить и выйти"]:
		if _find_button(overlay, caption) == null:
			failures.append("В игровом меню нет действия «%s»" % caption)
	var sound_before := bool(app.get("sound_enabled"))
	app.call("_toggle_sound")
	var sound_button := app.get("sound_button") as Button
	if bool(app.get("sound_enabled")) == sound_before or sound_button == null or not sound_button.text.begins_with("Звук:"):
		failures.append("Переключатель звука должен менять состояние и сразу обновлять подпись")
	app.call("_toggle_sound")
	var streams: Dictionary = app.get("sound_streams")
	for sound_id in ["click", "decision", "period", "alert", "battle"]:
		var stream := streams.get(sound_id) as AudioStreamWAV
		if stream == null or stream.data.is_empty():
			failures.append("Звуковой сигнал «%s» должен содержать реальные аудиоданные" % sound_id)

func _find_button(node: Node, caption: String) -> Button:
	if node is Button and (node as Button).text.begins_with(caption):
		return node as Button
	for child in node.get_children():
		var result := _find_button(child, caption)
		if result != null:
			return result
	return null

func _click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)

func _press_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	root.push_input(event, true)
