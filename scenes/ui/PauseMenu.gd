extends CanvasLayer

const MASTER_BUS := "Master"

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var check := $Control/OptionsOverlay/Panel/VBox/FullscreenRow/FullscreenCheck as CheckButton
	check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var slider := $Control/OptionsOverlay/Panel/VBox/VolumeRow/VolumeSlider as HSlider
	slider.value = Settings.master_volume
	_inject_joystick_row()

func toggle() -> void:
	if visible:
		_resume()
	else:
		show()
		get_tree().paused = true

func _resume() -> void:
	hide()
	get_tree().paused = false

func _on_resume_pressed() -> void:
	_resume()

func _on_options_pressed() -> void:
	$Control/OptionsOverlay.visible = true

func _on_options_close() -> void:
	$Control/OptionsOverlay.visible = false

func _inject_joystick_row() -> void:
	var vbox := $Control/OptionsOverlay/Panel/VBox as VBoxContainer
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	vbox.move_child(row, vbox.get_child_count() - 2)  # before CloseButton

	var lbl := Label.new()
	lbl.text = "JOYSTICK"
	lbl.custom_minimum_size = Vector2(110, 0)
	row.add_child(lbl)

	var sl := HSlider.new()
	sl.min_value = 0.5
	sl.max_value = 2.0
	sl.step      = 0.1
	sl.value     = Settings.joystick_size
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.value_changed.connect(func(v: float) -> void: Settings.set_joystick_size(v))
	row.add_child(sl)

func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	PlayerData.save()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
