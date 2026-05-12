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
const EnemyCatalogScript := preload("res://scripts/combat/enemy_catalog.gd")
const RelicManagerScript := preload("res://scripts/relics/relic_manager.gd")
const SaveManagerScript := preload("res://scripts/save/save_manager.gd")
const CARD_VIEW_SCENE := preload("res://scenes/combat/card_view.tscn")
const REWARD_SCREEN_SCENE := preload("res://scenes/ui/reward_screen.tscn")
const ActionQueueScript := preload("res://scripts/combat/action_queue.gd")
const CardInspectorScript := preload("res://scripts/ui/card_inspector.gd")
const PileModalScript := preload("res://scripts/ui/pile_modal.gd")
const DeckModalScript := preload("res://scripts/ui/deck_modal.gd")
const ToastLayerScript := preload("res://scripts/ui/toast_layer.gd")
const AscensionConfigScript := preload("res://scripts/core/ascension_config.gd")
const KeywordCatalogScript := preload("res://scripts/core/keyword_catalog.gd")

var player_max_hp := 76
var player_hp := 76
var player_block := 0
var player_energy := 3
var base_energy := 3
var turn_number := 1
var player_statuses: Dictionary = {}

var enemy  # Always points at the currently-targeted alive enemy (for legacy
		   # callers / tests / single-enemy code paths). Refreshed via
		   # _select_first_alive_target() whenever the lineup changes.
var enemies: Array = []  # All enemies in the current combat (1+).
var target_index: int = 0  # Index into `enemies` of the currently-selected target.
var deck
var card_database: Dictionary = {}
var enemy_database: Dictionary = {}
var enemy_move_database: Dictionary = {}
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
var configured_encounter_id := ""
var configured_relic_ids: Array[String] = ["sealed_badge"]
var ascension_level: int = 0
var combat_rng := RandomNumberGenerator.new()

var root_box: VBoxContainer
var top_bar: HBoxContainer
var battlefield: HBoxContainer
var bottom_bar: HBoxContainer
var energy_label: Label
var draw_pile_button: Button
var discard_pile_button: Button
var exhaust_pile_button: Button
var hand_box: Control
var hand_frame: PanelContainer
var hand_section_label: Label
var log_label: Label
var combat_title_label: Label
var effect_layer: Control
var player_label: Label
var player_hp_bar: ProgressBar
var player_block_label: Label
var player_status_label: Label
var player_status_icons: HBoxContainer
var player_art_rect: TextureRect
var enemy_label: Label
var enemy_art_rect: TextureRect
var enemy_hp_bar: ProgressBar
var enemy_block_label: Label
var enemy_status_label: Label
var enemy_status_icons: HBoxContainer
var intent_label: Label
var intent_icon_rect: TextureRect
var phase_marker_rect: TextureRect
# Multi-enemy battlefield layout. The fixed combat HUD now hosts a row of
# enemy panels rather than a single one; the legacy `enemy_*` vars above are
# updated to point at whichever panel is currently targeted (so per-target
# tweens / flashes / intent pulses keep working without per-call branches).
var enemy_row: HBoxContainer
var enemy_panels: Array = []  # One Dictionary per enemy, see _build_enemy_panel().
var combat_hud: Control
var energy_orb_rect: TextureRect
var turn_banner_label: Label
var piles_label: Label
var relics_label: Label
var relics_icon_row: HBoxContainer
var end_turn_button: Button
var restart_button: Button
var deck_summary_button: Button
var reward_screen
var action_queue
var card_inspector
var pile_modal
var deck_modal
var toast_layer
var fast_resolve: bool = false
# A1.8 — when true and `combats_won == 0`, the first combat schedules a small
# series of toast-driven tutorial hints over the opening turn.
var tutorial_hints_enabled: bool = true
var _animating: bool = false


func _audio():
	# Returns the global AudioManager autoload, or null if unavailable
	# (e.g. headless smoke tests where the autoload isn't registered).
	return get_node_or_null("/root/AudioManager")


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


func refresh_language() -> void:
	_update_ui()


func _ready() -> void:
	_build_ui()
	_create_card_database()
	_create_enemy_database()
	_create_relic_database()
	_create_run_relics()
	save_manager = SaveManagerScript.new()
	_start_combat()


func configure(deck_ids: Array[String], current_hp: int, max_hp: int, node_type: String, combat_index: int, node_title: String = "", encounter_id: String = "", rng_seed: int = 1, relic_ids: Array[String] = [], ascension: int = 0) -> void:
	run_deck_ids = deck_ids.duplicate()
	configured_hp = current_hp
	configured_max_hp = max_hp
	configured_node_type = node_type
	combats_won = combat_index
	configured_title = node_title if node_title != "" else node_type.capitalize()
	configured_encounter_id = encounter_id
	configured_relic_ids = relic_ids.duplicate()
	if configured_relic_ids.is_empty():
		configured_relic_ids = ["sealed_badge"]
	ascension_level = AscensionConfigScript.clamp_level(ascension)
	combat_rng.seed = rng_seed
	combat_rng.state = rng_seed


func get_combat_rng_state() -> int:
	return combat_rng.state


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
	relics_label.custom_minimum_size = Vector2(80, 40)
	relics_label.add_theme_font_size_override("font_size", 17)
	relics_label.text = _tr("combat.relics", "Relics:")
	top_bar.add_child(relics_label)

	relics_icon_row = HBoxContainer.new()
	relics_icon_row.add_theme_constant_override("separation", 4)
	relics_icon_row.custom_minimum_size = Vector2(160, 40)
	top_bar.add_child(relics_icon_row)

	restart_button = Button.new()
	restart_button.text = _tr("combat.reset", "Reset Run")
	restart_button.custom_minimum_size = Vector2(110, 40)
	restart_button.pressed.connect(_reset_run)
	top_bar.add_child(restart_button)

	turn_banner_label = Label.new()
	turn_banner_label.text = _tr("combat.player_turn", "Player Turn")
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
	player_title.text = _tr("combat.player_name", "Vanguard Archivist")
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
	player_art_rect.texture = _load_character_texture("res://art/generated/sprites/vanguard_archivist.png")
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
	_build_overlay_components()
	effect_layer.move_to_front()
	reward_screen.move_to_front()
	if pile_modal != null:
		pile_modal.move_to_front()
	if deck_modal != null:
		deck_modal.move_to_front()
	if card_inspector != null:
		card_inspector.move_to_front()
	if toast_layer != null:
		toast_layer.move_to_front()


func _build_overlay_components() -> void:
	action_queue = ActionQueueScript.new()
	action_queue.name = "ActionQueue"
	action_queue.fast_resolve = fast_resolve
	add_child(action_queue)

	card_inspector = CardInspectorScript.new()
	card_inspector.name = "CardInspector"
	card_inspector.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_inspector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_inspector)

	pile_modal = PileModalScript.new()
	pile_modal.name = "PileModal"
	add_child(pile_modal)

	deck_modal = DeckModalScript.new()
	deck_modal.name = "DeckModal"
	add_child(deck_modal)

	toast_layer = ToastLayerScript.new()
	toast_layer.name = "ToastLayer"
	toast_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_layer)

	if draw_pile_button != null:
		draw_pile_button.pressed.connect(_on_draw_pile_pressed)
	if discard_pile_button != null:
		discard_pile_button.pressed.connect(_on_discard_pile_pressed)
	if exhaust_pile_button != null:
		exhaust_pile_button.pressed.connect(_on_exhaust_pile_pressed)
	if deck_summary_button != null:
		deck_summary_button.pressed.connect(_on_deck_summary_pressed)


func set_fast_resolve(enabled: bool) -> void:
	fast_resolve = enabled
	if action_queue != null:
		action_queue.fast_resolve = enabled


func set_tutorial_hints_enabled(enabled: bool) -> void:
	tutorial_hints_enabled = enabled


# A1.8 — fires a small sequence of intro toasts on the very first combat of a
# run (combats_won == 0). No-op when disabled in settings, on later combats, or
# under fast_resolve (smoke tests / replays).
func _maybe_play_tutorial_hints() -> void:
	if not tutorial_hints_enabled:
		return
	if combats_won != 0:
		return
	if fast_resolve:
		return
	var lines := [
		{"text": "Tip: hover any card to see full details and keywords.", "color": Color(0.95, 0.86, 0.55), "delay": 1.2},
		{"text": "Tip: click an enemy panel to switch your target.", "color": Color(0.85, 0.78, 0.95), "delay": 4.0},
		{"text": "Tip: End Turn keeps Strength/Dex; Block resets each turn.", "color": Color(0.82, 0.94, 0.85), "delay": 7.0},
		{"text": "Tip: ESC opens pause / settings.", "color": Color(0.94, 0.86, 0.72), "delay": 10.0},
	]
	for entry in lines:
		var t := get_tree().create_timer(float(entry["delay"]))
		# Capture by-value so each timer pushes its own line.
		var line_text: String = String(entry["text"])
		var line_color: Color = entry["color"]
		t.timeout.connect(func() -> void:
			if is_instance_valid(self):
				_push_toast(line_text, line_color)
		)


func _on_draw_pile_pressed() -> void:
	if pile_modal == null or deck == null:
		return
	if card_inspector != null:
		card_inspector.hide_card(null)
	pile_modal.show_pile(_tr("modal.draw_pile", "Draw Pile (%d)") % deck.draw_pile.size(), deck.draw_pile)
	pile_modal.move_to_front()


func _on_discard_pile_pressed() -> void:
	if pile_modal == null or deck == null:
		return
	if card_inspector != null:
		card_inspector.hide_card(null)
	pile_modal.show_pile(_tr("modal.discard_pile", "Discard Pile (%d)") % deck.discard_pile.size(), deck.discard_pile)
	pile_modal.move_to_front()


