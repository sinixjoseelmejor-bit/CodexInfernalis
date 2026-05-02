extends "res://scenes/entities/BaseEnemy.gd"

const DASH_INTERVAL := 2.5
const DASH_DURATION := 0.45
const DASH_SPEED    := 860.0

const _SHEET_POS  := preload("res://assets/Characters/kael/Spider8positions.png")
const _SHEET_JUMP := preload("res://assets/Characters/kael/SpiderJump.png")

var _dash_timer   := 0.0
var _dash_active  := false
var _dash_elapsed := 0.0
var _dash_dir     := Vector2.ZERO

# direction → (col, row) in Spider8positions 128×128 grid
const _DIR_CELLS := {
	"south":      Vector2i(0, 0),
	"south_east": Vector2i(1, 0),
	"east":       Vector2i(2, 0),
	"north_east": Vector2i(0, 1),
	"north":      Vector2i(1, 1),
	"north_west": Vector2i(2, 1),
	"west":       Vector2i(0, 2),
	"south_west": Vector2i(1, 2),
}

func _setup() -> void:
	speed         = 160.0
	hp            = 10
	damage        = 8
	_sep_radius   = 48.0
	_sep_strength = 100.0
	_dash_timer   = randf_range(0.5, DASH_INTERVAL)
	_setup_animations()

func _setup_animations() -> void:
	var frames := SpriteFrames.new()

	for dir in _DIR_CELLS:
		var cell : Vector2i = _DIR_CELLS[dir]
		var atlas := AtlasTexture.new()
		atlas.atlas  = _SHEET_POS
		atlas.region = Rect2(cell.x * 128, cell.y * 128, 128, 128)
		frames.add_animation("idle_" + dir)
		frames.set_animation_speed("idle_" + dir, 1.0)
		frames.add_frame("idle_" + dir, atlas)

	frames.add_animation("dash")
	frames.set_animation_speed("dash", 18.0)
	frames.set_animation_loop("dash", true)
	for row in 3:
		for col in 3:
			var atlas := AtlasTexture.new()
			atlas.atlas  = _SHEET_JUMP
			atlas.region = Rect2(col * 128, row * 128, 128, 128)
			frames.add_frame("dash", atlas)

	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.play("idle_south")

func _tint(color: Color) -> void:
	$AnimatedSprite2D.modulate = color

func _normal_tint() -> Color:
	return Color(1.0, 1.0, 1.0, 1.0)

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

func _ai(delta: float) -> void:
	var player_dead: bool = player == null or player.get("_dead") == true
	if player_dead:
		_do_wander(delta)
		return

	if _dash_active:
		_dash_elapsed += delta
		velocity = _dash_dir * DASH_SPEED
		move_and_slide()
		$AnimatedSprite2D.play("dash")
		if _dash_elapsed >= DASH_DURATION:
			_dash_active = false
		return

	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_dash_timer   = DASH_INTERVAL + randf_range(-0.5, 0.5)
		_dash_active  = true
		_dash_elapsed = 0.0
		var to_player    := player.global_position - global_position
		var travel_time  := to_player.length() / DASH_SPEED
		var predicted    : Vector2 = player.global_position + (player as CharacterBody2D).velocity * travel_time
		_dash_dir = (predicted - global_position).normalized()
		return

	var dir := _nav_dir_to(player.global_position)
	velocity = dir * speed * _slow_factor * _boost_factor + _separation()
	move_and_slide()
	$AnimatedSprite2D.play("idle_" + _dir_name(dir))

func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_dir   = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_wander_timer = randf_range(1.5, 3.5)
	velocity = _wander_dir * speed * 0.5 + _separation()
	move_and_slide()
	$AnimatedSprite2D.play("idle_" + _dir_name(_wander_dir))

func _die() -> void:
	super._die()
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
