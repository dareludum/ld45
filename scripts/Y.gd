extends BaseCell

var fat_in: Vector3
var fat_out: Vector3
var thin_in: Array
var thin_out: Array


func _on_init():
	fat_out = cell.rotate_direction_cw(self.direction)
	fat_in = -fat_out
	var ne = cell.rotate_direction_ccw(self.direction)
	thin_out = [cell.rotate_direction_ccw(cell.rotate_direction_ccw(ne)), ne]
	thin_in = [-thin_out[0], -thin_out[1]]
	self.rotation_degrees = self.cell.direction_to_degrees(self.direction)


func balls_entering(balls, main) -> void:
	if len(balls) > 2:
		main.sim_crash("balls collided with a Y-combinator", [self.cell.cube_coords])
		return

	if len(balls) == 1:
		var ball = balls[0]
		var dir = ball.direction

		var split = dir == fat_in
		var funnel = dir in thin_in

		if not (split or funnel):
			main.sim_crash("ball collided with a Y-combinator", [self.cell.cube_coords])
			return

		if split:
			if ball.tier <= 1:
				main.sim_crash("cannot split a tier 1 ball", [self.cell.cube_coords])
				return
			main.set_ball_tier(ball, ball.tier - 1)
			ball.direction = thin_out[0]
			main.set_ball_tier(main.add_ball(ball.cell, thin_out[1], true), ball.tier)
			return

		if funnel:
			ball.direction = fat_out
			return
	else:
		assert(len(balls) == 2)
		var b0 = balls[0]
		var b1 = balls[1]
		var d0 = b0.direction
		var d1 = b1.direction
		assert(d0 != d1)
		if not (d0 in thin_in and d1 in thin_in):
			main.sim_crash("balls collided with a Y-combinator", [self.cell.cube_coords])
			return

		b0.direction = fat_out
		main.set_ball_tier(b0, b0.tier + 1)
		main.delete_ball_after_move(b1)
