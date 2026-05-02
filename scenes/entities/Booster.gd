extends "res://scenes/entities/BaseEnemy.gd"

const FLEE_RADIUS   := 380.0
const DESIRED_DIST  := 680.0
const AURA_RADIUS   := 280.0
const SPEED_BOOST   := 0.40
const BUFF_INTERVAL := 0.5

var _buff_timer := 0.0

func _setup() -> void:
	hp    = 80
	speed = 130.0
	add_to_group("boosters")
	_setup_animations()

func _setup_animations() -> void:
	var frames   := SpriteFrames.new()
	var lev_base := "res://assets/Characters/booster/animations/levitation-11aba404/"
	var rot_base := "res://assets/Characters/booster/rotations/"
	var dirs     := ["south","north","east","west","south-east","south-west","north-east","north-west"]

	for dir in dirs:
		var anim: String = "levitation_" + (dir as String).replace("-", "_")
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 8.0)
		for i in 9:
			frames.add_frame(anim, load(lev_base + dir + "/frame_%03d.png" % i))

		var idle: String = "idle_" + (dir as String).replace("-", "_")
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 5.0)
		frames.add_frame(idle, load(rot_base + dir + ".png"))

	var death_sheet := load("res://assets/Characters/booster/animations/BoosterDeath.png")
	frames.add_animation("death")
	frames.set_animation_speed("death", 8.0)
	frames.set_animation_loop("death", false)
	for row in 3:
		for col in 3:
			var atlas := AtlasTexture.new()
			atlas.atlas  = death_sheet
			atlas.region = Rect2(col * 180, row * 180, 180, 180)
			frames.add_frame("death", atlas)

	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)
	$AnimatedSprite2D.play("idle_south")

func _on_anim_finished() -> void:
	if $AnimatedSprite2D.animation == "death":
		queue_free()

func _tint(color: Color) -> void:
	$AnimatedSprite2D.modulate = color

func _normal_tint() -> Color:
	return Color(1.0, 1.0, 1.0, 1.0)

func _ai(delta: float) -> void:
	_buff_timer -= delta
	if _buff_timer <= 0.0:
		_buff_timer = BUFF_INTERVAL
		_apply_aura()

	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_do_wander(delta)
		return

	var to_player: Vector2 = (player as Node2D).global_position - global_position
	var dist: float = to_player.length()
	var move_dir: Vector2
	if dist < FLEE_RADIUS:
		move_dir = -to_player.normalized()
	elif dist > DESIRED_DIST + 120.0:
		move_dir = to_player.normalized() * 0.35
	else:
		move_dir = to_player.normalized().rotated(PI * 0.5) * 0.4
	velocity = move_dir * speed * _slow_factor
	move_and_slide()
	if move_dir.length_squared() > 0.001:
		$AnimatedSprite2D.play("levitation_" + _dir_name(move_dir))

func _apply_aura() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self:
			continue
		var e := enemy as Node2D
		if global_position.distance_to(e.global_position) <= AURA_RADIUS:
			if enemy.has_method("apply_booster_buff"):
				enemy.apply_booster_buff(SPEED_BOOST, BUFF_INTERVAL * 2.5)

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(2.0, 4.5)
	velocity = _wander_dir * speed * 0.4
	move_and_slide()
	if _wander_dir.length_squared() > 0.001:
		$AnimatedSprite2D.play("levitation_" + _dir_name(_wander_dir))

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
