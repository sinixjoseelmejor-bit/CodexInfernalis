extends CharacterBody2D

signal died

const SPEED        := 55.0
const SHOOT_RANGE  := 500.0
const SHOOT_CD     := 0.6
const ARENA_MIN    := Vector2(130, 120)
const ARENA_MAX    := Vector2(1890, 930)
const BULLET       := preload("res://scenes/entities/BrutusBullet.tscn")
const DEATH_SOUND  := preload("res://sounds/sfx/Brutus_Death.mp3")
const WALK_BASE    := "res://assets/Characters/Brutus/animations/The_demon_shifts_its_weight_and_begins_to_walk_for-427ed1f1/"
const ROT_BASE     := "res://assets/Characters/Brutus/rotations/"
const WALK_FRAMES  := 9

var hp     := 15
var damage := 1
var dead   := false

var player        : Node2D = null
var _last_dir     := "south"
var _shoot_timer  := 0.0
var _wander_dir   := Vector2.RIGHT
var _wander_timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("enemies")
	collision_layer = 2
	collision_mask  = 0
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

func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	_shoot_timer -= delta

	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_wander(delta)
		return

	var to_player := player.global_position - global_position
	var dist      := to_player.length()
	var dir       := to_player.normalized()

	velocity = dir * SPEED
	move_and_slide()
	global_position = global_position.clamp(ARENA_MIN, ARENA_MAX)
	_update_dir(dir)
	$AnimatedSprite2D.play("walk_" + _last_dir)

	if dist <= SHOOT_RANGE and _shoot_timer <= 0.0:
		_shoot(dir)
		_shoot_timer = SHOOT_CD

func _shoot(dir: Vector2) -> void:
	var b := BULLET.instantiate()
	b.global_position = global_position
	b.init(dir, damage)
	get_parent().call_deferred("add_child", b)

func _wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(2.0, 4.5)
	velocity = _wander_dir * SPEED * 0.5
	move_and_slide()
	global_position = global_position.clamp(ARENA_MIN, ARENA_MAX)
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

func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	_flash_hit()
	if hp <= 0:
		_die()

func _flash_hit() -> void:
	$AnimatedSprite2D.modulate = Color(1.0, 0.1, 0.1, 1.0)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)

func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	$CollisionPolygon2D.set_deferred("disabled", true)
	died.emit()
	PlayerData.kills_total += 1
	PlayerData.save()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_kills(PlayerData.kills_total)
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
