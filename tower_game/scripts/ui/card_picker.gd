class_name CardPicker
extends Control

# Reusable picker for upgrade / remove / transform.
# Emits picked(card_instance, index) when the user confirms a selection,
# cancelled when the user closes without choosing.

signal picked(card_instance, source_index)
signal cancelled

const CARD_VIEW_SCENE := preload("res://scenes/combat/card_view.tscn")
const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")
const CardInspectorScript := preload("res://scripts/ui/card_inspector.gd")

var dim: ColorRect
var panel: PanelContainer
var title_label: Label
var hint_label: Label
var grid: GridContainer
var scroll: ScrollContainer
var cancel_button: Button
var card_inspector

var _entries: Array = []  # array of {card: CardInstance, index: int}


func _loc():
	return get_node_or_null("/root/LocalizationManager")


func _tr(key: String, fallback: String = "") -> String:
	var loc = _loc()
	if loc != null:
		return loc.t(key, fallback)
	return fallback if fallback != "" else key


func _ready() -> void:
	visible = false
	z_index = 195
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	_build()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and panel != null:
		_layout_modal()


func _build() -> void:
	if dim != null:
		return

	dim = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.add_theme_stylebox_override("panel", _frame_box())
	add_child(panel)
	_layout_modal()

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)

	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text = _tr("picker.default_title", "Pick a card")
	title_label.add_theme_font_size_override("font_size", 22)
	header.add_child(title_label)

	cancel_button = Button.new()
	cancel_button.text = _tr("modal.cancel", "Cancel")
	cancel_button.custom_minimum_size = Vector2(96, 36)
	cancel_button.pressed.connect(_on_cancel_pressed)
	header.add_child(cancel_button)

	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.78, 0.69, 0.53))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint_label)

	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	card_inspector = CardInspectorScript.new()
	add_child(card_inspector)


# `cards` may be CardInstance objects, CardData resources, or strings of card ids
# accompanied by `card_database` for lookup. We accept already-prepared CardInstance.
# `predicate` (Callable) optionally filters which cards are pickable; non-pickable
# entries render disabled.
func show_picker(p_title: String, p_hint: String, cards: Array, predicate: Callable = Callable()) -> void:
	if dim == null:
		_build()
	_layout_modal()
	title_label.text = _localized_title(p_title)
	hint_label.text = _localized_hint(p_hint)
	cancel_button.text = _tr("modal.cancel", "Cancel")
	_entries.clear()
	for child in grid.get_children():
		child.queue_free()

	for i in cards.size():
		var raw = cards[i]
		var inst = raw
		var source_index := i
		if raw is Dictionary:
			inst = raw.get("card", null)
			source_index = int(raw.get("index", i))
		if raw is Resource and "card_type" in raw:
			inst = CardInstanceScript.new()
			inst.setup(raw, false)
		_entries.append({"card": inst, "index": source_index})

		var pickable := true
		if predicate.is_valid():
			pickable = bool(predicate.call(inst))

		var card_view = CARD_VIEW_SCENE.instantiate()
		card_view.setup(inst, 99, not pickable)
		card_view.card_hovered.connect(_on_card_hovered)
		card_view.card_unhovered.connect(_on_card_unhovered)
		var captured_index := source_index
		var captured_card = inst
		if pickable:
			card_view.card_selected.connect(func(_card) -> void: _on_card_picked(captured_card, captured_index))
		else:
			card_view.disabled = true
			card_view.modulate = Color(0.5, 0.5, 0.5)
		grid.add_child(card_view)

	visible = true
	move_to_front()
	if card_inspector != null:
		card_inspector.move_to_front()


func _localized_title(text: String) -> String:
	match text:
		"Remove a Strike Form":
			return _tr("picker.remove_strike.title", text)
		"Upgrade a card":
			return _tr("picker.upgrade.title", text)
		"Transform a card":
			return _tr("picker.transform.title", text)
		"Offer a card":
			return _tr("picker.offer.title", text)
		"Shop remove":
			return _tr("picker.shop_remove.title", text)
		"Pick a card":
			return _tr("picker.default_title", text)
		_:
			return text


func _localized_hint(text: String) -> String:
	match text:
		"Choose the copy to remove from this run.":
			return _tr("picker.remove_strike.hint", text)
		"Choose an unupgraded card to improve.":
			return _tr("picker.upgrade.hint", text)
		"Choose a card. The lantern rewrites it into another of the same type.":
			return _tr("picker.transform.hint", text)
		"Choose a card to rewrite under green wax flame.":
			return _tr("picker.transform_green.hint", text)
		"Remove one card from this run.":
			return _tr("picker.offer.hint", text)
		"Choose a Strike Form to remove. The vendor has already taken the gold.":
			return _tr("picker.shop_remove.hint", text)
		_:
			return text


func _layout_modal() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1280, 720)
	var panel_size := Vector2(min(900.0, viewport_size.x - 80.0), min(540.0, viewport_size.y - 70.0))
	var origin := (viewport_size - panel_size) * 0.5
	panel.offset_left = origin.x
	panel.offset_top = origin.y
	panel.offset_right = origin.x + panel_size.x
	panel.offset_bottom = origin.y + panel_size.y
	if scroll != null:
		scroll.custom_minimum_size = Vector2(0, max(280.0, panel_size.y - 145.0))


func _on_card_picked(card_instance, source_index: int) -> void:
	visible = false
	if card_inspector != null:
		card_inspector.hide_card(card_instance)
	picked.emit(card_instance, source_index)


func _on_cancel_pressed() -> void:
	visible = false
	if card_inspector != null:
		card_inspector.visible = false
	cancelled.emit()


func _on_card_hovered(card_instance, anchor_position: Vector2) -> void:
	if card_inspector == null:
		return
	card_inspector.show_card(card_instance, anchor_position)


func _on_card_unhovered(card_instance) -> void:
	if card_inspector == null:
		return
	card_inspector.hide_card(card_instance)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_on_cancel_pressed()


func _frame_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.07, 0.96)
	style.border_color = Color(0.74, 0.56, 0.27)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
