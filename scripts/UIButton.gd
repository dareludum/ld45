extends ColorRect

var mouse_pressed_on_button = false

signal click
signal mouse_enter # NOT mouse_entered
signal mouse_leave # NOT mouse_exited

export var key_hint: String = "" setget set_key_hint, get_key_hint
export var text_hint: String = ""

var is_mouse_inside: bool = false


func set_key_hint(value):
	$KeyHint/TextKeyHint.text = value


func get_key_hint():
	return $KeyHint/TextKeyHint.text


func _input(event):
	if event is InputEventMouseMotion:
		if not mouse_pressed_on_button:
			if self.get_global_rect().has_point(event.position):
				$BackgroundHover.visible = true
				if not is_mouse_inside:
					is_mouse_inside = true
					emit_signal("mouse_enter", self)
			else:
				$BackgroundHover.visible = false
				if is_mouse_inside:
					is_mouse_inside = false
					emit_signal("mouse_leave", self)
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.is_pressed():
			if self.get_global_rect().has_point(event.position):
				mouse_pressed_on_button = true
				$BackgroundHover.visible = false
		elif event.button_index == BUTTON_LEFT and not event.is_pressed():
			if self.get_global_rect().has_point(event.position):
				if mouse_pressed_on_button:
					_click()
				$BackgroundHover.visible = true
			mouse_pressed_on_button = false
			$BackgroundHover.visible = false


func _click():
	emit_signal("click")