func _on_exhaust_pile_pressed() -> void:
	if pile_modal == null or deck == null:
		return
	if card_inspector != null:
		card_inspector.hide_card(null)
	pile_modal.show_pile(_tr("modal.exhaust_pile", "Exhaust Pile (%d)") % deck.exhaust_pile.size(), deck.exhaust_pile)
	pile_modal.move_to_front()


func _on_deck_summary_pressed() -> void:
	if deck_modal == null or deck == null:
		return
	if card_inspector != null:
		card_inspector.hide_card(null)
	var all_cards: Array = []
	all_cards.append_array(deck.draw_pile)
	all_cards.append_array(deck.hand)
	all_cards.append_array(deck.discard_pile)
	all_cards.append_array(deck.exhaust_pile)
	deck_modal.show_deck(_tr("modal.run_deck", "Run Deck"), all_cards)
	deck_modal.move_to_front()


func _build_fixed_combat_layout() -> void:
	if turn_banner_label != null:
		turn_banner_label.visible = false

	var hud := Control.new()
	combat_hud = hud
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
	relics_label.add_theme_font_size_override("font_size", 17)
	relics_label.text = _tr("combat.relics", "Relics:")
	top_bar.add_child(relics_label)

	relics_icon_row = HBoxContainer.new()
	relics_icon_row.add_theme_constant_override("separation", 4)
	relics_icon_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(relics_icon_row)

	restart_button = Button.new()
	restart_button.text = _tr("combat.reset", "Reset")
	restart_button.custom_minimum_size = Vector2(82, 30)
	restart_button.pressed.connect(_reset_run)
	top_bar.add_child(restart_button)

	turn_banner_label = Label.new()
	_pin(turn_banner_label, 460, 54, 820, 80)
	turn_banner_label.text = _tr("combat.player_turn", "Player Turn")
	turn_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_banner_label.add_theme_font_size_override("font_size", 16)
	turn_banner_label.add_theme_stylebox_override("normal", _banner_box())
	hud.add_child(turn_banner_label)

	var player_panel := PanelContainer.new()
	_pin(player_panel, 82, 78, 540, 394)
	player_panel.clip_contents = true
	player_panel.add_theme_stylebox_override("normal", _stage_box(Color(0.035, 0.052, 0.056, 0.62), Color(0.42, 0.62, 0.76)))
	hud.add_child(player_panel)

	var player_panel_box := VBoxContainer.new()
	player_panel_box.add_theme_constant_override("separation", 3)
	player_panel.add_child(player_panel_box)

	var player_title := Label.new()
	player_title.text = _tr("combat.player_name", "Vanguard Archivist")
	player_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_title.add_theme_font_size_override("font_size", 21)
	player_panel_box.add_child(player_title)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.custom_minimum_size = Vector2(0, 18)
	player_hp_bar.show_percentage = false
	player_panel_box.add_child(player_hp_bar)

	player_block_label = Label.new()
	player_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_block_label.mouse_filter = Control.MOUSE_FILTER_STOP
	player_block_label.tooltip_text = KeywordCatalogScript.describe("block")
	player_panel_box.add_child(player_block_label)

	player_status_label = Label.new()
	player_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_status_label.add_theme_font_size_override("font_size", 12)
	player_panel_box.add_child(player_status_label)

	player_status_icons = HBoxContainer.new()
	player_status_icons.alignment = BoxContainer.ALIGNMENT_CENTER
	player_status_icons.custom_minimum_size = Vector2(0, 22)
	player_status_icons.add_theme_constant_override("separation", 4)
	player_panel_box.add_child(player_status_icons)

	player_art_rect = TextureRect.new()
	player_art_rect.custom_minimum_size = Vector2(0, 188)
	player_art_rect.ignore_texture_size = true
	player_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_art_rect.texture = _load_character_texture("res://art/generated/sprites/vanguard_archivist.png")
	player_panel_box.add_child(player_art_rect)

	# A row of enemy panels — one per alive enemy. Filled in
	# `_rebuild_enemy_panels()` once `enemies` is populated by `_start_combat`.
	# Until then we leave it empty; legacy single-enemy var pointers (enemy_label,
	# enemy_hp_bar, enemy_art_rect, intent_label, etc.) are repointed at the
	# currently-targeted panel each refresh so existing code paths keep working.
	enemy_row = HBoxContainer.new()
	_pin(enemy_row, 608, 66, 1256, 404)
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.add_theme_constant_override("separation", 8)
	hud.add_child(enemy_row)
	enemy_panels.clear()

	log_label = Label.new()
	# The combat log is now a quiet last-line breadcrumb beneath the stage; the
	# real running narration lives in the toast layer. Keep it slim and dim.
	_pin(log_label, 48, 382, 620, 404)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_font_size_override("font_size", 12)
	log_label.add_theme_color_override("font_color", Color(0.78, 0.70, 0.56, 0.78))
	log_label.add_theme_stylebox_override("normal", _stage_box(Color(0.025, 0.026, 0.024, 0.30), Color(0.35, 0.28, 0.16, 0.18)))
	hud.add_child(log_label)

	hand_section_label = Label.new()
	_pin(hand_section_label, 48, 404, 520, 428)
	hand_section_label.add_theme_font_size_override("font_size", 15)
	hud.add_child(hand_section_label)

	hand_frame = PanelContainer.new()
	_pin(hand_frame, 170, 416, 1210, 622)
	hand_frame.add_theme_stylebox_override("normal", _stage_box(Color(0.020, 0.022, 0.024, 0.34), Color(0.33, 0.27, 0.18, 0.36)))
	hud.add_child(hand_frame)

	hand_box = Control.new()
	hand_box.clip_contents = false
	hand_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	hand_frame.add_child(hand_box)

	energy_orb_rect = TextureRect.new()
	energy_orb_rect.texture = _load_png_texture("res://art/generated/ui/energy_orb.png")
	energy_orb_rect.ignore_texture_size = true
	energy_orb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	energy_orb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	energy_orb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_orb_rect.modulate = Color(1, 1, 1, 0.72)
	_pin(energy_orb_rect, 34, 594, 136, 696)
	hud.add_child(energy_orb_rect)

	energy_label = Label.new()
	_pin(energy_label, 42, 602, 128, 688)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_label.add_theme_font_size_override("font_size", 18)
	energy_label.add_theme_stylebox_override("normal", _orb_box(Color(0.12, 0.28, 0.42), Color(0.45, 0.85, 1.0)))
	energy_label.mouse_filter = Control.MOUSE_FILTER_STOP
	energy_label.tooltip_text = KeywordCatalogScript.describe("energy")
	hud.add_child(energy_label)

	draw_pile_button = _make_pile_button("Draw")
	_pin(draw_pile_button, 150, 628, 244, 686)
	hud.add_child(draw_pile_button)

	discard_pile_button = _make_pile_button("Discard")
	_pin(discard_pile_button, 262, 628, 372, 686)
	hud.add_child(discard_pile_button)

	exhaust_pile_button = _make_pile_button("Exhaust")
	_pin(exhaust_pile_button, 390, 628, 500, 686)
	hud.add_child(exhaust_pile_button)

	end_turn_button = Button.new()
	end_turn_button.text = _tr("combat.end_turn", "End Turn")
	end_turn_button.add_theme_font_size_override("font_size", 20)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	_pin(end_turn_button, 1028, 628, 1192, 688)
	hud.add_child(end_turn_button)

	# Deck-summary capsule. Replaces the lone "deck count" string in the top bar
	# and opens DeckModal on click.
	deck_summary_button = Button.new()
	deck_summary_button.text = _tr("select.deck", "Deck")
	deck_summary_button.add_theme_font_size_override("font_size", 14)
	deck_summary_button.add_theme_stylebox_override("normal", _capsule_box())
	deck_summary_button.add_theme_stylebox_override("hover", _capsule_box(Color(0.20, 0.17, 0.12), Color(0.92, 0.74, 0.36)))
	_pin(deck_summary_button, 524, 628, 718, 686)
	hud.add_child(deck_summary_button)

	# Fast-resolve toggle. Default OFF. When ON, ActionQueue collapses waits to
	# zero and HP / Block bars jump to their targets — useful for demos and
	# regression tests.
	var fast_button := CheckButton.new()
	fast_button.text = _tr("combat.fast", "Fast")
	fast_button.button_pressed = fast_resolve
	fast_button.add_theme_font_size_override("font_size", 12)
	fast_button.tooltip_text = "Fast resolve: skip card-play animations."
	fast_button.toggled.connect(set_fast_resolve)
	_pin(fast_button, 736, 634, 830, 678)
	hud.add_child(fast_button)


