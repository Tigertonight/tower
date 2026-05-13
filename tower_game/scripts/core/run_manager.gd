extends Control

const COMBAT_SCENE := preload("res://scenes/combat/combat_scene.tscn")
const SaveManagerScript := preload("res://scripts/save/save_manager.gd")
const RouteMapViewScript := preload("res://scripts/ui/route_map_view.gd")
const MapGeneratorScript := preload("res://scripts/map/map_generator.gd")
const PotionCatalogScript := preload("res://scripts/potions/potion_catalog.gd")
const ShopViewScript := preload("res://scripts/ui/shop_view.gd")
const CardPickerScript := preload("res://scripts/ui/card_picker.gd")
const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")
const AscensionConfigScript := preload("res://scripts/core/ascension_config.gd")
const CharacterCatalogScript := preload("res://scripts/core/character_catalog.gd")
const SettingsManagerScript := preload("res://scripts/core/settings_manager.gd")

var save_manager
var settings_manager
# A1.7 pause overlay — Control we add directly under the run scene root and
# toggle visible. Sits above the current screen and pauses combat tween updates
# via `get_tree().paused = true`.
var pause_overlay: Control = null
var run_deck_ids: Array[String] = []
var player_max_hp := 76
var player_hp := 76
var gold := 99
var floor_index := 0
var combat_index := 0
var completed := false
var story_seen := false
var current_screen: Control
var run_id := ""
var run_seed := 1
var current_node_id := "L0_0"
var ascension_level := 0
var selected_ascension_level := 0
# Currently-selected character for the next "Start New Run". The active run
# stores its own snapshot in `character_id`, so changing the menu pick after
# starting a run never retroactively rewrites it.
var selected_character_id := "char_vanguard"
var character_id := "char_vanguard"
var character_catalog: Dictionary = {}
var current_act := 1
const FINAL_ACT := 3
var rng_state := {
	"map_rng": 1,
	"combat_rng": 2,
	"reward_rng": 3,
	"event_rng": 4
}
var reward_rng := RandomNumberGenerator.new()
var event_rng := RandomNumberGenerator.new()
var relic_ids: Array[String] = ["sealed_badge"]
var potions: Array = [null, null, null]
var events_seen: Array[String] = []
var shop_visits := 0
var card_removals := 0
var card_database: Dictionary = {}
var relic_database: Dictionary = {}
var potion_database: Dictionary = {}
var current_shop_cards: Array = []
var current_shop_relics: Array = []
var current_shop_potions: Array = []
var pending_card_pick_context: Dictionary = {}
var new_run_reset_in_progress := false

var card_names := {
	"strike_form": "Strike Form",
	"guard_form": "Guard Form",
	"archive_bash": "Archive Bash",
	"quick_read": "Quick Read",
	"forward_step": "Forward Step",
	"measured_cut": "Measured Cut",
	"brace": "Brace",
	"shield_tap": "Shield Tap",
	"break_rhythm": "Break Rhythm",
	"oath_pressure": "Oath Pressure"
}

var map_nodes: Array = []


func _audio():
	return get_node_or_null("/root/AudioManager")


func _ready() -> void:
	save_manager = SaveManagerScript.new()
	settings_manager = SettingsManagerScript.new()
	settings_manager.apply_audio(_audio())
	if _loc() != null:
		_loc().set_language(String(settings_manager.get_value("language")))
		_loc().language_changed.connect(func(lang: String) -> void:
			settings_manager.set_value("language", lang)
			_rebuild_current_screen_for_language()
		)
	_load_content_databases()
	character_catalog = CharacterCatalogScript.load_all()
	_load_or_start_run()
	_show_main_menu()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if event.keycode == KEY_F2:
		_show_map()
	elif event.keycode == KEY_F3:
		_show_combat("combat", "Dust Scribe")
	elif event.keycode == KEY_ESCAPE:
		_toggle_pause_menu()
	elif event.keycode == KEY_L:
		_toggle_language()


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


func _toggle_language() -> void:
	var loc = _loc()
	if loc != null:
		loc.toggle_language()


func _rebuild_current_screen_for_language() -> void:
	if pause_overlay != null and is_instance_valid(pause_overlay) and pause_overlay.visible:
		_close_pause_menu()
		_open_pause_menu()
		return
	if current_screen == null:
		return
	var kind := String(current_screen.get_meta("screen_kind", "main"))
	match kind:
		"map":
			_show_map()
		"character_select":
			_show_character_select_menu()
		"combat":
			if current_screen.has_method("refresh_language"):
				current_screen.refresh_language()
		_:
			_show_main_menu()


func _load_or_start_run() -> void:
	var data: Dictionary = save_manager.load_run()
	if data.is_empty():
		_start_new_run()
		return
	if data.has("schema_version"):
		_load_schema_v1(data)
	else:
		_load_legacy_save(data)
	if run_deck_ids.is_empty():
		run_deck_ids = _starter_deck()
	_sync_rngs()


func _load_schema_v1(data: Dictionary) -> void:
	var run: Dictionary = data.get("run", {})
	run_id = String(run.get("run_id", _make_run_id()))
	run_seed = int(run.get("seed", 1))
	rng_state = run.get("rng_state", rng_state)
	var player: Dictionary = run.get("player", {})
	player_hp = int(player.get("hp", player_hp))
	player_max_hp = int(player.get("max_hp", player_max_hp))
	gold = int(player.get("gold", gold))
	potions = player.get("potions", [null, null, null])
	run_deck_ids.clear()
	for entry in run.get("deck", []):
		if typeof(entry) == TYPE_DICTIONARY:
			var card_id := String(entry.get("card_id", ""))
			if bool(entry.get("upgraded", false)):
				card_id += "+"
			run_deck_ids.append(card_id)
		else:
			run_deck_ids.append(String(entry))
	relic_ids.clear()
	for relic_entry in run.get("relics", [{"relic_id": "sealed_badge"}]):
		relic_ids.append(String(relic_entry.get("relic_id", "sealed_badge")))
	current_node_id = String(run.get("current_node_id", "L0_0"))
	ascension_level = AscensionConfigScript.clamp_level(int(run.get("ascension_level", 0)))
	completed = bool(run.get("completed", false))
	story_seen = bool(run.get("story_seen", false))
	var history: Dictionary = run.get("history", {})
	combat_index = int(history.get("encounters_completed", 0))
	events_seen.clear()
	for event_id in history.get("events_seen", []):
		events_seen.append(String(event_id))
	shop_visits = int(history.get("shop_visits", 0))
	card_removals = int(history.get("card_removals", 0))
	current_act = clamp(int(run.get("act", 1)), 1, FINAL_ACT)
	character_id = String(run.get("character_id", "char_vanguard"))
	if character_id == "":
		character_id = "char_vanguard"
	map_nodes = MapGeneratorScript.generate(run_seed, current_act)
	MapGeneratorScript.apply_node_states(map_nodes, run.get("map", {}).get("node_states", {}))
	floor_index = _current_layer_index()


func _load_legacy_save(data: Dictionary) -> void:
	run_deck_ids.clear()
	for card_id in data.get("run_deck_ids", []):
		run_deck_ids.append(String(card_id))
	player_hp = int(data.get("player_hp", player_max_hp))
	player_max_hp = int(data.get("player_max_hp", player_max_hp))
	gold = int(data.get("gold", gold))
	combat_index = int(data.get("combat_index", 0))
	completed = bool(data.get("completed", false))
	story_seen = bool(data.get("story_seen", false))
	run_seed = randi_range(1, 2147483647)
	rng_state = {"map_rng": run_seed, "combat_rng": run_seed + 11, "reward_rng": run_seed + 23, "event_rng": run_seed + 37}
	current_act = 1
	map_nodes = MapGeneratorScript.generate(run_seed, current_act)
	current_node_id = "L0_0"
	MapGeneratorScript.mark_visited(map_nodes, current_node_id)
	floor_index = 1


func _start_new_run() -> void:
	run_id = _make_run_id()
	run_seed = randi_range(1, 2147483647)
	rng_state = {"map_rng": run_seed, "combat_rng": run_seed + 11, "reward_rng": run_seed + 23, "event_rng": run_seed + 37}
	current_act = 1
	map_nodes = MapGeneratorScript.generate(run_seed, current_act)
	current_node_id = "L0_0"
	MapGeneratorScript.mark_visited(map_nodes, current_node_id)
	ascension_level = AscensionConfigScript.clamp_level(selected_ascension_level)
	# Lock in the character chosen on the menu — the active run keeps its own
	# id so changing the menu later doesn't mutate the in-progress run.
	character_id = selected_character_id
	var char_data = CharacterCatalogScript.resolve(character_catalog, character_id)
	run_deck_ids = _starter_deck()
	for curse_id in AscensionConfigScript.starting_curses(ascension_level):
		run_deck_ids.append(curse_id)
	var starting_relic := "sealed_badge"
	var base_hp := 76
	if char_data != null:
		starting_relic = String(char_data.starting_relic_id)
		base_hp = int(char_data.starting_hp)
	relic_ids = [starting_relic]
	potions = [null, null, null]
	player_max_hp = base_hp - AscensionConfigScript.player_max_hp_penalty(ascension_level)
	player_hp = player_max_hp
	gold = 99
	floor_index = 1
	combat_index = 0
	completed = false
	story_seen = false
	events_seen.clear()
	shop_visits = 0
	card_removals = 0
	_sync_rngs()
	_save_run()
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_ui_run_start")


func _starter_deck() -> Array[String]:
	# Per-character starter decks come from data/characters/*.tres. Falls back
	# to the original Vanguard list if the catalog isn't loaded yet (e.g. an
	# unusual reload order during tests).
	var char_data = CharacterCatalogScript.resolve(character_catalog, character_id)
	var ids: Array[String] = []
	if char_data != null and char_data.starter_deck != null and not char_data.starter_deck.is_empty():
		for entry in char_data.starter_deck:
			var card_id := String(entry)
			if card_id != "" and card_database.has(card_id.trim_suffix("+")):
				ids.append(card_id)
		if not ids.is_empty():
			return ids
	# Fallback: legacy Vanguard mix.
	for i in 5:
		ids.append("strike_form")
	for i in 4:
		ids.append("guard_form")
	ids.append("archive_bash")
	ids.append("quick_read")
	ids.append("forward_step")
	return ids


func _save_run() -> void:
	save_manager.save_run({
		"schema_version": 1,
		"build_version": "0.1.0",
		"run": {
			"run_id": run_id,
			"seed": run_seed,
			"rng_state": _capture_rng_state(),
			"character_id": character_id,
			"act": current_act,
			"ascension_level": ascension_level,
			"current_node_id": current_node_id,
			"completed": completed,
			"story_seen": story_seen,
			"player": {
				"max_hp": player_max_hp,
				"hp": player_hp,
				"gold": gold,
				"energy_per_turn": 3,
				"potion_slots": 3,
				"potions": potions
			},
			"deck": _deck_to_save(),
			"relics": _relics_to_save(),
			"map": {
				"generator_version": 1,
				"node_states": MapGeneratorScript.encode_node_states(map_nodes)
			},
			"history": {
				"encounters_completed": combat_index,
				"events_seen": events_seen,
				"shop_visits": shop_visits,
				"card_removals": card_removals
			},
			"combat_state": null
		}
	})


func _deck_to_save() -> Array:
	var deck: Array = []
	for entry in run_deck_ids:
		var card_id := String(entry)
		var upgraded := card_id.ends_with("+")
		deck.append({"card_id": card_id.trim_suffix("+"), "upgraded": upgraded})
	return deck


func _relics_to_save() -> Array:
	var relics: Array = []
	for relic_id in relic_ids:
		relics.append({"relic_id": relic_id, "counters": {}})
	return relics


func _load_content_databases() -> void:
	card_database.clear()
	var card_dir := DirAccess.open("res://data/cards")
	if card_dir != null:
		for file_name in card_dir.get_files():
			if file_name.ends_with(".tres"):
				var card = load("res://data/cards/%s" % file_name)
				if card != null:
					card_database[String(card.get("id"))] = card
	relic_database.clear()
	var relic_dir := DirAccess.open("res://data/relics")
	if relic_dir != null:
		for file_name in relic_dir.get_files():
			if file_name.ends_with(".tres"):
				var relic = load("res://data/relics/%s" % file_name)
				if relic != null:
					relic_database[String(relic.get("id"))] = relic
	potion_database = PotionCatalogScript.load_potions()


func _make_run_id() -> String:
	return "%d-%d" % [Time.get_unix_time_from_system(), randi_range(1000, 9999)]


func _sync_rngs() -> void:
	reward_rng.seed = run_seed + 23
	reward_rng.state = int(rng_state.get("reward_rng", run_seed + 23))
	event_rng.seed = run_seed + 37
	event_rng.state = int(rng_state.get("event_rng", run_seed + 37))


func _capture_rng_state() -> Dictionary:
	rng_state["reward_rng"] = reward_rng.state
	rng_state["event_rng"] = event_rng.state
	return rng_state


func _capture_combat_rng_state() -> void:
	if current_screen != null and current_screen.has_method("get_combat_rng_state"):
		rng_state["combat_rng"] = current_screen.get_combat_rng_state()


func _current_layer_index() -> int:
	var node := MapGeneratorScript.find_node(map_nodes, current_node_id)
	return int(node.get("layer", floor_index))


func _clear_screen() -> void:
	if current_screen != null:
		current_screen.queue_free()
		current_screen = null


func _clear_screen_immediate() -> void:
	if current_screen != null:
		current_screen.free()
		current_screen = null


