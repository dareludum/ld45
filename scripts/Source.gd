extends BaseCell

var interpolation_deg_from: float
var interpolation_deg_to: float


var orig_direction: Vector3


func _on_init():
	orig_direction = self.direction
	self.rotation_degrees = HexCell.direction_to_degrees(self.direction)
	reset_position()


func balls_entering(_balls, main):
	main.sim_crash("ball collided with a source", [self.cell.cube_coords])


func animation_process(progress: float):  # progress is between 0 and 1
	if progress >= 1.0:
		self.rotation_degrees = interpolation_deg_to
	else:
		self.rotation_degrees = interpolation_deg_from + (interpolation_deg_to - interpolation_deg_from) * progress
	if self.rotation_degrees > 720.0:
		self.rotation_degrees = self.rotation_degrees as int % 360


func reset_position():
	self.direction = orig_direction
	interpolation_deg_to = HexCell.direction_to_degrees(self.direction)
	interpolation_deg_from = interpolation_deg_to


func rotate_cw():
	interpolation_deg_from = HexCell.direction_to_degrees(self.direction)
	self.direction = HexCell.rotate_direction_cw(self.direction)
	interpolation_deg_to = HexCell.direction_to_degrees(self.direction)
	if interpolation_deg_to < interpolation_deg_from:
		interpolation_deg_to += 360.0
