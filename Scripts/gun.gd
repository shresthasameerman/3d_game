extends Node3D

signal weapon_fired

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

# Debug options
@export var debug_draw := false  # Enable to draw debug lines
@export var raycast_distance := 1000.0  # How far the raycast goes
@export var interact_distance := 1000.0  # How far the interaction raycast goes

# Internal variables
var initial_rotation: Vector3
var initial_position: Vector3
var target_rot: Vector3
var target_pos: Vector3
var current_time: float = 1.0
var is_recoiling: bool = false
var recovery_timer: float = 0.0
var raycast_bullet = preload("res://scenes/raycast_test.tscn")
var interact_cast_result = null

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
		_attack()
		apply_recoil()
		
	if Input.is_action_just_pressed("interact"):
		interact()
	
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

# Simple function to draw a debug line in 3D space
func draw_debug_line(start_pos: Vector3, end_pos: Vector3, color: Color = Color.RED, duration: float = 1.0):
	if Engine.is_editor_hint():
		return
		
	# Draw line using immediate geometry
	var im = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.flag_unshaded = true
	material.flag_no_depth_test = true
	
	var mi = MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = material
	get_tree().root.add_child(mi)
	
	im.clear()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(start_pos)
	im.surface_add_vertex(end_pos)
	im.surface_end()
	
	# Auto remove after duration
	await get_tree().create_timer(duration).timeout
	mi.queue_free()

func _attack() -> void:
	weapon_fired.emit()

	
	# Get the camera controller
	var camera = Global.player.CAMERA_CONTROLLER
	
	# Always fire from camera center (where reticle is)
	var screen_center = get_viewport().size / 2
	var origin = camera.project_ray_origin(screen_center)
	var direction = camera.project_ray_normal(screen_center)
	var end = origin + direction * raycast_distance
	
	# Debug visualization
	if debug_draw:
		draw_debug_line(origin, end, Color.RED, 2.0)

	

	
	# Set up raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	# Perform raycast
	var result = space_state.intersect_ray(query)
	
	if result and result.size() > 0:
		_bullet_hole(result.get("position"), result.get("normal"))
	
func _bullet_hole(position: Vector3, normal: Vector3) -> void:
	var instance = raycast_bullet.instantiate()
	if not is_instance_valid(instance):
		return
		
	get_tree().root.add_child(instance)
	instance.global_position = position
	
	# Ensure proper orientation
	instance.look_at(instance.global_transform.origin + normal, Vector3.UP)
	if normal != Vector3.UP and normal != Vector3.DOWN:
		instance.rotate_object_local(Vector3(1,0,0), 90)
	
	# Make sure the decal is visible
	if instance is Node3D:
		# Force visibility and scale
		if instance.has_method("set_visible"):
			instance.set_visible(true)
		
		# For debugging, ensure it's big enough to see
		instance.scale = Vector3(1, 1, 1)  # Adjust size if needed
	
	# Set up cleanup
	await get_tree().create_timer(2).timeout
	var fade = get_tree().create_tween()
	fade.tween_property(instance, "modulate:a", 0, 1.5)
	await get_tree().create_timer(1.5).timeout
	instance.queue_free()

# Function to cast a ray for interaction
func interact_cast() -> void:
	var camera = Global.player.CAMERA_CONTROLLER
	var space_state = camera.get_world_3d().direct_space_state
	var screen_center = get_viewport().size / 2
	var origin = camera.project_ray_origin(screen_center)
	var end = origin + camera.project_ray_normal(screen_center) * interact_distance
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	var current_cast_result = result.get("collider")
	interact_cast_result = current_cast_result

# Function to handle interaction
func interact() -> void:
	interact_cast()
	if interact_cast_result and interact_cast_result.has_user_signal("interacted"):
		interact_cast_result.emit_signal("interacted")
