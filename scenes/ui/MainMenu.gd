extends Control

var _vsp            : VideoStreamPlayer
var _fade           : ColorRect
var _mode           := ""   # "new_game" ou "continue"
var _delete_pending := 0

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
	_inject_options_extras()

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
	_delete_pending = 0
	var delete_row := $ProfileOverlay/Panel/VBox/DeleteRow
	for n in PlayerData.PROFILE_COUNT:
		var slot      : int    = n + 1
		var card      := $ProfileOverlay/Panel/VBox/Slots.get_node("Profile%d" % slot) as Button
		var del_btn   := delete_row.get_child(n) as Button
		var info      := PlayerData.get_profile_info(slot)
		del_btn.text  = "EFFACER"
		if info.is_empty():
			card.text        = "PROFIL %d\n— VIDE —" % slot
			card.disabled    = _mode == "continue"
			del_btn.disabled = true
		else:
			del_btn.disabled = false
			var lvl       : int    = int(info.get("player_level",    1))
			var vict      : int    = int(info.get("victories_total", 0))
			var char_name : String = String(info.get("selected_char", "neophyte")).to_upper()
			var run_active := PlayerData.has_run_in_progress(slot)
			card.disabled = false
			if _mode == "continue" and run_active:
				card.text = "PROFIL %d — %s\nVague %d  |  %d victoires" % [slot, char_name, lvl, vict]
			else:
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
		if PlayerData.player_level > 1:
			get_tree().change_scene_to_file("res://scenes/arenas/Arena1.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/ui/SelectCharacter.tscn")

func _on_delete_pressed(slot: int) -> void:
	var delete_row := $ProfileOverlay/Panel/VBox/DeleteRow
	if _delete_pending == slot:
		_delete_pending = 0
		PlayerData.delete_profile(slot)
		_refresh_profiles()
	else:
		_delete_pending = slot
		for n in PlayerData.PROFILE_COUNT:
			var del_btn := delete_row.get_child(n) as Button
			del_btn.text = "CONFIRMER ?" if (n + 1) == slot else "EFFACER"
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if _delete_pending == slot:
				_delete_pending = 0
				for n in PlayerData.PROFILE_COUNT:
					var del_btn := delete_row.get_child(n) as Button
					del_btn.text = "EFFACER"
		)

func _on_profile_overlay_close() -> void:
	$ProfileOverlay.visible = false
	_delete_pending = 0

# ── Options ──────────────────────────────────────────────────────────────────

func _inject_options_extras() -> void:
	var vbox := $OptionsOverlay/Panel/VBox as VBoxContainer

	var joy_row := HBoxContainer.new()
	joy_row.add_theme_constant_override("separation", 10)
	var close_btn := $OptionsOverlay/Panel/VBox/CloseButton as Button
	vbox.add_child(joy_row)
	vbox.move_child(joy_row, close_btn.get_index())

	var joy_lbl := Label.new()
	joy_lbl.text = "JOYSTICK"
	joy_lbl.custom_minimum_size = Vector2(120, 0)
	joy_row.add_child(joy_lbl)

	var joy_sl := HSlider.new()
	joy_sl.min_value = 0.5
	joy_sl.max_value = 2.0
	joy_sl.step      = 0.1
	joy_sl.value     = Settings.joystick_size
	joy_sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	joy_sl.value_changed.connect(func(v: float) -> void: Settings.set_joystick_size(v))
	joy_row.add_child(joy_sl)

	var reset_btn := Button.new()
	reset_btn.text = "RÉINITIALISER LA PARTIE EN COURS"
	reset_btn.pressed.connect(_on_reset_run_pressed)
	vbox.add_child(reset_btn)
	vbox.move_child(reset_btn, close_btn.get_index())

func _on_reset_run_pressed() -> void:
	PlayerData.reset_run()
	PlayerData.save()
	$OptionsOverlay.visible = false

func _on_options_close() -> void:
	$OptionsOverlay.visible = false

func _on_music_volume_changed(value: float) -> void:
	$AudioStreamPlayer.volume_db = value
	Settings.set_master_volume(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
