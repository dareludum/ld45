extends ColorRect

var mouse_pressed_on_button = false

signal click

export var key_hint: String = "" setget set_key_hint, get_key_hint


func set_key_hint(value):
	$KeyHint/TextKeyHint.text = value


func get_key_hint():
	return $KeyHint/TextKeyHint.text


func _input(event):
	if event is InputEventMouseMotion:
		if not mouse_pressed_on_button:
			$BackgroundHover.visible = self.get_global_rect().has_point(event.position)
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
