extends Control

@export var map_loader : MapLoader



func _on_start_button_pressed() -> void:
	hide()
	map_loader.load_map()
