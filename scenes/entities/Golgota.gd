extends CharacterBody2D

signal died

const ARENA_MIN    := Vector2(130, 120)
const ARENA_MAX    := Vector2(1890, 930)
const WALK_BASE    := "res://assets/Characters/Golgota/animations/animation-07a6a005/south/"
const ROT_BASE     := "res://assets/Characters/Golgota/rotations/"
const WALK_FRAMES  := 6
const ORB          := preload("res://scenes/entities/GolgotaOrb.tscn")
const LASER        := preload("res://scenes/entities/GolgotaLaser.tscn")
const BOSS_SOUL    := preload("res://scenes/entities/BossSoul.tscn")
const ALDRICH      := preload("res://scenes/entities/Aldrich.tscn")
const SHOCKWAVE    := preload("res://scenes/entities/GolgotaShockwave.gd")
const MAX_HP        := 1800
const SHOCKWAVE_CD  := 8.0
const SHOCKWAVE_DMG := 20
# "Carapace d'Orgueil" — plafonne chaque coup pour lisser les builds burst
const DMG_CAP       := 60

var hp            := MAX_HP
var damage        := 30
var laser_damage  := 25
var dead          := false

var player        : Node2D = null
var _last_dir     := "south"
var _orb_timer    := 2.0
var _laser_timer  := 4.0
const LASER_ACTIVE_DUR := 0.5  # must match GolgotaLaser.ACTIVE

var _laser_active := false

# Phase — 3=full HP, 2=mid, 1=critical
var _phase           := 3
var _cur_orb_cd      := 2.5
var _cur_laser_cd    := 6.0
var _cur_orb_count   := 5
var _cur_speed       := 35.0
var _cur_telegraph   := 1.2
var _spawn_cd        := 0.0
var _spawn_timer     := 0.0
var _shockwave_timer := SHOCKWAVE_CD

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("enemies")
	collision_layer = 2
	collision_mask  = 0
	_setup_animations()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_boss_bar(hp)

func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	var dirs := ["south", "north", "east", "west", "south-east", "south-west", "north-east", "north-west"]

	frames.add_animation("walk")
	frames.set_animation_speed("walk", 8.0)
	for i in WALK_FRAMES:
		frames.add_frame("walk", load(WALK_BASE + "frame_%03d.png" % i))

	for dir in dirs:
		var idle := "idle_" + (dir as String).replace("-", "_")
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 1.0)
		frames.add_frame(idle, load(ROT_BASE + dir + ".png"))

	var death_sheet := load("res://assets/Characters/Golgota/animations/Golgota Death.png") as Texture2D
	frames.add_animation("death")
	frames.set_animation_speed("death", 10.0)
	frames.set_animation_loop("death", false)
	for i in 17:
		var atlas := AtlasTexture.new()
		atlas.atlas = death_sheet
		atlas.region = Rect2(float(i % 5) * 160.0, float(i / 5) * 160.0, 160.0, 160.0)
		frames.add_frame("death", atlas)

	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("idle_south")

func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle_" + _last_dir)
		return

	if not _laser_active:
		_orb_timer   -= delta
		_laser_timer -= delta
		if _spawn_cd > 0.0:
			_spawn_timer -= delta

	var to_player := player.global_position - global_position
	var dir       := to_player.normalized()

	if not _laser_active:
		velocity = dir * _cur_speed
		move_and_slide()
		global_position = global_position.clamp(ARENA_MIN, ARENA_MAX)
		_update_dir(dir)
		$AnimatedSprite2D.play("walk")

		if _orb_timer <= 0.0:
			_spawn_orbs()
			_orb_timer = _cur_orb_cd

		if _laser_timer <= 0.0:
			_fire_lasers(dir)
			_laser_timer = _cur_laser_cd

		if _spawn_cd > 0.0 and _spawn_timer <= 0.0:
			_spawn_enemies()
			_spawn_timer = _spawn_cd

		if _phase == 1:
			_shockwave_timer -= delta
			if _shockwave_timer <= 0.0:
				_fire_shockwave()
				_shockwave_timer = SHOCKWAVE_CD
	else:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle_" + _last_dir)

