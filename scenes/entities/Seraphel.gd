extends "res://scenes/entities/BaseEnemy.gd"

const ALDRICH_SCENE := preload("res://scenes/entities/Aldrich.tscn")
const DESIRED_DIST  := 550.0
const FLEE_DIST     := 350.0
const SUMMON_CD     := 8.0

var summon_damage := 4
var _summon_timer : float = 4.0
var _body_poly    : Polygon2D = null

func _setup() -> void:
	speed         = 55.0
	hp            = 250
	damage        = 15
	_sep_radius   = 60.0
	_sep_strength = 90.0
	_build_visual()

func _build_visual() -> void:
	var N   := 5
	var pts := PackedVector2Array()
	for i in N:
		var a := 2.0 * PI * i / N - PI / 2.0
		pts.append(Vector2(cos(a), sin(a)) * 24.0)
	_body_poly = Polygon2D.new()
	_body_poly.polygon = pts
	_body_poly.color   = Color(0.9, 0.75, 0.1, 1.0)
	add_child(_body_poly)

func _tint(color: Color) -> void:
	if _body_poly:
		_body_poly.color = color

func _normal_tint() -> Color:
	return Color(0.9, 0.75, 0.1, 1.0)

func _ai(delta: float) -> void:
	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_do_wander(delta)
		return

	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = SUMMON_CD
		_do_summon()

	var to_player := player.global_position - global_position
	var dist      := to_player.length()
	var move_dir  : Vector2
	if dist < FLEE_DIST:
		move_dir = -to_player.normalized()
	elif dist > DESIRED_DIST + 80.0:
		move_dir = to_player.normalized() * 0.4
	else:
		move_dir = to_player.normalized().rotated(PI * 0.5) * 0.3
	velocity = move_dir * speed * _slow_factor * _boost_factor
	move_and_slide()

func _do_summon() -> void:
	var arena := get_parent()
	if arena == null:
		return
	for _i in 2:
		var a := ALDRICH_SCENE.instantiate()
		arena.add_child(a)
		a.hp     = summon_damage * 3
		a.damage = summon_damage
		a.speed  = 100.0
		a.position = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		a.died.connect(func(): if is_instance_valid(arena): arena.call("_on_enemy_died", "aldrich"))
		a.died.connect(func(): if is_instance_valid(arena): arena.call("_try_drop_key", a))

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(2.0, 5.0)
	velocity = _wander_dir * speed * 0.5 + _separation()
	move_and_slide()

func _die() -> void:
	super._die()
	$CollisionShape2D.set_deferred("disabled", true)
	if _body_poly:
		var tween := create_tween()
		tween.tween_property(_body_poly, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
