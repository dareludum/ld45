extends Node2D

const Globals = preload("res://scripts/Globals.gd")
const HexGrid = preload("res://HexGrid.gd")

var hex_grid: HexGrid  # parent, set in _init
var hex_position = Vector3.ZERO
var hex_direction = Vector3.ZERO
var target_hex_pos = Vector3.ZERO  # scratchpad for Main, equal to hex_position outside of _game_tick
var tier = 1

var interpolation_pos_from: Vector2
var interpolation_pos_to: Vector2
const CI_A = Vector2(0.5, 0)
const CI_B = Vector2(0, 1)


# WARNING: this is not _init (Script.new) but a custom init to be called after Node.instance
func init(hex_pos: Vector3, hex_dir: Vector3, grid: HexGrid) -> void:
	hex_grid = grid
	hex_position = hex_pos
	hex_direction = hex_dir
	move_to(hex_position)


func animation_process(progress: float):  # progress is between 0 and 1
	if progress >= 1.0:
		self.position = interpolation_pos_to
	else:
		# TODO: cubic interpolation destabilizes over time, find out why
		# self.position = interpolation_pos_from.cubic_interpolate(interpolation_pos_to, CI_A, CI_B, progress)
		self.position = interpolation_pos_from.linear_interpolate(interpolation_pos_to, progress)


func move_to(new_hex_pos: Vector3):
	interpolation_pos_from = hex_grid.get_hex_center(hex_position)
	interpolation_pos_to = hex_grid.get_hex_center(new_hex_pos)
	hex_position = new_hex_pos