# ── Laser spread angles per phase ───────────────────────────────────────────

func _laser_angles() -> Array:
	match _phase:
		1: return [0.0, deg_to_rad(-30.0), deg_to_rad(30.0), deg_to_rad(-65.0), deg_to_rad(65.0)]
		2: return [0.0, deg_to_rad(-40.0), deg_to_rad(40.0)]
		_: return [0.0]

func _fire_lasers(base_dir: Vector2) -> void:
	_laser_active = true
	velocity = Vector2.ZERO
	var angles := _laser_angles()
	for i in angles.size():
		var lsr := LASER.instantiate()
		lsr.global_position = global_position
		# Only the center laser (i==0) tracks the player; others keep their fixed spread angle
		lsr.init(base_dir.rotated(angles[i]), laser_damage, _cur_telegraph, i == 0)
		get_parent().call_deferred("add_child", lsr)
	# Reset via timer — avoids fragile signal counting across deferred nodes
	var reset_delay := _cur_telegraph + LASER_ACTIVE_DUR + 0.1
	get_tree().create_timer(reset_delay).timeout.connect(
		func() -> void:
			if is_instance_valid(self):
				_laser_active = false
	)

# ── Orbs ─────────────────────────────────────────────────────────────────────

func _spawn_orbs() -> void:
	for _i in _cur_orb_count:
		var orb   := ORB.instantiate()
		var angle := randf_range(0.0, TAU)
		var dist  := randf_range(150.0, 420.0)
		orb.global_position = (global_position + Vector2(cos(angle), sin(angle)) * dist).clamp(ARENA_MIN, ARENA_MAX)
		get_parent().call_deferred("add_child", orb)

# ── Shockwave (phase 1) ──────────────────────────────────────────────────────

func _fire_shockwave() -> void:
	var shock := SHOCKWAVE.new()
	shock.global_position = global_position
	shock.damage = SHOCKWAVE_DMG
	get_parent().call_deferred("add_child", shock)

# ── Enemy spawn attack ────────────────────────────────────────────────────────

func _spawn_enemies() -> void:
	var count := 3 if _phase == 2 else 5
	for _i in count:
		var enemy := ALDRICH.instantiate()
		var angle := randf_range(0.0, TAU)
		var dist  := randf_range(180.0, 350.0)
		var origin := player.global_position if player != null else global_position
		enemy.global_position = (origin + Vector2(cos(angle), sin(angle)) * dist).clamp(ARENA_MIN, ARENA_MAX)
		get_parent().call_deferred("add_child", enemy)

# ── Phase transitions ─────────────────────────────────────────────────────────

func _check_phase() -> void:
	var pct := float(hp) / float(MAX_HP)
	var new_phase := 3 if pct > 0.66 else (2 if pct > 0.33 else 1)
	if new_phase == _phase:
		return
	_phase = new_phase
	match _phase:
		2:
			_cur_orb_count  = 8
			_cur_orb_cd     = 2.0
			_cur_laser_cd   = 4.5
			_cur_speed      = 48.0
			_cur_telegraph  = 0.9
			_spawn_cd       = 12.0
			_spawn_timer    = 12.0
		1:
			_cur_orb_count  = 12
			_cur_orb_cd     = 1.5
			_cur_laser_cd   = 3.0
			_cur_speed      = 60.0
			_cur_telegraph  = 0.6
			_spawn_cd       = 7.0
			_spawn_timer    = 7.0

# ── Utils ─────────────────────────────────────────────────────────────────────

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
	hp -= mini(amount, DMG_CAP)
	_flash_hit()
	_check_phase()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_boss_hp(hp)
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
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.hide_boss_bar()
	var soul := BOSS_SOUL.instantiate()
	soul.global_position = global_position
	get_parent().call_deferred("add_child", soul)
	died.emit()
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	queue_free()
