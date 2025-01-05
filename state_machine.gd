class_name StateMachine
extends Node

@export var CURRENT_STATE: State
var states: Dictionary = {}
var machine_name: String
var previous_state: String = ""

func _ready():
	machine_name = name
	
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.transition.connect(on_child_transition)
		else:
			push_warning("State Machine contains incompatible child node")
	CURRENT_STATE.enter()
	previous_state = CURRENT_STATE.name

func _process(delta):
	CURRENT_STATE.update(delta)
	if Global.debug and Global.debug.visible:
		var state_info = "Current: %s" % [CURRENT_STATE.name]
		Global.debug.add_property(machine_name, state_info, 1)

func _physics_process(delta):
	CURRENT_STATE._physics_update(delta)
	
func on_child_transition(new_state_name: StringName) -> void:
	var new_state = states.get(new_state_name)
	if new_state != null:
		if new_state != CURRENT_STATE:
			CURRENT_STATE.exit()
			new_state.enter()
			CURRENT_STATE = new_state
			
			if Global.debug and Global.debug.visible:
				Global.debug.add_property(machine_name, CURRENT_STATE.name, 1)
				previous_state = CURRENT_STATE.name
	else:
		push_warning("State doesnt exist")
