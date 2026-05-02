extends Node2D

# ── Preloads ──────────────────────────────────────────────────────────────────
const ALDRICH  := preload("res://scenes/entities/Aldrich.tscn")
const BRUTUS   := preload("res://scenes/entities/Brutus.tscn")
const BOOSTER  := preload("res://scenes/entities/Booster.tscn")
const BOSS     := preload("res://scenes/entities/Golgota.tscn")
const KEY_SCENE := preload("res://scenes/entities/Key.tscn")
const KAEL     := preload("res://scenes/entities/Kael.tscn")
const MORBIUS  := preload("res://scenes/entities/Morbius.tscn")
const SERAPHEL := preload("res://scenes/entities/Seraphel.tscn")
const VEX      := preload("res://scenes/entities/Vex.tscn")
const NYX      := preload("res://scenes/entities/Nyx.tscn")

# ── Constants ─────────────────────────────────────────────────────────────────
const ENEMY_CAP             := 100
const KEY_DROP_CHANCE_EARLY := 0.30
const KEY_DROP_CHANCE       := 0.14
const KEY_DROP_CHANCE_LATE  := 0.08
const KEY_DROP_MAX_LATE     := 12
const ARENA_CENTER          := Vector2(1016, 517)
const SPAWN_RECT            := Rect2(350, 300, 1450, 580)

# ── Stat tables — indices 1..19 ───────────────────────────────────────────────
const ALDRICH_HP    := [0,  4,  6,  8, 11, 14, 18, 22, 27, 33, 40,  48,  58,  70,  84, 100, 120, 143, 170, 200]
const ALDRICH_DMG   := [0,  4,  5,  5,  6,  7,  8, 10, 12, 14, 17,  19,  21,  24,  27,  30,  34,  38,  42,  47]
const ALDRICH_SPEED := [0.0, 90.0, 92.0, 94.0, 96.0, 100.0, 105.0, 110.0, 115.0, 120.0, 126.0, 132.0, 138.0, 145.0, 152.0, 160.0, 168.0, 176.0, 185.0, 194.0]

const BRUTUS_HP    := [0, 0, 22, 26, 32, 38, 46, 55, 66, 80, 96, 110, 124, 140, 158, 178, 200, 226, 254, 285]
const BRUTUS_DMG   := [0, 0,  6,  7,  8,  9, 11, 13, 15, 17, 20,  22,  24,  27,  30,  33,  37,  41,  46,  51]
const BRUTUS_CD    := [0.0, 0.0, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50, 0.50, 0.45, 0.43, 0.41, 0.39, 0.37, 0.35, 0.33, 0.31, 0.29, 0.27]
const BRUTUS_BSPD  := [0.0, 0.0, 280.0, 300.0, 320.0, 340.0, 360.0, 380.0, 400.0, 420.0, 440.0, 460.0, 480.0, 500.0, 520.0, 540.0, 560.0, 580.0, 600.0, 620.0]
const BRUTUS_RANGE := [0.0, 0.0, 500.0, 500.0, 520.0, 520.0, 540.0, 540.0, 560.0, 560.0, 580.0, 600.0, 615.0, 630.0, 645.0, 660.0, 675.0, 690.0, 700.0, 700.0]

const BOOSTER_HP   := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 95, 112, 133, 157, 185, 218, 255, 300]

# ── Souls ─────────────────────────────────────────────────────────────────────
const SOULS_ALDRICH  := 1
const SOULS_BRUTUS   := 3
const SOULS_BOOSTER  := 8
const SOULS_KAEL     := 2
const SOULS_MORBIUS  := 6
const SOULS_SERAPHEL := 10
const SOULS_VEX      := 2
const SOULS_NYX      := 5
const SOULS_BOSS     := 50
# Eternal souls rewarded per boss (index = wave / 10)
const ETERNAL_BOSS   := [0, 50, 100, 175, 250, 500]

# ── State ─────────────────────────────────────────────────────────────────────
var _spawn_timer    := 0.0
var _brutus_timer   := 0.0
var _booster_timer  := 0.0
var _kael_timer     := 0.0
var _morbius_timer  := 0.0
var _seraphel_timer := 0.0
var _vex_timer      := 0.0
var _nyx_timer      := 0.0

