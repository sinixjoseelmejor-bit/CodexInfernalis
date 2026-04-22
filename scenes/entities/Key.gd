extends Area2D

const MAGNET_SPEED := 320.0

var _player : Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if _player.get("_dead") == true:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist < PlayerData.pickup_range:
		global_position = global_position.move_toward(_player.global_position, MAGNET_SPEED * delta)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var arena := get_tree().get_first_node_in_group("arena")
		if arena:
			arena.add_key()
		queue_free()
