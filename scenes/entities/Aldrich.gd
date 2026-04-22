extends CharacterBody2D

signal died

var speed  := 90.0
var hp     := 3
var damage := 1
var dead   := false
var player: Node2D = null
var _wander_dir := Vector2.RIGHT
var _wander_timer := 0.0

var _slow_factor := 1.0
var _slow_timer  := 0.0
var _bleed_dmg   := 0
var _bleed_timer := 0.0
var _bleed_tick  := 0.0

const ARENA_MIN    := Vector2(130, 120)
const ARENA_MAX    := Vector2(1890, 930)
const SEP_RADIUS   := 58.0
const SEP_STRENGTH := 120.0

func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var diff := global_position - (other as Node2D).global_position
		var dist := diff.length()
		if dist < SEP_RADIUS and dist > 0.01:
			push += diff / dist * (SEP_RADIUS - dist) / SEP_RADIUS * SEP_STRENGTH
	return push.limit_length(speed * 1.5)

func teleport_to_edge() -> void:
	match randi() % 4:
		0: global_position = Vector2(randf_range(ARENA_MIN.x, ARENA_MAX.x), ARENA_MIN.y)
		1: global_position = Vector2(randf_range(ARENA_MIN.x, ARENA_MAX.x), ARENA_MAX.y)
		2: global_position = Vector2(ARENA_MIN.x, randf_range(ARENA_MIN.y, ARENA_MAX.y))
		_: global_position = Vector2(ARENA_MAX.x, randf_range(ARENA_MIN.y, ARENA_MAX.y))
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1, 1), 0.3)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 0
	_setup_animations()
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)

func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	var walk_base := "res://assets/Characters/Aldrich/animations/AldrichWalk-ca79f0eb/"
	var death_base := "res://assets/Characters/Aldrich/animations/AldrichDeath-7904336b/"
	var rot_base := "res://assets/Characters/Aldrich/rotations/"
	var dirs := ["south", "north", "east", "west", "south-east", "south-west", "north-east", "north-west"]

	for dir in dirs:
		var anim: String = "walk_" + (dir as String).replace("-", "_")
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 10.0)
		for i in 11:
			frames.add_frame(anim, load(walk_base + dir + "/frame_%03d.png" % i))

		var idle: String = "idle_" + (dir as String).replace("-", "_")
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 5.0)
		frames.add_frame(idle, load(rot_base + dir + ".png"))

	frames.add_animation("death")
	frames.set_animation_speed("death", 8.0)
	frames.set_animation_loop("death", false)
	for i in 11:
		frames.add_frame("death", load(death_base + "south/frame_%03d.png" % i))

	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("idle_south")

func _physics_process(delta: float) -> void:
	if dead:
		return
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_factor = 1.0
	if _bleed_timer > 0.0:
		_bleed_timer -= delta
		_bleed_tick  -= delta
		if _bleed_tick <= 0.0:
			_bleed_tick = 1.0
			take_damage(_bleed_dmg)
		if dead:
			return
		if _bleed_timer <= 0.0:
			$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	var player_dead: bool = player == null or (player as CharacterBody2D).get("_dead") == true
	if player_dead:
		_wander(delta)
	else:
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * speed * _slow_factor + _separation()
		move_and_slide()
		_update_animation(dir)

func _wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(1.5, 3.5)
	velocity = _wander_dir * speed * 0.5 + _separation()
	move_and_slide()
	_update_animation(_wander_dir)

func _update_animation(dir: Vector2) -> void:
	$AnimatedSprite2D.play("walk_" + _dir_name(dir))

func _dir_name(dir: Vector2) -> String:
	var angle := dir.angle()
	var deg := fmod(rad_to_deg(angle) + 360.0, 360.0)
	if deg < 22.5 or deg >= 337.5:   return "east"
	elif deg < 67.5:                  return "south_east"
	elif deg < 112.5:                 return "south"
	elif deg < 157.5:                 return "south_west"
	elif deg < 202.5:                 return "west"
	elif deg < 247.5:                 return "north_west"
	elif deg < 292.5:                 return "north"
	else:                             return "north_east"

func slow(factor: float, duration: float) -> void:
	_slow_factor = factor
	_slow_timer  = duration

func apply_bleed(dmg_per_s: int, duration: float) -> void:
	_bleed_dmg   = dmg_per_s
	_bleed_timer = duration
	_bleed_tick  = 1.0
	$AnimatedSprite2D.modulate = Color(1.0, 0.45, 0.0, 1.0)

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
		$AnimatedSprite2D.modulate = Color(1.0, 0.45, 0.0, 1.0) if _bleed_timer > 0.0 else Color(1, 1, 1, 1)

const DEATH_SOUND  := preload("res://sounds/sfx/Aldrich_death.mp3")

func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("death")
	died.emit()
	PlayerData.kills_total += 1
	PlayerData.save()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_kills(PlayerData.kills_total)
	var snd := AudioStreamPlayer.new()
	snd.stream     = DEATH_SOUND
	snd.volume_db  = -35.0
	snd.autoplay   = false
	add_child(snd)
	snd.play()
	snd.finished.connect(snd.queue_free)

func _on_anim_finished() -> void:
	if $AnimatedSprite2D.animation == "death":
		queue_free()
