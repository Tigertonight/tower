class_name CharacterCatalog
extends RefCounted

# Loads all characters under res://data/characters/ and exposes a simple
# id → CharacterData lookup. RunManager calls `load_all()` once at startup.

const CharacterDataScript := preload("res://scripts/core/character_data.gd")
const ResourcePathUtilScript := preload("res://scripts/core/resource_path_util.gd")

const DEFAULT_ID := "char_vanguard"


static func load_all() -> Dictionary:
	var out := {}
	for path in ResourcePathUtilScript.data_resource_paths("res://data/characters"):
		var res = load(path)
		if res != null and String(res.id) != "":
			out[String(res.id)] = res
	return out


static func resolve(catalog: Dictionary, id: String):
	# Falls back to the default vanguard so a missing character_id (e.g. an
	# old save from before this system) never breaks a run.
	if catalog.has(id):
		return catalog[id]
	return catalog.get(DEFAULT_ID, null)
