extends State
class_name IdlePlayerState

@export var animation_player: AnimationPlayer

# Optional - for debug purposes
@export var debug_mode: bool = false

func _ready() -> void:
	# Verify animation player is set up correctly on ready
	if debug_mode:
		if animation_player:
			print("AnimationPlayer found with animations: ", animation_player.get_animation_list())
		else:
			push_warning("AnimationPlayer not assigned to IdlePlayerState!")

func enter() -> void:
	if debug_mode:
		print("Entering Idle State")
	
	if animation_player:
		if animation_player.has_animation("idle"):
			animation_player.play("idle")
		elif animation_player.has_animation("IDLE"):
			animation_player.play("IDLE")
		else:
			push_warning("No idle animation found in AnimationPlayer!")
			print("Available animations: ", animation_player.get_animation_list())

func exit() -> void:
	if debug_mode:
		print("Exiting Idle State")
	
	if animation_player and animation_player.is_playing():
		animation_player.stop()

func update(delta: float) -> void:
	var player = Global.player
	if not player:
		return
		
	# Check for movement input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Transition to walking state if there's input and actual movement
	if input_dir.length() > 0 and player.velocity.length_squared() > 0.01:
		transition.emit("WalkingPlayerState")
		
	# Optional - handle falling if player walks off edge
	if not player.is_on_floor():
		transition.emit("FallingPlayerState")

func handle_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
		
	if event.is_action_pressed("crouch"):
		transition.emit("CrouchingPlayerState")
	elif event.is_action_pressed("jump") and Global.player.is_on_floor():
		transition.emit("JumpingPlayerState")

# Optional - physics update if needed
func physics_update(delta: float) -> void:
	pass

# Optional - Add a method to force idle animation replay
func replay_idle_animation() -> void:
	if animation_player and animation_player.has_animation("idle"):
		animation_player.stop()
		animation_player.play("idle")