var _keys                    := 0
var _round_timer             := 30.0
var _level                   := 1
var _boss_spawned            := false
var _kills_this_round        := 0
var _keys_dropped_this_round := 0
var _disperse_timer          := 0.0
var _game_over               := false
var _hud                     : Node = null

const DISPERSE_CHECK_INTERVAL := 2.0
const CLUSTER_RADIUS          := 180.0
const CLUSTER_THRESHOLD       := 0.9

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("arena")
	$Player.died.connect($GameOver.show_screen)
	$Player.died.connect(func() -> void: _game_over = true)
	if not $ShopMenu.continue_round.is_connected(_on_round_continue):
		$ShopMenu.continue_round.connect(_on_round_continue)
	_level       = maxi(1, PlayerData.player_level)
	_round_timer = _round_duration()
	_hud = get_tree().get_first_node_in_group("hud")
	if _hud:
		_hud.refresh_level(_level)
		_hud.refresh_timer(int(_round_timer))
		_hud.refresh_keys(_keys)
		_hud.refresh_souls(PlayerData.souls)
		_hud.refresh_items()
	call_deferred("_rebuild_navmesh")

func _rebuild_navmesh() -> void:
	var outer := $ExterieurMap as Polygon2D
	var inner := $IleEviter as Polygon2D
	var nav   := $NavigationRegion2D as NavigationRegion2D
	if outer == null or nav == null:
		return
	var np := NavigationPolygon.new()
	np.agent_radius = 10.0
	np.add_outline(outer.polygon)
	if inner != null:
		var raw    := inner.polygon
		var offset := inner.position
		var hole   := PackedVector2Array()
		for i in raw.size():
			hole.append(raw[raw.size() - 1 - i] + offset)
		np.add_outline(hole)
	np.make_polygons_from_outlines()
	nav.navigation_polygon = np

func _unhandled_input(event: InputEvent) -> void:
	if _game_over:
		return
	if event.is_action_pressed("ui_cancel"):
		$PauseMenu.toggle()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B and event.ctrl_pressed:
			_cheat_skip_to_boss()
			get_viewport().set_input_as_handled()
		if event.keycode == KEY_I and event.ctrl_pressed:
			_cheat_give_items()
			get_viewport().set_input_as_handled()
		if event.keycode == KEY_R and event.ctrl_pressed:
			_cheat_reset_items()
			get_viewport().set_input_as_handled()
		if event.keycode == KEY_U and event.ctrl_pressed:
			_cheat_unequip_items()
			get_viewport().set_input_as_handled()

# ── Main loop ─────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _game_over or get_tree().paused:
		return
	if not _is_boss_level():
		_tick_spawners(delta)
	_tick_boss_state()
	if not _is_boss_level():
		_tick_round_clock(delta)

# ── Spawners ──────────────────────────────────────────────────────────────────
func _tick_spawners(delta: float) -> void:
	var at_cap := get_tree().get_nodes_in_group("enemies").size() >= ENEMY_CAP

	_spawn_timer += delta
	if _spawn_timer >= _aldrich_interval():
		_spawn_timer = 0.0
		if not at_cap:
			for _i in _spawn_count():
				if get_tree().get_nodes_in_group("enemies").size() >= ENEMY_CAP:
					break
				_spawn_aldrich()

	if _level >= 2:
		_brutus_timer += delta
		if _brutus_timer >= _brutus_interval() and not at_cap:
			_brutus_timer = 0.0
			_spawn_brutus()

	_disperse_timer += delta
	if _disperse_timer >= DISPERSE_CHECK_INTERVAL:
		_disperse_timer = 0.0
		_check_disperse()

	if _level >= 11:
		_booster_timer += delta
		if _booster_timer >= _booster_interval() and not at_cap:
			_booster_timer = 0.0
			_spawn_booster()

	if _level >= 12:
		_kael_timer += delta
		if _kael_timer >= _kael_interval() and not at_cap:
			_kael_timer = 0.0
			_spawn_kael()

	if _level >= 18:
		_morbius_timer += delta
		if _morbius_timer >= _morbius_interval() and not at_cap:
			_morbius_timer = 0.0
			_spawn_morbius()

	if _level >= 24:
		_seraphel_timer += delta
		if _seraphel_timer >= _seraphel_interval() and not at_cap:
			_seraphel_timer = 0.0
			_spawn_seraphel()

	if _level >= 30:
		_vex_timer += delta
		if _vex_timer >= _vex_interval() and not at_cap:
			_vex_timer = 0.0
			_spawn_vex()

	if _level >= 36:
		_nyx_timer += delta
		if _nyx_timer >= _nyx_interval() and not at_cap:
			_nyx_timer = 0.0
			_spawn_nyx()

