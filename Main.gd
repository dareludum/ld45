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
const FlipFlopScene = preload("res://scenes/FlipFlop.tscn")
const Reactor3Scene = preload("res://scenes/Reactor3.tscn")
const YCombScene = preload("res://scenes/Y.tscn")
const Reactor6Scene = preload("res://scenes/Reactor6.tscn")

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
	FLIPFLOP,
	REACTOR3,
	YCOMB,
	REACTOR6,
}

const TOOL_UNLOCK_TARGETS = {
	EditorTool.ERASER: 0,
	EditorTool.SOURCE: 0,
	EditorTool.MIRROR: 10,
	EditorTool.AMPLIFIER: 40,
	EditorTool.FLIPFLOP: 100,
	EditorTool.REACTOR3: 100, # TODO
	EditorTool.YCOMB: 100, # TODO
	EditorTool.REACTOR6: 100, # TODO
}

const TOOL_USES_MAX = {
	EditorTool.SOURCE: 2,
	EditorTool.AMPLIFIER: 1,
}

var state = SimulationState.STOPPED
var hi_score: int = 100

# Design time - specific
var picked_tool
var picked_tool_direction: Vector3
var placed_cells_per_tool = {
	EditorTool.SOURCE: 0,
	EditorTool.AMPLIFIER: 0,
}

# Run time - specific
var tick_timer = Timer.new()
var interpolation_t: float = 0
var tick: int = 0   # counts simulation steps, resets to 0 in sim_start
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

#	for circle in [  # the ball positions in sim_stop are coupled with this
#			{center = HexCell.DIR_SW * 3, radius = 2},
#			{center = HexCell.DIR_SE * 3, radius = 1},
#		]:
#		var dir = HexCell.DIR_SE
#		var pos = circle.radius * HexCell.DIR_S
#		var i = 0
#		while i < 6:
#			var mirror = MirrorScene.instance()
#			mirror.init(hex_grid, circle.center + pos, dir)
#			$CellHolder.add_child(mirror)
#			pos -= circle.radius * dir
#			dir = mirror.cell.rotate_direction_cw(dir)
#			i += 1
#
#	var amplifier = AmplifierScene.instance()
#	amplifier.init(hex_grid, 3 * HexCell.DIR_NW, HexCell.DIR_SE)
#	$CellHolder.add_child(amplifier)

	# TESTING CODE END

	$UIBar.set_hi(hi_score)
	$UIBar.set_source_uses_count(TOOL_USES_MAX[EditorTool.SOURCE])
	$UIBar.set_amplifier_uses_count(TOOL_USES_MAX[EditorTool.AMPLIFIER])

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
	elif picked_tool == EditorTool.FLIPFLOP:
		new_cell = FlipFlopScene.instance()
	elif picked_tool == EditorTool.REACTOR3:
		new_cell = Reactor3Scene.instance()
	elif picked_tool == EditorTool.YCOMB:
		new_cell = YCombScene.instance()
	elif picked_tool == EditorTool.REACTOR6:
		new_cell = Reactor6Scene.instance()
	else:
		assert(false)

	new_cell.init(hex_grid, cell, picked_tool_direction)

	return new_cell


func sim_update_tool_highlight():
	for child in $Highlight/ToolHolder.get_children():
		child.queue_free()
	
	var tool_ = sim_get_tool_cell(HexCell.new(Vector3.ZERO))
	if tool_ == null:
		return

	if picked_tool in placed_cells_per_tool and placed_cells_per_tool[picked_tool] == TOOL_USES_MAX[picked_tool]:
		tool_.get_node("Sprite").self_modulate = Color.orangered
	$Highlight/ToolHolder.add_child(tool_)


func sim_set_tool(tool_):
	if (hi_score < TOOL_UNLOCK_TARGETS[tool_]):
		return

	picked_tool = tool_
	picked_tool_direction = HexCell.DIR_SE
	sim_update_tool_highlight()


func sim_rotate_tool_cw():
	picked_tool_direction = HexCell.rotate_direction_cw(picked_tool_direction)
	sim_update_tool_highlight()


func sim_rotate_tool_ccw():
	picked_tool_direction = HexCell.rotate_direction_ccw(picked_tool_direction)
	sim_update_tool_highlight()


func sim_update_tool_uses(tool_, modifier: int):
	# Modifier is -1 when a cell is placed, +1 when it's erased
	var new_count = placed_cells_per_tool[tool_] - modifier
	var uses_left = TOOL_USES_MAX[tool_] - new_count
	if tool_ == EditorTool.SOURCE:
		$UIBar.set_source_uses_count(uses_left)
	elif tool_ == EditorTool.AMPLIFIER:
		$UIBar.set_amplifier_uses_count(uses_left)
	else:
		assert(false)
	placed_cells_per_tool[tool_] = new_count
	sim_update_tool_highlight()


