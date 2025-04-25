extends CharacterBody3D

enum STATE {IDLE, CHASING, ATTACKING, DEAD}
var current_state = STATE.IDLE

@export var speed = 3.5
@export var attack_damage = 20
@export var attack_cooldown = 1.5
@export var health = 100

var target = null
var can_attack = true

@onready var nav_agent = $NavigationAgent3D
@onready var animation_player = $AnimationPlayer
@onready var attack_area = $AttackArea
@onready var detection_area = $DetectionArea

func _ready():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	attack_area.body_entered.connect(_on_attack_area_entered)

func _physics_process(delta):
	match current_state:
		STATE.CHASING:
			chase_player(delta)
		STATE.ATTACKING:
			face_target(delta)
	
	move_and_slide()

func chase_player(delta):
	if target:
		nav_agent.target_position = target.global_position
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = (next_path_pos - global_position).normalized()
		velocity = velocity.lerp(direction * speed, delta * 5)
		
		# Play walk animation
		animation_player.play("walk")

func face_target(delta):
	if target:
		var target_pos = target.global_position
		look_at(Vector3(target_pos.x, global_position.y, target_pos.z), Vector3.UP)

func attack():
	if can_attack and target:
		animation_player.play("attack")
		# Damage logic handled in animation event
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

func take_damage(damage):
	health -= damage
	if health <= 0:
		die()
	else:
		animation_player.play("hit")

func die():
	current_state = STATE.DEAD
	animation_player.play("die")
	set_physics_process(false)
	await animation_player.animation_finished
	queue_free()

# Signal callbacks
func _on_player_detected(body):
	if body.is_in_group("player"):
		target = body
		current_state = STATE.CHASING

func _on_player_lost(body):
	if body == target:
		target = null
		current_state = STATE.IDLE
		animation_player.play("idle")

func _on_attack_area_entered(body):
	if body.is_in_group("player") and current_state != STATE.DEAD:
		current_state = STATE.ATTACKING
		attack()
