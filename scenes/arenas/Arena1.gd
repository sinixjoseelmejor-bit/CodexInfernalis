extends Node2D

const ALDRICH              := preload("res://scenes/entities/Aldrich.tscn")
const BRUTUS               := preload("res://scenes/entities/Brutus.tscn")
const BOSS                 := preload("res://scenes/entities/Golgota.tscn")
const BASE_SPAWN_INTERVAL  := 1.00
const MIN_SPAWN_INTERVAL   := 0.60
const BRUTUS_BASE_INTERVAL := 22.0
const BRUTUS_MIN_INTERVAL  := 9.0
const ROUND_DURATION       := 40.0

const ARENA_CENTER := Vector2(1016, 517)

var _spawn_timer  := 0.0
var _brutus_timer := 0.0
var _keys         := 0
var _round_timer  := ROUND_DURATION
var _level        := 1
var _boss_spawned := false

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
			get_viewport().set_input_as_handled()

func _cheat_give_items() -> void:
	var want := ["fire_boots", "auto_grenade", "storm_ring", "soul_harvester",
				 "vampire_amulet", "thorn_shield", "rage_ring", "phantom_step"]
	for id in want:
		PlayerData.add_item(id)
	PlayerData.souls     += 999
	PlayerData.lvl_hp      = PlayerData.MAX_LEVEL
	PlayerData.lvl_damage  = PlayerData.MAX_LEVEL
	PlayerData.lvl_speed   = PlayerData.MAX_LEVEL
	PlayerData.lvl_fire_cd = PlayerData.MAX_LEVEL
	PlayerData._recompute()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.hp = PlayerData.max_hp
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_souls(PlayerData.souls)
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
	_level        = 7
	_boss_spawned = false
	_round_timer  = ROUND_DURATION
	_spawn_timer  = 0.0
	_brutus_timer = 0.0
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_level(_level)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if _level < 7:
		_spawn_timer += delta
		if _spawn_timer >= _spawn_interval():
			_spawn_timer = 0.0
			for i in _spawn_count():
				_spawn_aldrich()

	if _level >= 2 and _level < 7:
		_brutus_timer += delta
		if _brutus_timer >= _brutus_interval():
			_brutus_timer = 0.0
			_spawn_brutus()
	if _level >= 7 and not _boss_spawned:
		_boss_spawned = true
		_spawn_boss()
	var hud := get_tree().get_first_node_in_group("hud")
	if _level >= 7:
		if hud:
			hud.refresh_timer(-1)
		return
	_round_timer -= delta
	if _round_timer <= 0.0:
		_round_timer = 0.0
		_end_round()
		return
	if hud:
		hud.refresh_timer(int(ceil(_round_timer)))

func _spawn_interval() -> float:
	return max(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL * pow(0.74, _level - 1))

func _brutus_interval() -> float:
	return max(BRUTUS_MIN_INTERVAL, BRUTUS_BASE_INTERVAL - (_level - 2) * 1.5)

func _spawn_count() -> int:
	return 1

func _edge_pos() -> Vector2:
	match randi() % 4:
		0: return Vector2(randf_range(120, 1800), 110)
		1: return Vector2(randf_range(120, 1800), 940)
		2: return Vector2(115, randf_range(110, 940))
		_: return Vector2(1900, randf_range(110, 940))

func _spawn_aldrich() -> void:
	var a := ALDRICH.instantiate()
	add_child(a)
	a.key_drop_chance = max(0.03, 0.15 - (_level - 1) * 0.024)
	a.hp = int(3 * pow(1.35, _level - 1))
	a.died.connect(_on_enemy_died)
	a.position = _edge_pos()

func _spawn_brutus() -> void:
	var b := BRUTUS.instantiate()
	add_child(b)
	b.hp = 15 + (_level - 2) * 6
	b.died.connect(_on_enemy_died)
	b.position = _edge_pos()

func _spawn_boss() -> void:
	var b := BOSS.instantiate()
	add_child(b)
	b.died.connect(_on_enemy_died)
	b.died.connect(_on_boss_defeated)
	b.position = Vector2(1016, 130)

func _on_boss_defeated() -> void:
	PlayerData.reset_run()

func _end_round() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	$ShopMenu.show_shop(_keys)

func add_key() -> void:
	_keys += 1
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_keys(_keys)

func _on_enemy_died() -> void:
	var bonus := PlayerData.item_count("soul_harvester")
	PlayerData.souls += 1 + bonus
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_souls(PlayerData.souls)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.on_enemy_kill()

func _on_round_continue(remaining_keys: int) -> void:
	_keys = remaining_keys
	_level += 1
	_round_timer  = ROUND_DURATION
	_spawn_timer  = 0.0
	_brutus_timer = 0.0
	_boss_spawned = false
	$Player.global_position = Vector2(1016, 517)
	$Player.hp = PlayerData.max_hp
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_hp(PlayerData.max_hp, PlayerData.max_hp)
		hud.refresh_level(_level)
		hud.refresh_timer(int(ROUND_DURATION))
		hud.refresh_keys(_keys)
		hud.refresh_souls(PlayerData.souls)
		hud.refresh_items()
