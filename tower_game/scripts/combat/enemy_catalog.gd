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
		"res://data/enemies/el_wax_sentinel.tres",
		"res://data/enemies/el_first_clause.tres",
		"res://data/enemies/el_quill_judge.tres",
		"res://data/enemies/el_ironbound_clerk.tres",
		"res://data/enemies/el_archive_warden.tres",
		"res://data/enemies/b_sealed_curator.tres",
		"res://data/enemies/b_chronicler_of_lost_pages.tres",
		"res://data/enemies/b_grand_archivist.tres"
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
