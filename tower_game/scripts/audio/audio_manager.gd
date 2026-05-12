extends Node

# Tower / Living Archive — global audio manager (autoloaded as `AudioManager`).
# Wired against the event table from `tower/20_audio_plan.md`.
#
# Properties:
#   * 3 buses (Master / Music / SFX) — auto-created on _ready if missing.
#   * Variant selection: picks any of `id_01.ogg`, `id_02.ogg`, ... at random.
#   * Format fallback: checks `.ogg`, `.mp3`, then `.wav` so generated
#     placeholders can land without a manual conversion step.
#   * Pitch jitter on `play_sfx_pitched()` for combat hits.
#   * Throttling: identical SFX within `min_repeat_seconds` are dropped so a
#     burst of card draws doesn't crash the SFX pool.
#   * Missing-file fallback: warns once per id, never crashes, never logs again.
#
# Usage (autoload form, recommended):
#   AudioManager.play_sfx("sfx_card_play_attack")
#   AudioManager.play_music("mus_combat_normal")
#
# If the autoload isn't registered yet, callers can fall back to a node lookup:
#   var am = get_node_or_null("/root/AudioManager")
#   if am != null: am.play_sfx("...")

const SFX_BASE := "res://audio/sfx/"
const MUSIC_BASE := "res://audio/music/"
const AMB_BASE := "res://audio/ambience/"

const MAX_SFX := 8
const VARIANT_LIMIT := 4  # check id, id_01..id_04
const DEFAULT_THROTTLE_SECONDS := 0.06
const STREAM_EXTENSIONS := ["ogg", "mp3", "wav"]

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "Sfx"

const SFX_MAX_SECONDS := {
	"sfx_ui_run_start": 0.65,
	"sfx_ui_button_click": 0.12,
	"sfx_ui_hover_soft": 0.10,
	"sfx_card_draw": 0.22,
	"sfx_card_shuffle": 0.60,
	"sfx_card_play_attack": 0.34,
	"sfx_card_play_skill": 0.34,
	"sfx_card_play_power": 0.60,
	"sfx_combat_hit": 0.22,
	"sfx_combat_block": 0.30,
	"sfx_combat_status_neg": 0.34,
	"sfx_combat_status_pos": 0.34,
	"sfx_turn_start": 0.38,
	"sfx_turn_end": 0.34,
	"sfx_enemy_intent": 0.36,
	"sfx_combat_victory": 1.25,
	"sfx_combat_defeat": 1.45,
	"sfx_reward_appear": 0.55,
	"sfx_reward_pick": 0.34,
	"sfx_shop_enter": 0.75,
	"sfx_shop_buy": 0.50,
	"sfx_campfire_rest": 1.25,
	"sfx_campfire_upgrade": 1.15,
	"sfx_event_open": 0.55,
	"sfx_boss_intro": 1.85,
	"sfx_boss_phase_shift": 1.65,
	"sfx_move_paper_storm": 1.05,
}

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _stream_cache: Dictionary = {}
var _missing_warned: Dictionary = {}
var _last_played_at: Dictionary = {}
var _current_music_id: String = ""
var _current_ambient_id: String = ""
var _verbose: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_ensure_buses()

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = BUS_MUSIC  # ambient rides the music bus so it ducks together
	add_child(_ambient_player)

	for i in MAX_SFX:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)


func _ensure_buses() -> void:
	# Add Music / Sfx buses if the project hasn't been configured yet. Default
	# mix from the audio plan: master 0 dB, music -6 dB, sfx 0 dB.
	if AudioServer.get_bus_index(BUS_MUSIC) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_MUSIC)
		AudioServer.set_bus_send(idx, BUS_MASTER)
		AudioServer.set_bus_volume_db(idx, -6.0)
	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus()
		var idx2 := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx2, BUS_SFX)
		AudioServer.set_bus_send(idx2, BUS_MASTER)
		AudioServer.set_bus_volume_db(idx2, 0.0)


# ─── Public API ────────────────────────────────────────────────────────────────

func play_sfx(sfx_id: String, volume_db: float = 0.0, throttle: float = DEFAULT_THROTTLE_SECONDS) -> void:
	if sfx_id.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if throttle > 0.0:
		var last := float(_last_played_at.get(sfx_id, -10.0))
		if now - last < throttle:
			return
	var stream := _try_load_stream(SFX_BASE, sfx_id)
	if stream == null:
		_warn_missing(sfx_id)
		return
	var player := _pick_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	player.play()
	_stop_sfx_after_design_tail(player, sfx_id, stream)
	_last_played_at[sfx_id] = now