func sim_cell_click(cell):
	if state != SimulationState.STOPPED:
		return

	var current_cell = null
	for child in $CellHolder.get_children():
		if child.cell.cube_coords == cell.cube_coords:
			current_cell = child

	# This condition allows rotating a placed Source in place even if no more usages
	if (picked_tool in placed_cells_per_tool and placed_cells_per_tool[picked_tool] == TOOL_USES_MAX[picked_tool]
		and not (current_cell != null and current_cell is Source and picked_tool == EditorTool.SOURCE)):
			return

	if current_cell != null:
		if current_cell is Source:
			sim_update_tool_uses(EditorTool.SOURCE, +1)
		elif current_cell is Amplifier:
			sim_update_tool_uses(EditorTool.AMPLIFIER, +1)
		current_cell.queue_free()

	if picked_tool == EditorTool.ERASER:
		return

	var new_cell = sim_get_tool_cell(cell)
	$CellHolder.add_child(new_cell)
	if picked_tool == EditorTool.SOURCE or picked_tool == EditorTool.AMPLIFIER:
		sim_update_tool_uses(picked_tool, -1)


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
		$StatusBar.visible = true

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
	tick_timer.stop()
	state = SimulationState.STOPPED

	$Background.self_modulate = BackgroundColorEditor
	$StatusBar.visible = false

	if tick >= Globals.TARGET_ITERATIONS_COUNT and score > hi_score:
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
	tick_timer.stop()
	state = SimulationState.CRASHED

	if locations:
		print("sim_crash: %s at %s" % [reason, locations])
	else:
		print("sim_crash: %s (location missing)" % reason)
	$Background.self_modulate = BackgroundColorCrashed
	$StatusBar/TextStatus.text = "Crashed: " + reason
	$StatusBar/TextStatus.self_modulate = Color.orangered

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


func new_floating_text(cell_or_hex_pos, show_delay: float, text: String):
	var ft = FloatingTextScene.instance()
	if cell_or_hex_pos is HexCell:
		ft.position = hex_grid.get_hex_center(cell_or_hex_pos.cube_coords)
	else:
		ft.position = hex_grid.get_hex_center(cell_or_hex_pos)
	$FloatingTextHolder.add_child(ft)
	ft.start(text, show_delay)


func add_ball(cell_or_pos, direction: Vector3, show_delay: float = 0.0):
	var b = BallScene.instance()
	b.init(hex_grid, HexCell.new(cell_or_pos), direction)
	$BallHolder.add_child(b)
	if show_delay > 0.0:
		b.hide()
		show_node_in(show_delay, b)
	return b


# this executes asynchronously, i.e. the call returns immediately,
# but the coroutine keeps running on its own
func queue_free_in(delay: float, nodes: Array):
	yield(get_tree().create_timer(delay), "timeout")
	for node in nodes:
		node.queue_free()


func show_node_in(delay: float, node):
	yield(get_tree().create_timer(delay), "timeout")
	node.show()

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
	elif Input.is_action_just_pressed("sim_pick_flipflop"):
		sim_set_tool(EditorTool.FLIPFLOP)
	elif Input.is_action_just_pressed("sim_pick_reactor3"):
		sim_set_tool(EditorTool.REACTOR3)
	elif Input.is_action_just_pressed("sim_pick_ycomb"):
		sim_set_tool(EditorTool.YCOMB)
	elif Input.is_action_just_pressed("sim_pick_reactor6"):
		sim_set_tool(EditorTool.REACTOR6)


