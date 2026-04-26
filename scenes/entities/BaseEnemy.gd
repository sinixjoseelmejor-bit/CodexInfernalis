extends CharacterBody2D
class_name BaseEnemy

const _FX_POISON := preload("res://scenes/effects/FxPoison.tscn")


signal died

const ARENA_MIN := Vector2(130, 120)
const ARENA_MAX := Vector2(1890, 930)

var hp     := 1
var damage := 1
var speed  := 100.0
var dead    := false
var grabbed := false
var player : Node2D = null

var _slow_factor  := 1.0
var _slow_timer   := 0.0
var _boost_factor := 1.0
var _boost_timer  := 0.0
var _bleed_dmg    := 0
var _bleed_timer  := 0.0
var _bleed_tick   := 0.0
@warning_ignore("unused_private_class_variable")
var _wander_dir   := Vector2.RIGHT
@warning_ignore("unused_private_class_variable")
var _wander_timer := 0.0
var _sep_radius   := 60.0
var _sep_strength := 120.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("enemies")
	collision_layer = 2
	collision_mask  = 0
	_setup()

func _setup() -> void:
	pass

func _physics_process(delta: float) -> void:
	if dead:
		return
	_tick_status(delta)
	if dead:
		return
	if grabbed:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	_ai(delta)

func _tick_status(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0
	if _boost_timer > 0.0:
		_boost_timer -= delta
		if _boost_timer <= 0.0:
			_boost_factor = 1.0
			if not dead and _bleed_timer <= 0.0:
				_tint(_normal_tint())
	if _bleed_timer > 0.0:
		_bleed_timer -= delta
		_bleed_tick  -= delta
		if _bleed_tick <= 0.0:
			_bleed_tick = 1.0
			take_damage(_bleed_dmg)
		if dead:
			return
		if _bleed_timer <= 0.0:
			_tint(_normal_tint())
			var fx := get_node_or_null("_poison_fx")
			if fx:
				fx.queue_free()

func _ai(_delta: float) -> void:
	pass

func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var diff := global_position - (other as Node2D).global_position
		var dist := diff.length()
		if dist < _sep_radius and dist > 0.01:
			push += diff / dist * (_sep_radius - dist) / _sep_radius * _sep_strength
	return push.limit_length(speed * 1.5)

func teleport_to_edge() -> void:
	match randi() % 4:
		0: global_position = Vector2(randf_range(ARENA_MIN.x, ARENA_MAX.x), ARENA_MIN.y)
		1: global_position = Vector2(randf_range(ARENA_MIN.x, ARENA_MAX.x), ARENA_MAX.y)
		2: global_position = Vector2(ARENA_MIN.x, randf_range(ARENA_MIN.y, ARENA_MAX.y))
		_: global_position = Vector2(ARENA_MAX.x, randf_range(ARENA_MIN.y, ARENA_MAX.y))

func slow(factor: float, duration: float) -> void:
	_slow_factor = factor
	_slow_timer  = duration

func apply_booster_buff(factor: float, duration: float) -> void:
	_boost_factor = 1.0 + factor
	_boost_timer  = duration
	if not dead and _bleed_timer <= 0.0:
		_tint(Color(0.75, 0.45, 1.0, 1.0))

func apply_bleed(dmg_per_s: int, duration: float) -> void:
	_bleed_dmg   = dmg_per_s
	_bleed_timer = duration
	_bleed_tick  = 1.0
	_tint(Color(0.2, 0.85, 0.1, 1.0))
	if not has_node("_poison_fx"):
		var fx := _FX_POISON.instantiate()
		fx.name = "_poison_fx"
		add_child(fx)

func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	_flash_hit()
	if hp <= 0:
		_die()

func _flash_hit() -> void:
	_tint(Color(1.0, 0.1, 0.1, 1.0))
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and not dead:
		_tint(Color(0.2, 0.85, 0.1, 1.0) if _bleed_timer > 0.0 else _normal_tint())

func _tint(_color: Color) -> void:
	pass

func _normal_tint() -> Color:
	return Color(1, 1, 1, 1)

func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	_tint(_normal_tint())
	died.emit()
	PlayerData.kills_total += 1
	PlayerData.save()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_kills(PlayerData.kills_total)
