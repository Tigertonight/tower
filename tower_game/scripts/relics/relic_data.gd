class_name RelicData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var rarity: String = "common"
@export var description: String = ""
@export var pool_id: String = "public"
@export var character_id: String = ""
@export var archetype_tags: Array = []
@export var trigger: String = ""
@export var effects: Array[Dictionary] = []
# Optional dispatch filters / counters consumed by RelicManager.trigger().
# Recognised keys:
#   "card_type_filter": String   # "attack" | "skill" | "power" — only fire when context.card_type matches.
#   "every_n":          int      # Only fire on every Nth qualifying event (uses RelicInstance.counter).
#   "hp_below_pct":     float    # For hp_threshold — fires once player_hp / max_hp drops below this fraction.
#   "once_per_combat":  bool     # If true, fires at most once between combat_start resets.
@export var trigger_params: Dictionary = {}
