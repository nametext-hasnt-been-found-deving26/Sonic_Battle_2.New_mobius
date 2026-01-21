extends DirectionalLight3D

func _ready() -> void:
	# Disable all shadows for this light
	shadow_enabled = false
