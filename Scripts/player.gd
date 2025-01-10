extends CharacterBody3D

@export var SPEED : float = 10.0
@export var SPEED_SPRINTING : float = 7.0
@export var JUMP_VELOCITY : float = 5
@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var ACCELERATION: float = 0.1
@export var DECELERATION: float = 0.25
@export var CAMERA_CONTROLLER: Camera3D
@export var animation_player: AnimationPlayer
@export var CROUCH_SHAPECAST: Node
@export var state_machine: StateMachine
@export_range(0.1, 1.0, 0.1) var CROUCH_SPEED_MULTIPLIER: float = 0.5
@export var ENABLE_CAMERA_BOB: bool = true

var _mouse_input: bool = false
var _rotation_input: float
var _tilt_input: float
var _mouse_rotation: Vector3
var _player_rotation: Vector3
var _camera_rotation: Vector3
var _is_crouching: bool = false
var _speed: float
const SPEED_DEFAULT: float = 10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _unhandled_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()

	if event.is_action_pressed("crouch") and is_on_floor():
		toggle_crouch()

func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta

	_player_rotation = Vector3(0.0, _mouse_rotation.y, 0.0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0.0, 0.0)

	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)

	CAMERA_CONTROLLER.rotation.z = 0.0

	_rotation_input = 0.0
	_tilt_input = 0.0

func _ready():
	Global.player = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_speed = SPEED
	CROUCH_SHAPECAST.add_exception(self)

func _physics_process(delta):
	if Global.debug:
		Global.debug.add_property("MovementSpeed", "%.2f" % _speed, 1)
		Global.debug.add_property("Velocity", "%.2f" % velocity.length(), 2)
		Global.debug.add_property("Position", "(%.1f, %.1f, %.1f)" % [position.x, position.y, position.z], 3)
		Global.debug.add_property("Is Crouching", str(_is_crouching), 4)
		Global.debug.add_property("On Floor", str(is_on_floor()), 5)
		
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var input_state = "None" if input_dir.length() == 0 else "Moving"
		Global.debug.add_property("Input State", input_state, 6)

	_update_camera(delta)

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor() and not _is_crouching:
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = lerp(velocity.x, direction.x * _speed, ACCELERATION)
		velocity.z = lerp(velocity.z, direction.z * _speed, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
		velocity.z = move_toward(velocity.z, 0, DECELERATION)

	move_and_slide()

func toggle_crouch():
	if _is_crouching and CROUCH_SHAPECAST.is_colliding() == false:
		print("Uncrouch")
		animation_player.play("crouch", -1, -(_speed * CROUCH_SPEED_MULTIPLIER), true)
		_speed = SPEED
	elif not _is_crouching:
		print("Crouch")
		animation_player.play("crouch", -1, _speed * CROUCH_SPEED_MULTIPLIER)
		_speed = SPEED * CROUCH_SPEED_MULTIPLIER
	_is_crouching = !_is_crouching


# Add this method to control camera bob animation
func toggle_camera_bob(enable: bool) -> void:
	if ENABLE_CAMERA_BOB and animation_player.has_animation("camera_bob") and not _is_crouching:  # Check for not crouching
		if enable and not animation_player.is_playing():
			animation_player.play("camera_bob")
		elif not enable:
			animation_player.stop()
			# Reset camera position to default
			if CAMERA_CONTROLLER:
				CAMERA_CONTROLLER.position = CAMERA_CONTROLLER.position.lerp(Vector3.ZERO, 0.1)
	elif _is_crouching and animation_player.is_playing():  # Stop animation if player starts crouching
		animation_player.stop()
		if CAMERA_CONTROLLER:
			CAMERA_CONTROLLER.position = CAMERA_CONTROLLER.position.lerp(Vector3.ZERO, 0.1)
