class_name DeckModal
extends Control

# Full-deck viewer with sort buttons (type / cost / rarity).
# Used from the map's deck-summary capsule and from any combat HUD button.

signal closed

const CARD_VIEW_SCENE := preload("res://scenes/combat/card_view.tscn")
const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")

const SORT_TYPE := "type"
const SORT_COST := "cost"
const SORT_RARITY := "rarity"

const RARITY_ORDER := {"basic": 0, "common": 1, "uncommon": 2, "rare": 3}

var dim: ColorRect
var panel: PanelContainer
var title_label: Label
var summary_label: Label
var grid: GridContainer
var scroll: ScrollContainer
var close_button: Button
var sort_buttons: Dictionary = {}

var _cards: Array = []
var _sort_mode: String = SORT_TYPE


func _loc():
	return get_node_or_null("/root/LocalizationManager")


func _tr(key: String, fallback: String = "") -> String:
	var loc = _loc()
	if loc != null:
		return loc.t(key, fallback)
	return fallback if fallback != "" else key


func _ready() -> void:
	visible = false
	z_index = 190
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
	dim.color = Color(0.0, 0.0, 0.0, 0.76)
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
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)

	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text = _tr("modal.deck_title", "Deck")
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.58))
	header.add_child(title_label)

	close_button = Button.new()
	close_button.text = _tr("modal.close", "Close")
	close_button.custom_minimum_size = Vector2(96, 36)
	close_button.add_theme_stylebox_override("normal", _button_box(Color(0.070, 0.058, 0.044, 0.86), Color(0.58, 0.42, 0.20, 0.86)))
	close_button.add_theme_stylebox_override("hover", _button_box(Color(0.095, 0.070, 0.048, 0.96), Color(0.90, 0.64, 0.28, 1.0)))
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)

	summary_label = Label.new()
	summary_label.add_theme_font_size_override("font_size", 14)
	summary_label.add_theme_color_override("font_color", Color(0.78, 0.69, 0.53))
	box.add_child(summary_label)

	var sort_row := HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 8)
	box.add_child(sort_row)

	for sort_key in [SORT_TYPE, SORT_COST, SORT_RARITY]:
		var btn := Button.new()
		btn.text = _sort_label(sort_key)
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(140, 32)
		btn.add_theme_stylebox_override("normal", _button_box(Color(0.048, 0.044, 0.038, 0.70), Color(0.34, 0.29, 0.22, 0.80)))
		btn.add_theme_stylebox_override("hover", _button_box(Color(0.070, 0.058, 0.044, 0.88), Color(0.70, 0.52, 0.24, 0.92)))
		btn.add_theme_stylebox_override("pressed", _button_box(Color(0.090, 0.068, 0.046, 0.94), Color(0.94, 0.68, 0.30, 1.0)))
		var captured: String = sort_key
		btn.pressed.connect(func() -> void: _set_sort(captured))
		sort_buttons[sort_key] = btn
		sort_row.add_child(btn)

	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)


# Accepts either CardInstance objects or raw CardData entries.
func show_deck(deck_label: String, cards: Array) -> void:
	if dim == null:
		_build()
	_layout_modal()
	_cards.clear()
	for entry in cards:
		var inst = entry
		if entry == null:
			continue
		if entry is Resource and "card_type" in entry:
			# raw CardData → wrap into CardInstance
			inst = CardInstanceScript.new()
			inst.setup(entry, false)
		_cards.append(inst)
	title_label.text = _localized_deck_label(deck_label)
	close_button.text = _tr("modal.close", "Close")
	for sort_key in sort_buttons.keys():
		(sort_buttons[sort_key] as Button).text = _sort_label(String(sort_key))
	_set_sort(SORT_TYPE)
	visible = true
	move_to_front()


func _layout_modal() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1280, 720)
	var panel_size := Vector2(min(960.0, viewport_size.x - 80.0), min(600.0, viewport_size.y - 70.0))
	var origin := (viewport_size - panel_size) * 0.5
	panel.offset_left = origin.x
	panel.offset_top = origin.y
	panel.offset_right = origin.x + panel_size.x
	panel.offset_bottom = origin.y + panel_size.y
	if scroll != null:
		scroll.custom_minimum_size = Vector2(0, max(300.0, panel_size.y - 180.0))


func _set_sort(sort_mode: String) -> void:
	_sort_mode = sort_mode
	for key in sort_buttons.keys():
		(sort_buttons[key] as Button).button_pressed = (key == sort_mode)
	_render()


func _render() -> void:
	for child in grid.get_children():
		child.queue_free()
	var sorted := _cards.duplicate()
	sorted.sort_custom(_compare_cards)

	var attack_count := 0
	var skill_count := 0
	var power_count := 0
	for card in sorted:
		var t := String(card.data.card_type)
		if t == "attack":
			attack_count += 1
		elif t == "skill":
			skill_count += 1
		elif t == "power":
			power_count += 1
		var card_view = CARD_VIEW_SCENE.instantiate()
		card_view.setup(card, 99, true)
		card_view.disabled = true
		card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(card_view)

	summary_label.text = _tr("modal.summary", "%d cards · %d atk · %d skl · %d pwr") % [_cards.size(), attack_count, skill_count, power_count]


func _localized_deck_label(deck_label: String) -> String:
	if deck_label == "Run Deck":
		return _tr("modal.run_deck", deck_label)
	if deck_label == "Deck":
		return _tr("modal.deck_title", deck_label)
	return deck_label


func _sort_label(sort_key: String) -> String:
	match sort_key:
		SORT_COST:
			return _tr("modal.sort.cost", "Sort: Cost")
		SORT_RARITY:
			return _tr("modal.sort.rarity", "Sort: Rarity")
		_:
			return _tr("modal.sort.type", "Sort: Type")


func _compare_cards(a, b) -> bool:
	match _sort_mode:
		SORT_COST:
			if a.get_cost() != b.get_cost():
				return a.get_cost() < b.get_cost()
			return String(a.data.display_name) < String(b.data.display_name)
		SORT_RARITY:
			var ra := int(RARITY_ORDER.get(String(a.data.rarity), 99))
			var rb := int(RARITY_ORDER.get(String(b.data.rarity), 99))
			if ra != rb:
				return ra < rb
			return String(a.data.display_name) < String(b.data.display_name)
		_:
			# type: attack > skill > power > other, then by cost.
			var type_order := {"attack": 0, "skill": 1, "power": 2}
			var ta := int(type_order.get(String(a.data.card_type), 9))
			var tb := int(type_order.get(String(b.data.card_type), 9))
			if ta != tb:
				return ta < tb
			if a.get_cost() != b.get_cost():
				return a.get_cost() < b.get_cost()
			return String(a.data.display_name) < String(b.data.display_name)


func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_on_close_pressed()


func _frame_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.050, 0.042, 0.034, 0.96)
	style.border_color = Color(0.78, 0.58, 0.26)
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


func _button_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style
