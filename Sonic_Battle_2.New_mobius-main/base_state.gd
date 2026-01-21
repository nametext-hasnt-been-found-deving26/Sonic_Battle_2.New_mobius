# base_character.gd (Updated to work with state machine)
extends CharacterBody3D

# State Machine (common to all characters)
enum State { IDLE, RUNNING, JUMPING, FALLING, LANDING, ATTACK_1, ATTACK_2, ATTACK_3, HEAVY_ATTACK, UPPER_ATTACK, AIR_ACTION, AIR_ATTACK, GUARD, HEAL_START, HEAL_LOOP, HEAL_END, TURNING_AROUND, TURNING_AROUND_WHILE_RUNNING, STOPPING, WALL_CLING }

# Heavy Attack Phases
enum HeavyPhase { DROP, HANDSTAND, FLARE, LEG_LIFT, RECOVERY }

# ===== MODULAR CONFIGURATION - MAKE ALL CHARACTER STATS CONFIGURABLE =====
@export_category("Character Identity")
@export var character_name: String = "Character"
@export var character_id: String = "default"

@export_category("Movement Settings")
@export var max_speed: float = 8.0
@export var acceleration: float = 0.5
@export var friction: float = 0.4
@export var air_control_factor: float = 0.33

@export_category("Jump Settings")
@export var jump_force: float = 4.5
@export var air_action_force: float = 8.0
@export var air_action_upward_boost: float = 2.0

@export_category("Combat Settings")
@export var attack_cooldown_duration: float = 0.3
@export var combo_window_ms: int = 500
@export var input_buffer_duration: float = 0.1
@export var heavy_attack_recovery: float = 0.5
@export var air_attack_cooldown_duration: float = 0.6

# Sonic Flare Phase Durations
@export_category("Heavy Attack - Sonic Flare")
@export var flare_drop_speed: float = 20.0
@export var flare_handstand_duration: float = 0.15
@export var flare_sweep_duration: float = 0.4
@export var flare_leg_lift_duration: float = 0.25
@export var flare_recovery_duration: float = 0.3
@export var flare_recovery_lift: float = 3.0
@export var flare_recoil_pushback: float = 2.0

@export_category("State Durations")
@export var landing_duration: float = 0.2
@export var attack_duration: float = 0.4
@export var upper_attack_duration: float = 0.4
@export var air_action_duration: float = 0.4
@export var air_attack_duration: float = 0.3
@export var turning_duration: float = 0.3
@export var turning_while_running_duration: float = 0.25
@export var stopping_duration: float = 0.2
@export var heal_start_duration: float = 0.3
@export var heal_loop_duration: float = 1.0
@export var heal_end_duration: float = 0.3
@export var wall_cling_duration: float = 1.0

@export_category("Health & Energy Settings")
@export var Maxhealth: int = 100
var health: int = 100

@export var Maxichikoro: float = 100.0
var ichikoro: float = 100.0

@export_category("Healing Settings")
@export var heal_amount_per_second: float = 20.0
@export var ichikoro_regen_per_second: float = 30.0

@export_category("Animation Settings")
@onready var animated_sprite_3d: AnimatedSprite3D = $AnimatedSprite3D

# State Machine Reference
@onready var state_machine: StateMachine = $StateMachine

# ===== INTERNAL VARIABLES =====
var current_state: State = State.IDLE
var heavy_phase: HeavyPhase = HeavyPhase.DROP

# Timers
var landing_timer: float = 0.0
var attack_timer: float = 0.0
var upper_attack_timer: float = 0.0
var air_action_timer: float = 0.0
var air_attack_timer: float = 0.0
var turning_timer: float = 0.0
var turning_while_running_timer: float = 0.0
var stopping_timer: float = 0.0
var heal_start_timer: float = 0.0
var heal_loop_timer: float = 0.0
var heal_end_timer: float = 0.0
var wall_cling_timer: float = 0.0
var heavy_phase_timer: float = 0.0
var ichikoro_regen_cooldown: float = 0.0

