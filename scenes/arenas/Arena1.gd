extends Node2D

const ALDRICH              := preload("res://scenes/entities/Aldrich.tscn")
const BRUTUS               := preload("res://scenes/entities/Brutus.tscn")
const BOSS                 := preload("res://scenes/entities/Golgota.tscn")
const KEY_SCENE            := preload("res://scenes/entities/Key.tscn")
const ENEMY_CAP            := 45
const KEY_DROP_CHANCE_EARLY := 0.30
const KEY_DROP_CHANCE       := 0.14

const ARENA_CENTER := Vector2(1016, 517)

# Tables de scaling — indices = niveau (1..9)
const ALDRICH_HP      := [0,  4,  6,  8, 11, 14, 18, 22, 27, 33]
const ALDRICH_DMG     := [0,  4,  5,  5,  6,  7,  8, 10, 12, 14]
const ALDRICH_SPEED   := [0.0, 90.0, 92.0, 94.0, 96.0, 100.0, 105.0, 110.0, 115.0, 120.0]

const BRUTUS_HP       := [0, 0, 22, 26, 32, 38, 46, 55, 66, 80]
const BRUTUS_DMG      := [0, 0,  6,  7,  8,  9, 11, 13, 15, 17]
const BRUTUS_CD       := [0.0, 0.0, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50, 0.50]
const BRUTUS_BSPD     := [0.0, 0.0, 280.0, 300.0, 320.0, 340.0, 360.0, 380.0, 400.0, 420.0]
const BRUTUS_RANGE    := [0.0, 0.0, 500.0, 500.0, 520.0, 520.0, 540.0, 540.0, 560.0, 560.0]
const BRUTUS_INTERVAL := [0.0, 0.0, 15.0, 12.0, 10.0, 8.5, 7.0, 6.0, 5.0, 4.5]

var _spawn_timer        := 0.0
var _brutus_timer       := 0.0
var _keys               := 0
var _round_timer        := 30.0
var _level              := 1
var _boss_spawned       := false
var _kills_this_round   := 0
var _disperse_timer     := 0.0

const DISPERSE_CHECK_INTERVAL := 2.0
const CLUSTER_RADIUS          := 180.0
const CLUSTER_THRESHOLD       := 0.9

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("arena")
	if not $Player.died.is_connected($GameOver.show_screen):
		$Player.died.connect($GameOver.show_screen)
	if not $ShopMenu.continue_round.is_connected(_on_round_continue):
		$ShopMenu.continue_round.connect(_on_round_continue)

func _unhandled_input(event: InputEvent) -> void:
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
		if event.keycode == KEY_U and event.ctrl_pressed:
			_cheat_unequip_items()
			get_viewport().set_input_as_handled()
			get_viewport().set_input_as_handled()

func _cheat_give_items() -> void:
	var want := ["fire_boots", "auto_grenade", "double_canon", "oeil_gele",
				 "orbe_mana", "cor_guerre", "vampire_amulet", "thorn_shield",
				 "rage_ring", "phantom_step"]
	for id in want:
		PlayerData.add_item(id)
	PlayerData.souls += 999
	PlayerData._recompute()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.hp = PlayerData.max_hp
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_souls(PlayerData.souls)
		hud.refresh_items()
		hud.refresh_hp(PlayerData.max_hp, PlayerData.max_hp)

func _cheat_unequip_items() -> void:
	PlayerData.items.clear()
	PlayerData._recompute()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.hp = PlayerData.max_hp
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_items()
		hud.refresh_hp(PlayerData.max_hp, PlayerData.max_hp)

func _cheat_reset_items() -> void:
	PlayerData.reset_run()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_items()
		hud.refresh_hp(PlayerData.max_hp, PlayerData.max_hp)
		hud.refresh_souls(PlayerData.souls)

func _cheat_skip_to_boss() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	_level        = 10
	_boss_spawned = false
	_round_timer  = _round_duration()
	_spawn_timer  = 0.0
	_brutus_timer = 0.0
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_level(_level)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if _level < 10:
		_spawn_timer += delta
		if _spawn_timer >= _spawn_interval():
			_spawn_timer = 0.0
			if get_tree().get_nodes_in_group("enemies").size() < ENEMY_CAP:
				for i in _spawn_count():
					_spawn_aldrich()

	if _level >= 2 and _level < 10:
		_brutus_timer += delta
		if _brutus_timer >= _brutus_interval():
			_brutus_timer = 0.0
			_spawn_brutus()
	if _level < 10:
		_disperse_timer += delta
		if _disperse_timer >= DISPERSE_CHECK_INTERVAL:
			_disperse_timer = 0.0
			_check_disperse()

	if _level >= 10 and not _boss_spawned:
		_boss_spawned = true
		_spawn_boss()
	var hud := get_tree().get_first_node_in_group("hud")
	if _level >= 10:
		if hud:
			hud.refresh_timer(-1)
		return
	_round_timer -= delta
	if _round_timer <= 0.0:
		_round_timer = 0.0
		if not $ShopMenu.visible:
			_end_round()
		return
	if hud:
		hud.refresh_timer(int(ceil(_round_timer)))

