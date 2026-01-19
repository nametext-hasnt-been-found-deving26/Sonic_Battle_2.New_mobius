extends Node
class_name State

var state_machine : StateMachine

func _on_enter(_context : Dictionary = {}) -> void:
	pass

func _on_exit() -> void:
	pass

func _on_update(_delta : float) -> void:
	pass

func _on_physics_update(_delta : float) -> void:
	pass

func transition(state : String, context : Dictionary = {}) -> void:
	state_machine.transition_to(state,context)