func _show_map() -> void:
	_clear_screen()
	var am = _audio()
	if am != null:
		am.play_music("mus_map_theme", 1000)
		am.play_ambient("amb_archive_room", 1400)
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.set_meta("screen_kind", "map")
	current_screen = screen
	add_child(screen)

	var bg := TextureRect.new()
	bg.texture = _load_png_texture("res://art/generated/backgrounds/living_archive_route_board.png")
	bg.ignore_texture_size = true
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)

	var bg_shade := ColorRect.new()
	bg_shade.color = Color(0, 0, 0, 0.34)
	bg_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg_shade)

	var top_glow := ColorRect.new()
	top_glow.color = Color(0.20, 0.15, 0.08, 0.38)
	top_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_glow.custom_minimum_size = Vector2(0, 96)
	screen.add_child(top_glow)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 32
	root.offset_top = 14
	root.offset_right = -32
	root.offset_bottom = -22
	root.add_theme_constant_override("separation", 10)
	screen.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var title := Label.new()
	title.text = _tr("map.title", "Living Archive")
	title.custom_minimum_size = Vector2(180, 34)
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	var stats := Label.new()
	stats.text = _tr("map.stats", "Act %d/%d  HP %d/%d  Gold %d  Deck %d  Layer %d/%d  Relics %d  Potions %d/3  A%d") % [current_act, FINAL_ACT, player_hp, player_max_hp, gold, run_deck_ids.size(), min(floor_index + 1, map_nodes.size()), map_nodes.size(), relic_ids.size(), _potion_count(), ascension_level]
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 15)
	header.add_child(stats)

	var reset := Button.new()
	reset.text = _tr("map.new", "New Run")
	reset.custom_minimum_size = Vector2(120, 40)
	reset.pressed.connect(_on_new_run_pressed)
	header.add_child(reset)

	if completed:
		_add_completion(root)
		return

	var info_bar := HBoxContainer.new()
	info_bar.custom_minimum_size = Vector2(0, 78)
	info_bar.add_theme_constant_override("separation", 12)
	root.add_child(info_bar)

	var quest := PanelContainer.new()
	quest.custom_minimum_size = Vector2(0, 72)
	quest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.055, 0.045, 0.035, 0.76), Color(0.58, 0.42, 0.18, 0.72)))
	info_bar.add_child(quest)
	var quest_box := VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 4)
	quest.add_child(quest_box)
	var quest_title := Label.new()
	quest_title.text = _tr("map.task", "Current Task")
	quest_title.add_theme_font_size_override("font_size", 14)
	quest_title.modulate = Color(0.96, 0.82, 0.54)
	quest_box.add_child(quest_title)
	var quest_body := Label.new()
	quest_body.text = _tr("map.task_body", "%s\nChoose one lit route node. Dim icons are locked.") % _quest_text()
	quest_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_body.add_theme_font_size_override("font_size", 14)
	quest_box.add_child(quest_body)

	var deck_card := PanelContainer.new()
	deck_card.custom_minimum_size = Vector2(286, 72)
	deck_card.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.035, 0.034, 0.032, 0.80), Color(0.58, 0.42, 0.18, 0.78)))
	info_bar.add_child(deck_card)
	var deck_box := VBoxContainer.new()
	deck_box.add_theme_constant_override("separation", 4)
	deck_card.add_child(deck_box)
	var deck_title := Label.new()
	deck_title.text = _tr("map.deck", "Deck (%d)") % run_deck_ids.size()
	deck_title.add_theme_font_size_override("font_size", 14)
	deck_title.modulate = Color(0.96, 0.82, 0.54)
	deck_box.add_child(deck_title)
	var deck_list := Label.new()
	deck_list.text = _deck_summary_text()
	deck_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_list.add_theme_font_size_override("font_size", 13)
	deck_box.add_child(deck_list)

	var map_and_side := Control.new()
	map_and_side.custom_minimum_size = Vector2(0, 500)
	map_and_side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(map_and_side)

	var map_panel := PanelContainer.new()
	map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_panel.offset_left = 22
	map_panel.offset_top = 8
	map_panel.offset_right = -22
	map_panel.offset_bottom = -8
	map_panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.05, 0.043, 0.032, 0.26), Color(0.70, 0.50, 0.20, 0.34)))
	map_and_side.add_child(map_panel)

	var map_view = RouteMapViewScript.new()
	map_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_view.node_selected.connect(_enter_node)
	map_panel.add_child(map_view)
	map_view.setup(map_nodes, floor_index, MapGeneratorScript.available_from(map_nodes, current_node_id))
	map_view.set_deck_summary(_deck_summary_text())


func _show_main_menu() -> void:
	_clear_screen()
	var am = _audio()
	if am != null:
		am.play_music("mus_main_theme", 1200)
		am.stop_ambient(800)
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.set_meta("screen_kind", "main")
	current_screen = screen
	add_child(screen)

	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.065, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)

	var bg_art := TextureRect.new()
	bg_art.texture = _load_png_texture("res://art/generated/backgrounds/main_menu_archive_entrance.png")
	bg_art.ignore_texture_size = true
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_art.modulate = Color(1, 1, 1, 0.72)
	screen.add_child(bg_art)

	var glow := ColorRect.new()
	glow.color = Color(0.22, 0.15, 0.07, 0.25)
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.offset_left = -520
	glow.offset_top = -260
	glow.offset_right = 520
	glow.offset_bottom = 260
	screen.add_child(glow)

	var hero := TextureRect.new()
	hero.texture = _character_sprite_texture(selected_character_id)
	hero.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	hero.offset_left = 42
	hero.offset_top = 145
	hero.offset_right = 315
	hero.offset_bottom = -30
	screen.add_child(hero)

	var key := TextureRect.new()
	key.texture = _load_png_texture("res://art/generated/sprites/archive_key.png")
	key.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	key.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	key.offset_left = -230
	key.offset_top = 165
	key.offset_right = -70
	key.offset_bottom = -165
	screen.add_child(key)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -190
	panel.offset_top = -230
	panel.offset_right = 350
	panel.offset_bottom = 210
	panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.035, 0.034, 0.032, 0.72), Color(0.68, 0.50, 0.24, 0.70)))
	screen.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var logo_holder := CenterContainer.new()
	logo_holder.custom_minimum_size = Vector2(0, 132)
	logo_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(logo_holder)

	var logo := TextureRect.new()
	logo.texture = _load_png_texture("res://art/generated/ui/living_archive_logo.png")
	logo.custom_minimum_size = Vector2(154, 132)
	logo.ignore_texture_size = true
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_holder.add_child(logo)

	var title := Label.new()
	title.text = _tr("main.title", "LIVING ARCHIVE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = _tr("main.subtitle", "A playable roguelike deckbuilder demo. Choose routes, fight with cards, improve your deck, and defeat the Sealed Curator.")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	var run_state := Label.new()
	run_state.text = _tr("main.saved", "Saved Run: Layer %d/%d, HP %d/%d, Gold %d") % [min(floor_index + 1, map_nodes.size()), map_nodes.size(), player_hp, player_max_hp, gold]
	run_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(run_state)

	var continue_button := Button.new()
	continue_button.text = _tr("main.continue", "Continue Run")
	continue_button.custom_minimum_size = Vector2(0, 52)
	continue_button.disabled = run_deck_ids.is_empty()
	continue_button.pressed.connect(func() -> void: _show_map())
	box.add_child(continue_button)

	var new_button := Button.new()
	new_button.text = _tr("main.new", "New Run")
	new_button.custom_minimum_size = Vector2(0, 52)
	new_button.pressed.connect(_show_character_select_menu)
	box.add_child(new_button)

	var settings_button := Button.new()
	settings_button.text = _tr("main.settings", "Settings")
	settings_button.custom_minimum_size = Vector2(0, 46)
	settings_button.pressed.connect(func() -> void:
		pause_overlay = _build_pause_overlay()
		add_child(pause_overlay)
	)
	box.add_child(settings_button)

	var controls := Label.new()
	controls.text = _tr("main.help", "Choose New Run to select a character, tune Ascension, and inspect the starting kit.")
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(controls)


func _show_character_select_menu() -> void:
	_clear_screen()
	var am = _audio()
	if am != null:
		am.play_music("mus_main_theme", 800)
		am.stop_ambient(600)
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.set_meta("screen_kind", "character_select")
	current_screen = screen
	add_child(screen)

	var bg_art := TextureRect.new()
	bg_art.texture = _load_png_texture("res://art/generated/backgrounds/main_menu_archive_entrance.png")
	bg_art.ignore_texture_size = true
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_art.modulate = Color(1, 1, 1, 0.62)
	screen.add_child(bg_art)

	var veil := ColorRect.new()
	veil.color = Color(0.015, 0.014, 0.012, 0.54)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(veil)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 34
	root.offset_top = 14
	root.offset_right = -34
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 8)
	screen.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var title := Label.new()
	title.text = _tr("select.title", "Choose Your Archivist")
	title.add_theme_font_size_override("font_size", 25)
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = _tr("select.subtitle", "Select a character, review the starting kit, then set Ascension before entering the archive.")
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.modulate = Color(0.84, 0.78, 0.68, 0.92)
	title_box.add_child(subtitle)

	var back := Button.new()
	back.text = _tr("select.back", "Back")
	back.custom_minimum_size = Vector2(108, 42)
	back.pressed.connect(_show_main_menu)
	header.add_child(back)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)

	var roster_panel := PanelContainer.new()
	roster_panel.custom_minimum_size = Vector2(520, 0)
	roster_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.034, 0.030, 0.026, 0.72), Color(0.72, 0.52, 0.24, 0.66)))
	body.add_child(roster_panel)

	var roster := GridContainer.new()
	roster.columns = 2
	roster.add_theme_constant_override("separation", 16)
	roster.add_theme_constant_override("h_separation", 16)
	roster.add_theme_constant_override("v_separation", 16)
	roster_panel.add_child(roster)

	var sorted_char_ids: Array = _playable_character_ids()
	sorted_char_ids.sort()
	if sorted_char_ids.is_empty():
		sorted_char_ids = ["char_vanguard"]
	for cid in sorted_char_ids:
		roster.add_child(_build_character_portrait_card(String(cid)))

	var details_panel := PanelContainer.new()
	details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.026, 0.027, 0.027, 0.82), Color(0.64, 0.48, 0.24, 0.70)))
	body.add_child(details_panel)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_panel.add_child(detail_scroll)

	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 12)
	detail_scroll.add_child(detail)

	var data = CharacterCatalogScript.resolve(character_catalog, selected_character_id)
	var name_text := selected_character_id
	var subtitle_text := ""
	var starting_hp := 76
	var relic_id := "sealed_badge"
	if data != null:
		name_text = _localized_name(String(data.id), String(data.display_name))
		if String(data.get("class_display_name")) != "":
			name_text = "%s — %s" % [_character_class_display_name(data), name_text]
		subtitle_text = _tr("char.%s.subtitle" % String(data.id), String(data.subtitle))
		starting_hp = int(data.starting_hp)
		relic_id = String(data.starting_relic_id)

	var detail_title := Label.new()
	detail_title.text = name_text
	detail_title.add_theme_font_size_override("font_size", 30)
	detail.add_child(detail_title)

	var detail_subtitle := Label.new()
	detail_subtitle.text = subtitle_text
	detail_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_subtitle.add_theme_font_size_override("font_size", 15)
	detail_subtitle.modulate = Color(0.95, 0.84, 0.62, 0.94)
	detail.add_child(detail_subtitle)

	var trait_grid := GridContainer.new()
	trait_grid.columns = 2
	trait_grid.add_theme_constant_override("h_separation", 10)
	trait_grid.add_theme_constant_override("v_separation", 10)
	detail.add_child(trait_grid)
	trait_grid.add_child(_build_stat_tile(_tr("select.hp", "Starting HP"), "%d" % (starting_hp - AscensionConfigScript.player_max_hp_penalty(selected_ascension_level))))
	trait_grid.add_child(_build_stat_tile(_tr("select.relic", "Relic"), _relic_display_name(relic_id)))
	trait_grid.add_child(_build_stat_tile(_tr("select.deck", "Deck"), _tr("select.card_count", "%d cards") % _starter_deck_for_character(selected_character_id).size()))
	trait_grid.add_child(_build_stat_tile(_tr("select.asc", "Ascension"), "A%d" % selected_ascension_level))

	var traits := Label.new()
	traits.text = _character_trait_text(selected_character_id)
	traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	traits.add_theme_font_size_override("font_size", 14)
	traits.modulate = Color(0.86, 0.82, 0.74, 0.94)
	detail.add_child(traits)

	var deck_title := Label.new()
	deck_title.text = _tr("select.cards", "Starting Cards")
	deck_title.add_theme_font_size_override("font_size", 18)
	detail.add_child(deck_title)

	var deck_list := Label.new()
	deck_list.text = _starter_deck_preview(selected_character_id)
	deck_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deck_list.custom_minimum_size = Vector2(0, 76)
	deck_list.add_theme_font_size_override("font_size", 13)
	deck_list.modulate = Color(0.82, 0.78, 0.70, 0.92)
	detail.add_child(deck_list)

	var asc_panel := PanelContainer.new()
	asc_panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.055, 0.044, 0.030, 0.62), Color(0.72, 0.54, 0.26, 0.64)))
	detail.add_child(asc_panel)
	var asc_box := VBoxContainer.new()
	asc_box.add_theme_constant_override("separation", 8)
	asc_panel.add_child(asc_box)
	var asc_row := HBoxContainer.new()
	asc_row.alignment = BoxContainer.ALIGNMENT_CENTER
	asc_row.add_theme_constant_override("separation", 10)
	asc_box.add_child(asc_row)
	var asc_label := Label.new()
	asc_label.text = _tr("select.difficulty", "Difficulty")
	asc_label.custom_minimum_size = Vector2(120, 0)
	asc_label.add_theme_font_size_override("font_size", 16)
	asc_row.add_child(asc_label)
	var asc_minus := Button.new()
	asc_minus.text = "-"
	asc_minus.custom_minimum_size = Vector2(42, 34)
	asc_row.add_child(asc_minus)
	var asc_value := Label.new()
	asc_value.text = "A%d" % selected_ascension_level
	asc_value.custom_minimum_size = Vector2(66, 0)
	asc_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	asc_value.add_theme_font_size_override("font_size", 18)
	asc_row.add_child(asc_value)
	var asc_plus := Button.new()
	asc_plus.text = "+"
	asc_plus.custom_minimum_size = Vector2(42, 34)
	asc_row.add_child(asc_plus)
	var asc_summary := Label.new()
	asc_summary.text = AscensionConfigScript.summary(selected_ascension_level)
	asc_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	asc_summary.add_theme_font_size_override("font_size", 13)
	asc_box.add_child(asc_summary)
	asc_minus.pressed.connect(func() -> void:
		selected_ascension_level = AscensionConfigScript.clamp_level(selected_ascension_level - 1)
		_show_character_select_menu()
	)
	asc_plus.pressed.connect(func() -> void:
		selected_ascension_level = AscensionConfigScript.clamp_level(selected_ascension_level + 1)
		_show_character_select_menu()
	)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)

	var warning := Label.new()
	warning.text = _tr("select.warning", "Starting a new run will replace the current saved run.")
	warning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning.modulate = Color(0.94, 0.72, 0.48, 0.86)
	footer.add_child(warning)

	var start := Button.new()
	start.text = _tr("select.start", "Enter the Archive")
	start.custom_minimum_size = Vector2(220, 46)
	start.add_theme_font_size_override("font_size", 18)
	start.pressed.connect(_on_new_run_confirmed)
	footer.add_child(start)


