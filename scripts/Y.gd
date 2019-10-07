extends BaseCell

var fat_in: Vector3
var fat_out: Vector3
var thin_in: Array
var thin_out: Array


func _on_init():
	print("Y init")
	fat_out = cell.rotate_direction_cw(self.direction)
	fat_in = -fat_out
	var ne = cell.rotate_direction_ccw(self.direction)
	thin_out = [cell.rotate_direction_ccw(cell.rotate_direction_ccw(ne)), ne]
	thin_in = [-thin_out[0], -thin_out[1]]
	self.rotation_degrees = self.cell.direction_to_degrees(self.direction)


func balls_entering(balls, main) -> void:
	if len(balls) != 1:
		main.sim_crash("balls collided inside a Y-combinator", [self.cell.cube_coords])
		return

	var ball = balls[0]
	var dir = ball.direction

	var split = dir == fat_in
	var funnel = dir in thin_in
	print("Y enter, split is %s, funnel is %s" % [split, funnel])

	if not (split or funnel):
		main.sim_crash("ball collided with a Y-combinator", [self.cell.cube_coords])
		return

	if split:
		if ball.tier <= 1:
			main.sim_crash("only balls of tier 2 or higher can be split by a Y-combinator")
			return
		main.set_ball_tier(ball, ball.tier - 1)
		ball.direction = thin_out[0]
		main.set_ball_tier(main.add_ball(ball.cell, thin_out[1], true), ball.tier)
		return

	if funnel:
		ball.direction = fat_out
