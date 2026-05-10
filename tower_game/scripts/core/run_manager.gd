extends Control

const COMBAT_SCENE := preload("res://scenes/combat/combat_scene.tscn")
const SaveManagerScript := preload("res://scripts/save/save_manager.gd")
const RouteMapViewScript := preload("res://scripts/ui/route_map_view.gd")

var save_manager
var run_deck_ids: Array[String] = []
var player_max_hp := 76
var player_hp := 76
var gold := 99
var floor_index := 0
var combat_index := 0
var completed := false
var story_seen := false
var current_screen: Control

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

var map_nodes := [
	[
		{"type": "combat", "title": "Dust Scribe", "subtitle": "A first hostile record."},
		{"type": "combat", "title": "Loose Folios", "subtitle": "A faster but fragile foe."}
	],
	[
		{"type": "event", "title": "Ink Debt", "subtitle": "Trade blood for a cleaner deck."},
		{"type": "combat", "title": "Restless Shelves", "subtitle": "Take a safer fight for rewards."}
	],
	[
		{"type": "shop", "title": "Quiet Vendor", "subtitle": "Spend gold before danger."},
		{"type": "elite", "title": "Index Knight", "subtitle": "Hard fight, better payout."},
		{"type": "event", "title": "Sealed Margin", "subtitle": "A risky archive clause."}
	],
	[
		{"type": "campfire", "title": "Waxlight Nook", "subtitle": "Rest or sharpen one thought."},
		{"type": "combat", "title": "Bound Errata", "subtitle": "One last ordinary fight."}
	],
	[
		{"type": "boss", "title": "Sealed Curator", "subtitle": "Keeper of the archive key."}
	]
]


func _ready() -> void:
	save_manager = SaveManagerScript.new()
	_load_or_start_run()
	_show_main_menu()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if event.keycode == KEY_F2:
		_show_map()
	elif event.keycode == KEY_F3:
		_show_combat("combat", "Dust Scribe")


func _load_or_start_run() -> void:
	var data: Dictionary = save_manager.load_run()
	if data.is_empty():
		_start_new_run()
		return
	run_deck_ids.clear()
	for card_id in data.get("run_deck_ids", []):
		run_deck_ids.append(String(card_id))
	player_hp = int(data.get("player_hp", player_max_hp))
	player_max_hp = int(data.get("player_max_hp", player_max_hp))
	gold = int(data.get("gold", gold))
	floor_index = int(data.get("floor_index", 0))
	combat_index = int(data.get("combat_index", 0))
	completed = bool(data.get("completed", false))
	story_seen = bool(data.get("story_seen", false))
	if run_deck_ids.is_empty():
		run_deck_ids = _starter_deck()


func _start_new_run() -> void:
	run_deck_ids = _starter_deck()
	player_max_hp = 76
	player_hp = player_max_hp
	gold = 99
	floor_index = 0
	combat_index = 0
	completed = false
	story_seen = false
	_save_run()


func _starter_deck() -> Array[String]:
	var ids: Array[String] = []
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
		"version": 2,
		"run_deck_ids": run_deck_ids,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"gold": gold,
		"floor_index": floor_index,
		"combat_index": combat_index,
		"completed": completed,
		"story_seen": story_seen
	})


func _clear_screen() -> void:
	if current_screen != null:
		current_screen.queue_free()
		current_screen = null


