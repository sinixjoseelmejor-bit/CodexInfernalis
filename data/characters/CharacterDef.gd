@tool
class_name CharacterDef
extends Resource

enum AttackStrategy { PROJECTILE, SUMMON }

@export var char_id         : String          = ""
@export var display_name    : String          = ""
@export var class_label     : String          = ""
@export var lore            : String          = ""
@export var attack_strategy : AttackStrategy  = AttackStrategy.PROJECTILE
@export var splashart_path  : String          = ""
@export var locked          : bool            = false
@export var stat_hp         : int             = 3
@export var stat_speed      : int             = 3
@export var stat_magic      : int             = 3

func setup(
		p_id: String, p_name: String, p_class: String, p_lore: String,
		p_strategy: AttackStrategy, p_splash: String, p_locked: bool,
		p_hp: int, p_speed: int, p_magic: int) -> CharacterDef:
	char_id         = p_id
	display_name    = p_name
	class_label     = p_class
	lore            = p_lore
	attack_strategy = p_strategy
	splashart_path  = p_splash
	locked          = p_locked
	stat_hp         = p_hp
	stat_speed      = p_speed
	stat_magic      = p_magic
	return self
