class_name SlidingPlayerState
extends State

@export var SPEED: float = 20.0  # Base sliding speed
@export var ACCELERATION: float = 0.1  # How quickly we reach max slide speed
@export var DECELERATION: float = 0.25  # How quickly we slow down
@export var TILT_AMOUNT: float = 0.09  # Amount of tilt during slides
@export_range(1.0, 0.1) var SLIDE_ANIM_SPEED: float = 4.0  # Animation speed multiplier
@export var MIN_SLIDE_SPEED: float = 2.0  # Minimum speed before exiting slide
@export var SLIDE_FRICTION: float = 0.98  # Friction multiplier while sliding

@onready var CROUCH_SHAPECAST: ShapeCast3D = %ShapeCast3D
@export var ANIMATION: AnimationPlayer

var slide_velocity: Vector3 = Vector3.ZERO
var initial_slide_direction: Vector3 = Vector3.ZERO

func enter(previous_state = null) -> void:
	if not Global.player:
		push_warning("Player reference not found")
		return
		
	var player = Global.player
	
	# Store initial slide direction and velocity
	initial_slide_direction = -player.global_transform.basis.z
	slide_velocity = player.velocity
	
	# Set up the slide animation
	if ANIMATION and ANIMATION.has_animation("sliding"):
		set_tilt(player._current_rotation)
		var anim = ANIMATION.get_animation("sliding")
		anim.track_set_key_value(0, 4, player.velocity.length())  # Track index, key index, value
		ANIMATION.speed_scale = 1.0
		ANIMATION.play("sliding", -1.0, SLIDE_ANIM_SPEED)
	
	# Adjust collision shape for sliding (if needed)
	adjust_collision_shape()

func update(delta: float) -> void:
	if not Global.player:
		return
		
	var player = Global.player
	
	# Update gravity
	player.update_gravity(delta)
	
	# Update slide physics
	update_slide_physics(delta)
	
	# Check for slide exit conditions
	check_slide_exit()

func update_slide_physics(delta: float) -> void:
	var player = Global.player
	
	# Apply slide friction
	slide_velocity *= SLIDE_FRICTION
	
	# Get input direction for slight steering
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var input_vec3 = Vector3(input_dir.x, 0, input_dir.y)
	
	# Allow slight steering while sliding
	var steer_influence = 0.2
	slide_velocity = slide_velocity.lerp(
		slide_velocity + input_vec3 * SPEED * steer_influence,
		delta * ACCELERATION
	)
	
	# Update player velocity
	player.velocity = slide_velocity
	player.update_velocity()
	
	# Update animation tilt based on current rotation
	set_tilt(player._current_rotation)

func set_tilt(player_rotation: float) -> void:
	if not ANIMATION or not ANIMATION.has_animation("sliding"):
		return
		
	var tilt = Vector3.ZERO
	tilt.z = clamp(TILT_AMOUNT * player_rotation, -0.1, 0.1)
	
	# Ensure minimum tilt
	if tilt.z == 0.0:
		tilt.z = 0.05
		
	# Update animation tilt keyframes
	var animation = ANIMATION.get_animation("sliding")
	animation.track_set_key_value(0, 0, tilt)  # Track index, key index, value
	animation.track_set_key_value(0, 1, tilt)  # Track index, key index, value

func check_slide_exit() -> void:
	var player = Global.player
	
	# Exit conditions for sliding
	if not Input.is_action_pressed("crouch"):
		if CROUCH_SHAPECAST and not CROUCH_SHAPECAST.is_colliding():
			finish()
	
	# Exit if speed is too low
	if slide_velocity.length() < MIN_SLIDE_SPEED:
		finish()
	
	# Exit if hitting a wall or steep slope
	if player.is_on_wall():
		finish()

func finish() -> void:
	# Clean up any slide-specific states
	if ANIMATION and ANIMATION.is_playing():
		ANIMATION.stop()
	
	# Reset collision shape if needed
	reset_collision_shape()
	
	# Transition to crouching state
	transition.emit("CrouchingPlayerState")

func adjust_collision_shape() -> void:
	# Adjust collision shape for sliding if needed
	# This would be similar to crouching but potentially even lower
	pass

func reset_collision_shape() -> void:
	# Reset collision shape to normal state
	pass

func exit() -> void:
	# Clean up any remaining slide states
	if ANIMATION and ANIMATION.is_playing():
		ANIMATION.stop()
	
	reset_collision_shape()
