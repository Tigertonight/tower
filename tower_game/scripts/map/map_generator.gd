class_name MapGenerator
extends RefCounted

const LAYER_RANGES := {
	0: Vector2i(1, 1),
	1: Vector2i(2, 3),
	2: Vector2i(3, 5),
	3: Vector2i(3, 5),
	4: Vector2i(3, 5),
	5: Vector2i(2, 4),
	6: Vector2i(3, 5),
	7: Vector2i(1, 1),
	8: Vector2i(1, 1)
}

static func generate(seed_value: int, act_index: int = 1) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + (act_index - 1) * 1009
	var layers: Array = []
	for layer_index in 9:
		var count: int = rng.randi_range(LAYER_RANGES[layer_index].x, LAYER_RANGES[layer_index].y)
		var layer_nodes: Array = []
		for node_index in count:
			var node_type := _roll_node_type(layer_index, rng)
			if layer_index == 0:
				node_type = "start"
			elif layer_index == 7:
				node_type = "campfire"
			elif layer_index == 8:
				node_type = "boss"
			var node := {
				"id": "L%d_%d" % [layer_index, node_index],
				"layer": layer_index,
				"column": node_index,
				"type": node_type,
				"title": _title_for_type(node_type),
				"subtitle": _subtitle_for_type(node_type),
				"encounter_id": "",
				"event_id": "",
				"visited": false,
				"edges_out": []
			}
			layer_nodes.append(node)
		layers.append(layer_nodes)
	_connect_layers(layers, rng)
	_assign_required_elite(layers)
	_repair_node_constraints(layers)
	_assign_encounters(layers, rng, act_index)
	return layers


static func available_from(layers: Array, current_node_id: String) -> Array[String]:
	if current_node_id == "":
		return ["L0_0"]
	var node := find_node(layers, current_node_id)
	if node.is_empty():
		return ["L0_0"]
	var ids: Array[String] = []
	for id in node.get("edges_out", []):
		ids.append(String(id))
	return ids


static func find_node(layers: Array, node_id: String) -> Dictionary:
	for layer in layers:
		for node in layer:
			if String(node.get("id", "")) == node_id:
				return node
	return {}


static func mark_visited(layers: Array, node_id: String) -> void:
	for layer_index in layers.size():
		for node_index in layers[layer_index].size():
			if String(layers[layer_index][node_index].get("id", "")) == node_id:
				layers[layer_index][node_index]["visited"] = true
				return


static func encode_node_states(layers: Array) -> Dictionary:
	var states := {}
	for layer in layers:
		for node in layer:
			if bool(node.get("visited", false)):
				states[String(node["id"])] = "visited"
	return states


static func apply_node_states(layers: Array, states: Dictionary) -> void:
	for node_id in states.keys():
		if String(states[node_id]) == "visited":
			mark_visited(layers, String(node_id))


static func _connect_layers(layers: Array, rng: RandomNumberGenerator) -> void:
	for layer_index in range(0, 8):
		var from_layer: Array = layers[layer_index]
		var to_layer: Array = layers[layer_index + 1]
		for from_index in from_layer.size():
			var target_index: int = clamp(from_index, 0, to_layer.size() - 1)
			_add_edge(from_layer, from_index, to_layer[target_index]["id"])
			if rng.randf() < 0.45 and target_index + 1 < to_layer.size():
				_add_edge(from_layer, from_index, to_layer[target_index + 1]["id"])
			if rng.randf() < 0.25 and target_index - 1 >= 0:
				_add_edge(from_layer, from_index, to_layer[target_index - 1]["id"])
		for to_index in to_layer.size():
			var target_id := String(to_layer[to_index]["id"])
			var has_parent := false
			for from_node in from_layer:
				if from_node["edges_out"].has(target_id):
					has_parent = true
					break
			if not has_parent:
				_add_edge(from_layer, min(to_index, from_layer.size() - 1), target_id)


static func _add_edge(layer: Array, from_index: int, target_id: String) -> void:
	if not layer[from_index]["edges_out"].has(target_id):
		layer[from_index]["edges_out"].append(target_id)


static func _roll_node_type(layer_index: int, rng: RandomNumberGenerator) -> String:
	var roll := rng.randi_range(1, 100)
	if layer_index <= 3:
		if roll <= 60:
			return "combat"
		if roll <= 82:
			return "event"
		if roll <= 90:
			return "shop"
		if roll <= 96:
			return "campfire"
		return "treasure"
	if roll <= 45:
		return "combat"
	if roll <= 67:
		return "event"
	if roll <= 79:
		return "shop"
	if roll <= 87:
		return "campfire"
	return "elite"


static func _assign_required_elite(layers: Array) -> void:
	for layer_index in [4, 6]:
		for node_index in layers[layer_index].size():
			if String(layers[layer_index][node_index]["type"]) == "elite":
				return
	layers[4][0]["type"] = "elite"
	layers[4][0]["title"] = _title_for_type("elite")
	layers[4][0]["subtitle"] = _subtitle_for_type("elite")


