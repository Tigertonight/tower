class_name CardInstance
extends RefCounted

var data
var upgraded := false
var cost_for_turn := -1


func _init(card_data = null, is_upgraded: bool = false) -> void:
	if card_data != null:
		setup(card_data, is_upgraded)


func setup(card_data, is_upgraded: bool = false) -> void:
	data = card_data
	upgraded = is_upgraded


func get_cost() -> int:
	if cost_for_turn >= 0:
		return cost_for_turn
	return data.cost


func get_display_name() -> String:
	if upgraded:
		return "%s+" % data.display_name
	return data.display_name


func get_description() -> String:
	return data.get_description(upgraded)


func get_effects() -> Array[Dictionary]:
	return data.get_effects(upgraded)
