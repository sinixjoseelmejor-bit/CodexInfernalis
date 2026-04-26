extends CanvasLayer

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_screen() -> void:
	get_tree().paused = true
	var earned := int(PlayerData.souls * 0.10)
	if earned > 0:
		PlayerData.eternal_souls += earned
		PlayerData.save()
	var reward_lbl := $Control/VBoxContainer/SoulsReward as Label
	if earned > 0:
		reward_lbl.text = "+%d âmes éternelles (10%% des âmes du run)" % earned
	else:
		reward_lbl.text = ""
	show()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	PlayerData.reset_run()
	PlayerData.save()
	get_tree().change_scene_to_file("res://scenes/arenas/Arena1.tscn")

func _on_select_pressed() -> void:
	get_tree().paused = false
	PlayerData.reset_run()
	PlayerData.save()
	get_tree().change_scene_to_file("res://scenes/ui/SelectCharacter.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
