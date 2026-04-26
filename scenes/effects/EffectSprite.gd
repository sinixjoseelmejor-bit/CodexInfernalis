@tool
extends AnimatedSprite2D

@export_file("*.png") var texture_path : String = "" :
	set(v):
		texture_path = v
		if Engine.is_editor_hint():
			_refresh()

@export var cols : int = 3 :
	set(v):
		cols = maxi(1, v)
		if Engine.is_editor_hint():
			_refresh()
@export var total_frames : int = 6 :
	set(v):
		total_frames = maxi(1, v)
		if Engine.is_editor_hint():
			_refresh()
@export var fps : float = 8.0 :
	set(v):
		fps = maxf(1.0, v)
		if Engine.is_editor_hint():
			_refresh()
@export var looping : bool = false :
	set(v):
		looping = v
		if Engine.is_editor_hint():
			_refresh()

func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh()
	else:
		if sprite_frames and sprite_frames.has_animation("play"):
			if not looping and not animation_finished.is_connected(queue_free):
				animation_finished.connect(queue_free)
			play("play")

func _refresh() -> void:
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return
	var tex := load(texture_path) as Texture2D
	if tex == null:
		return
	var tex_size := tex.get_size()
	var rows     := ceili(float(total_frames) / float(cols))
	var fw       := tex_size.x / float(cols)
	var fh       := tex_size.y / float(rows)

	var sf := SpriteFrames.new()
	sf.add_animation("play")
	sf.set_animation_loop("play", looping)
	sf.set_animation_speed("play", fps)
	for i in total_frames:
		var atlas   := AtlasTexture.new()
		atlas.atlas  = tex
		@warning_ignore("INTEGER_DIVISION")
		atlas.region = Rect2((i % cols) * fw, (i / cols) * fh, fw, fh)
		sf.add_frame("play", atlas)
	sprite_frames = sf
	play("play")
