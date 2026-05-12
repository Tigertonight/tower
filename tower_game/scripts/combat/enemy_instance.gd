class_name EnemyInstance
extends RefCounted

var display_name := "Animated Scribe"
var id := ""
var tier := "normal"
var art_path := ""
var max_hp := 42
var hp := 42
var block := 0
var statuses: Dictionary = {}
var intent_type := "attack"
var intent_damage := 6
var intent_multi_hit_count := 1
var intent_block := 0
var current_move
var move_pool: Array[Dictionary] = []
var phase_move_pool: Array[Dictionary] = []
var opener_move_ids: Array[String] = []
var phase_hp_below_pct := 0.0
var phase_enter_effects: Array[Dictionary] = []
var phase_active := false
var move_history: Array[String] = []
var move_database: Dictionary = {}
var damage_multiplier := 1.0


func setup(enemy_data, moves: Dictionary) -> void:
	id = enemy_data.id
	display_name = enemy_data.display_name
	tier = enemy_data.tier
	art_path = enemy_data.art_path
	max_hp = enemy_data.max_hp
	hp = max_hp
	block = enemy_data.spawn_block
	statuses.clear()
	move_pool = enemy_data.move_pool.duplicate(true)
	phase_move_pool = enemy_data.phase_move_pool.duplicate(true)
	opener_move_ids = enemy_data.opener_move_ids.duplicate()
	phase_hp_below_pct = enemy_data.phase_hp_below_pct
	phase_enter_effects = enemy_data.phase_enter_effects.duplicate(true)
	phase_active = false
	move_history.clear()
	move_database = moves


func is_dead() -> bool:
	return hp <= 0


func choose_intent(turn_number: int, rng: RandomNumberGenerator = null) -> void:
	_check_phase_entry()
	var move_id := ""
	if turn_number <= opener_move_ids.size():
		move_id = opener_move_ids[turn_number - 1]
	if move_id == "":
		move_id = _pick_weighted_move(_active_move_pool(), rng)
	if not move_database.has(move_id):
		push_warning("Unknown enemy move: %s" % move_id)
		return
	current_move = move_database[move_id]
	move_history.append(move_id)
	while move_history.size() > 3:
		move_history.pop_front()
	_apply_intent_from_move(current_move)


func _active_move_pool() -> Array[Dictionary]:
	if phase_active and not phase_move_pool.is_empty():
		return phase_move_pool
	return move_pool


func _pick_weighted_move(pool: Array[Dictionary], rng: RandomNumberGenerator = null) -> String:
	var candidates: Array[Dictionary] = []
	for entry in pool:
		var move_id := String(entry.get("move_id", ""))
		if move_id == "":
			continue
		var max_in_row := int(entry.get("max_in_row", 99))
		if max_in_row > 0 and _recent_repeat_count(move_id) >= max_in_row:
			continue
		candidates.append(entry)
	if candidates.is_empty():
		candidates = pool
	var total_weight := 0
	for entry in candidates:
		total_weight += max(1, int(entry.get("weight", 1)))
	var roll := 0
	if rng != null:
		roll = rng.randi_range(1, max(1, total_weight))
	else:
		roll = randi_range(1, max(1, total_weight))
	for entry in candidates:
		roll -= max(1, int(entry.get("weight", 1)))
		if roll <= 0:
			return String(entry.get("move_id", ""))
	return String(candidates.back().get("move_id", ""))


func _recent_repeat_count(move_id: String) -> int:
	var count := 0
	for index in range(move_history.size() - 1, -1, -1):
		if move_history[index] != move_id:
			break
		count += 1
	return count


func _check_phase_entry() -> void:
	if phase_active or phase_hp_below_pct <= 0.0 or max_hp <= 0:
		return
	if float(hp) / float(max_hp) <= phase_hp_below_pct:
		phase_active = true
		for effect in phase_enter_effects:
			_apply_self_effect(effect)


func _apply_intent_from_move(move) -> void:
	intent_block = 0
	intent_damage = _scaled_damage(move.damage)
	intent_multi_hit_count = max(1, move.multi_hit_count)
	intent_type = move.intent_type
	if intent_type == "attack" and intent_damage >= 13:
		intent_type = "heavy_attack"
	intent_block = move.block


func _scaled_damage(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	return int(round(float(base_damage) * damage_multiplier))


func resolve_intent(combat: Node) -> String:
	if current_move == null:
		return "%s hesitates." % display_name
	if current_move.block > 0:
		block += current_move.block
	for effect in current_move.self_effects:
		_apply_self_effect(effect)
	var total_damage := 0
	if current_move.damage > 0:
		var scaled_base := _scaled_damage(current_move.damage)
		for i in range(max(1, current_move.multi_hit_count)):
			var damage: int = scaled_base + int(statuses.get("strength", 0))
			if int(statuses.get("weak", 0)) > 0:
				damage = floori(float(damage) * 0.75)
			combat.take_player_damage_from_enemy(damage)
			total_damage += damage
	for status in current_move.status_applied:
		var target := String(status.get("target", "player"))
		combat.apply_status_to_named_target(target, String(status.get("status", "")), int(status.get("amount", 0)), self)
	var parts: Array[String] = []
	if current_move.damage > 0:
		if current_move.multi_hit_count > 1:
			parts.append("%s attacks for %d x %d." % [display_name, current_move.multi_hit_count, _scaled_damage(current_move.damage)])
		else:
			parts.append("%s attacks for %d." % [display_name, total_damage])
	if current_move.block > 0:
		parts.append("%s gains %d block." % [display_name, current_move.block])
	if not current_move.status_applied.is_empty():
		parts.append("%s marks the page." % display_name)
	if not current_move.self_effects.is_empty():
		parts.append("%s strengthens its clause." % display_name)
	if parts.is_empty():
		return "%s waits." % display_name
	return " ".join(parts)


func _apply_self_effect(effect: Dictionary) -> void:
	var effect_type := String(effect.get("type", ""))
	match effect_type:
		"strength":
			statuses["strength"] = int(statuses.get("strength", 0)) + int(effect.get("amount", 0))
		"block":
			block += int(effect.get("amount", 0))
		"status":
			var status := String(effect.get("status", ""))
			if status != "":
				statuses[status] = int(statuses.get(status, 0)) + int(effect.get("amount", 0))
		_:
			pass


func get_intent_text() -> String:
	match intent_type:
		"defend":
			return "Intent: Gain %d block" % intent_block
		"heavy_attack":
			return "Intent: Heavy attack %d" % intent_damage
		"attack_multi":
			return "Intent: Attack %d x %d" % [intent_multi_hit_count, intent_damage]
		"attack_defend":
			return "Intent: Attack %d and gain %d block" % [intent_damage, intent_block]
		"buff":
			return "Intent: Buff"
		"debuff":
			return "Intent: Debuff"
		"unknown":
			return "Intent: Unknown"
		_:
			return "Intent: Attack %d" % intent_damage


func get_status_text() -> String:
	var parts: Array[String] = []
	for key in statuses.keys():
		var value := int(statuses[key])
		if value > 0:
			parts.append("%s:%d" % [key, value])
	return " ".join(parts)
