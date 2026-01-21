extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	movexminus()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func movexminus():
	# Create the tween
	var tween = create_tween()
	
	# Start invisible and slide in from the left
	position.x += 1500  # Start 1,500 pixels to the left
	
	# Animate entrance with ease-out
	tween.parallel().tween_property(self, "position:x", position.x - 1500, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
