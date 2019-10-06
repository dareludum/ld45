# Script to attach to a node which represents a hex grid
extends Node2D

const BackgroundColorEditor = Color("#49518f")
const BackgroundColorRunning = Color("#495b8f")
const BackgroundColorPaused = Color("#49688f")
const BackgroundColorCrashed = Color("#64498f")

const Globals = preload("res://scripts/Globals.gd")
const HexCell = preload("res://HexCell.gd")
const HexGrid = preload("res://HexGrid.gd")
const BaseCell = preload("res://scripts/BaseCell.gd")
const Ball = preload("res://scripts/Ball.gd")
var Source = load("res://scripts/Source.gd")
var Mirror = load("res://scripts/Mirror.gd")
var Amplifier = load("res://scripts/Amplifier.gd")

const SourceScene = preload("res://scenes/Source.tscn")
const BallScene = preload("res://scenes/Ball.tscn")
const MirrorScene = preload("res://scenes/Mirror.tscn")
const AmplifierScene = preload("res://scenes/Amplifier.tscn")
const FloatingTextScene = preload("res://scenes/FloatingText.tscn")

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

enum EditorTool {
	ERASER,
	SOURCE,
	MIRROR,
	AMPLIFIER,
}

var state = SimulationState.STOPPED
var hi_score: int = 0

# Design time - specific
var picked_tool
var picked_tool_direction: Vector3

# Run time - specific
var tick_timer = Timer.new()
var interpolation_t: float = 0
var tick: int = 0
var score: int = 0


func _ready():
	hex_grid.hex_scale = Vector2(50, 50)
	for i in range(-20, 20):
		for j in range(-20, 20):
			var cell = preload("res://scenes/Cell.tscn").instance()
			cell.init(hex_grid, Vector2(i, j), HexCell.DIR_SE)
			$BackgroundCellHolder.add_child(cell)
	assert(OK == tick_timer.connect("timeout", self, "_game_tick"))
	tick_timer.autostart = false
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

	var amplifier = AmplifierScene.instance()
	amplifier.init(hex_grid, 3 * HexCell.DIR_NW, HexCell.DIR_SE)
	$CellHolder.add_child(amplifier)

	# TESTING CODE END

	sim_set_speed(1)
	sim_set_tool(EditorTool.ERASER)
	sim_stop() # TODO: remove, for now it just sets up the testing config


# ===== Simulation Editor =====


func sim_get_tool_cell(cell):
	if picked_tool == EditorTool.ERASER:
		return null

	var new_cell = null
	if picked_tool == EditorTool.SOURCE:
		new_cell = SourceScene.instance()
	elif picked_tool == EditorTool.MIRROR:
		new_cell = MirrorScene.instance()
	elif picked_tool == EditorTool.AMPLIFIER:
		new_cell = AmplifierScene.instance()
	else:
		assert(false)

	new_cell.init(hex_grid, cell, picked_tool_direction)

	return new_cell


func sim_update_tool_highlight():
	for child in $Highlight/ToolHolder.get_children():
		child.queue_free()
	$Highlight/ToolHolder.add_child(sim_get_tool_cell(HexCell.new(Vector3.ZERO)))


func sim_set_tool(tool_):
	picked_tool = tool_
	picked_tool_direction = HexCell.DIR_SE
	sim_update_tool_highlight()


func sim_rotate_tool_cw():
	picked_tool_direction = HexCell.rotate_direction_cw(picked_tool_direction)
	sim_update_tool_highlight()


func sim_rotate_tool_ccw():
	picked_tool_direction = HexCell.rotate_direction_ccw(picked_tool_direction)
	sim_update_tool_highlight()


func sim_cell_click(cell):
	if state != SimulationState.STOPPED:
		return

	for child in $CellHolder.get_children():
		if child.cell.cube_coords == cell.cube_coords:
			child.queue_free()

	if picked_tool == EditorTool.ERASER:
		return

	var new_cell = sim_get_tool_cell(cell)
	$CellHolder.add_child(new_cell)


# ===== Simulation Running =====


func sim_set_speed(speed: int):
	if speed == 1:
		tick_timer.wait_time = Globals.TICK_TIME
	elif speed == 2:
		tick_timer.wait_time = Globals.TICK_TIME_FAST
	elif speed == 3:
		tick_timer.wait_time = Globals.TICK_TIME_FASTEST
	else:
		assert(false)


