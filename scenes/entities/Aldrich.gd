extends "res://scenes/entities/BaseEnemy.gd"

const DEATH_SOUND := preload("res://sounds/sfx/AldrichdeatSound.mp3")

func _setup() -> void:
	speed         = 90.0
	hp            = 3
	damage        = 1
	_sep_radius   = 58.0
	_sep_strength = 120.0
	_setup_animations()
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)

func _setup_animations() -> void:
	var frames     := SpriteFrames.new()
	var walk_base  := "res://assets/Characters/Aldrich/animations/AldrichWalk-ca79f0eb/"
	var death_base := "res://assets/Characters/Aldrich/animations/AldrichDeath-7904336b/"
	var rot_base   := "res://assets/Characters/Aldrich/rotations/"
	var dirs := ["south","north","east","west","south-east","south-west","north-east","north-west"]

	for dir in dirs:
		var anim: String = "walk_" + (dir as String).replace("-", "_")
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 10.0)
		for i in 11:
			frames.add_frame(anim, load(walk_base + dir + "/frame_%03d.png" % i))

		var idle: String = "idle_" + (dir as String).replace("-", "_")
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 5.0)
		frames.add_frame(idle, load(rot_base + dir + ".png"))

	frames.add_animation("death")
	frames.set_animation_speed("death", 8.0)
	frames.set_animation_loop("death", false)
	for i in 11:
		frames.add_frame("death", load(death_base + "south/frame_%03d.png" % i))

	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("idle_south")

func teleport_to_edge() -> void:
	super.teleport_to_edge()
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color(1, 1, 1, 1), 0.3)

func _tint(color: Color) -> void:
	$AnimatedSprite2D.modulate = color

func _ai(delta: float) -> void:
	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_do_wander(delta)
	else:
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * speed * _slow_factor * _boost_factor + _separation()
		move_and_slide()
		$AnimatedSprite2D.play("walk_" + _dir_name(dir))

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(1.5, 3.5)
	velocity = _wander_dir * speed * 0.5 * _boost_factor + _separation()
	move_and_slide()
	$AnimatedSprite2D.play("walk_" + _dir_name(_wander_dir))

func _dir_name(dir: Vector2) -> String:
	var deg := fmod(rad_to_deg(dir.angle()) + 360.0, 360.0)
	if   deg < 22.5 or deg >= 337.5: return "east"
	elif deg < 67.5:                  return "south_east"
	elif deg < 112.5:                 return "south"
	elif deg < 157.5:                 return "south_west"
	elif deg < 202.5:                 return "west"
	elif deg < 247.5:                 return "north_west"
	elif deg < 292.5:                 return "north"
	else:                             return "north_east"

func _die() -> void:
	super._die()
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimatedSprite2D.play("death")
	var snd := AudioStreamPlayer.new()
	snd.stream    = DEATH_SOUND
	snd.volume_db = -35.0
	add_child(snd)
	snd.play()
	snd.finished.connect(snd.queue_free)

func _on_anim_finished() -> void:
	if $AnimatedSprite2D.animation == "death":
		queue_free()
