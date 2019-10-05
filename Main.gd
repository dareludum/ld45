# Script to attach to a node which represents a hex grid
extends Node2D

const Globals = preload("res://scripts/Globals.gd")
const BaseCell = preload("res://scripts/BaseCell.gd")
const Ball1 = preload("res://scenes/Ball1.tscn")
const Ball = preload("res://scripts/Ball.gd")
var Source = load("res://scripts/Source.gd")
var Mirror = load("res://scripts/Mirror.gd")

var HexCell = preload("res://HexCell.gd")
var HexGrid = preload("res://HexGrid.gd")
var hex_grid = HexGrid.new()

onready var highlight = get_node("Highlight")
onready var area_coords = get_node("Highlight/AreaCoords")
onready var hex_coords = get_node("Highlight/HexCoords")

var paused = true
var crashed = false
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

	var source = preload("res://scenes/Source.tscn").instance()
	source.init(hex_grid, Vector3(-2, 1, 1), HexCell.DIR_SE)
	$CellHolder.add_child(source)

	var mirror = preload("res://scenes/Mirror.tscn").instance()
	mirror.init(hex_grid, Vector3(0, -1, 1), HexCell.DIR_SE)
	$CellHolder.add_child(mirror)

	# TESTING CODE END

	sim_reset() # TODO: remove, for now it just sets up the testing config

func sim_reset():
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

	var offset01 = HexCell.DIR_NE + HexCell.DIR_SE
	var b0 = Ball1.instance()
	b0.init(hex_grid, HexCell.new(offset01 - HexCell.DIR_NE), HexCell.DIR_NE)
	$BallHolder.add_child(b0)

	var b1 = Ball1.instance()
	b1.init(hex_grid, HexCell.new(offset01 - HexCell.DIR_SW), HexCell.DIR_SW)
	$BallHolder.add_child(b1)

#	var i = 0
#	while i < len(HexCell.DIR_ALL):
#		var dir = HexCell.DIR_ALL[i]
#		var ball = Ball1.instance()
#		ball.init(hex_grid, HexCell.new(-(3 + i) * dir), dir)
#		$BallHolder.add_child(ball)
#		i += 1

	# TESTING CODE END

	crashed = false

func sim_start():
	print("sim_start")
	$Status.text = "Status: started"
	$Status.modulate = Color.green
	paused = false
	_game_tick()
	tick_timer.start()


func sim_stop():
	print("sim_stop")
	$Status.text = "Status: stopped"
	$Status.modulate = Color.orange
	paused = true
	tick_timer.stop()


func sim_crash(reason: String = "no reason") -> void:
	print("sim_crash: %s" % reason)
	$Status.text = "Status: crashed"
	$Status.modulate = Color.red
	paused = true
	crashed = true
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
		if event.pressed:
			if event.scancode == KEY_SPACE:
				if not crashed:
					if paused:
						sim_start()
					else:
						sim_stop()
			elif event.scancode == KEY_ESCAPE:
				sim_stop()
				sim_reset()


# Main logic function, does one simulation step
func _game_tick():
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
	if not crashed:
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
