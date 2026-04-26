extends "res://scenes/entities/BaseEnemy.gd"

const FLEE_RADIUS  := 380.0
const DESIRED_DIST := 680.0
const AURA_RADIUS  := 280.0
const SPEED_BOOST  := 0.40
const BUFF_INTERVAL := 0.5

var _buff_timer := 0.0
var _pulse_time := 0.0
var _body_poly  : Polygon2D = null

func _setup() -> void:
	hp    = 80
	speed = 130.0
	add_to_group("boosters")
	_build_visual()

func _build_visual() -> void:
	var N := 24
	var body_pts := PackedVector2Array()
	for i in N:
		var a := 2.0 * PI * i / N
		body_pts.append(Vector2(cos(a), sin(a)) * 22.0)
	_body_poly = Polygon2D.new()
	_body_poly.polygon = body_pts
	_body_poly.color   = Color(0.55, 0.1, 0.9, 1.0)
	add_child(_body_poly)

	var dot_pts := PackedVector2Array()
	for i in 12:
		var a := 2.0 * PI * i / 12
		dot_pts.append(Vector2(cos(a), sin(a)) * 6.0)
	var dot := Polygon2D.new()
	dot.polygon = dot_pts
	dot.color   = Color(0.95, 0.8, 1.0, 0.9)
	add_child(dot)

func _tint(color: Color) -> void:
	if _body_poly:
		_body_poly.color = color

func _normal_tint() -> Color:
	return Color(0.55, 0.1, 0.9, 1.0)

func _ai(delta: float) -> void:
	_pulse_time += delta
	if _body_poly:
		var pulse := 0.85 + 0.15 * sin(_pulse_time * 4.0)
		_body_poly.scale = Vector2(pulse, pulse)

	_buff_timer -= delta
	if _buff_timer <= 0.0:
		_buff_timer = BUFF_INTERVAL
		_apply_aura()

	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_do_wander(delta)
		return

	var to_player: Vector2 = (player as Node2D).global_position - global_position
	var dist: float = to_player.length()
	var move_dir: Vector2
	if dist < FLEE_RADIUS:
		move_dir = -to_player.normalized()
	elif dist > DESIRED_DIST + 120.0:
		move_dir = to_player.normalized() * 0.35
	else:
		move_dir = to_player.normalized().rotated(PI * 0.5) * 0.4
	velocity = move_dir * speed * _slow_factor
	move_and_slide()
	global_position = global_position.clamp(ARENA_MIN, ARENA_MAX)

func _apply_aura() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self:
			continue
		var e := enemy as Node2D
		if global_position.distance_to(e.global_position) <= AURA_RADIUS:
			if enemy.has_method("apply_booster_buff"):
				enemy.apply_booster_buff(SPEED_BOOST, BUFF_INTERVAL * 2.5)

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(2.0, 4.5)
	velocity = _wander_dir * speed * 0.4
	move_and_slide()
	global_position = global_position.clamp(ARENA_MIN, ARENA_MAX)

func _die() -> void:
	super._die()
	$CollisionShape2D.set_deferred("disabled", true)
	_tint(Color(0.3, 0.1, 0.4, 0.4))
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(self):
		queue_free()
