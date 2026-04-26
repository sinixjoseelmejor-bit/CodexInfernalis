extends Area2D

const SHEET := preload("res://assets/Characters/Golgota/GolgotaSoul.png")
const FRAME_SIZE := 108

func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 8.0)
	for row in 3:
		for col in 3:
			var atlas        := AtlasTexture.new()
			atlas.atlas      = SHEET
			atlas.region     = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame("idle", atlas)
	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("idle")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		PlayerData.boss_souls += 1
		var arena := get_tree().get_first_node_in_group("arena")
		if arena:
			arena.on_boss_soul_collected()
		queue_free()