# ── Boss state ────────────────────────────────────────────────────────────────
func _tick_boss_state() -> void:
	if not _is_boss_level():
		return
	if not _boss_spawned:
		_boss_spawned = true
		_spawn_boss()
	if _hud:
		_hud.refresh_timer(-1)

# ── Round clock ───────────────────────────────────────────────────────────────
func _tick_round_clock(delta: float) -> void:
	_round_timer -= delta
	if _round_timer <= 0.0:
		_round_timer = 0.0
		if not $ShopMenu.visible:
			_end_round()
		return
	if _hud:
		_hud.refresh_timer(int(ceil(_round_timer)))

# ── Level helpers ─────────────────────────────────────────────────────────────
func _is_boss_level() -> bool:
	return _level % 10 == 0

# Wave durations: 30s at wave 1, 150s at wave 50 (linear). Boss waves: 0.
func _round_duration() -> float:
	if _is_boss_level():
		return 0.0
	return 30.0 + float(_level - 1) * 120.0 / 49.0

# ── Spawn intervals (PDF table) ───────────────────────────────────────────────
func _aldrich_interval() -> float:
	var base := maxf(0.30, 1.40 - float(_level - 1) * 1.10 / 49.0)
	if _level >= 20:
		base *= 1.20
	if PlayerData.has_curse("curse_chaos"):
		base *= 0.80
	return base

func _brutus_interval() -> float:
	var base := maxf(3.0, 15.0 - float(_level - 2) * 1.1)
	if PlayerData.has_curse("curse_chaos"):
		base *= 0.80
	return base

func _booster_interval() -> float:
	return maxf(12.0, 25.0 - float(_level - 11) * 0.6)

func _kael_interval() -> float:
	var base := maxf(0.8, 2.5 - float(_level - 12) * 0.10)
	if PlayerData.has_curse("curse_chaos"):
		base *= 0.80
	return base

func _morbius_interval() -> float:
	return maxf(5.0, 20.0 - float(_level - 18) * 0.6)

func _seraphel_interval() -> float:
	return maxf(10.0, 25.0 - float(_level - 24) * 0.6)

func _vex_interval() -> float:
	var base := maxf(4.0, 18.0 - float(_level - 30) * 0.5)
	if PlayerData.has_curse("curse_chaos"):
		base *= 0.80
	return base

func _nyx_interval() -> float:
	return maxf(8.0, 28.0 - float(_level - 36) * 0.6)

func _spawn_count() -> int:
	if _level >= 31: return 7
	if _level >= 21: return 6
	if _level >= 11: return 5
	if _level >= 8:  return 4
	if _level >= 6:  return 3
	if _level >= 4:  return 2
	return 1

# ── Stat scaling — waves 1-19 use tables, 20+ use formulas ───────────────────
func _aldrich_hp(w: int) -> int:
	if w <= 19: return ALDRICH_HP[w]
	return int(200.0 * pow(1.16, w - 19))

func _aldrich_dmg(w: int) -> int:
	if w <= 19: return ALDRICH_DMG[w]
	return int(47.0 * pow(1.13, w - 19))

func _aldrich_spd(w: int) -> float:
	if w <= 19: return ALDRICH_SPEED[w]
	return minf(340.0, 194.0 + float(w - 19) * 5.0)

func _brutus_hp(w: int) -> int:
	if w <= 19: return BRUTUS_HP[w]
	return int(285.0 * pow(1.14, w - 19))

func _brutus_dmg(w: int) -> int:
	if w <= 19: return BRUTUS_DMG[w]
	return int(51.0 * pow(1.12, w - 19))

func _brutus_cd(w: int) -> float:
	if w <= 19: return BRUTUS_CD[w]
	return maxf(0.15, 0.27 - float(w - 19) * 0.01)

func _brutus_bspd(w: int) -> float:
	if w <= 19: return BRUTUS_BSPD[w]
	return minf(900.0, 620.0 + float(w - 19) * 12.0)

