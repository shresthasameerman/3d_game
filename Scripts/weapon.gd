extends Node3D

@export var weapon_resource: WeaponResource
var can_attack: bool = true
var is_attacking: bool = false

# Reference to the AnimationPlayer
@onready var anim_player: AnimationPlayer = get_node("../../AnimationPlayer")

func _ready():
	if !weapon_resource:
		weapon_resource = WeaponResource.new()

func _process(_delta):
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()

func attack():
	if is_attacking:
		return
		
	is_attacking = true
	can_attack = false
	
	# Play attack animation
	if anim_player and anim_player.has_animation("axe_swing"):
		anim_player.play("axe_swing")
	
	# Create attack hitbox
	check_hit()
	
	# Add attack cooldown
	await get_tree().create_timer(weapon_resource.swing_speed).timeout
	
	is_attacking = false
	can_attack = true

func check_hit():
	# Use ShapeCast3D to detect hits
	var shape_cast = get_node("../../ShapeCast3D")
	if shape_cast:
		shape_cast.force_shapecast_update()
		if shape_cast.is_colliding():
			var collider = shape_cast.get_collider(0)
			if collider.has_method("take_damage"):
				collider.take_damage(weapon_resource.damage)
