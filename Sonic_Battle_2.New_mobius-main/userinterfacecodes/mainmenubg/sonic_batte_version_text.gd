extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func movey():
	# Create the tween
	var tween = create_tween()
	
	# Start invisible and slide in from the top
	position.y += 20  # Start 1,500 pixels to the top
	
	# Animate entrance with ease-out
	tween.parallel().tween_property(self, "position:y", position.y - 20, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