func _brutus_range(w: int) -> float:
	if w <= 19: return BRUTUS_RANGE[w]
	return minf(800.0, 700.0 + float(w - 19) * 5.0)

func _booster_hp(w: int) -> int:
	if w <= 19: return BOOSTER_HP[w]
	return int(300.0 * pow(1.13, w - 19))

func _kael_hp(w: int)   -> int: return maxi(1, int(70.0  * pow(1.15, w - 12)))
func _kael_dmg(w: int)  -> int: return maxi(1, int(14.0  * pow(1.12, w - 12)))

func _morbius_hp(w: int)    -> int: return maxi(1, int(350.0 * pow(1.13, w - 18)))
func _morbius_dmg(w: int)   -> int: return maxi(1, int(24.0  * pow(1.10, w - 18)))
@warning_ignore("integer_division")
func _morbius_armor(w: int) -> int: return mini(8, 3 + (w - 18) / 8)

func _seraphel_hp(w: int)  -> int: return maxi(1, int(250.0 * pow(1.12, w - 24)))
func _seraphel_dmg(w: int) -> int: return maxi(1, int(18.0  * pow(1.10, w - 24)))

func _vex_hp(w: int)            -> int: return maxi(1, int(80.0  * pow(1.12, w - 30)))
func _vex_explosion_dmg(w: int) -> int: return maxi(1, int(35.0  * pow(1.14, w - 30)))

func _nyx_hp(w: int)  -> int: return maxi(1, int(200.0 * pow(1.12, w - 36)))
func _nyx_dmg(w: int) -> int: return maxi(1, int(30.0  * pow(1.12, w - 36)))

# ── Spawn helpers ─────────────────────────────────────────────────────────────
func _edge_pos() -> Vector2:
	var player := get_tree().get_first_node_in_group("player")
	var c := ARENA_CENTER if player == null else (player as Node2D).global_position
	const OX := 980.0
	const OY := 580.0
	match randi() % 4:
		0: return Vector2(randf_range(c.x - OX, c.x + OX), c.y - OY)
		1: return Vector2(randf_range(c.x - OX, c.x + OX), c.y + OY)
		2: return Vector2(c.x - OX, randf_range(c.y - OY, c.y + OY))
		_: return Vector2(c.x + OX, randf_range(c.y - OY, c.y + OY))

# ── Spawn functions ───────────────────────────────────────────────────────────
func _spawn_aldrich() -> void:
	var w := clampi(_level, 1, 50)
	var a := ALDRICH.instantiate()
	add_child(a)
	a.hp     = _aldrich_hp(w)
	a.damage = _aldrich_dmg(w)
	a.speed  = _aldrich_spd(w)
	a.died.connect(_on_enemy_died.bind("aldrich"))
	a.died.connect(func(): _try_drop_key(a))
	a.position = _edge_pos()

func _spawn_brutus() -> void:
	var w := clampi(_level, 2, 50)
	var b := BRUTUS.instantiate()
	add_child(b)
	b.hp           = _brutus_hp(w)
	b.damage       = _brutus_dmg(w)
	b.shoot_cd     = _brutus_cd(w)
	b.bullet_speed = _brutus_bspd(w)
	b.shoot_range  = _brutus_range(w)
	b.died.connect(_on_enemy_died.bind("brutus"))
	b.died.connect(func(): _try_drop_key(b))
	b.position = _edge_pos()

func _spawn_booster() -> void:
	if get_tree().get_nodes_in_group("boosters").size() >= 2:
		return
	var w := clampi(_level, 11, 50)
	var b := BOOSTER.instantiate()
	add_child(b)
	b.hp = _booster_hp(w)
	b.died.connect(_on_enemy_died.bind("booster"))
	b.died.connect(func(): _try_drop_key(b))
	b.position = _edge_pos()

func _spawn_kael() -> void:
	var w := clampi(_level, 12, 50)
	var k := KAEL.instantiate()
	add_child(k)
	k.hp     = _kael_hp(w)
	k.damage = _kael_dmg(w)
	k.died.connect(_on_enemy_died.bind("kael"))
	k.died.connect(func(): _try_drop_key(k))
	k.position = _edge_pos()

