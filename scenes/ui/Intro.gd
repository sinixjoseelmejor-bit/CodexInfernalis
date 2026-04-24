extends Control

const LOGO     := preload("res://assets/ui/LogoStudio.png")
const FADE_IN  := 1.5
const HOLD     := 2.0
const FADE_OUT := 1.5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.modulate.a = 0.0
	add_child(logo)

	var tween := create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, FADE_IN)
	tween.tween_interval(HOLD)
	tween.tween_property(logo, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(_go_to_menu)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
