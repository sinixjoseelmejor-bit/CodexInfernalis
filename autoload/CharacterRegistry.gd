extends Node

# Single source of truth for all playable characters.
# To add a character: add one entry here — no other files need modification.

var _defs: Dictionary = {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	_add(CharacterDef.new().setup(
		"neophyte",
		"NÉOPHYTE", "PRÊTRE DU FEU",
		"\"Les voix de l'abîme l'ont appelé.\nIl a répondu par les flammes.\"",
		CharacterDef.AttackStrategy.PROJECTILE,
		"res://assets/Characters/Neophyte/SplashartLyra.png",
		false, 5, 3, 4
	))
	_add(CharacterDef.new().setup(
		"serayne",
		"SERAYNE", "LA MAGE",
		"\"Quinze ans à étudier le Codex.\nElle en connaît le prix.\"",
		CharacterDef.AttackStrategy.SUMMON,
		"res://assets/Characters/Serayne/SerayneSplashart.png",
		false, 3, 3, 5
	))
	_add(CharacterDef.new().setup(
		"unknown_2",
		"???", "BIENTÔT",
		"\"Les ténèbres gardent encore leurs secrets.\"",
		CharacterDef.AttackStrategy.PROJECTILE,
		"",
		true, 0, 0, 0
	))

func _add(def: CharacterDef) -> void:
	_defs[def.char_id] = def

func get_def(char_id: String) -> CharacterDef:
	return _defs.get(char_id, null)

func get_all() -> Array:
	return _defs.values()
