extends BaseCell

var target_cell: HexCell  # scratchpad for Main, equal to cell.cube_coords outside of _game_tick
var tier = 1

var interpolation_pos_from: Vector2
var interpolation_pos_to: Vector2
const CI_A = Vector2(0.5, 0)
const CI_B = Vector2(0, 1)


func _on_init():
	move_to(self.cell)


func animation_process(progress: float):  # progress is between 0 and 1
	if progress >= 1.0:
		self.position = interpolation_pos_to
	else:
		# TODO: cubic interpolation destabilizes over time, find out why
		# self.position = interpolation_pos_from.cubic_interpolate(interpolation_pos_to, CI_A, CI_B, progress)
		self.position = interpolation_pos_from.linear_interpolate(interpolation_pos_to, progress)


func move_to(new_cell: HexCell):
	interpolation_pos_from = grid.get_hex_center(cell.cube_coords)
	interpolation_pos_to = grid.get_hex_center(new_cell.cube_coords)
	self.cell = new_cell
