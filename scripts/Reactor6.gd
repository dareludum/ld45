extends BaseCell


func _on_init():
	self.rotation_degrees = HexCell.direction_to_degrees(self.direction)


func balls_entering(balls, main):
	if len(balls) < 6:
		main.sim_crash("fewer than 6 balls entered a 6-reactor", [self.cell.cube_coords])
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
