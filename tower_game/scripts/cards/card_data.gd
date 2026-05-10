class_name CardData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var card_type: String = "attack"
@export var rarity: String = "common"
@export var cost: int = 1
@export var description: String = ""
@export var upgraded_description: String = ""
@export var effects: Array[Dictionary] = []
@export var upgraded_effects: Array[Dictionary] = []


func get_description(upgraded: bool = false) -> String:
	if upgraded and upgraded_description != "":
		return upgraded_description
	return description


func get_effects(upgraded: bool = false) -> Array[Dictionary]:
	if upgraded and not upgraded_effects.is_empty():
		return upgraded_effects
	return effects
