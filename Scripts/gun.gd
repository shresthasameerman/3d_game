extends Node3D

# Recoil curves
@export var recoil_rotation_x : Curve  # Vertical recoil
@export var recoil_rotation_z : Curve  # Horizontal recoil
@export var recoil_position_z : Curve  # Backward push

# Recoil settings
@export var recoil_amplitude := Vector3(1.0, 1.0, 1.0)  # Strength multipliers
@export var recoil_randomness := Vector3(0.2, 0.2, 0.1) # Random variation per axis
@export var return_speed := 5.0  # How fast the weapon returns to center
@export var recoil_speed := 15.0 # How fast the recoil applies
@export var max_recoil := Vector3(20.0, 15.0, 0.5) # Maximum recoil per axis
@export var recoil_recovery_delay: float = 0.1  # Delay before returning

# Internal variables
var initial_rotation: Vector3
var initial_position: Vector3
var target_rot: Vector3
var target_pos: Vector3
var current_time: float = 1.0
var is_recoiling: bool = false
var recovery_timer: float = 0.0
var raycast_bullet = preload("res://scenes/raycast_test.tscn") 

func _ready():
	# Store the very first transform as true initial position
	initial_rotation = rotation
	initial_position = position
	
	reset_targets()
	
	# Initialize default curves if they're null
	if not recoil_rotation_x:
		recoil_rotation_x = Curve.new()
		recoil_rotation_x.add_point(Vector2(0, 0))
		recoil_rotation_x.add_point(Vector2(0.1, 1))
		recoil_rotation_x.add_point(Vector2(1, 0), 0, -1)  # Smooth falloff
	
	if not recoil_rotation_z:
		recoil_rotation_z = Curve.new()
		recoil_rotation_z.add_point(Vector2(0, 0))
		recoil_rotation_z.add_point(Vector2(0.2, 1))
		recoil_rotation_z.add_point(Vector2(1, 0))
	
	if not recoil_position_z:
		recoil_position_z = Curve.new()
		recoil_position_z.add_point(Vector2(0, 0))
		recoil_position_z.add_point(Vector2(0.05, 1))
		recoil_position_z.add_point(Vector2(0.3, 0))
		recoil_position_z.add_point(Vector2(1, 0))

func reset_targets():
	target_rot = initial_rotation
	target_pos = initial_position
	current_time = 1.0
	is_recoiling = false
	recovery_timer = 0.0

func _physics_process(delta: float):
	if Input.is_action_just_pressed("fire"):
		apply_recoil()
		_attack()
	
	if is_recoiling:
		if current_time < 1.0:
			# Apply recoil movement
			current_time += delta * (1.0 / recoil_speed)
			
			# Calculate recoil values from curves
			var recoil_x = recoil_rotation_x.sample(current_time) * -recoil_amplitude.x
			var recoil_z = recoil_rotation_z.sample(current_time) * recoil_amplitude.y
			var recoil_pos_z = recoil_position_z.sample(current_time) * recoil_amplitude.z
			
			# Update targets with clamping
			target_rot.x = clamp(initial_rotation.x + recoil_x, -max_recoil.x, max_recoil.x)
			target_rot.z = clamp(initial_rotation.z + recoil_z, -max_recoil.y, max_recoil.y)
			target_pos.z = clamp(initial_position.z + recoil_pos_z, -max_recoil.z, max_recoil.z)
			
			# Smooth interpolation
			rotation = rotation.lerp(target_rot, delta * recoil_speed)
			position = position.lerp(target_pos, delta * recoil_speed)
		else:
			# Start recovery after delay
			recovery_timer += delta
			if recovery_timer >= recoil_recovery_delay:
				# Return to original position
				rotation = rotation.lerp(initial_rotation, delta * return_speed)
				position = position.lerp(initial_position, delta * return_speed)
				
				# Reset once fully recovered
				if rotation.distance_to(initial_rotation) < 0.01 and position.distance_to(initial_position) < 0.01:
					reset_targets()

func apply_recoil():
	current_time = 0.0
	is_recoiling = true
	recovery_timer = 0.0
	
	# Apply random variation to recoil
	var current_amplitude = recoil_amplitude
	current_amplitude.x *= 1.0 + (randf() * 2.0 - 1.0) * recoil_randomness.x
	current_amplitude.y *= 1.0 + (randf() * 2.0 - 1.0) * recoil_randomness.y
	current_amplitude.z *= 1.0 + (randf() * 2.0 - 1.0) * recoil_randomness.z
	
	# Randomize horizontal recoil direction
	current_amplitude.y *= -1 if randf() > 0.5 else 1
func _attack() -> void:
	var camera = Global.player.CAMERA_CONTROLLER
	var space_state = camera.get_world_3d().direct_space_state
	var screen_center = get_viewport().size/2
	var origin = camera.project_ray_origin(screen_center)
	var end = origin + camera.project_ray_normal(screen_center) * 1000
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	if result:
		_test_raycast(result.get("position"))
	
func _test_raycast(position: Vector3) -> void:
	var instance = raycast_bullet.instantiate()
	get_tree().root.add_child(instance)
	instance.global_position = position
	await get_tree().create_timer(3).timeout
	instance.queue_free()
