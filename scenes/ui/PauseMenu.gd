extends CanvasLayer

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

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

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
