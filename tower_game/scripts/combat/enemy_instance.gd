class_name EnemyInstance
extends RefCounted

var display_name := "Animated Scribe"
var max_hp := 42
var hp := 42
var block := 0
var statuses: Dictionary = {}
var intent_type := "attack"
var intent_damage := 6
var intent_block := 0


func is_dead() -> bool:
	return hp <= 0


func choose_intent(turn_number: int) -> void:
	intent_block = 0
	if turn_number % 4 == 0:
		intent_type = "defend"
		intent_damage = 0
		intent_block = 9
	elif turn_number % 3 == 0:
		intent_type = "heavy_attack"
		intent_damage = 10
	else:
		intent_type = "attack"
		intent_damage = 6


func get_intent_text() -> String:
	match intent_type:
		"defend":
			return "Intent: Gain %d block" % intent_block
		"heavy_attack":
			return "Intent: Heavy attack %d" % intent_damage
		_:
			return "Intent: Attack %d" % intent_damage


func get_status_text() -> String:
	var parts: Array[String] = []
	for key in statuses.keys():
		var value := int(statuses[key])
		if value > 0:
			parts.append("%s:%d" % [key, value])
	return " ".join(parts)
