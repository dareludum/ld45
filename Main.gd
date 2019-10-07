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
var FlipFlop = load("res://scripts/FlipFlop.gd")
var Reactor3 = load("res://scripts/Reactor3.gd")
var Reactor6 = load("res://scripts/Reactor6.gd")

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
onready var ui_bar = get_tree().root.get_node("Main/UILayer/UIBar")
onready var status_bar = get_tree().root.get_node("Main/UILayer/StatusBar")
onready var status_bar_text = get_tree().root.get_node("Main/UILayer/StatusBar/TextStatus")

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
	EditorTool.REACTOR3: 150,
	EditorTool.YCOMB: 400,
	EditorTool.REACTOR6: 1000
}

const TOOL_USES_MAX = {
	EditorTool.SOURCE: 2,
	EditorTool.AMPLIFIER: 1,
	EditorTool.REACTOR3: 1,
	EditorTool.REACTOR6: 1,
}

var state = SimulationState.STOPPED
var hi_score: int = 1000

# Design time - specific
var picked_tool
var picked_tool_direction = HexCell.DIR_SE
var placed_cells_per_tool = {
	EditorTool.SOURCE: 0,
	EditorTool.AMPLIFIER: 0,
	EditorTool.REACTOR3: 0,
	EditorTool.REACTOR6: 0,
}

# Run time - specific
var sim_speed: int = 1
var time_to_sim_step: float = 0.0
var interpolation_t: float = 0.0
var tick: int = 0   # counts simulation steps, resets to 0 in sim_start
var score: int = 0

signal move_anim_done
var time_to_move_anim_done: float = 0.0
var floating_texts_to_add: Array = []
var balls_to_show: Array = []
var tiers_to_set: Array = []


func _ready():
	hex_grid.hex_scale = Vector2(50, 50)
	for i in range(-20, 20):
		for j in range(-20, 20):
			var cell = preload("res://scenes/Cell.tscn").instance()
			cell.init(hex_grid, Vector2(i, j), HexCell.DIR_SE)
			$BackgroundCellHolder.add_child(cell)

	self.connect("move_anim_done", self, "on_move_anim_done")

	ui_bar.set_hi(hi_score)
	ui_bar.set_source_uses_count(TOOL_USES_MAX[EditorTool.SOURCE])
	ui_bar.set_amplifier_uses_count(TOOL_USES_MAX[EditorTool.AMPLIFIER])
	ui_bar.set_reactor3_uses_count(TOOL_USES_MAX[EditorTool.REACTOR3])
	ui_bar.set_reactor6_uses_count(TOOL_USES_MAX[EditorTool.REACTOR6])

	sim_speed = 1
	sim_set_tool(EditorTool.SOURCE)


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

	if state != SimulationState.STOPPED:
		$Highlight.self_modulate = Color.white
		return

	var tool_ = sim_get_tool_cell(HexCell.new(Vector3.ZERO))
	if tool_ == null:
		$Highlight.self_modulate = Color.red
		return
	else:
		$Highlight.self_modulate = Color.white

	if picked_tool in placed_cells_per_tool and placed_cells_per_tool[picked_tool] == TOOL_USES_MAX[picked_tool]:
		tool_.get_node("Sprite").self_modulate = Color.orangered
	$Highlight/ToolHolder.add_child(tool_)


func sim_set_tool(tool_):
	if (hi_score < TOOL_UNLOCK_TARGETS[tool_]):
		return

	picked_tool = tool_
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
		ui_bar.set_source_uses_count(uses_left)
	elif tool_ == EditorTool.AMPLIFIER:
		ui_bar.set_amplifier_uses_count(uses_left)
	elif tool_ == EditorTool.REACTOR3:
		ui_bar.set_reactor3_uses_count(uses_left)
	elif tool_ == EditorTool.REACTOR6:
		ui_bar.set_reactor6_uses_count(uses_left)
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

	# This condition allows rotating a placed Source or Reactor[3|6] in place even if no more usages
	if (picked_tool in placed_cells_per_tool and placed_cells_per_tool[picked_tool] == TOOL_USES_MAX[picked_tool]
		and not (current_cell != null and current_cell is Source and picked_tool == EditorTool.SOURCE)
		and not (current_cell != null and current_cell is Reactor3 and picked_tool == EditorTool.REACTOR3)
		and not (current_cell != null and current_cell is Reactor6 and picked_tool == EditorTool.REACTOR6)):
			return

	if current_cell != null:
		if current_cell is Source:
			sim_update_tool_uses(EditorTool.SOURCE, +1)
		elif current_cell is Amplifier:
			sim_update_tool_uses(EditorTool.AMPLIFIER, +1)
		elif current_cell is Reactor3:
			sim_update_tool_uses(EditorTool.REACTOR3, +1)
		elif current_cell is Reactor6:
			sim_update_tool_uses(EditorTool.REACTOR6, +1)
		current_cell.queue_free()

	if picked_tool == EditorTool.ERASER:
		return

	var new_cell = sim_get_tool_cell(cell)
	$CellHolder.add_child(new_cell)
	if (picked_tool == EditorTool.SOURCE or picked_tool == EditorTool.AMPLIFIER
		or picked_tool == EditorTool.REACTOR3 or picked_tool == EditorTool.REACTOR6):
			sim_update_tool_uses(picked_tool, -1)


