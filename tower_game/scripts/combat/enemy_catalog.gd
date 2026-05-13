class_name EnemyCatalog
extends RefCounted

const EnemyMoveDataScript := preload("res://scripts/combat/enemy_move_data.gd")

static func load_enemies() -> Dictionary:
	var paths := [
		"res://data/enemies/e_dust_scribe.tres",
		"res://data/enemies/e_loose_folio.tres",
		"res://data/enemies/e_wax_acolyte.tres",
		"res://data/enemies/e_margin_hound.tres",
		"res://data/enemies/e_burnt_courier.tres",
		"res://data/enemies/e_glassed_intern.tres",
		"res://data/enemies/e_late_filer.tres",
		"res://data/enemies/e_silent_ledger.tres",
		"res://data/enemies/e_dust_sentinel.tres",
		"res://data/enemies/e_red_string_imp.tres",
		"res://data/enemies/e_index_rat.tres",
		"res://data/enemies/e_staple_swarm.tres",
		"res://data/enemies/e_ink_moth.tres",
		"res://data/enemies/e_clause_mender.tres",
		"res://data/enemies/e_ledger_sentry.tres",
		"res://data/enemies/e_null_page.tres",
		"res://data/enemies/e_redaction_monk.tres",
		"res://data/enemies/e_keyhole_mimic.tres",
		"res://data/enemies/el_wax_sentinel.tres",
		"res://data/enemies/el_first_clause.tres",
		"res://data/enemies/el_quill_judge.tres",
		"res://data/enemies/el_ironbound_clerk.tres",
		"res://data/enemies/el_archive_warden.tres",
		"res://data/enemies/el_dust_chorus.tres",
		"res://data/enemies/el_penitent_index.tres",
		"res://data/enemies/el_null_librarian.tres",
		"res://data/enemies/el_redaction_engine.tres",
		"res://data/enemies/b_sealed_curator.tres",
		"res://data/enemies/b_chronicler_of_lost_pages.tres",
		"res://data/enemies/b_grand_archivist.tres",
		"res://data/enemies/b_ink_tyrant.tres",
		"res://data/enemies/b_mirror_tribunal.tres",
		"res://data/enemies/b_last_catalog.tres"
	]
	var enemies := {}
	for path in paths:
		var enemy = load(path)
		if enemy != null:
			enemies[enemy.id] = enemy
	return enemies


