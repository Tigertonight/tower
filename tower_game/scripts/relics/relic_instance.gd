class_name RelicInstance
extends RefCounted

var data
# Generic counter used by every_n / once_per_combat / hp_threshold latches.
# RelicManager owns the semantics; the instance just provides the storage.
var counter := 0
var fired_this_combat := false


func setup(relic_data) -> void:
	data = relic_data


func reset_combat_state() -> void:
	# Called on combat_start so once_per_combat / every_n latches reset.
	counter = 0
	fired_this_combat = false


func get_display_name() -> String:
	return data.display_name


func get_description() -> String:
	return data.description