func _capsule_box(bg: Color = Color(0.10, 0.09, 0.07), border: Color = Color(0.74, 0.56, 0.27)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _rebuild_enemy_panels() -> void:
	# Tear down any existing per-enemy widgets and rebuild from `enemies`. Called
	# every time a new combat starts; the row scales between 1–4 panels (StS-style
	# tight encounters; we don't expect more than 3 simultaneously).
	if enemy_row == null:
		return
	for child in enemy_row.get_children():
		child.queue_free()
	enemy_panels.clear()
	for i in enemies.size():
		var data := _build_enemy_panel(i)
		enemy_row.add_child(data["panel"])
		enemy_panels.append(data)


func _build_enemy_panel(idx: int) -> Dictionary:
	# Build one selectable enemy panel. Returns a dict of widget refs so
	# `_update_ui()` can poke them without traversing the tree.
	var panel := Button.new()
	panel.focus_mode = Control.FOCUS_NONE
	panel.flat = true
	panel.text = ""
	panel.custom_minimum_size = Vector2(210, 318)
	panel.add_theme_stylebox_override("normal", _stage_box(Color(0.075, 0.040, 0.034, 0.64), Color(0.82, 0.32, 0.20)))
	panel.add_theme_stylebox_override("hover", _stage_box(Color(0.105, 0.060, 0.048, 0.74), Color(0.95, 0.45, 0.28)))
	panel.add_theme_stylebox_override("pressed", _stage_box(Color(0.105, 0.060, 0.048, 0.78), Color(1.0, 0.55, 0.32)))
	panel.add_theme_stylebox_override("focus", _stage_box(Color(0.105, 0.060, 0.048, 0.74), Color(0.98, 0.50, 0.30)))
	panel.pressed.connect(func(): set_target_index(idx))
	# Click target highlight uses tooltip too — readable by screen-readers.
	panel.tooltip_text = "Click to target this enemy."

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 6
	box.offset_top = 6
	box.offset_right = -6
	box.offset_bottom = -6
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)

	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 20)
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hp_bar)

	var block_label := Label.new()
	block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block_label.add_theme_font_size_override("font_size", 13)
	block_label.mouse_filter = Control.MOUSE_FILTER_STOP
	block_label.tooltip_text = KeywordCatalogScript.describe("block")
	box.add_child(block_label)

	var status_label := Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(status_label)

	var status_icons := HBoxContainer.new()
	status_icons.alignment = BoxContainer.ALIGNMENT_CENTER
	status_icons.custom_minimum_size = Vector2(0, 20)
	status_icons.add_theme_constant_override("separation", 4)
	status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(status_icons)

	var art_rect := TextureRect.new()
	art_rect.custom_minimum_size = Vector2(0, 152)
	art_rect.ignore_texture_size = true
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art_rect)

	var intent_box := HBoxContainer.new()
	intent_box.alignment = BoxContainer.ALIGNMENT_CENTER
	intent_box.custom_minimum_size = Vector2(0, 38)
	intent_box.add_theme_constant_override("separation", 6)
	intent_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(intent_box)

	var intent_icon_local := TextureRect.new()
	intent_icon_local.custom_minimum_size = Vector2(32, 32)
	intent_icon_local.ignore_texture_size = true
	intent_icon_local.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intent_icon_local.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	intent_icon_local.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_box.add_child(intent_icon_local)

	var intent_label_local := Label.new()
	intent_label_local.custom_minimum_size = Vector2(0, 32)
	intent_label_local.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_label_local.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	intent_label_local.add_theme_font_size_override("font_size", 16)
	intent_label_local.mouse_filter = Control.MOUSE_FILTER_STOP
	intent_label_local.tooltip_text = KeywordCatalogScript.describe("intent")
	intent_box.add_child(intent_label_local)

	var phase_marker_local := TextureRect.new()
	phase_marker_local.custom_minimum_size = Vector2(22, 22)
	phase_marker_local.ignore_texture_size = true
	phase_marker_local.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	phase_marker_local.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	phase_marker_local.texture = _load_png_texture("res://art/generated/icons/icon_phase_marker.png")
	phase_marker_local.visible = false
	phase_marker_local.tooltip_text = "Phase 2 active"
	phase_marker_local.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_box.add_child(phase_marker_local)

	return {
		"panel": panel,
		"name_label": name_label,
		"hp_bar": hp_bar,
		"block_label": block_label,
		"status_label": status_label,
		"status_icons": status_icons,
		"art_rect": art_rect,
		"intent_label": intent_label_local,
		"intent_icon": intent_icon_local,
		"phase_marker": phase_marker_local,
	}


func _refresh_enemy_panel_targeting() -> void:
	# Visual indication of who the player has targeted: dim non-targets so
	# damage numbers / focus reads naturally land on the highlighted panel.
	for i in enemy_panels.size():
		var panel: Button = enemy_panels[i]["panel"]
		if i >= enemies.size():
			continue
		var inst = enemies[i]
		if inst.is_dead():
			panel.disabled = true
			panel.modulate = Color(0.42, 0.42, 0.42, 0.55)
			continue
		panel.disabled = false
		if i == target_index:
			panel.modulate = Color.WHITE
		else:
			panel.modulate = Color(0.78, 0.78, 0.78, 0.95)


func _legacy_enemy_widget_pointers() -> void:
	# Keep the legacy single-target pointers (`enemy_label`, `enemy_hp_bar`, etc.)
	# aimed at the currently-selected target. Anything that animates the
	# 'enemy panel' (flashes, intent pulses, hit text positioning) flows through
	# these vars, so re-pointing them on every refresh saves us from threading
	# a target index through the animation helpers.
	if target_index < 0 or target_index >= enemy_panels.size():
		return
	var data: Dictionary = enemy_panels[target_index]
	enemy_label = data.get("name_label", null)
	enemy_hp_bar = data.get("hp_bar", null)
	enemy_block_label = data.get("block_label", null)
	enemy_status_label = data.get("status_label", null)
	enemy_status_icons = data.get("status_icons", null)
	enemy_art_rect = data.get("art_rect", null)
	intent_label = data.get("intent_label", null)
	intent_icon_rect = data.get("intent_icon", null)
	phase_marker_rect = data.get("phase_marker", null)


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
	var dir := DirAccess.open("res://data/cards")
	if dir == null:
		push_error("Failed to open card data directory.")
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			_load_card("res://data/cards/%s" % file_name)
	reward_pool.clear()
	for card_id in card_database.keys():
		var card_data = card_database[card_id]
		var rarity := String(card_data.rarity)
		var c_type := String(card_data.card_type)
		# Exclude basic openers and unplayable curse/status cards from reward draws.
		if rarity == "basic" or rarity == "special":
			continue
		if c_type == "curse" or c_type == "status":
			continue
		reward_pool.append(String(card_id))


func _create_enemy_database() -> void:
	enemy_database = EnemyCatalogScript.load_enemies()
	enemy_move_database = EnemyCatalogScript.build_moves()


func _load_card(path: String) -> void:
	var card = load(path)
	if card == null:
		push_error("Failed to load card data: %s" % path)
		return
	card_database[card.id] = card


func _create_relic_database() -> void:
	relic_database.clear()
	var dir := DirAccess.open("res://data/relics")
	if dir == null:
		push_error("Failed to open relic data directory.")
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			_load_relic("res://data/relics/%s" % file_name)


func _load_relic(path: String) -> void:
	var relic = load(path)
	if relic == null:
		push_error("Failed to load relic data: %s" % path)
		return
	relic_database[relic.id] = relic


func _create_run_relics() -> void:
	relic_manager = RelicManagerScript.new()
	var relics: Array = []
	for relic_id in configured_relic_ids:
		if relic_database.has(relic_id):
			relics.append(relic_database[relic_id])
	if relics.is_empty() and relic_database.has("sealed_badge"):
		relics.append(relic_database["sealed_badge"])
	relic_manager.setup(relics)


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
	enemies.clear()
	target_index = 0
	for enemy_data in _resolve_encounter_enemies():
		var inst = EnemyInstanceScript.new()
		inst.setup(enemy_data, enemy_move_database)
		_apply_ascension_to_enemy(inst)
		enemies.append(inst)
	# Backwards compatibility: legacy code paths read `enemy` directly.
	enemy = enemies[0] if not enemies.is_empty() else null
	# Build one enemy panel per spawn — must happen before _legacy pointer fix-up
	# so the legacy enemy_* vars resolve to a real widget for the active target.
	_rebuild_enemy_panels()
	deck = DeckManagerScript.new()
	deck.setup(_create_deck_from_ids(run_deck_ids))
	relic_manager.trigger("combat_start", self)
	for inst2 in enemies:
		inst2.choose_intent(turn_number, combat_rng)
	_select_first_alive_target()
	_legacy_enemy_widget_pointers()
	_update_enemy_art()
	# Innate cards jump to the top of the draw pile so they're drawn this turn.
	_promote_innate_cards()
	deck.draw_cards(5)
	if enemies.size() == 1:
		_set_log("%s rises from the archive floor." % enemy.display_name)
	else:
		var names: Array[String] = []
		for inst3 in enemies:
			names.append(inst3.display_name)
		_set_log("%s rise from the archive floor." % ", ".join(names))
	_update_ui()
	_play_combat_intro()
	_maybe_play_tutorial_hints()
	# Audio: pick combat music by tier; bosses also get an intro sting.
	var am = _audio()
	if am != null:
		var music_id := "mus_combat_normal"
		if configured_node_type == "elite":
			music_id = "mus_combat_elite"
		elif configured_node_type == "boss":
			music_id = "mus_combat_boss"
			am.play_sfx("sfx_boss_intro")
		am.play_music(music_id, 800)


func _play_combat_intro() -> void:
	# Soft fade-in so the combat scene doesn't pop in. Skipped under fast_resolve
	# so smoke tests / quick replays don't pay the animation tax.
	if fast_resolve:
		return
	modulate = Color(1, 1, 1, 0)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.22)


func _promote_innate_cards() -> void:
	# Move every innate card to the back of draw_pile (which pop_back() draws first)
	# so they are guaranteed to land in the opener.
	if deck == null:
		return
	var innate: Array = []
	var rest: Array = []
	for card in deck.draw_pile:
		if card.is_innate():
			innate.append(card)
		else:
			rest.append(card)
	deck.draw_pile = rest
	for card in innate:
		deck.draw_pile.append(card)  # pop_back picks these first


func _resolve_enemy_data():
	# Legacy single-target accessor — keep for any caller that still expects one
	# EnemyData. Returns the first member of the encounter.
	var arr := _resolve_encounter_enemies()
	return arr[0] if not arr.is_empty() else null


func _resolve_encounter_enemies() -> Array:
	# An encounter id may name a single enemy ("e_dust_scribe") OR a `+`-joined
	# pack ("e_loose_folio+e_dust_scribe") to spawn 2-3 enemies side by side.
	var encounter_id := configured_encounter_id
	if encounter_id == "":
		match configured_node_type:
			"elite":
				encounter_id = "el_wax_sentinel"
			"boss":
				encounter_id = "b_sealed_curator"
			_:
				encounter_id = "e_dust_scribe"
	var ids: Array[String] = []
	for raw in encounter_id.split("+", false):
		var token := String(raw).strip_edges()
		if token != "":
			ids.append(token)
	if ids.is_empty():
		ids.append("e_dust_scribe")
	var result: Array = []
	for one_id in ids:
		if not enemy_database.has(one_id):
			push_warning("Unknown encounter id '%s'; falling back to Dust Scribe." % one_id)
			result.append(enemy_database["e_dust_scribe"])
		else:
			result.append(enemy_database[one_id])
	return result


