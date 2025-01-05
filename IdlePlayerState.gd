class_name IdlePlayerState
extends State

func update(delta: float) -> void:
	var player = Global.player
	# Check for actual movement and input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() > 0 and player.velocity.length_squared() > 0.01:
		transition.emit("WalkingPlayerState")
