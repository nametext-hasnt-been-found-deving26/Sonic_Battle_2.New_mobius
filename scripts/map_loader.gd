extends Node3D
class_name MapLoader

@export_group("Maps")
@export var map_packages : Array[ArenaPackage]

@export_group("Node requirments")
@export var arena_root    : Node3D
@export var song_player   : AudioStreamPlayer
@export var right_button  : Button
@export var current_map_l : Label
@export var left_button   : Button

## Temp ##
# temp storing the playable character and the AI here for now...
@export var player_char : PackedScene
@export var enemy_char : PackedScene

## Private ##
var _current_id    : int = 0
var _map           : Node3D
var _arena_package : ArenaPackage
var _disabled      : bool = false


func _ready() -> void:
	
	if map_packages.is_empty():
		print("Map array is empty, Please add maps")
		_disabled = true
		return
	
	if not is_instance_valid(song_player):
		print("Song player is null, please set it!")
		_disabled = true
		return
	
	current_map_l.text = "- %s -" % map_packages[_current_id].arena_title

func load_map() -> void:
	unload_map()
	
	_arena_package = map_packages[_current_id]
	
	song_player.stream = _arena_package.arena_song
	
	_map = _arena_package.arena_scene.instantiate()
	arena_root.add_child(_map)
	
	var spawn_root : Node3D = _map.get_node("SpawnPoints")
	
	if not is_instance_valid(spawn_root):
		print("Spawn points not valid, returning...")
		return
	
	var points : Array = spawn_root.get_children()
	var player_pos : Vector3 = find_a_valid_spawn_point(points)
	var enemy_pos : Vector3 = find_a_valid_spawn_point(points)
	
	var player : Node3D = player_char.instantiate()
	var enemy : Node3D = enemy_char.instantiate()
	
	# This is also temp as in the future a higher class would send players/npcs to here
	arena_root.add_child(player)
	player.global_position = player_pos
	arena_root.add_child(enemy)
	enemy.global_position = enemy_pos
	print(enemy)
	
	song_player.play()

func find_a_valid_spawn_point(spawn_points : Array[Node]) -> Vector3:
	
	var found_valid_point : bool = false
	var found_point : Vector3 = Vector3.ZERO
	
	spawn_points.shuffle()
	
	while found_valid_point != true:
		var point : Node3D = spawn_points.pick_random()
		if point.name != "NotValid":
			point.name = "NotValid"
			found_point = point.global_position
			found_valid_point = true
			
	
	
	return found_point

func unload_map() -> void:
	if is_instance_valid(_map):
		_map.queue_free()
		_map = null
		song_player.stop()

func present_next_map(dir : String) -> void:
	
	match dir:
		"+":
			_current_id = wrapi(_current_id + 1, 0, map_packages.size())
		"-":
			_current_id = wrapi(_current_id - 1, 0, map_packages.size())
		_:
			return 
	
	current_map_l.text = "- %s -" % map_packages[_current_id].arena_title

func _on_previous_pressed() -> void:
	present_next_map("-")

func _on_next_pressed() -> void:
	present_next_map("+")
