extends StateMachine
class_name SonicStateMachine

@export var sonic : Sonic

func set_parent_in_states() -> void:
	for state in _states:
		_states[state].sonic = sonic
