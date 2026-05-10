class_name RouteMapView
extends Control

signal node_selected(row_index: int, node_index: int)

var map_nodes: Array = []
var current_layer := 0
var node_positions: Array = []
var buttons: Array[Button] = []
var preview_label: Label


func setup(nodes: Array, layer: int) -> void:
	map_nodes = nodes
	current_layer = layer
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	buttons.clear()
	node_positions.clear()

	preview_label = Label.new()
	preview_label.position = Vector2(18, 16)
	preview_label.custom_minimum_size = Vector2(260, 54)
	preview_label.text = "Select a glowing route node."
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.add_theme_font_size_override("font_size", 15)
	preview_label.add_theme_stylebox_override("normal", _preview_box())
	add_child(preview_label)

	var layer_count: int = map_nodes.size()
	var width: float = max(460.0, size.x)
	var bottom: float = 250.0
	var row_gap: float = 50.0
	for row_index in layer_count:
		var row_nodes: Array = map_nodes[row_index]
		var row_positions: Array[Vector2] = []
		var total_width: float = float(row_nodes.size() - 1) * 124.0
		var start_x: float = (width - total_width) * 0.5
		var y: float = bottom - row_index * row_gap
		for node_index in row_nodes.size():
			var x: float = start_x + node_index * 124.0
			row_positions.append(Vector2(x, y))
			_add_node_button(row_index, node_index, row_nodes[node_index], Vector2(x, y))
		node_positions.append(row_positions)
	queue_redraw()


func _add_node_button(row_index: int, node_index: int, node: Dictionary, position_value: Vector2) -> void:
	var button := Button.new()
	button.position = position_value - Vector2(42, 25)
	button.custom_minimum_size = Vector2(84, 50)
	var state := "GO" if row_index == current_layer else ("DONE" if row_index < current_layer else "LOCK")
	button.text = "%s\n%s" % [_node_icon(String(node.type)), state]
	button.tooltip_text = "%s: %s" % [node.title, node.subtitle]
	button.disabled = row_index != current_layer
	button.add_theme_font_size_override("font_size", 13)
	if row_index == current_layer:
		button.add_theme_stylebox_override("normal", _node_box(Color(0.23, 0.16, 0.08), Color(1.0, 0.72, 0.22), 2))
		button.add_theme_stylebox_override("hover", _node_box(Color(0.31, 0.21, 0.09), Color(1.0, 0.86, 0.34), 3))
	elif row_index < current_layer:
		button.add_theme_stylebox_override("disabled", _node_box(Color(0.12, 0.18, 0.13), Color(0.38, 0.62, 0.38), 1))
	else:
		button.add_theme_stylebox_override("disabled", _node_box(Color(0.13, 0.13, 0.13), Color(0.32, 0.29, 0.24), 1))
	button.pressed.connect(func() -> void: node_selected.emit(row_index, node_index))
	button.mouse_entered.connect(func() -> void: _show_preview(node, row_index))
	button.mouse_exited.connect(func() -> void: _clear_preview())
	add_child(button)
	buttons.append(button)


func _draw() -> void:
	for row_index in max(0, node_positions.size() - 1):
		var from_row: Array = node_positions[row_index]
		var to_row: Array = node_positions[row_index + 1]
		for from_index in from_row.size():
			var from_pos: Vector2 = from_row[from_index]
			for to_index in to_row.size():
				if abs(from_index - to_index) > 1:
					continue
				var to_pos: Vector2 = to_row[to_index]
				var color := Color(0.45, 0.35, 0.18, 0.45)
				if row_index < current_layer:
					color = Color(0.55, 0.75, 0.45, 0.60)
				draw_line(from_pos - Vector2(0, 26), to_pos + Vector2(0, 26), color, 2.0)


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


func _short_name(value: String) -> String:
	if value.length() <= 13:
		return value
	return value.substr(0, 12)


func _show_preview(node: Dictionary, row_index: int) -> void:
	if preview_label == null:
		return
	var prefix := "Available" if row_index == current_layer else ("Cleared" if row_index < current_layer else "Locked")
	preview_label.text = "%s: %s\n%s" % [prefix, String(node.title), String(node.subtitle)]


func _clear_preview() -> void:
	if preview_label == null:
		return
	preview_label.text = "Select a glowing route node."


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