func _show_map() -> void:
	_clear_screen()
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	bg_shade.color = Color(0, 0, 0, 0.26)
	bg_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg_shade)

	var top_glow := ColorRect.new()
	top_glow.color = Color(0.20, 0.15, 0.08, 0.38)
	top_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_glow.custom_minimum_size = Vector2(0, 96)
	screen.add_child(top_glow)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 18
	root.offset_right = -24
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 6)
	screen.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)

	var title := Label.new()
	title.text = "Living Archive"
	title.custom_minimum_size = Vector2(360, 34)
	header.add_child(title)

	var stats := Label.new()
	stats.text = "HP %d/%d    Gold %d    Deck %d    Layer %d/%d" % [player_hp, player_max_hp, gold, run_deck_ids.size(), min(floor_index + 1, map_nodes.size()), map_nodes.size()]
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(stats)

	var reset := Button.new()
	reset.text = "New Run"
	reset.custom_minimum_size = Vector2(120, 40)
	reset.pressed.connect(_on_new_run_pressed)
	header.add_child(reset)

	if completed:
		_add_completion(root)
		return

	var quest := PanelContainer.new()
	quest.custom_minimum_size = Vector2(560, 58)
	quest.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	quest.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.055, 0.045, 0.035, 0.78), Color(0.58, 0.42, 0.18, 0.8)))
	root.add_child(quest)
	var quest_box := VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 6)
	quest.add_child(quest_box)
	var quest_title := Label.new()
	quest_title.text = "Current Task"
	quest_box.add_child(quest_title)
	var quest_body := Label.new()
	quest_body.text = _quest_text()
	quest_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_box.add_child(quest_body)

	var hint := Label.new()
	hint.text = "Choose one available route node. Your choice changes gold, deck size, health, and the next fight."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(720, 28)
	hint.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(hint)

	var map_and_side := Control.new()
	map_and_side.custom_minimum_size = Vector2(0, 340)
	map_and_side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(map_and_side)

	var map_panel := PanelContainer.new()
	map_panel.set_anchors_preset(Control.PRESET_CENTER)
	map_panel.offset_left = -500
	map_panel.offset_top = -162
	map_panel.offset_right = 280
	map_panel.offset_bottom = 162
	map_panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.05, 0.043, 0.032, 0.16), Color(0.70, 0.50, 0.20, 0.26)))
	map_and_side.add_child(map_panel)

	var map_view = RouteMapViewScript.new()
	map_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_view.node_selected.connect(_enter_node)
	map_panel.add_child(map_view)
	map_view.setup(map_nodes, floor_index)

	var side_panel := PanelContainer.new()
	side_panel.anchor_left = 0.0
	side_panel.anchor_top = 0.0
	side_panel.anchor_right = 0.0
	side_panel.anchor_bottom = 1.0
	side_panel.offset_left = 760
	side_panel.offset_top = 0
	side_panel.offset_right = 1000
	side_panel.offset_bottom = 0
	side_panel.add_theme_stylebox_override("normal", _glass_panel_box(Color(0.035, 0.034, 0.032, 0.82), Color(0.58, 0.42, 0.18, 0.9)))
	map_and_side.add_child(side_panel)

	var side_box := VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 10)
	side_panel.add_child(side_box)

	var deck_title := Label.new()
	deck_title.text = "Deck (%d)" % run_deck_ids.size()
	side_box.add_child(deck_title)

	var deck_list := Label.new()
	deck_list.text = _deck_summary()
	deck_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_box.add_child(deck_list)

	var note := Label.new()
	note.text = "Goal: reach the Curator. Elites raise risk; campfires preserve the run."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_box.add_child(note)


func _show_main_menu() -> void:
	_clear_screen()
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	current_screen = screen
	add_child(screen)

	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.065, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(bg)

	var glow := ColorRect.new()
	glow.color = Color(0.22, 0.15, 0.07, 0.25)
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.offset_left = -520
	glow.offset_top = -260
	glow.offset_right = 520
	glow.offset_bottom = 260
	screen.add_child(glow)

	var hero := TextureRect.new()
	hero.texture = _load_png_texture("res://art/generated/sprites/vanguard_archivist.png")
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
	panel.offset_top = -210
	panel.offset_right = 350
	panel.offset_bottom = 210
	screen.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title := Label.new()
	title.text = "LIVING ARCHIVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A playable roguelike deckbuilder demo. Choose routes, fight with cards, improve your deck, and defeat the Sealed Curator."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	var run_state := Label.new()
	run_state.text = "Saved Run: Layer %d/%d, HP %d/%d, Gold %d" % [min(floor_index + 1, map_nodes.size()), map_nodes.size(), player_hp, player_max_hp, gold]
	run_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(run_state)

	var continue_button := Button.new()
	continue_button.text = "Continue Run"
	continue_button.custom_minimum_size = Vector2(0, 52)
	continue_button.disabled = run_deck_ids.is_empty()
	continue_button.pressed.connect(func() -> void: _show_map())
	box.add_child(continue_button)

	var new_button := Button.new()
	new_button.text = "Start New Run"
	new_button.custom_minimum_size = Vector2(0, 52)
	new_button.pressed.connect(_on_new_run_pressed)
	box.add_child(new_button)

	var controls := Label.new()
	controls.text = "Controls: click route nodes, click cards to play them, then end your turn."
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(controls)


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
	title.text = "Prologue: The Door That Remembered"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var intro_art := TextureRect.new()
	intro_art.custom_minimum_size = Vector2(0, 110)
	intro_art.ignore_texture_size = true
	intro_art.texture = _load_png_texture("res://art/generated/sprites/archive_key.png")
	intro_art.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	intro_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(intro_art)

	var story := Label.new()
	story.custom_minimum_size = Vector2(640, 0)
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.text = "The Living Archive has opened beneath the old tower. Every shelf remembers a broken oath. Every page has learned to bite. You carry the Sealed Badge, a minor authority and a fragile excuse to survive.\n\nTask: recover the Archive Key from the Sealed Curator before the tower writes your name into its losses."
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(story)

	var start := Button.new()
	start.text = "Enter the Archive"
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
		var base_id := entry_text.trim_suffix("+")
		var display_name := String(card_names.get(base_id, base_id))
		if entry_text.ends_with("+"):
			display_name += "+"
		parts.append("%s x%d" % [display_name, counts[entry]])
	return ", ".join(parts)


