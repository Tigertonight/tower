extends Control

signal combat_reward_chosen(card_id: String, remaining_hp: int)
signal combat_reward_skipped(remaining_hp: int)
signal combat_lost
signal boss_defeated(remaining_hp: int)
signal reset_run_requested

const CardDataScript := preload("res://scripts/cards/card_data.gd")
const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")
const DeckManagerScript := preload("res://scripts/cards/deck_manager.gd")
const EffectResolverScript := preload("res://scripts/cards/effect_resolver.gd")
const EnemyInstanceScript := preload("res://scripts/combat/enemy_instance.gd")
const RelicManagerScript := preload("res://scripts/relics/relic_manager.gd")
const SaveManagerScript := preload("res://scripts/save/save_manager.gd")
const CARD_VIEW_SCENE := preload("res://scenes/combat/card_view.tscn")
const REWARD_SCREEN_SCENE := preload("res://scenes/ui/reward_screen.tscn")

var player_max_hp := 76
var player_hp := 76
var player_block := 0
var player_energy := 3
var base_energy := 3
var turn_number := 1
var player_statuses: Dictionary = {}

var enemy
var deck
var card_database: Dictionary = {}
var relic_database: Dictionary = {}
var relic_manager
var save_manager
var reward_pool: Array[String] = []
var run_deck_ids: Array[String] = []
var combats_won := 0
var configured_hp := 76
var configured_max_hp := 76
var configured_node_type := "combat"
var configured_title := "Combat"

var root_box: VBoxContainer
var top_bar: HBoxContainer
var battlefield: HBoxContainer
var bottom_bar: HBoxContainer
var energy_label: Label
var draw_pile_button: Button
var discard_pile_button: Button
var exhaust_pile_button: Button
var hand_box: HBoxContainer
var hand_frame: PanelContainer
var hand_section_label: Label
var log_label: Label
var combat_title_label: Label
var effect_layer: Control
var player_label: Label
var player_hp_bar: ProgressBar
var player_block_label: Label
var player_status_label: Label
var player_art_rect: TextureRect
var enemy_label: Label
var enemy_art_rect: TextureRect
var enemy_hp_bar: ProgressBar
var enemy_block_label: Label
var enemy_status_label: Label
var intent_label: Label
var turn_banner_label: Label
var piles_label: Label
var relics_label: Label
var end_turn_button: Button
var restart_button: Button
var reward_screen


func _ready() -> void:
	_build_ui()
	_create_card_database()
	_create_relic_database()
	_create_run_relics()
	save_manager = SaveManagerScript.new()
	_start_combat()


