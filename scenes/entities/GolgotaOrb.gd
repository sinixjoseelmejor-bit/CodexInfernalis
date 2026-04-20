extends Area2D

const SPEED    := 460.0
const WAIT     := 1.8
const LIFETIME := 6.0

var _timer    := WAIT
var _launched := false
var _dir      := Vector2.DOWN
var _player: Node2D = null

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if _launched:
		global_position += _dir * SPEED * delta
	else:
		_timer -= delta
		var pulse: float = 0.4 + sin(Time.get_ticks_msec() * 0.006) * 0.4
		modulate.a = pulse
		if _timer <= 0.0:
			_launch()

func _launch() -> void:
	_launched = true
	modulate.a = 1.0
	if _player and is_instance_valid(_player) and not _player.get("_dead"):
		_dir = (_player.global_position - global_position).normalized()
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	if _launched and body.is_in_group("player"):
		body.take_damage(1)
		queue_free()
