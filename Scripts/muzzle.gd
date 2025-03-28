extends Node3D

@export var weapon: Node3D 
@export var flash_time: float = 0.05

@export var light: OmniLight3D 
@export var emitter: GPUParticles3D

func _add_muzzle_flash() -> void:
	light.visible = true
	emitter.emitting = true
	await get_tree().create_timer(flash_time).timeout
	light.visible = false
	