func sim_add_points(points: int):
	score += points
	$UIBar.set_points(score)


func sim_start():
	print("sim_start")
	$Background.self_modulate = BackgroundColorRunning

	if state == SimulationState.STOPPED:
		tick = 0
		score = 0
		$UIBar.set_points(score)

	state = SimulationState.RUNNING
	_game_tick()
	tick_timer.start()


func sim_pause():
	print("sim_pause")
	$Background.self_modulate = BackgroundColorPaused
	state = SimulationState.PAUSED
	tick_timer.stop()


func sim_stop():
	print("sim_stop")
	$Background.self_modulate = BackgroundColorEditor
	state = SimulationState.STOPPED
	tick_timer.stop()

	if tick >= 60 and score > hi_score:
		hi_score = score
		$UIBar.set_hi(hi_score)

	# remove balls
	for ball in $BallHolder.get_children():
		ball.queue_free()

	# reset rotations
	for child in $CellHolder.get_children():
		if child is Source:
			child.reset_position()
	
	# reset background
	for child in $BackgroundCellHolder.get_children():
		child.reset()

	# TESTING CODE BEGIN

	# balls to run around the circle, positions coupled with _ready
#	var offset01 = HexCell.DIR_NE + HexCell.DIR_SE
#	var b0 = BallScene.instance()
#	b0.init(hex_grid, HexCell.DIR_SW * 3 + HexCell.DIR_NE + HexCell.DIR_N, HexCell.DIR_SE)
#	b0.set_tier(1)
#	$BallHolder.add_child(b0)
#
#	var b1 = BallScene.instance()
#	b1.set_tier(3)
#	b1.init(hex_grid, HexCell.DIR_SE * 4, HexCell.DIR_N)
#	$BallHolder.add_child(b1)
#
#
#	# balls that collide head on
#	var b2 = BallScene.instance()
#	b2.init(hex_grid, HexCell.DIR_NE * 4 + 2 * HexCell.DIR_N, HexCell.DIR_S)
#	b2.set_tier(2)
#	$BallHolder.add_child(b2)
#
#	var b3 = BallScene.instance()
#	b3.init(hex_grid, HexCell.DIR_NE * 4 + 2 * HexCell.DIR_S, HexCell.DIR_N)
#	b3.set_tier(2)
#	$BallHolder.add_child(b3)
#
#	# a ball that gets amplified
#	var b4 = BallScene.instance()
#	b4.init(hex_grid, HexCell.new(HexCell.DIR_N * 2 + 3 * HexCell.DIR_NW), HexCell.DIR_S)
#	b4.set_tier(1)
#	$BallHolder.add_child(b4)

	# TESTING CODE END


func sim_crash(reason: String = "no reason", locations: Array = []) -> void:
	print("sim_crash: %s" % reason)
	state = SimulationState.CRASHED
	tick_timer.stop()

	$Background.self_modulate = BackgroundColorCrashed
	for location in locations:
		for child in $BackgroundCellHolder.get_children():
			if child.cell.cube_coords == location:
				child.mark_as_crashsite()
				break

# ===== End of simulation code =====


func get_animation_time() -> float:
	return Globals.get_animation_time(tick_timer.wait_time)


func _process(delta: float) -> void:
	interpolation_t = min(1.0, interpolation_t + delta / get_animation_time())
	for child in $CellHolder.get_children():
		child.animation_process(interpolation_t)
	for child in $BallHolder.get_children():
		child.animation_process(interpolation_t)
	for child in $BallToDeleteHolder.get_children():
		child.animation_process(interpolation_t)


func new_floating_text(cell_or_hex_pos, delay: float, text: String):
	var ft = FloatingTextScene.instance()
	if cell_or_hex_pos is HexCell:
		ft.position = hex_grid.get_hex_center(cell_or_hex_pos.cube_coords)
	else:
		ft.position = hex_grid.get_hex_center(cell_or_hex_pos)
	$FloatingTextHolder.add_child(ft)
	ft.start(text, delay)


# this executes asynchronously, i.e. the call returns immediately,
# but the coroutine keeps running on its own
func queue_free_in(delay: float, nodes: Array):
	yield(get_tree().create_timer(delay), "timeout")
	for node in nodes:
		node.queue_free()


