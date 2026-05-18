extends SceneTree

const RUN_SCENE := preload("res://scenes/run/run_scene.tscn")
const COMBAT_SCENE := preload("res://scenes/combat/combat_scene.tscn")

const OUT_DIR := "res://../tower/targeted_screenshots"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := _parse_args()
	var screen := String(args.get("screen", "map"))
	var stem := String(args.get("out", screen))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await _settle_frames(3)
	_prepare_out_dir(false)
	if screen == "combat":
		await _capture_combat(stem)
	else:
		await _capture_run_screen(screen, stem)
	print("Visual screenshot written: %s" % ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, stem]))
	quit(0)


func _parse_args() -> Dictionary:
	var out: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		var raw := String(arg)
		if not raw.begins_with("--"):
			continue
		raw = raw.substr(2)
		var eq := raw.find("=")
		if eq < 0:
			out[raw] = true
		else:
			out[raw.substr(0, eq)] = raw.substr(eq + 1)
	return out


func _capture_run_screen(screen: String, stem: String) -> void:
	_remove_save()
	_set_zh()
	var run := RUN_SCENE.instantiate()
	root.add_child(run)
	await _settle_frames(4)
	run.gold = 999
	run.player_hp = run.player_max_hp
	run.selected_character_id = "char_assassin"
	run.character_id = "char_assassin"
	match screen:
		"character":
			run._show_character_select_menu()
		"map":
			run._show_map()
		"campfire":
			run._show_campfire()
		"shop":
			run._show_shop()
		"event":
			run.current_act = 1
			_force_event(run, "ev_silent_margin")
			run._show_event()
		"event_blocked":
			run.gold = 0
			run._show_unavailable_event_choice("你的金币不够。")
		"summary":
			run._show_run_summary("defeat")
		_:
			run._show_map()
	await _settle_frames(14)
	await _save_viewport(stem)
	root.remove_child(run)
	run.queue_free()
	await _settle_frames(2)


func _capture_combat(stem: String) -> void:
	_remove_save()
	_set_zh()
	var combat = COMBAT_SCENE.instantiate()
	var deck_ids: Array[String] = [
		"margin_slash", "margin_slash", "margin_slash", "margin_slash",
		"needle_guard", "needle_guard", "needle_guard", "needle_guard",
		"side_cut", "smoke_step", "marked_pin", "throwing_label"
	]
	var relic_ids: Array[String] = ["hidden_blade"]
	combat.configure(
		deck_ids,
		66,
		66,
		"combat",
		0,
		"Archive Fight",
		"e_dust_scribe+e_loose_folio",
		12345,
		relic_ids,
		0,
		"char_assassin",
		"assassin"
	)
	root.add_child(combat)
	await _settle_frames(18)
	await _save_viewport(stem)
	root.remove_child(combat)
	combat.queue_free()
	await _settle_frames(2)


func _settle_frames(count: int) -> void:
	for _i in count:
		await process_frame


func _save_viewport(file_stem: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, file_stem])


func _prepare_out_dir(clear_existing: bool) -> void:
	var abs_dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	if not clear_existing:
		return
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


func _remove_save() -> void:
	var path := "user://tower_run.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
