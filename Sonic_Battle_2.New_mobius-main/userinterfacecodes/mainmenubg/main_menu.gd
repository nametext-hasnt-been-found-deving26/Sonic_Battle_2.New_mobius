extends CanvasLayer

@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

@onready var anim = $Transitions/AnimationPlayer

func _ready() -> void:
	# Add the sound effect player
	add_child(sfx_player)
	sfx_player.stream = preload("res://mode_change.wav")
	sfx_player.volume_db = -4  # Adjust volume if needed
	$Background/AnimatedSprite2D.play("BG")

func _process(delta: float) -> void:
	# Detect left/right input
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		_play_mode_change_sfx()
	$Background/AnimatedSprite2D.rotation += 1 * delta

func _play_mode_change_sfx() -> void:
	if sfx_player and sfx_player.stream:
		sfx_player.play()

func _on_battle_mode_pressed() -> void:
	anim.play("In")
	await anim.animation_finished
	_change_scene_safe("res://arena.tscn")

func _on_story_mode_pressed() -> void:
	anim.play("In")
	await anim.animation_finished
	_change_scene_safe("res://arena.tscn")

func _on_training_pressed() -> void:
	anim.play("In")
	await anim.animation_finished
	_change_scene_safe("res://arena.tscn")

func _change_scene_safe(scene_path: String) -> void:
	if not is_inside_tree():
		await ready

	var tree = get_tree()
	if tree:
		tree.change_scene_to_file(scene_path)
	else:
		push_warning("Scene tree not found — cannot change scene yet.")

func movex():
	# Create the tween
	var tween = create_tween()
	
	# Start invisible and slide in from the right
	self.position.x += -1500  # Start 1,500 pixels to the left
	
	# Animate entrance with ease-out
	tween.parallel().tween_property(self, "position:x", self.position.x - 1500, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