func _enter_node(row_index: int, node_index: int) -> void:
	var node = map_nodes[row_index][node_index]
	match node.type:
		"combat", "elite", "boss":
			_show_combat(node.type, node.title)
		"event":
			_show_event()
		"shop":
			_show_shop()
		"campfire":
			_show_campfire()


func _show_combat(node_type: String, node_title: String = "") -> void:
	_clear_screen()
	var combat = COMBAT_SCENE.instantiate()
	combat.configure(run_deck_ids, player_hp, player_max_hp, node_type, combat_index, node_title)
	current_screen = combat
	add_child(combat)
	combat.combat_reward_chosen.connect(_on_combat_reward_chosen)
	combat.combat_reward_skipped.connect(_on_combat_reward_skipped)
	combat.combat_lost.connect(_on_combat_lost)
	combat.boss_defeated.connect(_on_boss_defeated)
	combat.reset_run_requested.connect(_on_new_run_pressed)


func _on_combat_reward_chosen(card_id: String, remaining_hp: int) -> void:
	run_deck_ids.append(card_id)
	player_hp = remaining_hp
	gold += 18
	floor_index += 1
	combat_index += 1
	_save_run()
	_show_map()


func _on_combat_reward_skipped(remaining_hp: int) -> void:
	player_hp = remaining_hp
	gold += 25
	floor_index += 1
	combat_index += 1
	_save_run()
	_show_map()


func _on_combat_lost() -> void:
	_show_defeat()


func _on_boss_defeated(remaining_hp: int) -> void:
	player_hp = remaining_hp
	completed = true
	_save_run()
	_show_map()


func _show_event() -> void:
	if floor_index == 2:
		_show_choice_screen(
			"Sealed Margin",
			"A margin note offers speed, but the ink still remembers the cost.",
			[
				{"text": "Gain Oath Pressure. Lose 8 HP.", "action": func() -> void: _event_gain_oath()},
				{"text": "Gain 35 gold.", "action": func() -> void: _event_gain_gold(35)}
			]
		)
	else:
		_show_choice_screen(
			"Ink Debt",
			"The archive offers a clean cut through your worst habit, priced in blood.",
			[
				{"text": "Remove a Strike Form. Lose 6 HP.", "action": func() -> void: _event_remove_strike()},
				{"text": "Refuse the contract.", "action": func() -> void: _advance_floor()}
			]
		)


func _event_remove_strike() -> void:
	_remove_first_matching_card("strike_form")
	player_hp = max(1, player_hp - 6)
	_advance_floor()


func _event_gain_oath() -> void:
	run_deck_ids.append("oath_pressure")
	player_hp = max(1, player_hp - 8)
	_advance_floor()


func _event_gain_gold(amount: int) -> void:
	gold += amount
	_advance_floor()


func _show_shop() -> void:
	_show_choice_screen(
		"Quiet Vendor",
		"A lantern-lit vendor lays three tools on velvet. Gold speaks softly here.",
		[
			{"text": "Buy Measured Cut - 45 gold", "action": func() -> void: _buy_card("measured_cut", 45)},
			{"text": "Buy Brace - 45 gold", "action": func() -> void: _buy_card("brace", 45)},
			{"text": "Buy Break Rhythm - 55 gold", "action": func() -> void: _buy_card("break_rhythm", 55)},
			{"text": "Remove a card - 75 gold", "action": func() -> void: _shop_remove_card()},
			{"text": "Leave", "action": func() -> void: _advance_floor()}
		]
	)


