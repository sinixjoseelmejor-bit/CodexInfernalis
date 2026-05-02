extends "res://scenes/entities/BaseEnemy.gd"

const DESIRED_DIST := 650.0
const FLEE_DIST    := 400.0
const SHOOT_CD     := 3.5

var _shoot_timer := 0.0
var _body_poly   : Polygon2D = null

func _setup() -> void:
	speed         = 60.0
	hp            = 200
	damage        = 30
	_sep_radius   = 55.0
	_sep_strength = 90.0
	_shoot_timer  = randf_range(1.0, SHOOT_CD)
	_build_visual()

func _build_visual() -> void:
	# 8-pointed star
	var N   := 8
	var pts := PackedVector2Array()
	for i in N:
		var a := 2.0 * PI * i / N
		var r := 26.0 if (i % 2 == 0) else 14.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	_body_poly = Polygon2D.new()
	_body_poly.polygon = pts
	_body_poly.color   = Color(0.1, 0.6, 0.35, 1.0)
	add_child(_body_poly)

func _tint(color: Color) -> void:
	if _body_poly:
		_body_poly.color = color

func _normal_tint() -> Color:
	return Color(0.1, 0.6, 0.35, 1.0)

func _ai(delta: float) -> void:
	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_do_wander(delta)
		return

	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = SHOOT_CD
		_shoot()

	var to_player := player.global_position - global_position
	var dist      := to_player.length()
	var move_dir  : Vector2
	if dist < FLEE_DIST:
		move_dir = -to_player.normalized()
	elif dist > DESIRED_DIST + 100.0:
		move_dir = to_player.normalized() * 0.5
	else:
		move_dir = to_player.normalized().rotated(PI * 0.5) * 0.3
	velocity = move_dir * speed * _slow_factor * _boost_factor
	move_and_slide()

func _shoot() -> void:
	if player == null:
		return
	var dir := (player.global_position - global_position).normalized()
	var b   := BulletPool.get_brutus_bullet(get_parent())
	b.global_position = global_position
	b.init(dir, damage, 420.0)

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(2.0, 5.0)
	velocity = _wander_dir * speed * 0.4 + _separation()
	move_and_slide()

func _die() -> void:
	super._die()
	$CollisionShape2D.set_deferred("disabled", true)
	if _body_poly:
		var tween := create_tween()
		tween.tween_property(_body_poly, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
