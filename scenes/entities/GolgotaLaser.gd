extends Node2D

const TELEGRAPH  := 1.2
const LOCK_DELAY := 0.2
const ACTIVE     := 0.5
const LENGTH    := 950.0
const LASER_TEX := preload("res://assets/projectiles/Laser.png")

var _phase         := "telegraph"
var _timer         := TELEGRAPH
var _telegraph_dur := TELEGRAPH
var _tracking      := true
var _damage := 5
var _dir    := Vector2.RIGHT
var _area   : Area2D
var _spr    : Sprite2D

func init(direction: Vector2, dmg: int, telegraph: float = TELEGRAPH, tracking: bool = true) -> void:
	_damage        = dmg
	_dir           = direction.normalized()
	_telegraph_dur = telegraph
	_tracking      = tracking

func _ready() -> void:
	_timer   = _telegraph_dur
	rotation = _dir.angle()

	_spr          = Sprite2D.new()
	_spr.texture  = LASER_TEX
	var tex_w     := float(LASER_TEX.get_width())
	_spr.scale    = Vector2(LENGTH / tex_w, 1.2)
	_spr.position = Vector2(LENGTH * 0.5, 0.0)
	_spr.modulate = Color(1.4, 0.4, 0.2, 0.0)
	add_child(_spr)

	_area                  = Area2D.new()
	_area.collision_layer  = 0
	_area.collision_mask   = 1
	_area.monitoring       = false
	_area.body_entered.connect(_on_body_entered)
	var shape   := CollisionShape2D.new()
	var rect    := RectangleShape2D.new()
	rect.size   = Vector2(LENGTH, float(LASER_TEX.get_height()) * 1.2)
	shape.shape    = rect
	shape.position = Vector2(LENGTH * 0.5, 0.0)
	_area.add_child(shape)
	add_child(_area)

func _process(delta: float) -> void:
	_timer -= delta
	if _phase == "telegraph":
		if _timer > LOCK_DELAY:
			if _tracking:
				var player := get_tree().get_first_node_in_group("player")
				if player and is_instance_valid(player):
					rotation = (player.global_position - global_position).angle()
			var progress := 1.0 - ((_timer - LOCK_DELAY) / (_telegraph_dur - LOCK_DELAY))
			_spr.modulate = Color(1.5, 0.8, 0.1, progress * 0.4)
		else:
			# Direction locked — bright warning flash
			var lock_progress := 1.0 - (_timer / LOCK_DELAY)
			_spr.modulate = Color(1.5, 0.2, 0.05, 0.4 + lock_progress * 0.4)
		if _timer <= 0.0:
			_phase           = "active"
			_timer           = ACTIVE
			_spr.scale.y     = 2.2
			for child in _area.get_children():
				if child is CollisionShape2D:
					(child.shape as RectangleShape2D).size.y = float(LASER_TEX.get_height()) * 2.2
			_spr.modulate    = Color(1.0, 1.0, 1.0, 1.0)
			_area.monitoring = true
	elif _phase == "active":
		if _timer <= 0.0:
			queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(_damage)