static func _repair_node_constraints(layers: Array) -> void:
	for layer_index in range(0, layers.size() - 1):
		for node_index in layers[layer_index].size():
			var node_type := String(layers[layer_index][node_index]["type"])
			for target_id in layers[layer_index][node_index]["edges_out"]:
				var target := find_node(layers, String(target_id))
				if target.is_empty():
					continue
				var target_type := String(target.get("type", ""))
				if node_type == "shop" and target_type == "shop":
					_retype_node(layers, String(target_id), "combat")
				elif node_type == "campfire" and target_type == "campfire":
					if layer_index == 7:
						continue
					_retype_node(layers, String(layers[layer_index][node_index]["id"]), "combat")
					node_type = "combat"


static func _retype_node(layers: Array, node_id: String, node_type: String) -> void:
	for layer_index in layers.size():
		for node_index in layers[layer_index].size():
			if String(layers[layer_index][node_index].get("id", "")) == node_id:
				if layer_index == 0 or layer_index == 7 or layer_index == 8:
					return
				layers[layer_index][node_index]["type"] = node_type
				layers[layer_index][node_index]["title"] = _title_for_type(node_type)
				layers[layer_index][node_index]["subtitle"] = _subtitle_for_type(node_type)
				return


static func _assign_encounters(layers: Array, rng: RandomNumberGenerator, act_index: int = 1) -> void:
	var early: Array
	var mid: Array
	var late: Array
	var elites: Array
	var boss: String
	# Multi-enemy "packs" use `+`-joined ids (parsed by combat_manager). Mixing
	# packs into the pool keeps single-enemy fights as the baseline while making
	# A1 demo runs feel less repetitive — the late-act pools get the heavier
	# packs to telegraph escalation.
	match act_index:
		2:
			early = ["e_glassed_intern", "e_late_filer", "e_glassed_intern+e_late_filer"]
			mid = ["e_silent_ledger", "e_dust_sentinel", "e_glassed_intern", "e_dust_sentinel+e_glassed_intern"]
			late = ["e_dust_sentinel", "e_red_string_imp", "e_silent_ledger", "e_silent_ledger+e_red_string_imp"]
			elites = ["el_quill_judge", "el_ironbound_clerk"]
			boss = "b_chronicler_of_lost_pages"
		3:
			early = ["e_late_filer", "e_silent_ledger", "e_late_filer+e_silent_ledger"]
			mid = ["e_dust_sentinel", "e_red_string_imp", "e_burnt_courier", "e_red_string_imp+e_burnt_courier"]
			late = ["e_red_string_imp", "e_burnt_courier", "e_dust_sentinel", "e_dust_sentinel+e_burnt_courier+e_red_string_imp"]
			elites = ["el_archive_warden", "el_ironbound_clerk"]
			boss = "b_grand_archivist"
		_:
			early = ["e_dust_scribe", "e_loose_folio", "e_dust_scribe+e_loose_folio"]
			mid = ["e_loose_folio", "e_wax_acolyte", "e_margin_hound", "e_loose_folio+e_dust_scribe"]
			late = ["e_wax_acolyte", "e_margin_hound", "e_burnt_courier", "e_wax_acolyte+e_margin_hound"]
			elites = ["el_wax_sentinel", "el_first_clause"]
			boss = "b_sealed_curator"
	for layer_index in layers.size():
		for node_index in layers[layer_index].size():
			var node_type := String(layers[layer_index][node_index]["type"])
			match node_type:
				"combat":
					var pool := early
					if layer_index >= 4 and layer_index <= 5:
						pool = mid
					elif layer_index >= 6:
						pool = late
					layers[layer_index][node_index]["encounter_id"] = pool[rng.randi_range(0, pool.size() - 1)]
				"elite":
					layers[layer_index][node_index]["encounter_id"] = elites[rng.randi_range(0, elites.size() - 1)]
				"boss":
					layers[layer_index][node_index]["encounter_id"] = boss


static func _title_for_type(node_type: String) -> String:
	match node_type:
		"start":
			return "Outer Gate"
		"combat":
			return "Archive Fight"
		"elite":
			return "Elite Seal"
		"event":
			return "Archive Event"
		"shop":
			return "Quiet Vendor"
		"campfire":
			return "Waxlight Nook"
		"treasure":
			return "Locked Drawer"
		"boss":
			return "Sealed Curator"
		_:
			return "Node"


static func _subtitle_for_type(node_type: String) -> String:
	match node_type:
		"start":
			return "The archive opens."
		"combat":
			return "A hostile record blocks the way."
		"elite":
			return "A sealed enforcer waits."
		"event":
			return "A clause offers a bargain."
		"shop":
			return "Spend gold for consistency."
		"campfire":
			return "Rest or sharpen a card."
		"treasure":
			return "Claim a stored object."
		"boss":
			return "Recover the archive key."
		_:
			return ""
