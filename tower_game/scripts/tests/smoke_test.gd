extends SceneTree

const SCENES := [
	"res://scenes/main/main.tscn",
	"res://scenes/run/run_scene.tscn",
	"res://scenes/combat/combat_scene.tscn",
	"res://scenes/combat/card_view.tscn",
	"res://scenes/ui/reward_screen.tscn"
]

const CARDS := [
	"res://data/cards/strike_form.tres",
	"res://data/cards/guard_form.tres",
	"res://data/cards/archive_bash.tres",
	"res://data/cards/quick_read.tres",
	"res://data/cards/forward_step.tres",
	"res://data/cards/measured_cut.tres",
	"res://data/cards/brace.tres",
	"res://data/cards/shield_tap.tres",
	"res://data/cards/break_rhythm.tres",
	"res://data/cards/oath_pressure.tres"
]

const RELICS := [
	"res://data/relics/sealed_badge.tres"
]

const ART := [
	"res://art/placeholder/vanguard_archivist.svg",
	"res://art/placeholder/dust_scribe.svg",
	"res://art/placeholder/sealed_curator.svg",
	"res://art/placeholder/archive_key.svg",
	"res://art/generated/green_screen_asset_sheet.png",
	"res://art/generated/sprites/vanguard_archivist.png",
	"res://art/generated/sprites/dust_scribe.png",
	"res://art/generated/sprites/sealed_curator.png",
	"res://art/generated/sprites/archive_key.png"
]


func _init() -> void:
	var failed := false
	for path in SCENES:
		failed = _check_load(path) or failed
	for path in CARDS:
		failed = _check_load(path) or failed
	for path in RELICS:
		failed = _check_load(path) or failed
	for path in ART:
		failed = _check_file(path) or failed

	if failed:
		print("Smoke test failed.")
		quit(1)
	else:
		print("Smoke test passed.")
		quit(0)


func _check_load(path: String) -> bool:
	var resource = load(path)
	if resource == null:
		push_error("Failed to load: %s" % path)
		return true
	return false


func _check_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("Missing file: %s" % path)
		return true
	return false
