class_name RewardScreen
extends Control

signal card_chosen(card_id: String)
signal skipped

const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")
const CARD_VIEW_SCENE := preload("res://scenes/combat/card_view.tscn")

var content_box: VBoxContainer
var card_box: HBoxContainer
var panel: PanelContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
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

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -390
	panel.offset_top = -230
	panel.offset_right = 390
	panel.offset_bottom = 230
	panel.add_theme_stylebox_override("normal", _reward_box())
	add_child(panel)

	content_box = VBoxContainer.new()
	content_box.add_theme_constant_override("separation", 12)
	panel.add_child(content_box)

	var title := Label.new()
	title.text = "Archive Spoils"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	content_box.add_child(title)

	var gold_line := Label.new()
	gold_line.text = "+18 gold secured. Choose one card."
	gold_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_line.add_theme_font_size_override("font_size", 16)
	content_box.add_child(gold_line)

	var hint := Label.new()
	hint.text = "The archive offers three possible notes. Take one, or leave them sealed for extra gold."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(hint)

	card_box = HBoxContainer.new()
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card_box.add_theme_constant_override("separation", 18)
	content_box.add_child(card_box)

	var skip_button := Button.new()
	skip_button.text = "Skip Reward (+25 gold)"
	skip_button.custom_minimum_size = Vector2(220, 50)
	skip_button.pressed.connect(func() -> void: skipped.emit())
	content_box.add_child(skip_button)


func show_rewards(cards: Array) -> void:
	if content_box == null:
		_build_ui()
	for child in card_box.get_children():
		child.queue_free()
	for card in cards:
		var card_id := String(card.id)
		var instance = CardInstanceScript.new()
		instance.setup(card)
		var card_view = CARD_VIEW_SCENE.instantiate()
		card_view.setup(instance, 99, false)
		card_view.card_selected.connect(func(_card) -> void: card_chosen.emit(card_id))
		card_box.add_child(card_view)
	visible = true


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
