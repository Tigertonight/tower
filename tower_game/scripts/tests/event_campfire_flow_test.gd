extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Event/campfire flow test starting.")
	var scene: PackedScene = load("res://scenes/run/run_scene.tscn")
	var run = scene.instantiate()
	root.add_child(run)
	run._load_content_databases()
	run.character_catalog = run.CharacterCatalogScript.load_all()

	run.character_id = "char_vanguard"
	run.selected_character_id = "char_vanguard"
	run.run_seed = 12345
	run.current_act = 1
	run.map_nodes = run.MapGeneratorScript.generate(run.run_seed, run.current_act)
	run.current_node_id = "L1_0"
	run.floor_index = 1
	_set_deck(run, _test_deck())
	run.player_max_hp = 76
	run.player_hp = 50
	run.gold = 20
	run.relic_ids.clear()
	run.relic_ids.append("sealed_badge")
	run.potions = [null, null, null]
	run.pending_node = _event_node("ev_revision_desk")

	_check_unavailable_returns_to_event(run, func(): run._event_upgrade_for_gold(50), "low-gold upgrade")
	_check_unavailable_returns_to_event(run, func(): run._event_buy_random_card(30), "low-gold random card")
	_check_unavailable_returns_to_event(run, func(): run._event_buy_max_hp(60, 12), "low-gold max hp")
	_check_unavailable_returns_to_event(run, func(): run._event_transform_card_for_gold(40), "low-gold transform")

	_set_deck(run, ["strike_form", "guard_form", "archive_bash", "quick_read"])
	_check_unavailable_returns_to_event(run, func(): run._event_remove_any_card_for_heal(10), "too-small offer")

	_set_deck(run, _test_deck())
	run.gold = 80
	_check_cancel_returns_to_event(run, func(): run._event_remove_card_for_gold(75), 80, 50, "event remove cancel")
	_check_cancel_returns_to_event(run, func(): run._event_upgrade_for_gold(50), 60, 50, "event gold upgrade cancel")
	_check_cancel_returns_to_event(run, func(): run._event_upgrade_for_hp(6), 60, 50, "event hp upgrade cancel")
	_check_cancel_returns_to_event(run, func(): run._event_transform_card_for_gold(40), 60, 50, "event paid transform cancel")
	_check_cancel_returns_to_event(run, func(): run._event_transform_card(), 60, 50, "event free transform cancel")
	_check_cancel_returns_to_event(run, func(): run._event_remove_any_card_for_heal(10), 60, 50, "event offer cancel")

	run.pending_node = _campfire_node()
	_check_cancel_returns_to_campfire(run, func(): run._show_card_picker_for_upgrade("Upgrade", "Pick", true, 0, 0, "campfire"), "campfire upgrade cancel")
	_check_cancel_returns_to_campfire(run, func(): run._show_card_picker_for_remove_any("Remove", "Pick", true, 0, 0, "campfire"), "campfire remove cancel")
	_check_cancel_returns_to_campfire(run, func(): run._show_card_picker_for_transform("Transform", "Pick", true, 0, 0, "campfire"), "campfire transform cancel")

	print("Event/campfire flow test passed.")
	quit(0)


func _check_unavailable_returns_to_event(run, action: Callable, label: String) -> void:
	action.call()
	run._return_to_pending_event_or_map()
	_assert_pending_type(run, "event", label)


func _check_cancel_returns_to_event(run, action: Callable, expected_gold: int, expected_hp: int, label: String) -> void:
	run.pending_node = _event_node("ev_revision_desk")
	run.gold = expected_gold
	run.player_hp = expected_hp
	action.call()
	run._on_run_deck_pick_cancelled(null)
	if run.gold != expected_gold:
		_fail("%s did not refund gold. got=%d expected=%d" % [label, run.gold, expected_gold])
		return
	if run.player_hp != expected_hp:
		_fail("%s did not refund hp. got=%d expected=%d" % [label, run.player_hp, expected_hp])
		return
	_assert_pending_type(run, "event", label)


func _check_cancel_returns_to_campfire(run, action: Callable, label: String) -> void:
	run.pending_node = _campfire_node()
	action.call()
	run._on_run_deck_pick_cancelled(null)
	_assert_pending_type(run, "campfire", label)


func _assert_pending_type(run, expected: String, label: String) -> void:
	if String(run.pending_node.get("type", "")) != expected:
		_fail("%s cleared pending %s." % [label, expected])


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _test_deck() -> Array[String]:
	return ["strike_form", "strike_form", "strike_form", "strike_form", "strike_form", "guard_form", "guard_form", "guard_form", "guard_form", "archive_bash", "quick_read"]


func _set_deck(run, ids: Array) -> void:
	run.run_deck_ids.clear()
	for id in ids:
		run.run_deck_ids.append(String(id))


func _event_node(event_id: String) -> Dictionary:
	return {"id": "L1_0", "type": "event", "title": "Archive Event", "encounter_id": "", "event_id": event_id}


func _campfire_node() -> Dictionary:
	return {"id": "L1_0", "type": "campfire", "title": "Waxlight Nook", "encounter_id": "", "event_id": ""}
