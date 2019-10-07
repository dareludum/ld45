extends BaseCell


var directions_in: Array


func _on_init():
	directions_in = [
		self.direction,
		HexCell.rotate_direction_cw(HexCell.rotate_direction_cw(self.direction)),
		HexCell.rotate_direction_ccw(HexCell.rotate_direction_ccw(self.direction)),
	]
	self.rotation_degrees = HexCell.direction_to_degrees(self.direction)


func balls_entering(balls, main):
	for ball in balls:
		if not ball.direction in directions_in:
			main.sim_crash("ball collided with a 3-reactor", [self.cell.cube_coords])
			return

	if len(balls) < 3:
		main.sim_crash("fewer than 3 balls entered a 3-reactor", [self.cell.cube_coords])
		return
	elif len(balls) > 3:
		main.sim_crash("more than 3 balls entered a 3-reactor", [self.cell.cube_coords])
		return

	var sum = 0
	for ball in balls:
		if ball.tier == 1:
			sum += 1
		elif ball.tier == 2:
			sum += 3
		elif ball.tier == 3:
			sum += 6
		else:
			assert(false)

	main.add_points(sum * sum, cell.cube_coords)
	main.delete_balls_after_move(balls)
