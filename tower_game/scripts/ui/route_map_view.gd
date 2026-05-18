class_name RouteMapView
extends Control

signal node_selected(row_index: int, node_index: int)
var map_nodes: Array = []
var current_layer := 0
var available_node_ids: Array[String] = []
var node_positions: Array = []
var buttons: Array[Button] = []
var preview_label: Label
var deck_summary_text := "Deck"
var _rebuild_queued := false


func _loc():
	return get_node_or_null("/root/LocalizationManager")


func _tr(key: String, fallback: String = "") -> String:
	var loc = _loc()
	if loc != null:
		return loc.t(key, fallback)
	return fallback if fallback != "" else key


func setup(nodes: Array, layer: int, available_ids: Array[String] = []) -> void:
	map_nodes = nodes
	current_layer = layer
	available_node_ids = available_ids.duplicate()
	_queue_rebuild()


func set_deck_summary(summary_text: String) -> void:
	deck_summary_text = summary_text


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not map_nodes.is_empty():
		_queue_rebuild()


func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _rebuild() -> void:
	_rebuild_queued = false
	for child in get_children():
		child.queue_free()
	buttons.clear()
	node_positions.clear()

	preview_label = Label.new()
	preview_label.position = Vector2(22, 18)
	preview_label.custom_minimum_size = Vector2(360, 44)
	preview_label.text = _tr("route.select", "Select a lit route node.")
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.add_theme_font_size_override("font_size", 14)
	preview_label.add_theme_stylebox_override("normal", _preview_box())
	add_child(preview_label)

	var layer_count: int = map_nodes.size()
	var width: float = _map_width()
	var height: float = _map_height()
	var left: float = 76.0
	var right: float = max(left + 160.0, width - 76.0)
	var top: float = 104.0
	var bottom: float = max(top + 140.0, height - 78.0)
	var layer_gap: float = 122.0
	if layer_count > 1:
		layer_gap = max(96.0, (right - left) / float(layer_count - 1))
	for row_index in range(layer_count):
		var row_nodes: Array = map_nodes[row_index]
		var row_positions: Array[Vector2] = []
		var row_center_y := (top + bottom) * 0.5
		var node_gap := 94.0
		if row_nodes.size() > 1:
			node_gap = min(112.0, max(78.0, (bottom - top) / float(row_nodes.size() - 1)))
		var start_y := row_center_y - node_gap * float(row_nodes.size() - 1) * 0.5
		var x: float = left + float(row_index) * layer_gap
		for node_index in range(row_nodes.size()):
			var y: float = start_y + float(node_index) * node_gap
			row_positions.append(Vector2(x, y))
			_add_node_button(row_index, node_index, row_nodes[node_index], Vector2(x, y))
		node_positions.append(row_positions)
	queue_redraw()


func _map_width() -> float:
	if size.x > 1.0:
		return size.x
	if get_parent() is Control:
		return max(760.0, (get_parent() as Control).size.x)
	return 1040.0


func _map_height() -> float:
	if size.y > 1.0:
		return size.y
	if get_parent() is Control:
		return max(440.0, (get_parent() as Control).size.y)
	return 500.0