func play_sfx_pitched(sfx_id: String, semitone_jitter: float = 1.0, volume_db: float = 0.0) -> void:
	# Used for combat_hit etc. so a streak doesn't sound robotic.
	if sfx_id.is_empty():
		return
	var stream := _try_load_stream(SFX_BASE, sfx_id)
	if stream == null:
		_warn_missing(sfx_id)
		return
	var player := _pick_free_sfx_player()
	if player == null:
		return
	var jitter := _rng.randf_range(-semitone_jitter, semitone_jitter)
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pow(2.0, jitter / 12.0)
	player.play()
	_stop_sfx_after_design_tail(player, sfx_id, stream)


func play_music(track_id: String, fade_ms: int = 600) -> void:
	if track_id.is_empty():
		return
	if track_id == _current_music_id and _music_player.playing:
		return
	var stream := _try_load_stream(MUSIC_BASE, track_id)
	if stream == null:
		_warn_missing(track_id)
		return
	_current_music_id = track_id
	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()
	if fade_ms > 0:
		_music_player.volume_db = -40.0
		var t := create_tween()
		t.tween_property(_music_player, "volume_db", 0.0, float(fade_ms) / 1000.0)


func stop_music(fade_ms: int = 600) -> void:
	_current_music_id = ""
	if not _music_player.playing:
		return
	if fade_ms > 0:
		var t := create_tween()
		t.tween_property(_music_player, "volume_db", -40.0, float(fade_ms) / 1000.0)
		t.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


func play_ambient(amb_id: String, fade_ms: int = 1200) -> void:
	if amb_id.is_empty():
		stop_ambient(fade_ms)
		return
	if amb_id == _current_ambient_id and _ambient_player.playing:
		return
	var stream := _try_load_stream(AMB_BASE, amb_id)
	if stream == null:
		_warn_missing(amb_id)
		return
	_current_ambient_id = amb_id
	_ambient_player.stop()
	_ambient_player.stream = stream
	_ambient_player.play()
	if fade_ms > 0:
		_ambient_player.volume_db = -40.0
		var t := create_tween()
		t.tween_property(_ambient_player, "volume_db", -8.0, float(fade_ms) / 1000.0)


func stop_ambient(fade_ms: int = 1200) -> void:
	_current_ambient_id = ""
	if not _ambient_player.playing:
		return
	if fade_ms > 0:
		var t := create_tween()
		t.tween_property(_ambient_player, "volume_db", -40.0, float(fade_ms) / 1000.0)
		t.tween_callback(_ambient_player.stop)
	else:
		_ambient_player.stop()


# ─── Volume controls ───────────────────────────────────────────────────────────

func set_master_volume_db(db: float) -> void:
	_set_bus_db(BUS_MASTER, db)


func set_music_volume_db(db: float) -> void:
	_set_bus_db(BUS_MUSIC, db)


func set_sfx_volume_db(db: float) -> void:
	_set_bus_db(BUS_SFX, db)


func _set_bus_db(bus: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)


# ─── Internals ─────────────────────────────────────────────────────────────────

func _try_load_stream(base: String, id: String) -> AudioStream:
	var cached = _stream_cache.get(id, null)
	if cached != null and cached is AudioStream:
		return cached
	# First check the bare path, then search numbered variants and pick at random.
	var found: Array[String] = []
	for ext in STREAM_EXTENSIONS:
		var bare := "%s%s.%s" % [base, id, ext]
		if ResourceLoader.exists(bare) or FileAccess.file_exists(bare):
			found.append(bare)
		for v in range(1, VARIANT_LIMIT + 1):
			var candidate := "%s%s_%02d.%s" % [base, id, v, ext]
			if ResourceLoader.exists(candidate) or FileAccess.file_exists(candidate):
				found.append(candidate)
	if found.is_empty():
		return null
	var pick := found[_rng.randi_range(0, found.size() - 1)]
	var stream = _load_audio_stream(pick)
	if stream is AudioStream:
		_stream_cache[id] = stream
		return stream
	return null


func _load_audio_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var imported = load(path)
		if imported is AudioStream:
			return imported
	if path.ends_with(".wav"):
		return AudioStreamWAV.load_from_file(path)
	if path.ends_with(".mp3"):
		return AudioStreamMP3.load_from_file(path)
	if path.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(path)
	return null


func _pick_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	# Pool exhausted (>8 simultaneous SFX). The audio plan says drop the oldest.
	var oldest := _sfx_players[0]
	oldest.stop()
	return oldest


func _warn_missing(id: String) -> void:
	if _missing_warned.has(id):
		return
	_missing_warned[id] = true
	if _verbose:
		push_warning("AudioManager: missing audio asset '%s'" % id)


func _stop_sfx_after_design_tail(player: AudioStreamPlayer, sfx_id: String, stream: AudioStream) -> void:
	if not SFX_MAX_SECONDS.has(sfx_id):
		return
	var seconds := float(SFX_MAX_SECONDS[sfx_id])
	if seconds <= 0.0:
		return
	_stop_sfx_player_later(player, stream, seconds)


func _stop_sfx_player_later(player: AudioStreamPlayer, stream: AudioStream, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(player) and player.playing and player.stream == stream:
		player.stop()