# Combat System
var attack_combo_count: int = 0
var can_combo: bool = false
var is_attacking: bool = false
var last_attack_time: int = 0
var is_healing: bool = false
var has_air_action: bool = true
var has_air_attacked: bool = false
var attack_cooldown: float = 0.0
var air_attack_cooldown: float = 0.0

# Input buffering
var attack_input_buffer: bool = false
var attack_input_cooldown: float = 0.0

# Direction tracking
var last_input_direction: Vector2 = Vector2.ZERO
var current_facing_direction: int = 1

# Physics
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# ===== INITIALIZATION =====
func _ready() -> void:
	# Initialize health and ichikoro to max values
	health = Maxhealth
	ichikoro = Maxichikoro
	
	validate_animations()
	
	# Initialize state machine
	if state_machine:
		state_machine.root_node = self
		state_machine.setup_states()

func validate_animations() -> void:
	if animated_sprite_3d and animated_sprite_3d.sprite_frames:
		var animations = animated_sprite_3d.sprite_frames.get_animation_names()
		print("=== AVAILABLE ANIMATIONS ===")
		for anim in animations:
			print(" - '", anim, "'")
		print("=============================")
		var critical_anims = ["1st attack", "2nd attack", "3rd attack", "Heavy attack", "Upper attack", "Air action", "Air attack", "Guard", "Heal start", "Heal loop", "Heal end"]
		for anim_name in critical_anims:
			if animated_sprite_3d.sprite_frames.has_animation(anim_name):
				print("SUCCESS: '", anim_name, "' found!")
			else:
				print("ERROR: '", anim_name, "' NOT found!")
	else:
		print("ERROR: No SpriteFrames resource assigned!")

# ===== MAIN PROCESS =====
func _physics_process(delta: float) -> void:
	update_cooldowns(delta)
	regenerate_ichikoro(delta)
	move_and_slide()

func update_cooldowns(delta: float) -> void:
	if attack_cooldown > 0:
		attack_cooldown -= delta
	if attack_input_cooldown > 0:
		attack_input_cooldown -= delta
		if attack_input_cooldown <= 0:
			attack_input_buffer = false
	if air_attack_cooldown > 0:
		air_attack_cooldown -= delta
		if air_attack_cooldown < 0:
			air_attack_cooldown = 0.0

func regenerate_ichikoro(delta: float) -> void:
	# Passive ichikoro regeneration when not in combat
	if not is_attacking and not is_healing and current_state not in [State.ATTACK_1, State.ATTACK_2, State.ATTACK_3, State.HEAVY_ATTACK, State.AIR_ATTACK]:
		ichikoro_regen_cooldown -= delta
		if ichikoro_regen_cooldown <= 0:
			ichikoro = min(ichikoro + 5.0 * delta, Maxichikoro)
			ichikoro_regen_cooldown = 0.1

# Helper method for state machine
func _get_state_enum(state_name: String) -> State:
	match state_name:
		"IDLE": return State.IDLE
		"RUNNING": return State.RUNNING
		"JUMPING": return State.JUMPING
		"FALLING": return State.FALLING
		"LANDING": return State.LANDING
		"ATTACK1": return State.ATTACK_1
		"ATTACK2": return State.ATTACK_2
		"ATTACK3": return State.ATTACK_3
		"HEAVYATTACK": return State.HEAVY_ATTACK
		"UPPERATTACK": return State.UPPER_ATTACK
		"AIRACTION": return State.AIR_ACTION
		"AIRATTACK": return State.AIR_ATTACK
		"GUARD": return State.GUARD
		"HEALSTART": return State.HEAL_START
		"HEALLOOP": return State.HEAL_LOOP
		"HEALEND": return State.HEAL_END
		"TURNINGAROUND": return State.TURNING_AROUND
		"TURNINGAROUNDWHILERUNNING": return State.TURNING_AROUND_WHILE_RUNNING
		"STOPPING": return State.STOPPING
		"WALLCLING": return State.WALL_CLING
		_: return State.IDLE