func _add_node_button(row_index: int, node_index: int, node: Dictionary, position_value: Vector2) -> void:
	var button := Button.new()
	button.position = position_value - Vector2(34, 30)
	button.custom_minimum_size = Vector2(68, 60)
	var node_id := String(node.get("id", ""))
	var is_available := available_node_ids.has(node_id)
	var is_visited := bool(node.get("visited", false))
	button.text = ""
	var state_text := _state_text(is_available, is_visited)
	button.tooltip_text = "%s - %s: %s" % [state_text, _node_title(node), _node_subtitle(node)]
	button.disabled = not is_available
	if is_available:
		button.add_theme_stylebox_override("normal", _node_box(Color(0.24, 0.16, 0.07, 0.94), Color(1.0, 0.73, 0.20), 2))
		button.add_theme_stylebox_override("hover", _node_box(Color(0.33, 0.22, 0.08, 0.96), Color(1.0, 0.88, 0.36), 3))
		button.add_theme_stylebox_override("pressed", _node_box(Color(0.40, 0.27, 0.10, 0.98), Color(1.0, 0.90, 0.42), 3))
	elif is_visited:
		button.add_theme_stylebox_override("disabled", _node_box(Color(0.10, 0.16, 0.11, 0.88), Color(0.36, 0.66, 0.38), 1))
	else:
		button.add_theme_stylebox_override("disabled", _node_box(Color(0.13, 0.12, 0.10, 0.84), Color(0.42, 0.34, 0.23, 0.72), 1))
	button.pressed.connect(func() -> void: node_selected.emit(row_index, node_index))
	button.mouse_entered.connect(func() -> void: _show_preview(node, row_index))
	button.mouse_exited.connect(func() -> void: _clear_preview())
	add_child(button)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _load_node_icon_texture(String(node.type))
	icon.ignore_texture_size = true
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 13
	icon.offset_top = 8
	icon.offset_right = -13
	icon.offset_bottom = -12
	if not is_available and not is_visited:
		icon.modulate = Color(0.62, 0.56, 0.46, 0.72)
	elif is_visited:
		icon.modulate = Color(0.68, 0.92, 0.62, 0.96)
	elif is_available:
		icon.modulate = Color(1.18, 1.02, 0.72, 1.0)
	button.add_child(icon)

	var status_dot := Panel.new()
	status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_dot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	status_dot.offset_left = -20
	status_dot.offset_top = -20
	status_dot.offset_right = -8
	status_dot.offset_bottom = -8
	if is_available:
		status_dot.add_theme_stylebox_override("panel", _dot_box(Color(1.0, 0.75, 0.22), Color(1.0, 0.94, 0.54)))
	elif is_visited:
		status_dot.add_theme_stylebox_override("panel", _dot_box(Color(0.32, 0.74, 0.36), Color(0.64, 0.95, 0.62)))
	else:
		status_dot.add_theme_stylebox_override("panel", _dot_box(Color(0.30, 0.24, 0.16, 0.88), Color(0.55, 0.43, 0.26, 0.90)))
	button.add_child(status_dot)
	buttons.append(button)


func _draw() -> void:
	for row_index in range(max(0, node_positions.size() - 1)):
		var from_row: Array = node_positions[row_index]
		var to_row: Array = node_positions[row_index + 1]
		for from_index in from_row.size():
			var from_pos: Vector2 = from_row[from_index]
			for to_index in to_row.size():
				var to_id := String(map_nodes[row_index + 1][to_index].get("id", ""))
				if not map_nodes[row_index][from_index].get("edges_out", []).has(to_id):
					continue
				var to_pos: Vector2 = to_row[to_index]
				var color := Color(0.50, 0.40, 0.24, 0.36)
				if bool(map_nodes[row_index][from_index].get("visited", false)):
					color = Color(0.60, 0.78, 0.44, 0.56)
				draw_line(from_pos + Vector2(34, 0), to_pos - Vector2(34, 0), color, 2.0)


func _node_icon(node_type: String) -> String:
	match node_type:
		"combat":
			return "ATK"
		"elite":
			return "ELT"
		"event":
			return "?"
		"shop":
			return "$"
		"campfire":
			return "REST"
		"boss":
			return "BOSS"
		_:
			return "NODE"


func _load_node_icon_texture(node_type: String) -> Texture2D:
	var icon_id := node_type
	if node_type == "campfire":
		icon_id = "campfire"
	elif node_type == "start":
		icon_id = "boss"
	elif node_type == "treasure":
		icon_id = "event"
	var path := "res://art/generated/icons/node_%s.png" % icon_id
	if ResourceLoader.exists(path):
		var imported = load(path)
		if imported is Texture2D:
			return imported
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Failed to load route node icon: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _short_name(value: String) -> String:
	if value.length() <= 13:
		return value
	return value.substr(0, 12)


func _show_preview(node: Dictionary, row_index: int) -> void:
	if preview_label == null:
		return
	var node_id := String(node.get("id", ""))
	var is_available := available_node_ids.has(node_id)
	var is_visited := bool(node.get("visited", false)) or row_index < current_layer
	preview_label.text = "%s: %s\n%s" % [_state_text(is_available, is_visited), _node_title(node), _node_subtitle(node)]


func _clear_preview() -> void:
	if preview_label == null:
		return
	preview_label.text = _tr("route.select", "Select a lit route node.")


func _state_text(is_available: bool, is_visited: bool) -> String:
	if is_available:
		return _tr("map.state.available", "Available")
	if is_visited:
		return _tr("map.state.cleared", "Cleared")
	return _tr("map.state.locked", "Locked")


func _node_title(node: Dictionary) -> String:
	var node_type := String(node.get("type", "node"))
	return _tr("map.node.%s.title" % node_type, String(node.get("title", "")))


func _node_subtitle(node: Dictionary) -> String:
	var node_type := String(node.get("type", "node"))
	return _tr("map.node.%s.subtitle" % node_type, String(node.get("subtitle", "")))


func _node_box(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _dot_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _capsule_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _preview_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.072, 0.078, 0.86)
	style.border_color = Color(0.42, 0.32, 0.18, 0.84)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
