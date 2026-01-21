extends ScrollContainer

@onready var list_container = $HBoxContainer

var current_index := 0
var scroll_target := 0.0
var scroll_speed := 50.0   # Adjust for faster/slower smooth scrolling

func _ready():
	movexminus()
	update_highlight()
	scroll_to_current()

func _unhandled_input(event):
	if event.is_action_pressed("ui_right"):
		# Move right and loop around
		current_index = (current_index + 1) % list_container.get_child_count()
		$"../arrow_handler".play("hit_arrow_right")
		scroll_to_current()
	elif event.is_action_pressed("ui_left"):
		# Move left and loop around
		current_index = (current_index - 1 + list_container.get_child_count()) % list_container.get_child_count()
		$"../arrow_handler".play("hit_arrow_left")
		scroll_to_current()
	if event.is_action_pressed("ui_accept"):
		var focused := get_viewport().gui_get_focus_owner() as Button
		if focused:
			focused.emit_signal("pressed")

func scroll_to_current():
	if list_container.get_child_count() == 0:
		return

	var target = list_container.get_child(current_index)
	# Center the selected button horizontally relative to the ScrollContainer
	scroll_target = target.position.x - size.x / 2 + target.size.x / 2
	update_highlight()

func _process(delta):
	# Smoothly interpolate scroll
	var t = clamp(delta * scroll_speed, 0.0, 1.0)
	scroll_horizontal = lerp(float(scroll_horizontal), float(scroll_target), t)

func update_highlight():
	for i in range(list_container.get_child_count()):
		var btn = list_container.get_child(i)
		if i == current_index:
			btn.scale = Vector2(1.1, 1.1)  # slightly bigger
			btn.grab_focus()
		else:
			btn.scale = Vector2.ONE
	

func scale():
	# Create the tween
	var tween = create_tween()
	
	# Start invisible and slide in from the right
	size.x += 2  # Scale 2 pixels across
	size.y += 2  # Start 2 pixels across
	
	# Animate entrance with ease-out
	tween.parallel().tween_property(self, "position:x", size.x - 1500, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

func movexminus():
	# Create the tween
	var tween = create_tween()
	
	# Start invisible and slide in from the left
	position.x -= 1500  # Start 1,500 pixels to the left
	
	# Animate entrance with ease-out
	tween.parallel().tween_property(self, "position:x", position.x + 1500, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
