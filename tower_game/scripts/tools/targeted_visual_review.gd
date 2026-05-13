extends SceneTree

const RUN_SCENE := preload("res://scenes/run/run_scene.tscn")
const COMBAT_SCENE := preload("res://scenes/combat/combat_scene.tscn")

const OUT_DIR := "res://../tower/targeted_screenshots"

var backup: Variant = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	backup = _backup_save()
	_remove_save()
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await process_frame
	await process_frame
	_prepare_out_dir()
	await _shot_run_screen("01_character_select_zh", func(run) -> void:
		_set_zh()
		run._show_character_select_menu()
	)
	await _shot_run_screen("02_campfire_zh", func(run) -> void:
		_set_zh()
		run._show_campfire()
	)
	await _shot_run_screen("03_shop_zh", func(run) -> void:
		_set_zh()
		run.gold = 999
		run._show_shop()
	)
	await _shot_run_screen("04_event_transform_zh", func(run) -> void:
		_set_zh()
		run.current_act = 2
		run.character_id = "char_vanguard"
		run.selected_character_id = "char_vanguard"
		_force_event(run, "ev_transform_lantern")
		run._show_event()
	)
	await _shot_run_screen("05_event_unavailable_zh", func(run) -> void:
		_set_zh()
		run.gold = 0
		run._show_unavailable_event_choice("你的金币不够。")
	)
	await _shot_run_screen("06_run_summary_defeat_zh", func(run) -> void:
		_set_zh()
		run._show_run_summary("defeat")
	)
	await _shot_combat_screen("07_combat_zh")
	_restore_save(backup)
	print("Targeted visual review screenshots written to %s" % ProjectSettings.globalize_path(OUT_DIR))
	quit(0)


func _shot_run_screen(file_stem: String, setup: Callable) -> void:
	_remove_save()
	var run := RUN_SCENE.instantiate()
	root.add_child(run)
	await process_frame
	await process_frame
	run.gold = 999
	run.player_hp = run.player_max_hp
	setup.call(run)
	await _settle_frames(8)
	await _save_viewport(file_stem)
	root.remove_child(run)
	run.free()
	await _settle_frames(3)


func _shot_combat_screen(file_stem: String) -> void:
	_remove_save()
	_set_zh()
	var combat = COMBAT_SCENE.instantiate()
	root.add_child(combat)
	var deck_ids: Array[String] = [
		"strike_form", "strike_form", "strike_form", "strike_form",
		"guard_form", "guard_form", "guard_form", "guard_form",
		"quick_read", "field_order", "page_turn", "archive_bash"
	]
	var relic_ids: Array[String] = ["sealed_badge"]
	combat.configure(
		deck_ids,
		76,
		76,
		"combat",
		0,
		"Dust Scribe",
		"e_dust_scribe",
		12345,
		relic_ids,
		0,
		"char_vanguard",
		"vanguard"
	)
	await _settle_frames(12)
	await _save_viewport(file_stem)
	root.remove_child(combat)
	combat.free()
	await _settle_frames(3)


func _settle_frames(count: int) -> void:
	for _i in count:
		await process_frame


func _save_viewport(file_stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, file_stem])


func _prepare_out_dir() -> void:
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var dir := DirAccess.open(abs_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _set_zh() -> void:
	var loc = root.get_node_or_null("/root/LocalizationManager")
	if loc != null and loc.has_method("set_language"):
		loc.set_language("zh")


func _force_event(run: Node, event_id: String) -> void:
	run.events_seen.clear()
	for candidate in _event_pool_for(run):
		if String(candidate) != event_id:
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
