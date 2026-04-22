extends Area2D

const LIFETIME := 3.0

var _dir   := Vector2.RIGHT
var damage := 1
var speed  := 280.0

func init(direction: Vector2, dmg: int, bullet_speed: float = 280.0) -> void:
	_dir     = direction.normalized()
	damage   = dmg
	speed    = bullet_speed
	rotation = _dir.angle()

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += _dir * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()
