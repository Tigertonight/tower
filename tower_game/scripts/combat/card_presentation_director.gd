class_name CardPresentationDirector
extends Node

var combat
var fast_resolve: bool = false


func setup(owner_combat) -> void:
	combat = owner_combat


func set_fast_resolve(enabled: bool) -> void:
	fast_resolve = enabled


func card_has_damage(card) -> bool:
	for effect in _effects(card):
		var et := String(effect.get("type", ""))
		if et == "damage" or et == "damage_all_enemies" or et == "damage_per_target_ink":
			return true
	return false


func resolve_profile(card) -> String:
	if card == null or card.data == null:
		return "focus"
	var explicit := String(card.data.vfx_profile).strip_edges()
	if explicit != "":
		return explicit
	var analysis := _analyze_effects(card)
	if bool(analysis.get("damage", false)):
		if combat != null and combat.has_method("_attack_vfx_profile_for_card"):
			return combat._attack_vfx_profile_for_card(card)
		return "slash"
	if bool(analysis.get("debuff", false)):
		return "debuff"
	if bool(analysis.get("block", false)):
		return "guard"
	if bool(analysis.get("draw", false)):
		return "draw"
	if bool(analysis.get("energy", false)):
		return "energy"
	if bool(analysis.get("power", false)):
		return "power"
	if String(card.data.card_type) == "power":
		return "power"
	if String(card.data.card_type) == "curse" or String(card.data.card_type) == "status":
		return "curse"
	return "focus"


func enqueue_card_presentation(queue, card) -> String:
	var profile := resolve_profile(card)
	queue.push_wait(0.14)
	if card_has_damage(card):
		queue.push(func() -> Tween: return combat._play_player_attack_commit(profile))
		queue.push(func(): combat._spawn_attack_travel_effect(profile))
		queue.push_wait(combat._attack_pre_hit_wait(profile))
		queue.push_hit_pause(combat._attack_hit_pause(profile))
	else:
		queue.push(func(): combat._spawn_card_presentation_effect(profile))
		queue.push_wait(_pre_resolve_wait(profile))
	return profile


func _effects(card) -> Array:
	if card == null:
		return []
	return card.get_effects()


func _analyze_effects(card) -> Dictionary:
	var result := {
		"damage": false,
		"block": false,
		"draw": false,
		"energy": false,
		"power": false,
		"debuff": false
	}
	for effect in _effects(card):
		var et := String(effect.get("type", ""))
		match et:
			"damage", "damage_all_enemies", "damage_per_target_ink":
				result["damage"] = true
			"block":
				result["block"] = true
			"draw":
				result["draw"] = true
			"energy":
				result["energy"] = true
			"strength", "dexterity", "heal_player", "gain_max_hp":
				result["power"] = true
			"status", "status_all_enemies":
				var status := String(effect.get("status", ""))
				if status in ["weak", "vulnerable", "frail", "ink", "poison"]:
					result["debuff"] = true
				else:
					result["power"] = true
			"add_card_to_hand", "add_card_to_discard":
				result["draw"] = true
	return result


func _pre_resolve_wait(profile: String) -> float:
	if fast_resolve:
		return 0.0
	match profile:
		"guard":
			return 0.09
		"draw":
			return 0.08
		"energy":
			return 0.08
		"power":
			return 0.12
		"debuff":
			return 0.11
		"curse":
			return 0.12
		_:
			return 0.07