func _unhandled_input(event):
	if event is InputEventMouse:
		var relative_pos = self.transform.affine_inverse() * event.position
		var cell = hex_grid.get_hex_at(relative_pos)

		# Display the coords used
		if area_coords != null:
			area_coords.text = str(relative_pos)
		if hex_coords != null:
			hex_coords.text = str(cell.axial_coords)

		# Snap the highlight to the nearest grid cell
		if highlight != null:
			highlight.position = hex_grid.get_hex_center(cell)

		if event is InputEventMouseButton:
			if (event.button_index == BUTTON_LEFT and event.is_pressed()
				and $CollisionBox.get_viewport_rect().has_point(event.position)):
					sim_cell_click(cell)

	if Input.is_action_just_pressed("sim_start_pause"):
		if state == SimulationState.STOPPED || state == SimulationState.PAUSED:
			sim_start()
		elif state == SimulationState.RUNNING:
			sim_pause()
	elif Input.is_action_just_pressed("sim_stop"):
		sim_stop()
	elif Input.is_action_just_pressed("sim_speed_1"):
		sim_set_speed(1)
	elif Input.is_action_just_pressed("sim_speed_2"):
		sim_set_speed(2)
	elif Input.is_action_just_pressed("sim_speed_3"):
		sim_set_speed(3)
	elif Input.is_action_just_pressed("sim_rotate_left"):
		sim_rotate_tool_ccw()
	elif Input.is_action_just_pressed("sim_rotate_right"):
		sim_rotate_tool_cw()
	elif Input.is_action_just_pressed("sim_pick_eraser"):
		sim_set_tool(EditorTool.ERASER)
	elif Input.is_action_just_pressed("sim_pick_source"):
		sim_set_tool(EditorTool.SOURCE)
	elif Input.is_action_just_pressed("sim_pick_mirror"):
		sim_set_tool(EditorTool.MIRROR)
	elif Input.is_action_just_pressed("sim_pick_amplifier"):
		sim_set_tool(EditorTool.AMPLIFIER)


# Main logic function, does one simulation step
func _game_tick():
	if state != SimulationState.RUNNING:
		# no time to debug why this happens
		tick_timer.stop()
		return

	tick += 1

	# spawn new balls
	for source in $CellHolder.get_children():
		if source is Source:
			var b = BallScene.instance()
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

	# detect edge collisions (ball-ball swapping places)
	for ball in $BallHolder.get_children():
		for intruder in balls_moving_to.get(ball.cell.cube_coords, []):
			if ball.target_cell.cube_coords == intruder.cell.cube_coords:
				var locations = [ball.cell.cube_coords, intruder.cell.cube_coords]
				sim_crash("edge collision between %s and %s" % locations, locations)

	# apply movement (even if crashed, to pause after the collision happens)
	for ball in $BallHolder.get_children():
		ball.move_to(ball.target_cell)

	# detect ball-structure collisions
	for child in $CellHolder.get_children():
		var hex_pos = child.cell.cube_coords
		if not hex_pos in balls_moving_to:
			continue

		var visitors = balls_moving_to[hex_pos]
		if child is Source:
			sim_crash("ball entered a source at %s" % hex_pos, [hex_pos])
		elif child is Mirror or child is Amplifier:
			child.balls_entered(visitors, self)

		# consume this collision to prevent both the ball-structure and ball-ball rules from applying
		balls_moving_to.erase(hex_pos)

	# detect ball-ball collisions when entering the same cell
	if state != SimulationState.CRASHED:
		for hex_pos in balls_moving_to:
			var visitors = balls_moving_to[hex_pos]
			var n = len(visitors)
			if n < 2:
				continue
			balls_collided(visitors, hex_pos)
			print("%d balls in cell %s" % [n, hex_pos])

	# apply rotations
	for child in $CellHolder.get_children():
		if child is Source:
			child.rotate_cw()

	interpolation_t = 0.0
	print("Tick")


func balls_collided(balls, hex_pos):
	if len(balls) > 2:
		sim_crash("multiple balls collided", [hex_pos])
		return

	var points = 1
	var time_to_collision = get_animation_time()
	new_floating_text(0.5 * (balls[0].cell.cube_coords + balls[1].cell.cube_coords), time_to_collision, "+" + str(points))
	queue_free_in(time_to_collision, balls)
	# remove the balls from the game logic immediately, don't rely on animation_time < tick_time
	for ball in balls:
		$BallHolder.remove_child(ball)
		$BallToDeleteHolder.add_child(ball)

	if tick <= 60:
		sim_add_points(points)
