# Script to attach to a node which represents a hex grid
extends Node2D

const Globals = preload("res://scripts/Globals.gd")

const Ball1 = preload("res://scenes/Ball1.tscn")
const Ball = preload("res://scripts/Ball.gd")

var HexGrid = preload("./HexGrid.gd").new()

onready var highlight = get_node("Highlight")
onready var area_coords = get_node("Highlight/AreaCoords")
onready var hex_coords = get_node("Highlight/HexCoords")

var tick_timer = Timer.new()

func _ready():
	HexGrid.hex_scale = Vector2(50, 50)
	assert(OK == tick_timer.connect("timeout", self, "_game_tick"))
	tick_timer.autostart = false
	tick_timer.wait_time = Globals.TICK_TIME
	self.add_child(tick_timer)

	# Below is testing code
	var ball = Ball1.instance()
	ball.position = HexGrid.get_hex_center(ball.hex_position)
	self.add_child(ball)
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

# Main logic function, does one simulation step
func _game_tick():
	for child in self.get_children():
		if child is Ball:
			child.hex_position += Vector3(1, -1, 0)
			child.move_to(HexGrid.get_hex_center(child.hex_position))
	print("Tick")
