class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var tier: String = "normal"
@export var max_hp: int = 24
@export var spawn_block: int = 0
@export var art_path: String = ""
@export var move_pool: Array[Dictionary] = []
@export var opener_move_ids: Array[String] = []
@export var phase_hp_below_pct: float = 0.0
@export var phase_enter_effects: Array[Dictionary] = []
@export var phase_move_pool: Array[Dictionary] = []
