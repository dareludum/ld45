extends BaseCell

var interpolation_deg_from: float
var interpolation_deg_to: float
var animation_duration: float
var time_to_animation: float = -1.0
var interpolation_t: float = 1.0

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


func balls_entering(balls, main):
	if len(balls) > 1:
		main.sim_crash("balls collided inside a flip-flop", [self.cell.cube_coords])
		return

	var ball = balls[0]
	var cw: bool
	if flip == (ball.direction in directions_cw):
		cw = true
		ball.direction = HexCell.rotate_direction_cw(ball.direction)
	else:
		ball.direction = HexCell.rotate_direction_ccw(ball.direction)
		cw = false

	interpolation_deg_from = HexCell.direction_to_degrees(self.direction)
	if cw:
		self.direction = HexCell.rotate_direction_cw(self.direction)
	else:
		self.direction = HexCell.rotate_direction_ccw(self.direction)
	interpolation_deg_to = HexCell.direction_to_degrees(self.direction)
	if interpolation_deg_to > interpolation_deg_from + 70:
		interpolation_deg_to = interpolation_deg_from - 60
	elif interpolation_deg_to < interpolation_deg_from - 70:
		interpolation_deg_to = interpolation_deg_from + 60

	animation_duration = main.get_animation_time()
	time_to_animation = 0.75 * animation_duration
	animation_duration *= 0.5
	flip = not flip


func _process(delta: float) -> void:
	var waiting = time_to_animation > 0.0
	var animating = interpolation_t < 1.0
	if not (waiting or animating):
		return

	if animating:
		interpolation_t += delta / animation_duration
		if interpolation_t >= 1.0:
			self.rotation_degrees = interpolation_deg_to
			interpolation_deg_from = interpolation_deg_to
		else:
			self.rotation_degrees = lerp(interpolation_deg_from, interpolation_deg_to, interpolation_t)
		if self.rotation_degrees > 720.0:
			self.rotation_degrees = self.rotation_degrees as int % 360
	elif waiting:
		time_to_animation -= delta
		if time_to_animation <= 0.0:
			interpolation_t = 0.0
			self.rotation_degrees = interpolation_deg_from


func reset_position():
	self.direction = orig_direction
	flip = true
	interpolation_deg_to = HexCell.direction_to_degrees(self.direction)
	interpolation_deg_from = interpolation_deg_to
	time_to_animation = -1.0
	interpolation_t = 1.0
