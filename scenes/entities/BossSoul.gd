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
		PlayerData.save()
		PlayerData.reset_run()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/MainMenu.tscn")
