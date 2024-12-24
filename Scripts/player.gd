extends CharacterBody3D

@export var SPEED : float = 10.0
@export var JUMP_VELOCITY : float = 5
@export var MOUSE_SENSITIVITY : float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER : Camera3D
@export var animation_player: AnimationPlayer
@export var CROUCH_SHAPECAST: Node
@export_range(0.1, 1.0, 0.1) var CROUCH_SPEED_MULTIPLIER: float = 0.5  # Multiplier for crouch speed

var _mouse_input : bool = false
var _rotation_input : float
var _tilt_input : float
var _mouse_rotation : Vector3
var _player_rotation : Vector3
var _camera_rotation : Vector3
var _is_crouching : bool = false
var _speed : float
const SPEED_DEFAULT : float = 10.0  # Assigned a fixed constant value

# Get the gravity from the project settings to be synced with RigidBody nodes.
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
	# Rotates camera using euler rotation
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
	# Get mouse input
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_speed = SPEED  # Initialize _speed from the exported variable
	CROUCH_SHAPECAST.add_exception($".")

func _physics_process(delta):
	Global.debug.add_property("MovementSpeed", _speed, 1)

	# Update camera movement based on mouse movement
	_update_camera(delta)

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not _is_crouching:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
	else:
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)

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
