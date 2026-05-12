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
	var name: String = String(data.display_name)
	var loc = _loc()
	if loc != null:
		name = loc.name_for(String(data.id), name)
	if upgraded:
		return "%s+" % name
	return name


func get_description() -> String:
	var description: String = String(data.get_description(upgraded))
	var loc = _loc()
	if loc != null:
		if loc.has_method("card_description_for"):
			return loc.card_description_for(String(data.id), description, upgraded)
		return loc.card_description(String(data.id), description)
	return description


func get_effects() -> Array[Dictionary]:
	return data.get_effects(upgraded)


func is_unplayable() -> bool:
	return data != null and data.is_unplayable()


func is_exhaust_on_play() -> bool:
	return data != null and bool(data.exhaust_on_play)


func is_ethereal() -> bool:
	return data != null and bool(data.ethereal)


func is_retain() -> bool:
	return data != null and bool(data.retain)


func is_innate() -> bool:
	return data != null and bool(data.innate)


func get_end_of_turn_effects() -> Array:
	if data == null:
		return []
	return data.end_of_turn_effects


func _loc():
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("/root/LocalizationManager")