static func build_moves() -> Dictionary:
	var moves := {}
	_add_move(moves, "mv_inkstroke", "Inkstroke", "attack", 6)
	_add_move(moves, "mv_scribe_defend", "Defend", "defend", 0, 1, 5)
	_add_move(moves, "mv_study", "Study", "buff", 0, 1, 0, [], [{"type": "strength", "amount": 1}])
	_add_move(moves, "mv_flutter", "Flutter", "attack_multi", 3, 3)
	_add_move(moves, "mv_gather", "Gather", "defend", 0, 1, 4)
	_add_move(moves, "mv_slap", "Slap", "attack", 8)
	_add_move(moves, "mv_seal", "Seal", "defend", 0, 1, 6)
	_add_move(moves, "mv_imprint", "Imprint", "debuff", 0, 1, 0, [{"target": "player", "status": "frail", "amount": 2}])
	_add_move(moves, "mv_stamp", "Stamp", "attack", 9)
	_add_move(moves, "mv_tear", "Tear", "attack", 7, 1, 0, [{"target": "player", "status": "vulnerable", "amount": 1}])
	_add_move(moves, "mv_bay", "Bay", "debuff", 0, 1, 0, [{"target": "player", "status": "weak", "amount": 2}])
	_add_move(moves, "mv_unknown_lunge", "Unknown Lunge", "unknown", 11)
	_add_move(moves, "mv_dispatch", "Dispatch", "attack", 12)
	_add_move(moves, "mv_kindle", "Kindle", "buff", 0, 1, 0, [], [{"type": "strength", "amount": 2}])
	_add_move(moves, "mv_tamp", "Tamp", "defend", 0, 1, 6)
	_add_move(moves, "mv_set_seal", "Set Seal", "defend", 0, 1, 12)
	_add_move(moves, "mv_heavy_stamp", "Heavy Stamp", "attack", 14)
	_add_move(moves, "mv_double_press", "Double Press", "attack_multi", 7, 2)
	_add_move(moves, "mv_clause_strike", "Clause Strike", "attack", 11)
	_add_move(moves, "mv_cite_subsection", "Cite Subsection", "debuff", 0, 1, 0, [{"target": "player", "status": "weak", "amount": 1}])
	_add_move(moves, "mv_amend", "Amend", "attack_defend", 0, 1, 8, [{"target": "player", "status": "frail", "amount": 1}])
	_add_move(moves, "mv_cold_appraisal", "Cold Appraisal", "attack", 13)
	_add_move(moves, "mv_marginal_note", "Marginal Note", "debuff", 0, 1, 0, [{"target": "player", "status": "vulnerable", "amount": 2}])
	_add_move(moves, "mv_seal_block", "Seal Block", "defend", 0, 1, 14)
	_add_move(moves, "mv_errata", "Errata", "buff", 0, 1, 0, [], [{"type": "strength", "amount": 1}])
	_add_move(moves, "mv_final_review", "Final Review", "attack_multi", 6, 3)
	_add_move(moves, "mv_signature", "Signature", "attack", 18, 1, 0, [{"target": "player", "status": "weak", "amount": 1}])
	_add_move(moves, "mv_seal_player_card", "Seal Player Card", "debuff", 0, 1, 0, [{"target": "player", "status": "weak", "amount": 1}])
	_add_move(moves, "mv_dictate", "Dictate", "defend", 0, 1, 18)
	# ── Boss phase-2 specific moves ────────────────────────────────────────────
	# Chronicler of Lost Pages — phase 2: paper-barrage and silence clauses
	_add_move(moves, "mv_lost_pages", "Lost Pages", "attack_multi", 5, 4)
	_add_move(moves, "mv_silence_clause", "Silence Clause", "attack", 24, 1, 0, [{"target": "player", "status": "weak", "amount": 2}])
	_add_move(moves, "mv_amend_record", "Amend Record", "defend", 0, 1, 14, [], [{"type": "strength", "amount": 2}])
	# Grand Archivist — phase 2: anathema, excommunicate, archival decree
	_add_move(moves, "mv_anathema", "Anathema", "attack", 28, 1, 0, [{"target": "player", "status": "frail", "amount": 2}])
	_add_move(moves, "mv_excommunicate", "Excommunicate", "attack_multi", 10, 3, 0, [{"target": "player", "status": "vulnerable", "amount": 1}])
	_add_move(moves, "mv_archival_decree", "Archival Decree", "defend", 0, 1, 22, [], [{"type": "strength", "amount": 3}])
	# Expanded enemy set — clearer act checks and richer encounter texture.
	_add_move(moves, "mv_nibble_index", "Nibble Index", "attack", 5, 2)
	_add_move(moves, "mv_hide_in_footnotes", "Hide in Footnotes", "defend", 0, 1, 7)
	_add_move(moves, "mv_gnaw_binding", "Gnaw Binding", "attack", 6, 1, 0, [{"target": "player", "status": "vulnerable", "amount": 1}])
	_add_move(moves, "mv_staple_prick", "Staple Prick", "attack_multi", 2, 4)
	_add_move(moves, "mv_scatter_clips", "Scatter Clips", "debuff", 0, 1, 0, [{"target": "player", "status": "frail", "amount": 1}])
	_add_move(moves, "mv_swarm_tightens", "Swarm Tightens", "buff", 0, 1, 6, [], [{"type": "strength", "amount": 1}])
	_add_move(moves, "mv_ink_dust", "Ink Dust", "debuff", 0, 1, 0, [{"target": "player", "status": "weak", "amount": 1}, {"target": "player", "status": "ink", "amount": 2}])
	_add_move(moves, "mv_lamp_dive", "Lamp Dive", "attack", 10)
	_add_move(moves, "mv_powder_wings", "Powder Wings", "defend", 0, 1, 8)
	_add_move(moves, "mv_repair_clause", "Repair Clause", "defend", 0, 1, 10, [], [{"type": "strength", "amount": 1}])
	_add_move(moves, "mv_cut_fine_print", "Cut Fine Print", "attack", 9, 1, 0, [{"target": "player", "status": "frail", "amount": 1}])
	_add_move(moves, "mv_late_fee", "Late Fee", "attack", 12)
	_add_move(moves, "mv_audit_slam", "Audit Slam", "attack", 16)
	_add_move(moves, "mv_guarded_entry", "Guarded Entry", "defend", 0, 1, 12)
	_add_move(moves, "mv_debit_mark", "Debit Mark", "debuff", 0, 1, 0, [{"target": "player", "status": "vulnerable", "amount": 2}])
	_add_move(moves, "mv_blank_stare", "Blank Stare", "debuff", 0, 1, 0, [{"target": "player", "status": "weak", "amount": 2}])
	_add_move(moves, "mv_page_fold", "Page Fold", "attack_defend", 8, 1, 8)
	_add_move(moves, "mv_white_cut", "White Cut", "attack", 13)
	_add_move(moves, "mv_black_bar", "Black Bar", "attack", 14, 1, 0, [{"target": "player", "status": "weak", "amount": 1}])
	_add_move(moves, "mv_censor_prayer", "Censor Prayer", "buff", 0, 1, 0, [], [{"type": "strength", "amount": 2}])
	_add_move(moves, "mv_erase_margin", "Erase Margin", "debuff", 0, 1, 0, [{"target": "player", "status": "frail", "amount": 2}])
	_add_move(moves, "mv_keyhole_bite", "Keyhole Bite", "attack", 11)
	_add_move(moves, "mv_lock_jaw", "Lock Jaw", "attack", 8, 1, 0, [{"target": "player", "status": "vulnerable", "amount": 2}])
	_add_move(moves, "mv_mimic_shield", "Mimic Shield", "defend", 0, 1, 16)
	_add_move(moves, "mv_chorus_screech", "Chorus Screech", "debuff", 0, 1, 0, [{"target": "player", "status": "weak", "amount": 2}])
	_add_move(moves, "mv_chorus_peck", "Chorus Peck", "attack_multi", 4, 4)
	_add_move(moves, "mv_chorus_gather", "Chorus Gather", "defend", 0, 1, 18, [], [{"type": "strength", "amount": 1}])
	_add_move(moves, "mv_penitent_sentence", "Penitent Sentence", "attack", 18, 1, 0, [{"target": "player", "status": "frail", "amount": 1}])
	_add_move(moves, "mv_index_kneel", "Index Kneel", "defend", 0, 1, 20, [], [{"type": "strength", "amount": 1}])
	_add_move(moves, "mv_margin_whip", "Margin Whip", "attack_multi", 8, 2)
	_add_move(moves, "mv_null_command", "Null Command", "debuff", 0, 1, 0, [{"target": "player", "status": "weak", "amount": 2}, {"target": "player", "status": "frail", "amount": 1}])
	_add_move(moves, "mv_void_checkout", "Void Checkout", "attack", 20)
	_add_move(moves, "mv_silent_catalogue", "Silent Catalogue", "defend", 0, 1, 18, [], [{"type": "strength", "amount": 2}])
	_add_move(moves, "mv_redaction_saw", "Redaction Saw", "attack_multi", 6, 4)
	_add_move(moves, "mv_censor_field", "Censor Field", "defend", 0, 1, 24)
	_add_move(moves, "mv_blackout_notice", "Blackout Notice", "debuff", 0, 1, 0, [{"target": "player", "status": "vulnerable", "amount": 2}])
	_add_move(moves, "mv_tyrant_spill", "Tyrant Spill", "attack_multi", 4, 5, 0, [{"target": "player", "status": "ink", "amount": 2}])
	_add_move(moves, "mv_black_decree", "Black Decree", "attack", 22, 1, 0, [{"target": "player", "status": "weak", "amount": 2}])
	_add_move(moves, "mv_crowned_ink", "Crowned Ink", "defend", 0, 1, 18, [], [{"type": "strength", "amount": 2}])
	_add_move(moves, "mv_tyrant_flood", "Tyrant Flood", "attack_multi", 7, 4, 0, [{"target": "player", "status": "ink", "amount": 3}])
	_add_move(moves, "mv_mirror_verdict", "Mirror Verdict", "attack", 17, 1, 0, [{"target": "player", "status": "frail", "amount": 1}])
	_add_move(moves, "mv_reflective_barrier", "Reflective Barrier", "defend", 0, 1, 20, [], [{"type": "strength", "amount": 1}])
	_add_move(moves, "mv_double_sentence", "Double Sentence", "attack_multi", 9, 2)
	_add_move(moves, "mv_guilty_reflection", "Guilty Reflection", "attack", 26, 1, 0, [{"target": "player", "status": "vulnerable", "amount": 2}])
	_add_move(moves, "mv_catalog_close", "Catalog Close", "attack", 24)
	_add_move(moves, "mv_final_index", "Final Index", "debuff", 0, 1, 0, [{"target": "player", "status": "weak", "amount": 2}, {"target": "player", "status": "vulnerable", "amount": 1}])
	_add_move(moves, "mv_shelf_collapse", "Shelf Collapse", "attack_multi", 8, 3)
	_add_move(moves, "mv_last_ledger", "Last Ledger", "defend", 0, 1, 28, [], [{"type": "strength", "amount": 2}])
	_add_move(moves, "mv_total_recall", "Total Recall", "attack_multi", 12, 3, 0, [{"target": "player", "status": "frail", "amount": 2}])
	return moves


static func _add_move(moves: Dictionary, id: String, display_name: String, intent_type: String, damage: int = 0, multi_hit_count: int = 1, block: int = 0, status_applied: Array = [], self_effects: Array = []) -> void:
	var move = EnemyMoveDataScript.new()
	move.id = id
	move.display_name = display_name
	move.intent_type = intent_type
	move.damage = damage
	move.multi_hit_count = multi_hit_count
	move.block = block
	move.status_applied = _typed_dictionary_array(status_applied)
	move.self_effects = _typed_dictionary_array(self_effects)
	moves[id] = move


static func _typed_dictionary_array(entries: Array) -> Array[Dictionary]:
	var typed: Array[Dictionary] = []
	for entry in entries:
		typed.append(entry)
	return typed
