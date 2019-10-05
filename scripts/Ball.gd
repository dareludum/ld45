extends Node2D

const Globals = preload("res://scripts/Globals.gd")

var hex_position = Vector3(0, 0, 0)
var target_position: Vector2
var tier = 1

var is_interpolating = false
var interpolation_t = 0.0
var interpolation_from: Vector2
var interpolation_to: Vector2
const CI_A = Vector2(0.5, 0)
const CI_B = Vector2(0, 1)

func _ready():
	pass

func _process(delta):
	if is_interpolating:
		# TODO: cubic interpolation destabilizes over time, find out why
		# self.position = interpolation_from.cubic_interpolate(interpolation_to, CI_A, CI_B, interpolation_t)
		self.position = interpolation_from.linear_interpolate(interpolation_to, interpolation_t)
		interpolation_t += delta / Globals.TICK_TIME * 2 # speedup
		if interpolation_t >= 1.0:
			self.position = target_position # snap to the target position to avoid rounding errors
			interpolation_t = 1.0
			is_interpolating = false

func move_to(new_position: Vector2):
	target_position = new_position
	interpolation_from = self.position
	interpolation_to = target_position
	interpolation_t = 0.0
	is_interpolating = true
