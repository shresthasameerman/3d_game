class_name IdlePlayerState
extends State

func enter() -> void:
	print("Entered Idle state")

func update(delta: float) -> void:
	if Global.player.velocity.length() > 0.0:
		print("Transitioning from Idle to Walking")
		emit_signal("transition", "WalkingPlayerState")

func exit() -> void:
	print("Exiting Idle state")
