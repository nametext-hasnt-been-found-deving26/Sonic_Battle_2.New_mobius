extends Control


func _ready() -> void:
	var tween : Tween = create_tween()
	#if tween: tween.kill()
	tween.tween_property(%bg,"position",Vector2(-256,-2),0.1)
	tween.tween_property(%bg,"position",Vector2(-256,-42),0.3)
	await tween.finished
	

func bounce():
	var tween : Tween = create_tween()
	#if tween: tween.kill()
	tween.tween_property(%bg,"position",Vector2(-256,-22),0.1)
	tween.tween_property(%bg,"position",Vector2(-256,-42),0.1)
	await tween.finished
