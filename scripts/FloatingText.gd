extends Node2D

const Globals = preload("res://scripts/Globals.gd")

var label: Label
var fun  # coroutine state

func start(text: String, initial_delay: float = 0.0, color = null):
	self.label = $Label
	self.label.text = text
	if color:
		self.label.add_color_override("font_color", color)

	fun = coroutine(initial_delay)


func _process(delta: float) -> void:
	if fun:
		fun = fun.resume(delta)


func coroutine(delay: float):
	if delay > 0.0:
		self.hide()
	var t = 0.0
	while t < delay:
		t += yield()

	self.show()

	t = 0.0
	var delta: float
	while t < Globals.FLOATING_TEXT_SCROLL_TIME:
		delta = yield()
		self.label.rect_position.y -= Globals.FLOATING_TEXT_SCROLL_SPEED * delta
		t += delta

	self.fun = null
	self.hide()
	self.queue_free()
