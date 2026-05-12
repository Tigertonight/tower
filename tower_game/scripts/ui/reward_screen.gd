class_name RewardScreen
extends Control

signal card_chosen(card_id: String)
signal skipped

const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")
const CARD_VIEW_SCENE := preload("res://scenes/combat/card_view.tscn")

var content_box: VBoxContainer
var card_box: HBoxContainer
var panel: PanelContainer
var frame_art: TextureRect
var skip_button: Button


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
	skip_button.custom_minimum_size = Vector2(320, 48)
	skip_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	skip_button.pressed.connect(func() -> void: skipped.emit())
	skip_holder.add_child(skip_button)
	_layout_reward()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and panel != null:
		_layout_reward()


func _layout_reward() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1280, 720)
	size = viewport_size
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
		var card_view = CARD_VIEW_SCENE.instantiate()
		card_view.setup(instance, 99, false)
		card_view.position = Vector2.ZERO
		card_view.rotation = 0.0
		card_view.scale = Vector2.ONE
		if card_view.has_method("set_rest_pose"):
			card_view.set_rest_pose(Vector2.ZERO, 0.0, 0)
		card_view.card_selected.connect(func(_card) -> void: card_chosen.emit(card_id))
		slot.add_child(card_view)
		card_box.add_child(slot)
	visible = true
	move_to_front()


func hide_rewards() -> void:
	visible = false


func _reward_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.095, 0.075, 0.050, 0.96)
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


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Failed to load image: %s" % path)
		return null
	return ImageTexture.create_from_image(image)
