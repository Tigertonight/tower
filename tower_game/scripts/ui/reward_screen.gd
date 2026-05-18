class_name RewardScreen
extends Control

signal card_chosen(card_id: String)
signal skipped

const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")
const CARD_VIEW_SCENE := preload("res://scenes/combat/card_view.tscn")
const CardInspectorScript := preload("res://scripts/ui/card_inspector.gd")

var content_box: VBoxContainer
var card_box: HBoxContainer
var panel: PanelContainer
var frame_art: TextureRect
var skip_button: Button
var card_inspector
var reveal_label: Label


func _loc():
	return get_node_or_null("/root/LocalizationManager")


func _tr(key: String, fallback: String = "") -> String:
	var loc = _loc()
	if loc != null:
		return loc.t(key, fallback)
	return fallback if fallback != "" else key


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg_art := TextureRect.new()
	bg_art.texture = _load_png_texture("res://art/generated/backgrounds/reward_archive_spoils.png")
	bg_art.ignore_texture_size = true
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_art.modulate = Color(1, 1, 1, 0.54)
	bg_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_art)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.005, 0.0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var glow := ColorRect.new()
	glow.color = Color(0.45, 0.26, 0.07, 0.18)
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.offset_left = -520
	glow.offset_top = -230
	glow.offset_right = 520
	glow.offset_bottom = 230
	add_child(glow)

	frame_art = TextureRect.new()
	frame_art.texture = _load_png_texture("res://art/generated/ui/reward_panel_frame.png")
	frame_art.ignore_texture_size = true
	frame_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame_art.set_anchors_preset(Control.PRESET_CENTER)
	frame_art.offset_left = -460
	frame_art.offset_top = -270
	frame_art.offset_right = 460
	frame_art.offset_bottom = 270
	frame_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame_art)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.add_theme_stylebox_override("normal", _reward_box())
	add_child(panel)
	_layout_reward()

	content_box = VBoxContainer.new()
	content_box.add_theme_constant_override("separation", 12)
	panel.add_child(content_box)

	var title := Label.new()
	title.text = _tr("reward.title", "Archive Spoils")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.58))
	content_box.add_child(title)

	var gold_line := Label.new()
	gold_line.text = _tr("reward.gold", "+18 gold secured. Choose one card.")
	gold_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_line.add_theme_font_size_override("font_size", 16)
	content_box.add_child(gold_line)

	var hint := Label.new()
	hint.text = _tr("reward.hint", "The archive offers three possible notes. Take one, or leave them sealed for extra gold.")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(hint)

	reveal_label = Label.new()
	reveal_label.text = _tr("reward.reveal", "Unseal one record")
	reveal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_label.add_theme_font_size_override("font_size", 14)
	reveal_label.add_theme_color_override("font_color", Color(0.90, 0.74, 0.42))
	content_box.add_child(reveal_label)

	card_box = HBoxContainer.new()
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card_box.add_theme_constant_override("separation", 18)
	card_box.custom_minimum_size = Vector2(0, 178)
	content_box.add_child(card_box)

	var skip_holder := CenterContainer.new()
	skip_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_child(skip_holder)

	skip_button = Button.new()
	skip_button.text = _tr("reward.skip", "Skip Reward (+25 gold)")
	skip_button.custom_minimum_size = Vector2(260, 38)
	skip_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip_button.add_theme_font_size_override("font_size", 13)
	skip_button.add_theme_stylebox_override("normal", _skip_box(Color(0.050, 0.046, 0.040, 0.72), Color(0.36, 0.30, 0.20, 0.78)))
	skip_button.add_theme_stylebox_override("hover", _skip_box(Color(0.070, 0.058, 0.044, 0.86), Color(0.68, 0.50, 0.24, 0.90)))
	skip_button.add_theme_stylebox_override("pressed", _skip_box(Color(0.090, 0.068, 0.046, 0.94), Color(0.82, 0.60, 0.30, 1.0)))
	skip_button.pressed.connect(func() -> void: skipped.emit())
	skip_holder.add_child(skip_button)

	card_inspector = CardInspectorScript.new()
	add_child(card_inspector)
	_layout_reward()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and panel != null:
		_layout_reward()


func _layout_reward() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1280, 720)
	var panel_size := Vector2(min(780.0, viewport_size.x - 96.0), min(460.0, viewport_size.y - 86.0))
	var origin := (viewport_size - panel_size) * 0.5
	if panel != null:
		panel.offset_left = origin.x
		panel.offset_top = origin.y
		panel.offset_right = origin.x + panel_size.x
		panel.offset_bottom = origin.y + panel_size.y
	if frame_art != null:
		frame_art.offset_left = origin.x - 70.0
		frame_art.offset_top = origin.y - 50.0
		frame_art.offset_right = origin.x + panel_size.x + 70.0
		frame_art.offset_bottom = origin.y + panel_size.y + 50.0


func show_rewards(cards: Array) -> void:
	if content_box == null:
		_build_ui()
	for child in card_box.get_children():
		child.queue_free()
	for card in cards:
		var card_id := String(card.id)
		var instance = CardInstanceScript.new()
		instance.setup(card)
		var slot := CenterContainer.new()
		slot.custom_minimum_size = Vector2(146, 172)
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var rarity := String(card.rarity)
		if rarity == "rare" or rarity == "uncommon":
			var glow := ColorRect.new()
			glow.color = Color(1.0, 0.76, 0.22, 0.16) if rarity == "rare" else Color(0.35, 0.68, 1.0, 0.12)
			glow.set_anchors_preset(Control.PRESET_FULL_RECT)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(glow)
		var card_view = CARD_VIEW_SCENE.instantiate()
		card_view.setup(instance, 99, false)
		if card_view.has_method("set_hover_lift_enabled"):
			card_view.set_hover_lift_enabled(false)
		card_view.position = Vector2.ZERO
		card_view.rotation = 0.0
		card_view.scale = Vector2(0.82, 0.82)
		card_view.modulate = Color(1, 1, 1, 0.0)
		card_view.card_selected.connect(func(_card) -> void: card_chosen.emit(card_id))
		card_view.card_hovered.connect(_on_card_hovered)
		card_view.card_unhovered.connect(_on_card_unhovered)
		slot.add_child(card_view)
		card_box.add_child(slot)
	visible = true
	move_to_front()
	if card_inspector != null:
		card_inspector.move_to_front()
	_animate_reward_reveal()


func hide_rewards() -> void:
	visible = false
	if card_inspector != null:
		card_inspector.visible = false


func _on_card_hovered(card_instance, anchor_position: Vector2) -> void:
	if card_inspector == null:
		return
	card_inspector.show_card(card_instance, anchor_position)


func _on_card_unhovered(card_instance) -> void:
	if card_inspector == null:
		return
	card_inspector.hide_card(card_instance)


func _reward_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.080, 0.060, 0.042, 0.88)
	style.border_color = Color(0.72, 0.52, 0.22)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _skip_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _animate_reward_reveal() -> void:
	var index := 0
	for slot in card_box.get_children():
		for child in slot.get_children():
			if child is Button:
				var card_view := child as Control
				var tween := create_tween()
				tween.tween_interval(0.08 * float(index))
				tween.tween_property(card_view, "modulate:a", 1.0, 0.16)
				tween.parallel().tween_property(card_view, "scale", Vector2.ONE, 0.18)
				index += 1


func _load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported = load(path)
		if imported is Texture2D:
			return imported
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Failed to load image: %s" % path)
		return null
	return ImageTexture.create_from_image(image)
