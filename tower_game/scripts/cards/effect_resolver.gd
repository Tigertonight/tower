class_name EffectResolver
extends RefCounted


static func resolve(effect: Dictionary, combat: Node, source: Variant, target: Variant) -> void:
	var effect_type := String(effect.get("type", ""))
	match effect_type:
		"damage":
			combat.deal_damage(target, int(effect.get("amount", 0)))
		"damage_per_target_ink":
			# Archivist payoff card: damage scales with stacks already applied to
			# the target. Multiplier defaults to 1 (i.e. raw stack count).
			var ink_stacks: int = 0
			if target != null and target.statuses != null:
				ink_stacks = int(target.statuses.get("ink", 0))
			var mult := int(effect.get("multiplier", 1))
			combat.deal_damage(target, ink_stacks * mult)
		"damage_all_enemies":
			# AoE attack: hit every alive enemy. Falls back to single-target
			# damage if the combat object doesn't expose an enemy list.
			if combat.has_method("alive_enemies"):
				for foe in combat.alive_enemies():
					combat.deal_damage(foe, int(effect.get("amount", 0)))
			else:
				combat.deal_damage(target, int(effect.get("amount", 0)))
		"status_all_enemies":
			# AoE debuff: apply the same status to every alive enemy.
			if combat.has_method("alive_enemies"):
				for foe in combat.alive_enemies():
					combat.apply_status(foe, String(effect.get("status", "")), int(effect.get("amount", 0)))
			else:
				combat.apply_status(target, String(effect.get("status", "")), int(effect.get("amount", 0)))
		"block":
			combat.gain_player_block(int(effect.get("amount", 0)))
		"draw":
			combat.draw_cards(int(effect.get("amount", 0)))
		"energy":
			combat.gain_energy(int(effect.get("amount", 0)))
		"status":
			var who := String(effect.get("target", "enemy"))
			if who == "self" or who == "player":
				combat.apply_status(source, String(effect.get("status", "")), int(effect.get("amount", 0)))
			else:
				combat.apply_status(target, String(effect.get("status", "")), int(effect.get("amount", 0)))
		"self_status":
			combat.apply_status(source, String(effect.get("status", "")), int(effect.get("amount", 0)))
		"strength":
			combat.apply_status(source, "strength", int(effect.get("amount", 0)))
		"dexterity":
			combat.apply_status(source, "dexterity", int(effect.get("amount", 0)))
		"heal_player":
			combat.heal_player(int(effect.get("amount", 0)))
		"lose_hp":
			# Bypass block — used for curses, decay-on-turn-end statuses.
			combat.lose_player_hp(int(effect.get("amount", 0)))
		"add_card_to_discard":
			combat.add_card_to_discard(String(effect.get("card_id", "")))
		"add_card_to_hand":
			combat.add_card_to_hand(String(effect.get("card_id", "")))
		"exhaust_random_card":
			combat.exhaust_random_hand_card(int(effect.get("amount", 1)))
		"discard_random_card":
			combat.discard_random_hand_card(int(effect.get("amount", 1)))
		"max_hp":
			combat.gain_max_hp(int(effect.get("amount", 0)))
		"gold":
			combat.gain_gold(int(effect.get("amount", 0)))
		_:
			push_warning("Unknown effect type: %s" % effect_type)
