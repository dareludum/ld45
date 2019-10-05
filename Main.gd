# Script to attach to a node which represents a hex grid
extends Node2D

var HexGrid = preload("./HexGrid.gd").new()

onready var highlight = get_node("Highlight")
onready var area_coords = get_node("Highlight/AreaCoords")
onready var hex_coords = get_node("Highlight/HexCoords")

const Ball1 = preload("res://scenes/Ball1.tscn")

func _ready():
	HexGrid.hex_scale = Vector2(50, 50)
	var ball = Ball1.instance()
	ball.position = HexGrid.get_hex_center(Vector3(0, 0, 0))
	add_child(ball)

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
