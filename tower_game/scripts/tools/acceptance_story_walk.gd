extends SceneTree

const RUN_SCENE := preload("res://scenes/run/run_scene.tscn")

const EVENTS := [
	{"id": "ev_quiet_stack", "act": 1, "character": "char_vanguard"},
	{"id": "ev_clean_margin", "act": 1, "character": "char_vanguard"},
	{"id": "ev_red_string", "act": 1, "character": "char_vanguard"},
	{"id": "ev_revision_desk", "act": 1, "character": "char_archivist"},
	{"id": "ev_ink_well", "act": 1, "character": "char_vanguard"},
	{"id": "ev_loose_page", "act": 1, "character": "char_vanguard"},
	{"id": "ev_transform_lantern", "act": 2, "character": "char_vanguard"},
	{"id": "ev_dust_oracle", "act": 2, "character": "char_archivist"},
	{"id": "ev_weighing_scales", "act": 2, "character": "char_vanguard"},
	{"id": "ev_burned_archive", "act": 3, "character": "char_vanguard"},
	{"id": "ev_broken_standard", "act": 1, "character": "char_vanguard"},
	{"id": "ev_unpaid_contract", "act": 1, "character": "char_archivist"},
	{"id": "ev_core_orrery", "act": 1, "character": "char_mage"},
	{"id": "ev_silent_margin", "act": 1, "character": "char_assassin"},
]

const TOP_LEVEL_SCREENS := [
	"main_menu",
	"character_select",
	"story_intro",
	"map",
	"shop",
	"campfire",
	"run_summary_defeat",
	"run_summary_victory",
]

var failures: Array[String] = []
var warnings: Array[String] = []
var backup: Variant = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	backup = _backup_save()
	_remove_save()
	await _check_top_level_screens()
	await _check_all_events_and_choices()
	_restore_save(backup)
	if not warnings.is_empty():
		print("Acceptance warnings:")
		for item in warnings:
			print("  - %s" % item)
	if failures.is_empty():
		print("Acceptance story walk passed.")
		quit(0)
	else:
		print("Acceptance story walk failed:")
		for item in failures:
			print("  - %s" % item)
		quit(1)


func _check_top_level_screens() -> void:
	for screen_id in TOP_LEVEL_SCREENS:
		var run := await _new_run()
		match screen_id:
			"main_menu":
				run._show_main_menu()
			"character_select":
				run._show_character_select_menu()
			"story_intro":
				run._show_story_intro()
			"map":
				run._show_map()
			"shop":
				run.gold = 999
				run._show_shop()
			"campfire":
				run._show_campfire()
			"run_summary_defeat":
				run._show_run_summary("defeat")
			"run_summary_victory":
				run._show_run_summary("victory")
		await process_frame
		_check_screen(run, screen_id)
		run.queue_free()
		await process_frame


func _check_all_events_and_choices() -> void:
	for event_entry in EVENTS:
		var event_id := String(event_entry["id"])
		var choice_count := await _event_choice_count(event_entry)
		if choice_count < 1:
			failures.append("%s has no choice buttons." % event_id)
			continue
		if choice_count != 3:
			warnings.append("%s has %d choices; expected 3 for consistent event rhythm." % [event_id, choice_count])
		for choice_index in choice_count:
			var run := await _new_run()
			_prepare_event_run(run, event_entry)
			run._show_event()
			await process_frame
			_check_screen(run, "%s choice screen" % event_id)
			var buttons := _all_enabled_buttons(run.current_screen)
			if choice_index >= buttons.size():
				failures.append("%s missing button index %d." % [event_id, choice_index])
				run.queue_free()
				await process_frame
				continue
			buttons[choice_index].pressed.emit()
			await process_frame
			await process_frame
			if run.current_screen == null:
				failures.append("%s choice %d left the run on a null screen." % [event_id, choice_index + 1])
			run.queue_free()
			await process_frame


func _event_choice_count(event_entry: Dictionary) -> int:
	var run := await _new_run()
	_prepare_event_run(run, event_entry)
	run._show_event()
	await process_frame
	var count := _all_enabled_buttons(run.current_screen).size()
	_check_screen(run, "%s choice screen" % String(event_entry["id"]))
	run.queue_free()
	await process_frame
	return count


