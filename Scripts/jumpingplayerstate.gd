class_name JumpingPlayerState
extends State

@export var JUMP_SPEED: float = 10.0
@export var DOUBLE_JUMP_SPEED: float = 8.0

var has_double_jumped: bool = false

func enter() -> void:
	# Apply an upward force to make the player Jump
	Global.player.velocity.y = JUMP_SPEED
	print("Player is jumping")

func exit() -> void:
	# Reset the double Jump state when exiting
	has_double_jumped = false

func update(_delta: float) -> void:
	# Check if the player has landed
	if Global.player.is_on_floor():
		# Transition to IdlePlayerState
		transition.emit("IdlePlayerState")
	
	# Check for transition to sprinting or crouching states
	check_for_transition()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("crouch"):
		transition.emit("CrouchingPlayerState")
	elif event.is_action_pressed("sprint") and Global.player.is_on_floor():
		transition.emit("SprintingPlayerState")
	elif event.is_action_pressed("Jump") and not Global.player.is_on_floor() and not has_double_jumped:
		# Perform double Jump
		Global.player.velocity.y = DOUBLE_JUMP_SPEED
		has_double_jumped = true
		print("Player performed double Jump")

func check_for_transition() -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# Transition to WalkingPlayerState if there is input and player is on the floor
	if input_dir.length() > 0 and Global.player.is_on_floor():
		transition.emit("WalkingPlayerState")
