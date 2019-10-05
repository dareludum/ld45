# Script to attach to a node which represents a hex grid
extends Node2D

const Globals = preload("res://scripts/Globals.gd")
const Ball1 = preload("res://scenes/Ball1.tscn")
const Ball = preload("res://scripts/Ball.gd")

var HexCell = preload("res://HexCell.gd").new()
var HexGrid = preload("res://HexGrid.gd").new()

onready var highlight = get_node("Highlight")
onready var area_coords = get_node("Highlight/AreaCoords")
onready var hex_coords = get_node("Highlight/HexCoords")

var paused = true
var tick_timer = Timer.new()

func _ready():
	HexGrid.hex_scale = Vector2(50, 50)
	for i in range(-20, 20):
		for j in range(-20, 20):
			var cell = preload("res://scenes/Cell.tscn").instance()
			cell.position = HexGrid.get_hex_center(Vector2(i, j))
			cell.scale = Vector2(0.33, 0.33)
			$BackgroundCellHolder.add_child(cell)
	assert(OK == tick_timer.connect("timeout", self, "_game_tick"))
	tick_timer.autostart = false
	tick_timer.wait_time = Globals.TICK_TIME
	self.add_child(tick_timer)

	# Below is testing code

	var offset01 = HexCell.DIR_NE + HexCell.DIR_SE
	var b0 = Ball1.instance()
	b0.hex_direction = HexCell.DIR_NE
	b0.hex_position = HexCell.round_coords(offset01 - HexCell.DIR_NE)
	b0.position = HexGrid.get_hex_center(b0.hex_position)
	self.add_child(b0)

	var b1 = Ball1.instance()
	b1.hex_direction = HexCell.DIR_SW
	b1.hex_position = HexCell.round_coords(offset01 - HexCell.DIR_SW)
	b1.position = HexGrid.get_hex_center(b1.hex_position)
	self.add_child(b1)

	var i = 0
	while i < len(HexCell.DIR_ALL):
		var dir = HexCell.DIR_ALL[i]
		var ball = Ball1.instance()
		ball.hex_direction = dir
		ball.hex_position = HexCell.round_coords(-(3 + i) * dir)
		ball.position = HexGrid.get_hex_center(ball.hex_position)
		self.add_child(ball)
		i += 1
	tick_timer.start()

func _unhandled_input(event):
	if 'position' in event:
		var relative_pos = self.transform.affine_inverse() * event.position
		# Display the coords used
		if area_coords != null:
			area_coords.text = str(relative_pos)
		if hex_coords != null:
			hex_coords.text = str(HexGrid.get_hex_at(relative_pos).axial_coords)

		# Snap the highlight to the nearest grid cell
		if highlight != null:
			highlight.position = HexGrid.get_hex_center(HexGrid.get_hex_at(relative_pos))

	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_SPACE:
			paused = not paused

func get_balls() -> Array:
	var balls = []
	for child in self.get_children():
		if child is Ball:
			balls.append(child)
	return balls


# Main logic function, does one simulation step
func _game_tick():
	if paused:
		print("Paused")
		return

	var balls = get_balls()
	var balls_moving_to = {}  # hex_pos => [Ball]

	# declare movement
	for ball in balls:
		ball.target_hex_pos = HexCell.round_coords(ball.hex_position + ball.hex_direction)
		if ball.target_hex_pos in balls_moving_to:
			balls_moving_to[ball.target_hex_pos].append(ball)
		else:
			balls_moving_to[ball.target_hex_pos] = [ball]

	# detect edge collisions (ball-ball or ball-structure)
	for ball in balls:
		for intruder in balls_moving_to.get(ball.hex_position, []):
			if ball.target_hex_pos == intruder.hex_position:
				print("edge collision between %s and %s" % [ball.hex_position, intruder.hex_position])

	# apply movement
	for ball in balls:
		ball.hex_position = ball.target_hex_pos
		ball.move_to(HexGrid.get_hex_center(ball.hex_position))  # todo: do this inside the ball

	# detect cell collisions (2+ balls entering the same cell)
	for hex_pos in balls_moving_to:
		var visitors = balls_moving_to[hex_pos]
		var n = len(visitors)
		if n < 2:
			continue
		print("%d balls in cell %s" % [n, hex_pos])

	print("Tick")
