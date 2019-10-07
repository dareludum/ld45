extends Node


var is_smooth = false

var jerky: Sprite
var smooth: Sprite

signal smoothness_changed

func _ready() -> void:
	var parent = get_parent()
	jerky = parent.get_node("Jerky")
	smooth = parent.get_node("Smooth")
	parent.connect("click", self, "toggle")


func toggle() -> void:
	is_smooth = not is_smooth
	if is_smooth:
		smooth.show()
		jerky.hide()
	else:
		smooth.hide()
		jerky.show()
	emit_signal("smoothness_changed", is_smooth)
