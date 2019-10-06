extends Control

const Globals = preload("res://scripts/Globals.gd")


func _enter_tree():
	assert(OK == $SimControlHolder/ButtonStartPause.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $SimControlHolder/ButtonStartPause.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $SimControlHolder/ButtonStartPause.connect("click", self, "_on_start_pause_click"))
	assert(OK == $SimControlHolder/ButtonStop.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $SimControlHolder/ButtonStop.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $SimControlHolder/ButtonStop.connect("click", self, "_on_stop_click"))
	assert(OK == $RotationHolder/ButtonRotateRight.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $RotationHolder/ButtonRotateRight.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $RotationHolder/ButtonRotateRight.connect("click", self, "_on_rotate_right_click"))
	assert(OK == $RotationHolder/ButtonRotateLeft.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $RotationHolder/ButtonRotateLeft.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $RotationHolder/ButtonRotateLeft.connect("click", self, "_on_rotate_left_click"))
	assert(OK == $CellHolder/ButtonCellEraser.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellEraser.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellEraser.connect("click", self, "_on_pick_eraser_click"))
	assert(OK == $CellHolder/ButtonCellSource.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellSource.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellSource.connect("click", self, "_on_pick_source_click"))
	assert(OK == $CellHolder/ButtonCellMirror.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellMirror.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellMirror.connect("click", self, "_on_pick_mirror_click"))
	assert(OK == $CellHolder/ButtonCellAmplifier.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellAmplifier.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellAmplifier.connect("click", self, "_on_pick_amplifier_click"))


func set_points(points: int):
	$PointsHolder/TextPts.text = str(points)


func set_hi(points: int):
	$PointsHolder/TextHI.text = str(points)
	var locks = [
		$CellHolder/ButtonCellMirror/Lock,
		$CellHolder/ButtonCellAmplifier/Lock,
	]
	for lock in locks:
		if points >= lock.target:
			lock.visible = false


func simulate_input_event(name):
	var event = InputEventAction.new()
	event.action = name
	event.pressed = true
	Input.parse_input_event(event)
	event.pressed = false
	Input.parse_input_event(event)


func _on_button_mouse_enter(button):
	var lock = button.get_node("Lock")
	if lock != null and lock.visible:
		$HintPanel/TextHint.text = "Get %d points in %d iterations to unlock" % [lock.target, Globals.TARGET_ITERATIONS_COUNT]
	else:
		$HintPanel/TextHint.text = button.text_hint
	$HintPanel.visible = true


func _on_button_mouse_leave(button):
	$HintPanel.visible = false


func _on_start_pause_click():
	simulate_input_event("sim_start_pause")


func _on_stop_click():
	simulate_input_event("sim_stop")


func _on_rotate_right_click():
	simulate_input_event("sim_rotate_right")


func _on_rotate_left_click():
	simulate_input_event("sim_rotate_left")


func _on_pick_eraser_click():
	simulate_input_event("sim_pick_eraser")


func _on_pick_source_click():
	simulate_input_event("sim_pick_source")


func _on_pick_mirror_click():
	simulate_input_event("sim_pick_mirror")


func _on_pick_amplifier_click():
	simulate_input_event("sim_pick_amplifier")