func configure(deck_ids: Array[String], current_hp: int, max_hp: int, node_type: String, combat_index: int, node_title: String = "") -> void:
	run_deck_ids = deck_ids.duplicate()
	configured_hp = current_hp
	configured_max_hp = max_hp
	configured_node_type = node_type
	combats_won = combat_index
	configured_title = node_title if node_title != "" else node_type.capitalize()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := TextureRect.new()
	background.texture = _load_png_texture("res://art/generated/backgrounds/living_archive_combat_floor.png")
	background.ignore_texture_size = true
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var bg_shade := ColorRect.new()
	bg_shade.color = Color(0.0, 0.0, 0.0, 0.40)
	bg_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_shade)

	var upper_warmth := ColorRect.new()
	upper_warmth.color = Color(0.20, 0.12, 0.055, 0.18)
	upper_warmth.set_anchors_preset(Control.PRESET_TOP_WIDE)
	upper_warmth.custom_minimum_size = Vector2(0, 132)
	add_child(upper_warmth)

	var stage_floor := ColorRect.new()
	stage_floor.color = Color(0.025, 0.030, 0.032, 0.48)
	stage_floor.anchor_left = 0.0
	stage_floor.anchor_top = 0.33
	stage_floor.anchor_right = 1.0
	stage_floor.anchor_bottom = 0.73
	add_child(stage_floor)

	root_box = VBoxContainer.new()
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", 7)
	root_box.offset_left = 18
	root_box.offset_top = 8
	root_box.offset_right = -18
	root_box.offset_bottom = -8
	add_child(root_box)

	top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 14)
	root_box.add_child(top_bar)

	combat_title_label = Label.new()
	combat_title_label.custom_minimum_size = Vector2(200, 40)
	combat_title_label.add_theme_font_size_override("font_size", 20)
	top_bar.add_child(combat_title_label)

	player_label = Label.new()
	player_label.custom_minimum_size = Vector2(210, 40)
	player_label.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(player_label)

	piles_label = Label.new()
	piles_label.custom_minimum_size = Vector2(270, 40)
	piles_label.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(piles_label)

	relics_label = Label.new()
	relics_label.custom_minimum_size = Vector2(220, 40)
	relics_label.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(relics_label)

	restart_button = Button.new()
	restart_button.text = "Reset Run"
	restart_button.custom_minimum_size = Vector2(110, 40)
	restart_button.pressed.connect(_reset_run)
	top_bar.add_child(restart_button)

	turn_banner_label = Label.new()
	turn_banner_label.text = "Player Turn"
	turn_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_banner_label.anchor_left = 0.18
	turn_banner_label.anchor_top = 0.043
	turn_banner_label.anchor_right = 0.82
	turn_banner_label.anchor_bottom = 0.043
	turn_banner_label.offset_left = 0
	turn_banner_label.offset_top = 0
	turn_banner_label.offset_right = 0
	turn_banner_label.offset_bottom = 28
	turn_banner_label.add_theme_font_size_override("font_size", 16)
	turn_banner_label.add_theme_stylebox_override("normal", _banner_box())
	add_child(turn_banner_label)

	battlefield = HBoxContainer.new()
	battlefield.custom_minimum_size = Vector2(0, 154)
	battlefield.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	battlefield.alignment = BoxContainer.ALIGNMENT_CENTER
	battlefield.add_theme_constant_override("separation", 58)
	root_box.add_child(battlefield)

	var player_panel := PanelContainer.new()
	player_panel.custom_minimum_size = Vector2(370, 150)
	player_panel.clip_contents = true
	player_panel.add_theme_stylebox_override("normal", _stage_box(Color(0.055, 0.075, 0.078, 0.78), Color(0.44, 0.58, 0.66)))
	battlefield.add_child(player_panel)

	var player_panel_box := VBoxContainer.new()
	player_panel_box.add_theme_constant_override("separation", 3)
	player_panel.add_child(player_panel_box)

	var player_title := Label.new()
	player_title.text = "Vanguard Archivist"
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_title.add_theme_font_size_override("font_size", 20)
	player_panel_box.add_child(player_title)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.custom_minimum_size = Vector2(0, 20)
	player_hp_bar.show_percentage = false
	player_panel_box.add_child(player_hp_bar)

	player_block_label = Label.new()
	player_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel_box.add_child(player_block_label)

	player_status_label = Label.new()
	player_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_status_label.add_theme_font_size_override("font_size", 13)
	player_panel_box.add_child(player_status_label)

	player_art_rect = TextureRect.new()
	player_art_rect.custom_minimum_size = Vector2(126, 42)
	player_art_rect.ignore_texture_size = true
	player_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_art_rect.texture = _load_png_texture("res://art/generated/sprites/vanguard_archivist.png")
	player_panel_box.add_child(player_art_rect)

	var player_hint := Label.new()
	player_hint.text = "Status: Ready"
	player_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_panel_box.add_child(player_hint)

	var enemy_panel := PanelContainer.new()
	enemy_panel.custom_minimum_size = Vector2(370, 150)
	enemy_panel.clip_contents = true
	enemy_panel.add_theme_stylebox_override("normal", _stage_box(Color(0.105, 0.055, 0.045, 0.78), Color(0.68, 0.34, 0.22)))
	battlefield.add_child(enemy_panel)

	var enemy_panel_box := VBoxContainer.new()
	enemy_panel_box.add_theme_constant_override("separation", 3)
	enemy_panel.add_child(enemy_panel_box)

	enemy_label = Label.new()
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.add_theme_font_size_override("font_size", 20)
	enemy_panel_box.add_child(enemy_label)

	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.custom_minimum_size = Vector2(0, 20)
	enemy_hp_bar.show_percentage = false
	enemy_panel_box.add_child(enemy_hp_bar)

	enemy_block_label = Label.new()
	enemy_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_panel_box.add_child(enemy_block_label)

	enemy_status_label = Label.new()
	enemy_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_status_label.add_theme_font_size_override("font_size", 13)
	enemy_panel_box.add_child(enemy_status_label)

	enemy_art_rect = TextureRect.new()
	enemy_art_rect.custom_minimum_size = Vector2(126, 42)
	enemy_art_rect.ignore_texture_size = true
	enemy_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_panel_box.add_child(enemy_art_rect)

	intent_label = Label.new()
	intent_label.custom_minimum_size = Vector2(0, 34)
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_label.add_theme_font_size_override("font_size", 18)
	enemy_panel_box.add_child(intent_label)

	log_label = Label.new()
	log_label.custom_minimum_size = Vector2(0, 26)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_font_size_override("font_size", 16)
	root_box.add_child(log_label)

	hand_section_label = Label.new()
	hand_section_label.text = "Hand"
	hand_section_label.add_theme_font_size_override("font_size", 16)
	root_box.add_child(hand_section_label)

	hand_frame = PanelContainer.new()
	hand_frame.custom_minimum_size = Vector2(0, 116)
	hand_frame.add_theme_stylebox_override("normal", _stage_box(Color(0.06, 0.065, 0.07, 0.86), Color(0.33, 0.27, 0.18)))
	root_box.add_child(hand_frame)

	var hand_center := CenterContainer.new()
	hand_frame.add_child(hand_center)

	hand_box = HBoxContainer.new()
	hand_box.custom_minimum_size = Vector2(0, 112)
	hand_box.add_theme_constant_override("separation", 10)
	hand_center.add_child(hand_box)

	bottom_bar = HBoxContainer.new()
	bottom_bar.add_theme_constant_override("separation", 12)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	root_box.add_child(bottom_bar)

	energy_label = Label.new()
	energy_label.custom_minimum_size = Vector2(76, 38)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_label.add_theme_stylebox_override("normal", _orb_box(Color(0.12, 0.28, 0.42), Color(0.45, 0.85, 1.0)))
	bottom_bar.add_child(energy_label)

	draw_pile_button = _make_pile_button("Draw")
	bottom_bar.add_child(draw_pile_button)

	discard_pile_button = _make_pile_button("Discard")
	bottom_bar.add_child(discard_pile_button)

	exhaust_pile_button = _make_pile_button("Exhaust")
	bottom_bar.add_child(exhaust_pile_button)

	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.custom_minimum_size = Vector2(150, 38)
	end_turn_button.add_theme_font_size_override("font_size", 18)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	bottom_bar.add_child(end_turn_button)

	var bottom_hint := Label.new()
	bottom_hint.text = "End turn discards hand. Empty draw reshuffles discard."
	bottom_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.add_child(bottom_hint)

	effect_layer = Control.new()
	effect_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(effect_layer)

	reward_screen = REWARD_SCREEN_SCENE.instantiate()
	reward_screen.card_chosen.connect(_on_reward_card_chosen)
	reward_screen.skipped.connect(_on_reward_skipped)
	add_child(reward_screen)

	root_box.visible = false
	_build_fixed_combat_layout()
	effect_layer.move_to_front()
	reward_screen.move_to_front()


