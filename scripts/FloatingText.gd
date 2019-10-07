extends Node2D

const Globals = preload("res://scripts/Globals.gd")

var label: Label
var existed_for: float

func start(text: String, color = null):
	self.label = $Label
	self.label.text = text
	self.existed_for = 0.0
	if color:
		self.label.add_color_override("font_color", color)


func _process(delta: float) -> void:
	if existed_for < Globals.FLOATING_TEXT_SCROLL_TIME:
		self.label.rect_position.y -= Globals.FLOATING_TEXT_SCROLL_SPEED * delta
		existed_for += delta
	else:
		self.queue_free()
