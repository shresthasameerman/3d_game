extends Node3D

@export var weapon_resource: WeaponResource
@export var animation_player_path: NodePath

var can_attack: bool = true
var is_attacking: bool = false
var anim_player: AnimationPlayer

func _ready():
	if not weapon_resource:
		weapon_resource = WeaponResource.new()
	
	# Try to get the AnimationPlayer node using the exported path
	if animation_player_path:
		anim_player = get_node(animation_player_path) as AnimationPlayer
	
	# Fallback: search for AnimationPlayer in the parent hierarchy
	if not anim_player:
		var parent = get_parent()
		while parent:
			if parent is AnimationPlayer:
				anim_player = parent
				break
			parent = parent.get_parent()
	
	if not anim_player:
		push_error("AnimationPlayer not found for weapon")

func _process(_delta):
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()

func attack():
	if is_attacking:
		return
	
	is_attacking = true
	can_attack = false
	
	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")
	else:
		push_warning("Animation 'attack' not found")
	
	check_hit()
	
	var timer = get_tree().create_timer(weapon_resource.swing_speed)
	timer.connect("timeout", _on_attack_cooldown_timeout)

func _on_attack_cooldown_timeout():
	is_attacking = false
	can_attack = true

func check_hit():
	var shape_cast = get_node_or_null("../../ShapeCast3D")
	if shape_cast:
		shape_cast.force_shapecast_update()
		if shape_cast.is_colliding():
			var collider = shape_cast.get_collider(0)
			if collider and collider.has_method("take_damage"):
				collider.take_damage(weapon_resource.damage)
	else:
		push_warning("ShapeCast3D not found for weapon hit detection")
