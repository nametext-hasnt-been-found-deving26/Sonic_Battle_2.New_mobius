extends Node
class_name StateMachine

signal state_changed(old_state, new_state) # We'll be using this for state changes.

# Current active state
var current_state: State = null
# Reference to the character this state machine controls
var character: CharacterBody3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	if current_state:
		current_state.enter()

func initialize(char: CharacterBody3D, initial_state: State) -> void:
	character = char
	change_state(initial_state)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)
	

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	# Exit current state
	if current_state:
		current_state.exit()
	
	var old_state = current_state
	current_state = new_state
	
	# Enter new state
	if current_state:
		current_state.character = character
		current_state.state_machine = self
		current_state.enter()
		state_changed.emit(old_state, current_state)

class State:
	var character: CharacterBody3D
	var state_machine: StateMachine
	var timer: float = 0.0
	
	func enter() -> void:
		pass
	
	func exit() -> void:
		pass
	
	func update(delta: float) -> void:
		pass
	
	func get_animation_name() -> String:
		return "Idle"