func _spawn_morbius() -> void:
	var w := clampi(_level, 18, 50)
	var m := MORBIUS.instantiate()
	add_child(m)
	m.hp     = _morbius_hp(w)
	m.damage = _morbius_dmg(w)
	m.armor  = _morbius_armor(w)
	m.died.connect(_on_enemy_died.bind("morbius"))
	m.died.connect(func(): _try_drop_key(m))
	m.position = _edge_pos()

func _spawn_seraphel() -> void:
	var w := clampi(_level, 24, 50)
	var s := SERAPHEL.instantiate()
	add_child(s)
	s.hp           = _seraphel_hp(w)
	s.damage       = _seraphel_dmg(w)
	@warning_ignore("integer_division")
	s.summon_damage = maxi(1, _aldrich_dmg(w) / 2)
	s.died.connect(_on_enemy_died.bind("seraphel"))
	s.died.connect(func(): _try_drop_key(s))
	s.position = _edge_pos()

func _spawn_vex() -> void:
	var w := clampi(_level, 30, 50)
	var v := VEX.instantiate()
	add_child(v)
	v.hp              = _vex_hp(w)
	v.explosion_damage = _vex_explosion_dmg(w)
	v.died.connect(_on_enemy_died.bind("vex"))
	v.died.connect(func(): _try_drop_key(v))
	v.position = _edge_pos()

func _spawn_nyx() -> void:
	var w := clampi(_level, 36, 50)
	var n := NYX.instantiate()
	add_child(n)
	n.hp     = _nyx_hp(w)
	n.damage = _nyx_dmg(w)
	n.died.connect(_on_enemy_died.bind("nyx"))
	n.died.connect(func(): _try_drop_key(n))
	n.position = _edge_pos()

func _spawn_boss() -> void:
	var b := BOSS.instantiate()
	match _level:
		20:
			b.custom_max_hp = 3600
			b.damage        = 50
			b.laser_damage  = 40
		30:
			b.custom_max_hp = 8000
			b.damage        = 70
			b.laser_damage  = 55
		40:
			b.custom_max_hp = 18000
			b.damage        = 95
			b.laser_damage  = 75
		50:
			b.custom_max_hp = 40000
			b.damage        = 130
			b.laser_damage  = 100
	add_child(b)
	b.died.connect(_on_enemy_died.bind("boss"))
	b.position = Vector2(1016, 130)

# ── Boss reward ───────────────────────────────────────────────────────────────
func on_boss_soul_collected() -> void:
	PlayerData.victories_total += 1
	if PlayerData.victories_total >= 1 and not ("zealot" in PlayerData.unlocked_chars):
		PlayerData.unlocked_chars.append("zealot")
	if PlayerData.victories_total >= 5 and not ("paladin" in PlayerData.unlocked_chars):
		PlayerData.unlocked_chars.append("paladin")
	var boss_num: int = _level / 10
	PlayerData.eternal_souls += ETERNAL_BOSS[mini(boss_num, 5)]
	PlayerData.save()
	if _level >= 50:
		PlayerData.reset_run()
		get_tree().change_scene_to_file("res://scenes/ui/SelectCharacter.tscn")
		return
	for _i in 5:
		add_key()
	_end_round()

# ── Round management ──────────────────────────────────────────────────────────
func _end_round() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	$ShopMenu.show_shop(_keys, _level)

func _on_round_continue(remaining_keys: int) -> void:
	_keys = remaining_keys
	_kills_this_round        = 0
	_keys_dropped_this_round = 0
	_spawn_timer             = 0.0
	_brutus_timer            = 0.0
	_booster_timer           = 0.0
	_kael_timer              = 0.0
	_morbius_timer           = 0.0
	_seraphel_timer          = 0.0
	_vex_timer               = 0.0
	_nyx_timer               = 0.0
	_disperse_timer          = 0.0
	_level += 1
	PlayerData.player_level = _level
	PlayerData._recompute()
	_round_timer  = _round_duration()
	_boss_spawned = false
	$Player.global_position = Vector2(247, 462)
	$Player.revive()
	$Player.on_wave_start()
	if _hud:
		_hud.refresh_hp(PlayerData.max_hp, PlayerData.max_hp)
		_hud.refresh_level(_level)
		_hud.refresh_timer(int(_round_timer))
		_hud.refresh_keys(_keys)
		_hud.refresh_souls(PlayerData.souls)
		_hud.refresh_items()

