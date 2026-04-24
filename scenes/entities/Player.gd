extends CharacterBody2D

signal hp_changed(current: int, maximum: int)
signal died

const IFRAMES        := 0.5
const ATTACK_FRAMES  := 9
const DEATH_DELAY    := 2.5
const FIREBALL       := preload("res://scenes/entities/Fireball.tscn")
const FIRE_TRAIL     := preload("res://scenes/entities/FireTrail.tscn")
const GRENADE        := preload("res://scenes/entities/Grenade.tscn")

const GRENADE_CD         := 6.0
const TRAIL_CD           := 0.15
const RAGE_DURATION      := 2.0
const TEMPETE_CD         := 10.0
const MOUSE_OVERRIDE_DUR := 2.0
const AUTO_AIM_RANGE     := 400.0
const COR_GUERRE_DUR     := 5.0

var hp                  := 5
var last_direction      := "south"
var _aim_direction      := "south"
var _fire_timer         := 0.0
var _iframe_timer       := 0.0
var _attacking          := false
var _dead               := false
var _grenade_timer      := 0.0
var _trail_timer        := 0.0
var _rage_timer         := 0.0
var _enraged            := false
var _tempete_timer      := 0.0
var _pending_shot_dir      := Vector2.ZERO
var _waiting_to_shoot      := false
var _mouse_override_timer  := 0.0
var _last_aim_dir          := Vector2.DOWN
var _last_is_crit          := false
var _oeil_gele_counter     := 0
var _orbe_mana_counter     := 0
var _cor_guerre_timer      := 0.0
var _cor_guerre_active     := false
var _lightning_timer       := 0.0
var _sceptre_timer         := 0.0
var _shield_timer          := 0.0
var _shield_active         := false
var _stationary_timer      := 0.0
var _ire_bonus             := 0.0
var _baal_counter          := 0
var _revive_used           := false
var _mercy_cd              := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("player")
	hp = PlayerData.max_hp
	_setup_animations()
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)
	$HitArea.body_entered.connect(_on_body_entered)
	_setup_camera()

func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.zoom = Vector2(1.2, 1.2)
	cam.limit_left   = 0
	cam.limit_top    = 0
	cam.limit_right  = 1920
	cam.limit_bottom = 1080
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed   = 6.0
	add_child(cam)

func _input(event: InputEvent) -> void:
	if _dead:
		return
	if not DisplayServer.is_touchscreen_available():
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
		var bullet_speed := PlayerData.has_skill("velocite") as float * (2020.0 - 1200.0) + 1200.0
		var to_enemy := nearest.global_position - global_position
		var travel_time := to_enemy.length() / bullet_speed
		var predicted := nearest.global_position + (nearest as CharacterBody2D).velocity * travel_time
		return predicted - global_position
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
	if _mercy_cd > 0.0:
		_mercy_cd -= delta

	if _enraged:
		_rage_timer -= delta
		if _rage_timer <= 0.0:
			_enraged = false

	if _cor_guerre_active:
		_cor_guerre_timer -= delta
		if _cor_guerre_timer <= 0.0:
			_cor_guerre_active = false

	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):  dir.x += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):   dir.x -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):   dir.y += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):     dir.y -= 1
	if dir == Vector2.ZERO and PlayerData.touch_move.length() > 0.1:
		dir = PlayerData.touch_move

	var eff_speed := PlayerData.speed
	if PlayerData.has_timed_buff("phlegethon_speed"):
		eff_speed = minf(550.0, eff_speed * (1.0 + 0.05 * float(PlayerData.item_count("anneau_phlegethon"))))
	velocity = dir.normalized() * eff_speed if dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

	if dir != Vector2.ZERO:
		_update_dir(dir)
		_try_fire_trail(delta)
		_stationary_timer = 0.0
	else:
		_trail_timer = 0.0
		if PlayerData.item_count("bandeau_inquisiteur") > 0:
			_stationary_timer += delta

	if PlayerData.item_count("orbe_limbes") > 0 and not _shield_active:
		_shield_timer += delta
		if _shield_timer >= 8.0:
			_shield_timer = 0.0
			_shield_active = true

	if PlayerData.item_count("rune_foudre") > 0:
		_lightning_timer += delta
		if _lightning_timer >= 5.0:
			_lightning_timer = 0.0
			_strike_lightning()

	if PlayerData.item_count("sceptre_tartare") > 0:
		_sceptre_timer += delta
		if _sceptre_timer >= 4.0:
			_sceptre_timer = 0.0
			_launch_sceptre_blast()

	_mouse_override_timer -= delta

	if _fire_timer <= 0.0 and not PlayerData.dev_no_shoot:
		_shoot()
		_fire_timer = PlayerData.fire_cd

	if _waiting_to_shoot and $AnimatedSprite2D.frame >= 1:
		_waiting_to_shoot = false
		var dir_n := _pending_shot_dir.normalized()
		var count      := PlayerData.projectile_count
		var spread_deg := 15.0
		for b in count:
			var angle_off := deg_to_rad(spread_deg * (b - (count - 1) * 0.5))
			_spawn_bullet(dir_n.rotated(angle_off), global_position)

	if not _attacking:
		_play_move_anim(dir)

	if PlayerData.item_count("auto_grenade") > 0:
		_grenade_timer += delta
		if _grenade_timer >= GRENADE_CD:
			_grenade_timer = 0.0
			_launch_grenade()

	if PlayerData.has_skill("tempete_acier"):
		_tempete_timer += delta
		if _tempete_timer >= TEMPETE_CD:
			_tempete_timer = 0.0
			_launch_tempete()

