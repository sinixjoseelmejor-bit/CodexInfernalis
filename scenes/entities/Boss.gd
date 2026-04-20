extends CharacterBody2D

signal died

const SPEED         := 40.0
const SHOOT_CD      := 0.4
const STORM_CD      := 3.5
const ARENA_MIN     := Vector2(130, 120)
const ARENA_MAX     := Vector2(1890, 930)
const BULLET        := preload("res://scenes/entities/BrutusBullet.tscn")
const WALK_BASE     := "res://assets/Characters/Brutus/animations/The_demon_shifts_its_weight_and_begins_to_walk_for-427ed1f1/"
const ROT_BASE      := "res://assets/Characters/Brutus/rotations/"
const WALK_FRAMES   := 9

var hp     := 250
var damage := 1
var dead   := false

var player       : Node2D = null
var _last_dir    := "south"
var _shoot_timer := 0.0
var _storm_timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("enemies")
	collision_layer = 2
	collision_mask  = 0
	_setup_animations()

func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	var dirs   := ["south","north","east","west","south-east","south-west","north-east","north-west"]
	for dir in dirs:
		var d: String = (dir as String).replace("-", "_")
		var walk := "walk_" + d
		frames.add_animation(walk)
		frames.set_animation_speed(walk, 8.0)
		for i in WALK_FRAMES:
			frames.add_frame(walk, load(WALK_BASE + dir + "/frame_%03d.png" % i))
		var idle := "idle_" + d
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 5.0)
		frames.add_frame(idle, load(ROT_BASE + dir + ".png"))
	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("idle_south")

func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	_shoot_timer -= delta
	_storm_timer -= delta

	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		return

	var to_player := player.global_position - global_position
	var dir       := to_player.normalized()

	velocity = dir * SPEED
	move_and_slide()
	global_position = global_position.clamp(ARENA_MIN, ARENA_MAX)
	_update_dir(dir)
	$AnimatedSprite2D.play("walk_" + _last_dir)

	if _shoot_timer <= 0.0:
		_shoot(dir)
		_shoot_timer = SHOOT_CD

	if _storm_timer <= 0.0:
		_shoot_storm()
		_storm_timer = STORM_CD

func _shoot(dir: Vector2) -> void:
	var b := BULLET.instantiate()
	b.global_position = global_position
	b.init(dir, damage)
	get_parent().call_deferred("add_child", b)

func _shoot_storm() -> void:
	for i in 8:
		var angle := i * PI / 4.0
		var dir   := Vector2(cos(angle), sin(angle))
		var b     := BULLET.instantiate()
		b.global_position = global_position
		b.init(dir, damage)
		get_parent().call_deferred("add_child", b)

func _update_dir(dir: Vector2) -> void:
	if   dir.x > 0.5  and abs(dir.y) < 0.4:  _last_dir = "east"
	elif dir.x < -0.5 and abs(dir.y) < 0.4:  _last_dir = "west"
	elif dir.y < -0.5 and abs(dir.x) < 0.4:  _last_dir = "north"
	elif dir.y > 0.5  and abs(dir.x) < 0.4:  _last_dir = "south"
	elif dir.x > 0.3  and dir.y < -0.3:       _last_dir = "north_east"
	elif dir.x < -0.3 and dir.y < -0.3:       _last_dir = "north_west"
	elif dir.x > 0.3  and dir.y > 0.3:        _last_dir = "south_east"
	elif dir.x < -0.3 and dir.y > 0.3:        _last_dir = "south_west"

func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	if hp <= 0:
		_die()

func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	died.emit()
	queue_free()