func _round_duration() -> float:
	match _level:
		1: return 30.0
		2: return 34.0
		3: return 38.0
		4: return 41.0
		5: return 45.0
		6: return 49.0
		7: return 53.0
		8: return 56.0
		_: return 60.0

func _spawn_interval() -> float:
	# Formule de la proposition : max(0.40, 1.40 * 0.78^(niv-1))
	var interval := 1.40 * pow(0.78, _level - 1)
	if PlayerData.has_curse("curse_chaos"):
		interval *= 0.80
	return max(0.40, interval)

func _brutus_interval() -> float:
	var base: float = BRUTUS_INTERVAL[clampi(_level, 2, 9)]
	if PlayerData.has_curse("curse_chaos"):
		base *= 0.80
	return max(4.5, base)

func _spawn_count() -> int:
	if _level >= 8: return 4
	if _level >= 6: return 3
	if _level >= 4: return 2
	return 1

func _edge_pos() -> Vector2:
	match randi() % 4:
		0: return Vector2(randf_range(120, 1800), 110)
		1: return Vector2(randf_range(120, 1800), 940)
		2: return Vector2(115, randf_range(110, 940))
		_: return Vector2(1900, randf_range(110, 940))

func _spawn_aldrich() -> void:
	var lvl: int = clampi(_level, 1, 9)
	var a := ALDRICH.instantiate()
	add_child(a)
	a.hp     = ALDRICH_HP[lvl]
	a.damage = ALDRICH_DMG[lvl]
	a.speed  = ALDRICH_SPEED[lvl]
	a.died.connect(_on_enemy_died.bind("aldrich"))
	a.died.connect(func(): _try_drop_key(a))
	a.position = _edge_pos()

func _spawn_brutus() -> void:
	var lvl: int = clampi(_level, 2, 9)
	var b := BRUTUS.instantiate()
	add_child(b)
	b.hp           = BRUTUS_HP[lvl]
	b.damage       = BRUTUS_DMG[lvl]
	b.shoot_cd     = BRUTUS_CD[lvl]
	b.bullet_speed = BRUTUS_BSPD[lvl]
	b.shoot_range  = BRUTUS_RANGE[lvl]
	b.died.connect(_on_enemy_died.bind("brutus"))
	b.died.connect(func(): _try_drop_key(b))
	b.position = _edge_pos()

func _spawn_boss() -> void:
	var b := BOSS.instantiate()
	add_child(b)
	b.died.connect(_on_enemy_died.bind("boss"))
	b.died.connect(_on_boss_defeated)
	b.position = Vector2(1016, 130)

func _on_boss_defeated() -> void:
	PlayerData.victories_total += 1
	# Unlock characters selon nombre de victoires
	if PlayerData.victories_total >= 1 and not ("zealot" in PlayerData.unlocked_chars):
		PlayerData.unlocked_chars.append("zealot")
	if PlayerData.victories_total >= 5 and not ("paladin" in PlayerData.unlocked_chars):
		PlayerData.unlocked_chars.append("paladin")
	PlayerData.save()
	# Drop garanti du boss : 5 clés
	for i in 5:
		add_key()
	PlayerData.reset_run()

func _end_round() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	$ShopMenu.show_shop(_keys, _level)

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

func _try_drop_key(enemy: Node2D) -> void:
	_kills_this_round += 1
	var chance := KEY_DROP_CHANCE_EARLY if (_level <= 2 and _kills_this_round <= 5) else KEY_DROP_CHANCE
	if randf() < chance:
		var key := KEY_SCENE.instantiate()
		key.global_position = enemy.global_position
		call_deferred("add_child", key)

func add_key() -> void:
	_keys += 1
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_keys(_keys)

func _on_enemy_died(enemy_type: String) -> void:
	var base_souls := 0
	match enemy_type:
		"aldrich": base_souls = 1
		"brutus":  base_souls = 3
		"boss":    base_souls = 50
		_:         base_souls = 1
	var mult := PlayerData.get_curse_soul_multiplier()
	PlayerData.souls += maxi(1, int(ceil(float(base_souls) * (1.0 + PlayerData.soul_bonus_rate) * mult)))
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_souls(PlayerData.souls)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.on_enemy_kill()

func _on_round_continue(remaining_keys: int) -> void:
	_keys = remaining_keys
	_kills_this_round = 0
	_level += 1
	PlayerData.player_level = _level
	PlayerData._recompute()
	_round_timer  = _round_duration()
	_spawn_timer  = 0.0
	_brutus_timer = 0.0
	_boss_spawned = false
	$Player.global_position = Vector2(1016, 517)
	$Player.revive()
	$Player.on_wave_start()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_hp(PlayerData.max_hp, PlayerData.max_hp)
		hud.refresh_level(_level)
		hud.refresh_timer(int(_round_duration()))
		hud.refresh_keys(_keys)
		hud.refresh_souls(PlayerData.souls)
		hud.refresh_items()