func _build_character_portrait_card(char_id: String) -> Control:
	var data = CharacterCatalogScript.resolve(character_catalog, char_id)
	var selected := char_id == selected_character_id
	var color := Color(0.86, 0.62, 0.30)
	var display_name := char_id
	var subtitle := ""
	if data != null:
		color = data.theme_color
		display_name = _localized_name(String(data.id), String(data.display_name))
		if String(data.get("class_display_name")) != "":
			display_name = "%s" % _character_class_display_name(data)
		subtitle = _tr("char.%s.subtitle" % String(data.id), String(data.subtitle))
	var button := Button.new()
	button.custom_minimum_size = Vector2(210, 212)
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.050, 0.044, 0.036, 0.66), color.darkened(0.26)))
	button.add_theme_stylebox_override("hover", _glass_panel_box(Color(0.070, 0.058, 0.042, 0.78), color.lightened(0.16)))
	button.add_theme_stylebox_override("pressed", _glass_panel_box(Color(0.082, 0.064, 0.044, 0.82), color.lightened(0.28)))
	if selected:
		button.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.080, 0.062, 0.040, 0.84), color.lightened(0.20)))
	button.pressed.connect(func() -> void:
		selected_character_id = char_id
		_show_character_select_menu()
	)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_top = 10
	box.offset_right = -10
	box.offset_bottom = -10
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var art := TextureRect.new()
	art.texture = _character_sprite_texture(char_id)
	art.custom_minimum_size = Vector2(0, 136)
	art.ignore_texture_size = true
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)

	var name := Label.new()
	name.text = display_name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 20)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name)

	var tag := Label.new()
	tag.text = _tr("select.selected", "SELECTED") if selected else _tr("select.available", "AVAILABLE")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 12)
	tag.modulate = color.lightened(0.22) if selected else Color(0.62, 0.58, 0.50, 0.90)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(tag)
	return button


func _build_stat_tile(label_text: String, value_text: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(210, 60)
	panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.048, 0.044, 0.038, 0.62), Color(0.44, 0.34, 0.20, 0.58)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 11)
	label.modulate = Color(0.70, 0.66, 0.58, 0.92)
	box.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(value)
	return panel


func _starter_deck_for_character(char_id: String) -> Array:
	var data = CharacterCatalogScript.resolve(character_catalog, char_id)
	if data == null:
		return []
	return data.starter_deck.duplicate()


func _starter_deck_preview(char_id: String) -> String:
	var counts := {}
	for entry in _starter_deck_for_character(char_id):
		var card_id := String(entry).trim_suffix("+")
		counts[card_id] = int(counts.get(card_id, 0)) + 1
	var parts: Array[String] = []
	for card_id in counts.keys():
		parts.append("%s x%d" % [_card_display_name(card_id), int(counts[card_id])])
	parts.sort()
	return ", ".join(parts)


func _playable_character_ids() -> Array:
	var ids: Array = []
	for char_id in character_catalog.keys():
		var data = character_catalog.get(char_id, null)
		if data == null:
			continue
		if bool(data.get("is_playable")):
			ids.append(String(char_id))
	return ids


func _relic_display_name(relic_id: String) -> String:
	var data = relic_database.get(relic_id, null)
	if data != null and String(data.get("display_name")) != "":
		return _localized_name(relic_id, String(data.get("display_name")))
	return relic_id.capitalize()


func _character_trait_text(char_id: String) -> String:
	var data = CharacterCatalogScript.resolve(character_catalog, char_id)
	if data != null and String(data.get("class_trait_summary")) != "":
		var localized := _tr("char.%s.traits" % String(data.id), "")
		if localized != "":
			return localized
		var keywords = data.get("class_keywords")
		var keyword_text := ""
		if keywords != null and not keywords.is_empty():
			var parts: Array[String] = []
			for entry in keywords:
				parts.append(String(entry))
			keyword_text = "\n%s: %s" % [_tr("select.keywords", "Keywords"), ", ".join(parts)]
		return "%s%s" % [String(data.get("class_trait_summary")), keyword_text]
	match char_id:
		"char_vanguard":
			return _tr("char.char_vanguard.traits", "Role: front-line brawler.\nStrengths: high HP, reliable block, simple attack curve.\nPressure: slower card flow, needs damage upgrades before elites.")
		"char_archivist":
			return _tr("char.char_archivist.traits", "Role: status and draw specialist.\nStrengths: cheaper card flow, Ink pressure, more tactical turns.\nPressure: lower HP, weaker early blocking if draw misses.")
		_:
			return "Role: unknown archive claimant.\nStrengths and pressure will be defined as this character receives tuning."


func _character_class_display_name(data) -> String:
	if data == null:
		return ""
	var class_id := String(data.get("class_id"))
	var fallback := String(data.get("class_display_name"))
	if class_id == "":
		return fallback
	return _tr("class.%s" % class_id, fallback)


func _show_story_intro() -> void:
	_clear_screen()
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	current_screen = screen
	add_child(screen)

	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.052, 0.055)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)

	var bg_art := TextureRect.new()
	bg_art.texture = _load_png_texture("res://art/generated/backgrounds/prologue_door_scene.png")
	bg_art.ignore_texture_size = true
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_art.modulate = Color(1, 1, 1, 0.64)
	screen.add_child(bg_art)

	var story_glow := ColorRect.new()
	story_glow.color = Color(0.18, 0.12, 0.06, 0.25)
	story_glow.set_anchors_preset(Control.PRESET_CENTER)
	story_glow.offset_left = -520
	story_glow.offset_top = -280
	story_glow.offset_right = 520
	story_glow.offset_bottom = 280
	screen.add_child(story_glow)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -350
	panel.offset_top = -240
	panel.offset_right = 350
	panel.offset_bottom = 240
	screen.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title := Label.new()
	title.text = _tr("intro.title", "Prologue: The Door That Remembered")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var intro_art_holder := CenterContainer.new()
	intro_art_holder.custom_minimum_size = Vector2(0, 112)
	intro_art_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(intro_art_holder)

	var intro_art := TextureRect.new()
	intro_art.custom_minimum_size = Vector2(148, 104)
	intro_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	intro_art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	intro_art.ignore_texture_size = true
	intro_art.texture = _load_png_texture("res://art/generated/sprites/archive_key.png")
	intro_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intro_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	intro_art_holder.add_child(intro_art)

	var story := Label.new()
	story.custom_minimum_size = Vector2(640, 0)
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var char_data = CharacterCatalogScript.resolve(character_catalog, character_id)
	var relic_name := "Sealed Badge"
	if char_data != null:
		relic_name = _relic_display_name(String(char_data.starting_relic_id))
	story.text = _tr("intro.story", "The Living Archive has opened beneath the old tower. Every shelf remembers a broken oath. Every page has learned to bite. You carry %s, a minor authority and a fragile excuse to survive.\n\nTask: recover the Archive Key from the Sealed Curator before the tower writes your name into its losses.") % relic_name
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(story)

	var start := Button.new()
	start.text = _tr("intro.enter", "Enter the Archive")
	start.custom_minimum_size = Vector2(0, 54)
	start.pressed.connect(func() -> void:
		story_seen = true
		_save_run()
		_show_map()
	)
	box.add_child(start)


func _node_icon(node_type: String) -> String:
	match node_type:
		"combat":
			return "COMBAT"
		"elite":
			return "ELITE"
		"event":
			return "EVENT"
		"shop":
			return "SHOP"
		"campfire":
			return "CAMP"
		"boss":
			return "BOSS"
		_:
			return "NODE"


