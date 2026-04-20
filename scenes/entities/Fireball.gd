extends Area2D

const SPEED_BASE   := 1200.0
const SPEED_FAST   := 2020.0
const MAX_DISTANCE := 400.0
const EXPLOSION    := preload("res://scenes/entities/BulletExplosion.tscn")

var direction    := Vector2.ZERO
var _traveled    := 0.0
var _damage      := 1
var _hits_left   := 1
var _hit_count   := 0
var _bounced     := false

func init(dir: Vector2, dmg: int = 1) -> void:
	_damage    = dmg
	direction  = dir.normalized()
	rotation   = direction.angle()
	_hits_left = 4 if PlayerData.has_skill("penetration") else 2

func _process(delta: float) -> void:
	var spd  := SPEED_FAST if PlayerData.has_skill("velocite") else SPEED_BASE
	var move := direction * spd * delta
	position += move
	_traveled += move.length()
	if _traveled >= MAX_DISTANCE:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	var threshold := 2 if PlayerData.has_skill("penetration") else 1
	var actual_dmg := _damage
	if _hit_count >= threshold:
		actual_dmg = maxi(1, _damage / 2)
	_hit_count += 1
	body.take_damage(actual_dmg)
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_enemy_hit"):
		player.on_enemy_hit(actual_dmg)

	if PlayerData.has_skill("explosion"):
		var blast := EXPLOSION.instantiate()
		blast.global_position = global_position
		blast.damage = _damage
		get_parent().call_deferred("add_child", blast)

	_hits_left -= 1
	if _hits_left <= 0:
		if PlayerData.has_skill("ricochet") and not _bounced:
			_do_ricochet(body)
		else:
			queue_free()

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
		queue_free()
		return
	direction = (best.global_position - global_position).normalized()
	rotation  = direction.angle()
