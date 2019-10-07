extends Node2D

const Globals = preload("res://scripts/Globals.gd")

var label: Label
var existed_for: float
var speed: float

func start(text: String, color = null, speed: float = 1.0):
	self.label = $Label
	self.label.text = text
	self.existed_for = 0.0
	self.speed = speed
	if color:
		self.label.add_color_override("font_color", color)


func _process(delta: float) -> void:
	if existed_for < Globals.FLOATING_TEXT_SCROLL_TIME:
		self.label.rect_position.y -= Globals.FLOATING_TEXT_SCROLL_SPEED * delta * self.speed
		existed_for += delta
	else:
		self.queue_free()