func _effective_damage() -> int:
	var base := float(PlayerData.damage) * (1.5 if _enraged else 1.0)
	if _cor_guerre_active:
		base *= 1.3
	if _ire_bonus > 0.0:
		base *= (1.0 + _ire_bonus)
	if PlayerData.has_timed_buff("courroux") and PlayerData.item_count("sang_courroux") > 0:
		base += 3.0 * float(PlayerData.item_count("sang_courroux"))
	if _stationary_timer >= 1.0 and PlayerData.item_count("bandeau_inquisiteur") > 0:
		base *= 1.0 + 0.20 * float(PlayerData.item_count("bandeau_inquisiteur"))
	var mirror := PlayerData.item_count("miroir_supplies")
	if mirror > 0 and randf() < 0.05 * float(mirror):
		base *= 2.0
	if PlayerData.has_timed_buff("rage_condamne"):
		base *= 1.30
	if PlayerData.item_count("oeil_tenebres") > 0:
		var enemies := get_tree().get_nodes_in_group("enemies")
		var min_dist := INF
		for e in enemies:
			var d := global_position.distance_to((e as Node2D).global_position)
			if d < min_dist:
				min_dist = d
		if min_dist > 300.0:
			base *= 1.0 + 0.15 * float(PlayerData.item_count("oeil_tenebres"))
	_last_is_crit = PlayerData.roll_crit()
	if _last_is_crit:
		base *= PlayerData.crit_multiplier
	return int(base)

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
	var dmg     := _effective_damage()
	var is_crit := _last_is_crit
	var fb := FIREBALL.instantiate()
	get_parent().add_child(fb)
	fb.global_position = pos
	fb.init(dir, dmg, is_crit)

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

func on_enemy_hit(enemy: Node, dmg: int, is_crit: bool = false) -> void:
	if _dead:
		return

	# vampire_amulet lifesteal
	var heal := PlayerData.calc_lifesteal(dmg)
	if heal > 0:
		hp = min(hp + heal, PlayerData.max_hp)
		var hud_ls := get_tree().get_first_node_in_group("hud")
		if hud_ls:
			hud_ls.refresh_hp(hp, PlayerData.max_hp)
		hp_changed.emit(hp, PlayerData.max_hp)

	# oeil_gele: every 7th hit slows enemy 40% for 2s
	if PlayerData.item_count("oeil_gele") > 0:
		_oeil_gele_counter += 1
		if _oeil_gele_counter >= 7:
			_oeil_gele_counter = 0
			if enemy != null and is_instance_valid(enemy) and enemy.has_method("slow"):
				enemy.slow(0.4, 2.0)

	# orbe_mana: every 10th hit fires a bonus projectile toward the enemy
	if PlayerData.item_count("orbe_mana") > 0:
		_orbe_mana_counter += 1
		if _orbe_mana_counter >= 10:
			_orbe_mana_counter = 0
			if enemy != null and is_instance_valid(enemy):
				var bonus_dir: Vector2 = (enemy.global_position - global_position).normalized()
				call_deferred("_spawn_bullet", bonus_dir, global_position)

	# marteau_fissure: crits apply bleed (2 dmg/s for 3s)
	if is_crit and PlayerData.item_count("marteau_fissure") > 0:
		if enemy != null and is_instance_valid(enemy) and enemy.has_method("apply_bleed"):
			enemy.apply_bleed(2, 3.0)

	# dague_asmodee: poison 3s (2 dmg/s)
	if PlayerData.item_count("dague_asmodee") > 0:
		if enemy != null and is_instance_valid(enemy) and enemy.has_method("apply_bleed"):
			enemy.apply_bleed(2, 3.0)

	# griffe_mephisto: flat lifesteal per hit
	if PlayerData.lifesteal_flat_per_shot > 0:
		hp = mini(hp + PlayerData.lifesteal_flat_per_shot, PlayerData.max_hp)
		var hud_f := get_tree().get_first_node_in_group("hud")
		if hud_f:
			hud_f.refresh_hp(hp, PlayerData.max_hp)
		hp_changed.emit(hp, PlayerData.max_hp)

	# amulette_baal: every 3rd hit → 20 dmg to nearest enemy
	if PlayerData.item_count("amulette_baal") > 0:
		_baal_counter += 1
		if _baal_counter >= 3:
			_baal_counter = 0
			_baal_strike()

