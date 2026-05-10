extends Control

const RUN_SCENE := preload("res://scenes/run/run_scene.tscn")
const ThemeFactoryScript := preload("res://scripts/ui/theme_factory.gd")


func _ready() -> void:
	theme = ThemeFactoryScript.build_theme()
	var run := RUN_SCENE.instantiate()
	add_child(run)