# Main logic function, does one simulation step
func _game_tick():
	if state != SimulationState.RUNNING:
		# no time to debug why this happens
		tick_timer.stop()
		return

	tick += 1
	if tick <= Globals.TARGET_ITERATIONS_COUNT:
		$StatusBar/TextStatus.text = "Validating iteration %d/%d..." % [tick, Globals.TARGET_ITERATIONS_COUNT]
		$StatusBar/TextStatus.self_modulate = Color.white
	elif tick == Globals.TARGET_ITERATIONS_COUNT + 1:
		if score != 0:
			$StatusBar/TextStatus.text = "Validated! Stop simulation to claim %d points" % score
		else:
			$StatusBar/TextStatus.text = "Validated! Zero score - try colliding the balls"
		$StatusBar/TextStatus.self_modulate = Color.greenyellow

	var ball_holder = $BallHolder

	# delete balls that are out of the simulation area
	for ball in ball_holder.get_children():
		if ball.cell.cube_coords.length_squared() > 1200.0:  # 3 * 20^2
			ball_holder.remove_child(ball)
			ball.queue_free()

	# spawn new balls
	for source in $CellHolder.get_children():
		if source is Source:
			add_ball(source.cell, source.direction)

	var balls_moving_to = {}  # hex_pos => [Ball]

	# declare movement
	for ball in ball_holder.get_children():
		ball.target_cell = HexCell.new(ball.cell.cube_coords + ball.direction)
		if ball.target_cell.cube_coords in balls_moving_to:
			balls_moving_to[ball.target_cell.cube_coords].append(ball)
		else:
			balls_moving_to[ball.target_cell.cube_coords] = [ball]

	# detect edge collisions (ball-ball swapping places)
	for ball in ball_holder.get_children():
		for intruder in balls_moving_to.get(ball.cell.cube_coords, []):
			if ball.target_cell.cube_coords == intruder.cell.cube_coords:
				var locations = [ball.cell.cube_coords, intruder.cell.cube_coords]
				sim_crash("balls collided on a cell edge", locations)

	# apply movement (even if crashed, to pause after the collision happens)
	for ball in ball_holder.get_children():
		ball.move_to(ball.target_cell)

	# detect ball-structure collisions
	for child in $CellHolder.get_children():
		var hex_pos = child.cell.cube_coords
		if not hex_pos in balls_moving_to:
			continue

		var visitors = balls_moving_to[hex_pos]
		if child is Source:
			sim_crash("ball collided with a source", [hex_pos])
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

	var b0: Ball = balls[0]
	var b1: Ball = balls[1]
	var d0: int = HexCell.DIR_ALL.find(b0.direction)
	var d1: int = HexCell.DIR_ALL.find(b1.direction)
	var direction_difference = abs(d0 - d1)
	# a number between 0 and 3, where 0 means d0 == d1, and 3 means d0 == -d1
	direction_difference = min(direction_difference, 6 - direction_difference)
	assert(direction_difference > 0)

	var points = 0
	var to_delete = []
	var time_to_collision = get_animation_time()

	if b0.tier != b1.tier:
		# different tiers: the lower one is converted to points, the higher one loses energy
		if b0.tier > b1.tier:
			var tmp = b0
			b0 = b1
			b1 = tmp
		points = b0.tier + b1.tier
		b1.set_tier(b1.tier - b0.tier, time_to_collision)
		to_delete.append(b0)
	else:  # b0.tier == b1.tier
		if direction_difference == 1:
			# 60 degrees: emit points, downgrade the balls
			if b0.tier <= 1:
				points = 1
				to_delete.append(b0)
				to_delete.append(b1)
			else:
				points = 2 * b0.tier
				b0.set_tier(b0.tier - 1, time_to_collision)
				b1.set_tier(b1.tier - 1, time_to_collision)
		# 120 degrees: merge the balls, emit points, and sometimes new balls
		elif direction_difference == 2:
			var d2 = (d0 + d1) / 2
			if abs(d2 - d0) != 1:
				d2 = (d2 + 3) % 6  # DIR_ALL[d2] = 0.5 * (DIR_ALL[d0] + DIR_ALL[1])
			b0.direction = HexCell.DIR_ALL[d2]

			if b0.tier <= 1:
				points = 1
				to_delete.append(b1)
			elif b0.tier == 2:
				points = 6
			elif b0.tier == 3:
				points = 15

			if b0.tier > 1:
				b1.set_tier(b1.tier - 1, time_to_collision)
				add_ball(b1.cell, HexCell.DIR_ALL[d0], time_to_collision).set_tier(b1.tier)
				add_ball(b1.cell, -HexCell.DIR_ALL[d2], time_to_collision).set_tier(b1.tier)
		# 180 degrees: emit points and sometimes new balls
		elif direction_difference == 3:
			if b0.tier <= 1:
				points = 2
				to_delete.append(b0)
				to_delete.append(b1)
			elif b0.tier == 2:
				points = 10
			elif b0.tier == 3:
				points = 24

			if b0.tier > 1:
				b0.direction = HexCell.DIR_ALL[(d0 + 1) % 6]
				b1.direction = HexCell.DIR_ALL[(d1 + 1) % 6]
				b0.set_tier(b0.tier - 1, time_to_collision)
				b1.set_tier(b1.tier - 1, time_to_collision)
				add_ball(b0.cell, HexCell.DIR_ALL[(d0 + 5) % 6], time_to_collision).set_tier(b0.tier)
				add_ball(b0.cell, HexCell.DIR_ALL[(d1 + 5) % 6], time_to_collision).set_tier(b0.tier)

	if points > 0:
		new_floating_text(0.5 * (b0.cell.cube_coords + b1.cell.cube_coords), time_to_collision, "+" + str(points))
	queue_free_in(time_to_collision, to_delete)

	# remove the balls from the game logic immediately, don't rely on animation_time < tick_time
	for ball in to_delete:
		$BallHolder.remove_child(ball)
		$BallToDeleteHolder.add_child(ball)

	if tick <= Globals.TARGET_ITERATIONS_COUNT:
		sim_add_points(points)
