extends PanelContainer

@onready var v_box_container: VBoxContainer = %VBoxContainer

var frames_per_second: String

func _ready():
	Global.debug = self
	visible = false
	print("Debug panel ready")

func _process(delta):
	if visible:
		frames_per_second = "%.2f" % (1.0 / delta)
		add_property("FPS", frames_per_second, 0)

func _input(event):
	if event.is_action_pressed("Debug"):
		visible = !visible
		print("Debug panel visibility toggled: %s" % visible)

func add_property(title: String, value, order: int):
	var target = v_box_container.find_child(title, true, false)
	if !target:
		target = Label.new()
		v_box_container.add_child(target)
		target.name = title
		print("Added new property: %s" % title)
	target.text = title + ": " + str(value)
	v_box_container.move_child(target, order)
