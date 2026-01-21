extends Node2D

var KO_s: int
var parent
@onready var tens_sprite: AnimatedSprite2D = $tens
@onready var units_sprite: AnimatedSprite2D = $units

func _ready():
	parent = $"../../.."
	
	update_display(KO_s)
func _process(delta: float) -> void:
	KO_s = parent.KO_s
	update_display(KO_s)

#func set_value(new_value: int) -> void:
	
	#KO_s = max(new_value, 0)
	

func update_display(number: int) -> void:
	var units = number % 10
	var tens = (number / 10) % 10

	units_sprite.play(str(units))
	tens_sprite.play(str(tens))
