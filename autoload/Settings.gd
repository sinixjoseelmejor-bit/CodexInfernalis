extends Node

const PATH := "user://settings.cfg"

var master_volume : float = 0.0
var joystick_size : float = 1.0

func _ready() -> void:
	_load()
	_apply_volume()

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master_volume", 0.0))
	joystick_size = clampf(float(cfg.get_value("input", "joystick_size", 1.0)), 0.5, 2.0)

func _apply_volume() -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, master_volume)

func set_master_volume(value: float) -> void:
	master_volume = value
	_apply_volume()
	_save()

func set_joystick_size(value: float) -> void:
	joystick_size = clampf(value, 0.5, 2.0)
	_save()

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("input", "joystick_size", joystick_size)
	cfg.save(PATH)
