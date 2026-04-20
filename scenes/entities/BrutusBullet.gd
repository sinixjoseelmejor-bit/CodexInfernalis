extends Area2D

const SPEED  := 420.0
const LIFETIME := 3.0

var _dir   := Vector2.RIGHT
var damage := 1

func init(direction: Vector2, dmg: int) -> void:
	_dir   = direction.normalized()
	damage = dmg
	rotation = _dir.angle()

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += _dir * SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()
