extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var arena := get_tree().get_first_node_in_group("arena")
		if arena:
			arena.add_key()
		queue_free()
