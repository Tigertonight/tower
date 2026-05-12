extends SceneTree

# A1.9 — headless balance simulation pipeline.
#
# Run with:
#   godot --headless --script res://scripts/tools/headless_runs.gd \
#         -- --char=char_vanguard --asc=0 --runs=200 --out=user://balance.csv
#
# Or use the wrapper at `tower/run_balance_sim.sh`. CSV columns:
#   character, ascension, run_seed, floors_cleared, act_reached, outcome,
#   final_hp, deck_size, turns_total, biggest_hit
#
# Scope: this is intentionally a *simplified* simulator. It uses real
# CardData / EnemyData / CharacterData but a mocked "combat" object that
# implements just the surface area EffectResolver.resolve() needs. Card
# effects we don't simulate (e.g. add_card_to_hand, exhaust_random_card)
# are no-ops and treated as 0 damage / 0 block contribution.
#
# AI heuristic: each player turn, repeatedly play the highest-cost playable
# card from hand (random tie-break). End turn when energy is 0 or no card is
# affordable. This is "good enough" to surface gross balance issues even if
# it under-plays optimal lines.
#
# This is intentionally NOT a perfect re-host of CombatManager — that file
# is UI-coupled. The goal is a stable winrate signal across `runs * acts`.

const CardDataScript := preload("res://scripts/cards/card_data.gd")
const EnemyInstanceScript := preload("res://scripts/combat/enemy_instance.gd")
const EnemyCatalogScript := preload("res://scripts/combat/enemy_catalog.gd")
const CharacterCatalogScript := preload("res://scripts/core/character_catalog.gd")
const AscensionConfigScript := preload("res://scripts/core/ascension_config.gd")
const MapGeneratorScript := preload("res://scripts/map/map_generator.gd")
const EffectResolverScript := preload("res://scripts/cards/effect_resolver.gd")

var card_db: Dictionary = {}
var enemy_db: Dictionary = {}
var move_db: Dictionary = {}
var character_db: Dictionary = {}


func _init() -> void:
	var args := _parse_args()
	var character_id: String = String(args.get("char", "char_vanguard"))
	var ascension: int = int(args.get("asc", 0))
	var runs: int = int(args.get("runs", 100))
	var out_path: String = String(args.get("out", "user://balance.csv"))
	var seed_base: int = int(args.get("seed", 1))

	_load_databases()

	print("[balance] character=%s ascension=%d runs=%d out=%s" % [character_id, ascension, runs, out_path])
	var rows: Array[String] = []
	rows.append("character,ascension,run_seed,floors_cleared,act_reached,outcome,final_hp,deck_size,turns_total,biggest_hit")
	var wins := 0
	for i in runs:
		var run_seed := seed_base + i
		var result: Dictionary = _simulate_run(character_id, ascension, run_seed)
		rows.append(",".join([
			character_id,
			str(ascension),
			str(run_seed),
			str(result["floors_cleared"]),
			str(result["act_reached"]),
			String(result["outcome"]),
			str(result["final_hp"]),
			str(result["deck_size"]),
			str(result["turns_total"]),
			str(result["biggest_hit"]),
		]))
		if String(result["outcome"]) == "victory":
			wins += 1
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(rows))
		f.close()
		print("[balance] wrote %d rows → %s  winrate=%.1f%%" % [runs, out_path, 100.0 * float(wins) / float(max(1, runs))])
	else:
		push_warning("Could not open %s for write" % out_path)
	quit()


func _parse_args() -> Dictionary:
	var out: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		var raw := String(arg)
		if not raw.begins_with("--"):
			continue
		raw = raw.substr(2)
		var eq := raw.find("=")
		if eq < 0:
			out[raw] = true
		else:
			out[raw.substr(0, eq)] = raw.substr(eq + 1)
	return out


func _load_databases() -> void:
	# Cards
	var card_dir := DirAccess.open("res://data/cards")
	if card_dir != null:
		for file_name in card_dir.get_files():
			if file_name.ends_with(".tres"):
				var card = load("res://data/cards/%s" % file_name)
				if card != null:
					card_db[String(card.get("id"))] = card
	# Enemies + moves
	enemy_db = EnemyCatalogScript.load_enemies()
	move_db = EnemyCatalogScript.build_moves()
	# Characters
	var char_dir := DirAccess.open("res://data/characters")
	if char_dir != null:
		for file_name in char_dir.get_files():
			if file_name.ends_with(".tres"):
				var c = load("res://data/characters/%s" % file_name)
				if c != null:
					character_db[String(c.get("id"))] = c


