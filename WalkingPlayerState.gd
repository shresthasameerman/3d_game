class_name WalkingPlayerState
extends State

func enter() -> void:
	# Start camera bob when entering walking state
	if Global.player:
		Global.player.toggle_camera_bob(true)

func exit() -> void:
	# Stop camera bob when exiting walking state
	if Global.player:
		Global.player.toggle_camera_bob(false)

func update(delta: float) -> void:
	var player = Global.player
	# Check for both stopping movement and lack of input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() == 0 and player.velocity.length_squared() <= 0.01:
		transition.emit("IdlePlayerState")
