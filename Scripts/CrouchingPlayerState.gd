class_name CrouchingPlayerState
extends State

@export var ANIMATION: AnimationPlayer
@export var CROUCH_SPEED: float = 3.0  # Slower movement while crouching
@export var CROUCH_HEIGHT: float = 1.0  # Height when crouched (will be multiplied by original height)
@export var TRANSITION_SPEED: float = 10.0  # Speed of crouch animation

var original_height: float
var original_y_position: float
var collision_shape: CollisionShape3D

func enter() -> void:
	# Store reference to player and collision shape
	var player = Global.player
	collision_shape = player.get_node("CollisionShape3D")  # Adjust path if needed
	
	# Store original properties
	original_height = collision_shape.shape.height
	original_y_position = collision_shape.position.y
	
	# Set crouch speed
	player._speed = CROUCH_SPEED
	
	# Start crouch animation if it exists
	if ANIMATION and ANIMATION.has_animation("crouch"):
		ANIMATION.play("crouch")
	
	# Adjust collision shape for crouching
	var target_height = original_height * CROUCH_HEIGHT
	collision_shape.shape.height = target_height
	collision_shape.position.y = original_y_position - (original_height - target_height) / 2

func exit() -> void:
	# Restore original collision shape
	collision_shape.shape.height = original_height
	collision_shape.position.y = original_y_position
	
	# Stop crouch animation
	if ANIMATION and ANIMATION.is_playing():
		ANIMATION.stop()
	
	# Reset player speed to default
	Global.player._speed = Global.player.SPEED_DEFAULT

func update(delta: float) -> void:
	var player = Global.player
	
	# Check for movement input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Perform raycast check above player to ensure they can stand up
	var can_stand = check_can_stand()
	
	# If crouch key is released and there's space to stand
	if not Input.is_action_pressed("crouch") and can_stand:
		# Transition to appropriate state based on movement and sprint input
		if Input.is_action_pressed("sprint") and input_dir.length() > 0:
			transition.emit("SprintingPlayerState")
		elif input_dir.length() > 0:
			transition.emit("WalkingPlayerState")
		else:
			transition.emit("IdlePlayerState")

func _input(event: InputEvent) -> void:
	# Handle any specific input events while crouching
	pass

func check_can_stand() -> bool:
	# Create a raycast to check if there's enough space to stand up
	var space_state = Global.player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	
	# Get the current position and calculate the end position
	var start_pos = Global.player.global_position
	var end_pos = start_pos + Vector3(0, original_height, 0)
	
	query.from = start_pos
	query.to = end_pos
	query.exclude = [Global.player]
	
	var result = space_state.intersect_ray(query)
	
	# Return true if no collision (can stand up)
	return result.is_empty()