func alive_enemies() -> Array:
	var result: Array = []
	for inst in enemies:
		if not inst.is_dead():
			result.append(inst)
	return result


func _all_enemies_dead() -> bool:
	for inst in enemies:
		if not inst.is_dead():
			return false
	return true


func _select_first_alive_target() -> void:
	# Pick the first alive enemy as the new target. Used after a kill or at
	# combat start so `enemy` always points at something the player can hit.
	for i in enemies.size():
		if not enemies[i].is_dead():
			target_index = i
			enemy = enemies[i]
			_legacy_enemy_widget_pointers()
			return
	# All dead — leave `enemy` pointing at the last entry so reads (e.g. UI
	# during the victory banner) don't blow up.
	if not enemies.is_empty():
		enemy = enemies[enemies.size() - 1]
		_legacy_enemy_widget_pointers()


func set_target_index(idx: int) -> void:
	if idx < 0 or idx >= enemies.size():
		return
	if enemies[idx].is_dead():
		return
	target_index = idx
	enemy = enemies[idx]
	_legacy_enemy_widget_pointers()
	_update_ui()


func _apply_ascension_to_enemy(target) -> void:
	if target == null or ascension_level <= 0:
		return
	var tier := String(target.tier)
	var hp_mult := AscensionConfigScript.enemy_hp_multiplier(ascension_level, tier)
	if hp_mult != 1.0:
		target.max_hp = max(1, int(round(float(target.max_hp) * hp_mult)))
		target.hp = target.max_hp
	target.damage_multiplier = AscensionConfigScript.enemy_damage_multiplier(ascension_level, tier)


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
	if _animating:
		return
	if _all_enemies_dead() or player_hp <= 0 or (reward_screen != null and reward_screen.visible):
		return
	if card.is_unplayable():
		_push_toast("%s is unplayable" % card.get_display_name(), Color(0.95, 0.30, 0.55))
		return
	if card.get_cost() > player_energy:
		_set_log("Not enough energy for %s." % card.get_display_name())
		_push_toast("Not enough energy", Color(1.0, 0.6, 0.4))
		return
	if action_queue == null:
		# Fallback to synchronous resolve if the queue isn't ready yet.
		_resolve_card_immediate(card)
		return
	_animating = true
	_update_ui()
	_play_card_with_queue(card)


func _play_card_with_queue(card) -> void:
	# Determine the target & whether we have damage/block early so we can
	# choose the right animation flavor.
	var had_damage_effect := false
	var had_block_effect := false
	for effect in card.get_effects():
		var et := String(effect.get("type", ""))
		if et == "damage":
			had_damage_effect = true
		elif et == "block":
			had_block_effect = true

	player_energy -= card.get_cost()
	_set_log("Played %s." % card.get_display_name())
	_push_toast("Played %s" % card.get_display_name(), Color(0.95, 0.83, 0.45))
	_remove_played_card_from_hand(card)
	_update_ui()
	# Cosmetic flying card.
	_spawn_card_play_effect(card)
	# Audio: pick the per-type card-play SFX.
	var am = _audio()
	if am != null:
		var ct := String(card.data.card_type) if card != null and card.data != null else ""
		var sfx_id := "sfx_card_play_skill"
		if ct == "attack":
			sfx_id = "sfx_card_play_attack"
		elif ct == "power":
			sfx_id = "sfx_card_play_power"
		am.play_sfx(sfx_id)

	# Step 1: brief flight delay (140 ms).
	action_queue.push_wait(0.14)

	# Step 2: VFX + hit pause (only meaningful on damage cards).
	if had_damage_effect:
		action_queue.push(func(): _spawn_slash_effect())
		action_queue.push_wait(0.08)
		action_queue.push_hit_pause(0.06)
	elif had_block_effect:
		action_queue.push(func(): _spawn_focus_effect())
		action_queue.push_wait(0.04)
	else:
		action_queue.push(func(): _spawn_focus_effect())
		action_queue.push_wait(0.06)

	# Step 3: resolve effects (damage / block / draw / status / energy).
	action_queue.push(func():
		var target = enemy
		for effect in card.get_effects():
			EffectResolverScript.resolve(effect, self, self, target)
		# Fire card_played relics; pass card_type so type-filtered relics
		# (e.g. attack-only) can opt-in via trigger_params.
		if relic_manager != null and card != null and card.data != null:
			relic_manager.trigger("card_played", self, {"card_type": String(card.data.card_type)})
	)

	# Step 4: enemy flash + shake on damage.
	if had_damage_effect:
		action_queue.push(func(): _flash_enemy())
	# HP / Block bars tween in deal_damage / gain_player_block already.
	action_queue.push_wait(0.20)

	# Step 5: discard / exhaust & cleanup.
	action_queue.push(func():
		Engine.time_scale = 1.0
		_move_played_card_to_final_pile(card)
		_tick_statuses_after_card()
		_check_combat_end()
		_animating = false
		_update_ui()
	)
	await action_queue.flush()
	Engine.time_scale = 1.0


func _resolve_card_immediate(card) -> void:
	# Legacy sync path used as a safety fallback.
	player_energy -= card.get_cost()
	_remove_played_card_from_hand(card)
	_spawn_card_play_effect(card)
	var target = enemy
	var had_damage_effect := false
	for effect in card.get_effects():
		if String(effect.get("type", "")) == "damage":
			had_damage_effect = true
		EffectResolverScript.resolve(effect, self, self, target)
	_move_played_card_to_final_pile(card)
	_set_log("Played %s." % card.get_display_name())
	if had_damage_effect:
		_spawn_slash_effect()
	else:
		_spawn_focus_effect()
	_tick_statuses_after_card()
	_check_combat_end()
	_update_ui()


func _remove_played_card_from_hand(card) -> void:
	if deck == null or card == null:
		return
	if deck.hand.has(card):
		deck.hand.erase(card)


func _move_played_card_to_final_pile(card) -> void:
	if deck == null or card == null:
		return
	# Normal deck.discard/exhaust only move from hand. Played cards are removed
	# from the visible hand immediately for responsiveness, then routed here
	# after effects finish so pile counts still settle correctly.
	if deck.hand.has(card):
		deck.hand.erase(card)
	if card.is_exhaust_on_play():
		if not deck.exhaust_pile.has(card):
			deck.exhaust_pile.append(card)
	else:
		if not deck.discard_pile.has(card):
			deck.discard_pile.append(card)


func _flash_enemy() -> void:
	if enemy_art_rect == null:
		return
	var t := create_tween()
	t.tween_property(enemy_art_rect, "modulate", Color(1.4, 0.8, 0.7, 1.0), 0.04)
	t.tween_property(enemy_art_rect, "modulate", Color.WHITE, 0.18)
	# Quick shake.
	var origin := enemy_art_rect.position
	var shake := create_tween()
	shake.tween_property(enemy_art_rect, "position", origin + Vector2(8, 0), 0.04)
	shake.tween_property(enemy_art_rect, "position", origin + Vector2(-6, 0), 0.04)
	shake.tween_property(enemy_art_rect, "position", origin, 0.04)


func _flash_player() -> void:
	if player_art_rect == null:
		return
	var t := create_tween()
	t.tween_property(player_art_rect, "modulate", Color(1.3, 0.7, 0.6, 1.0), 0.04)
	t.tween_property(player_art_rect, "modulate", Color.WHITE, 0.18)


func _screen_shake(strength: float = 6.0, duration: float = 0.18) -> void:
	# Light, controllable shake on the whole combat container. Triggered for big
	# hits (heavy enemy attacks, big damage). Restores rest position with a
	# small chained tween so concurrent calls don't stack indefinitely.
	if not is_inside_tree():
		return
	var rest := position
	var t := create_tween()
	var steps := 4
	for i in steps:
		var dx := randf_range(-strength, strength)
		var dy := randf_range(-strength * 0.6, strength * 0.6)
		t.tween_property(self, "position", rest + Vector2(dx, dy), duration / float(steps))
	t.tween_property(self, "position", rest, 0.04)


func _push_toast(text_value: String, color: Color = Color(0.94, 0.86, 0.72)) -> void:
	if toast_layer != null:
		toast_layer.push_toast(text_value, color)


func _pulse_intent() -> void:
	# Briefly scale + brighten the enemy intent so the player notices the new
	# threat at the start of their turn. Uses pivot_offset to scale around the
	# label's centre instead of its top-left corner.
	if intent_label == null:
		return
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_enemy_intent", -4.0, 0.25)
	intent_label.pivot_offset = intent_label.size * 0.5
	intent_label.modulate = Color.WHITE
	intent_label.scale = Vector2.ONE
	var t := create_tween()
	t.tween_property(intent_label, "scale", Vector2(1.15, 1.15), 0.10)
	t.parallel().tween_property(intent_label, "modulate", Color(1.25, 1.05, 0.75), 0.10)
	t.tween_property(intent_label, "scale", Vector2.ONE, 0.18)
	t.parallel().tween_property(intent_label, "modulate", Color.WHITE, 0.18)


