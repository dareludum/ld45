extends BaseCell

var directions_in: Array
var directions_out: Array

func _on_init():
	directions_in = [
		self.direction,
		cell.rotate_direction_cw(cell.rotate_direction_cw(self.direction))
	]
	directions_out = [
		-directions_in[1],
		-directions_in[0]
	]
	self.rotation_degrees = self.cell.direction_to_degrees(self.direction)


func balls_entered(balls, main) -> void:
	if len(balls) > 1:
		main.sim_crash("multiple balls entered a mirror", [self.cell.cube_coords])
		return

	var ball = balls[0]
	if ball.direction == directions_in[0]:
		ball.direction = directions_out[0]
		return
	if ball.direction == directions_in[1]:
		ball.direction = directions_out[1]
		return

	main.sim_crash("ball entered a mirror from the wrong side", [self.cell.cube_coords])
