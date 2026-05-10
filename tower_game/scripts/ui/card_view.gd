class_name CardView
extends Button

signal card_selected(card)

const CARD_SIZE := Vector2(100, 112)

var card
var rest_position := Vector2.ZERO
var cost_label: Label
var rarity_label: Label
var name_label: Label
var art_panel: PanelContainer
var type_label: Label
var rules_label: Label
var glow_panel: Panel


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	text = ""
	clip_text = true
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_build_card_body()


func setup(card_instance, available_energy: int, disabled_by_state: bool) -> void:
	card = card_instance
	rest_position = position
	custom_minimum_size = CARD_SIZE
	_build_card_body()
	_add_card_styles()
	_update_text()
	disabled = disabled_by_state or card.get_cost() > available_energy
	tooltip_text = "%s\n\n%s" % [card.get_display_name(), card.get_description()]
	modulate = Color(0.58, 0.58, 0.58) if disabled else Color.WHITE


func refresh(available_energy: int, disabled_by_state: bool) -> void:
	if card == null:
		return
	_update_text()
	disabled = disabled_by_state or card.get_cost() > available_energy
	modulate = Color(0.58, 0.58, 0.58) if disabled else Color.WHITE


func _build_card_body() -> void:
	if cost_label != null:
		return

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	glow_panel = Panel.new()
	glow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow_panel.offset_left = 4
	glow_panel.offset_top = 4
	glow_panel.offset_right = -4
	glow_panel.offset_bottom = -4
	root.add_child(glow_panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 7
	box.offset_top = 6
	box.offset_right = -7
	box.offset_bottom = -6
	box.add_theme_constant_override("separation", 1)
	root.add_child(box)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.custom_minimum_size = Vector2(0, 22)
	header.add_theme_constant_override("separation", 4)
	box.add_child(header)

	cost_label = Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.custom_minimum_size = Vector2(24, 22)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 16)
	header.add_child(cost_label)

	rarity_label = Label.new()
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 10)
	header.add_child(rarity_label)

	name_label = Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.custom_minimum_size = Vector2(0, 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 13)
	box.add_child(name_label)

	art_panel = PanelContainer.new()
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_panel.custom_minimum_size = Vector2(0, 18)
	box.add_child(art_panel)
	var art_label := Label.new()
	art_label.name = "ArtGlyph"
	art_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_label.add_theme_font_size_override("font_size", 16)
	art_panel.add_child(art_label)

	type_label = Label.new()
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.custom_minimum_size = Vector2(0, 15)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 10)
	box.add_child(type_label)

	rules_label = Label.new()
	rules_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rules_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rules_label.add_theme_font_size_override("font_size", 8)
	box.add_child(rules_label)


func _update_text() -> void:
	if card == null:
		return
	var rarity := String(card.data.rarity).to_upper()
	var card_type := String(card.data.card_type).to_upper()
	cost_label.text = str(card.get_cost())
	rarity_label.text = rarity
	name_label.text = card.get_display_name()
	type_label.text = card_type
	rules_label.text = card.get_description()
	var art_label := art_panel.get_node_or_null("ArtGlyph") as Label
	if art_label != null:
		art_label.text = _type_glyph(String(card.data.card_type))


func _on_pressed() -> void:
	if card != null:
		card_selected.emit(card)


func _on_mouse_entered() -> void:
	if disabled:
		return
	rest_position = position
	z_index = 40
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.18, 1.18), 0.09)
	tween.parallel().tween_property(self, "position", rest_position + Vector2(0, -34), 0.09)


func _on_mouse_exited() -> void:
	z_index = 0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.09)
	tween.parallel().tween_property(self, "position", rest_position, 0.09)


func _add_card_styles() -> void:
	var palette := _palette_for_card()
	add_theme_stylebox_override("normal", _card_box(palette["bg"], palette["border"], 2))
	add_theme_stylebox_override("hover", _card_box(palette["bg"].lightened(0.08), palette["border"].lightened(0.18), 3))
	add_theme_stylebox_override("pressed", _card_box(palette["bg"].lightened(0.14), palette["border"].lightened(0.25), 3))
	add_theme_stylebox_override("disabled", _card_box(Color(0.11, 0.11, 0.11), Color(0.27, 0.25, 0.22), 1))
	cost_label.add_theme_stylebox_override("normal", _round_box(Color(0.07, 0.11, 0.14), palette["border"], 2, 14))
	name_label.add_theme_stylebox_override("normal", _strip_box(palette["strip"], palette["border"].darkened(0.15)))
	type_label.add_theme_stylebox_override("normal", _strip_box(palette["type_bg"], palette["border"].darkened(0.1)))
	rules_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74))
	rarity_label.add_theme_color_override("font_color", Color(0.78, 0.69, 0.53))
	art_panel.add_theme_stylebox_override("normal", _art_box(palette["art"]))
	glow_panel.add_theme_stylebox_override("panel", _glow_box(palette["glow"]))


func _palette_for_card() -> Dictionary:
	var card_type := ""
	if card != null:
		card_type = String(card.data.card_type)
	match card_type:
		"attack":
			return {
				"bg": Color(0.22, 0.085, 0.055),
				"strip": Color(0.34, 0.12, 0.08),
				"type_bg": Color(0.42, 0.16, 0.10),
				"art": Color(0.18, 0.10, 0.08),
				"border": Color(0.90, 0.37, 0.20),
				"glow": Color(0.85, 0.25, 0.10, 0.14)
			}
		"skill":
			return {
				"bg": Color(0.055, 0.13, 0.20),
				"strip": Color(0.075, 0.19, 0.30),
				"type_bg": Color(0.08, 0.25, 0.38),
				"art": Color(0.055, 0.13, 0.18),
				"border": Color(0.36, 0.68, 1.00),
				"glow": Color(0.18, 0.55, 1.00, 0.14)
			}
		"power":
			return {
				"bg": Color(0.16, 0.08, 0.22),
				"strip": Color(0.24, 0.11, 0.32),
				"type_bg": Color(0.30, 0.15, 0.40),
				"art": Color(0.13, 0.08, 0.17),
				"border": Color(0.75, 0.48, 0.95),
				"glow": Color(0.65, 0.30, 1.00, 0.14)
			}
		_:
			return {
				"bg": Color(0.18, 0.15, 0.10),
				"strip": Color(0.25, 0.20, 0.13),
				"type_bg": Color(0.28, 0.22, 0.14),
				"art": Color(0.14, 0.12, 0.09),
				"border": Color(0.74, 0.56, 0.27),
				"glow": Color(0.80, 0.55, 0.20, 0.12)
			}


func _type_glyph(card_type: String) -> String:
	match card_type:
		"attack":
			return "BLADE"
		"skill":
			return "WARD"
		"power":
			return "OATH"
		_:
			return "PAGE"


func _card_box(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _strip_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _round_box(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _art_box(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color(0.02, 0.02, 0.018, 0.90)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style


func _glow_box(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(color.r, color.g, color.b, 0.22)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	return style
