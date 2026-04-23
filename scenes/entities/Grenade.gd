extends Area2D

const FUSE_TIME    := 0.9
const BLAST_RADIUS := 220.0
const MOVE_SPEED   := 320.0
const ROTATE_SPEED := 6.0

var _dir      := Vector2.ZERO
var _fuse     := 0.0
var _exploded := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_setup_explosion()

func _setup_explosion() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("explode")
	frames.set_animation_speed("explode", 14.0)
	frames.set_animation_loop("explode", false)
	var sheet := load("res://assets/effects/HolyGrenadeExplosion.png") as Texture2D
	for row in 3:
		for col in 4:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * 64, row * 64, 64, 64)
			frames.add_frame("explode", atlas)
	$Explosion.sprite_frames = frames
	$Explosion.animation_finished.connect(queue_free)

func init(target_pos: Vector2) -> void:
	_dir = (target_pos - global_position).normalized()

func _process(delta: float) -> void:
	if _exploded:
		return
	position += _dir * MOVE_SPEED * delta
	$Visual.rotation += ROTATE_SPEED * delta
	_fuse += delta
	if _fuse >= FUSE_TIME:
		_explode()

func _explode() -> void:
	_exploded = true
	for body in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(body.global_position) <= BLAST_RADIUS:
			body.take_damage(maxi(8, PlayerData.damage * 4))
	$Visual.hide()
	var final_scale := BLAST_RADIUS * 2.0 * 0.6 / 64.0
	var frame_count : int = $Explosion.sprite_frames.get_frame_count("explode")
	var anim_duration : float = float(frame_count) / float($Explosion.sprite_frames.get_animation_speed("explode"))
	$Explosion.scale = Vector2.ONE
	$Explosion.show()
	$Explosion.play("explode")
	var tween := create_tween()
	tween.tween_property($Explosion, "scale", Vector2.ONE * final_scale, anim_duration)
