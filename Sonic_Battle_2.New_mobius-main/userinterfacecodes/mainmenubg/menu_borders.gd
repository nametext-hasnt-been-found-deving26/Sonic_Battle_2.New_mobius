extends Control

@onready var _1: TextureRect = $"1"
@onready var _2: TextureRect = $"2"


func _ready() -> void:
	top()
	bottom()
	



func top():
	var top_tween : Tween = create_tween()
	#if top_tween: top_tween.kill()
	top_tween.tween_property(_1,"position",Vector2(0,-50),0.1)
	top_tween.tween_property(_1,"position",Vector2(0,0),0.1)
	await top_tween.finished

	
func bottom():
	var bottom_tween : Tween = create_tween()
	#if bottom_tween: bottom_tween.kill()
	bottom_tween.tween_property(_2,"position",Vector2(0,632),0.1)
	bottom_tween.tween_property(_2,"position",Vector2(0,432),0.1)
	await bottom_tween.finished
