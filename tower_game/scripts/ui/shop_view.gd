class_name ShopView
extends Control

const CARD_VIEW_SCENE := preload("res://scenes/combat/card_view.tscn")
const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")

# Shop screen presented as a grid (3 cards / 2 relics / 2 potions + remove).
# Designed to replace the legacy choice-screen list.
#
# Caller wires up the `*_purchased` signals to mutate gold/deck/relics/potions,
# and re-calls `set_offers` after each purchase so the SOLD overlay updates.

signal card_purchased(card_id: String, price: int)
signal relic_purchased(relic_id: String, price: int)
signal potion_purchased(potion_id: String, price: int)
signal remove_card_requested(price: int)
signal leave_pressed

const RARITY_COLORS := {
	"basic": Color(0.78, 0.78, 0.78),
	"common": Color(0.78, 0.78, 0.78),
	"uncommon": Color(0.45, 0.78, 1.00),
	"rare": Color(1.00, 0.82, 0.32),
}

var _gold: int = 0
var _panel: PanelContainer
var _content_scroll: ScrollContainer
var _gold_label: Label
var _hint_label: Label
var _card_row: HBoxContainer
var _relic_row: HBoxContainer
var _potion_row: HBoxContainer
var _service_box: VBoxContainer
var _remove_button: Button
var _leave_button: Button
var _sold_card_ids: Dictionary = {}
var _sold_relic_ids: Dictionary = {}
var _sold_potion_ids: Dictionary = {}


func _loc():
	return get_node_or_null("/root/LocalizationManager")


func _tr(key: String, fallback: String = "") -> String:
	var loc = _loc()
	if loc != null:
		return loc.t(key, fallback)
	return fallback if fallback != "" else key


func _localized_name(id: String, fallback: String) -> String:
	var loc = _loc()
	if loc != null:
		return loc.name_for(id, fallback)
	return fallback


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _panel != null:
		_layout_shop()


func _build() -> void:
	if _gold_label != null:
		return

	var bg_art := TextureRect.new()
	bg_art.texture = _load_png_texture("res://art/generated/backgrounds/shop_quiet_vendor.png")
	bg_art.ignore_texture_size = true
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_art)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.010, 0.64)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.add_theme_stylebox_override("panel", _frame_box())
	add_child(_panel)
	_layout_shop()

	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(_content_scroll)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	box.add_child(header)

	var title := Label.new()
	title.text = _tr("shop.title", "Quiet Vendor")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	header.add_child(_gold_label)

	_hint_label = Label.new()
	_hint_label.text = _tr("shop.hint", "A lantern-lit vendor lays three tools on velvet. Gold speaks softly here.")
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint_label)

	_card_row = HBoxContainer.new()
	_card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_row.add_theme_constant_override("separation", 16)
	_card_row.custom_minimum_size = Vector2(0, 160)
	box.add_child(_card_row)

	_relic_row = HBoxContainer.new()
	_relic_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_relic_row.add_theme_constant_override("separation", 16)
	_relic_row.custom_minimum_size = Vector2(0, 96)
	box.add_child(_relic_row)

	_potion_row = HBoxContainer.new()
	_potion_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_potion_row.add_theme_constant_override("separation", 16)
	_potion_row.custom_minimum_size = Vector2(0, 96)
	box.add_child(_potion_row)

	_service_box = VBoxContainer.new()
	_service_box.add_theme_constant_override("separation", 8)
	box.add_child(_service_box)

	_remove_button = Button.new()
	_remove_button.text = _tr("shop.remove", "Remove a card  -  %d gold") % 0
	_remove_button.custom_minimum_size = Vector2(220, 40)
	_remove_button.pressed.connect(_on_remove_pressed)
	_service_box.add_child(_remove_button)

	_leave_button = Button.new()
	_leave_button.text = _tr("shop.leave", "Leave")
	_leave_button.custom_minimum_size = Vector2(160, 40)
	_leave_button.pressed.connect(func() -> void: leave_pressed.emit())
	_service_box.add_child(_leave_button)
	_layout_shop()


