extends Area2D

const SPEED_BASE   := 1200.0
const SPEED_FAST   := 2020.0
const MAX_DISTANCE := 400.0
const HIT_SOUND    := preload("res://sounds/sfx/FireballSound.mp3")

var direction    := Vector2.ZERO
var _traveled    := 0.0
var _damage      := 1
var _hits_left   := 1
var _hit_count   := 0
var _bounced     := false
var _is_crit     := false

func init(dir: Vector2, dmg: int = 1, is_crit: bool = false) -> void:
	_traveled  = 0.0
	_hit_count = 0
	_bounced   = false
	_damage    = dmg
	_is_crit   = is_crit
	direction  = dir.normalized()
	rotation   = direction.angle()
	if PlayerData.has_skill("percant"):
		_hits_left = 999
	elif PlayerData.has_skill("penetration"):
		_hits_left = 4
	else:
		_hits_left = 2

func _pool_return() -> void:
	BulletPool.release_fireball(self)

func _process(delta: float) -> void:
	var spd  := SPEED_FAST if PlayerData.has_skill("velocite") else SPEED_BASE
	var move := direction * spd * delta
	position += move
	_traveled += move.length()
	if _traveled >= MAX_DISTANCE + PlayerData.flat_range:
		call_deferred("_pool_return")

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	var threshold := 2 if PlayerData.has_skill("penetration") else 1
	var actual_dmg := _damage
	if _hit_count >= threshold:
		actual_dmg = maxi(1, _damage >> 1)
	_hit_count += 1
	if _hit_count == 1:
		var snd := AudioStreamPlayer.new()
		snd.stream = HIT_SOUND
		snd.volume_db = -10.0
		get_parent().add_child(snd)
		snd.play()
		snd.finished.connect(snd.queue_free)
	body.take_damage(actual_dmg)
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_hit"):
		player.on_enemy_hit(body, actual_dmg, _is_crit)

	if PlayerData.has_skill("explosion"):
		call_deferred("_spawn_explosion", get_parent(), global_position, _damage)

	_hits_left -= 1
	if _hits_left <= 0:
		if PlayerData.has_skill("ricochet") and not _bounced:
			_do_ricochet(body)
		else:
			call_deferred("_pool_return")

func _spawn_explosion(arena: Node, pos: Vector2, dmg: int) -> void:
	if not is_instance_valid(arena):
		return
	var blast := BulletPool.get_explosion(arena)
	blast.global_position = pos
	blast.reinit(dmg)

func _do_ricochet(from_body: Node) -> void:
	_bounced   = true
	_hits_left = 1
	var enemies  := get_tree().get_nodes_in_group("enemies")
	var best     : Node2D = null
	var best_dist := 400.0
	for e in enemies:
		if e == from_body:
			continue
		var d := global_position.distance_to((e as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			best      = e
	if best == null:
		call_deferred("_pool_return")
		return
	direction = (best.global_position - global_position).normalized()
	rotation  = direction.angle()
