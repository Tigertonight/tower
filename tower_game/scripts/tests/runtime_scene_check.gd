extends SceneTree

const RUN_SCENE := preload("res://scenes/run/run_scene.tscn")
const COMBAT_SCENE := preload("res://scenes/combat/combat_scene.tscn")

const ENCOUNTERS := [
	"e_dust_scribe",
	"e_loose_folio",
	"e_wax_acolyte",
	"e_margin_hound",
	"e_burnt_courier",
	"el_wax_sentinel",
	"el_first_clause",
	"b_sealed_curator"
]

const STARTER_DECK := [
	"strike_form",
	"strike_form",
	"strike_form",
	"strike_form",
	"strike_form",
	"guard_form",
	"guard_form",
	"guard_form",
	"guard_form",
	"archive_bash",
	"quick_read",
	"forward_step"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := false
	var backup: Variant = _backup_save()
	_remove_save()
	failed = await _check_run_scene() or failed
	failed = await _check_combat_encounters() or failed
	_restore_save(backup)
	if failed:
		print("Runtime scene check failed.")
		quit(1)
	else:
		print("Runtime scene check passed.")
		quit(0)


func _check_run_scene() -> bool:
	var failed := false
	var run: Node = RUN_SCENE.instantiate()
	root.add_child(run)
	await process_frame
	await process_frame
	if run.map_nodes.size() != 9:
		push_error("Run scene did not generate 9 map layers.")
		failed = true
	if run.run_deck_ids.size() != 12:
		push_error("Run scene starter deck size is %d, expected 12." % run.run_deck_ids.size())
		failed = true
	if run.relic_ids.is_empty() or run.relic_ids[0] != "sealed_badge":
		push_error("Run scene did not start with Sealed Badge.")
		failed = true
	if run.current_screen == null:
		push_error("Run scene did not build an initial screen.")
		failed = true
	run._show_map()
	await process_frame
	if run.current_screen == null:
		push_error("Run scene did not build map screen.")
		failed = true
	run.queue_free()
	await process_frame
	return failed


func _check_combat_encounters() -> bool:
	var failed := false
	for encounter_id in ENCOUNTERS:
		var combat: Node = COMBAT_SCENE.instantiate()
		var node_type := "combat"
		if encounter_id.begins_with("el_"):
			node_type = "elite"
		elif encounter_id.begins_with("b_"):
			node_type = "boss"
		combat.configure(_starter_deck(), 76, 76, node_type, 0, encounter_id, encounter_id, 1000 + ENCOUNTERS.find(encounter_id), _starter_relics())
		root.add_child(combat)
		await process_frame
		await process_frame
		if combat.enemy == null:
			push_error("Combat %s did not create enemy." % encounter_id)
			failed = true
		elif combat.enemy.id != encounter_id:
			push_error("Combat expected %s, got %s." % [encounter_id, combat.enemy.id])
			failed = true
		elif combat.enemy.current_move == null:
			push_error("Combat %s did not choose enemy intent." % encounter_id)
			failed = true
		if combat.deck == null or combat.deck.hand.size() != 5:
			push_error("Combat %s did not draw opening hand." % encounter_id)
			failed = true
		combat.queue_free()
		await process_frame
	return failed


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


func _restore_save(backup: Variant) -> void:
	_remove_save()
	if backup == null:
		return
	var file := FileAccess.open("user://tower_run.json", FileAccess.WRITE)
	if file != null:
		file.store_string(String(backup))


func _starter_deck() -> Array[String]:
	var ids: Array[String] = []
	for card_id in STARTER_DECK:
		ids.append(String(card_id))
	return ids


func _starter_relics() -> Array[String]:
	return ["sealed_badge"]
