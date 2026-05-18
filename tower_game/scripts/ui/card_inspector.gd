class_name CardInspector
extends Control

# Big-card preview overlay. Positioned above a hovered CardView.
# Reused by hand hover, shop, deck modal, reward screen.

const INSPECTOR_SIZE := Vector2(220, 280)

var panel: PanelContainer
var name_label: Label
var cost_label: Label
var rarity_label: Label
var type_label: Label
var rules_label: Label
var diff_label: Label
var art_rect: TextureRect
var _current_card


func _loc():
	return get_node_or_null("/root/LocalizationManager")


func _tr(key: String, fallback: String = "") -> String:
	var loc = _loc()
	if loc != null:
		return loc.t(key, fallback)
	return fallback if fallback != "" else key


func _enum_text(value: String) -> String:
	var loc = _loc()
	if loc != null:
		return loc.enum_text(value)
	return value.to_upper()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	z_index = 200
	_build()


func _build() -> void:
	if panel != null:
		return
	panel = PanelContainer.new()
	panel.custom_minimum_size = INSPECTOR_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _frame_box())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	box.add_child(header)

	cost_label = Label.new()
	cost_label.custom_minimum_size = Vector2(36, 36)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 22)
	cost_label.add_theme_stylebox_override("normal", _round_box(Color(0.07, 0.11, 0.14), Color(0.45, 0.85, 1.0), 2, 18))
	header.add_child(cost_label)

	name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	header.add_child(name_label)

	rarity_label = Label.new()
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", Color(0.78, 0.69, 0.53))
	box.add_child(rarity_label)

	art_rect = TextureRect.new()
	art_rect.custom_minimum_size = Vector2(0, 96)
	art_rect.ignore_texture_size = true
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	box.add_child(art_rect)

	type_label = Label.new()
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 12)
	box.add_child(type_label)

	rules_label = Label.new()
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.add_theme_font_size_override("font_size", 14)
	rules_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74))
	box.add_child(rules_label)

	diff_label = Label.new()
	diff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diff_label.add_theme_font_size_override("font_size", 12)
	diff_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32))
	diff_label.visible = false
	box.add_child(diff_label)


func show_card(card_instance, anchor_position: Vector2) -> void:
	if panel == null:
		_build()
	_current_card = card_instance
	if card_instance == null:
		visible = false
		return
	var data = card_instance.data
	cost_label.text = str(card_instance.get_cost())
	name_label.text = card_instance.get_display_name()
	rarity_label.text = "%s · %s" % [_enum_text(String(data.rarity)), _enum_text(String(data.card_type))]
	type_label.text = _enum_text(String(data.card_type))
	rules_label.text = card_instance.get_description()
	if card_instance.upgraded and String(data.description) != "" and String(data.upgraded_description) != data.description:
		diff_label.visible = true
		diff_label.text = _tr("inspector.upgraded", "Upgraded -> %s") % card_instance.get_description()
	else:
		diff_label.visible = false
	art_rect.texture = _load_card_art(String(data.id))
	_position_near(anchor_position)
	modulate = Color(1, 1, 1, 0)
	visible = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.10)


func hide_card(card_instance = null) -> void:
	if card_instance != null and card_instance != _current_card:
		return
	visible = false
	_current_card = null


func _position_near(anchor: Vector2) -> void:
	# anchor is screen-space top-center of hovered card.
	var viewport := get_viewport_rect().size
	var pos := anchor + Vector2(-INSPECTOR_SIZE.x * 0.5, -INSPECTOR_SIZE.y - 12)
	pos.x = clamp(pos.x, 12, viewport.x - INSPECTOR_SIZE.x - 12)
	pos.y = max(12, pos.y)
	if panel != null:
		panel.position = pos


func _frame_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.07, 0.96)
	style.border_color = Color(0.74, 0.56, 0.27)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
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


func _load_card_art(card_id: String) -> Texture2D:
	var path := "res://art/generated/cards/%s.png" % card_id
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		path = "res://art/generated/ui/card_back.png"
	if ResourceLoader.exists(path):
		var imported = load(path)
		if imported is Texture2D:
			return imported
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
