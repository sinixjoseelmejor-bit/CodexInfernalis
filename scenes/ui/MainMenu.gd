extends Control

var _vsp      : VideoStreamPlayer
var _fade     : ColorRect
var _mode     := ""   # "new_game" ou "continue"

const FADE_DUR := 0.5

func _ready() -> void:
	_vsp = $VideoStreamPlayer
	_vsp.loop = false
	var stream = load("res://assets/environment/MainMenuBackgroundV.ogv")
	if stream:
		_vsp.stream = stream
		_vsp.play()
		$FallbackBG.hide()
		_vsp.finished.connect(_on_video_finished)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.z_index = 1
	add_child(_fade)
	move_child(_fade, 1)

	$OptionsOverlay/Panel/VBox/FullscreenRow/FullscreenCheck.button_pressed = \
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

# ── Vidéo ────────────────────────────────────────────────────────────────────

func _on_video_finished() -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, FADE_DUR)
	tween.tween_callback(func() -> void:
		_vsp.play()
		var t2 := create_tween()
		t2.tween_property(_fade, "modulate:a", 0.0, FADE_DUR)
	)

# ── Boutons principaux ───────────────────────────────────────────────────────

func _on_new_game_pressed() -> void:
	_mode = "new_game"
	_refresh_profiles()
	$ProfileOverlay.visible = true

func _on_continue_pressed() -> void:
	_mode = "continue"
	_refresh_profiles()
	$ProfileOverlay.visible = true

func _on_options_pressed() -> void:
	$OptionsOverlay.visible = true

# ── Sélecteur de profils ─────────────────────────────────────────────────────

func _refresh_profiles() -> void:
	for n in PlayerData.PROFILE_COUNT:
		var slot : int = n + 1
		var card := $ProfileOverlay/Panel/VBox/Slots.get_node("Profile%d" % slot) as Button
		var info := PlayerData.get_profile_info(slot)
		if info.is_empty():
			card.text = "PROFIL %d\n— VIDE —" % slot
			card.disabled = _mode == "continue"
		else:
			var lvl       : int    = int(info.get("player_level",    1))
			var vict      : int    = int(info.get("victories_total", 0))
			var char_name : String = String(info.get("selected_char", "neophyte")).to_upper()
			var run_active := PlayerData.has_run_in_progress(slot)
			if _mode == "continue":
				card.disabled = not run_active
				if run_active:
					card.text = "PROFIL %d — %s\nVague %d  |  %d victoires" % [slot, char_name, lvl, vict]
				else:
					card.text = "PROFIL %d — %s\n%d victoires  (pas de run en cours)" % [slot, char_name, vict]
			else:
				card.disabled = false
				card.text = "PROFIL %d — %s\n%d victoires" % [slot, char_name, vict]

func _on_profile_selected(slot: int) -> void:
	$ProfileOverlay.visible = false
	if _mode == "new_game":
		PlayerData.load_profile(slot)
		PlayerData.reset_run()
		PlayerData.save()
		get_tree().change_scene_to_file("res://scenes/ui/StoryIntro.tscn")
	elif _mode == "continue":
		PlayerData.load_profile(slot)
		get_tree().change_scene_to_file("res://scenes/arenas/Arena1.tscn")

func _on_profile_overlay_close() -> void:
	$ProfileOverlay.visible = false

# ── Options ──────────────────────────────────────────────────────────────────

func _on_options_close() -> void:
	$OptionsOverlay.visible = false

func _on_music_volume_changed(value: float) -> void:
	$AudioStreamPlayer.volume_db = value

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