func _simulate_run(character_id: String, ascension: int, run_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var character = CharacterCatalogScript.resolve(character_db, character_id)
	if character == null:
		return {"outcome": "skipped", "floors_cleared": 0, "act_reached": 1, "final_hp": 0, "deck_size": 0, "turns_total": 0, "biggest_hit": 0}
	var deck: Array = []
	for entry in character.starter_deck:
		var cid := String(entry).trim_suffix("+")
		if card_db.has(cid):
			deck.append({"id": cid, "upgraded": String(entry).ends_with("+")})
	var max_hp: int = int(character.starting_hp)
	var hp: int = max_hp
	var act := 1
	var floors_cleared := 0
	var turns_total := 0
	var biggest_hit := 0
	var act_results: Array = _build_act_encounter_list()
	var outcome := "defeat"
	for act_index in act_results.size():
		act = act_index + 1
		var encounters: Array = act_results[act_index]
		# Run between 6 and 9 encounters per act in a vertical-slice approximation.
		var encounter_count: int = clamp(encounters.size(), 6, 9)
		for floor_idx in encounter_count:
			var encounter_id: String
			if floor_idx == encounter_count - 1:
				encounter_id = _act_boss_id(act)
			else:
				encounter_id = encounters[floor_idx % encounters.size()]
			var combat_result: Dictionary = _simulate_combat(deck, hp, max_hp, encounter_id, ascension, rng)
			turns_total += int(combat_result["turns"])
			biggest_hit = max(biggest_hit, int(combat_result["biggest_hit"]))
			if not bool(combat_result["won"]):
				return {
					"outcome": "defeat",
					"floors_cleared": floors_cleared,
					"act_reached": act,
					"final_hp": 0,
					"deck_size": deck.size(),
					"turns_total": turns_total,
					"biggest_hit": biggest_hit,
				}
			hp = int(combat_result["hp"])
			floors_cleared += 1
		# Inter-act heal + small reward (loose simulation of run rewards).
		hp = min(max_hp, hp + int(float(max_hp) * 0.20))
	outcome = "victory"
	return {
		"outcome": outcome,
		"floors_cleared": floors_cleared,
		"act_reached": act,
		"final_hp": hp,
		"deck_size": deck.size(),
		"turns_total": turns_total,
		"biggest_hit": biggest_hit,
	}


func _build_act_encounter_list() -> Array:
	# Hand-pick a representative set per act so sims don't depend on map RNG.
	return [
		# Act 1
		["e_dust_scribe", "e_loose_folio", "e_dust_scribe+e_loose_folio", "e_wax_acolyte", "e_margin_hound", "e_burnt_courier", "el_first_clause"],
		# Act 2
		["e_glassed_intern", "e_late_filer", "e_glassed_intern+e_late_filer", "e_silent_ledger", "e_dust_sentinel", "el_quill_judge"],
		# Act 3
		["e_late_filer", "e_silent_ledger", "e_dust_sentinel", "e_red_string_imp", "e_burnt_courier", "el_archive_warden", "e_dust_sentinel+e_burnt_courier+e_red_string_imp"],
	]


func _act_boss_id(act: int) -> String:
	match act:
		1:
			return "b_chronicler_of_lost_pages"
		2:
			return "b_grand_archivist"
		3:
			return "b_sealed_curator"
		_:
			return "b_sealed_curator"


# ─── Single-combat sim ────────────────────────────────────────────────────────

func _simulate_combat(deck: Array, hp: int, max_hp: int, encounter_id: String, ascension: int, rng: RandomNumberGenerator) -> Dictionary:
	var combat := SimCombat.new(card_db, enemy_db, move_db)
	combat.ascension = ascension
	combat.player_hp = hp
	combat.player_max_hp = max_hp
	combat.rng = rng
	combat.setup_deck(deck)
	combat.spawn_enemies(encounter_id)
	# Energy = 3, hand size = 5 (matches in-game defaults).
	combat.run_loop(80)  # cap turn count at 80 so a stuck sim still terminates.
	return {
		"won": combat.alive_enemies().is_empty() and combat.player_hp > 0,
		"hp": combat.player_hp,
		"turns": combat.turn_number,
		"biggest_hit": combat.biggest_hit,
	}


# ─── Mocked "combat" object — implements just enough of the CombatManager
#     surface that EffectResolver, EnemyInstance.resolve_intent etc. need. ───

class SimCombat:
	extends RefCounted
	var card_db: Dictionary
	var enemy_db: Dictionary
	var move_db: Dictionary
	var rng: RandomNumberGenerator
	var ascension: int = 0
	var player_hp: int = 76
	var player_max_hp: int = 76
	var player_block: int = 0
	var player_energy: int = 0
	var base_energy: int = 3
	var hand_size: int = 5
	var player_statuses: Dictionary = {}
	var draw_pile: Array = []
	var hand: Array = []
	var discard_pile: Array = []
	var exhaust_pile: Array = []
	var enemies: Array = []
	var turn_number: int = 0
	var biggest_hit: int = 0

	const EnemyInstanceLocal := preload("res://scripts/combat/enemy_instance.gd")

	func _init(_cards: Dictionary, _enemies: Dictionary, _moves: Dictionary) -> void:
		card_db = _cards
		enemy_db = _enemies
		move_db = _moves

	func setup_deck(deck_entries: Array) -> void:
		draw_pile.clear()
		for entry in deck_entries:
			var cid := String(entry["id"])
			if card_db.has(cid):
				draw_pile.append({"id": cid, "upgraded": bool(entry["upgraded"])})
		_shuffle(draw_pile)

	func spawn_enemies(encounter_id: String) -> void:
		enemies.clear()
		for piece in encounter_id.split("+"):
			var pid := String(piece)
			var data = enemy_db.get(pid, null)
			if data == null:
				continue
			var inst = EnemyInstanceLocal.new()
			inst.setup(data, move_db)
			# Apply a rough ascension HP/damage bump so A2 sims hit harder.
			if ascension >= 2:
				inst.max_hp = int(inst.max_hp * 1.10)
				inst.hp = inst.max_hp
				inst.damage_multiplier = 1.10
			enemies.append(inst)

	func alive_enemies() -> Array:
		var result: Array = []
		for e in enemies:
			if not e.is_dead():
				result.append(e)
		return result

	func run_loop(turn_cap: int) -> void:
		# Choose initial intents.
		for e in enemies:
			e.choose_intent(1, rng)
		while turn_number < turn_cap and player_hp > 0 and not alive_enemies().is_empty():
			turn_number += 1
			_start_player_turn()
			_play_ai_turn()
			_end_player_turn()
			if alive_enemies().is_empty() or player_hp <= 0:
				break
			_run_enemy_turn()
			# Choose next-turn intents for survivors.
			for e in alive_enemies():
				e.choose_intent(turn_number + 1, rng)

	func _start_player_turn() -> void:
		player_block = 0
		player_energy = base_energy
		_decay_player_dot_at_turn_start()
		_draw_to(hand_size)

	func _draw_to(target: int) -> void:
		while hand.size() < target:
			if draw_pile.is_empty():
				if discard_pile.is_empty():
					break
				draw_pile = discard_pile
				discard_pile = []
				_shuffle(draw_pile)
			hand.append(draw_pile.pop_back())

	func _shuffle(arr: Array) -> void:
		var n := arr.size()
		for i in range(n - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = arr[i]
			arr[i] = arr[j]
			arr[j] = tmp

	func _play_ai_turn() -> void:
		var safety := 30
		while safety > 0:
			safety -= 1
			var idx := _pick_card_to_play()
			if idx < 0:
				break
			var entry: Dictionary = hand[idx]
			var card = card_db.get(String(entry["id"]), null)
			if card == null:
				hand.remove_at(idx)
				continue
			if int(card.cost) > player_energy:
				break
			# Pay energy and resolve effects.
			player_energy -= max(0, int(card.cost))
			var card_effects: Array = card.get_effects(bool(entry["upgraded"]))
			var target = _pick_first_alive_enemy()
			for effect in card_effects:
				EffectResolverScript.resolve(effect, self, self, target)
				target = _pick_first_alive_enemy()
			# Move card to discard / exhaust.
			hand.remove_at(idx)
			if bool(card.exhaust_on_play):
				exhaust_pile.append(entry)
			else:
				discard_pile.append(entry)
			if alive_enemies().is_empty():
				break

	func _pick_card_to_play() -> int:
		# Highest cost playable, random tie-break. Skip unplayable cards.
		var best_cost := -1
		var candidates: Array = []
		for i in hand.size():
			var entry: Dictionary = hand[i]
			var card = card_db.get(String(entry["id"]), null)
			if card == null:
				continue
			if card.is_unplayable():
				continue
			var cost := int(card.cost)
			if cost > player_energy:
				continue
			if cost > best_cost:
				best_cost = cost
				candidates = [i]
			elif cost == best_cost:
				candidates.append(i)
		if candidates.is_empty():
			return -1
		return int(candidates[rng.randi_range(0, candidates.size() - 1)])

	func _end_player_turn() -> void:
		# Apply ethereal exhaust + retain.
		var keep: Array = []
		for entry in hand:
			var card = card_db.get(String(entry["id"]), null)
			if card == null:
				continue
			if bool(card.ethereal):
				exhaust_pile.append(entry)
			elif bool(card.retain):
				keep.append(entry)
			else:
				discard_pile.append(entry)
		hand = keep

	func _decay_player_dot_at_turn_start() -> void:
		# Decay common per-turn statuses by 1 (vulnerable, weak, frail, etc.)
		for key in ["vulnerable", "weak", "frail"]:
			if int(player_statuses.get(key, 0)) > 0:
				player_statuses[key] = int(player_statuses[key]) - 1

	func _run_enemy_turn() -> void:
		for e in enemies:
			if e.is_dead():
				continue
			e.resolve_intent(self)
			# Decay enemy DoT (Ink) at end of enemy turn.
			if int(e.statuses.get("ink", 0)) > 0:
				var stacks: int = int(e.statuses["ink"])
				deal_damage(e, stacks)
				e.statuses["ink"] = stacks - 1
		# Decay enemy short-term debuffs by 1 each enemy turn-end.
		for e in alive_enemies():
			for key in ["vulnerable", "weak", "frail"]:
				if int(e.statuses.get(key, 0)) > 0:
					e.statuses[key] = int(e.statuses[key]) - 1

	func _pick_first_alive_enemy():
		for e in enemies:
			if not e.is_dead():
				return e
		return null

	# ── CombatManager-like API used by EffectResolver ──
	func deal_damage(target, amount: int) -> void:
		if target == null or amount <= 0:
			return
		var dmg := amount
		if int(target.statuses.get("vulnerable", 0)) > 0:
			dmg = int(round(dmg * 1.5))
		dmg += int(player_statuses.get("strength", 0))
		biggest_hit = max(biggest_hit, dmg)
		var absorbed: int = min(target.block, dmg)
		target.block -= absorbed
		dmg -= absorbed
		target.hp -= dmg

	func gain_player_block(amount: int) -> void:
		var b: int = amount + int(player_statuses.get("dexterity", 0))
		player_block += max(0, b)

	func draw_cards(amount: int) -> void:
		_draw_to(hand.size() + amount)

	func gain_energy(amount: int) -> void:
		player_energy += max(0, amount)

	func apply_status(target, status: String, amount: int) -> void:
		if target == null or status == "" or amount == 0:
			return
		if target == self:
			player_statuses[status] = int(player_statuses.get(status, 0)) + amount
		else:
			target.statuses[status] = int(target.statuses.get(status, 0)) + amount

	func heal_player(amount: int) -> void:
		player_hp = min(player_max_hp, player_hp + max(0, amount))

	func lose_player_hp(amount: int) -> void:
		player_hp -= max(0, amount)

	func gain_max_hp(amount: int) -> void:
		player_max_hp += max(0, amount)
		player_hp += max(0, amount)

	func gain_gold(_amount: int) -> void:
		pass

	func add_card_to_discard(card_id: String) -> void:
		if card_db.has(card_id):
			discard_pile.append({"id": card_id, "upgraded": false})

	func add_card_to_hand(card_id: String) -> void:
		if card_db.has(card_id):
			hand.append({"id": card_id, "upgraded": false})

	func exhaust_random_hand_card(amount: int) -> void:
		for _i in amount:
			if hand.is_empty():
				return
			var idx := rng.randi_range(0, hand.size() - 1)
			exhaust_pile.append(hand[idx])
			hand.remove_at(idx)

	func discard_random_hand_card(amount: int) -> void:
		for _i in amount:
			if hand.is_empty():
				return
			var idx := rng.randi_range(0, hand.size() - 1)
			discard_pile.append(hand[idx])
			hand.remove_at(idx)

	# ── Engine-side convenience used by EnemyInstance.resolve_intent ──
	func take_player_damage_from_enemy(damage: int) -> void:
		var dmg := damage
		if int(player_statuses.get("vulnerable", 0)) > 0:
			dmg = int(round(dmg * 1.5))
		var absorbed: int = min(player_block, dmg)
		player_block -= absorbed
		dmg -= absorbed
		player_hp -= dmg

	func apply_status_to_named_target(target: String, status: String, amount: int, _source = null) -> void:
		if target == "player" or target == "self":
			apply_status(self, status, amount)
		else:
			# Default to current target enemy.
			apply_status(_pick_first_alive_enemy(), status, amount)
