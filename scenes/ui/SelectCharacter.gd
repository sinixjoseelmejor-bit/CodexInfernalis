extends Control

const SKILL_TREE_OVERLAY := preload("res://scenes/ui/SkillTreeOverlay.tscn")

const CHARACTERS := [
	{
		"id": "neophyte",
		"name": "NÉOPHYTE",
		"class": "LA CULTISTE",
		"lore": "\"Appelée par l'abîme, elle a tout sacrifié\npour maîtriser les flammes infernales.\"",
		"hp": 5,
		"speed": 3,
		"magic": 4,
		"splashart": "res://assets/Characters/Masqued_Neophyte/NeophyteSplashart.png",
		"locked": false
	},
	{
		"id": "unknown_1",
		"name": "???",
		"class": "BIENTÔT",
		"lore": "\"Les ténèbres gardent encore leurs secrets.\"",
		"hp": 0, "speed": 0, "magic": 0,
		"splashart": "",
		"locked": true
	},
	{
		"id": "unknown_2",
		"name": "???",
		"class": "BIENTÔT",
		"lore": "\"Les ténèbres gardent encore leurs secrets.\"",
		"hp": 0, "speed": 0, "magic": 0,
		"splashart": "",
		"locked": true
	},
]

var _current        := 0
var _skill_overlay  : Control = null

func _ready() -> void:
	_skill_overlay = SKILL_TREE_OVERLAY.instantiate()
	_skill_overlay.hide()
	_skill_overlay.skill_changed.connect(_refresh_forge)
	add_child(_skill_overlay)
	_refresh()

func _refresh() -> void:
	var c: Dictionary = CHARACTERS[_current]
	%CharName.text   = c["name"]
	%CharClass.text  = c["class"]
	%CharLore.text   = c["lore"]
	%StatHP.text     = _dots(c["hp"], 5)
	%StatSpeed.text  = _dots(c["speed"], 5)
	%StatMagic.text  = _dots(c["magic"], 5)
	%NavDots.text    = _nav_dots()
	%ConfirmBtn.disabled = c["locked"]
	%ConfirmBtn.text = "BIENTÔT" if c["locked"] else "ENTRER DANS L'ABÎME"

	if c["splashart"] != "":
		%Portrait.texture = load(c["splashart"])
		%Portrait.modulate = Color(1, 1, 1, 1)
		%LockLabel.hide()
	else:
		%Portrait.texture = null
		%Portrait.modulate = Color(0.2, 0.15, 0.3, 1)
		%LockLabel.show()

	_refresh_forge()

func _refresh_forge() -> void:
	%BossSoulsLabel.text  = "✦ x%d" % PlayerData.boss_souls
	%GrimoireBtn.disabled = CHARACTERS[_current]["locked"]

func _dots(val: int, max_val: int) -> String:
	return "●".repeat(val) + "○".repeat(max_val - val)

func _nav_dots() -> String:
	var s := ""
	for i in CHARACTERS.size():
		s += "◆ " if i == _current else "◇ "
	return s.strip_edges()

func _on_prev_pressed() -> void:
	_current = (_current - 1 + CHARACTERS.size()) % CHARACTERS.size()
	_refresh()

func _on_next_pressed() -> void:
	_current = (_current + 1) % CHARACTERS.size()
	_refresh()

func _on_open_grimoire() -> void:
	var char_id: String = CHARACTERS[_current]["id"]
	_skill_overlay.open(char_id)

func _on_character_selected() -> void:
	if not CHARACTERS[_current]["locked"]:
		PlayerData.selected_char = CHARACTERS[_current]["id"]
		PlayerData.reset_run()
		get_tree().change_scene_to_file("res://scenes/arenas/Arena1.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
