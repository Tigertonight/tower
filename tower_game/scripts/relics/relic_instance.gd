class_name RelicInstance
extends RefCounted

var data
var counter := 0


func setup(relic_data) -> void:
	data = relic_data


func get_display_name() -> String:
	return data.display_name


func get_description() -> String:
	return data.description