func _layout_shop() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1280, 720)
	size = viewport_size
	var panel_size := Vector2(min(1060.0, viewport_size.x - 80.0), min(620.0, viewport_size.y - 78.0))
	var origin := (viewport_size - panel_size) * 0.5
	if _panel != null:
		_panel.offset_left = origin.x
		_panel.offset_top = origin.y
		_panel.offset_right = origin.x + panel_size.x
		_panel.offset_bottom = origin.y + panel_size.y
	if _content_scroll != null:
		_content_scroll.custom_minimum_size = Vector2(max(760.0, panel_size.x - 36.0), max(420.0, panel_size.y - 32.0))


func set_offers(gold: int, card_offers: Array, relic_offers: Array, potion_offers: Array, remove_price: int, can_remove: bool) -> void:
	if _gold_label == null:
		_build()
	_gold = gold
	_gold_label.text = _tr("shop.gold", "Gold: %d") % gold
	_remove_button.text = _tr("shop.remove", "Remove a card  -  %d gold") % remove_price
	_remove_button.disabled = (gold < remove_price) or not can_remove
	_remove_button.tooltip_text = (_tr("shop.remove_tip", "Removes a card from your run deck.") if can_remove else _tr("shop.remove_tip_blocked", "Need at least one Strike Form and a deck size > 8."))
	_render_row(_card_row, card_offers, "card")
	_render_row(_relic_row, relic_offers, "relic")
	_render_row(_potion_row, potion_offers, "potion")


func mark_card_sold(card_id: String) -> void:
	_sold_card_ids[card_id] = true
	# caller will re-call set_offers; we update visually too just in case
	for child in _card_row.get_children():
		if child.get_meta("offer_id", "") == card_id:
			_apply_sold_overlay(child)


func mark_relic_sold(relic_id: String) -> void:
	_sold_relic_ids[relic_id] = true
	for child in _relic_row.get_children():
		if child.get_meta("offer_id", "") == relic_id:
			_apply_sold_overlay(child)


func mark_potion_sold(potion_id: String) -> void:
	_sold_potion_ids[potion_id] = true


func _render_row(row: HBoxContainer, offers: Array, kind: String) -> void:
	for child in row.get_children():
		child.queue_free()
	if offers.is_empty():
		var hint := Label.new()
		var kind_label := _tr("shop.kind.%s" % kind, kind)
		hint.text = _tr("shop.empty", "(no %s on offer)") % kind_label
		hint.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5))
		row.add_child(hint)
		return
	for offer in offers:
		var item := _make_offer_item(offer, kind)
		row.add_child(item)


func _make_offer_item(offer: Dictionary, kind: String) -> Control:
	if kind == "card" and offer.get("card_data", null) != null:
		return _make_card_offer_item(offer)

	var rarity := String(offer.get("rarity", "common"))
	var border: Color = RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
	var item := PanelContainer.new()
	item.custom_minimum_size = Vector2(168, 88)
	item.add_theme_stylebox_override("panel", _offer_box(border))
	item.set_meta("offer_id", String(offer.get("id", "")))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	item.add_child(box)

	var icon_path := String(offer.get("icon_path", ""))
	if icon_path != "":
		var icon := TextureRect.new()
		icon.texture = _load_png_texture(icon_path)
		icon.custom_minimum_size = Vector2(0, 34)
		icon.ignore_texture_size = true
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)

	var name_label := Label.new()
	name_label.text = _localized_name(String(offer.get("id", "")), String(offer.get("name", "?")))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	box.add_child(name_label)

	var rarity_label := Label.new()
	rarity_label.text = _tr("enum.%s" % rarity, rarity.to_upper())
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.add_theme_color_override("font_color", border)
	box.add_child(rarity_label)

	var price := int(offer.get("price", 0))
	var price_label := Label.new()
	price_label.text = _tr("shop.price", "%d gold") % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 14)
	if _gold < price:
		price_label.add_theme_color_override("font_color", Color(1.0, 0.40, 0.32))
	else:
		price_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	box.add_child(price_label)

	var buy_button := Button.new()
	buy_button.text = _tr("shop.buy", "Buy")
	buy_button.disabled = _gold < price
	buy_button.custom_minimum_size = Vector2(0, 28)
	box.add_child(buy_button)

	# Description tooltip when present.
	var description := String(offer.get("description", ""))
	if description != "":
		item.tooltip_text = description

	var offer_id := String(offer.get("id", ""))
	var sold := false
	match kind:
		"card": sold = _sold_card_ids.has(offer_id)
		"relic": sold = _sold_relic_ids.has(offer_id)
		"potion": sold = _sold_potion_ids.has(offer_id)
	if sold:
		_apply_sold_overlay(item)
		buy_button.disabled = true
		buy_button.text = _tr("shop.sold", "SOLD")
	else:
		match kind:
			"card":
				buy_button.pressed.connect(func() -> void:
					_sold_card_ids[offer_id] = true
					card_purchased.emit(offer_id, price))
			"relic":
				buy_button.pressed.connect(func() -> void:
					_sold_relic_ids[offer_id] = true
					relic_purchased.emit(offer_id, price))
			"potion":
				buy_button.pressed.connect(func() -> void:
					_sold_potion_ids[offer_id] = true
					potion_purchased.emit(offer_id, price))

	return item


