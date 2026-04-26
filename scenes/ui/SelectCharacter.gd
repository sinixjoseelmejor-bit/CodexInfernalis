extends Control

const SKILL_TREE_OVERLAY := preload("res://scenes/ui/SkillTreeOverlay.tscn")

const CHARACTERS := [
	{
		"id": "neophyte",
		"name": "NÉOPHYTE",
		"class": "PRÊTRE DU FEU",
		"lore": "\"Les voix de l'abîme l'ont appelé.\nIl a répondu par les flammes.\"",
		"hp": 5,
		"speed": 3,
		"magic": 4,
		"splashart": "res://assets/Characters/Neophyte/SplashartLyra.png",
		"locked": false
	},
	{
		"id": "serayne",
		"name": "SERAYNE",
		"class": "LA MAGE",
		"lore": "\"Quinze ans à étudier le Codex.\nElle en connaît le prix.\"",
		"hp": 3,
		"speed": 3,
		"magic": 5,
		"splashart": "res://assets/Characters/Serayne/SerayneSplashart.png",
		"locked": false
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
var _float_tween    : Tween

func _ready() -> void:
	_skill_overlay = SKILL_TREE_OVERLAY.instantiate()
	_skill_overlay.hide()
	_skill_overlay.skill_changed.connect(_refresh_forge)
	add_child(_skill_overlay)
	_refresh()
	_anim_entrance()

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
	_anim_portrait_float()

func _anim_entrance() -> void:
	var card  := $Card
	var title := $Title
	var nav   := $NavRow
	# card glisse depuis la droite en fading in
	card.modulate.a = 0.0
	title.modulate.a = 0.0
	nav.modulate.a = 0.0
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "modulate:a", 1.0, 0.6).from(0.0)
	t.parallel().tween_method(func(x: float) -> void:
		card.offset_left  = 240.0 + x
		card.offset_right = 1680.0 + x,
		80.0, 0.0, 0.5)
	# titre et nav un peu après
	var t2 := create_tween()
	t2.tween_interval(0.3)
	t2.tween_property(title, "modulate:a", 1.0, 0.4).from(0.0)
	var t3 := create_tween()
	t3.tween_interval(0.45)
	t3.tween_property(nav, "modulate:a", 1.0, 0.35).from(0.0)

func _anim_portrait_float() -> void:
	pass

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
	_switch_character()

func _on_next_pressed() -> void:
	_current = (_current + 1) % CHARACTERS.size()
	_switch_character()

func _switch_character() -> void:
	if _float_tween:
		_float_tween.kill()
	var t := create_tween()
	t.tween_property(%Portrait, "modulate:a", 0.0, 0.15)
	t.tween_callback(_refresh)
	t.tween_property(%Portrait, "modulate:a", 1.0, 0.25)

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
