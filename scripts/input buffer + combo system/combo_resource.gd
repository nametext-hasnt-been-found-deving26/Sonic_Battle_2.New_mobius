extends Resource
class_name Combo

enum valid_inputs {FORWARD,BACKWARD,LEFT,RIGHT,JUMP,ATTACK,SPECIAL,BLOCK}

@export var inputs : Array[valid_inputs]
@export var action : CM.Moves
