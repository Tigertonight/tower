class_name EnemyMoveData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var intent_type: String = "attack"
@export var damage: int = 0
@export var multi_hit_count: int = 1
@export var block: int = 0
@export var status_applied: Array[Dictionary] = []
@export var self_effects: Array[Dictionary] = []
@export var add_card_to_discard: String = ""
