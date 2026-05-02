extends Node

const FIREBALL      := preload("res://scenes/entities/Fireball.tscn")
const FIRE_TRAIL    := preload("res://scenes/entities/FireTrail.tscn")
const EXPLOSION     := preload("res://scenes/entities/BulletExplosion.tscn")
const BRUTUS_BULLET := preload("res://scenes/entities/BrutusBullet.tscn")

var _fireballs      : Array = []
var _trails         : Array = []
var _explosions     : Array = []
var _brutus_bullets : Array = []

func get_fireball(arena: Node) -> Node:
	var fb: Node
	if _fireballs.is_empty():
		fb = FIREBALL.instantiate()
		arena.add_child(fb)
	else:
		fb = _fireballs.pop_back()
		fb.reparent(arena, false)
	fb.visible    = true
	fb.set_process(true)
	fb.monitoring = true
	fb.monitorable = true
	return fb

func release_fireball(fb: Node) -> void:
	fb.set_process(false)
	fb.monitoring  = false
	fb.monitorable = false
	fb.visible     = false
	fb.reparent(self, false)
	_fireballs.append(fb)

func get_trail(arena: Node) -> Node:
	var t: Node
	if _trails.is_empty():
		t = FIRE_TRAIL.instantiate()
		arena.add_child(t)
	else:
		t = _trails.pop_back()
		t.reparent(arena, false)
	t.visible    = true
	t.set_process(true)
	t.monitoring = true
	t.monitorable = true
	t.reinit()
	return t

func release_trail(t: Node) -> void:
	t.set_process(false)
	t.monitoring  = false
	t.monitorable = false
	t.visible     = false
	t.reparent(self, false)
	_trails.append(t)

func get_explosion(arena: Node) -> Node:
	var e: Node
	if _explosions.is_empty():
		e = EXPLOSION.instantiate()
		arena.add_child(e)
	else:
		e = _explosions.pop_back()
		e.reparent(arena, false)
	e.visible     = true
	e.set_process(true)
	e.monitoring  = true
	e.monitorable = true
	return e

func release_explosion(e: Node) -> void:
	e.set_process(false)
	e.monitoring  = false
	e.monitorable = false
	e.visible     = false
	e.reparent(self, false)
	_explosions.append(e)

func get_brutus_bullet(arena: Node) -> Node:
	var b: Node
	if _brutus_bullets.is_empty():
		b = BRUTUS_BULLET.instantiate()
		arena.add_child(b)
	else:
		b = _brutus_bullets.pop_back()
		b.reparent(arena, false)
	b.visible     = true
	b.set_physics_process(true)
	b.monitoring  = true
	b.monitorable = true
	return b

func release_brutus_bullet(b: Node) -> void:
	b.set_physics_process(false)
	b.monitoring  = false
	b.monitorable = false
	b.visible     = false
	b.reparent(self, false)
	_brutus_bullets.append(b)
