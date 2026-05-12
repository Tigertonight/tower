class_name SettingsManager
extends RefCounted

# A1.7 — lightweight, file-backed settings store.
#
# Stores audio volumes (in dB) and a couple of UX toggles. Values are loaded on
# first access and saved whenever any setter is called, so the pause menu can
# tweak settings without explicit save calls.
#
# Volumes are stored as dB on a [-40, +6] range. -40 dB is treated as muted by
# AudioManager. The save file is JSON for easy hand-editing during dev.

const SAVE_PATH := "user://tower_settings.json"

const DEFAULTS := {
	"master_db": 0.0,
	"music_db": -6.0,
	"sfx_db": 0.0,
	"language": "en",
	"fast_resolve": false,
	"show_tutorial_hints": true,
}

var values: Dictionary = {}
var _loaded := false


func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	values = DEFAULTS.duplicate(true)
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for k in parsed.keys():
		if values.has(k):
			values[k] = parsed[k]


func get_value(key: String):
	_ensure_loaded()
	return values.get(key, DEFAULTS.get(key))


func set_value(key: String, value) -> void:
	_ensure_loaded()
	values[key] = value
	_save()


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(values, "  "))
	f.close()


# Apply persisted audio settings to AudioManager (called on game start and after
# any volume change so the change is audible immediately).
func apply_audio(audio_manager) -> void:
	_ensure_loaded()
	if audio_manager == null:
		return
	if audio_manager.has_method("set_master_volume_db"):
		audio_manager.set_master_volume_db(float(values.get("master_db", 0.0)))
	if audio_manager.has_method("set_music_volume_db"):
		audio_manager.set_music_volume_db(float(values.get("music_db", -6.0)))
	if audio_manager.has_method("set_sfx_volume_db"):
		audio_manager.set_sfx_volume_db(float(values.get("sfx_db", 0.0)))
