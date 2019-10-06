extends BaseCell

var tier: int
var target_cell: HexCell  # scratchpad for Main, equal to cell.cube_coords outside of _game_tick

var interpolation_pos_from: Vector2
var interpolation_pos_to: Vector2
const CI_A = Vector2(0.5, 0)
const CI_B = Vector2(0, 1)


func _on_init():
	set_tier(1)
	move_to(self.cell)


func set_tier(tier_, ui_change_delay: float = 0.0):
	assert(0 < tier_ and tier_ <= Globals.MAX_BALL_TIER)
	tier = tier_
	if ui_change_delay > 0.0:
		yield(get_tree().create_timer(ui_change_delay), "timeout")
	var sprite = $Sprite
	if tier == 1:
		sprite.modulate = Globals.BALL_YELLOW
		sprite.scale = Globals.BALL_SMALL
	elif tier == 2:  # orange
		sprite.modulate = Globals.BALL_ORANGE
		sprite.scale = Globals.BALL_MEDIUM
	elif tier == 3:  # red
		sprite.modulate = Globals.BALL_RED
		sprite.scale = Globals.BALL_LARGE
	else:
		assert(false)

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
