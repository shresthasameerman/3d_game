extends Node3D

@export var gun: Node3D 
@export var flash_time: float = 0.05
@export var light: OmniLight3D 
@export var emitter: GPUParticles3D

# Debug control - set to false in production
@export var debug_mode: bool = true

func _ready() -> void:
	if debug_mode:
		_debug_print("Muzzle script ready")
		_debug_print("Gun reference: %s" % gun)
		_debug_print("Light reference: %s" % light)
		_debug_print("Emitter reference: %s" % emitter)
	
	# Null check before connecting
	if gun and gun.has_signal("weapon_fired"):
		gun.weapon_fired.connect(_add_muzzle_flash)
		if debug_mode:
			_debug_print("Signal connected successfully")
	elif debug_mode:
		push_error("Failed to connect signal - check gun reference")

func _add_muzzle_flash() -> void:
	if debug_mode:
		_debug_print("Muzzle flash triggered")
	
	# Null checks before modifying
	if light:
		light.visible = true
	else:
		push_error("Light reference is null")
	
	if emitter:
		emitter.emitting = true
	else:
		push_error("Emitter reference is null")
	
	await get_tree().create_timer(flash_time).timeout
	
	if light:
		light.visible = false
	
	if emitter:
		emitter.emitting = false

# Helper function for controlled debug output
func _debug_print(message: String) -> void:
	if debug_mode:
		print("[MuzzleFlash] ", message)