func _buy_card(card_id: String, price: int) -> void:
	if gold >= price:
		gold -= price
		run_deck_ids.append(card_id)
	_advance_floor()


func _shop_remove_card() -> void:
	if gold >= 75 and _has_card("strike_form"):
		gold -= 75
		_remove_first_matching_card("strike_form")
	_advance_floor()


func _show_campfire() -> void:
	_show_choice_screen(
		"Waxlight Nook",
		"Warm wax pools beside an old blade. The archive is quiet for one breath.",
			[
			{"text": "Rest: heal 24 HP", "action": func() -> void: _campfire_rest()},
			{"text": "Upgrade a card", "action": func() -> void: _campfire_upgrade()}
		]
	)


func _campfire_rest() -> void:
	player_hp = min(player_max_hp, player_hp + 24)
	_advance_floor()


func _campfire_upgrade() -> void:
	for index in run_deck_ids.size():
		if not run_deck_ids[index].ends_with("+"):
			run_deck_ids[index] = "%s+" % run_deck_ids[index]
			break
	_advance_floor()


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
	state.text = "HP %d/%d    Gold %d    Deck %d" % [player_hp, player_max_hp, gold, run_deck_ids.size()]
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_box.add_child(state)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_box.add_child(body)

	var scene_tag := Label.new()
	scene_tag.text = _choice_scene_tag(title_text)
	scene_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_tag.custom_minimum_size = Vector2(0, 120)
	story_box.add_child(scene_tag)

	var choices_box := VBoxContainer.new()
	choices_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices_box.add_theme_constant_override("separation", 12)
	box.add_child(choices_box)

	for choice in choices:
		var button := Button.new()
		button.text = choice.text
		button.custom_minimum_size = Vector2(0, 58)
		button.pressed.connect(choice.action)
		choices_box.add_child(button)


func _choice_bg_color(title_text: String) -> Color:
	if title_text.find("Vendor") >= 0:
		return Color(0.10, 0.085, 0.055)
	if title_text.find("Nook") >= 0:
		return Color(0.11, 0.06, 0.04)
	if title_text.find("Lost") >= 0:
		return Color(0.08, 0.03, 0.03)
	return Color(0.08, 0.09, 0.10)


func _choice_scene_tag(title_text: String) -> String:
	if title_text.find("Vendor") >= 0:
		return "[ LANTERN SHOP ]"
	if title_text.find("Nook") >= 0:
		return "[ WAXFIRE CAMP ]"
	if title_text.find("Lost") >= 0:
		return "[ RUN LOST ]"
	return "[ ARCHIVE EVENT ]"


func _advance_floor() -> void:
	floor_index += 1
	_save_run()
	_show_map()


func _show_defeat() -> void:
	_show_choice_screen(
		"Run Lost",
		"The archive shuts. Your notes remain, but this run is over.",
		[
			{"text": "Start a new run", "action": func() -> void: _on_new_run_pressed()}
		]
	)


func _add_completion(root: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Archive Key Recovered"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var key_art := TextureRect.new()
	key_art.custom_minimum_size = Vector2(0, 120)
	key_art.ignore_texture_size = true
	key_art.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	key_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key_art.texture = _load_png_texture("res://art/generated/sprites/archive_key.png")
	root.add_child(key_art)

	var body := Label.new()
	body.text = "The Sealed Curator falls silent. The archive key turns once in your palm, and every locked shelf exhales. This demo run is complete.\n\nFinal state: HP %d/%d, Gold %d, Deck %d cards." % [player_hp, player_max_hp, gold, run_deck_ids.size()]
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(body)

	var again := Button.new()
	again.text = "Start New Run"
	again.custom_minimum_size = Vector2(180, 48)
	again.pressed.connect(_on_new_run_pressed)
	root.add_child(again)


func _on_new_run_pressed() -> void:
	save_manager.clear_run()
	_start_new_run()
	_show_story_intro()


func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_warning("Failed to load image: %s" % path)
		return null
	return ImageTexture.create_from_image(image)
