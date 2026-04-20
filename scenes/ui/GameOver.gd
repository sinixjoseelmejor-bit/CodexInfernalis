extends CanvasLayer

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_screen() -> void:
	show()

func _on_restart_pressed() -> void:
	PlayerData.reset_run()
	get_tree().change_scene_to_file("res://scenes/arenas/Arena1.tscn")

func _on_select_pressed() -> void:
	PlayerData.reset_run()
	get_tree().change_scene_to_file("res://scenes/ui/SelectCharacter.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
