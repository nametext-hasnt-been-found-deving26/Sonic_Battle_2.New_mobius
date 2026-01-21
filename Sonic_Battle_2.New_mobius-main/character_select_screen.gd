extends Control

@export var arena_scene: String = "res://arena.tscn"
@export var sonic_button: Button

func _ready() -> void:
	if sonic_button:
		sonic_button.pressed.connect(_load_arena)

func _load_arena():
	get_tree().change_scene_to_file(arena_scene)
