class_name CardView
extends Button

signal card_selected(card)
signal card_hovered(card, anchor_position: Vector2)
signal card_unhovered(card)

const CARD_SIZE := Vector2(118, 154)
const KeywordCatalogScript := preload("res://scripts/core/keyword_catalog.gd")

var card
var rest_position := Vector2.ZERO
var rest_rotation := 0.0
var cost_label: Label
var rarity_label: Label
var name_label: Label
var art_panel: PanelContainer
var type_label: Label
var rules_label: Label
var glow_panel: Panel
var art_rect: TextureRect


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
	rest_rotation = rotation
	pivot_offset = CARD_SIZE * 0.5
	custom_minimum_size = CARD_SIZE
	_build_card_body()
	_add_card_styles()
	_update_text()
	disabled = disabled_by_state or card.get_cost() > available_energy
	tooltip_text = _build_card_tooltip()
	modulate = Color(0.58, 0.58, 0.58) if disabled else Color.WHITE


func refresh(available_energy: int, disabled_by_state: bool) -> void:
	if card == null:
		return
	_update_text()
	disabled = disabled_by_state or card.get_cost() > available_energy
	tooltip_text = _build_card_tooltip()
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
	box.offset_left = 8
	box.offset_top = 7
	box.offset_right = -8
	box.offset_bottom = -7
	box.add_theme_constant_override("separation", 2)
	root.add_child(box)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.custom_minimum_size = Vector2(0, 24)
	header.add_theme_constant_override("separation", 4)
	box.add_child(header)

	cost_label = Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.custom_minimum_size = Vector2(27, 24)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 18)
	header.add_child(cost_label)

	rarity_label = Label.new()
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 10)
	header.add_child(rarity_label)

	name_label = Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.custom_minimum_size = Vector2(0, 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 14)
	box.add_child(name_label)

	art_panel = PanelContainer.new()
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_panel.custom_minimum_size = Vector2(0, 48)
	box.add_child(art_panel)
	art_rect = TextureRect.new()
	art_rect.name = "ArtImage"
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_rect.ignore_texture_size = true
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	art_panel.add_child(art_rect)

	type_label = Label.new()
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_label.custom_minimum_size = Vector2(0, 16)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 10)
	box.add_child(type_label)

	rules_label = Label.new()
	rules_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rules_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rules_label.add_theme_font_size_override("font_size", 9)
	box.add_child(rules_label)


func _update_text() -> void:
	if card == null:
		return
	var rarity := String(card.data.rarity).to_upper()
	var card_type := String(card.data.card_type).to_upper()
	var loc = _loc()
	if loc != null:
		rarity = loc.enum_text(String(card.data.rarity))
		card_type = loc.enum_text(String(card.data.card_type))
	cost_label.text = str(card.get_cost())
	rarity_label.text = rarity
	name_label.text = card.get_display_name()
	type_label.text = card_type
	rules_label.text = card.get_description()
	if art_rect != null:
		art_rect.texture = _load_card_art_texture(String(card.data.id))


func _on_pressed() -> void:
	if card != null:
		card_selected.emit(card)


func _build_card_tooltip() -> String:
	if card == null:
		return ""
	var lines: Array[String] = []
	lines.append(card.get_display_name())
	lines.append("")
	lines.append(card.get_description())
	# Append a definition block for any keyword found in the rules text. Keeps
	# the tooltip self-contained for first-time players, but stays terse so
	# experienced players can ignore the trailing block.
	var text_lower := String(card.get_description()).to_lower()
	var seen: Dictionary = {}
	for entry in KeywordCatalogScript.entries():
		var id := String(entry.get("id", ""))
		if id == "" or seen.has(id):
			continue
		var display := String(entry.get("display", id)).to_lower()
		if text_lower.find(display) == -1:
			continue
		seen[id] = true
		lines.append("")
		lines.append("%s: %s" % [String(entry.get("display", id)), String(entry.get("summary", ""))])
	return "\n".join(lines)


