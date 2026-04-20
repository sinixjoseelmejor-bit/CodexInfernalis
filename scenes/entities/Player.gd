extends CharacterBody2D

signal hp_changed(current: int, maximum: int)
signal died

const IFRAMES        := 0.5
const ATTACK_FRAMES  := 9
const DEATH_DELAY    := 2.5
const FIREBALL       := preload("res://scenes/entities/Fireball.tscn")
const FIRE_TRAIL     := preload("res://scenes/entities/FireTrail.tscn")
const GRENADE        := preload("res://scenes/entities/Grenade.tscn")

const GRENADE_CD          := 8.0
const TRAIL_CD            := 0.15
const RAGE_DURATION       := 2.0
const STORM_CD            := 15.0
const TEMPETE_CD          := 10.0
const MOUSE_OVERRIDE_DUR  := 2.0
const AUTO_AIM_RANGE      := 400.0

var hp                  := 5
var last_direction      := "south"
var _aim_direction      := "south"
var _fire_timer         := 0.0
var _iframe_timer       := 0.0
var _attacking          := false
var _dead               := false
var _heal_accumulator   := 0.0
var _grenade_timer      := 0.0
var _trail_timer        := 0.0
var _rage_timer         := 0.0
var _enraged            := false
var _storm_timer        := 0.0
var _tempete_timer      := 0.0
var _pending_shot_dir      := Vector2.ZERO
var _waiting_to_shoot      := false
var _mouse_override_timer  := 0.0
var _last_aim_dir          := Vector2.DOWN

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("player")
	hp = PlayerData.max_hp
	_setup_animations()
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)
	$HitArea.body_entered.connect(_on_body_entered)

func _input(event: InputEvent) -> void:
	if _dead:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_mouse_override_timer = MOUSE_OVERRIDE_DUR

func _get_aim_dir() -> Vector2:
	if PlayerData.touch_shooting and PlayerData.touch_aim_world != Vector2.ZERO:
		return PlayerData.touch_aim_world - global_position
	if _mouse_override_timer > 0.0:
		return get_global_mouse_position() - global_position
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := INF
	for e in enemies:
		if (e as Node2D).get("dead") == true:
			continue
		var d := global_position.distance_to((e as Node2D).global_position)
		if d < nearest_dist and d <= AUTO_AIM_RANGE:
			nearest_dist = d
			nearest = e
	if nearest:
		return nearest.global_position - global_position
	return Vector2.ZERO

func _setup_animations() -> void:
	var frames  := SpriteFrames.new()
	var run_b   := "res://assets/Characters/Masqued_Neophyte/animations/Running-dc016826/"
	var atk_b   := "res://assets/Characters/Masqued_Neophyte/animations/FireballSummon-e753ce67/"
	var death_b := "res://assets/Characters/Masqued_Neophyte/animations/animation-0817bd7e/"
	var rot_b   := "res://assets/Characters/Masqued_Neophyte/rotations/"
	var dirs    := ["south","north","east","west","south-east","south-west","north-east","north-west"]

	for dir in dirs:
		var d := (dir as String).replace("-", "_")

		var run: String = "run_" + d
		frames.add_animation(run)
		frames.set_animation_speed(run, 10.0)
		for i in 8:
			frames.add_frame(run, load(run_b + dir + "/frame_%03d.png" % i))

		var atk: String = "attack_" + d
		frames.add_animation(atk)
		frames.set_animation_speed(atk, ATTACK_FRAMES / PlayerData.fire_cd)
		frames.set_animation_loop(atk, false)
		for i in 9:
			frames.add_frame(atk, load(atk_b + dir + "/frame_%03d.png" % i))

		var idle: String = "idle_" + d
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 5.0)
		frames.add_frame(idle, load(rot_b + dir + ".png"))

	frames.add_animation("death")
	frames.set_animation_speed("death", 8.0)
	frames.set_animation_loop("death", false)
	for i in 9:
		frames.add_frame("death", load(death_b + "south/frame_%03d.png" % i))

	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("idle_south")

