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


func trigger(trigger_name: String, combat: Node) -> void:
	for relic in relics:
		if relic.data.trigger != trigger_name:
			continue
		for effect in relic.data.effects:
			EffectResolverScript.resolve(effect, combat, combat, combat)


func get_display_text() -> String:
	if relics.is_empty():
		return "Relics: none"
	var names: Array[String] = []
	for relic in relics:
		names.append(relic.get_display_name())
	return "Relics: %s" % ", ".join(names)