# ===== Simulation Running =====


func get_tick_time():
	if sim_speed == 1:
		return Globals.TICK_TIME
	elif sim_speed == 2:
		return Globals.TICK_TIME_FAST
	elif sim_speed == 3:
		return Globals.TICK_TIME_FASTEST
	else:
		assert(false)


func get_animation_time() -> float:
	return get_tick_time() / 1.5
	# todo: return get_tick_time() if smooth animaton is on


func get_animation_speed():
	if sim_speed == 1:
		return 1.0
	elif sim_speed == 2:
		return Globals.TICK_TIME / Globals.TICK_TIME_FAST
	elif sim_speed == 3:
		return Globals.TICK_TIME / Globals.TICK_TIME_FASTEST
	else:
		assert(false)


func sim_add_points(points: int):
	score += points
	ui_bar.set_points(score)


func sim_start():
	$Background.self_modulate = BackgroundColorRunning
	ui_bar.simulation_started()

	if state == SimulationState.STOPPED:
		tick = 0
		score = 0
		ui_bar.set_points(score)
		status_bar.visible = true

	state = SimulationState.RUNNING
	sim_update_tool_highlight()
	sim_step()
	time_to_sim_step = get_tick_time()


func sim_pause():
	$Background.self_modulate = BackgroundColorPaused
	ui_bar.simulation_paused()
	state = SimulationState.PAUSED


func sim_stop():
	# flush all the queued operations before we delete the nodes they would work on
	on_move_anim_done()

	time_to_sim_step = 0.0
	state = SimulationState.STOPPED

	$Background.self_modulate = BackgroundColorEditor
	ui_bar.simulation_stopped()
	sim_update_tool_highlight()
	status_bar.visible = false

	if tick >= Globals.TARGET_ITERATIONS_COUNT and score > hi_score:
		hi_score = score
		ui_bar.set_hi(hi_score)

	# remove balls
	for ball in $BallHolder.get_children():
		ball.queue_free()

	# reset rotations
	for child in $CellHolder.get_children():
		if child is Source or child is FlipFlop:
			child.reset_position()

	# reset background
	for child in $BackgroundCellHolder.get_children():
		child.reset()


func sim_crash(reason: String, locations: Array) -> void:
	state = SimulationState.CRASHED
	time_to_sim_step = 0.0
	print("sim_crash: %s at %s" % [reason, locations])
	$Background.self_modulate = BackgroundColorCrashed
	status_bar_text.text = "Crashed: " + reason
	status_bar_text.self_modulate = Color.orangered

	for location in locations:
		for child in $BackgroundCellHolder.get_children():
			if child.cell.cube_coords == location:
				child.mark_as_crashsite()
				break

# ===== End of simulation code =====


func set_ball_tier(ball: Ball, tier: int):
	# the logic applies immediately, and the graphics when the move animation ends
	ball.tier = tier
	tiers_to_set.append({ball=ball, tier=tier})


func _process(delta: float) -> void:
	if state == SimulationState.RUNNING:
		time_to_sim_step -= delta
		if time_to_sim_step <= 0.0:
			sim_step()
			time_to_sim_step += get_tick_time()

	interpolation_t = min(1.0, interpolation_t + delta / get_animation_time())
	for child in $CellHolder.get_children():
		child.animation_process(interpolation_t)
	for child in $BallHolder.get_children():
		child.animation_process(interpolation_t)
	for child in $BallToDeleteHolder.get_children():
		child.animation_process(interpolation_t)

	if time_to_move_anim_done > 0.0:
		time_to_move_anim_done -= delta
		if time_to_move_anim_done <= 0.0:
			emit_signal("move_anim_done")


func safe_to_touch(node):
	return is_instance_valid(node) and not node.is_queued_for_deletion()


func on_move_anim_done():
	for d in floating_texts_to_add:
		var ft = FloatingTextScene.instance()
		$FloatingTextHolder.add_child(ft)
		ft.position = d.pos
		ft.start(d.text, d.color, get_animation_speed())
	if floating_texts_to_add:
		floating_texts_to_add.clear()

	for b in balls_to_show:
		if safe_to_touch(b):
			b.show()
	if balls_to_show:
		balls_to_show.clear()

	for d in tiers_to_set:
		if safe_to_touch(d.ball):
			d.ball.set_tier(d.tier)
	if tiers_to_set:
		tiers_to_set.clear()

	for node in $BallToDeleteHolder.get_children():
		node.queue_free()