func _make_card_offer_item(offer: Dictionary) -> Control:
	var offer_id := String(offer.get("id", ""))
	var price := int(offer.get("price", 0))
	var rarity := String(offer.get("rarity", "common"))
	var border: Color = RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
	var sold := _sold_card_ids.has(offer_id)

	var item := PanelContainer.new()
	item.custom_minimum_size = Vector2(132, 178)
	item.add_theme_stylebox_override("panel", _offer_box(border))
	item.set_meta("offer_id", offer_id)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 5)
	item.add_child(box)

	var card_instance = CardInstanceScript.new()
	card_instance.setup(offer["card_data"], false)
	var card_view = CARD_VIEW_SCENE.instantiate()
	card_view.setup(card_instance, 99, sold)
	card_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not sold:
		card_view.card_selected.connect(func(_card) -> void:
			_sold_card_ids[offer_id] = true
			card_purchased.emit(offer_id, price))
	box.add_child(card_view)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 6)
	box.add_child(footer)

	var price_label := Label.new()
	price_label.text = _tr("shop.price", "%d gold") % price
	price_label.add_theme_font_size_override("font_size", 13)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.40, 0.32) if _gold < price else Color(1.0, 0.82, 0.32))
	footer.add_child(price_label)

	var buy_button := Button.new()
	buy_button.text = _tr("shop.buy", "Buy")
	buy_button.disabled = sold or _gold < price
	buy_button.custom_minimum_size = Vector2(52, 26)
	buy_button.pressed.connect(func() -> void:
		_sold_card_ids[offer_id] = true
		card_purchased.emit(offer_id, price))
	footer.add_child(buy_button)

	var description := String(offer.get("description", ""))
	if description != "":
		item.tooltip_text = description
	if sold:
		buy_button.text = _tr("shop.sold", "SOLD")
		_apply_sold_overlay(item)
	return item


func _apply_sold_overlay(item: Control) -> void:
	item.modulate = Color(0.55, 0.55, 0.55)
	var stamp_tex := _load_png_texture("res://art/generated/ui/sold_stamp.png")
	if stamp_tex != null:
		var stamp := TextureRect.new()
		stamp.texture = stamp_tex
		stamp.ignore_texture_size = true
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stamp.set_anchors_preset(Control.PRESET_CENTER)
		stamp.offset_left = -56
		stamp.offset_top = -28
		stamp.offset_right = 56
		stamp.offset_bottom = 28
		stamp.rotation = -0.18
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(stamp)
	else:
		var stamp := Label.new()
		stamp.text = _tr("shop.sold", "SOLD")
		stamp.add_theme_font_size_override("font_size", 26)
		stamp.add_theme_color_override("font_color", Color(0.95, 0.30, 0.20))
		stamp.set_anchors_preset(Control.PRESET_CENTER)
		stamp.offset_left = -40
		stamp.offset_top = -16
		stamp.offset_right = 40
		stamp.offset_bottom = 16
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(stamp)


func _on_remove_pressed() -> void:
	remove_card_requested.emit(0)


func _frame_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.96)
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


func _offer_box(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.085, 0.06, 0.94)
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _load_png_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)
