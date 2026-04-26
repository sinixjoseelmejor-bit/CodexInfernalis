extends CanvasLayer

const MASTER_BUS := "Master"

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var check := $Control/OptionsOverlay/Panel/VBox/FullscreenRow/FullscreenCheck as CheckButton
	check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var slider := $Control/OptionsOverlay/Panel/VBox/VolumeRow/VolumeSlider as HSlider
	slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS))

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

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), value)

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