func _node_box(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _glass_panel_box(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _quest_text() -> String:
	if _loc() != null and _loc().is_zh():
		if floor_index <= 1:
			return _tr("map.quest", "Build a reliable deck. Find one damage card and one defense tool before the upper archive.")
		if floor_index == 2:
			return "选择风险：去商店提高稳定性，接受事件交易，或挑战精英。"
		if floor_index == 3:
			return "准备面对馆长。治疗、升级，或赢下最后一份奖励。"
		return "击败封印馆长，取回档案馆钥匙。"
	if floor_index <= 1:
		return "Build a reliable deck. Find one damage card and one defense tool before the upper archive."
	if floor_index == 2:
		return "Choose your risk: shop for consistency, take an event bargain, or challenge the elite."
	if floor_index == 3:
		return "Prepare for the Curator. Heal, upgrade, or win one final reward."
	return "Defeat the Sealed Curator and recover the Archive Key."


func _deck_summary() -> String:
	var counts := {}
	for card_id in run_deck_ids:
		counts[card_id] = int(counts.get(card_id, 0)) + 1
	var parts: Array[String] = []
	for entry in counts.keys():
		var entry_text := String(entry)
		parts.append("%s x%d" % [_card_display_name(entry_text), counts[entry]])
	return ", ".join(parts)


func _enter_node(row_index: int, node_index: int) -> void:
	var node = map_nodes[row_index][node_index]
	if not MapGeneratorScript.available_from(map_nodes, current_node_id).has(String(node.id)):
		return
	current_node_id = String(node.id)
	floor_index = int(node.get("layer", floor_index))
	MapGeneratorScript.mark_visited(map_nodes, current_node_id)
	_save_run()
	match node.type:
		"start":
			_show_map()
		"combat", "elite", "boss":
			_show_combat(node.type, node.title, String(node.get("encounter_id", "")))
		"event":
			_show_event()
		"shop":
			_show_shop()
		"campfire":
			_show_campfire()
		"treasure":
			_gain_random_relic()
			_advance_after_noncombat()


func _show_combat(node_type: String, node_title: String = "", encounter_id: String = "") -> void:
	_clear_screen()
	var combat = COMBAT_SCENE.instantiate()
	combat.set_meta("screen_kind", "combat")
	combat.configure(run_deck_ids, player_hp, player_max_hp, node_type, combat_index, node_title, encounter_id, int(rng_state.get("combat_rng", run_seed + 11)), relic_ids, ascension_level, character_id, _current_character_pool_id())
	current_screen = combat
	add_child(combat)
	combat.combat_reward_chosen.connect(_on_combat_reward_chosen)
	combat.combat_reward_skipped.connect(_on_combat_reward_skipped)
	combat.combat_lost.connect(_on_combat_lost)
	combat.boss_defeated.connect(_on_boss_defeated)
	combat.reset_run_requested.connect(_on_new_run_pressed)
	# Apply persisted "fast resolve" preference from the pause menu.
	if settings_manager != null and combat.has_method("set_fast_resolve"):
		combat.set_fast_resolve(bool(settings_manager.get_value("fast_resolve")))
	# A1.8 — propagate the tutorial-hints toggle. Hints only fire on the very
	# first combat (combats_won == 0); set_tutorial_hints_enabled gates them.
	if settings_manager != null and combat.has_method("set_tutorial_hints_enabled"):
		combat.set_tutorial_hints_enabled(bool(settings_manager.get_value("show_tutorial_hints")))


func _on_combat_reward_chosen(card_id: String, remaining_hp: int) -> void:
	run_deck_ids.append(card_id)
	player_hp = remaining_hp
	gold += _combat_gold_reward()
	_roll_post_combat_rewards()
	combat_index += 1
	_capture_combat_rng_state()
	_save_run()
	_show_map()


func _on_combat_reward_skipped(remaining_hp: int) -> void:
	player_hp = remaining_hp
	gold += _combat_gold_reward() + 7
	_roll_post_combat_rewards()
	combat_index += 1
	_capture_combat_rng_state()
	_save_run()
	_show_map()


func _on_combat_lost() -> void:
	_show_run_summary("defeat")


func _on_boss_defeated(remaining_hp: int) -> void:
	player_hp = remaining_hp
	gold += 60
	_capture_combat_rng_state()
	if current_act >= FINAL_ACT:
		completed = true
		_save_run()
		_show_run_summary("victory")
		return
	# Advance to the next act: regenerate map with act-flavored encounters,
	# heal a bit, drop a cross-act treasure, and reset to the new outer gate.
	current_act += 1
	combat_index += 1
	_gain_random_relic()
	player_hp = min(player_max_hp, player_hp + floori(float(player_max_hp) * 0.20))
	map_nodes = MapGeneratorScript.generate(run_seed, current_act)
	current_node_id = "L0_0"
	MapGeneratorScript.mark_visited(map_nodes, current_node_id)
	floor_index = 1
	_save_run()
	_show_act_transition()


func _combat_gold_reward() -> int:
	var node := MapGeneratorScript.find_node(map_nodes, current_node_id)
	match String(node.get("type", "")):
		"elite":
			return reward_rng.randi_range(30, 45)
		"boss":
			return 60
		_:
			var band := 0 if floor_index <= 3 else (1 if floor_index <= 5 else 2)
			return reward_rng.randi_range(12 + band * 2, 18 + band * 4)


func _roll_post_combat_rewards() -> void:
	var node := MapGeneratorScript.find_node(map_nodes, current_node_id)
	var node_type := String(node.get("type", "combat"))
	var potion_chance := 35
	if node_type == "elite":
		potion_chance = 70
		_gain_random_relic()
	if reward_rng.randi_range(1, 100) <= potion_chance:
		_gain_random_potion()


func _gain_random_relic() -> void:
	var source_pool := _roll_relic_source_pool(false)
	_gain_random_relic_from_pool(source_pool)


func _gain_random_relic_from_pool(source_pool: String) -> void:
	var candidates := _relic_candidates(source_pool)
	if candidates.is_empty() and source_pool != "":
		candidates = _relic_candidates("")
	if candidates.is_empty():
		gold += 25
		return
	var relic_id := candidates[reward_rng.randi_range(0, candidates.size() - 1)]
	relic_ids.append(relic_id)


func _relic_candidates(source_pool: String = "") -> Array[String]:
	var candidates: Array[String] = []
	for relic_id in relic_database.keys():
		if _is_relic_available(String(relic_id), source_pool):
			candidates.append(String(relic_id))
	return candidates


func _is_relic_available(relic_id: String, source_pool: String = "") -> bool:
	if not relic_database.has(relic_id):
		return false
	if relic_ids.has(relic_id):
		return false
	var relic = relic_database[relic_id]
	if String(relic.rarity) == "starter":
		return false
	var pool_id := _relic_pool_id(relic)
	if source_pool != "" and pool_id != source_pool:
		return false
	return pool_id == "public" or pool_id == _current_character_class_id()


func _relic_pool_id(relic) -> String:
	var pool_id := String(relic.get("pool_id"))
	if pool_id == "":
		return "public"
	return pool_id


func _current_character_class_id() -> String:
	var data = CharacterCatalogScript.resolve(character_catalog, character_id if character_id != "" else selected_character_id)
	if data != null:
		var class_id := String(data.get("class_id"))
		if class_id != "":
			return class_id
	return _current_character_pool_id()


func _roll_relic_source_pool(for_shop: bool = false) -> String:
	var class_pool := _current_character_class_id()
	var roll := reward_rng.randi_range(1, 100)
	if for_shop:
		if roll <= 60:
			return "public"
		if roll <= 95:
			return class_pool
		return "public"
	if roll <= 70:
		return "public"
	return class_pool


func _gain_random_potion() -> void:
	var empty_index := -1
	for index in potions.size():
		if potions[index] == null:
			empty_index = index
			break
	if empty_index < 0:
		gold += 25
		return
	var ids: Array[String] = []
	for potion_id in potion_database.keys():
		ids.append(String(potion_id))
	if ids.is_empty():
		return
	potions[empty_index] = ids[reward_rng.randi_range(0, ids.size() - 1)]


func _potion_count() -> int:
	var count := 0
	for potion in potions:
		if potion != null:
			count += 1
	return count


func _show_event() -> void:
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_event_open")
	var event_id := _roll_event_id()
	events_seen.append(event_id)
	match event_id:
		"ev_quiet_stack":
			_show_choice_screen(
				_tr("event.quiet_stack.title", "The Quiet Stack"),
				_tr("event.quiet_stack.body", "A reading desk has been left as if mid-thought. A small object rests under the lamp."),
				[
					{"text": _tr("event.quiet_stack.choice1", "Take the object. Lose 8 HP. Gain a relic."), "action": func() -> void: _event_gain_relic_for_hp(8)},
					{"text": _tr("event.quiet_stack.choice2", "Read first. Lose 4 HP. Gain a relic."), "action": func() -> void: _event_gain_relic_for_hp(4)},
					{"text": _tr("event.quiet_stack.choice3", "Leave the desk."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_clean_margin":
			_show_choice_screen(
				_tr("event.clean_margin.title", "A Clean Margin"),
				_tr("event.clean_margin.body", "Someone has left an eraser on the table. It only works on yourself."),
				[
					{"text": _tr("event.clean_margin.choice1", "Pay 75 gold. Remove a Strike Form."), "action": func() -> void: _event_remove_card_for_gold(75)},
					{"text": _tr("event.clean_margin.choice2", "Pay 30 gold. Gain a random card."), "action": func() -> void: _event_buy_random_card(30)},
					{"text": _tr("event.clean_margin.choice3", "Walk past."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_red_string":
			_show_choice_screen(
				_tr("event.red_string.title", "The Red String"),
				_tr("event.red_string.body", "A red string has been tied around your finger. You did not tie it."),
				[
					{"text": _tr("event.red_string.choice1", "Accept. Gain a relic and Oath Pressure."), "action": func() -> void: _event_red_string_accept()},
					{"text": _tr("event.red_string.choice2", "Cut it. Lose 5 HP."), "action": func() -> void: _event_lose_hp(5)},
					{"text": _tr("event.red_string.choice3", "Leave it. Take 2 damage."), "action": func() -> void: _event_lose_hp(2)}
				]
			)
		"ev_revision_desk":
			_show_choice_screen(
				_tr("event.revision_desk.title", "The Revision Desk"),
				_tr("event.revision_desk.body", "The desk has been waiting for you. There is a pen, a stamp, and a price."),
				[
					{"text": _tr("event.revision_desk.choice1", "Pay 50 gold. Upgrade a card."), "action": func() -> void: _event_upgrade_for_gold(50)},
					{"text": _tr("event.revision_desk.choice2", "Bleed for it. Lose 6 HP. Upgrade a card."), "action": func() -> void: _event_upgrade_for_hp(6)},
					{"text": _tr("event.revision_desk.choice3", "Leave the desk."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_transform_lantern":
			_show_choice_screen(
				_tr("event.transform_lantern.title", "The Transform Lantern"),
				_tr("event.transform_lantern.body", "A lantern with green wax flame. Watch the flame long enough and a card you carry rewrites itself."),
				[
					{"text": _tr("event.transform_lantern.choice1", "Stare into the flame. Transform a card."), "action": func() -> void: _event_transform_card()},
					{"text": _tr("event.transform_lantern.choice2", "Pay 40 gold. Transform a card."), "action": func() -> void: _event_transform_card_for_gold(40)},
					{"text": _tr("event.transform_lantern.choice3", "Walk past."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_ink_well":
			_show_choice_screen(
				_tr("event.ink_well.title", "The Ink Well"),
				_tr("event.ink_well.body", "A black pool that has been mistaken for ink for centuries. It is something else."),
				[
					{"text": _tr("event.ink_well.choice1", "Drink. Lose 6 HP. Gain 40 gold."), "action": func() -> void: _event_drink_ink(6, 40)},
					{"text": _tr("event.ink_well.choice2", "Bottle it. Gain a random potion."), "action": func() -> void: _event_gain_potion()},
					{"text": _tr("event.ink_well.choice3", "Leave it sealed."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_dust_oracle":
			_show_choice_screen(
				_tr("event.dust_oracle.title", "The Dust Oracle"),
				_tr("event.dust_oracle.body", "A small reading-mound of dust shaped vaguely like a child. It asks for one card and one promise."),
				[
					{"text": _tr("event.dust_oracle.choice1", "Offer a card. Remove it. Heal 10 HP."), "action": func() -> void: _event_remove_any_card_for_heal(10)},
					{"text": _tr("event.dust_oracle.choice2", "Offer 30 gold. Upgrade a card."), "action": func() -> void: _event_upgrade_for_gold(30)},
					{"text": _tr("event.dust_oracle.choice3", "Refuse politely."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_weighing_scales":
			_show_choice_screen(
				_tr("event.weighing_scales.title", "The Weighing Scales"),
				_tr("event.weighing_scales.body", "A copper scale older than the tower. One pan asks for blood, the other gold. The pointer is honest."),
				[
					{"text": _tr("event.weighing_scales.choice1", "Place 8 HP on the scales. Gain 80 gold."), "action": func() -> void: _event_lose_hp_gain_gold(8, 80)},
					{"text": _tr("event.weighing_scales.choice2", "Place 60 gold. Gain 12 max HP."), "action": func() -> void: _event_buy_max_hp(60, 12)},
					{"text": _tr("event.weighing_scales.choice3", "Step away."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_burned_archive":
			_show_choice_screen(
				_tr("event.burned_archive.title", "The Burned Archive"),
				_tr("event.burned_archive.body", "A side hall has collapsed into ash. Salvage is possible. The pages object."),
				[
					{"text": _tr("event.burned_archive.choice1", "Salvage. Lose 10 HP. Gain a relic."), "action": func() -> void: _event_gain_relic_for_hp(10)},
					{"text": _tr("event.burned_archive.choice2", "Search slowly. Lose 4 HP. Gain a random card."), "action": func() -> void: _event_buy_random_card_for_hp(4)},
					{"text": _tr("event.burned_archive.choice3", "Seal the door."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_broken_standard":
			_show_choice_screen(
				_tr("event.broken_standard.title", "The Broken Standard"),
				_tr("event.broken_standard.body", "A snapped field standard leans against the shelf. Its cloth still remembers a line that refused to break."),
				[
					{"text": _tr("event.broken_standard.choice1", "Raise it. Lose 5 HP. Gain a Warrior relic."), "action": func() -> void: _event_gain_class_relic_for_hp(5)},
					{"text": _tr("event.broken_standard.choice2", "Drill the line. Gain Guarded Cut."), "action": func() -> void: _event_gain_specific_card("guarded_cut")},
					{"text": _tr("event.broken_standard.choice3", "Fold it carefully."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_unpaid_contract":
			_show_choice_screen(
				_tr("event.unpaid_contract.title", "The Unpaid Contract"),
				_tr("event.unpaid_contract.body", "A black-wax contract opens to a blank signature line. The ink moves before the pen touches it."),
				[
					{"text": _tr("event.unpaid_contract.choice1", "Sign in black ink. Lose 6 HP. Gain a Warlock relic."), "action": func() -> void: _event_gain_class_relic_for_hp(6)},
					{"text": _tr("event.unpaid_contract.choice2", "Copy the clause. Gain Index Mark and 25 gold."), "action": func() -> void: _event_gain_card_and_gold("index_mark", 25)},
					{"text": _tr("event.unpaid_contract.choice3", "Leave it unsigned."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_core_orrery":
			_show_choice_screen(
				_tr("event.core_orrery.title", "The Core Orrery"),
				_tr("event.core_orrery.body", "A small brass orrery turns without a hand. Its blue core waits for a theorem worth burning."),
				[
					{"text": _tr("event.core_orrery.choice1", "Tune the core. Lose 5 HP. Gain a Mage relic."), "action": func() -> void: _event_gain_class_relic_for_hp(5)},
					{"text": _tr("event.core_orrery.choice2", "Copy the orbit. Gain Core Spark and 20 gold."), "action": func() -> void: _event_gain_card_and_gold("core_spark", 20)},
					{"text": _tr("event.core_orrery.choice3", "Let it keep turning."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		"ev_silent_margin":
			_show_choice_screen(
				_tr("event.silent_margin.title", "The Silent Margin"),
				_tr("event.silent_margin.body", "A margin opens where no page should have one. Something inside offers a knife without a handle."),
				[
					{"text": _tr("event.silent_margin.choice1", "Reach in. Lose 5 HP. Gain an Assassin relic."), "action": func() -> void: _event_gain_class_relic_for_hp(5)},
					{"text": _tr("event.silent_margin.choice2", "Take the route. Gain Smoke Step and 20 gold."), "action": func() -> void: _event_gain_card_and_gold("smoke_step", 20)},
					{"text": _tr("event.silent_margin.choice3", "Close the margin."), "action": func() -> void: _advance_after_noncombat()}
				]
			)
		_:
			_show_choice_screen(
				_tr("event.loose_page.title", "A Loose Page"),
				_tr("event.loose_page.body", "A page peels itself from a binding and stands up. It does not look pleased."),
				[
					{"text": _tr("event.loose_page.choice1", "Fight it."), "action": func() -> void: _show_combat("combat", "Loose Folio", "e_loose_folio")},
					{"text": _tr("event.loose_page.choice2", "Flee. Take 4 damage."), "action": func() -> void: _event_lose_hp(4)},
					{"text": _tr("event.loose_page.choice3", "Speak to it."), "action": func() -> void: _event_loose_page_speak()}
				]
			)


func _roll_event_id() -> String:
	# Per-act event pools. Each tier surfaces events appropriate to where the
	# player is in the run — Act 1 is introductory (small risk/reward), Act 2
	# escalates costs, Act 3 leans into late-run swings.
	#
	# Acts also inherit shared "common" events that fit anywhere. We dedupe
	# against `events_seen` so a run won't repeat the same event until its
	# tier pool is exhausted.
	var common_pool := ["ev_quiet_stack", "ev_clean_margin", "ev_loose_page"]
	var act_pools := {
		1: ["ev_red_string", "ev_revision_desk", "ev_ink_well"],
		2: ["ev_transform_lantern", "ev_dust_oracle", "ev_weighing_scales"],
		3: ["ev_burned_archive", "ev_dust_oracle", "ev_weighing_scales"]
	}
	# Class-specific extras keep event texture aligned with the selected
	# archetype while still sharing the act/common backbone.
	var class_pools := {
		"warrior": ["ev_broken_standard"],
		"warlock": ["ev_unpaid_contract", "ev_revision_desk", "ev_dust_oracle"],
		"mage": ["ev_core_orrery"],
		"assassin": ["ev_silent_margin"]
	}
	var pool: Array = common_pool.duplicate()
	pool.append_array(act_pools.get(current_act, common_pool))
	pool.append_array(class_pools.get(_current_character_class_id(), []))
	var candidates: Array[String] = []
	for event_id in pool:
		if not events_seen.has(event_id):
			candidates.append(String(event_id))
	if candidates.is_empty():
		# Fall back to whichever events match this tier — re-rolling is fine
		# because events_seen is a "first-time bias", not a hard exclusion.
		for event_id in pool:
			candidates.append(String(event_id))
	if candidates.is_empty():
		# Absolute fallback: any event that exists.
		candidates = ["ev_quiet_stack"]
	return candidates[event_rng.randi_range(0, candidates.size() - 1)]


func _event_gain_relic_for_hp(cost: int) -> void:
	player_hp = max(1, player_hp - cost)
	_gain_random_relic()
	_advance_after_noncombat()


func _event_gain_class_relic_for_hp(cost: int) -> void:
	player_hp = max(1, player_hp - cost)
	_gain_random_relic_from_pool(_current_character_class_id())
	_advance_after_noncombat()


func _event_gain_specific_card(card_id: String) -> void:
	if card_database.has(card_id):
		run_deck_ids.append(card_id)
	_advance_after_noncombat()


func _event_gain_card_and_gold(card_id: String, amount: int) -> void:
	if card_database.has(card_id):
		run_deck_ids.append(card_id)
	gold += amount
	_advance_after_noncombat()


func _event_remove_card_for_gold(price: int) -> void:
	if gold >= price and run_deck_ids.size() > 8:
		gold -= price
		_show_card_picker_for_remove(_tr("picker.remove_strike.title", "Remove a Strike Form"), _tr("picker.remove_strike.hint", "Choose the copy to remove from this run."), true, price)
	else:
		_show_unavailable_event_choice(_tr("event.unavailable.remove", "Need enough gold and a deck larger than 8 cards."))


func _event_buy_random_card(price: int) -> void:
	if gold >= price:
		gold -= price
		run_deck_ids.append(_random_reward_card_id())
	_advance_after_noncombat()


func _event_red_string_accept() -> void:
	run_deck_ids.append("oath_pressure")
	_gain_random_relic()
	_advance_after_noncombat()


func _event_lose_hp(amount: int) -> void:
	player_hp = max(1, player_hp - amount)
	_advance_after_noncombat()


func _event_upgrade_for_gold(price: int) -> void:
	if gold >= price:
		gold -= price
		_show_card_picker_for_upgrade(_tr("picker.upgrade.title", "Upgrade a card"), _tr("picker.upgrade.hint", "Choose an unupgraded card to improve."), true, price, 0)
	else:
		_show_unavailable_event_choice(_tr("event.unavailable.gold", "You do not have enough gold."))


func _event_upgrade_for_hp(cost: int) -> void:
	player_hp = max(1, player_hp - cost)
	_show_card_picker_for_upgrade(_tr("picker.upgrade.title", "Upgrade a card"), _tr("picker.upgrade.hint", "Choose an unupgraded card to improve."), true, 0, cost)


func _event_transform_card() -> void:
	if not _has_transform_target():
		_advance_after_noncombat()
		return
	_show_card_picker_for_transform(_tr("picker.transform.title", "Transform a card"), _tr("picker.transform.hint", "Choose a card. The lantern rewrites it into another of the same type."), true)


func _event_transform_card_for_gold(price: int) -> void:
	if gold < price or not _has_transform_target():
		_show_unavailable_event_choice(_tr("event.unavailable.transform", "Need enough gold and a non-basic card that can be transformed."))
		return
	gold -= price
	_show_card_picker_for_transform(_tr("picker.transform.title", "Transform a card"), _tr("picker.transform_green.hint", "Choose a card to rewrite under green wax flame."), true)


func _event_drink_ink(hp_cost: int, gold_gain: int) -> void:
	player_hp = max(1, player_hp - hp_cost)
	gold += gold_gain
	_advance_after_noncombat()


func _event_gain_potion() -> void:
	_gain_random_potion()
	_advance_after_noncombat()


func _event_remove_any_card_for_heal(heal_amount: int) -> void:
	if run_deck_ids.size() <= 8:
		_show_unavailable_event_choice(_tr("event.unavailable.deck", "Your deck is too small to offer a card."))
		return
	pending_card_pick_context = {"action": "remove_any", "return_to_map": true, "refund_gold": 0, "refund_hp": 0, "post_heal": heal_amount}
	_show_run_deck_picker(_tr("picker.offer.title", "Offer a card"), _tr("picker.offer.hint", "Remove one card from this run."), Callable(self, "_is_remove_any_pickable"))


func _event_lose_hp_gain_gold(hp_cost: int, gold_gain: int) -> void:
	player_hp = max(1, player_hp - hp_cost)
	gold += gold_gain
	_advance_after_noncombat()


func _event_buy_max_hp(price: int, amount: int) -> void:
	if gold >= price:
		gold -= price
		player_max_hp += amount
		player_hp = min(player_max_hp, player_hp + amount)
	else:
		_show_unavailable_event_choice(_tr("event.unavailable.gold", "You do not have enough gold."))
		return
	_advance_after_noncombat()


func _event_buy_random_card_for_hp(hp_cost: int) -> void:
	player_hp = max(1, player_hp - hp_cost)
	run_deck_ids.append(_random_reward_card_id())
	_advance_after_noncombat()


func _event_loose_page_speak() -> void:
	if event_rng.randi_range(1, 100) <= 25:
		gold += 10
	else:
		gold += 30
	_advance_after_noncombat()


func _show_unavailable_event_choice(reason: String) -> void:
	_show_choice_screen(
		_tr("event.unavailable.title", "Choice unavailable"),
		reason,
		[{"text": _tr("event.unavailable.continue", "Return to the route."), "action": func() -> void: _advance_after_noncombat()}]
	)


func _show_shop() -> void:
	shop_visits += 1
	current_shop_cards = _shop_card_offers()
	current_shop_relics = _shop_relic_offers()
	current_shop_potions = _shop_potion_offers()
	_show_shop_view()


func _show_shop_view() -> void:
	_clear_screen()
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_shop_enter")
	var shop = ShopViewScript.new()
	shop.card_purchased.connect(_on_shop_card_purchased)
	shop.relic_purchased.connect(_on_shop_relic_purchased)
	shop.potion_purchased.connect(_on_shop_potion_purchased)
	shop.remove_card_requested.connect(_on_shop_remove_requested)
	shop.leave_pressed.connect(_advance_after_noncombat)
	current_screen = shop
	add_child(shop)
	_refresh_shop_view()


func _refresh_shop_view() -> void:
	if current_screen == null or not current_screen.has_method("set_offers"):
		return
	current_screen.set_offers(gold, current_shop_cards, current_shop_relics, current_shop_potions, _remove_price(), _has_card("strike_form") and run_deck_ids.size() > 8)


func _on_shop_card_purchased(card_id: String, price: int) -> void:
	if gold >= price:
		gold -= price
		run_deck_ids.append(card_id)
		var am = _audio()
		if am != null:
			am.play_sfx("sfx_shop_buy")
		if current_screen != null and current_screen.has_method("mark_card_sold"):
			current_screen.mark_card_sold(card_id)
	_save_run()
	_refresh_shop_view()


func _on_shop_relic_purchased(relic_id: String, price: int) -> void:
	if gold >= price and not relic_ids.has(relic_id):
		gold -= price
		relic_ids.append(relic_id)
		var am = _audio()
		if am != null:
			am.play_sfx("sfx_shop_buy")
		if current_screen != null and current_screen.has_method("mark_relic_sold"):
			current_screen.mark_relic_sold(relic_id)
	_save_run()
	_refresh_shop_view()


func _on_shop_potion_purchased(potion_id: String, price: int) -> void:
	if gold >= price and _potion_count() < 3:
		gold -= price
		for index in potions.size():
			if potions[index] == null:
				potions[index] = potion_id
				break
		var am = _audio()
		if am != null:
			am.play_sfx("sfx_shop_buy")
		if current_screen != null and current_screen.has_method("mark_potion_sold"):
			current_screen.mark_potion_sold(potion_id)
	_save_run()
	_refresh_shop_view()


func _on_shop_remove_requested(_price_from_view: int) -> void:
	var price := _remove_price()
	if gold < price or not _has_card("strike_form") or run_deck_ids.size() <= 8:
		_refresh_shop_view()
		return
	gold -= price
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_shop_buy")
	_show_card_picker_for_remove(_tr("picker.shop_remove.title", "Shop remove"), _tr("picker.shop_remove.hint", "Choose a Strike Form to remove. The vendor has already taken the gold."), false, price)


func _buy_card(card_id: String, price: int) -> void:
	if gold >= price:
		gold -= price
		run_deck_ids.append(card_id)
	_advance_after_noncombat()


func _buy_relic(relic_id: String, price: int) -> void:
	if gold >= price and not relic_ids.has(relic_id):
		gold -= price
		relic_ids.append(relic_id)
	_advance_after_noncombat()


func _buy_potion(potion_id: String, price: int) -> void:
	if gold >= price and _potion_count() < 3:
		gold -= price
		for index in potions.size():
			if potions[index] == null:
				potions[index] = potion_id
				break
	_advance_after_noncombat()


func _shop_remove_card(leave_after: bool = true) -> void:
	var price := _remove_price()
	if gold >= price and _has_card("strike_form") and run_deck_ids.size() > 8:
		gold -= price
		_remove_first_matching_card("strike_form")
		card_removals += 1
	if leave_after:
		_advance_after_noncombat()
	else:
		_save_run()


func _show_campfire() -> void:
	var am = _audio()
	if am != null:
		am.play_music("mus_campfire", 800)
		am.play_sfx("sfx_event_open")
	_clear_screen()
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	current_screen = screen
	add_child(screen)

	var bg_art := TextureRect.new()
	bg_art.texture = _load_png_texture("res://art/generated/backgrounds/campfire_waxlight_nook.png")
	bg_art.ignore_texture_size = true
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_art.modulate = Color(1, 1, 1, 0.68)
	screen.add_child(bg_art)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.012, 0.006, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -470
	panel.offset_top = -245
	panel.offset_right = 470
	panel.offset_bottom = 245
	panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.055, 0.036, 0.024, 0.82), Color(0.86, 0.54, 0.24, 0.72)))
	screen.add_child(panel)

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	panel.add_child(box)

	var story_box := VBoxContainer.new()
	story_box.custom_minimum_size = Vector2(420, 0)
	story_box.add_theme_constant_override("separation", 14)
	box.add_child(story_box)

	var title := Label.new()
	title.text = _tr("camp.title", "Waxlight Nook")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	story_box.add_child(title)

	var state := Label.new()
	state.text = _tr("camp.state", "HP %d/%d    Gold %d    Deck %d") % [player_hp, player_max_hp, gold, run_deck_ids.size()]
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.add_theme_font_size_override("font_size", 15)
	state.modulate = Color(0.95, 0.84, 0.64, 0.95)
	story_box.add_child(state)

	var body := Label.new()
	body.text = _tr("camp.body", "Warm wax pools beside an old blade. The archive is quiet for one breath.")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	story_box.add_child(body)

	var scene_art := TextureRect.new()
	scene_art.texture = _load_png_texture("res://art/generated/sprites/campfire_wax_flame.png")
	scene_art.ignore_texture_size = true
	scene_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	scene_art.custom_minimum_size = Vector2(0, 190)
	story_box.add_child(scene_art)

	var action_box := VBoxContainer.new()
	action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_box.add_theme_constant_override("separation", 12)
	box.add_child(action_box)

	_add_campfire_action(action_box, _tr("camp.rest", "Rest: heal 30% HP"), _tr("camp.rest_hint", "Heal and return to the map."), _load_png_texture("res://art/generated/ui/campfire_rest_icon.png"), Callable(self, "_campfire_rest"), true)
	_add_campfire_action(action_box, _tr("camp.upgrade", "Smith: upgrade a card"), _tr("camp.upgrade_hint", "Choose one unupgraded card."), _load_png_texture("res://art/generated/ui/campfire_upgrade_icon.png"), func() -> void:
		_show_card_picker_for_upgrade(_tr("camp.upgrade", "Waxlight upgrade"), _tr("camp.upgrade_hint", "Choose one unupgraded card."), true), _has_upgrade_target())
	_add_campfire_action(action_box, _tr("camp.remove", "Burn: remove a card"), _tr("camp.remove_hint", "Burn a non-basic card permanently."), null, func() -> void:
		_show_card_picker_for_remove_any(_tr("camp.remove", "Waxlight Burn"), _tr("camp.remove_hint", "Burn a non-basic card permanently."), true), run_deck_ids.size() > 8)
	_add_campfire_action(action_box, _tr("camp.transform", "Lift: transform a card"), _tr("camp.transform_hint", "Rewrite one card into another of the same type."), null, func() -> void:
		_show_card_picker_for_transform(_tr("camp.transform", "Waxlight Lift"), _tr("camp.transform_hint", "Rewrite one card into another of the same type."), true), _has_transform_target())


func _add_campfire_action(parent: VBoxContainer, title_text: String, hint_text: String, icon: Texture2D, action: Callable, enabled: bool) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 86)
	button.disabled = not enabled
	button.text = title_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = hint_text
	button.pressed.connect(action)
	parent.add_child(button)


func _has_transform_target() -> bool:
	for entry in run_deck_ids:
		var card_id := String(entry).trim_suffix("+")
		if not card_database.has(card_id):
			continue
		var data = card_database[card_id]
		var rarity := String(data.rarity)
		var card_type := String(data.card_type)
		if rarity == "basic" or card_type == "curse" or card_type == "status":
			continue
		return true
	return false


func _campfire_rest() -> void:
	player_hp = min(player_max_hp, player_hp + floori(float(player_max_hp) * 0.30))
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_campfire_rest")
	_advance_after_noncombat()


func _campfire_upgrade_card(index: int) -> void:
	if index >= 0 and index < run_deck_ids.size() and not run_deck_ids[index].ends_with("+"):
		run_deck_ids[index] = "%s+" % run_deck_ids[index]
	var am = _audio()
	if am != null:
		am.play_sfx("sfx_campfire_upgrade")
	_advance_after_noncombat()


func _show_card_picker_for_upgrade(title: String, hint: String, return_to_map: bool, refund_gold: int = 0, refund_hp: int = 0) -> void:
	pending_card_pick_context = {"action": "upgrade", "return_to_map": return_to_map, "refund_gold": refund_gold, "refund_hp": refund_hp}
	_show_run_deck_picker(title, hint, Callable(self, "_is_upgrade_pickable"))


func _show_card_picker_for_remove(title: String, hint: String, return_to_map: bool, refund_gold: int = 0) -> void:
	pending_card_pick_context = {"action": "remove", "return_to_map": return_to_map, "refund_gold": refund_gold, "refund_hp": 0}
	_show_run_deck_picker(title, hint, Callable(self, "_is_remove_pickable"))


func _show_run_deck_picker(title: String, hint: String, predicate: Callable) -> void:
	var picker = CardPickerScript.new()
	picker.picked.connect(_on_run_deck_card_picked.bind(picker))
	picker.cancelled.connect(_on_run_deck_pick_cancelled.bind(picker))
	add_child(picker)
	picker.show_picker(title, hint, _run_deck_card_instances(), predicate)


func _on_run_deck_card_picked(_card_instance, source_index: int, picker: Control) -> void:
	if picker != null:
		picker.queue_free()
	var action := String(pending_card_pick_context.get("action", ""))
	if source_index >= 0 and source_index < run_deck_ids.size():
		if action == "upgrade" and not run_deck_ids[source_index].ends_with("+"):
			run_deck_ids[source_index] = "%s+" % run_deck_ids[source_index]
		elif action == "remove" and run_deck_ids[source_index].trim_suffix("+") == "strike_form":
			run_deck_ids.remove_at(source_index)
			card_removals += 1
		elif action == "remove_any" and run_deck_ids.size() > 8:
			run_deck_ids.remove_at(source_index)
			card_removals += 1
		elif action == "transform":
			var old_id := String(run_deck_ids[source_index]).trim_suffix("+")
			var replacement := _random_transform_replacement(old_id)
			if replacement != "":
				run_deck_ids[source_index] = replacement
	_finish_card_picker_context()


func _on_run_deck_pick_cancelled(picker: Control) -> void:
	if picker != null:
		picker.queue_free()
	gold += int(pending_card_pick_context.get("refund_gold", 0))
	player_hp = min(player_max_hp, player_hp + int(pending_card_pick_context.get("refund_hp", 0)))
	_finish_card_picker_context()


func _finish_card_picker_context() -> void:
	var return_to_map := bool(pending_card_pick_context.get("return_to_map", true))
	var post_heal := int(pending_card_pick_context.get("post_heal", 0))
	if post_heal > 0:
		player_hp = min(player_max_hp, player_hp + post_heal)
	pending_card_pick_context.clear()
	if return_to_map:
		_advance_after_noncombat()
	else:
		_save_run()
		_refresh_shop_view()


func _deck_summary_text() -> String:
	var attack_count := 0
	var skill_count := 0
	var power_count := 0
	for entry in run_deck_ids:
		var card_id := String(entry).trim_suffix("+")
		if not card_database.has(card_id):
			continue
		var card_type := String(card_database[card_id].card_type)
		if card_type == "attack":
			attack_count += 1
		elif card_type == "skill":
			skill_count += 1
		elif card_type == "power":
			power_count += 1
	return _tr("map.deck_summary", "Deck %d  ·  %d atk / %d skl / %d pwr") % [run_deck_ids.size(), attack_count, skill_count, power_count]


func _show_deck_modal_overlay() -> void:
	const DeckModalScriptLocal := preload("res://scripts/ui/deck_modal.gd")
	# Ensure only one modal at a time even if the user clicks the capsule rapidly.
	for child in get_children():
		if child is Control and child.has_method("show_deck") and child.has_method("_on_close_pressed"):
			child.queue_free()
	var modal = DeckModalScriptLocal.new()
	add_child(modal)
	var instances: Array = []
	for entry in _run_deck_card_instances():
		instances.append(entry["card"])
	modal.show_deck(_tr("modal.run_deck", "Run Deck"), instances)
	modal.closed.connect(func() -> void: modal.queue_free())


func _run_deck_card_instances() -> Array:
	var cards: Array = []
	for index in run_deck_ids.size():
		var entry := run_deck_ids[index]
		var card_id := String(entry).trim_suffix("+")
		if not card_database.has(card_id):
			continue
		var card = CardInstanceScript.new()
		card.setup(card_database[card_id], String(entry).ends_with("+"))
		cards.append({"card": card, "index": index})
	return cards


func _is_upgrade_pickable(card_instance) -> bool:
	return card_instance != null and not bool(card_instance.upgraded)


func _is_remove_pickable(card_instance) -> bool:
	return card_instance != null and String(card_instance.data.id) == "strike_form"


func _is_remove_any_pickable(card_instance) -> bool:
	if card_instance == null:
		return false
	var rarity := String(card_instance.data.rarity)
	return rarity != "basic"


func _is_transform_pickable(card_instance) -> bool:
	if card_instance == null:
		return false
	var card_type := String(card_instance.data.card_type)
	if card_type == "curse" or card_type == "status":
		return false
	var rarity := String(card_instance.data.rarity)
	return rarity != "basic"


func _random_transform_replacement(old_id: String) -> String:
	var old_data = card_database.get(old_id, null)
	if old_data == null:
		return ""
	var target_type := String(old_data.card_type)
	var pool: Array[String] = []
	for card_id in _reward_card_pool():
		var entry = card_database[card_id]
		if String(entry.id) == old_id:
			continue
		if String(entry.card_type) != target_type:
			continue
		pool.append(String(entry.id))
	if pool.is_empty():
		return ""
	return pool[reward_rng.randi_range(0, pool.size() - 1)]


func _show_card_picker_for_remove_any(title: String, hint: String, return_to_map: bool, refund_gold: int = 0, refund_hp: int = 0) -> void:
	pending_card_pick_context = {"action": "remove_any", "return_to_map": return_to_map, "refund_gold": refund_gold, "refund_hp": refund_hp}
	_show_run_deck_picker(title, hint, Callable(self, "_is_remove_any_pickable"))


func _show_card_picker_for_transform(title: String, hint: String, return_to_map: bool, refund_gold: int = 0, refund_hp: int = 0) -> void:
	pending_card_pick_context = {"action": "transform", "return_to_map": return_to_map, "refund_gold": refund_gold, "refund_hp": refund_hp}
	_show_run_deck_picker(title, hint, Callable(self, "_is_transform_pickable"))


func _has_upgrade_target() -> bool:
	for entry in run_deck_ids:
		if not String(entry).ends_with("+"):
			return true
	return false


func _shop_card_offers() -> Array:
	var offers: Array = []
	var selected: Array[String] = []
	var attacks := _shop_card_candidates_for_type("attack", selected)
	var skills := _shop_card_candidates_for_type("skill", selected)
	if not attacks.is_empty():
		selected.append(_pick_id(attacks))
	if not skills.is_empty():
		selected.append(_pick_id(skills))
	var remaining := _shop_card_candidates_for_type("", selected)
	while selected.size() < 3 and not remaining.is_empty():
		var card_id := _pick_id(remaining)
		selected.append(card_id)
		remaining.erase(card_id)
	for card_id in selected:
		var price := _price_with_variance(_card_base_price(_card_rarity(card_id)))
		var card = card_database.get(card_id, null)
		var description := ""
		var card_type := ""
		if card != null:
			description = String(card.description)
			card_type = String(card.card_type)
		offers.append({"id": card_id, "name": _card_display_name(card_id), "price": price, "rarity": _card_rarity(card_id), "description": description, "card_type": card_type, "card_data": card})
	return offers


func _shop_relic_offers() -> Array:
	var offers: Array = []
	while offers.size() < 2:
		var source_pool := _roll_relic_source_pool(true)
		var candidates := _relic_candidates(source_pool)
		if candidates.is_empty() and source_pool != "":
			candidates = _relic_candidates("")
		for offer in offers:
			candidates.erase(String(offer.get("id", "")))
		if candidates.is_empty():
			break
		var relic_id := _pick_id(candidates)
		var relic = relic_database[relic_id]
		var price := 150
		if relic.rarity == "uncommon":
			price = 250
		elif relic.rarity == "rare":
			price = 300
		offers.append({
			"id": relic_id,
			"name": relic.display_name,
			"price": _price_with_variance(price),
			"rarity": String(relic.rarity),
			"description": String(relic.description),
			"icon_path": "res://art/generated/icons/relic_%s.png" % relic_id
		})
	return offers


func _shop_potion_offers() -> Array:
	var ids: Array[String] = []
	for potion_id in potion_database.keys():
		ids.append(String(potion_id))
	var offers: Array = []
	while offers.size() < 2 and not ids.is_empty():
		var potion_id := _pick_id(ids)
		ids.erase(potion_id)
		var potion = potion_database[potion_id]
		var price := 50
		if potion.rarity == "uncommon":
			price = 70
		elif potion.rarity == "rare":
			price = 100
		offers.append({
			"id": potion_id,
			"name": potion.display_name,
			"price": _price_with_variance(price),
			"rarity": String(potion.rarity),
			"description": String(potion.description),
			"icon_path": "res://art/generated/icons/potion_%s.png" % potion_id
		})
	return offers


func _remove_price() -> int:
	return min(175, 75 + card_removals * 25)


func _random_reward_card_id() -> String:
	var source_pool := _roll_reward_source_pool(false)
	var rarity := _roll_run_reward_rarity()
	var pool := _reward_card_candidates_for_rarity(rarity, source_pool)
	if pool.is_empty() and source_pool != "":
		pool = _reward_card_candidates_for_rarity(rarity, "")
	if pool.is_empty():
		pool = _reward_card_pool()
	return pool[reward_rng.randi_range(0, pool.size() - 1)]


func _reward_card_pool(source_pool: String = "") -> Array[String]:
	var ids: Array[String] = []
	for card_id in card_database.keys():
		if _is_rewardable_card(String(card_id), source_pool):
			ids.append(String(card_id))
	if not ids.is_empty():
		return ids
	return ["measured_cut", "brace", "shield_tap", "quick_read", "forward_step", "break_rhythm", "oath_pressure"]


func _is_rewardable_card(card_id: String, source_pool: String = "") -> bool:
	if not card_database.has(card_id):
		return false
	var card = card_database[card_id]
	if not bool(card.get("rewardable")):
		return false
	var rarity := String(card.rarity)
	if rarity == "basic" or rarity == "special":
		return false
	var card_type := String(card.card_type)
	if card_type == "curse" or card_type == "status":
		return false
	var pool_id := _card_pool_id(card)
	if pool_id == "status" or pool_id == "curse" or pool_id == "generated" or pool_id == "event":
		return false
	if source_pool != "" and pool_id != source_pool:
		return false
	return _card_allowed_for_current_character(card)


func _card_allowed_for_current_character(card) -> bool:
	var pool_id := _card_pool_id(card)
	if pool_id == "public":
		return true
	return pool_id == _current_character_pool_id()


func _card_pool_id(card) -> String:
	var pool_id := String(card.get("pool_id"))
	if pool_id == "":
		return "public"
	return pool_id


func _current_character_pool_id() -> String:
	return _character_card_pool_id(character_id if character_id != "" else selected_character_id)


func _character_card_pool_id(char_id: String) -> String:
	var data = CharacterCatalogScript.resolve(character_catalog, char_id)
	if data != null:
		var pool_id := String(data.get("card_pool_id"))
		if pool_id != "":
			return pool_id
	if char_id.begins_with("char_"):
		return char_id.trim_prefix("char_")
	return char_id


func _roll_reward_source_pool(for_shop: bool = false) -> String:
	var character_pool := _current_character_pool_id()
	var roll := reward_rng.randi_range(1, 100)
	if for_shop:
		if roll <= 60:
			return character_pool
		if roll <= 95:
			return "public"
		return character_pool
	if roll <= 85:
		return character_pool
	return "public"


func _card_rarity(card_id: String) -> String:
	if card_database.has(card_id):
		return String(card_database[card_id].rarity)
	if ["final_argument", "binding_cut", "red_string", "last_word"].has(card_id):
		return "rare"
	if ["redline", "counterseal", "quiet_revision", "stamp_down", "candle_count", "hardcopy", "break_rhythm", "oath_pressure"].has(card_id):
		return "uncommon"
	return "common"


func _card_display_name(card_entry: String) -> String:
	var base_id := String(card_entry).trim_suffix("+")
	var display_name := String(card_names.get(base_id, base_id.replace("_", " ").capitalize()))
	if card_database.has(base_id):
		display_name = String(card_database[base_id].display_name)
	display_name = _localized_name(base_id, display_name)
	if String(card_entry).ends_with("+"):
		display_name += "+"
	return display_name


func _reward_card_candidates_for_type(card_type: String, excluded: Array[String], source_pool: String = "") -> Array[String]:
	var ids: Array[String] = []
	for card_id in _reward_card_pool(source_pool):
		if excluded.has(card_id):
			continue
		if card_type == "" or (card_database.has(card_id) and String(card_database[card_id].card_type) == card_type):
			ids.append(card_id)
	return ids


func _shop_card_candidates_for_type(card_type: String, excluded: Array[String]) -> Array[String]:
	var source_pool := _roll_reward_source_pool(true)
	var ids := _reward_card_candidates_for_type(card_type, excluded, source_pool)
	if ids.is_empty() and source_pool != "":
		ids = _reward_card_candidates_for_type(card_type, excluded, "")
	return ids


func _reward_card_candidates_for_rarity(rarity: String, source_pool: String = "") -> Array[String]:
	var ids: Array[String] = []
	for card_id in _reward_card_pool(source_pool):
		if _card_rarity(card_id) == rarity:
			ids.append(card_id)
	return ids


func _roll_run_reward_rarity() -> String:
	var roll := reward_rng.randi_range(1, 100)
	if roll <= 60:
		return "common"
	if roll <= 97:
		return "uncommon"
	return "rare"


func _card_base_price(rarity: String) -> int:
	if rarity == "uncommon":
		return 75
	if rarity == "rare":
		return 150
	return 50


func _price_with_variance(base_price: int) -> int:
	var modifier := reward_rng.randf_range(0.9, 1.1)
	return int(round(float(base_price) * modifier / 5.0) * 5.0)


func _pick_id(ids: Array[String]) -> String:
	return ids[reward_rng.randi_range(0, ids.size() - 1)]


func _upgrade_first_eligible_card() -> void:
	for index in run_deck_ids.size():
		if not run_deck_ids[index].ends_with("+"):
			run_deck_ids[index] = "%s+" % run_deck_ids[index]
			return


func _has_card(card_id: String) -> bool:
	for entry in run_deck_ids:
		if entry.trim_suffix("+") == card_id:
			return true
	return false


func _remove_first_matching_card(card_id: String) -> void:
	for index in run_deck_ids.size():
		if run_deck_ids[index].trim_suffix("+") == card_id:
			run_deck_ids.remove_at(index)
			return


func _advance_after_noncombat() -> void:
	_save_run()
	_show_map()


func _show_choice_screen(title_text: String, body_text: String, choices: Array) -> void:
	_clear_screen()
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	current_screen = screen
	add_child(screen)

	var bg := ColorRect.new()
	bg.color = _choice_bg_color(title_text)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)

	var bg_art := TextureRect.new()
	bg_art.texture = _choice_background_texture(title_text)
	bg_art.ignore_texture_size = true
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_art.modulate = Color(1, 1, 1, 0.58)
	screen.add_child(bg_art)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -460
	panel.offset_top = -240
	panel.offset_right = 460
	panel.offset_bottom = 240
	screen.add_child(panel)

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var story_box := VBoxContainer.new()
	story_box.custom_minimum_size = Vector2(440, 0)
	story_box.add_theme_constant_override("separation", 14)
	box.add_child(story_box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_box.add_child(title)

	var state := Label.new()
	state.text = _tr("modal.state", "HP %d/%d    Gold %d    Deck %d") % [player_hp, player_max_hp, gold, run_deck_ids.size()]
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_box.add_child(state)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_box.add_child(body)

	var scene_art := TextureRect.new()
	scene_art.texture = _choice_scene_texture(title_text)
	scene_art.ignore_texture_size = true
	scene_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	scene_art.custom_minimum_size = Vector2(0, 140)
	story_box.add_child(scene_art)

	var choices_box := VBoxContainer.new()
	choices_box.custom_minimum_size = Vector2(470, 0)
	choices_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_box.add_theme_constant_override("separation", 12)
	box.add_child(choices_box)

	for choice in choices:
		var choice_icon := _choice_button_icon(String(choice.text))
		var hint := String(choice.get("hint", ""))
		var enabled := bool(choice.get("enabled", true))
		_add_choice_action(choices_box, String(choice.text), hint, choice_icon, choice.action, enabled)


func _add_choice_action(parent: VBoxContainer, title_text: String, hint_text: String, icon: Texture2D, action: Callable, enabled: bool = true) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 78)
	button.text = title_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = hint_text
	button.disabled = not enabled
	button.pressed.connect(action)
	parent.add_child(button)


func _add_action_row_content(button: Button, title_text: String, hint_text: String, icon: Texture2D) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 12
	margin.offset_top = 8
	margin.offset_right = -12
	margin.offset_bottom = -8
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(34, 34)
		icon_rect.ignore_texture_size = true
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_rect)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)

	var title := Label.new()
	title.text = title_text
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 15)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(title)

	if hint_text != "":
		var hint := Label.new()
		hint.text = hint_text
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_font_size_override("font_size", 12)
		hint.modulate = Color(0.82, 0.76, 0.66, 0.88)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_box.add_child(hint)


func _choice_button_icon(choice_text: String) -> Texture2D:
	var lower := choice_text.to_lower()
	if lower.find("rest") >= 0 or lower.find("heal") >= 0 or choice_text.find("回复") >= 0 or choice_text.find("休息") >= 0:
		return _load_png_texture("res://art/generated/ui/campfire_rest_icon.png")
	if lower.find("upgrade") >= 0 or choice_text.find("升级") >= 0 or choice_text.find("锻牌") >= 0:
		return _load_png_texture("res://art/generated/ui/campfire_upgrade_icon.png")
	return null


func _choice_bg_color(title_text: String) -> Color:
	if title_text.find("Vendor") >= 0 or title_text.find("商人") >= 0:
		return Color(0.10, 0.085, 0.055)
	if title_text.find("Nook") >= 0 or title_text.find("休憩") >= 0:
		return Color(0.11, 0.06, 0.04)
	if title_text.find("Lost") >= 0 or title_text.find("失败") >= 0:
		return Color(0.08, 0.03, 0.03)
	return Color(0.08, 0.09, 0.10)


func _choice_background_texture(title_text: String) -> Texture2D:
	# Map each event/title to its bespoke background. Falls back to the generic
	# archive-contract scene for anything we haven't authored a unique bg for.
	if title_text.find("Vendor") >= 0 or title_text.find("商人") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/shop_quiet_vendor.png")
	if title_text.find("Nook") >= 0 or title_text.find("Camp") >= 0 or title_text.find("Waxfire") >= 0 or title_text.find("休憩") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/campfire_waxlight_nook.png")
	if title_text.find("Lost") >= 0 or title_text.find("Defeat") >= 0 or title_text.find("失败") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/defeat_archive_closing.png")
	if title_text.find("Quiet Stack") >= 0 or title_text.find("静默书堆") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_quiet_stack.png")
	if title_text.find("Silent Margin") >= 0 or title_text.find("静默页边") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_silent_margin.png")
	if title_text.find("Clean Margin") >= 0 or title_text.find("干净页边") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_clean_margin.png")
	if title_text.find("Red String") >= 0 or title_text.find("红线") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_red_string.png")
	if title_text.find("Revision") >= 0 or title_text.find("修订桌") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_revision_desk.png")
	if title_text.find("Transform Lantern") >= 0 or title_text.find("变化提灯") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_transform_lantern.png")
	if title_text.find("Ink Well") >= 0 or title_text.find("墨井") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_ink_well.png")
	if title_text.find("Dust Oracle") >= 0 or title_text.find("尘土神谕") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_dust_oracle.png")
	if title_text.find("Weighing Scales") >= 0 or title_text.find("称量天平") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_weighing_scales.png")
	if title_text.find("Burned Archive") >= 0 or title_text.find("焚毁档案室") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_burned_archive.png")
	if title_text.find("Broken Standard") >= 0 or title_text.find("断裂战旗") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_broken_standard.png")
	if title_text.find("Unpaid Contract") >= 0 or title_text.find("未付契约") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_unpaid_contract.png")
	if title_text.find("Core Orrery") >= 0 or title_text.find("核心星仪") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_core_orrery.png")
	if title_text.find("Loose Page") >= 0 or title_text.find("Loose Folio") >= 0 or title_text.find("散页") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/event_loose_page.png")
	if title_text.find("Archive Key") >= 0 or title_text.find("Victory") >= 0 or title_text.find("档案钥匙") >= 0 or title_text.find("胜利") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/victory_archive_key_scene.png")
	return _load_png_texture("res://art/generated/backgrounds/event_archive_contract.png")


func _choice_scene_tag(title_text: String) -> String:
	if title_text.find("Vendor") >= 0 or title_text.find("商人") >= 0:
		return _tr("scene.shop", "[ LANTERN SHOP ]")
	if title_text.find("Nook") >= 0 or title_text.find("休憩") >= 0:
		return _tr("scene.camp", "[ WAXFIRE CAMP ]")
	if title_text.find("Lost") >= 0 or title_text.find("失败") >= 0:
		return _tr("scene.lost", "[ RUN LOST ]")
	return _tr("scene.event", "[ ARCHIVE EVENT ]")


func _choice_scene_texture(title_text: String) -> Texture2D:
	if title_text.find("Vendor") >= 0 or title_text.find("商人") >= 0:
		return _load_png_texture("res://art/generated/sprites/shop_vendor.png")
	if title_text.find("Nook") >= 0 or title_text.find("休憩") >= 0:
		return _load_png_texture("res://art/generated/sprites/campfire_wax_flame.png")
	if title_text.find("Lost") >= 0 or title_text.find("失败") >= 0:
		return _load_png_texture("res://art/generated/backgrounds/defeat_archive_closing.png")
	if title_text.find("Margin") >= 0 or title_text.find("页边") >= 0:
		return _load_png_texture("res://art/generated/sprites/event_ink_contract.png")
	return _load_png_texture("res://art/generated/sprites/event_ink_contract.png")


func _advance_floor() -> void:
	_advance_after_noncombat()


func _show_act_transition() -> void:
	var titles := {
		2: _tr("act2.title", "Act II: The Chronicler's Wing"),
		3: _tr("act3.title", "Act III: The Grand Vault")
	}
	var bodies := {
		2: _tr("act2.body", "The first seal cracks. Beyond it, half-burnt pages reorganise themselves around a Chronicler who has been waiting for someone to read along. You feel the archive shift one floor deeper."),
		3: _tr("act3.body", "The Chronicler's quiet folds shut. A vault door opens onto rows of unread shelves. Somewhere at the back, the Grand Archivist tallies the cost of your trespass.")
	}
	var title := String(titles.get(current_act, _tr("act.next_title", "Next Act")))
	var body := String(bodies.get(current_act, _tr("act.default_body", "The archive opens further.")))
	_show_choice_screen(
		title,
		_tr("act.recover", "%s\n\nYou recover slightly. A new relic is pressed into your hand by the silence.") % body,
		[
			{"text": _tr("act.continue", "Press onward"), "action": func() -> void: _show_map()}
		]
	)


func _show_defeat() -> void:
	_show_run_summary("defeat")


# A1.6 — Run summary screen.
# Replaces the old single-line defeat / completion path with a richer modal that
# surfaces what the player accomplished this run: outcome, final HP, deck size
# + composition, relics gained, floors / acts cleared, gold earned.
# Called from `_on_combat_lost` (outcome="defeat") and `_on_boss_defeated`
# when current_act >= FINAL_ACT (outcome="victory").
func _show_run_summary(outcome: String) -> void:
	_clear_screen()
	var am = _audio()
	if am != null:
		if outcome == "victory":
			am.play_sfx("sfx_ui_run_start")
		# defeat: leave music as-is so the boss-loss tail plays out.

	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	current_screen = screen
	add_child(screen)

	var bg := ColorRect.new()
	if outcome == "victory":
		bg.color = Color(0.06, 0.05, 0.02, 1)
	else:
		bg.color = Color(0.04, 0.02, 0.02, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)

	var bg_art := TextureRect.new()
	if outcome == "victory":
		bg_art.texture = _load_png_texture("res://art/generated/sprites/archive_key.png")
	else:
		bg_art.texture = _load_png_texture("res://art/generated/backgrounds/living_archive_route_board.png")
	bg_art.ignore_texture_size = true
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_art.modulate = Color(1, 1, 1, 0.32)
	screen.add_child(bg_art)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -480
	panel.offset_top = -300
	panel.offset_right = 480
	panel.offset_bottom = 300
	if outcome == "victory":
		panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.07, 0.06, 0.04, 0.92), Color(0.78, 0.58, 0.22, 0.95)))
	else:
		panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.06, 0.04, 0.03, 0.92), Color(0.58, 0.18, 0.18, 0.95)))
	screen.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	# Padding wrapper so content doesn't hug the panel border.
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 18)
	pad.add_theme_constant_override("margin_bottom", 18)
	root.add_child(pad)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	pad.add_child(inner)

	var title := Label.new()
	if outcome == "victory":
		title.text = _tr("summary.victory_title", "Archive Sealed - Run Complete")
	else:
		title.text = _tr("summary.defeat_title", "Run Lost - The Archive Shuts")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	if outcome == "victory":
		title.modulate = Color(1.0, 0.86, 0.55)
	else:
		title.modulate = Color(1.0, 0.62, 0.58)
	inner.add_child(title)

	var subtitle := Label.new()
	var char_data = CharacterCatalogScript.resolve(character_catalog, character_id)
	var char_name := character_id
	if char_data != null and String(char_data.display_name) != "":
		char_name = _localized_name(String(char_data.id), String(char_data.display_name))
	subtitle.text = _tr("summary.subtitle", "%s - Ascension %d - Seed %d") % [char_name, ascension_level, run_seed]
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.86, 0.82, 0.74)
	inner.add_child(subtitle)

	var sep := HSeparator.new()
	inner.add_child(sep)

	var body_scroll := ScrollContainer.new()
	body_scroll.custom_minimum_size = Vector2(0, 285)
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(body_scroll)

	# Two-column body: left = headline numbers, right = deck composition + relics.
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(body)

	var stats_col := VBoxContainer.new()
	stats_col.add_theme_constant_override("separation", 6)
	stats_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stats_col)

	var stats_lines: Array = _build_run_summary_stat_lines(outcome)
	for line_text in stats_lines:
		var label := Label.new()
		label.text = String(line_text)
		stats_col.add_child(label)

	var lists_col := VBoxContainer.new()
	lists_col.add_theme_constant_override("separation", 6)
	lists_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(lists_col)

	var deck_title := Label.new()
	deck_title.text = _tr("summary.deck_title", "Deck (%d)") % run_deck_ids.size()
	deck_title.modulate = Color(0.95, 0.85, 0.65)
	lists_col.add_child(deck_title)

	var deck_breakdown_label := Label.new()
	deck_breakdown_label.text = _run_summary_deck_breakdown_text()
	deck_breakdown_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lists_col.add_child(deck_breakdown_label)

	var relics_title := Label.new()
	relics_title.text = _tr("summary.relics_title", "Relics (%d)") % relic_ids.size()
	relics_title.modulate = Color(0.95, 0.85, 0.65)
	lists_col.add_child(relics_title)

	var relics_label := Label.new()
	relics_label.text = _run_summary_relics_text()
	relics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lists_col.add_child(relics_label)

	var sep2 := HSeparator.new()
	inner.add_child(sep2)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	inner.add_child(buttons)

	var new_run_btn := Button.new()
	new_run_btn.text = _tr("summary.new_run", "Start New Run")
	new_run_btn.custom_minimum_size = Vector2(200, 50)
	new_run_btn.pressed.connect(_on_new_run_pressed)
	buttons.add_child(new_run_btn)

	var menu_btn := Button.new()
	menu_btn.text = _tr("summary.main_menu", "Main Menu")
	menu_btn.custom_minimum_size = Vector2(160, 50)
	menu_btn.pressed.connect(func() -> void: _show_main_menu())
	buttons.add_child(menu_btn)


# Returns the headline stat lines (left column) for the run summary modal.
func _build_run_summary_stat_lines(outcome: String) -> Array:
	var lines: Array = []
	if outcome == "victory":
		lines.append(_tr("summary.outcome_victory", "Outcome: Victory"))
	else:
		lines.append(_tr("summary.outcome_defeat", "Outcome: Defeat"))
	lines.append(_tr("summary.final_hp", "Final HP: %d / %d") % [max(0, player_hp), player_max_hp])
	lines.append(_tr("summary.act", "Act reached: %d / %d") % [current_act, FINAL_ACT])
	lines.append(_tr("summary.floor", "Floor reached: %d") % max(floor_index, 1))
	lines.append(_tr("summary.encounters", "Encounters cleared: %d") % combat_index)
	lines.append(_tr("summary.gold", "Gold earned: %d") % gold)
	lines.append(_tr("summary.removals", "Card removals: %d") % card_removals)
	lines.append(_tr("summary.shop_visits", "Shop visits: %d") % shop_visits)
	lines.append(_tr("summary.events_seen", "Events seen: %d") % events_seen.size())
	return lines


# Returns the deck composition string (e.g. "Atk 8  Skl 6  Pwr 1  Crs 0  Sts 0")
# plus the upgraded-card count.
func _run_summary_deck_breakdown_text() -> String:
	var counts := {"attack": 0, "skill": 0, "power": 0, "curse": 0, "status": 0}
	var upgraded := 0
	for entry in run_deck_ids:
		var cid := String(entry)
		if cid.ends_with("+"):
			upgraded += 1
			cid = cid.trim_suffix("+")
		var card_data = card_database.get(cid, null)
		var ctype := "skill"
		if card_data != null:
			ctype = String(card_data.get("card_type"))
		if not counts.has(ctype):
			counts[ctype] = 0
		counts[ctype] += 1
	var parts: Array[String] = []
	parts.append(_tr("summary.deck_breakdown", "Atk %d  Skl %d  Pwr %d") % [counts.get("attack", 0), counts.get("skill", 0), counts.get("power", 0)])
	if int(counts.get("curse", 0)) > 0:
		parts.append(_tr("summary.deck_curse", "Crs %d") % counts.get("curse", 0))
	if int(counts.get("status", 0)) > 0:
		parts.append(_tr("summary.deck_status", "Sts %d") % counts.get("status", 0))
	parts.append(_tr("summary.deck_upgraded", "Upg %d") % upgraded)
	return "  ".join(parts)


# Returns a comma-separated list of relic display names for the summary panel.
func _run_summary_relics_text() -> String:
	if relic_ids.is_empty():
		return _tr("summary.none", "(none)")
	var names: Array[String] = []
	for rid in relic_ids:
		var rdata = relic_database.get(rid, null)
		if rdata != null and String(rdata.get("display_name")) != "":
			names.append(_localized_name(String(rid), String(rdata.get("display_name"))))
		else:
			names.append(String(rid))
	return ", ".join(names)


func _add_completion(root: VBoxContainer) -> void:
	var title := Label.new()
	title.text = _tr("completion.title", "Archive Key Recovered")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var key_holder := CenterContainer.new()
	key_holder.custom_minimum_size = Vector2(0, 128)
	key_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root.add_child(key_holder)

	var key_art := TextureRect.new()
	key_art.custom_minimum_size = Vector2(164, 118)
	key_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	key_art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	key_art.ignore_texture_size = true
	key_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	key_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key_art.texture = _load_png_texture("res://art/generated/sprites/archive_key.png")
	key_holder.add_child(key_art)

	var body := Label.new()
	body.text = _tr("completion.body", "The Sealed Curator falls silent. The archive key turns once in your palm, and every locked shelf exhales. This demo run is complete.\n\nFinal state: HP %d/%d, Gold %d, Deck %d cards.") % [player_hp, player_max_hp, gold, run_deck_ids.size()]
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(body)

	var again := Button.new()
	again.text = _tr("summary.new_run", "Start New Run")
	again.custom_minimum_size = Vector2(180, 48)
	again.pressed.connect(_on_new_run_pressed)
	root.add_child(again)


func _on_new_run_pressed() -> void:
	_show_character_select_menu()


func _on_new_run_confirmed() -> void:
	if new_run_reset_in_progress:
		return
	new_run_reset_in_progress = true
	call_deferred("_perform_new_run_reset")


func _perform_new_run_reset() -> void:
	if pause_overlay != null and is_instance_valid(pause_overlay):
		pause_overlay.free()
	pause_overlay = null
	_clear_screen_immediate()
	save_manager.clear_run()
	_start_new_run()
	_show_story_intro()
	new_run_reset_in_progress = false


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Failed to load image: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _character_sprite_texture(char_id: String) -> Texture2D:
	var data = character_catalog.get(char_id, null)
	if data != null and String(data.sprite_path) != "":
		var tex := _load_png_texture(String(data.sprite_path))
		if tex != null:
			return tex
	return _load_png_texture("res://art/generated/sprites/vanguard_archivist.png")


func _character_chip_texture(char_id: String) -> Texture2D:
	var suffix := String(char_id).trim_prefix("char_")
	var tex := _load_png_texture("res://art/generated/ui/char_chip_%s.png" % suffix)
	if tex != null:
		return tex
	return null


# ─── A1.7: Pause menu & settings ─────────────────────────────────────────────
#
# Toggled with ESC. Modal overlay with: Resume / Settings (volumes + toggles) /
# Main Menu. Settings persist via SettingsManager. We keep the
# pause overlay outside `current_screen` so showing it does not unload combat.

func _toggle_pause_menu() -> void:
	if pause_overlay != null and is_instance_valid(pause_overlay) and pause_overlay.visible:
		_close_pause_menu()
	else:
		_open_pause_menu()


func _open_pause_menu() -> void:
	if pause_overlay != null and is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
	pause_overlay = _build_pause_overlay()
	add_child(pause_overlay)
	pause_overlay.move_to_front()
	var am = _audio()
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("sfx_pause_open")


func _close_pause_menu() -> void:
	if pause_overlay != null and is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
	pause_overlay = null
	var am = _audio()
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("sfx_pause_close")


func _build_pause_overlay() -> Control:
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -240
	panel.offset_top = -290
	panel.offset_right = 240
	panel.offset_bottom = 290
	panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.06, 0.05, 0.04, 0.94), Color(0.62, 0.46, 0.20, 0.95)))
	screen.add_child(panel)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	pad.add_theme_constant_override("margin_top", 18)
	pad.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(pad)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	pad.add_child(col)

	var title := Label.new()
	title.text = _tr("settings.paused", "Paused")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	col.add_child(title)

	var hint := Label.new()
	hint.text = _tr("settings.hint", "(Press ESC to resume)")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.78, 0.74, 0.66)
	col.add_child(hint)

	col.add_child(HSeparator.new())

	# ── Settings: volume sliders + toggles ───────────────────────────────────
	var settings_title := Label.new()
	settings_title.text = _tr("settings.title", "Settings")
	settings_title.modulate = Color(0.95, 0.85, 0.65)
	col.add_child(settings_title)

	col.add_child(_build_pause_volume_row(_tr("settings.master", "Master"), "master_db", -40.0, 6.0))
	col.add_child(_build_pause_volume_row(_tr("settings.music", "Music"), "music_db", -40.0, 6.0))
	col.add_child(_build_pause_volume_row(_tr("settings.sfx", "SFX"), "sfx_db", -40.0, 6.0))

	var language_box := HBoxContainer.new()
	language_box.add_theme_constant_override("separation", 8)
	var language_label := Label.new()
	language_label.text = _tr("settings.language", "Language")
	language_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_box.add_child(language_label)
	var language_button := Button.new()
	language_button.text = _tr("settings.language_value", "English")
	language_button.custom_minimum_size = Vector2(120, 34)
	language_button.pressed.connect(_toggle_language)
	language_box.add_child(language_button)
	col.add_child(language_box)

	var fast_box := HBoxContainer.new()
	fast_box.add_theme_constant_override("separation", 8)
	var fast_label := Label.new()
	fast_label.text = _tr("settings.fast", "Fast resolve")
	fast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fast_box.add_child(fast_label)
	var fast_check := CheckBox.new()
	fast_check.button_pressed = bool(settings_manager.get_value("fast_resolve"))
	fast_check.toggled.connect(func(on: bool) -> void:
		settings_manager.set_value("fast_resolve", on)
		# Apply to current combat scene if one is up.
		if current_screen != null and current_screen.has_method("set_fast_resolve"):
			current_screen.set_fast_resolve(on)
	)
	fast_box.add_child(fast_check)
	col.add_child(fast_box)

	var hints_box := HBoxContainer.new()
	hints_box.add_theme_constant_override("separation", 8)
	var hints_label := Label.new()
	hints_label.text = _tr("settings.tutorial", "Show tutorial hints")
	hints_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints_box.add_child(hints_label)
	var hints_check := CheckBox.new()
	hints_check.button_pressed = bool(settings_manager.get_value("show_tutorial_hints"))
	hints_check.toggled.connect(func(on: bool) -> void:
		settings_manager.set_value("show_tutorial_hints", on)
	)
	hints_box.add_child(hints_check)
	col.add_child(hints_box)

	col.add_child(HSeparator.new())

	# ── Action buttons ───────────────────────────────────────────────────────
	var resume := Button.new()
	resume.text = _tr("settings.resume", "Resume")
	resume.custom_minimum_size = Vector2(0, 44)
	resume.pressed.connect(_close_pause_menu)
	col.add_child(resume)

	var menu_btn := Button.new()
	menu_btn.text = _tr("settings.menu", "Main Menu")
	menu_btn.custom_minimum_size = Vector2(0, 40)
	menu_btn.pressed.connect(func() -> void:
		_close_pause_menu()
		_save_run()
		_show_main_menu()
	)
	col.add_child(menu_btn)

	return screen


func _build_pause_volume_row(label_text: String, key: String, vmin: float, vmax: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(80, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = vmin
	slider.max_value = vmax
	slider.step = 1.0
	slider.value = float(settings_manager.get_value(key))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(220, 0)
	row.add_child(slider)

	var value_lbl := Label.new()
	value_lbl.text = "%d dB" % int(slider.value)
	value_lbl.custom_minimum_size = Vector2(60, 0)
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		settings_manager.set_value(key, v)
		value_lbl.text = "%d dB" % int(v)
		settings_manager.apply_audio(_audio())
	)
	return row
