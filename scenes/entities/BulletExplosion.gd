extends Area2D

const DURATION := 0.22

var damage := 1
var _time  := 0.0
var _hit   := false

func _ready() -> void:
	await get_tree().process_frame
	if not _hit:
		_hit = true
		for body in get_overlapping_bodies():
			if body.is_in_group("enemies"):
				body.take_damage(damage)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= DURATION:
		queue_free()

func _draw() -> void:
	var t    := _time / DURATION
	var r    := 80.0 * (0.25 + t * 0.75)
	var a    := 1.0 - t
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.55, 0.05, a * 0.35))
	draw_arc(Vector2.ZERO, r,        0.0, TAU, 40, Color(1.0, 0.75, 0.2, a * 0.9), 3.5)
	draw_arc(Vector2.ZERO, r * 0.55, 0.0, TAU, 32, Color(1.0, 0.95, 0.5, a * 0.6), 1.5)
