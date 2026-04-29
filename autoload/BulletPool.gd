extends Node

const FIREBALL   := preload("res://scenes/entities/Fireball.tscn")
const FIRE_TRAIL := preload("res://scenes/entities/FireTrail.tscn")

var _fireballs : Array = []
var _trails    : Array = []

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
