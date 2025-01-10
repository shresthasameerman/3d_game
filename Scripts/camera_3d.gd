extends Camera3D

@export var bob_frequency: float = 2.0  # How fast the camera bobs
@export var bob_amplitude: float = 0.08  # How much the camera moves up/down
@export var sway_amount: float = 0.1    # How much the camera tilts side to side
@export_range(0, 1) var smoothness: float = 0.9  # Higher = smoother movement

var time: float = 0.0
var initial_position: Vector3
var initial_rotation: Vector3
var is_walking: bool = false
var velocity: Vector3 = Vector3.ZERO

func _ready():
	initial_position = position
	initial_rotation = rotation_degrees

func _process(delta: float):
	# Only shake if we're walking
	if is_walking and velocity.length() > 0.1:
		time += delta * bob_frequency * (velocity.length() / 5.0)
		
		# Calculate vertical bob
		var bob = sin(time) * bob_amplitude
		
		# Calculate side-to-side sway
		var sway = cos(time * 2) * sway_amount
		
		# Apply smoothing using lerp
		position = position.lerp(initial_position + Vector3(0, bob, 0), 1 - smoothness)
		rotation_degrees = rotation_degrees.lerp(initial_rotation + Vector3(0, 0, sway), 1 - smoothness)
	else:
		# Return to initial position when not walking
		position = position.lerp(initial_position, 1 - smoothness)
		rotation_degrees = rotation_degrees.lerp(initial_rotation, 1 - smoothness)

# Call this from your character controller when movement state changes
func set_walking(walking: bool, current_velocity: Vector3):
	is_walking = walking
	velocity = current_velocity