func _draw() -> void:
	if Input.is_physical_key_pressed(KEY_ALT):
		draw_arc(Vector2.ZERO, AUTO_AIM_RANGE, 0.0, TAU, 64, Color(0.6, 0.9, 1.0, 0.5), 2.0)

func _physics_process(delta: float) -> void:
	queue_redraw()
	if _dead:
		return

	_fire_timer   -= delta
	_iframe_timer -= delta

	if _enraged:
		_rage_timer -= delta
		if _rage_timer <= 0.0:
			_enraged = false

	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):  dir.x += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):   dir.x -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):   dir.y += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):     dir.y -= 1
	if dir == Vector2.ZERO and PlayerData.touch_move.length() > 0.1:
		dir = PlayerData.touch_move

	velocity = dir.normalized() * PlayerData.speed if dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

	if dir != Vector2.ZERO:
		_update_dir(dir)
		_try_fire_trail(delta)
	else:
		_trail_timer = 0.0

	_mouse_override_timer -= delta

	if _fire_timer <= 0.0:
		_shoot()
		_fire_timer = PlayerData.fire_cd

	if _waiting_to_shoot and $AnimatedSprite2D.frame >= 1:
		_waiting_to_shoot = false
		_spawn_bullet(_pending_shot_dir, global_position)
		if PlayerData.has_skill("double_tir"):
			var perp := _pending_shot_dir.normalized().rotated(PI * 0.5) * 18.0
			_spawn_bullet(_pending_shot_dir, global_position + perp)

	if not _attacking:
		_play_move_anim(dir)

	if PlayerData.item_count("auto_grenade") > 0:
		_grenade_timer += delta
		if _grenade_timer >= GRENADE_CD:
			_grenade_timer = 0.0
			_launch_grenade()

	if PlayerData.item_count("storm_ring") > 0:
		_storm_timer += delta
		if _storm_timer >= STORM_CD:
			_storm_timer = 0.0
			_launch_storm()

	if PlayerData.has_skill("tempete_acier"):
		_tempete_timer += delta
		if _tempete_timer >= TEMPETE_CD:
			_tempete_timer = 0.0
			_launch_tempete()

func _effective_damage() -> int:
	return int(PlayerData.damage * (1.5 if _enraged else 1.0))

func _vec_to_dir_name(v: Vector2) -> String:
	var deg := fmod(rad_to_deg(v.angle()) + 360.0, 360.0)
	if   deg < 22.5 or deg >= 337.5: return "east"
	elif deg < 67.5:                  return "south_east"
	elif deg < 112.5:                 return "south"
	elif deg < 157.5:                 return "south_west"
	elif deg < 202.5:                 return "west"
	elif deg < 247.5:                 return "north_west"
	elif deg < 292.5:                 return "north"
	else:                             return "north_east"

func _spawn_bullet(dir: Vector2, pos: Vector2) -> void:
	var fb := FIREBALL.instantiate()
	get_parent().add_child(fb)
	fb.global_position = pos
	fb.init(dir, _effective_damage())

func _shoot() -> void:
	var aim_dir := _get_aim_dir()
	if aim_dir == Vector2.ZERO:
		return
	_last_aim_dir     = aim_dir
	_attacking        = true
	_pending_shot_dir = aim_dir
	_waiting_to_shoot = true
	_aim_direction    = _vec_to_dir_name(aim_dir)
	var atk_anim := "attack_" + _aim_direction
	$AnimatedSprite2D.sprite_frames.set_animation_speed(atk_anim, ATTACK_FRAMES / PlayerData.fire_cd)
	$AnimatedSprite2D.play(atk_anim)

func _try_fire_trail(delta: float) -> void:
	if PlayerData.item_count("fire_boots") <= 0:
		return
	_trail_timer += delta
	if _trail_timer >= TRAIL_CD:
		_trail_timer = 0.0
		var trail := FIRE_TRAIL.instantiate()
		get_parent().add_child(trail)
		trail.global_position = global_position + Vector2(0, 18)

