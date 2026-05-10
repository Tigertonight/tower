class_name EffectResolver
extends RefCounted


static func resolve(effect: Dictionary, combat: Node, source: Variant, target: Variant) -> void:
	var effect_type := String(effect.get("type", ""))
	match effect_type:
		"damage":
			combat.deal_damage(target, int(effect.get("amount", 0)))
		"block":
			combat.gain_player_block(int(effect.get("amount", 0)))
		"draw":
			combat.draw_cards(int(effect.get("amount", 0)))
		"energy":
			combat.gain_energy(int(effect.get("amount", 0)))
		"status":
			combat.apply_status(target, String(effect.get("status", "")), int(effect.get("amount", 0)))
		"strength":
			combat.apply_status(source, "strength", int(effect.get("amount", 0)))
		"heal_player":
			combat.heal_player(int(effect.get("amount", 0)))
		_:
			push_warning("Unknown effect type: %s" % effect_type)
