extends BaseCell

var interpolation_deg_from: float
var interpolation_deg_to: float

var orig_direction: Vector3
var directions_cw: Array
var flip = true

func _on_init():
	directions_cw = [
		self.direction,
		HexCell.rotate_direction_cw(HexCell.rotate_direction_cw(self.direction)),
		HexCell.rotate_direction_ccw(HexCell.rotate_direction_ccw(self.direction)),
	]
	orig_direction = self.direction
	self.rotation_degrees = HexCell.direction_to_degrees(self.direction)
	reset_position()


func balls_entered(balls, main):
	if len(balls) > 1:
		main.sim_crash("balls collided inside a flip-flop", [self.cell.cube_coords])
		return

	var ball = balls[0]
	if flip == (ball.direction in directions_cw):
		ball.direction = HexCell.rotate_direction_cw(ball.direction)
	else:
		ball.direction = HexCell.rotate_direction_ccw(ball.direction)
	
	interpolation_deg_from = HexCell.direction_to_degrees(self.direction)
	if flip:
		self.direction = HexCell.rotate_direction_cw(orig_direction)
	else:
		self.direction = orig_direction
	interpolation_deg_to = HexCell.direction_to_degrees(self.direction)

	flip = not flip


func animation_process(progress: float):  # progress is between 0 and 1
	if progress >= 1.0:
		self.rotation_degrees = interpolation_deg_to
		interpolation_deg_from = interpolation_deg_to
	else:
		self.rotation_degrees = interpolation_deg_from + (interpolation_deg_to - interpolation_deg_from) * progress
	if self.rotation_degrees > 720.0:
		self.rotation_degrees = self.rotation_degrees as int % 360


func reset_position():
	self.direction = orig_direction
	flip = true
	interpolation_deg_to = HexCell.direction_to_degrees(self.direction)
	interpolation_deg_from = interpolation_deg_to
