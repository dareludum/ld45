extends Node2D

class_name BaseCell

const Globals = preload("res://scripts/Globals.gd")
const HexGrid = preload("res://HexGrid.gd")
const HexCell = preload("res://HexCell.gd")

var grid: HexGrid  # parent, set in init
var cell: HexCell
var direction = Vector3.ZERO

# WARNING: this is not _init (Script.new) but a custom init to be called after Node.instance
func init(grid: HexGrid, cell: HexCell, direction: Vector3) -> void:
	self.grid = grid
	self.cell = cell
	self.direction = direction
	self.position = grid.get_hex_center(cell.cube_coords)
	_on_init()

func _on_init():
	pass
