extends SceneTree

const MapGeneratorScript := preload("res://scripts/map/map_generator.gd")
const EnemyCatalogScript := preload("res://scripts/combat/enemy_catalog.gd")
const PotionCatalogScript := preload("res://scripts/potions/potion_catalog.gd")
const ResourcePathUtilScript := preload("res://scripts/core/resource_path_util.gd")

const DATA_DIRS := [
	"res://data/cards",
	"res://data/relics",
	"res://data/potions",
	"res://data/enemies"
]


func _init() -> void:
	var failed := false
	failed = _check_all_data_resources() or failed
	failed = _check_enemy_move_links() or failed
	failed = _check_content_counts() or failed
	failed = _check_maps() or failed
	if failed:
		print("MVP runtime check failed.")
		quit(1)
	else:
		print("MVP runtime check passed.")
		quit(0)


func _check_all_data_resources() -> bool:
	var failed := false
	for dir_path in DATA_DIRS:
		var paths := ResourcePathUtilScript.data_resource_paths(dir_path)
		if paths.is_empty():
			push_error("Failed to open data dir: %s" % dir_path)
			failed = true
			continue
		for path in paths:
			var resource = load(path)
			if resource == null:
				push_error("Failed to load resource: %s" % path)
				failed = true
	return failed


func _check_enemy_move_links() -> bool:
	var failed := false
	var enemies := EnemyCatalogScript.load_enemies()
	var moves := EnemyCatalogScript.build_moves()
	for enemy_id in enemies.keys():
		var enemy = enemies[enemy_id]
		for entry in enemy.move_pool:
			var move_id := String(entry.get("move_id", ""))
			if not moves.has(move_id):
				push_error("Enemy %s references missing move %s" % [enemy_id, move_id])
				failed = true
		for move_id in enemy.opener_move_ids:
			if not moves.has(move_id):
				push_error("Enemy %s references missing opener %s" % [enemy_id, move_id])
				failed = true
		for entry in enemy.phase_move_pool:
			var move_id := String(entry.get("move_id", ""))
			if not moves.has(move_id):
				push_error("Enemy %s references missing phase move %s" % [enemy_id, move_id])
				failed = true
	return failed


func _check_content_counts() -> bool:
	var cards := _count_tres("res://data/cards")
	var relics := _count_tres("res://data/relics")
	var potions := _count_tres("res://data/potions")
	var enemies := _count_tres("res://data/enemies")
	var failed := false
	if cards < 30:
		push_error("Expected at least 30 cards, found %d." % cards)
		failed = true
	if relics < 10:
		push_error("Expected at least 10 relics, found %d." % relics)
		failed = true
	if potions < 5:
		push_error("Expected at least 5 potions, found %d." % potions)
		failed = true
	if enemies < 8:
		push_error("Expected at least 8 enemies, found %d." % enemies)
		failed = true
	return failed


func _count_tres(dir_path: String) -> int:
	return ResourcePathUtilScript.data_resource_paths(dir_path).size()


func _check_maps() -> bool:
	var failed := false
	for seed_value in [1, 2, 3, 42, 99, 999, 20260511]:
		var layers := MapGeneratorScript.generate(seed_value)
		failed = _check_map(seed_value, layers) or failed
	return failed


func _check_map(seed_value: int, layers: Array) -> bool:
	var failed := false
	if layers.size() != 9:
		push_error("Seed %d: expected 9 layers, got %d." % [seed_value, layers.size()])
		return true
	if String(layers[0][0].get("type", "")) != "start":
		push_error("Seed %d: layer 0 is not start." % seed_value)
		failed = true
	if String(layers[7][0].get("type", "")) != "campfire":
		push_error("Seed %d: layer 7 is not campfire." % seed_value)
		failed = true
	if String(layers[8][0].get("type", "")) != "boss":
		push_error("Seed %d: layer 8 is not boss." % seed_value)
		failed = true
	if _count_type(layers, "elite") < 1:
		push_error("Seed %d: no elite node." % seed_value)
		failed = true
	if not _can_reach(layers, "L0_0", "L8_0"):
		push_error("Seed %d: start cannot reach boss." % seed_value)
		failed = true
	for layer_index in range(0, layers.size() - 1):
		for node in layers[layer_index]:
			var edges: Array = node.get("edges_out", [])
			if edges.is_empty():
				push_error("Seed %d: node %s has no outgoing edge." % [seed_value, node.get("id", "")])
				failed = true
			for target_id in edges:
				var target := MapGeneratorScript.find_node(layers, String(target_id))
				if target.is_empty():
					push_error("Seed %d: missing edge target %s." % [seed_value, target_id])
					failed = true
				if String(node.get("type", "")) == "shop" and String(target.get("type", "")) == "shop":
					push_error("Seed %d: shop to shop edge %s -> %s." % [seed_value, node.get("id", ""), target_id])
					failed = true
				if String(node.get("type", "")) == "campfire" and String(target.get("type", "")) == "campfire":
					push_error("Seed %d: campfire to campfire edge %s -> %s." % [seed_value, node.get("id", ""), target_id])
					failed = true
	return failed


func _count_type(layers: Array, node_type: String) -> int:
	var count := 0
	for layer in layers:
		for node in layer:
			if String(node.get("type", "")) == node_type:
				count += 1
	return count


func _can_reach(layers: Array, start_id: String, goal_id: String) -> bool:
	var frontier := [start_id]
	var seen := {}
	while not frontier.is_empty():
		var node_id := String(frontier.pop_back())
		if node_id == goal_id:
			return true
		if seen.has(node_id):
			continue
		seen[node_id] = true
		var node := MapGeneratorScript.find_node(layers, node_id)
		for target_id in node.get("edges_out", []):
			frontier.append(String(target_id))
	return false