func add_floating_text(cell_or_hex_pos, text: String, color=null):
	var pos: Vector2
	if cell_or_hex_pos is HexCell:
		pos = hex_grid.get_hex_center(cell_or_hex_pos.cube_coords)
	else:
		pos = hex_grid.get_hex_center(cell_or_hex_pos)
	floating_texts_to_add.append({
		pos=pos,
		text=text,
		color=color,
	})


func add_ball(cell_or_pos, direction: Vector3, hide_until_move_anim_end: bool = false):
	var b = BallScene.instance()
	b.init(hex_grid, HexCell.new(cell_or_pos), direction)
	$BallHolder.add_child(b)
	if hide_until_move_anim_end:
		b.hide()
		balls_to_show.append(b)
	return b


# remove the balls from the game logic immediately,
# but keep them around until the end of the next move animation
func delete_ball_after_move(ball: Ball):
	$BallHolder.remove_child(ball)
	$BallToDeleteHolder.add_child(ball)


func delete_balls_after_move(balls: Array):
	var from = $BallHolder
	var to = $BallToDeleteHolder
	for ball in balls:
		from.remove_child(ball)
		to.add_child(ball)


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

		if ($CollisionBox.get_viewport_rect().has_point(event.position)
			and ((event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed())
				or Input.is_mouse_button_pressed(BUTTON_LEFT))):
					sim_cell_click(cell)

	if Input.is_action_just_pressed("sim_start_pause"):
		if state == SimulationState.STOPPED || state == SimulationState.PAUSED:
			sim_start()
		elif state == SimulationState.RUNNING:
			sim_pause()
	elif Input.is_action_just_pressed("sim_stop"):
		sim_stop()
	elif Input.is_action_just_pressed("sim_speed_1"):
		sim_speed = 1
	elif Input.is_action_just_pressed("sim_speed_2"):
		sim_speed = 2
	elif Input.is_action_just_pressed("sim_speed_3"):
		sim_speed = 3
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
func sim_step():
	if state != SimulationState.RUNNING:
		# no time to debug why this happens
		return

	tick += 1
	if tick <= Globals.TARGET_ITERATIONS_COUNT:
		status_bar_text.text = "Validating iteration %d/%d..." % [tick, Globals.TARGET_ITERATIONS_COUNT]
		status_bar_text.self_modulate = Color.white
	elif tick == Globals.TARGET_ITERATIONS_COUNT + 1:
		if score != 0:
			status_bar_text.text = "Validated! Stop simulation to claim %d points" % score
		else:
			status_bar_text.text = "Validated! Zero score - try colliding the balls"
		status_bar_text.self_modulate = Color.greenyellow

	# schedule the next move_anim_done signal
	time_to_move_anim_done = get_animation_time()

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
		child.balls_entering(visitors, self)

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

	# apply rotations
	for child in $CellHolder.get_children():
		if child is Source:
			child.rotate_cw()

	interpolation_t = 0.0


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

	if b0.tier != b1.tier:
		# different tiers: the lower one is converted to points, the higher one loses energy
		if b0.tier > b1.tier:
			var tmp = b0
			b0 = b1
			b1 = tmp
		points = b0.tier + b1.tier
		set_ball_tier(b1, b1.tier - b0.tier)
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
				set_ball_tier(b0, b0.tier - 1)
				set_ball_tier(b1, b1.tier - 1)
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
				set_ball_tier(b1, b1.tier - 1)
				set_ball_tier(add_ball(b1.cell, HexCell.DIR_ALL[d0], true), b1.tier)
				set_ball_tier(add_ball(b1.cell, -HexCell.DIR_ALL[d2], true), b1.tier)
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
				set_ball_tier(b0, b0.tier - 1)
				set_ball_tier(b1, b1.tier - 1)
				set_ball_tier(add_ball(b0.cell, HexCell.DIR_ALL[(d0 + 5) % 6], true), b0.tier)
				set_ball_tier(add_ball(b0.cell, HexCell.DIR_ALL[(d1 + 5) % 6], true), b0.tier)

	add_points(points, 0.5 * (b0.cell.cube_coords + b1.cell.cube_coords))
	delete_balls_after_move(to_delete)


func add_points(points: int, coords: Vector3):
	if points > 0:
		var text: String
		var color = null
		if tick <= Globals.TARGET_ITERATIONS_COUNT:
			sim_add_points(points)
			text = "+" + str(points)
		else:
			text = str(points)
			color = Color.gray
		add_floating_text(coords, text, color)
