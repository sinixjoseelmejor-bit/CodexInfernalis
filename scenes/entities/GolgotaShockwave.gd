extends Node2D

const TELEGRAPH         := 0.8
const PULSE_DURATION    := 1.5
const MAX_RADIUS        := 500.0
const PLAYER_SAFE_RADIUS := 80.0
const HIT_BAND           := 35.0

var damage := 20

var _state := "telegraph"
var _timer := TELEGRAPH
var _current_radius := 0.0
var _hit_player := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	_timer -= delta
	queue_redraw()
	match _state:
		"telegraph":
			if _timer <= 0.0:
				_state = "pulsing"
				_timer = PULSE_DURATION
				_current_radius = 0.0
		"pulsing":
			var t: float = 1.0 - (_timer / PULSE_DURATION)
			_current_radius = t * MAX_RADIUS
			_check_hit()
			if _timer <= 0.0:
				queue_free()

func _check_hit() -> void:
	if _hit_player:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	var d: float = global_position.distance_to((player as Node2D).global_position)
	if d > PLAYER_SAFE_RADIUS and abs(d - _current_radius) < HIT_BAND:
		_hit_player = true
		if player.has_method("take_damage"):
			player.take_damage(damage)

func _draw() -> void:
	match _state:
		"telegraph":
			var t: float = 1.0 - (_timer / TELEGRAPH)
			var alpha: float = 0.15 + 0.35 * t
			draw_arc(Vector2.ZERO, MAX_RADIUS, 0.0, TAU, 64, Color(0.7, 0.15, 1.0, alpha), 3.0)
			draw_circle(Vector2.ZERO, 40.0 + t * 30.0, Color(0.8, 0.2, 1.0, 0.3 * t))
		"pulsing":
			var ring_alpha: float = 0.95
			var inner_alpha: float = 0.25
			draw_arc(Vector2.ZERO, _current_radius, 0.0, TAU, 64, Color(1.0, 0.25, 1.0, ring_alpha), 10.0)
			if _current_radius > 20.0:
				draw_arc(Vector2.ZERO, _current_radius - 10.0, 0.0, TAU, 64, Color(1.0, 0.6, 1.0, inner_alpha), 4.0)
