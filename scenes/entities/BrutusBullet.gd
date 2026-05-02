extends Area2D

const LIFETIME := 3.0

var _dir    := Vector2.RIGHT
var damage  := 1
var speed   := 280.0
var _life   := 0.0
var _active := false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func init(direction: Vector2, dmg: int, bullet_speed: float = 280.0) -> void:
	_dir    = direction.normalized()
	damage  = dmg
	speed   = bullet_speed
	_life   = 0.0
	_active = true
	rotation = _dir.angle()

func _pool_return() -> void:
	_active = false
	BulletPool.release_brutus_bullet(self)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	position += _dir * speed * delta
	_life    += delta
	if _life >= LIFETIME:
		call_deferred("_pool_return")

func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if body.is_in_group("player"):
		body.take_damage(damage)
	call_deferred("_pool_return")