func on_enemy_kill() -> void:
	if _dead:
		return
	var rage_stacks := PlayerData.item_count("rage_ring")
	if rage_stacks > 0:
		_enraged = true
		_rage_timer = RAGE_DURATION + float(rage_stacks - 1) * 1.0
	if PlayerData.item_count("sang_courroux") > 0:
		PlayerData.set_timed_buff("courroux", 5.0)
	if PlayerData.item_count("anneau_phlegethon") > 0:
		PlayerData.set_timed_buff("phlegethon_speed", 3.0)
	if PlayerData.item_count("talisman_ire") > 0:
		_ire_bonus = minf(_ire_bonus + 0.03 * float(PlayerData.item_count("talisman_ire")), 0.30)
	if PlayerData.item_count("chapelet_condamnes") > 0:
		PlayerData.bonus_armor_round = mini(PlayerData.bonus_armor_round + 2 * PlayerData.item_count("chapelet_condamnes"), 10)

func on_wave_start() -> void:
	if PlayerData.item_count("cor_guerre") > 0:
		_cor_guerre_active = true
		_cor_guerre_timer  = COR_GUERRE_DUR
	_oeil_gele_counter        = 0
	_orbe_mana_counter        = 0
	_ire_bonus                = 0.0
	_baal_counter             = 0
	_stationary_timer         = 0.0
	PlayerData.bonus_armor_round = 0

func revive() -> void:
	_dead             = false
	_attacking        = false
	_waiting_to_shoot = false
	_iframe_timer     = 0.0
	_fire_timer       = 0.0
	_enraged          = false
	_rage_timer       = 0.0
	hp                = PlayerData.max_hp
	velocity          = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", false)
	$HitArea/HitShape.set_deferred("disabled", false)
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)
	$AnimatedSprite2D.play("idle_south")

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
	if _shield_active and PlayerData.item_count("orbe_limbes") > 0:
		_shield_active = false
		_shield_timer  = 0.0
		return
	var final_dmg := PlayerData.calc_damage_taken(amount)
	if final_dmg == 0:
		return  # dodged
	var phantom := PlayerData.item_count("phantom_step")
	var plumes  := PlayerData.item_count("plume_rapide")
	_iframe_timer = IFRAMES + 0.4 * phantom + 0.1 * plumes
	hp = max(0, hp - final_dmg)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_hp(hp, PlayerData.max_hp)
	hp_changed.emit(hp, PlayerData.max_hp)
	_flash_damage()
	_thorn_reflect(final_dmg)
	_ecu_reflect(final_dmg)
	_check_mercy_burst()
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
	if PlayerData.revive_count > 0 and not _revive_used:
		_revive_used  = true
		hp            = maxi(1, int(PlayerData.max_hp * 0.30))
		_iframe_timer = 2.0
		var hud_r := get_tree().get_first_node_in_group("hud")
		if hud_r:
			hud_r.refresh_hp(hp, PlayerData.max_hp)
		hp_changed.emit(hp, PlayerData.max_hp)
		return
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

func _strike_lightning() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var nearest: Node2D = null
	var nearest_dist := INF
	for e in enemies:
		var d := global_position.distance_to((e as Node2D).global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	if nearest and is_instance_valid(nearest):
		nearest.take_damage(50 * PlayerData.item_count("rune_foudre"))

func _launch_sceptre_blast() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var target_pos := global_position + Vector2(randf_range(-200.0, 200.0), randf_range(-200.0, 200.0))
	if not enemies.is_empty():
		var nearest: Node2D = enemies[0]
		for e in enemies:
			if global_position.distance_to((e as Node2D).global_position) < global_position.distance_to(nearest.global_position):
				nearest = e
		target_pos = nearest.global_position
	var blast_dmg := 60 * PlayerData.item_count("sceptre_tartare")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if target_pos.distance_to((enemy as Node2D).global_position) <= 120.0:
			enemy.take_damage(blast_dmg)

func _baal_strike() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var nearest: Node2D = null
	var nearest_dist := INF
	for e in enemies:
		var d := global_position.distance_to((e as Node2D).global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	if nearest and is_instance_valid(nearest):
		nearest.take_damage(20 * PlayerData.item_count("amulette_baal"))

func _ecu_reflect(dmg_taken: int) -> void:
	if PlayerData.reflect_pct <= 0.0:
		return
	var reflect := int(ceil(float(dmg_taken) * PlayerData.reflect_pct))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to((enemy as Node2D).global_position) <= 250.0:
			enemy.take_damage(reflect)

func _check_mercy_burst() -> void:
	if _mercy_cd > 0.0:
		return
	if float(hp) / float(PlayerData.max_hp) > 0.25:
		return
	PlayerData.set_timed_buff("rage_condamne", 5.0)
	_mercy_cd = 20.0
	_flash_mercy()

func _flash_mercy() -> void:
	$AnimatedSprite2D.modulate = Color(1.0, 0.85, 0.1, 1.0)
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(self):
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)
