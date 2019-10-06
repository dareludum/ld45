extends Node

# Times are in seconds

const TICK_TIME: float = 0.5
const TICK_TIME_FAST: float = 0.25
const TICK_TIME_FASTEST: float = 0.1

const FLOATING_TEXT_SCROLL_SPEED: float = 20.0  # pixels per second
const FLOATING_TEXT_SCROLL_TIME:  float = 1.25  # seconds

static func get_animation_time(tick_time: float):
	return tick_time / 1.5