func _on_end_turn_pressed() -> void:
	if _all_enemies_dead() or player_hp <= 0 or (reward_screen != null and reward_screen.visible):
		return
	if _animating:
		# Card animations still in flight — wait for them to settle so end-of-turn
		# effects don't fire on top of an in-progress card resolve.
		return
	if end_turn_button != null:
		end_turn_button.disabled = true
	_animating = true
	Engine.time_scale = 1.0
	_update_ui()
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_turn_end")
	# StS turn order:
	#   1. Resolve end-of-turn hand (curse damage, etc) and route cards to piles
	#   2. Decay player statuses (vulnerable/weak/frail tick down)
	#   3. Enemy turn: reset enemy block, resolve intent, then decay enemy statuses
	#   4. Start next player turn (reset block, draw, choose intent, gain energy)
	if relic_manager != null:
		relic_manager.trigger("turn_end", self)
	_resolve_end_of_turn_hand()
	_decay_statuses(player_statuses)
	# Apply player Ink at end of player turn (DoT damage from Archivist
	# kit). Bypasses block; ticks the stack down by 1.
	_tick_ink(player_statuses, true)
	_show_turn_banner(_tr("combat.enemy_turn", "Enemy Turn"))
	_set_log(_tr("combat.enemy_turn", "Enemy Turn"))
	await _wait_combat(0.20)
	for inst in enemies:
		inst.block = 0
	await _resolve_enemy_turn()
	for inst in enemies:
		_decay_statuses(inst.statuses)
		_tick_ink(inst.statuses, false, inst)
	if player_hp <= 0:
		_animating = false
		_set_log("Defeat. The archive closes around the fallen vanguard.")
		_update_ui()
		var am2 = _audio()
		if am2 != null:
			am2.play_sfx("sfx_combat_defeat")
			am2.stop_music(800)
		combat_lost.emit()
		return
	_animating = false
	_start_player_turn()


func _resolve_end_of_turn_hand() -> void:
	# Run end-of-turn hand effects (curses, decay statuses) before discarding.
	# Ethereal cards exhaust instead of discarding; retain cards stay in hand.
	if deck == null:
		return
	var original_hand: Array = deck.hand.duplicate()
	var kept: Array = []
	for card in original_hand:
		var eot_effects = card.get_end_of_turn_effects()
		if eot_effects != null and not eot_effects.is_empty():
			for effect in eot_effects:
				EffectResolverScript.resolve(effect, self, self, enemy)
		if card.is_retain():
			kept.append(card)
		elif card.is_ethereal():
			deck.exhaust_pile.append(card)
		else:
			deck.discard_pile.append(card)
	deck.hand = kept


func _start_player_turn() -> void:
	turn_number += 1
	_show_turn_banner("%s %d" % [_tr("combat.player_turn", "Player Turn"), turn_number])
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_turn_start")
	player_block = 0
	player_energy = base_energy
	# Status decay now happens at the end of each side's turn (see _on_end_turn_pressed)
	# to match StS timing — buffs/debuffs applied this turn last the full turn.
	# Each alive enemy rolls its own intent for the upcoming turn. Track phase
	# transitions per-enemy so the boss-phase banner only fires when the
	# specific boss flips, not for adds.
	for inst in enemies:
		if inst.is_dead():
			continue
		var was_phase_active: bool = inst.phase_active
		inst.choose_intent(turn_number, combat_rng)
		if not was_phase_active and inst.phase_active:
			_announce_boss_phase_for(inst)
	# Fire turn_start relics BEFORE drawing so things like "draw +1 on turn
	# start" land in the same hand the player is about to play.
	if relic_manager != null:
		relic_manager.trigger("turn_start", self)
	deck.draw_cards(5)
	_set_log("Turn %d. Draw, guard, decide." % turn_number)
	_update_ui()
	_pulse_intent()


func _announce_boss_phase() -> void:
	_announce_boss_phase_for(enemy)


func _announce_boss_phase_for(target_enemy) -> void:
	# Fires once when a boss flips into its phase-2 move pool. Surfaces a banner
	# + toast + audio sting so the player sees the breakpoint they just crossed.
	_show_turn_banner(_tr("combat.phase", "Phase Shift"))
	_push_toast("%s reaches its phase!" % target_enemy.display_name, Color(0.95, 0.62, 0.36))
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_boss_phase_shift")
	_spawn_phase_shift_effect()
	_screen_shake(6.0, 0.30)


func _resolve_enemy_turn() -> void:
	# Each alive enemy resolves its intent in spawn order. Stops early if the
	# player has already died, so a chain of attacks doesn't keep ticking after
	# defeat.
	for i in enemies.size():
		var inst = enemies[i]
		if inst.is_dead():
			continue
		if player_hp <= 0:
			break
		set_target_index(i)
		_update_ui()
		_pulse_intent()
		await _wait_combat(0.22)
		if inst.current_move != null and String(inst.current_move.id) == "mv_lost_pages":
			_spawn_lost_pages_storm()
			var am = _audio()
			if am != null:
				am.play_sfx("sfx_move_paper_storm")
		_set_log(inst.resolve_intent(self))
		_update_ui()
		await _wait_combat(0.42)


func _wait_combat(seconds: float) -> void:
	if fast_resolve or seconds <= 0.0:
		return
	await get_tree().create_timer(seconds, false, false, true).timeout


func deal_damage(target, amount: int) -> void:
	# Apply Strength buff first, then Weak reduction (StS: Weak reduces final attack damage by 25%),
	# then Vulnerable amplification on the target (+50%). Order mirrors Slay-the-Spire.
	var damage: int = amount + int(player_statuses.get("strength", 0))
	if int(player_statuses.get("weak", 0)) > 0:
		damage = floori(float(damage) * 0.75)
	if int(target.statuses.get("vulnerable", 0)) > 0:
		damage = floori(float(damage) * 1.5)
	if damage < 0:
		damage = 0
	var blocked: int = min(target.block, damage)
	target.block -= blocked
	damage -= blocked
	target.hp = max(0, target.hp - damage)
	if damage > 0:
		_spawn_hit_effect()
		_spawn_float_text("-%d" % damage, _float_anchor_for(enemy_art_rect, Vector2(900, 250)), Color(1.0, 0.36, 0.22))
		var am = _audio()
		if am != null:
			am.play_sfx_pitched("sfx_combat_hit", 1.0)
		if damage >= 12:
			# Big hits get a heavier shake to sell the impact.
			_screen_shake(8.0, 0.20)


func gain_player_block(amount: int) -> void:
	# Dexterity adds flat block, then Frail multiplies (StS order).
	amount += int(player_statuses.get("dexterity", 0))
	if int(player_statuses.get("frail", 0)) > 0:
		amount = floori(float(amount) * 0.75)
	if amount <= 0:
		return
	player_block += amount
	_spawn_block_effect()
	_spawn_float_text("+%d Block" % amount, _float_anchor_for(player_art_rect, Vector2(250, 250)), Color(0.45, 0.72, 1.0))
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_combat_block")


func draw_cards(amount: int) -> void:
	var prior_hand_size: int = deck.hand.size()
	var prior_draw_size: int = deck.draw_pile.size()
	var prior_discard_size: int = deck.discard_pile.size()
	deck.draw_cards(amount)
	var am = _audio()
	# If discard pile drained into draw, fire shuffle VFX.
	if prior_draw_size < amount and prior_discard_size > 0 and deck.discard_pile.size() < prior_discard_size:
		_spawn_shuffle_effect()
		if am != null:
			am.play_sfx("sfx_card_shuffle")
	var added: int = deck.hand.size() - prior_hand_size
	_spawn_float_text("Draw %d" % added, Vector2(560, 610), Color(0.95, 0.83, 0.45))
	# Throttled card-draw click — one shot covers the burst rather than 5 in a row.
	if am != null and added > 0:
		am.play_sfx("sfx_card_draw", 0.0, 0.18)
	# We update the UI here so the newly-arrived CardViews tween in.
	_update_ui()
	if not fast_resolve:
		_animate_draw_arrival(added)


func _animate_draw_arrival(count: int) -> void:
	if count <= 0 or hand_box == null:
		return
	var children: Array = hand_box.get_children()
	if children.is_empty():
		return
	# The most recently appended children correspond to the newly drawn cards.
	var start_index: int = max(0, children.size() - count)
	var draw_anchor := Vector2(196, 600)
	for i in range(start_index, children.size()):
		var view := children[i] as Control
		if view == null:
			continue
		var rest := view.position
		var rest_rotation := view.rotation
		view.position = draw_anchor - hand_box.global_position + Vector2(-rest.x, 0)
		view.rotation = 0.0
		view.modulate = Color(1, 1, 1, 0.2)
		var stagger: float = 0.04 * float(i - start_index)
		var tween := create_tween()
		tween.tween_interval(stagger)
		tween.tween_property(view, "position", rest, 0.07)
		tween.parallel().tween_property(view, "rotation", rest_rotation, 0.07)
		tween.parallel().tween_property(view, "modulate:a", 1.0, 0.07)


func gain_energy(amount: int) -> void:
	player_energy += amount
	if amount > 0:
		_spawn_energy_gain_effect()


func heal_player(amount: int) -> void:
	var prior := player_hp
	player_hp = min(player_max_hp, player_hp + amount)
	if player_hp > prior:
		_spawn_heal_effect()
		_spawn_float_text("+%d" % (player_hp - prior), _float_anchor_for(player_art_rect, Vector2(250, 250)), Color(0.55, 0.95, 0.62))


func lose_player_hp(amount: int) -> void:
	# Bypasses block — used by curses, decay statuses, and self-damage cards.
	if amount <= 0:
		return
	player_hp = max(0, player_hp - amount)
	_spawn_float_text("-%d" % amount, _float_anchor_for(player_art_rect, Vector2(250, 250)), Color(0.95, 0.30, 0.55))
	_flash_player()


func gain_max_hp(amount: int) -> void:
	if amount == 0:
		return
	player_max_hp = max(1, player_max_hp + amount)
	if amount > 0:
		player_hp = min(player_max_hp, player_hp + amount)
	else:
		player_hp = min(player_hp, player_max_hp)


func gain_gold(amount: int) -> void:
	# Combat pages don't track gold directly, but cards may grant it for
	# post-combat tally; we proxy via an autoload-friendly meta entry.
	set_meta("pending_gold_bonus", int(get_meta("pending_gold_bonus", 0)) + amount)


