# Script to attach to a node which represents a hex grid
extends Node2D

const Globals = preload("res://scripts/Globals.gd")
const HexCell = preload("res://HexCell.gd")
const HexGrid = preload("res://HexGrid.gd")
const BaseCell = preload("res://scripts/BaseCell.gd")
const Ball = preload("res://scripts/Ball.gd")
var Source = load("res://scripts/Source.gd")
var Mirror = load("res://scripts/Mirror.gd")

const Ball1 = preload("res://scenes/Ball1.tscn")
const MirrorScene = preload("res://scenes/Mirror.tscn")

var hex_grid = HexGrid.new()

onready var highlight = get_node("Highlight")
onready var area_coords = get_node("Highlight/AreaCoords")
onready var hex_coords = get_node("Highlight/HexCoords")

enum SimulationState {
	RUNNING,
	PAUSED,
	STOPPED, # design mode
	CRASHED,
}

var state = SimulationState.STOPPED
var tick_timer = Timer.new()
var interpolation_t: float = 0

func _ready():
	hex_grid.hex_scale = Vector2(50, 50)
	for i in range(-20, 20):
		for j in range(-20, 20):
			var cell = preload("res://scenes/Cell.tscn").instance()
			cell.position = hex_grid.get_hex_center(Vector2(i, j))
			$BackgroundCellHolder.add_child(cell)
	assert(OK == tick_timer.connect("timeout", self, "_game_tick"))
	tick_timer.autostart = false
	tick_timer.wait_time = Globals.TICK_TIME
	self.add_child(tick_timer)

	# TESTING CODE BEGIN

#	var source = preload("res://scenes/Source.tscn").instance()
#	source.init(hex_grid, Vector3(-2, 1, 1), HexCell.DIR_SE)
#	$CellHolder.add_child(source)

#	var mirror = MirrorScene.instance()
#	mirror.init(hex_grid, Vector3(0, -1, 1), HexCell.DIR_SE)
#	$CellHolder.add_child(mirror)

	for circle in [  # the ball positions in sim_stop are coupled with this
			{center = HexCell.DIR_SW * 3, radius = 2},
			{center = HexCell.DIR_SE * 3, radius = 1},
		]:
		var dir = HexCell.DIR_SE
		var pos = circle.radius * HexCell.DIR_S
		var i = 0
		while i < 6:
			var mirror = MirrorScene.instance()
			mirror.init(hex_grid, circle.center + pos, dir)
			$CellHolder.add_child(mirror)
			pos -= circle.radius * dir
			dir = mirror.cell.rotate_direction_cw(dir)
			i += 1

	# TESTING CODE END

	sim_stop() # TODO: remove, for now it just sets up the testing config


func sim_start():
	print("sim_start")
	$Status.text = "Status: started"
	$Status.modulate = Color.green

	state = SimulationState.RUNNING
	_game_tick()
	tick_timer.start()


func sim_pause():
	print("sim_pause")
	$Status.text = "Status: paused"
	$Status.modulate = Color.orange

	state = SimulationState.PAUSED
	tick_timer.stop()


func sim_stop():
	print("sim_stop")
	$Status.text = "Status: stopped"
	$Status.modulate = Color.white

	state = SimulationState.STOPPED
	tick_timer.stop()

	# remove balls
	var to_delete = $BallHolder.get_children()
	for child in to_delete:
		remove_child(child)
		child.queue_free()

	# reset rotations
	for child in $CellHolder.get_children():
		if child is Source:
			child.reset_position()

	# TESTING CODE BEGIN

	# balls to run around the circle, positions coupled with _ready
	var offset01 = HexCell.DIR_NE + HexCell.DIR_SE
	var b0 = Ball1.instance()
	b0.init(hex_grid, HexCell.DIR_SW * 3 + HexCell.DIR_NE + HexCell.DIR_N, HexCell.DIR_SE)
	$BallHolder.add_child(b0)

	var b1 = Ball1.instance()
	b1.init(hex_grid, HexCell.DIR_SE * 4, HexCell.DIR_N)
	$BallHolder.add_child(b1)

	# TESTING CODE END


func sim_crash(reason: String = "no reason") -> void:
	print("sim_crash: %s" % reason)
	$Status.text = "Status: crashed"
	$Status.modulate = Color.red

	state = SimulationState.CRASHED
	tick_timer.stop()


func _process(delta: float) -> void:
	interpolation_t = min(1.0, interpolation_t + 2 * delta * (1.0 / Globals.TICK_TIME))
	for child in $CellHolder.get_children():
		child.animation_process(interpolation_t)
	for child in $BallHolder.get_children():
		child.animation_process(interpolation_t)


func _unhandled_input(event):
	if 'position' in event:
		var relative_pos = self.transform.affine_inverse() * event.position
		# Display the coords used
		if area_coords != null:
			area_coords.text = str(relative_pos)
		if hex_coords != null:
			hex_coords.text = str(hex_grid.get_hex_at(relative_pos).axial_coords)

		# Snap the highlight to the nearest grid cell
		if highlight != null:
			highlight.position = hex_grid.get_hex_center(hex_grid.get_hex_at(relative_pos))

	if event is InputEventKey:
		if Input.is_action_pressed("sim_start_pause"):
			if state == SimulationState.STOPPED || state == SimulationState.PAUSED:
				sim_start()
			elif state == SimulationState.RUNNING:
				sim_pause()
		elif Input.is_action_pressed("sim_stop"):
			sim_stop()


# Main logic function, does one simulation step
func _game_tick():
	if state != SimulationState.RUNNING:
		# no time to debug why this happens
		tick_timer.stop()
		return

	# spawn new balls
	for source in $CellHolder.get_children():
		if source is Source:
			var b = Ball1.instance()
			b.init(hex_grid, HexCell.new(source.cell), source.direction)
			$BallHolder.add_child(b)

	var balls_moving_to = {}  # hex_pos => [Ball]

	# declare movement
	for ball in $BallHolder.get_children():
		ball.target_cell = HexCell.new(ball.cell.cube_coords + ball.direction)
		if ball.target_cell.cube_coords in balls_moving_to:
			balls_moving_to[ball.target_cell.cube_coords].append(ball)
		else:
			balls_moving_to[ball.target_cell.cube_coords] = [ball]

	# detect edge collisions (ball-ball or ball-structure)
	for ball in $BallHolder.get_children():
		for intruder in balls_moving_to.get(ball.cell.cube_coords, []):
			if ball.target_cell.cube_coords == intruder.cell.cube_coords:
				sim_crash("edge collision between %s and %s" % [ball.cell.cube_coords, intruder.cell.cube_coords])

	# apply movement (even if crashed, to pause after the collision happens)
	for ball in $BallHolder.get_children():
		ball.move_to(ball.target_cell)

	# detect cell collisions (2+ balls entering the same cell)
	if state != SimulationState.CRASHED:
		for hex_pos in balls_moving_to:
			var visitors = balls_moving_to[hex_pos]
			var n = len(visitors)
			if n < 2:
				continue
			print("%d balls in cell %s" % [n, hex_pos])

	# apply structure collision rules
	for child in $CellHolder.get_children():
		var hex_pos = child.cell.cube_coords
		if not hex_pos in balls_moving_to:
			continue

		var visitors = balls_moving_to[hex_pos]
		if child is Source:
			sim_crash("ball entered a source at %s" % hex_pos)
		if child is Mirror:
			child.balls_entered(visitors, self)

	# apply rotations
	for child in $CellHolder.get_children():
		if child is Source:
			child.rotate_cw()

	interpolation_t = 0.0
	print("Tick")
