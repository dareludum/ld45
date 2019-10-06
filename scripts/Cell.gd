extends BaseCell

func mark_as_crashsite():
	$Sprite.self_modulate = Color("#f24747")

func reset():
	$Sprite.self_modulate = Color.white
