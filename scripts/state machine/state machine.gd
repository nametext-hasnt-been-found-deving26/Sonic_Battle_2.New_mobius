extends Node
class_name StateMachine

## Prints the enter and exit functions in each state.
@export var initial_state : String = "Idle"
@export var debug_mode : bool = false
var _states : Dictionary = {}
var _current_state : State

func _ready() -> void:
	await get_tree().physics_frame
	build_states_dictionary()
	set_parent_in_states()
	
	if not has_state(initial_state):
		print("State not found (%s)" % initial_state)
		return
	
	var first_state : State = _states[initial_state]
	first_state._on_enter()
	_current_state = first_state


func build_states_dictionary() -> void:
	for child in get_children():
		if child is State:
			child.state_machine = self
			_states[child.name] = child

func set_parent_in_states() -> void:
	pass

func _physics_process(delta: float) -> void:
	if _current_state:
		_current_state._on_physics_update(delta)

func _process(delta: float) -> void:
	if _current_state:
		_current_state._on_update(delta)

func transition_to(_state : String, _context : Dictionary = {}) -> void:
	
	if debug_mode:
		print("Exited %s" % _current_state.name)
		print("Entered %s" % _state)
	
	if not has_state(_state):
		print("Failed to transition from (%s) to the next state (%s)" % [_current_state.name,_state])
		return
	# we call the exit function on the current state
	# useful for cleaning up logic or variables
	_current_state._on_exit()
	# we get the next state from the states dict
	var next_state : State = _states[_state]
	# we call enter first before we set it to current state
	# we do this to avoid calling the update functions early
	next_state._on_enter(_context)
	_current_state = next_state

func has_state(state : String) -> bool:
	return _states.has(state)
