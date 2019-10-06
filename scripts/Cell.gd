extends BaseCell

func mark_as_crashsite():
	$Sprite.self_modulate = Color("#ff8080")

func reset():
	$Sprite.self_modulate = Color.white
