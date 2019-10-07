extends Control

const Globals = preload("res://scripts/Globals.gd")

signal sandbox_click

func _enter_tree():
	assert(OK == $SimControlHolder/ButtonStartPause.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $SimControlHolder/ButtonStartPause.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $SimControlHolder/ButtonStartPause.connect("click", self, "_on_start_pause_click"))
	assert(OK == $SimControlHolder/ButtonStop.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $SimControlHolder/ButtonStop.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $SimControlHolder/ButtonStop.connect("click", self, "_on_stop_click"))
	assert(OK == $SimControlHolder/ButtonSpeed1.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $SimControlHolder/ButtonSpeed1.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $SimControlHolder/ButtonSpeed1.connect("click", self, "_on_speed1_click"))
	assert(OK == $SimControlHolder/ButtonSpeed2.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $SimControlHolder/ButtonSpeed2.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $SimControlHolder/ButtonSpeed2.connect("click", self, "_on_speed2_click"))
	assert(OK == $SimControlHolder/ButtonSpeed3.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $SimControlHolder/ButtonSpeed3.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $SimControlHolder/ButtonSpeed3.connect("click", self, "_on_speed3_click"))
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
	assert(OK == $CellHolder/ButtonCellFlipFlop.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellFlipFlop.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellFlipFlop.connect("click", self, "_on_pick_flipflop_click"))
	assert(OK == $CellHolder/ButtonCellReactor3.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellReactor3.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellReactor3.connect("click", self, "_on_pick_reactor3_click"))
	assert(OK == $CellHolder/ButtonCellY.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellY.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellY.connect("click", self, "_on_pick_ycomb_click"))
	assert(OK == $CellHolder/ButtonCellReactor6.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellReactor6.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellReactor6.connect("click", self, "_on_pick_reactor6_click"))
	assert(OK == $ButtonSandbox.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $ButtonSandbox.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $ButtonSandbox.connect("click", self, "_on_sandbox_click"))
	assert(OK == $ButtonSmooth.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $ButtonSmooth.connect("mouse_leave", self, "_on_button_mouse_leave"))


func set_points(points: int):
	$PointsHolder/TextPts.text = str(points)


func set_hi(points: int):
	$PointsHolder/TextHI.text = str(points)
	var locks = [
		$CellHolder/ButtonCellMirror/Lock,
		$CellHolder/ButtonCellAmplifier/Lock,
		$CellHolder/ButtonCellFlipFlop/Lock,
		$CellHolder/ButtonCellReactor3/Lock,
		$CellHolder/ButtonCellY/Lock,
		$CellHolder/ButtonCellReactor6/Lock,
		$ButtonSandbox/Lock,
	]
	for lock in locks:
		if points >= lock.target:
			lock.visible = false


func set_source_uses_count(count: int):
	$CellHolder/ButtonCellSource.set_uses_count(count)


func set_amplifier_uses_count(count: int):
	$CellHolder/ButtonCellAmplifier.set_uses_count(count)


func set_reactor3_uses_count(count: int):
	$CellHolder/ButtonCellReactor3.set_uses_count(count)


func set_reactor6_uses_count(count: int):
	$CellHolder/ButtonCellReactor6.set_uses_count(count)


func simulation_started():
	$SimControlHolder/ButtonStartPause/SpriteStart.visible = false
	$SimControlHolder/ButtonStartPause/SpritePause.visible = true
	pass


func simulation_paused():
	$SimControlHolder/ButtonStartPause/SpriteStart.visible = true
	$SimControlHolder/ButtonStartPause/SpritePause.visible = false
	pass


func simulation_stopped():
	$SimControlHolder/ButtonStartPause/SpriteStart.visible = true
	$SimControlHolder/ButtonStartPause/SpritePause.visible = false
	pass


func simulate_input_event(name):
	var event = InputEventAction.new()
	event.action = name
	event.pressed = true
	Input.parse_input_event(event)
	event.pressed = false
	Input.parse_input_event(event)


func _on_button_mouse_enter(button):
	var lock = button.get_node_or_null("Lock")
	if lock != null and lock.visible:
		$HintPanel/TextHint.text = "Get %d points in %d iterations to unlock" % [lock.target, Globals.TARGET_ITERATIONS_COUNT]
	else:
		$HintPanel/TextHint.text = button.text_hint
	$HintPanel.visible = true


func _on_button_mouse_leave(_button):
	$HintPanel.visible = false


func _on_start_pause_click():
	simulate_input_event("sim_start_pause")


func _on_stop_click():
	simulate_input_event("sim_stop")


func _on_speed1_click():
	simulate_input_event("sim_speed_1")


func _on_speed2_click():
	simulate_input_event("sim_speed_2")


func _on_speed3_click():
	simulate_input_event("sim_speed_3")


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


func _on_pick_flipflop_click():
	simulate_input_event("sim_pick_flipflop")


func _on_pick_reactor3_click():
	simulate_input_event("sim_pick_reactor3")


func _on_pick_ycomb_click():
	simulate_input_event("sim_pick_ycomb")


func _on_pick_reactor6_click():
	simulate_input_event("sim_pick_reactor6")


func _on_sandbox_click():
	emit_signal("sandbox_click")
