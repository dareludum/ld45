extends ColorRect

var _target: int = 0

export var target: int setget set_target, get_target

func set_target(value):
	_target = value
	$TextTarget.text = str(_target)

func get_target():
	return _target