func add_card_to_discard(card_id: String) -> void:
	if card_id == "" or deck == null:
		return
	var inst = _make_card_instance_from_id(card_id)
	if inst != null:
		deck.discard_pile.append(inst)


func add_card_to_hand(card_id: String) -> void:
	if card_id == "" or deck == null:
		return
	if deck.hand.size() >= deck.max_hand_size:
		add_card_to_discard(card_id)
		return
	var inst = _make_card_instance_from_id(card_id)
	if inst != null:
		deck.hand.append(inst)
		_update_ui()


func exhaust_random_hand_card(count: int) -> void:
	if deck == null:
		return
	for i in count:
		if deck.hand.is_empty():
			break
		var idx: int = combat_rng.randi_range(0, deck.hand.size() - 1) if combat_rng != null else randi_range(0, deck.hand.size() - 1)
		var card = deck.hand[idx]
		deck.hand.remove_at(idx)
		deck.exhaust_pile.append(card)
	_update_ui()


func discard_random_hand_card(count: int) -> void:
	if deck == null:
		return
	for i in count:
		if deck.hand.is_empty():
			break
		var idx: int = combat_rng.randi_range(0, deck.hand.size() - 1) if combat_rng != null else randi_range(0, deck.hand.size() - 1)
		var card = deck.hand[idx]
		deck.hand.remove_at(idx)
		deck.discard_pile.append(card)
	_update_ui()


func _make_card_instance_from_id(card_id: String):
	# Looks up the card data and wraps it in a CardInstance. Honours `+` suffix
	# for upgraded variants so reward / event flows can hand us the same id form.
	var trimmed := card_id.trim_suffix("+")
	if not card_database.has(trimmed):
		push_warning("add_card: unknown card_id %s" % card_id)
		return null
	var inst = CardInstanceScript.new()
	inst.setup(card_database[trimmed], card_id.ends_with("+"))
	return inst


func apply_status(target: Variant, status: String, amount: int) -> void:
	if status == "" or amount <= 0:
		return
	var statuses: Dictionary = player_statuses if target == self else target.statuses
	statuses[status] = int(statuses.get(status, 0)) + amount
	_spawn_status_apply_effect(status, target == self)


func apply_status_to_named_target(target_name: String, status: String, amount: int, source_enemy = null) -> void:
	if status == "" or amount <= 0:
		return
	if target_name == "enemy":
		var status_target = source_enemy if source_enemy != null else enemy
		status_target.statuses[status] = int(status_target.statuses.get(status, 0)) + amount
		_spawn_status_apply_effect(status, false)
	else:
		player_statuses[status] = int(player_statuses.get(status, 0)) + amount
		_spawn_status_apply_effect(status, true)


func take_player_damage_from_enemy(amount: int) -> void:
	_take_player_damage(amount)


func _take_player_damage(amount: int) -> void:
	# Player Vulnerable amplifies incoming damage by 50% (StS rule).
	var damage: int = amount
	if int(player_statuses.get("vulnerable", 0)) > 0:
		damage = floori(float(damage) * 1.5)
	if damage < 0:
		damage = 0
	var blocked: int = min(player_block, damage)
	player_block -= blocked
	damage -= blocked
	player_hp = max(0, player_hp - damage)
	if damage > 0:
		_spawn_float_text("-%d" % damage, _float_anchor_for(player_art_rect, Vector2(250, 250)), Color(1.0, 0.26, 0.22))
		_flash_player()
		if damage >= 10:
			_screen_shake(7.0, 0.20)
		# Fire hp_threshold relics — once per combat, when crossing the
		# configured fraction (e.g. 0.5 = below 50% HP). RelicManager handles
		# the latch so re-entering the threshold doesn't re-fire.
		if relic_manager != null and player_max_hp > 0:
			var pct := float(player_hp) / float(player_max_hp)
			relic_manager.trigger("hp_threshold", self, {"hp_pct": pct})


func _tick_statuses_after_card() -> void:
	pass


func _decay_statuses(statuses: Dictionary) -> void:
	for key in statuses.keys():
		# Strength and Dexterity are persistent buffs (do not decay).
		# Ink decays by one stack per *tick* in `_tick_ink`, not the per-turn
		# debuff decay rate, so we skip it here.
		if key == "strength" or key == "dexterity" or key == "ink":
			continue
		statuses[key] = max(0, int(statuses[key]) - 1)


func _tick_ink(statuses: Dictionary, is_player: bool, source_enemy = null) -> void:
	# Archivist DoT mechanic. Deals damage equal to the current stack count,
	# bypassing block (matches StS Poison conventions). Then decreases by 1.
	# Fires on whichever side just finished its turn — see _on_end_turn_pressed
	# (player) and the per-enemy decay loop after enemy turn.
	var stacks := int(statuses.get("ink", 0))
	if stacks <= 0:
		return
	if is_player:
		lose_player_hp(stacks)
	else:
		# Direct HP damage on the source enemy (block-bypass).
		if source_enemy != null:
			source_enemy.hp = max(0, source_enemy.hp - stacks)
			_spawn_float_text("-%d" % stacks, _float_anchor_for(enemy_art_rect, Vector2(900, 250)), Color(0.55, 0.30, 0.95))
			var am = _audio()
			if am != null:
				am.play_sfx("sfx_status_ink_tick", -2.0, 0.18)
	statuses["ink"] = max(0, stacks - 1)


func _check_combat_end() -> void:
	# Fire enemy_killed for any enemy that died this resolve step before the
	# global victory check. This covers AoE attacks that finish multiple
	# enemies at once.
	for inst in enemies:
		if inst.is_dead() and not bool(inst.get_meta("_kill_fired", false)):
			inst.set_meta("_kill_fired", true)
			if relic_manager != null:
				# Surface kill-time status presence so DoT-payoff relics like
				# Inkwell's Grace can opt-in via trigger_params.
				var had_ink: bool = int(inst.statuses.get("ink", 0)) > 0
				relic_manager.trigger("enemy_killed", self, {"had_ink": had_ink})
	# If the currently-targeted enemy died but others remain, advance the
	# selection so the player isn't stuck pointing at a corpse.
	if enemy != null and enemy.is_dead() and not _all_enemies_dead():
		_select_first_alive_target()
	if _all_enemies_dead():
		combats_won += 1
		relic_manager.trigger("combat_victory", self)
		var am = _audio()
		if am != null:
			am.play_sfx("sfx_combat_victory")
			am.stop_music(800)
		if configured_node_type == "boss":
			_show_turn_banner(_tr("combat.victory", "Victory"))
			_set_log("Victory. The Sealed Curator yields the archive key.")
			boss_defeated.emit(player_hp)
		else:
			_show_turn_banner(_tr("combat.victory", "Victory"))
			_set_log("Victory. The page-thing collapses into quiet dust.")
			_show_card_rewards()


func _show_card_rewards() -> void:
	var cards: Array = []
	var picked: Array[String] = []
	while cards.size() < 3 and picked.size() < reward_pool.size():
		var rarity := _roll_reward_rarity()
		var candidates := _reward_candidates_for_rarity(rarity, picked)
		if candidates.is_empty():
			candidates = _reward_candidates_for_rarity("common", picked)
		if candidates.is_empty():
			candidates = _reward_candidates_for_rarity("", picked)
		if candidates.is_empty():
			break
		var card_id := String(candidates[combat_rng.randi_range(0, candidates.size() - 1)])
		picked.append(card_id)
		cards.append(card_database[card_id])
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_reward_appear")
	if combat_hud != null:
		combat_hud.visible = false
	if root_box != null:
		root_box.visible = false
	reward_screen.show_rewards(cards)
	reward_screen.move_to_front()


func _roll_reward_rarity() -> String:
	var roll := combat_rng.randi_range(1, 100)
	if configured_node_type == "elite":
		if roll <= 40:
			return "common"
		if roll <= 90:
			return "uncommon"
		return "rare"
	if configured_node_type == "boss":
		if roll <= 60:
			return "uncommon"
		return "rare"
	if roll <= 60:
		return "common"
	if roll <= 97:
		return "uncommon"
	return "rare"


func _reward_candidates_for_rarity(rarity: String, excluded: Array[String]) -> Array[String]:
	var ids: Array[String] = []
	for card_id in reward_pool:
		if excluded.has(card_id):
			continue
		if rarity == "" or String(card_database[card_id].rarity) == rarity:
			ids.append(card_id)
	return ids


func _on_reward_card_chosen(card_id: String) -> void:
	run_deck_ids.append(card_id)
	_set_log("Added %s to the deck." % card_database[card_id].display_name)
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_reward_pick")
	combat_reward_chosen.emit(card_id, player_hp)


func _on_reward_skipped() -> void:
	_set_log("Skipped card reward.")
	combat_reward_skipped.emit(player_hp)


