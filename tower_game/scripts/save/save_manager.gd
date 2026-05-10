class_name SaveManager
extends RefCounted

const RUN_SAVE_PATH := "user://tower_run.json"


func save_run(data: Dictionary) -> void:
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open run save for writing.")
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_run() -> Dictionary:
	if not FileAccess.file_exists(RUN_SAVE_PATH):
		return {}
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open run save for reading.")
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func clear_run() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_SAVE_PATH))
