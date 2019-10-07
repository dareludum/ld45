extends Node

# Times are in seconds

const TICK_TIME: float = 0.5
const TICK_TIME_FAST: float = 0.25
const TICK_TIME_FASTEST: float = 0.1

const TARGET_ITERATIONS_COUNT: int = 60
const MAX_BALL_TIER = 3

const BALL_RED = Color(0.9, 0.15, 0.15, 1)
const BALL_ORANGE = Color(0.9, 0.45, 0.1, 1)
const BALL_YELLOW = Color(1, 0.85, 0, 1)

const BALL_SMALL = 2 * Vector2(0.265, 0.265) # sqrt(1.6)
const BALL_MEDIUM = 2 * Vector2(0.285, 0.285) # sqrt(1.65)
const BALL_LARGE = 2 * Vector2(0.3, 0.3) # sqrt(1.7)

const FLOATING_TEXT_SCROLL_SPEED: float = 30.0  # pixels per second
const FLOATING_TEXT_SCROLL_TIME:  float = 1.25  # seconds

static func get_animation_time(tick_time: float):
	return tick_time / 1.5
