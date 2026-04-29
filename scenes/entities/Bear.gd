extends Node2D

const SHEET_IDLE  := preload("res://assets/Characters/Serayne/invocation/Bear.png")
const SHEET_ATK_L := preload("res://assets/Characters/Serayne/invocation/bearAttackLeft.PNG")
const SHEET_ATK_R := preload("res://assets/Characters/Serayne/invocation/bearAttackRight.png")

const SPEED       := 420.0
const RANGE       := 350.0
const ATTACK_DIST := 60.0

var _target  : Node2D = null
var _damage  := 1
var _is_crit := false
var _hitting := false

func init(damage: int, is_crit: bool) -> void:
	_damage  = damage
	_is_crit = is_crit
	_build_frames()
	$AnimatedSprite2D.play("idle")
	_find_target()

func _build_frames() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.set_animation_speed("idle", 10.0)
	for f in _slice_sheet(SHEET_IDLE, 3, 3, 120, 120):
		sf.add_frame("idle", f)
	sf.add_animation("attack_left")
	sf.set_animation_speed("attack_left", 12.0)
	sf.set_animation_loop("attack_left", false)
	for f in _slice_sheet(SHEET_ATK_L, 3, 3, 128, 128):
		sf.add_frame("attack_left", f)
	sf.add_animation("attack_right")
	sf.set_animation_speed("attack_right", 12.0)
	sf.set_animation_loop("attack_right", false)
	for f in _slice_sheet(SHEET_ATK_R, 3, 3, 128, 128):
		sf.add_frame("attack_right", f)
	$AnimatedSprite2D.sprite_frames = sf
	$AnimatedSprite2D.animation_finished.connect(_on_attack_finished)

func _slice_sheet(sheet: Texture2D, cols: int, rows: int, fw: int, fh: int) -> Array:
	var result := []
	for row in rows:
		for col in cols:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * fw, row * fh, fw, fh)
			result.append(atlas)
	return result

func _find_target() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest : Node2D = null
	var nearest_dist := INF
	for e in enemies:
		if (e as Node2D).get("dead") == true:
			continue
		var d := global_position.distance_to((e as Node2D).global_position)
		if d < nearest_dist and d <= RANGE:
			nearest_dist = d
			nearest = e as Node2D
	if nearest == null:
		queue_free()
		return
	_target = nearest

func _process(delta: float) -> void:
	if _hitting or _target == null:
		return
	if not is_instance_valid(_target) or _target.get("dead") == true:
		queue_free()
		return
	var to := _target.global_position - global_position
	if to.length() <= ATTACK_DIST:
		_strike()
	else:
		global_position += to.normalized() * SPEED * delta

func _strike() -> void:
	_hitting = true
	if is_instance_valid(_target) and "grabbed" in _target:  # Golgota has no grabbed property
		_target.grabbed = true
	var anim := "attack_left" if _target.global_position.x < global_position.x else "attack_right"
	$AnimatedSprite2D.play(anim)
	_deal_tick()
	await get_tree().create_timer(0.25).timeout
	_deal_tick()

const AOE_RADIUS := 120.0

func _deal_tick() -> void:
	var player := get_tree().get_first_node_in_group("player")
	for e in get_tree().get_nodes_in_group("enemies"):
		if (e as Node2D).get("dead") == true:
			continue
		if global_position.distance_to((e as Node2D).global_position) <= AOE_RADIUS:
			e.take_damage(_damage)
			if player and player.has_method("on_enemy_hit"):
				player.on_enemy_hit(e, _damage, _is_crit)

func _on_attack_finished() -> void:
	if is_instance_valid(_target) and "grabbed" in _target:
		_target.grabbed = false
	queue_free()