func _update_ui() -> void:
	combat_title_label.text = configured_title
	player_label.text = "HP %d/%d    Block %d    Energy %d/%d" % [player_hp, player_max_hp, player_block, player_energy, base_energy]
	piles_label.text = "Draw %d    Hand %d    Discard %d    Exhaust %d" % [deck.draw_pile.size(), deck.hand.size(), deck.discard_pile.size(), deck.exhaust_pile.size()]
	_update_relic_icon_row()
	player_label.tooltip_text = "Player statuses: %s" % (_status_text(player_statuses) if _status_text(player_statuses) != "" else "none")
	player_hp_bar.max_value = player_max_hp
	_tween_bar(player_hp_bar, player_hp)
	player_block_label.text = "%s    %s" % [_tr("combat.block", "Block: %d") % player_block, _tr("combat.energy", "ENERGY\n%d/%d").replace("\n", " ") % [player_energy, base_energy]]
	player_status_label.text = _status_icons(player_statuses)
	_update_status_icon_row(player_status_icons, player_statuses)
	# Refresh every enemy panel against its EnemyInstance.
	_legacy_enemy_widget_pointers()
	for i in enemy_panels.size():
		if i >= enemies.size():
			continue
		_refresh_enemy_panel_widgets(i)
	_refresh_enemy_panel_targeting()
	energy_label.text = _tr("combat.energy", "ENERGY\n%d/%d") % [player_energy, base_energy]
	draw_pile_button.text = _tr("combat.draw", "Draw\n%d") % deck.draw_pile.size()
	discard_pile_button.text = _tr("combat.discard", "Discard\n%d") % deck.discard_pile.size()
	exhaust_pile_button.text = _tr("combat.exhaust", "Exhaust\n%d") % deck.exhaust_pile.size()
	if deck_summary_button != null:
		var total: int = deck.draw_pile.size() + deck.hand.size() + deck.discard_pile.size() + deck.exhaust_pile.size()
		var atk := 0
		var skl := 0
		var pwr := 0
		for pile in [deck.draw_pile, deck.hand, deck.discard_pile, deck.exhaust_pile]:
			for c in pile:
				match String(c.data.card_type):
					"attack": atk += 1
					"skill": skl += 1
					"power": pwr += 1
		deck_summary_button.text = _tr("combat.deck", "Deck %d · %d/%d/%d") % [total, atk, skl, pwr]
		deck_summary_button.tooltip_text = _tr("combat.deck_tip", "Click to view full deck (atk/skl/pwr)")
	_style_intent_badge()
	end_turn_button.disabled = _all_enemies_dead() or player_hp <= 0
	hand_section_label.text = _tr("combat.resolving", "Resolving card...") if _animating else _tr("combat.hand", "Hand - click a card to play it. Energy left: %d") % player_energy

	for child in hand_box.get_children():
		child.queue_free()

	for card_index in range(deck.hand.size()):
		var card = deck.hand[card_index]
		var card_view = CARD_VIEW_SCENE.instantiate()
		card_view.setup(card, player_energy, _all_enemies_dead() or player_hp <= 0)
		card_view.card_selected.connect(_on_card_pressed)
		card_view.card_hovered.connect(_on_card_hovered)
		card_view.card_unhovered.connect(_on_card_unhovered)
		hand_box.add_child(card_view)
		_layout_hand_card(card_view, card_index, deck.hand.size())


func _layout_hand_card(card_view: Control, index: int, count: int) -> void:
	if hand_box == null or card_view == null:
		return
	var card_size := Vector2(118, 154)
	var area := hand_box.size
	if area.x <= 1.0:
		area = Vector2(1040, 206)
	var spread: float = min(108.0, max(70.0, (area.x - card_size.x - 48.0) / max(1.0, float(count - 1))))
	var center_x: float = area.x * 0.5
	var center_index: float = (float(count) - 1.0) * 0.5
	var offset: float = float(index) - center_index
	var fan_strength: float = clamp(abs(offset) / max(1.0, center_index), 0.0, 1.0)
	var x: float = center_x + offset * spread - card_size.x * 0.5
	var y: float = 22.0 + fan_strength * 18.0
	var rot: float = deg_to_rad(offset * 5.5)
	if card_view.has_method("set_rest_pose"):
		card_view.set_rest_pose(Vector2(x, y), rot, index)
	else:
		card_view.position = Vector2(x, y)
		card_view.rotation = rot


func _refresh_enemy_panel_widgets(idx: int) -> void:
	# Sync one enemy panel's widgets to the underlying EnemyInstance state.
	# Per-enemy refresh keeps multi-foe combats responsive without rebuilding
	# the panel tree on every update.
	var data: Dictionary = enemy_panels[idx]
	var inst = enemies[idx]
	var name_label: Label = data.get("name_label", null)
	var hp_bar: ProgressBar = data.get("hp_bar", null)
	var block_label: Label = data.get("block_label", null)
	var status_label: Label = data.get("status_label", null)
	var status_icons: HBoxContainer = data.get("status_icons", null)
	var art_rect: TextureRect = data.get("art_rect", null)
	var intent_label_local: Label = data.get("intent_label", null)
	var intent_icon_local: TextureRect = data.get("intent_icon", null)
	var phase_marker_local: TextureRect = data.get("phase_marker", null)
	if name_label != null:
		var enemy_name := _localized_name(inst.id, inst.display_name)
		name_label.text = _tr("combat.hp_block", "%s\nHP %d/%d  Block %d") % [enemy_name, inst.hp, inst.max_hp, inst.block]
		name_label.tooltip_text = _tr("combat.statuses", "Statuses: %s") % (inst.get_status_text() if inst.get_status_text() != "" else _tr("combat.none", "none"))
	if hp_bar != null:
		hp_bar.max_value = inst.max_hp
		_tween_bar(hp_bar, inst.hp)
	if block_label != null:
		block_label.text = _tr("combat.block", "Block: %d") % inst.block
	if status_label != null:
		status_label.text = _status_icons(inst.statuses)
	if status_icons != null:
		_update_status_icon_row(status_icons, inst.statuses)
	if art_rect != null:
		art_rect.texture = _load_character_texture(inst.art_path)
		# Death visual: faded silhouette while still on-screen for clarity.
		art_rect.modulate = Color(0.4, 0.4, 0.4, 0.55) if inst.is_dead() else Color.WHITE
	if intent_label_local != null:
		intent_label_local.text = _intent_display_text_for(inst)
	if intent_icon_local != null:
		intent_icon_local.texture = _intent_texture_for(inst)
	if phase_marker_local != null:
		phase_marker_local.visible = bool(inst.phase_active)


func _tween_bar(bar: ProgressBar, target_value: float) -> void:
	if bar == null:
		return
	var duration := 0.0 if fast_resolve else 0.25
	if duration <= 0.0 or is_equal_approx(bar.value, target_value):
		bar.value = target_value
		return
	var t := create_tween()
	t.tween_property(bar, "value", target_value, duration)


func _on_card_hovered(card_instance, anchor_position: Vector2) -> void:
	if card_inspector == null:
		return
	# anchor_position is global; card_inspector is also full-rect, so it's
	# already in the same coordinate space.
	card_inspector.show_card(card_instance, anchor_position)


func _on_card_unhovered(card_instance) -> void:
	if card_inspector == null:
		return
	card_inspector.hide_card(card_instance)


func _update_enemy_art() -> void:
	if enemy_art_rect == null:
		return
	enemy_art_rect.texture = _load_character_texture(enemy.art_path)


func _style_intent_badge() -> void:
	if enemy == null or intent_label == null:
		return
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
	return _intent_display_text_for(enemy)


func _intent_display_text_for(target_enemy) -> String:
	if target_enemy == null:
		return ""
	if target_enemy.is_dead():
		return "—"
	match target_enemy.intent_type:
		"defend":
			return "WARD\nBlock %d" % target_enemy.intent_block
		"attack_multi":
			return "!\n%d x %d" % [target_enemy.intent_multi_hit_count, target_enemy.intent_damage]
		"attack_defend":
			return "!\n%d + Block %d" % [target_enemy.intent_damage, target_enemy.intent_block]
		"buff":
			return "UP\nBuff"
		"debuff":
			return "DOWN\nDebuff"
		"unknown":
			return "?\nUnknown"
		"heavy_attack":
			return "!!\nHeavy Attack %d" % target_enemy.intent_damage
		_:
			return "!\nAttack %d" % target_enemy.intent_damage


func _intent_texture() -> Texture2D:
	return _intent_texture_for(enemy)


func _intent_texture_for(target_enemy) -> Texture2D:
	if target_enemy == null or target_enemy.is_dead():
		return null
	match target_enemy.intent_type:
		"defend":
			return _load_png_texture("res://art/generated/icons/intent_defend.png")
		"heavy_attack":
			return _load_png_texture("res://art/generated/icons/intent_heavy_attack.png")
		"attack_multi":
			return _load_png_texture("res://art/generated/icons/intent_heavy_attack.png")
		"attack_defend":
			return _load_png_texture("res://art/generated/icons/intent_attack.png")
		"buff":
			return _load_png_texture("res://art/generated/icons/intent_buff.png")
		"debuff":
			return _load_png_texture("res://art/generated/icons/intent_debuff.png")
		"unknown":
			return _load_png_texture("res://art/generated/icons/intent_unknown.png")
		_:
			return _load_png_texture("res://art/generated/icons/intent_attack.png")


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
	# The combat log has been demoted: messages now flow through the toast layer
	# whenever it is available. The legacy label still receives the latest line so
	# tests / smoke harnesses can read combat state without snapshotting toasts.
	if log_label != null:
		log_label.text = message
	if toast_layer != null and message != "":
		toast_layer.push_toast(message, _toast_color_for_message(message))


func _toast_color_for_message(message: String) -> Color:
	var lower := message.to_lower()
	if lower.begins_with("victory") or lower.begins_with("added"):
		return Color(0.65, 0.95, 0.55)
	if lower.begins_with("defeat") or lower.begins_with("not enough"):
		return Color(1.00, 0.62, 0.40)
	if lower.begins_with("turn"):
		return Color(0.78, 0.86, 1.00)
	return Color(0.94, 0.86, 0.72)


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
	if int(statuses.get("dexterity", 0)) > 0:
		parts.append("DEX %d" % int(statuses["dexterity"]))
	if int(statuses.get("vulnerable", 0)) > 0:
		parts.append("VUL %d" % int(statuses["vulnerable"]))
	if int(statuses.get("weak", 0)) > 0:
		parts.append("WEAK %d" % int(statuses["weak"]))
	if int(statuses.get("frail", 0)) > 0:
		parts.append("FRAIL %d" % int(statuses["frail"]))
	if int(statuses.get("ink", 0)) > 0:
		parts.append("INK %d" % int(statuses["ink"]))
	if parts.is_empty():
		return ""
	return "  ".join(parts)


