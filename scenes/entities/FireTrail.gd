extends Area2D

const LIFETIME  := 2.0
const TICK_CD   := 0.5
const TEXTURES  := [
	preload("res://assets/effects/FireTrail1.png"),
	preload("res://assets/effects/FireTrail2.png"),
]

var _life  := 0.0
var _tick  := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	$Visual.texture = TEXTURES[randi() % 2]
	$Visual.rotation = randf() * TAU
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_life += delta
	_tick += delta
	if _tick >= TICK_CD:
		_tick = 0.0
		for body in get_overlapping_bodies():
			if body.is_in_group("enemies"):
				body.take_damage(1)
	$Visual.modulate.a = 1.0 - (_life / LIFETIME)
	if _life >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(1)
