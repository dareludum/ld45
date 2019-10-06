extends Control


func set_points(points: int):
	$PointsHolder/TextPts.text = str(points)


func set_hi(points: int):
	$PointsHolder/TextHI.text = str(points)