func _new_run() -> Node:
	_remove_save()
	var run: Node = RUN_SCENE.instantiate()
	root.add_child(run)
	await process_frame
	await process_frame
	run.gold = 999
	run.player_hp = run.player_max_hp
	if run.run_deck_ids.size() < 12:
		failures.append("Starter deck unexpectedly small: %d." % run.run_deck_ids.size())
	return run


func _prepare_event_run(run: Node, event_entry: Dictionary) -> void:
	run.current_act = int(event_entry["act"])
	run.character_id = String(event_entry["character"])
	run.selected_character_id = String(event_entry["character"])
	run.events_seen.clear()
	for candidate in _event_pool_for(run):
		if String(candidate) != String(event_entry["id"]):
			run.events_seen.append(String(candidate))
	run.event_rng.seed = 12345


func _event_pool_for(run: Node) -> Array[String]:
	var common_pool: Array[String] = ["ev_quiet_stack", "ev_clean_margin", "ev_loose_page"]
	var act_pools := {
		1: ["ev_red_string", "ev_revision_desk", "ev_ink_well"],
		2: ["ev_transform_lantern", "ev_dust_oracle", "ev_weighing_scales"],
		3: ["ev_burned_archive", "ev_dust_oracle", "ev_weighing_scales"]
	}
	var class_pools := {
		"warrior": ["ev_broken_standard"],
		"warlock": ["ev_unpaid_contract", "ev_revision_desk", "ev_dust_oracle"],
		"mage": ["ev_core_orrery"],
		"assassin": ["ev_silent_margin"]
	}
	var pool: Array[String] = []
	for item in common_pool:
		pool.append(item)
	for item in act_pools.get(run.current_act, common_pool):
		pool.append(String(item))
	for item in class_pools.get(run._current_character_class_id(), []):
		pool.append(String(item))
	return pool


func _check_screen(run: Node, label: String) -> void:
	if run.current_screen == null:
		failures.append("%s did not create current_screen." % label)
		return
	var button_count := _all_buttons(run.current_screen).size()
	if button_count == 0:
		warnings.append("%s has no buttons; confirm this is intentional." % label)
	var scroll_count := _count_nodes_by_class(run.current_screen, "ScrollContainer")
	if scroll_count > 0 and (label.find("event") >= 0 or label.find("campfire") >= 0 or label.find("choice") >= 0):
		warnings.append("%s uses %d ScrollContainer(s); this may create visible scrollbars in narrative UI." % [label, scroll_count])
	var out_of_bounds := _find_out_of_bounds_controls(run.current_screen)
	for item in out_of_bounds:
		warnings.append("%s out-of-bounds control: %s" % [label, item])


func _all_buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	if node is Button:
		out.append(node)
	for child in node.get_children():
		out.append_array(_all_buttons(child))
	return out


func _all_enabled_buttons(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for button in _all_buttons(node):
		if not button.disabled and button.visible:
			buttons.append(button)
	return buttons


func _count_nodes_by_class(node: Node, class_name_value: String) -> int:
	var count := 0
	if node.get_class() == class_name_value:
		count += 1
	for child in node.get_children():
		count += _count_nodes_by_class(child, class_name_value)
	return count


func _find_out_of_bounds_controls(node: Node) -> Array[String]:
	var out: Array[String] = []
	if node is Control and node.visible:
		var control := node as Control
		var rect := Rect2(control.global_position, control.size)
		if rect.size.x > 0 and rect.size.y > 0:
			if rect.position.x < -4 or rect.position.y < -4 or rect.end.x > 1284 or rect.end.y > 724:
				out.append("%s rect=%s" % [control.get_class(), rect])
	for child in node.get_children():
		out.append_array(_find_out_of_bounds_controls(child))
	return out


func _backup_save() -> Variant:
	var path := "user://tower_run.json"
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return file.get_as_text()


func _remove_save() -> void:
	var path := "user://tower_run.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _restore_save(saved_text: Variant) -> void:
	_remove_save()
	if saved_text == null:
		return
	var file := FileAccess.open("user://tower_run.json", FileAccess.WRITE)
	if file != null:
		file.store_string(String(saved_text))
