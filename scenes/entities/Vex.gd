extends "res://scenes/entities/BaseEnemy.gd"

var explosion_damage := 35
var _body_poly       : Polygon2D = null

func _setup() -> void:
	speed         = 200.0
	hp            = 80
	damage        = 10
	_sep_radius   = 36.0
	_sep_strength = 60.0
	_build_visual()

func _build_visual() -> void:
	var N   := 12
	var pts := PackedVector2Array()
	for i in N:
		var a := 2.0 * PI * i / N
		pts.append(Vector2(cos(a), sin(a)) * 14.0)
	_body_poly = Polygon2D.new()
	_body_poly.polygon = pts
	_body_poly.color   = Color(0.9, 0.15, 0.1, 1.0)
	add_child(_body_poly)

func _tint(color: Color) -> void:
	if _body_poly:
		_body_poly.color = color

func _normal_tint() -> Color:
	return Color(0.9, 0.15, 0.1, 1.0)

func _ai(delta: float) -> void:
	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_do_wander(delta)
		return
	var dir := _nav_dir_to(player.global_position)
	velocity = dir * speed * _slow_factor * _boost_factor + _separation()
	move_and_slide()

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(1.0, 2.5)
	velocity = _wander_dir * speed * 0.5 + _separation()
	move_and_slide()

func _die() -> void:
	_explode()
	super._die()
	$CollisionShape2D.set_deferred("disabled", true)
	if _body_poly:
		var tween := create_tween()
		tween.tween_property(_body_poly, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)

func _explode() -> void:
	var arena := get_parent()
	if arena == null:
		return
	var _explo := BulletPool.get_explosion(arena)
	_explo.global_position = global_position
	_explo.reinit(explosion_damage)
