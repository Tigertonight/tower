class_name CharacterData
extends Resource

# A playable character archetype: starter deck, starting relic, theme color,
# and a few small stat overrides so each character feels distinct from the
# first turn. RunManager looks up CharacterCatalog.get(selected_character_id)
# at run-start to seed the run.
#
# Design notes:
#   • Vanguard is the bash-and-block default (mirrors the Ironclad in StS
#     terms — high HP, low draw, attacks scale with Strength).
#   • Archivist is a status/knowledge build (mirrors something like the
#     Silent — slightly lower HP, but more draw and Vulnerable/Weak
#     application from cheap skills).
@export var id: String = ""
@export var display_name: String = ""
@export var subtitle: String = ""
@export var theme_color: Color = Color(0.85, 0.66, 0.36)
@export var starting_hp: int = 76
@export var starting_relic_id: String = "sealed_badge"
# Plain Array because Godot's typed-resource exports save fine but Array[String]
# in .tres can be finicky for short lists; we coerce in the loader.
@export var starter_deck: Array = []
@export var sprite_path: String = ""
