class_name PotionCatalog
extends RefCounted

const ResourcePathUtilScript := preload("res://scripts/core/resource_path_util.gd")

static func load_potions() -> Dictionary:
	var potions := {}
	for path in ResourcePathUtilScript.data_resource_paths("res://data/potions"):
		var potion = load(path)
		if potion != null:
			potions[potion.id] = potion
	return potions
