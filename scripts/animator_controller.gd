extends Node
class_name AnimatorController

var base : String = "idle"
var currently_playing : String = "None"
var temp : String = "None"
var is_anim_done : bool = true
var animator : AnimatedSprite3D

var stop_update : bool = false

func _init(_animator : AnimatedSprite3D) -> void:
	animator = _animator

func update() -> void:
	if stop_update:
		return
	
	# currently_playing avoids spamming the play func
	if not is_busy() and currently_playing != base:
		currently_playing = base
		play(base)

# base is always the inital state e.g if we are moving the base state is now running
# but if in the move state we have an anim that needs to play we dont set it here.
func set_base(anim : String) -> void:
	if base != anim:  # Only update if changed
		base = anim
		
		if not is_busy():
			play(base)

func play(animation : String, is_temp : bool = false) -> void:
	if !animator or !animator.sprite_frames.has_animation(animation):
		print("Animation not found %s" % animation)
		return
	
	animator.play(animation)
	
	if is_temp:
		temp = animation
		currently_playing = temp
		# Wait for animation to finish
		await animator.animation_finished
		temp = "None"

func is_busy() -> bool:
	return temp != "None"
