extends "res://scenes/entities/BaseEnemy.gd"

const DEATH_SOUND := preload("res://sounds/sfx/Brutus_Death.mp3")
const WALK_BASE   := "res://assets/Characters/Brutus/animations/The_demon_shifts_its_weight_and_begins_to_walk_for-427ed1f1/"
const ROT_BASE    := "res://assets/Characters/Brutus/rotations/"
const WALK_FRAMES := 9

var shoot_range  := 500.0
var shoot_cd     := 0.60
var bullet_speed := 280.0
var _last_dir    := "south"
var _shoot_timer := 0.0

func _setup() -> void:
	speed         = 55.0
	hp            = 15
	damage        = 1
	_sep_radius   = 68.0
	_sep_strength = 110.0
	_setup_animations()
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)

func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	var dirs   := ["south","north","east","west","south-east","south-west","north-east","north-west"]
	for dir in dirs:
		var d: String = (dir as String).replace("-", "_")

		var walk := "walk_" + d
		frames.add_animation(walk)
		frames.set_animation_speed(walk, 10.0)
		for i in WALK_FRAMES:
			frames.add_frame(walk, load(WALK_BASE + dir + "/frame_%03d.png" % i))

		var idle := "idle_" + d
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 5.0)
		frames.add_frame(idle, load(ROT_BASE + dir + ".png"))

	var death_sheet := load("res://assets/Characters/Brutus/animations/BrutusDeath/DeathBrutus.png")
	frames.add_animation("death")
	frames.set_animation_speed("death", 8.0)
	frames.set_animation_loop("death", false)
	var frame_cols := [4, 4, 3]
	for row in 3:
		for col in frame_cols[row]:
			var atlas := AtlasTexture.new()
			atlas.atlas  = death_sheet
			atlas.region = Rect2(col * 120, row * 120, 120, 120)
			frames.add_frame("death", atlas)

	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("idle_south")

func teleport_to_edge() -> void:
	super.teleport_to_edge()
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1, 1), 0.3)

func _tint(color: Color) -> void:
	$AnimatedSprite2D.modulate = color

const DESIRED_DIST := 380.0
const FLEE_DIST    := 220.0

func _ai(delta: float) -> void:
	_shoot_timer -= delta
	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_do_wander(delta)
		return

	var to_player := player.global_position - global_position
	var dist      := to_player.length()
	var move_dir  : Vector2

	if dist < FLEE_DIST:
		move_dir = -to_player.normalized()
	elif dist > DESIRED_DIST + 80.0:
		move_dir = _nav_dir_to(player.global_position)
	else:
		move_dir = to_player.normalized().rotated(PI * 0.5) * 0.3

	velocity = move_dir * speed * _slow_factor * _boost_factor + _separation()
	move_and_slide()
	if move_dir.length_squared() > 0.01:
		_update_dir(move_dir)
	var in_shoot_zone := dist >= FLEE_DIST and dist <= DESIRED_DIST + 80.0
	if in_shoot_zone:
		$AnimatedSprite2D.play("idle_" + _last_dir)
	else:
		$AnimatedSprite2D.play("walk_" + _last_dir)

	if dist <= shoot_range and _shoot_timer <= 0.0:
		_shoot(to_player.normalized())
		_shoot_timer = shoot_cd

func _shoot(dir: Vector2) -> void:
	var b := BulletPool.get_brutus_bullet(get_parent())
	b.global_position = global_position
	b.init(dir, damage, bullet_speed)

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(2.0, 4.5)
	velocity = _wander_dir * speed * 0.5 * _boost_factor + _separation()
	move_and_slide()
	_update_dir(_wander_dir)
	$AnimatedSprite2D.play("walk_" + _last_dir)

func _update_dir(dir: Vector2) -> void:
	if   dir.x > 0.5  and abs(dir.y) < 0.4:  _last_dir = "east"
	elif dir.x < -0.5 and abs(dir.y) < 0.4:  _last_dir = "west"
	elif dir.y < -0.5 and abs(dir.x) < 0.4:  _last_dir = "north"
	elif dir.y > 0.5  and abs(dir.x) < 0.4:  _last_dir = "south"
	elif dir.x > 0.3  and dir.y < -0.3:       _last_dir = "north_east"
	elif dir.x < -0.3 and dir.y < -0.3:       _last_dir = "north_west"
	elif dir.x > 0.3  and dir.y > 0.3:        _last_dir = "south_east"
	elif dir.x < -0.3 and dir.y > 0.3:        _last_dir = "south_west"

func _die() -> void:
	super._die()
	$CollisionPolygon2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("death")
	var snd := AudioStreamPlayer.new()
	snd.stream    = DEATH_SOUND
	snd.volume_db = -15.0
	get_parent().add_child(snd)
	snd.play()
	snd.finished.connect(snd.queue_free)

func _on_anim_finished() -> void:
	if $AnimatedSprite2D.animation == "death":
		queue_free()
