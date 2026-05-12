class_name CardData
extends Resource

# card_type values: "attack", "skill", "power", "curse", "status"
# rarity values: "basic", "common", "uncommon", "rare", "special"
# exhaust_on_play : true → card moves to exhaust pile after play
# ethereal        : true → if still in hand at end of player turn, exhaust it
# unplayable      : true → cannot be played (curse / status)
# end_of_turn_effects : effects fired when the card is in hand at end of turn
#                       (used by curses/statuses like "lose 1 HP each turn").
# innate          : true → drawn first turn alongside opener hand
# retain          : true → does not discard at end of turn

@export var id: String = ""
@export var display_name: String = ""
@export var card_type: String = "attack"
@export var rarity: String = "common"
@export var cost: int = 1
@export var description: String = ""
@export var upgraded_description: String = ""
@export var effects: Array[Dictionary] = []
@export var upgraded_effects: Array[Dictionary] = []
@export var exhaust_on_play: bool = false
@export var ethereal: bool = false
@export var unplayable: bool = false
@export var innate: bool = false
@export var retain: bool = false
@export var end_of_turn_effects: Array[Dictionary] = []
@export var card_target: String = "enemy"  # "enemy" / "self" / "all_enemies" / "none"


func get_description(upgraded: bool = false) -> String:
	if upgraded and upgraded_description != "":
		return upgraded_description
	return description


func get_effects(upgraded: bool = false) -> Array[Dictionary]:
	if upgraded and not upgraded_effects.is_empty():
		return upgraded_effects
	return effects


func is_unplayable() -> bool:
	return unplayable or card_type == "curse" or card_type == "status"
