class_name PileModal
extends Control

# Modal that lists the contents of a pile (Draw / Discard / Exhaust / Hand).
# Cards are grouped by type and rendered as small CardView clones.

signal closed

const CARD_VIEW_SCENE := preload("res://scenes/combat/card_view.tscn")

var dim: ColorRect
var panel: PanelContainer
var title_label: Label
var summary_label: Label
var grid: GridContainer
var scroll: ScrollContainer
var close_button: Button


func _loc():
	return get_node_or_null("/root/LocalizationManager")


func _tr(key: String, fallback: String = "") -> String:
	var loc = _loc()
	if loc != null:
		return loc.t(key, fallback)
	return fallback if fallback != "" else key


func _ready() -> void:
	visible = false
	z_index = 180
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

	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)


func show_pile(pile_title: String, cards: Array) -> void:
	if dim == null:
		_build()
	_layout_modal()
	title_label.text = _localized_pile_title(pile_title)
	close_button.text = _tr("modal.close", "Close")
	for child in grid.get_children():
		child.queue_free()

	# Group by card_type so layout is "all attacks, then skills, then powers".
	var grouped := {"attack": [], "skill": [], "power": [], "other": []}
	for card in cards:
		var t := String(card.data.card_type)
		if not grouped.has(t):
			t = "other"
		grouped[t].append(card)

	var attack_count: int = grouped["attack"].size()
	var skill_count: int = grouped["skill"].size()
	var power_count: int = grouped["power"].size()
	summary_label.text = _tr("modal.summary", "%d cards · %d atk · %d skl · %d pwr") % [cards.size(), attack_count, skill_count, power_count]

	for type_key in ["attack", "skill", "power", "other"]:
		for card in grouped[type_key]:
			var card_view = CARD_VIEW_SCENE.instantiate()
			card_view.setup(card, 99, true)
			card_view.disabled = true
			# Disable hover lift so the modal behaves like a static viewer.
			card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(card_view)

	visible = true
	move_to_front()


func _localized_pile_title(pile_title: String) -> String:
	if pile_title.begins_with("Draw Pile"):
		var draw_template := _tr("modal.draw_pile", "Draw Pile (%d)")
		return draw_template % _extract_count(pile_title)
	if pile_title.begins_with("Discard Pile"):
		var discard_template := _tr("modal.discard_pile", "Discard Pile (%d)")
		return discard_template % _extract_count(pile_title)
	if pile_title.begins_with("Exhaust Pile"):
		var exhaust_template := _tr("modal.exhaust_pile", "Exhaust Pile (%d)")
		return exhaust_template % _extract_count(pile_title)
	return pile_title


func _extract_count(text: String) -> int:
	var start := text.find("(")
	var end := text.find(")")
	if start >= 0 and end > start:
		return int(text.substr(start + 1, end - start - 1))
	return 0


func _layout_modal() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1280, 720)
	var panel_size := Vector2(min(880.0, viewport_size.x - 80.0), min(520.0, viewport_size.y - 70.0))
	var origin := (viewport_size - panel_size) * 0.5
	panel.offset_left = origin.x
	panel.offset_top = origin.y
	panel.offset_right = origin.x + panel_size.x
	panel.offset_bottom = origin.y + panel_size.y
	if scroll != null:
		scroll.custom_minimum_size = Vector2(0, max(260.0, panel_size.y - 140.0))


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