func _loc():
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("/root/LocalizationManager")


func _on_mouse_entered() -> void:
	if disabled:
		return
	z_index = 200
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.28, 1.28), 0.11)
	tween.parallel().tween_property(self, "position", rest_position + Vector2(0, -56), 0.11)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.11)
	# Anchor for the inspector overlay = top-center of the resting card,
	# in global (viewport) coordinates so the inspector can position itself
	# regardless of where this CardView lives in the tree.
	var anchor := global_position + Vector2(CARD_SIZE.x * 0.5, 0)
	card_hovered.emit(card, anchor)


func _on_mouse_exited() -> void:
	z_index = 0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.10)
	tween.parallel().tween_property(self, "position", rest_position, 0.10)
	tween.parallel().tween_property(self, "rotation", rest_rotation, 0.10)
	card_unhovered.emit(card)


func set_rest_pose(pos: Vector2, rot: float, layer: int) -> void:
	rest_position = pos
	rest_rotation = rot
	position = pos
	rotation = rot
	z_index = layer
	pivot_offset = CARD_SIZE * 0.5


func _add_card_styles() -> void:
	var palette := _palette_for_card()
	var upgraded := card != null and bool(card.upgraded)
	var border_width: int = 3 if upgraded else 2
	if upgraded:
		# Replace the border color with gold so upgraded cards stand out at a glance.
		palette["border"] = Color(1.00, 0.84, 0.30)
		palette["glow"] = Color(1.00, 0.78, 0.20, 0.18)
	add_theme_stylebox_override("normal", _card_box(palette["bg"], palette["border"], border_width))
	add_theme_stylebox_override("hover", _card_box(palette["bg"].lightened(0.08), palette["border"].lightened(0.18), border_width + 1))
	add_theme_stylebox_override("pressed", _card_box(palette["bg"].lightened(0.14), palette["border"].lightened(0.25), border_width + 1))
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
		"curse":
			# Curse cards: heavy purple/black with red trim. Visibly oppressive.
			return {
				"bg": Color(0.07, 0.04, 0.05),
				"strip": Color(0.12, 0.05, 0.07),
				"type_bg": Color(0.20, 0.07, 0.10),
				"art": Color(0.10, 0.05, 0.07),
				"border": Color(0.70, 0.20, 0.30),
				"glow": Color(0.40, 0.10, 0.18, 0.20)
			}
		"status":
			# Status cards (slimes, dazes etc): muted grey-green.
			return {
				"bg": Color(0.07, 0.09, 0.07),
				"strip": Color(0.11, 0.14, 0.10),
				"type_bg": Color(0.16, 0.20, 0.14),
				"art": Color(0.10, 0.13, 0.10),
				"border": Color(0.55, 0.62, 0.40),
				"glow": Color(0.30, 0.45, 0.20, 0.16)
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


func _load_card_art_texture(card_id: String) -> Texture2D:
	# Try the card-specific art first, then fall back to a per-type placeholder so
	# attack/skill/power cards remain visually distinct even without bespoke art.
	var candidates: Array[String] = [
		"res://art/generated/cards/%s.png" % card_id,
	]
	var card_type := ""
	if card != null and card.data != null:
		card_type = String(card.data.card_type)
		candidates.append("res://art/generated/cards/_placeholder_%s.png" % card_type)
		candidates.append("res://art/generated/ui/placeholder_%s.png" % card_type)
	candidates.append("res://art/generated/ui/card_back.png")
	for path in candidates:
		if not FileAccess.file_exists(path):
			continue
		var image := Image.new()
		var err := image.load(path)
		if err == OK:
			return ImageTexture.create_from_image(image)
	# As a last resort, generate a flat-color placeholder so the slot is never empty.
	var palette := _palette_for_card()
	var fallback := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	fallback.fill(palette.get("art", Color(0.14, 0.12, 0.09)))
	return ImageTexture.create_from_image(fallback)
