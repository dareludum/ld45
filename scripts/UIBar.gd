extends Control


func _enter_tree():
	assert(OK == $SimControlHolder/ButtonStartPause.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $SimControlHolder/ButtonStartPause.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $SimControlHolder/ButtonStop.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $SimControlHolder/ButtonStop.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $RotationHolder/ButtonRotateRight.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $RotationHolder/ButtonRotateRight.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $RotationHolder/ButtonRotateLeft.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $RotationHolder/ButtonRotateLeft.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellEraser.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellEraser.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellSource.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellSource.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellMirror.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellMirror.connect("mouse_leave", self, "_on_button_mouse_leave"))
	assert(OK == $CellHolder/ButtonCellAmplifier.connect("mouse_enter", self, "_on_button_mouse_enter"))
	assert(OK == $CellHolder/ButtonCellAmplifier.connect("mouse_leave", self, "_on_button_mouse_leave"))


func set_points(points: int):
	$PointsHolder/TextPts.text = str(points)


func set_hi(points: int):
	$PointsHolder/TextHI.text = str(points)


func _on_button_mouse_enter(button):
	$HintPanel/TextHint.text = button.text_hint
	$HintPanel.visible = true


func _on_button_mouse_leave(button):
	$HintPanel.visible = false
