extends Node

var _frames_cache: Dictionary = {}

func get_player_frames(char_id: String) -> SpriteFrames:
	if _frames_cache.has(char_id):
		return _frames_cache[char_id]
	var frames: SpriteFrames
	match char_id:
		"serayne":
			frames = _build_serayne_frames()
		_:
			frames = _build_neophyte_frames()
	_frames_cache[char_id] = frames
	return frames

func _build_neophyte_frames() -> SpriteFrames:
	var frames  := SpriteFrames.new()
	var run_b   := "res://assets/Characters/Neophyte/animations/walk/"
	var atk_b   := "res://assets/Characters/Neophyte/animations/fireball/"
	var death_b := "res://assets/Characters/Neophyte/animations/mort/"
	var rot_b   := "res://assets/Characters/Neophyte/rotations/"
	var dirs    := ["south","north","east","west","south-east","south-west","north-east","north-west"]
	var run_dir_map : Dictionary = {"east": "east-cd7532fa"}
	var atk_dir_map : Dictionary = {"south-west": "south-west-079a6897"}
	var run_counts  : Dictionary = {"south": 8}
	var atk_counts  : Dictionary = {"east": 5, "west": 5}
	for dir in dirs:
		var d := (dir as String).replace("-", "_")
		var run_dir : String = run_dir_map.get(dir, dir)
		var atk_dir : String = atk_dir_map.get(dir, dir)
		var run: String = "run_" + d
		frames.add_animation(run)
		frames.set_animation_speed(run, 10.0)
		for i in int(run_counts.get(dir, 7)):
			frames.add_frame(run, load(run_b + run_dir + "/frame_%03d.png" % i))
		var atk: String = "attack_" + d
		var atk_count: int = int(atk_counts.get(dir, 7))
		frames.add_animation(atk)
		frames.set_animation_speed(atk, 15.0)
		frames.set_animation_loop(atk, false)
		for i in atk_count:
			frames.add_frame(atk, load(atk_b + atk_dir + "/frame_%03d.png" % i))
		var idle: String = "idle_" + d
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 5.0)
		frames.add_frame(idle, load(rot_b + dir + ".png"))
	frames.add_animation("death")
	frames.set_animation_speed("death", 8.0)
	frames.set_animation_loop("death", false)
	for i in 9:
		frames.add_frame("death", load(death_b + "south/frame_%03d.png" % i))
	return frames

func _build_serayne_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var run_b  := "res://assets/Characters/Serayne/animations/The_wizard_steps_forward_with_a_steady_rhythmic_ga-ee30a20d/"
	var atk_b  := "res://assets/Characters/Serayne/animations/The_mage_stands_centered_her_expression_focused_as-86eecd19/"
	var rot_b  := "res://assets/Characters/Serayne/rotations/"
	var dirs   := ["south","north","east","west","south-east","south-west","north-east","north-west"]
	for dir in dirs:
		var d := (dir as String).replace("-", "_")
		var run := "run_" + d
		frames.add_animation(run)
		frames.set_animation_speed(run, 10.0)
		for i in 9:
			frames.add_frame(run, load(run_b + dir + "/frame_%03d.png" % i))
		var atk := "attack_" + d
		frames.add_animation(atk)
		frames.set_animation_speed(atk, 15.0)
		frames.set_animation_loop(atk, false)
		for i in 9:
			frames.add_frame(atk, load(atk_b + dir + "/frame_%03d.png" % i))
		var idle := "idle_" + d
		frames.add_animation(idle)
		frames.set_animation_speed(idle, 5.0)
		frames.add_frame(idle, load(rot_b + dir + ".png"))
	var death_sheet := load("res://assets/Characters/Serayne/animations/deathSerayne.png") as Texture2D
	frames.add_animation("death")
	frames.set_animation_speed("death", 8.0)
	frames.set_animation_loop("death", false)
	for row in 2:
		for col in 3:
			var atlas := AtlasTexture.new()
			atlas.atlas = death_sheet
			atlas.region = Rect2(col * 341, row * 256, 341, 256)
			frames.add_frame("death", atlas)
	return frames
