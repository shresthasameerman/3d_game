extends Node3D

enum {
	IDLE,
	ALERT,
	STUNNED
}
var state = IDLE
@onready var raycast = $RayCast
@onready var ap = $dummymale/AnimationPlayer

var stun_timer = 0.0
const STUN_DURATION = 2.0  # Adjust this to match your stunned animation length

func _ready():
	pass
	
func _process(delta: float):
	# Handle stun timer if we're in stunned state
	if state == STUNNED:
		stun_timer -= delta
		if stun_timer <= 0:
			state = IDLE
		return  # Skip other state checks while stunned
	
	# Normal state checks
	if raycast.is_colliding():
		state = ALERT
	elif Input.is_action_just_pressed("fire"):
		state = STUNNED
		stun_timer = STUN_DURATION
		ap.play("Stunned")  # Force play the stunned animation
		return  # Skip other state checks this frame
	else:
		state = IDLE
	
	# Only play animations if not stunned
	if state != STUNNED:
		match state:
			IDLE:
				if not ap.current_animation == "Idle":
					ap.play("Idle")
			ALERT:
				if not ap.current_animation == "Alert":
					ap.play("Alert")