func _update_status_icon_row(container: HBoxContainer, statuses: Dictionary) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
	# Iteration order matches the HUD-row reading order. `ink` is the
	# Archivist's signature DoT and is shown alongside the other debuffs.
	for key in ["strength", "dexterity", "vulnerable", "weak", "frail", "ink"]:
		var amount := int(statuses.get(key, 0))
		if amount <= 0:
			continue
		var group := HBoxContainer.new()
		# Hover the whole group to get the tooltip; STOP so it captures
		# mouse, but the tooltip itself comes from each child.
		group.mouse_filter = Control.MOUSE_FILTER_STOP
		group.add_theme_constant_override("separation", 2)
		group.tooltip_text = KeywordCatalogScript.describe(key)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(18, 18)
		icon.ignore_texture_size = true
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _load_png_texture("res://art/generated/icons/status_%s.png" % key)
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		group.add_child(icon)
		var count := Label.new()
		count.text = str(amount)
		count.add_theme_font_size_override("font_size", 11)
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count.mouse_filter = Control.MOUSE_FILTER_PASS
		group.add_child(count)
		container.add_child(group)


func _update_relic_icon_row() -> void:
	if relics_icon_row == null:
		return
	for child in relics_icon_row.get_children():
		child.queue_free()
	if relic_manager == null:
		return
	for relic in relic_manager.relics:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.ignore_texture_size = true
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var relic_id := String(relic.data.id)
		var tex := _load_png_texture("res://art/generated/icons/relic_%s.png" % relic_id)
		if tex == null:
			tex = _load_png_texture("res://art/generated/ui/relic_slot.png")
		icon.texture = tex
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.tooltip_text = "%s — %s" % [relic.get_display_name(), relic.get_description()]
		relics_icon_row.add_child(icon)


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Failed to load image: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _load_character_texture(path: String) -> Texture2D:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Failed to load character image: %s" % path)
		return null
	var bounds := _alpha_bounds(image)
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return ImageTexture.create_from_image(image)
	var padding := 8
	bounds.position.x = max(0, bounds.position.x - padding)
	bounds.position.y = max(0, bounds.position.y - padding)
	bounds.size.x = min(image.get_width() - bounds.position.x, bounds.size.x + padding * 2)
	bounds.size.y = min(image.get_height() - bounds.position.y, bounds.size.y + padding * 2)
	return ImageTexture.create_from_image(image.get_region(bounds))


func _alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.03:
				continue
			min_x = min(min_x, x)
			min_y = min(min_y, y)
			max_x = max(max_x, x)
			max_y = max(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _spawn_slash_effect() -> void:
	var slash := TextureRect.new()
	slash.texture = _load_png_texture("res://art/generated/sprites/vfx_slash_arc.png")
	slash.ignore_texture_size = true
	slash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slash.custom_minimum_size = Vector2(170, 90)
	slash.position = Vector2(820, 250)
	slash.rotation = -0.35
	effect_layer.add_child(slash)
	var tween := create_tween()
	tween.tween_property(slash, "position", Vector2(940, 210), 0.18)
	tween.parallel().tween_property(slash, "modulate:a", 0.0, 0.22)
	tween.tween_callback(slash.queue_free)


func _spawn_focus_effect() -> void:
	var pulse := TextureRect.new()
	pulse.texture = _load_png_texture("res://art/generated/sprites/vfx_reward_glow.png")
	pulse.ignore_texture_size = true
	pulse.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pulse.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pulse.modulate = Color(1, 1, 1, 0.62)
	pulse.custom_minimum_size = Vector2(130, 100)
	pulse.position = Vector2(330, 244)
	pulse.rotation = 0.1
	effect_layer.add_child(pulse)
	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector2(1.6, 1.0), 0.20)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.25)
	tween.tween_callback(pulse.queue_free)


func _spawn_phase_shift_effect() -> void:
	if effect_layer == null:
		return
	var burst := TextureRect.new()
	burst.texture = _load_png_texture("res://art/generated/sprites/vfx_phase_shift_burst.png")
	burst.ignore_texture_size = true
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	burst.custom_minimum_size = Vector2(760, 240)
	burst.position = Vector2(260, 96)
	burst.modulate = Color(1, 1, 1, 0.0)
	effect_layer.add_child(burst)
	var tween := create_tween()
	tween.tween_property(burst, "modulate:a", 0.92, 0.08)
	tween.parallel().tween_property(burst, "scale", Vector2(1.06, 1.06), 0.18)
	tween.tween_property(burst, "modulate:a", 0.0, 0.35)
	tween.tween_callback(burst.queue_free)


func _spawn_lost_pages_storm() -> void:
	if effect_layer == null:
		return
	var storm := TextureRect.new()
	storm.texture = _load_png_texture("res://art/generated/sprites/vfx_lost_pages_storm.png")
	storm.ignore_texture_size = true
	storm.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	storm.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	storm.custom_minimum_size = Vector2(760, 240)
	storm.position = Vector2(44, 138)
	storm.modulate = Color(1, 1, 1, 0.0)
	effect_layer.add_child(storm)
	var tween := create_tween()
	tween.tween_property(storm, "modulate:a", 0.74, 0.08)
	tween.parallel().tween_property(storm, "position", storm.position + Vector2(42, -12), 0.58)
	tween.tween_property(storm, "modulate:a", 0.0, 0.22)
	tween.tween_callback(storm.queue_free)


func _spawn_block_effect() -> void:
	if effect_layer == null:
		return
	var pulse := TextureRect.new()
	pulse.texture = _load_png_texture("res://art/generated/sprites/vfx_block_pulse.png")
	pulse.ignore_texture_size = true
	pulse.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pulse.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pulse.custom_minimum_size = Vector2(112, 112)
	pulse.position = Vector2(190, 206)
	effect_layer.add_child(pulse)
	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector2(1.35, 1.35), 0.28)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.34)
	tween.tween_callback(pulse.queue_free)


func _spawn_hit_effect() -> void:
	if effect_layer == null:
		return
	var spark := TextureRect.new()
	spark.texture = _load_png_texture("res://art/generated/sprites/vfx_hit_spark.png")
	spark.ignore_texture_size = true
	spark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spark.custom_minimum_size = Vector2(96, 96)
	spark.position = Vector2(850, 226)
	effect_layer.add_child(spark)
	var tween := create_tween()
	tween.tween_property(spark, "scale", Vector2(1.25, 1.25), 0.16)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.24)
	tween.tween_callback(spark.queue_free)


func _spawn_energy_gain_effect() -> void:
	if effect_layer == null:
		return
	var pulse := TextureRect.new()
	pulse.texture = _load_png_texture("res://art/generated/sprites/vfx_energy_gain.png")
	pulse.ignore_texture_size = true
	pulse.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pulse.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pulse.custom_minimum_size = Vector2(96, 96)
	pulse.position = Vector2(150, 540)
	pulse.modulate = Color(1, 1, 1, 0.92)
	effect_layer.add_child(pulse)
	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector2(1.4, 1.4), 0.20)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.32)
	tween.tween_callback(pulse.queue_free)


func _spawn_heal_effect() -> void:
	if effect_layer == null:
		return
	var pulse := TextureRect.new()
	pulse.texture = _load_png_texture("res://art/generated/sprites/vfx_heal_pulse.png")
	pulse.ignore_texture_size = true
	pulse.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pulse.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pulse.custom_minimum_size = Vector2(120, 120)
	pulse.position = Vector2(180, 220)
	effect_layer.add_child(pulse)
	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector2(1.3, 1.3), 0.30)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.36)
	tween.tween_callback(pulse.queue_free)


func _spawn_status_apply_effect(status: String, on_player: bool) -> void:
	if effect_layer == null:
		return
	var debuffs := ["weak", "vulnerable", "frail", "poison"]
	var is_debuff: bool = status in debuffs
	var path := "res://art/generated/sprites/vfx_status_apply_debuff.png" if is_debuff else "res://art/generated/sprites/vfx_status_apply_buff.png"
	var pulse := TextureRect.new()
	pulse.texture = _load_png_texture(path)
	pulse.ignore_texture_size = true
	pulse.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pulse.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pulse.custom_minimum_size = Vector2(80, 80)
	pulse.position = Vector2(220, 200) if on_player else Vector2(880, 200)
	pulse.modulate = Color(1, 1, 1, 0.88)
	effect_layer.add_child(pulse)
	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector2(1.25, 1.25), 0.22)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.30)
	tween.tween_callback(pulse.queue_free)


func _spawn_shuffle_effect() -> void:
	if effect_layer == null:
		return
	var pages := TextureRect.new()
	pages.texture = _load_png_texture("res://art/generated/sprites/vfx_shuffle_pages.png")
	pages.ignore_texture_size = true
	pages.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pages.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pages.custom_minimum_size = Vector2(140, 100)
	pages.position = Vector2(440, 540)
	effect_layer.add_child(pages)
	var tween := create_tween()
	tween.tween_property(pages, "rotation", 0.5, 0.30)
	tween.parallel().tween_property(pages, "modulate:a", 0.0, 0.30)
	tween.tween_callback(pages.queue_free)


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
	label.modulate = color
	label.scale = Vector2(0.72, 0.72)
	# Add a small horizontal jitter so multi-hit attacks (Pommel, multi-strikes) don't
	# spawn perfectly stacked numbers — readability improves a lot from <8px scatter.
	var jitter := Vector2(randf_range(-18.0, 18.0), randf_range(-10.0, 8.0))
	label.position = position + jitter
	label.add_theme_font_size_override("font_size", 36)
	# Drop-shadow for legibility on busy backgrounds.
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.86))
	label.add_theme_constant_override("outline_size", 9)
	effect_layer.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position", label.position + Vector2(0, -18), 0.08)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.10)
	tween.parallel().tween_property(label, "position", label.position + Vector2(0, -72), 0.58)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.58)
	tween.tween_callback(label.queue_free)


func _float_anchor_for(control: Control, fallback: Vector2) -> Vector2:
	if control == null or effect_layer == null:
		return fallback
	if not control.is_inside_tree() or not effect_layer.is_inside_tree():
		return fallback
	return control.global_position - effect_layer.global_position + control.size * 0.5
