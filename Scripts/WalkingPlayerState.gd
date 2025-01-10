class_name WalkingPlayerState
extends State

@export var ANIMATION: AnimationPlayer
@export var TOP_ANIM_SPEED: float = 2.2

func enter() -> void:
	# Start camera bob when entering walking state
	if Global.player:
		Global.player.toggle_camera_bob(true)
		Global.player._speed = Global.player.SPEED_DEFAULT
		# Play walking animation
		if ANIMATION:
			ANIMATION.play("walking")

func exit() -> void:
	# Stop camera bob when exiting walking state
	if Global.player:
		Global.player.toggle_camera_bob(false)
		# Stop walking animation
		if ANIMATION:
			ANIMATION.stop()

func update(delta: float) -> void:
	var player = Global.player
	# Check for both stopping movement and lack of input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() == 0 and player.velocity.length_squared() <= 0.01:
		transition.emit("IdlePlayerState")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("sprint") and Global.player.is_on_floor():
		transition.emit("SprintingPlayerState")
	elif event.is_action_pressed("crouch"):
		transition.emit("CrouchingPlayerState")