func _build_fixed_combat_layout() -> void:
	if turn_banner_label != null:
		turn_banner_label.visible = false

	var hud := Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hud)

	var top_panel := PanelContainer.new()
	_pin(top_panel, 28, 8, 1252, 48)
	top_panel.add_theme_stylebox_override("normal", _stage_box(Color(0.045, 0.035, 0.026, 0.72), Color(0.58, 0.42, 0.18, 0.7)))
	hud.add_child(top_panel)

	top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 18)
	top_panel.add_child(top_bar)

	combat_title_label = Label.new()
	combat_title_label.custom_minimum_size = Vector2(190, 30)
	combat_title_label.add_theme_font_size_override("font_size", 20)
	top_bar.add_child(combat_title_label)

	player_label = Label.new()
	player_label.custom_minimum_size = Vector2(210, 30)
	player_label.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(player_label)

	piles_label = Label.new()
	piles_label.custom_minimum_size = Vector2(280, 30)
	piles_label.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(piles_label)

	relics_label = Label.new()
	relics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relics_label.add_theme_font_size_override("font_size", 17)
	top_bar.add_child(relics_label)

	restart_button = Button.new()
	restart_button.text = "Reset"
	restart_button.custom_minimum_size = Vector2(82, 30)
	restart_button.pressed.connect(_reset_run)
	top_bar.add_child(restart_button)

	turn_banner_label = Label.new()
	_pin(turn_banner_label, 460, 54, 820, 80)
	turn_banner_label.text = "Player Turn"
	turn_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_banner_label.add_theme_font_size_override("font_size", 16)
	turn_banner_label.add_theme_stylebox_override("normal", _banner_box())
	hud.add_child(turn_banner_label)

	var player_panel := PanelContainer.new()
	_pin(player_panel, 140, 118, 472, 334)
	player_panel.clip_contents = true
	player_panel.add_theme_stylebox_override("normal", _stage_box(Color(0.035, 0.052, 0.056, 0.62), Color(0.42, 0.62, 0.76)))
	hud.add_child(player_panel)

	var player_panel_box := VBoxContainer.new()
	player_panel_box.add_theme_constant_override("separation", 3)
	player_panel.add_child(player_panel_box)

	var player_title := Label.new()
	player_title.text = "Vanguard Archivist"
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_title.add_theme_font_size_override("font_size", 19)
	player_panel_box.add_child(player_title)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.custom_minimum_size = Vector2(0, 18)
	player_hp_bar.show_percentage = false
	player_panel_box.add_child(player_hp_bar)

	player_block_label = Label.new()
	player_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel_box.add_child(player_block_label)

	player_status_label = Label.new()
	player_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_status_label.add_theme_font_size_override("font_size", 12)
	player_panel_box.add_child(player_status_label)

	player_art_rect = TextureRect.new()
	player_art_rect.custom_minimum_size = Vector2(0, 92)
	player_art_rect.ignore_texture_size = true
	player_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_art_rect.texture = _load_png_texture("res://art/generated/sprites/vanguard_archivist.png")
	player_panel_box.add_child(player_art_rect)

	var enemy_panel := PanelContainer.new()
	_pin(enemy_panel, 812, 108, 1148, 338)
	enemy_panel.clip_contents = true
	enemy_panel.add_theme_stylebox_override("normal", _stage_box(Color(0.075, 0.040, 0.034, 0.64), Color(0.82, 0.32, 0.20)))
	hud.add_child(enemy_panel)

	var enemy_panel_box := VBoxContainer.new()
	enemy_panel_box.add_theme_constant_override("separation", 3)
	enemy_panel.add_child(enemy_panel_box)

	enemy_label = Label.new()
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.add_theme_font_size_override("font_size", 19)
	enemy_panel_box.add_child(enemy_label)

	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.custom_minimum_size = Vector2(0, 18)
	enemy_hp_bar.show_percentage = false
	enemy_panel_box.add_child(enemy_hp_bar)

	enemy_block_label = Label.new()
	enemy_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_panel_box.add_child(enemy_block_label)

	enemy_status_label = Label.new()
	enemy_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_status_label.add_theme_font_size_override("font_size", 12)
	enemy_panel_box.add_child(enemy_status_label)

	enemy_art_rect = TextureRect.new()
	enemy_art_rect.custom_minimum_size = Vector2(0, 82)
	enemy_art_rect.ignore_texture_size = true
	enemy_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_panel_box.add_child(enemy_art_rect)

	intent_label = Label.new()
	intent_label.custom_minimum_size = Vector2(0, 46)
	intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intent_label.add_theme_font_size_override("font_size", 17)
	enemy_panel_box.add_child(intent_label)

	log_label = Label.new()
	_pin(log_label, 48, 356, 620, 390)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_font_size_override("font_size", 16)
	log_label.add_theme_stylebox_override("normal", _stage_box(Color(0.025, 0.026, 0.024, 0.50), Color(0.35, 0.28, 0.16, 0.3)))
	hud.add_child(log_label)

	hand_section_label = Label.new()
	_pin(hand_section_label, 48, 400, 450, 424)
	hand_section_label.add_theme_font_size_override("font_size", 15)
	hud.add_child(hand_section_label)

	hand_frame = PanelContainer.new()
	_pin(hand_frame, 210, 430, 1164, 550)
	hand_frame.add_theme_stylebox_override("normal", _stage_box(Color(0.020, 0.022, 0.024, 0.62), Color(0.33, 0.27, 0.18, 0.55)))
	hud.add_child(hand_frame)

	var hand_center := CenterContainer.new()
	hand_frame.add_child(hand_center)

	hand_box = HBoxContainer.new()
	hand_box.custom_minimum_size = Vector2(0, 112)
	hand_box.add_theme_constant_override("separation", 14)
	hand_center.add_child(hand_box)

	energy_label = Label.new()
	_pin(energy_label, 44, 560, 132, 648)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_label.add_theme_font_size_override("font_size", 18)
	energy_label.add_theme_stylebox_override("normal", _orb_box(Color(0.12, 0.28, 0.42), Color(0.45, 0.85, 1.0)))
	hud.add_child(energy_label)

	draw_pile_button = _make_pile_button("Draw")
	_pin(draw_pile_button, 156, 574, 250, 632)
	hud.add_child(draw_pile_button)

	discard_pile_button = _make_pile_button("Discard")
	_pin(discard_pile_button, 268, 574, 378, 632)
	hud.add_child(discard_pile_button)

	exhaust_pile_button = _make_pile_button("Exhaust")
	_pin(exhaust_pile_button, 396, 574, 506, 632)
	hud.add_child(exhaust_pile_button)

	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.add_theme_font_size_override("font_size", 20)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	_pin(end_turn_button, 1028, 574, 1192, 632)
	hud.add_child(end_turn_button)


