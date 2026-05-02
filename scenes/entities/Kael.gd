extends "res://scenes/entities/BaseEnemy.gd"

const DASH_INTERVAL := 2.5
const DASH_DURATION := 0.25
const DASH_SPEED    := 480.0

var _dash_timer   := 0.0
var _dash_active  := false
var _dash_elapsed := 0.0
var _dash_dir     := Vector2.ZERO
var _body_poly    : Polygon2D = null

func _setup() -> void:
	speed         = 160.0
	hp            = 10
	damage        = 8
	_sep_radius   = 48.0
	_sep_strength = 100.0
	_dash_timer   = randf_range(0.5, DASH_INTERVAL)
	_build_visual()

func _build_visual() -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, -18))
	pts.append(Vector2(12, 0))
	pts.append(Vector2(0, 18))
	pts.append(Vector2(-12, 0))
	_body_poly = Polygon2D.new()
	_body_poly.polygon = pts
	_body_poly.color   = Color(0.15, 0.3, 0.9, 1.0)
	add_child(_body_poly)

func _tint(color: Color) -> void:
	if _body_poly:
		_body_poly.color = color

func _normal_tint() -> Color:
	return Color(0.15, 0.3, 0.9, 1.0)

func _ai(delta: float) -> void:
	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_do_wander(delta)
		return

	if _dash_active:
		_dash_elapsed += delta
		velocity = _dash_dir * DASH_SPEED
		move_and_slide()
		if _dash_elapsed >= DASH_DURATION:
			_dash_active = false
		return

	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_dash_timer   = DASH_INTERVAL + randf_range(-0.5, 0.5)
		_dash_active  = true
		_dash_elapsed = 0.0
		var to_player := (player.global_position - global_position).normalized()
		_dash_dir = to_player.rotated(PI * 0.5 * (1.0 if randf() > 0.5 else -1.0))
		return

	var dir := _nav_dir_to(player.global_position)
	velocity = dir * speed * _slow_factor * _boost_factor + _separation()
	move_and_slide()

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(1.5, 3.5)
	velocity = _wander_dir * speed * 0.5 + _separation()
	move_and_slide()

func _die() -> void:
	super._die()
	$CollisionShape2D.set_deferred("disabled", true)
	if _body_poly:
		var tween := create_tween()
		tween.tween_property(_body_poly, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)