# ── Enemy death ───────────────────────────────────────────────────────────────
func _on_enemy_died(enemy_type: String) -> void:
	var base_souls := 0
	match enemy_type:
		"aldrich":  base_souls = SOULS_ALDRICH
		"brutus":   base_souls = SOULS_BRUTUS
		"booster":  base_souls = SOULS_BOOSTER
		"kael":     base_souls = SOULS_KAEL
		"morbius":  base_souls = SOULS_MORBIUS
		"seraphel": base_souls = SOULS_SERAPHEL
		"vex":      base_souls = SOULS_VEX
		"nyx":      base_souls = SOULS_NYX
		"boss":     base_souls = SOULS_BOSS
	var mult := PlayerData.get_curse_soul_multiplier()
	PlayerData.souls += maxi(1, int(ceil(float(base_souls) * (1.0 + PlayerData.soul_bonus_rate) * mult)))
	if _hud:
		_hud.refresh_souls(PlayerData.souls)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.on_enemy_kill()

# ── Key drops ─────────────────────────────────────────────────────────────────
func _try_drop_key(enemy: Node2D) -> void:
	if _is_boss_level():
		return
	_kills_this_round += 1
	var chance: float
	if _level >= 10:
		if _keys_dropped_this_round >= KEY_DROP_MAX_LATE:
			return
		chance = KEY_DROP_CHANCE_LATE
	elif _level <= 2 and _kills_this_round <= 5:
		chance = KEY_DROP_CHANCE_EARLY
	else:
		chance = KEY_DROP_CHANCE
	if randf() < chance:
		_keys_dropped_this_round += 1
		var key := KEY_SCENE.instantiate()
		key.global_position = enemy.global_position
		call_deferred("add_child", key)

func add_key() -> void:
	_keys += 1
	if _hud:
		_hud.refresh_keys(_keys)

# ── Anti-cluster disperse ─────────────────────────────────────────────────────
func _check_disperse() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var count := enemies.size()
	if count < 4:
		return
	var centroid := Vector2.ZERO
	for e in enemies:
		centroid += (e as Node2D).global_position
	centroid /= count
	var clustered: Array = []
	for e in enemies:
		if (e as Node2D).global_position.distance_to(centroid) < CLUSTER_RADIUS:
			clustered.append(e)
	if float(clustered.size()) / float(count) < CLUSTER_THRESHOLD:
		return
	clustered.shuffle()
	for i in clustered.size():
		var e: Node2D = clustered[i]
		get_tree().create_timer(i * 0.7).timeout.connect(
			func(): if is_instance_valid(e): e.call("teleport_to_edge")
		)

# ── Cheats ────────────────────────────────────────────────────────────────────
func _cheat_give_items() -> void:
	var want := ["fire_boots", "auto_grenade", "double_canon", "oeil_gele",
				 "orbe_mana", "cor_guerre", "vampire_amulet", "thorn_shield",
				 "rage_ring", "phantom_step", "sceau_resurrection"]
	for id in want:
		PlayerData.add_item(id)
	PlayerData.souls += 999
	PlayerData._recompute()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.hp = PlayerData.max_hp
	if _hud:
		_hud.refresh_souls(PlayerData.souls)
		_hud.refresh_items()
		_hud.refresh_hp(PlayerData.max_hp, PlayerData.max_hp)

func _cheat_unequip_items() -> void:
	PlayerData.items.clear()
	PlayerData._recompute()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.hp = PlayerData.max_hp
	if _hud:
		_hud.refresh_items()
		_hud.refresh_hp(PlayerData.max_hp, PlayerData.max_hp)

func _cheat_reset_items() -> void:
	PlayerData.reset_run()
	if _hud:
		_hud.refresh_items()
		_hud.refresh_hp(PlayerData.max_hp, PlayerData.max_hp)
		_hud.refresh_souls(PlayerData.souls)

func _cheat_skip_to_boss() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	var next_boss: int = ((_level / 10) + 1) * 10
	_level        = mini(next_boss, 50)
	_boss_spawned = false
	_round_timer  = 0.0
	_spawn_timer  = 0.0
	_brutus_timer = 0.0
	_kael_timer   = 0.0
	if _hud:
		_hud.refresh_level(_level)
