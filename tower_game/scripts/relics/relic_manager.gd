class_name RelicManager
extends RefCounted

const RelicInstanceScript := preload("res://scripts/relics/relic_instance.gd")
const EffectResolverScript := preload("res://scripts/cards/effect_resolver.gd")

var relics: Array = []


func setup(relic_data_list: Array) -> void:
	relics.clear()
	for relic_data in relic_data_list:
		var relic = RelicInstanceScript.new()
		relic.setup(relic_data)
		relics.append(relic)


# Fire every relic whose `trigger` matches `trigger_name` and whose
# `trigger_params` are satisfied by `context`.
#
# `context` is an optional Dictionary supplied by the call site so trigger-
# specific filters can be evaluated. Recognised keys:
#   "card_type":      String      # for card_played
#   "hp_pct":         float       # for hp_threshold (player_hp / max_hp)
# Unknown context keys are ignored — relics opt-in via trigger_params.
func trigger(trigger_name: String, combat: Node, context: Dictionary = {}) -> void:
	# combat_start always resets per-combat latches — even relics that don't
	# fire on combat_start need their counters cleared between fights.
	if trigger_name == "combat_start":
		for r in relics:
			r.reset_combat_state()
	for relic in relics:
		if relic.data.trigger != trigger_name:
			continue
		if not _params_match(relic, context):
			continue
		if not _consume_counter(relic):
			continue
		_apply_effects(relic, combat)


func _params_match(relic, context: Dictionary) -> bool:
	var params: Dictionary = relic.data.trigger_params if relic.data.trigger_params != null else {}
	if params.has("card_type_filter"):
		var want := String(params["card_type_filter"])
		var got := String(context.get("card_type", ""))
		if want != "" and want != got:
			return false
	if params.has("hp_below_pct"):
		var threshold := float(params["hp_below_pct"])
		var hp_pct := float(context.get("hp_pct", 1.0))
		if hp_pct >= threshold:
			return false
		# hp_threshold is one-shot per combat by design.
		if relic.fired_this_combat:
			return false
	if params.has("once_per_combat") and bool(params["once_per_combat"]):
		if relic.fired_this_combat:
			return false
	# enemy_killed-specific: filter to enemies that had a particular status when
	# they died (e.g. Inkwell's Grace requires `had_ink: true`).
	if params.has("require_had_ink") and bool(params["require_had_ink"]):
		if not bool(context.get("had_ink", false)):
			return false
	return true


func _consume_counter(relic) -> bool:
	# Returns true if this firing should proceed. Increments per-instance
	# counter / fired latch as appropriate.
	var params: Dictionary = relic.data.trigger_params if relic.data.trigger_params != null else {}
	if params.has("every_n"):
		var n: int = max(1, int(params["every_n"]))
		relic.counter += 1
		if relic.counter < n:
			return false
		relic.counter = 0
	if params.has("once_per_combat") and bool(params["once_per_combat"]):
		relic.fired_this_combat = true
	if params.has("hp_below_pct"):
		# hp_threshold is implicitly once_per_combat.
		relic.fired_this_combat = true
	return true


func _apply_effects(relic, combat: Node) -> void:
	for effect in relic.data.effects:
		var target_name := String(effect.get("target", "player"))
		if target_name == "enemy":
			if String(effect.get("type", "")) == "status":
				combat.apply_status_to_named_target("enemy", String(effect.get("status", "")), int(effect.get("amount", 0)))
			elif String(effect.get("type", "")) == "damage":
				if combat.has_method("deal_damage") and combat.enemy != null:
					combat.deal_damage(combat.enemy, int(effect.get("amount", 0)))
			continue
		EffectResolverScript.resolve(effect, combat, combat, combat)


func get_display_text() -> String:
	if relics.is_empty():
		return "Relics: none"
	var names: Array[String] = []
	for relic in relics:
		names.append(relic.get_display_name())
	return "Relics: %s" % ", ".join(names)


func get_relic_ids() -> Array[String]:
	var ids: Array[String] = []
	for relic in relics:
		ids.append(String(relic.data.id))
	return ids
