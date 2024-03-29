extends BaseCell

func balls_entering(balls, main) -> void:
	if len(balls) > 1:
		main.sim_crash("balls collided inside an amplifier", [self.cell.cube_coords])
		return

	var b = balls[0]
	if b.tier >= Globals.MAX_BALL_TIER:
		main.sim_crash("max tier ball entered an amplifier", [self.cell.cube_coords])
		return

	main.set_ball_tier(b, b.tier + 1)
