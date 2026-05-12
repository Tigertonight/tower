class_name PotionCatalog
extends RefCounted

static func load_potions() -> Dictionary:
	var potions := {}
	var dir := DirAccess.open("res://data/potions")
	if dir == null:
		return potions
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var potion = load("res://data/potions/%s" % file_name)
			if potion != null:
				potions[potion.id] = potion
		file_name = dir.get_next()
	dir.list_dir_end()
	return potions