func _pin(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom


func _make_pile_button(label_text: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(84, 38)
	button.text = label_text
	button.add_theme_font_size_override("font_size", 16)
	button.tooltip_text = "%s pile count" % label_text
	button.add_theme_stylebox_override("normal", _pile_box())
	button.add_theme_stylebox_override("hover", _pile_box(Color(0.20, 0.17, 0.12), Color(0.82, 0.62, 0.30)))
	return button


func _stage_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _orb_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(3)
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _pile_box(bg: Color = Color(0.12, 0.11, 0.10), border: Color = Color(0.42, 0.34, 0.22)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _banner_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.075, 0.04, 0.72)
	style.border_color = Color(0.52, 0.38, 0.18, 0.76)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _create_card_database() -> void:
	card_database.clear()
	_load_card("res://data/cards/strike_form.tres")
	_load_card("res://data/cards/guard_form.tres")
	_load_card("res://data/cards/archive_bash.tres")
	_load_card("res://data/cards/quick_read.tres")
	_load_card("res://data/cards/forward_step.tres")
	_load_card("res://data/cards/measured_cut.tres")
	_load_card("res://data/cards/brace.tres")
	_load_card("res://data/cards/shield_tap.tres")
	_load_card("res://data/cards/break_rhythm.tres")
	_load_card("res://data/cards/oath_pressure.tres")
	reward_pool = ["measured_cut", "brace", "shield_tap", "quick_read", "forward_step", "break_rhythm", "oath_pressure"]


func _load_card(path: String) -> void:
	var card = load(path)
	if card == null:
		push_error("Failed to load card data: %s" % path)
		return
	card_database[card.id] = card


func _create_relic_database() -> void:
	relic_database.clear()
	_load_relic("res://data/relics/sealed_badge.tres")


func _load_relic(path: String) -> void:
	var relic = load(path)
	if relic == null:
		push_error("Failed to load relic data: %s" % path)
		return
	relic_database[relic.id] = relic


func _create_run_relics() -> void:
	relic_manager = RelicManagerScript.new()
	relic_manager.setup([relic_database["sealed_badge"]])


func _load_run_state() -> void:
	var data: Dictionary = save_manager.load_run()
	if data.is_empty():
		return
	run_deck_ids.clear()
	for card_id in data.get("run_deck_ids", []):
		if card_database.has(String(card_id)):
			run_deck_ids.append(String(card_id))
	combats_won = int(data.get("combats_won", 0))


func _save_run_state() -> void:
	save_manager.save_run({
		"version": 1,
		"run_deck_ids": run_deck_ids,
		"combats_won": combats_won
	})


func _reset_run() -> void:
	reset_run_requested.emit()


func _start_combat() -> void:
	if run_deck_ids.is_empty():
		run_deck_ids = _create_starter_deck_ids()
	if reward_screen != null:
		reward_screen.hide_rewards()
	player_max_hp = configured_max_hp
	player_hp = configured_hp
	player_block = 0
	player_energy = base_energy
	turn_number = 1
	player_statuses.clear()
	enemy = EnemyInstanceScript.new()
	enemy.max_hp += combats_won * 6
	if configured_node_type == "elite":
		enemy.display_name = "Index Knight"
		enemy.max_hp += 16
		enemy.intent_damage += 3
	elif configured_node_type == "boss":
		enemy.display_name = "The Sealed Curator"
		enemy.max_hp += 40
		enemy.intent_damage += 5
	enemy.hp = enemy.max_hp
	enemy.intent_damage += combats_won
	deck = DeckManagerScript.new()
	deck.setup(_create_deck_from_ids(run_deck_ids))
	enemy.choose_intent(turn_number)
	_update_enemy_art()
	deck.draw_cards(5)
	_set_log("%s rises from the archive floor." % enemy.display_name)
	_update_ui()


func _create_starter_deck_ids() -> Array[String]:
	var ids: Array[String] = []
	for i in 5:
		ids.append("strike_form")
	for i in 4:
		ids.append("guard_form")
	ids.append("archive_bash")
	ids.append("quick_read")
	ids.append("forward_step")
	return ids


func _create_deck_from_ids(card_ids: Array[String]) -> Array:
	var cards: Array = []
	for entry in card_ids:
		cards.append(_make_card(entry))
	return cards


func _make_card(card_entry: String):
	var upgraded := card_entry.ends_with("+")
	var card_id := card_entry.trim_suffix("+")
	var card = CardInstanceScript.new()
	card.setup(card_database[card_id], upgraded)
	return card


func _on_card_pressed(card) -> void:
	if enemy.is_dead() or player_hp <= 0 or (reward_screen != null and reward_screen.visible):
		return
	if card.get_cost() > player_energy:
		_set_log("Not enough energy for %s." % card.get_display_name())
		return

	player_energy -= card.get_cost()
	_spawn_card_play_effect(card)
	var target = enemy
	var had_damage_effect := false
	for effect in card.get_effects():
		if String(effect.get("type", "")) == "damage":
			had_damage_effect = true
		EffectResolverScript.resolve(effect, self, self, target)
	deck.discard(card)
	_set_log("Played %s." % card.get_display_name())
	if had_damage_effect:
		_spawn_slash_effect()
	else:
		_spawn_focus_effect()
	_tick_statuses_after_card()
	_check_combat_end()
	_update_ui()


func _on_end_turn_pressed() -> void:
	if enemy.is_dead() or player_hp <= 0 or (reward_screen != null and reward_screen.visible):
		return
	deck.discard_hand()
	_show_turn_banner("Enemy Turn")
	_resolve_enemy_turn()
	if player_hp <= 0:
		_set_log("Defeat. The archive closes around the fallen vanguard.")
		_update_ui()
		combat_lost.emit()
		return
	_start_player_turn()


func _start_player_turn() -> void:
	turn_number += 1
	_show_turn_banner("Player Turn %d" % turn_number)
	player_block = 0
	player_energy = base_energy
	_decay_statuses(player_statuses)
	_decay_statuses(enemy.statuses)
	enemy.choose_intent(turn_number)
	deck.draw_cards(5)
	_set_log("Turn %d. Draw, guard, decide." % turn_number)
	_update_ui()


func _resolve_enemy_turn() -> void:
	if enemy.intent_type == "defend":
		enemy.block += enemy.intent_block
		_set_log("%s braces for %d block." % [enemy.display_name, enemy.intent_block])
		return
	var damage: int = enemy.intent_damage
	if int(enemy.statuses.get("weak", 0)) > 0:
		damage = floori(float(damage) * 0.75)
	_take_player_damage(damage)
	_set_log("%s attacks for %d." % [enemy.display_name, damage])


func deal_damage(target, amount: int) -> void:
	var damage: int = amount + int(player_statuses.get("strength", 0))
	if int(target.statuses.get("vulnerable", 0)) > 0:
		damage = floori(float(damage) * 1.5)
	var blocked: int = min(target.block, damage)
	target.block -= blocked
	damage -= blocked
	target.hp = max(0, target.hp - damage)
	if damage > 0:
		_spawn_float_text("-%d" % damage, Vector2(880, 270), Color(1.0, 0.36, 0.22))


func gain_player_block(amount: int) -> void:
	player_block += amount
	_spawn_float_text("+%d Block" % amount, Vector2(210, 280), Color(0.45, 0.72, 1.0))


func draw_cards(amount: int) -> void:
	deck.draw_cards(amount)
	_spawn_float_text("Draw %d" % amount, Vector2(560, 610), Color(0.95, 0.83, 0.45))


func gain_energy(amount: int) -> void:
	player_energy += amount


func heal_player(amount: int) -> void:
	player_hp = min(player_max_hp, player_hp + amount)


func apply_status(target: Variant, status: String, amount: int) -> void:
	if status == "" or amount <= 0:
		return
	var statuses: Dictionary = player_statuses if target == self else target.statuses
	statuses[status] = int(statuses.get(status, 0)) + amount


func _take_player_damage(amount: int) -> void:
	var damage: int = amount
	var blocked: int = min(player_block, damage)
	player_block -= blocked
	damage -= blocked
	player_hp = max(0, player_hp - damage)
	if damage > 0:
		_spawn_float_text("-%d" % damage, Vector2(220, 260), Color(1.0, 0.26, 0.22))


func _tick_statuses_after_card() -> void:
	pass


func _decay_statuses(statuses: Dictionary) -> void:
	for key in statuses.keys():
		if key == "strength":
			continue
		statuses[key] = max(0, int(statuses[key]) - 1)


func _check_combat_end() -> void:
	if enemy.is_dead():
		combats_won += 1
		relic_manager.trigger("combat_victory", self)
		if configured_node_type == "boss":
			_show_turn_banner("Victory")
			_set_log("Victory. The Sealed Curator yields the archive key.")
			boss_defeated.emit(player_hp)
		else:
			_show_turn_banner("Victory")
			_set_log("Victory. The page-thing collapses into quiet dust.")
			_show_card_rewards()


func _show_card_rewards() -> void:
	var reward_ids := reward_pool.duplicate()
	reward_ids.shuffle()
	var cards: Array = []
	for i in min(3, reward_ids.size()):
		cards.append(card_database[reward_ids[i]])
	reward_screen.show_rewards(cards)


func _on_reward_card_chosen(card_id: String) -> void:
	run_deck_ids.append(card_id)
	_set_log("Added %s to the deck." % card_database[card_id].display_name)
	combat_reward_chosen.emit(card_id, player_hp)


func _on_reward_skipped() -> void:
	_set_log("Skipped card reward.")
	combat_reward_skipped.emit(player_hp)


func _update_ui() -> void:
	combat_title_label.text = configured_title
	player_label.text = "HP %d/%d    Block %d    Energy %d/%d" % [player_hp, player_max_hp, player_block, player_energy, base_energy]
	piles_label.text = "Draw %d    Hand %d    Discard %d    Exhaust %d" % [deck.draw_pile.size(), deck.hand.size(), deck.discard_pile.size(), deck.exhaust_pile.size()]
	relics_label.text = relic_manager.get_display_text()
	enemy_label.text = "%s\nHP %d/%d    Block %d\n%s" % [enemy.display_name, enemy.hp, enemy.max_hp, enemy.block, enemy.get_status_text()]
	enemy_label.tooltip_text = "Statuses: %s" % (enemy.get_status_text() if enemy.get_status_text() != "" else "none")
	player_label.tooltip_text = "Player statuses: %s" % (_status_text(player_statuses) if _status_text(player_statuses) != "" else "none")
	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp
	player_block_label.text = "Block: %d    Energy: %d/%d" % [player_block, player_energy, base_energy]
	player_status_label.text = _status_icons(player_statuses)
	enemy_hp_bar.max_value = enemy.max_hp
	enemy_hp_bar.value = enemy.hp
	enemy_block_label.text = "Block: %d" % enemy.block
	enemy_status_label.text = _status_icons(enemy.statuses)
	energy_label.text = "ENERGY\n%d/%d" % [player_energy, base_energy]
	draw_pile_button.text = "Draw\n%d" % deck.draw_pile.size()
	discard_pile_button.text = "Discard\n%d" % deck.discard_pile.size()
	exhaust_pile_button.text = "Exhaust\n%d" % deck.exhaust_pile.size()
	intent_label.text = _intent_display_text()
	_style_intent_badge()
	end_turn_button.disabled = enemy.is_dead() or player_hp <= 0
	hand_section_label.text = "Hand - click a card to play it. Energy left: %d" % player_energy

	for child in hand_box.get_children():
		child.queue_free()

	for card in deck.hand:
		var card_view = CARD_VIEW_SCENE.instantiate()
		card_view.setup(card, player_energy, enemy.is_dead() or player_hp <= 0)
		card_view.card_selected.connect(_on_card_pressed)
		hand_box.add_child(card_view)


func _update_enemy_art() -> void:
	if enemy_art_rect == null:
		return
	if configured_node_type == "boss":
		enemy_art_rect.texture = _load_png_texture("res://art/generated/sprites/sealed_curator.png")
	elif configured_node_type == "elite":
		enemy_art_rect.texture = _load_png_texture("res://art/generated/sprites/sealed_curator.png")
	else:
		enemy_art_rect.texture = _load_png_texture("res://art/generated/sprites/dust_scribe.png")


func _style_intent_badge() -> void:
	var bg := Color(0.20, 0.12, 0.10)
	var border := Color(0.85, 0.32, 0.22)
	if enemy.intent_type == "defend":
		bg = Color(0.10, 0.16, 0.20)
		border = Color(0.35, 0.62, 0.92)
	elif enemy.intent_type == "heavy_attack":
		bg = Color(0.24, 0.08, 0.06)
		border = Color(1.0, 0.24, 0.18)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	intent_label.add_theme_stylebox_override("normal", style)


func _intent_display_text() -> String:
	match enemy.intent_type:
		"defend":
			return "WARD\nBlock %d" % enemy.intent_block
		"heavy_attack":
			return "!!\nHeavy Attack %d" % enemy.intent_damage
		_:
			return "!\nAttack %d" % enemy.intent_damage


func _show_turn_banner(text_value: String) -> void:
	if turn_banner_label == null:
		return
	turn_banner_label.text = text_value
	turn_banner_label.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(turn_banner_label, "modulate:a", 1.0, 0.12)
	tween.tween_interval(0.42)
	tween.tween_property(turn_banner_label, "modulate:a", 0.72, 0.25)


func _set_log(message: String) -> void:
	if log_label != null:
		log_label.text = message


func _status_text(statuses: Dictionary) -> String:
	var parts: Array[String] = []
	for key in statuses.keys():
		if int(statuses[key]) > 0:
			parts.append("%s:%d" % [key, int(statuses[key])])
	return " ".join(parts)


func _status_icons(statuses: Dictionary) -> String:
	var parts: Array[String] = []
	if int(statuses.get("strength", 0)) > 0:
		parts.append("STR %d" % int(statuses["strength"]))
	if int(statuses.get("vulnerable", 0)) > 0:
		parts.append("VUL %d" % int(statuses["vulnerable"]))
	if int(statuses.get("weak", 0)) > 0:
		parts.append("WEAK %d" % int(statuses["weak"]))
	if parts.is_empty():
		return ""
	return "  ".join(parts)


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Failed to load image: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _spawn_slash_effect() -> void:
	var slash := ColorRect.new()
	slash.color = Color(1.0, 0.82, 0.38, 0.72)
	slash.custom_minimum_size = Vector2(160, 12)
	slash.position = Vector2(820, 250)
	slash.rotation = -0.35
	effect_layer.add_child(slash)
	var tween := create_tween()
	tween.tween_property(slash, "position", Vector2(940, 210), 0.18)
	tween.parallel().tween_property(slash, "modulate:a", 0.0, 0.22)
	tween.tween_callback(slash.queue_free)


func _spawn_focus_effect() -> void:
	var pulse := ColorRect.new()
	pulse.color = Color(0.35, 0.70, 1.0, 0.28)
	pulse.custom_minimum_size = Vector2(130, 10)
	pulse.position = Vector2(330, 244)
	pulse.rotation = 0.1
	effect_layer.add_child(pulse)
	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector2(1.6, 1.0), 0.20)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.25)
	tween.tween_callback(pulse.queue_free)


func _spawn_card_play_effect(card_instance) -> void:
	if effect_layer == null:
		return
	var ghost := PanelContainer.new()
	ghost.custom_minimum_size = Vector2(118, 44)
	ghost.position = Vector2(572, 560)
	ghost.modulate = Color(1, 1, 1, 0.92)
	ghost.add_theme_stylebox_override("normal", _pile_box(Color(0.18, 0.13, 0.08), Color(0.96, 0.68, 0.28)))
	effect_layer.add_child(ghost)
	var label := Label.new()
	label.text = card_instance.get_display_name()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	ghost.add_child(label)
	var tween := create_tween()
	tween.tween_property(ghost, "position", Vector2(612, 380), 0.20)
	tween.parallel().tween_property(ghost, "scale", Vector2(0.78, 0.78), 0.20)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.14)
	tween.tween_callback(ghost.queue_free)


func _spawn_float_text(text_value: String, position: Vector2, color: Color) -> void:
	if effect_layer == null:
		return
	var label := Label.new()
	label.text = text_value
	label.position = position
	label.modulate = color
	effect_layer.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", position + Vector2(0, -42), 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(label.queue_free)