func _launch_grenade() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var target := global_position + Vector2(randf_range(-300, 300), randf_range(-300, 300))
	if not enemies.is_empty():
		var nearest: Node2D = enemies[0]
		for e in enemies:
			if global_position.distance_to((e as Node2D).global_position) < global_position.distance_to(nearest.global_position):
				nearest = e
		target = nearest.global_position
	var g := GRENADE.instantiate()
	get_parent().add_child(g)
	g.global_position = global_position
	g.init(target)

func _launch_tempete() -> void:
	for i in 12:
		var angle := i * TAU / 12.0
		var dir   := Vector2(cos(angle), sin(angle))
		_spawn_bullet(dir, global_position)

func _launch_storm() -> void:
	var count := PlayerData.item_count("storm_ring")
	var shots := 8 * count
	for i in shots:
		var angle := i * TAU / shots
		var dir := Vector2(cos(angle), sin(angle))
		var fb := FIREBALL.instantiate()
		get_parent().add_child(fb)
		fb.global_position = global_position
		fb.init(dir, _effective_damage())

func on_enemy_hit(dmg: int) -> void:
	var stacks := PlayerData.item_count("vampire_amulet")
	if stacks <= 0 or _dead:
		return
	_heal_accumulator += dmg * 0.01 * stacks
	if _heal_accumulator >= 1.0:
		_heal_accumulator -= 1.0
		hp = min(hp + 1, PlayerData.max_hp)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.refresh_hp(hp, PlayerData.max_hp)
		hp_changed.emit(hp, PlayerData.max_hp)

func on_enemy_kill() -> void:
	if PlayerData.item_count("rage_ring") <= 0 or _dead:
		return
	_enraged = true
	_rage_timer = RAGE_DURATION

func _on_anim_finished() -> void:
	var anim: String = $AnimatedSprite2D.animation
	if anim.begins_with("attack"):
		_attacking = false
		$AnimatedSprite2D.play("idle_" + _aim_direction)
	elif anim == "death":
		await get_tree().create_timer(DEATH_DELAY).timeout
		died.emit()

func take_damage(amount: int) -> void:
	if _dead or _iframe_timer > 0.0:
		return
	var phantom := PlayerData.item_count("phantom_step")
	_iframe_timer = IFRAMES + 1.0 * phantom
	hp = max(0, hp - amount)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_hp(hp, PlayerData.max_hp)
	hp_changed.emit(hp, PlayerData.max_hp)
	_flash_damage()
	_thorn_reflect(amount)
	if hp == 0:
		_die()

func _flash_damage() -> void:
	$AnimatedSprite2D.modulate = Color(1.0, 0.15, 0.15, 1.0)
	await get_tree().create_timer(0.12).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)

func _thorn_reflect(original_dmg: int) -> void:
	var stacks := PlayerData.item_count("thorn_shield")
	if stacks <= 0:
		return
	var reflect := int(ceil(original_dmg * 0.15 * stacks))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to((enemy as Node2D).global_position) <= 280.0:
			enemy.take_damage(reflect)

func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	$HitArea/HitShape.set_deferred("disabled", true)
	$AnimatedSprite2D.play("death")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		take_damage(body.get("damage") if body.get("damage") != null else 1)

func _update_dir(dir: Vector2) -> void:
	if   dir.x > 0 and dir.y == 0:  last_direction = "east"
	elif dir.x < 0 and dir.y == 0:  last_direction = "west"
	elif dir.x == 0 and dir.y < 0:  last_direction = "north"
	elif dir.x == 0 and dir.y > 0:  last_direction = "south"
	elif dir.x > 0 and dir.y < 0:   last_direction = "north_east"
	elif dir.x < 0 and dir.y < 0:   last_direction = "north_west"
	elif dir.x > 0 and dir.y > 0:   last_direction = "south_east"
	elif dir.x < 0 and dir.y > 0:   last_direction = "south_west"

func _play_move_anim(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		$AnimatedSprite2D.play("idle_" + last_direction)
	else:
		$AnimatedSprite2D.play("run_" + last_direction)
