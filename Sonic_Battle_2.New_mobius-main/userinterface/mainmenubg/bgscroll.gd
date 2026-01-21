extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x += -100 * delta
	position.y += -100 * delta
	print(position.x)
	
	if position.x == -640:
		position.x = 0
	if position.y == -1920:
		position.y = 0
