extends TextureProgressBar

var parent
var max_value_amount
var min_value_amount

func _ready():
	parent = $"../../.."
	
	# Debug parent path
	print("Health bar parent node: ", parent.name if is_instance_valid(parent) else "Invalid parent")
	
	# Safely get Maxhealth with fallback
	if "Maxhealth" in parent:
		max_value_amount = parent.Maxhealth
		print("Maxhealth found: ", max_value_amount)
	else:
		push_error("Parent is missing 'Maxhealth' property! Using fallback value of 100.")
		max_value_amount = 100  # fallback

	min_value_amount = 0
	
	self.max_value = max_value_amount
	self.min_value = min_value_amount
	
	# Set initial value immediately
	if is_instance_valid(parent) and "health" in parent:
		self.value = clamp(parent.health, min_value_amount, max_value_amount)
		print("Initial health set to: ", self.value)
	else:
		self.value = max_value_amount  # Default to full if we can't read health
		print("Using default full health value")

func _process(delta):
	if not is_instance_valid(parent):
		return

	# Get current health safely
	var current_health = 0
	if "health" in parent:
		current_health = parent.health
	else:
		current_health = max_value_amount  # Default to full if property missing
	
	# Clamp to valid range
	current_health = clamp(current_health, min_value_amount, max_value_amount)
	
	# Set value directly (no smoothing for now to debug)
	self.value = current_health
	
	# Debug current value
	#print("Health bar value: ", self.value, " | Current health: ", current_health)

	# Calculate health percentage 
	var health_percentage = self.value / max_value_amount if max_value_amount > 0 else 0.0

	# Healing state detection
	var is_healing = false
	if "is_healing" in parent:
		is_healing = parent.is_healing
	elif "current_state" in parent and "State" in parent:
		# Check if in any healing state
		var healing_states = [parent.State.HEAL_START, parent.State.HEAL_LOOP, parent.State.HEAL_END]
		is_healing = parent.current_state in healing_states

	var filter = $"../filter effects"
	if not is_instance_valid(filter) or not filter.has_method("play"):
		return

	# Priority system for filter effects
	if is_healing:
		filter.play("healing")
	elif self.value < 30:
		# Safely check ichikoro and Maxichikoro
		var current_ichikoro = parent.ichikoro if "ichikoro" in parent else 0
		var max_ichikoro = parent.Maxichikoro if "Maxichikoro" in parent else max_value_amount
		
		if current_ichikoro != max_ichikoro:
			filter.play("low_health")
		else:
			filter.play("ichikoro_and_low_health")
	else:
		# Normal health state - stop any active effects
		if filter.has_method("stop"):
			filter.stop()
