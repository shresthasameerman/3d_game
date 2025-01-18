class_name SprintingPlayerState
extends State

@export var ANIMATION: AnimationPlayer
@export var SPRINT_SPEED: float = 15.0

func enter() -> void:
	# Start the sprinting animation if it exists
	if ANIMATION and ANIMATION.has_animation("sprint"):
		print("Playing sprinting animation")
		ANIMATION.play("sprint")
	else:
		print("AnimationPlayer or sprinting animation not found")
	# Set the player's speed to sprinting speed
	Global.player._speed = SPRINT_SPEED

func exit() -> void:
	# Stop the sprinting animation if it is playing
	if ANIMATION and ANIMATION.is_playing():
		print("Stopping sprinting animation")
		ANIMATION.stop()

func update(delta: float) -> void:
	# Check for transition back to walking or idle state
	check_for_transition()

func _input(event: InputEvent) -> void:
	# Transition to WalkingPlayerState if sprint key is released
	if event.is_action_released("sprint"):
		transition.emit("WalkingPlayerState")
	elif event.is_action_pressed("crouch"):
		transition.emit("CrouchingPlayerState")
	elif event.is_action_pressed("Jump") and Global.player.is_on_floor():
		transition.emit("JumpingPlayerState")

func check_for_transition() -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# Transition to WalkingPlayerState if no input or player is not on the floor
	if input_dir.length() == 0 or not Global.player.is_on_floor():
		transition.emit("WalkingPlayerState")
