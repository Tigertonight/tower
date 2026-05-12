class_name CharacterCatalog
extends RefCounted

# Loads all characters under res://data/characters/ and exposes a simple
# id → CharacterData lookup. RunManager calls `load_all()` once at startup.

const CharacterDataScript := preload("res://scripts/core/character_data.gd")

const DEFAULT_ID := "char_vanguard"


static func load_all() -> Dictionary:
	var out := {}
	var dir := DirAccess.open("res://data/characters")
	if dir == null:
		return out
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := "res://data/characters/%s" % file_name
			var res = load(path)
			if res != null and String(res.id) != "":
				out[String(res.id)] = res
		file_name = dir.get_next()
	dir.list_dir_end()
	return out


static func resolve(catalog: Dictionary, id: String):
	# Falls back to the default vanguard so a missing character_id (e.g. an
	# old save from before this system) never breaks a run.
	if catalog.has(id):
		return catalog[id]
	return catalog.get(DEFAULT_ID, null)
