extends Node

@export var combos : Array[Combo]
@export var v_box : VBoxContainer

enum Keys {FORWARD,BACKWARD,LEFT,RIGHT,JUMP,ATTACK,SPECIAL,BLOCK}

var key_translation : Dictionary[int,String] = {
	Keys.FORWARD  : "Forward",
	Keys.BACKWARD : "Backward",
	Keys.LEFT     : "Left",
	Keys.RIGHT    : "Right",
	Keys.JUMP     : "Jump",
	Keys.ATTACK   : "Attack",
	Keys.SPECIAL  : "Special",
	Keys.BLOCK    : "Block"}
	
var move_translation : Dictionary[int,String] = {
	CM.Moves.DASH : "Dash",
	CM.Moves.ATK_1 : "Attack 1",
	CM.Moves.ATK_2 : "Attack 2",
	CM.Moves.ATK_3 : "Attack 3",
	CM.Moves.HEAVY_ATK : "Heavy Attack",
	CM.Moves.AIR_ATK : "Air Attack",
	CM.Moves.SPECIAL : "Special",
}
## buffer that holds the input and the frame it was added ##
var buffer : Array[input_data]
## keeping frames ##
var current_frame : int = 0
## How long an input can stay in the buffer in frames ##
const EXPIRE_FRAMES_MAX : int = 28
## pending combo, with its indices and frames ##
var pending_combo : Combo = null
var pending_indices : Array[int] = []
var pending_frame : int = -1
## Wait n amouunt of frames before executing a combo ##
const WAIT_FRAMES : int = 8
## A local class specific for this system
class input_data:
	var input : int = -1
	var frame : int = -1
	
	func _init(_input : int, _frame : int) -> void:
		input = _input
		frame = _frame
	
	func _to_string() -> String:
		return "Key: %s, Time: %s" % [input,frame]

func _ready() -> void:
	# for debug only!
	generate_combos_list()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		
		if event.is_action_pressed("left"):
			buffer.push_back(input_data.new(Keys.LEFT,current_frame))
			
		if event.is_action_pressed("right"):
			buffer.push_back(input_data.new(Keys.RIGHT,current_frame))
			
		if event.is_action_pressed("forward"):
			buffer.push_back(input_data.new(Keys.FORWARD,current_frame))
			
		if event.is_action_pressed("backward"):
			buffer.push_back(input_data.new(Keys.BACKWARD,current_frame))
			
		if event.is_action_pressed("punch"):
			buffer.push_back(input_data.new(Keys.ATTACK,current_frame))
			
		if event.is_action_pressed("special"):
			buffer.push_back(input_data.new(Keys.SPECIAL,current_frame))
		

func _physics_process(_delta: float) -> void:
	current_frame += 1

	clean_up_buffer()
	
	if pending_combo == null:
		var found_result : Dictionary = search_for_combo()
		
		if found_result:
			pending_combo = found_result["Combo"]
			pending_indices = found_result["Indices"]
			pending_frame = current_frame
		
	elif can_be_extended(pending_combo):
		if (current_frame - pending_frame) > WAIT_FRAMES:
			commit_combo(pending_combo,pending_indices)
		else:
			# Search for a longer combo:
			var found_result : Dictionary = search_for_longer_combo()
			
			if found_result:
				pending_combo = found_result["Combo"]
				pending_indices = found_result["Indices"]
				pending_frame = current_frame
			
	elif (current_frame - pending_frame) > WAIT_FRAMES:
		commit_combo(pending_combo,pending_indices)

func generate_combos_list() -> void:
	for combo in combos:
		var input_string : String = ""
		for input in combo.inputs:
			input_string += key_translation[input] + " + "
			
		input_string = input_string.substr(0, input_string.length() - 3)
		input_string += " = " + move_translation[combo.action]
		
		var label : Label = Label.new()
		v_box.add_child(label)
		label.text = input_string
		
func search_for_combo() -> Dictionary:
	
	var found_result : Dictionary = {"Combo" : null,"Indices" : []}
	
	for combo in combos:
		var result : Array[int] = match_combo(combo.inputs)
		
		if result:
			found_result["Combo"] = combo
			found_result["Indices"] = result
			return found_result
	
	return {}

func search_for_longer_combo() -> Dictionary:
	
	if pending_combo == null:
		return {}
	
	var found_result : Dictionary = {"Combo" : null,"Indices" : []}
	
	for combo in combos:
		# we skip combos that are shorter or the same length
		if combo.inputs.size() <= pending_combo.inputs.size():
			continue
		
		var result : Array[int] = match_combo(combo.inputs)
		# if the result is not empty, we have found a longer combo.
		if not result.is_empty():
			found_result["Combo"] = combo
			found_result["Indices"] = result
			return found_result
	
	return {}

func match_combo(inputs: Array[Combo.valid_inputs]) -> Array[int]:
	if buffer.size() < inputs.size():
		return []

	var matched_indices : Array[int] = []

	for i in range(inputs.size()):
		var buffer_index := buffer.size() - 1 - i
		var combo_index  := inputs.size() - 1 - i

		if buffer[buffer_index].input != inputs[combo_index]:
			return []

		matched_indices.push_back(buffer_index)

	return matched_indices

func can_be_extended(base_combo : Combo) -> bool:
	for combo in combos:
		if combo.inputs.size() <= base_combo.inputs.size():
			continue

		if is_prefix(base_combo.inputs, combo.inputs):
			return true

	return false


func is_prefix(shorter : Array, longer : Array) -> bool:
	for i in range(shorter.size()):
		if shorter[i] != longer[i]:
			return false
	return true

func commit_combo(combo : Combo, indices : Array[int]) -> void:
	print("EXECUTE COMBO:", move_translation[combo.action])
	clear_used_combo(indices)
	clear_pending()
	
func clear_pending() -> void:
	pending_combo = null
	pending_indices = []
	pending_frame = -1

func clear_used_combo(s : Array[int]) -> void:
	for i in s:
		buffer.remove_at(i)

func clean_up_buffer() -> void:
	for i in range(buffer.size() - 1, -1, -1):
		if current_frame - buffer[i].frame > EXPIRE_FRAMES_MAX:
			buffer.remove_at(i)
	
	# stop a pending combo is the buffer size does not match the combo size.
	if buffer.size() < pending_indices.size():
		pending_combo = null
		pending_frame = 0
		pending_indices.clear()
