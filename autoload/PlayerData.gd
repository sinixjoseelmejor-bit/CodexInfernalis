extends Node

const SAVE_PATH := "user://save.json"

# Stats de base par niveau de vague (index 1..9)
const BASE_HP_TABLE  := [0,  20,  23,  27,  31,  36,  41,  47,  54,  62]
const BASE_DMG_TABLE := [0,   2,   2,   3,   3,   4,   4,   5,   5,   6]
const BASE_CD_TABLE  := [0.0, 0.85, 0.82, 0.79, 0.76, 0.73, 0.70, 0.67, 0.64, 0.61]

# rarity: 0=commun, 1=rare, 2=épique
const ITEM_DB: Dictionary = {
	# ─── COMMUNS R1 (rarity 0, max_stacks 5) ────────────────────────────────
	"coeur_pierre":     {"rarity":0,"name":"Cœur de Pierre",    "desc":"+8 HP max\n+2 armure à 3 stacks",        "flat_hp":8},
	"ampoule_vie":      {"rarity":0,"name":"Ampoule de Vie",    "desc":"+5 HP max\n+0.3 regen/stack",            "flat_hp":5, "flat_regen":0.3},
	"amulette_foi":     {"rarity":0,"name":"Amulette de Foi",   "desc":"+4 HP max\n+3% esquive",                 "flat_hp":4, "pct_dodge":0.03},
	"dent_loup":        {"rarity":0,"name":"Dent de Loup",      "desc":"+1 dégât\n+3% critique",                 "flat_damage":1, "pct_crit":0.03},
	"pierre_aceree":    {"rarity":0,"name":"Pierre Acérée",     "desc":"+2 dégâts\n+5% vitesse proj",            "flat_damage":2, "flat_proj_speed":0.05},
	"marteau_fissure":  {"rarity":0,"name":"Marteau Fissure",   "desc":"+2 dégâts\nCrit → saignement 3s",        "flat_damage":2},
	"plume_rapide":     {"rarity":0,"name":"Plume Rapide",      "desc":"+15 vitesse\n+0.1s iframes/stack",       "flat_speed":15.0},
	"bague_tir":        {"rarity":0,"name":"Bague du Tireur",   "desc":"Tir 8% plus rapide",                     "flat_fire_cd":-0.08},
	"sac_trou":         {"rarity":0,"name":"Sac sans Fond",     "desc":"+40 portée ramassage\n+5% âmes bonus",   "flat_pickup":40.0, "bonus_soul_rate":0.05},
	"pendentif_chance": {"rarity":0,"name":"Pendentif Chance",  "desc":"+2% crit\n+1% esquive\n+10 portée",      "pct_crit":0.02, "pct_dodge":0.01, "flat_pickup":10.0},
	# ─── RARES R1 (rarity 1, max_stacks 3) ──────────────────────────────────
	"vampire_amulet":   {"rarity":1,"name":"Amulette Vampire",  "desc":"+8% HP max\n+2% vol de vie/stack",       "pct_hp":0.08, "pct_lifesteal":0.02},
	"fire_boots":       {"rarity":1,"name":"Bottes de Feu",     "desc":"+12% vitesse\nTraînée de feu",           "pct_speed":0.12},
	"thorn_shield":     {"rarity":1,"name":"Bouclier Épineux",  "desc":"+8% dégâts\nRenvoie 15%×stacks dégâts", "pct_damage":0.08},
	"rage_ring":        {"rarity":1,"name":"Anneau de Rage",    "desc":"+8% dégâts\nEnragé 2s après kill",       "pct_damage":0.08},
	"phantom_step":     {"rarity":1,"name":"Pas Fantôme",       "desc":"+12% vitesse\n+0.4s iframes/stack",      "pct_speed":0.12},
	"oeil_gele":        {"rarity":1,"name":"Œil Gelé",          "desc":"+8% dégâts\n7e tir ralentit 40% (2s)",   "pct_damage":0.08},
	"orbe_mana":        {"rarity":1,"name":"Orbe de Mana",      "desc":"+10% dégâts\n10e tir = proj bonus",      "pct_damage":0.10},
	"cor_guerre":       {"rarity":1,"name":"Cor de Guerre",     "desc":"+6% dégâts\n+30% dmg 5s début vague",    "pct_damage":0.06},
	# ─── ÉPIQUES R1 (rarity 2, max_stacks 2) ────────────────────────────────
	"auto_grenade":     {"rarity":2,"name":"Grenade Automatique","desc":"Grenade toutes les 6s\n+15% dégâts",    "pct_damage":0.15, "icon":"res://assets/items/HolyGrenade1.png"},
	"double_canon":     {"rarity":2,"name":"Double Canon",      "desc":"+1 projectile simultané\n+5% dégâts",    "flat_projectiles":1, "pct_damage":0.05},
}

const SKILL_TREES: Dictionary = {
	"neophyte": [
		{
			"id": "double_tir", "name": "DOUBLE TIR",
			"desc": "Tire 2 projectiles\ncôte à côte", "cost": 1,
			"requires": [], "row": 0, "col": 1,
			"flat_projectiles": 1,
		},
		{
			"id": "penetration", "name": "PÉNÉTRATION",
			"desc": "Les balles traversent\njusqu'à 4 ennemis", "cost": 1,
			"requires": ["double_tir"], "row": 1, "col": 0,
		},
		{
			"id": "velocite", "name": "VÉLOCITÉ",
			"desc": "Projectiles\n+60% plus rapides", "cost": 1,
			"requires": ["double_tir"], "row": 1, "col": 2,
		},
		{
			"id": "explosion", "name": "EXPLOSION",
			"desc": "Chaque impact crée\nune explosion (80px)", "cost": 1,
			"requires": ["penetration"], "row": 2, "col": 0,
		},
		{
			"id": "ricochet", "name": "RICOCHET",
			"desc": "La balle rebondit\nvers l'ennemi le plus proche", "cost": 1,
			"requires": ["velocite"], "row": 2, "col": 2,
		},
		{
			"id": "tempete_acier", "name": "TEMPÊTE\nD'ACIER",
			"desc": "Salve de 12 tirs omni\ntoutes les 10 secondes", "cost": 1,
			"requires": ["explosion", "ricochet"], "row": 3, "col": 1,
		},
	]
}

# ── Persistant entre sessions (disque) ──────────────────────────────────────
var boss_souls          : int          = 0
var kills_total         : int          = 0
var victories_total     : int          = 0
var perm_skills_by_char : Dictionary   = {}
var unlocked_chars      : Array[String]= ["neophyte"]
var selected_char       : String       = "neophyte"

# ── Run-only (reset à chaque run) ───────────────────────────────────────────
var souls        := 0
var player_level := 1

var items  : Array[String] = []
var curses : Array[String] = []

# Stats calculées (output de _recompute)
var max_hp               := 50
var damage               := 2
var speed                := 275.0
var fire_cd              := 0.85
var flat_range           := 0
var armor                := 0
var hp_regen             := 0.0
var crit_chance          := 0.05
var crit_multiplier      := 1.5
var lifesteal_pct        := 0.0
var dodge_chance         := 0.0
var pickup_range         := 150.0
var projectile_count     := 1
var projectile_speed_pct := 0.0
var soul_bonus_rate      := 0.0

# Trigger state (run-only)
var _trigger_counters : Dictionary = {}
var _timed_buffs      : Dictionary = {}

# ── Dev flags ───────────────────────────────────────────────────────────────
var dev_no_shoot := false

# ── Touch input (non sauvegardé) ────────────────────────────────────────────
var touch_move        : Vector2 = Vector2.ZERO
var touch_aim_world   : Vector2 = Vector2.ZERO
var touch_shooting    : bool    = false

func _ready() -> void:
	load_save()
	_recompute()

# ── Skill tree ──────────────────────────────────────────────────────────────

func get_char_skills() -> Array:
	var s = perm_skills_by_char.get(selected_char, [])
	if s is Array:
		return s
	return []

func has_skill(skill_id: String) -> bool:
	return skill_id in get_char_skills()

func can_buy_skill(skill_id: String) -> bool:
	if has_skill(skill_id):
		return false
	if boss_souls <= 0:
		return false
	var tree: Array = SKILL_TREES.get(selected_char, [])
	for nd in tree:
		if nd["id"] == skill_id:
			if boss_souls < int(nd.get("cost", 1)):
				return false
			for req in nd.get("requires", []):
				if not has_skill(req):
					return false
			return true
	return false

func buy_skill(skill_id: String) -> bool:
	if not can_buy_skill(skill_id):
		return false
	var tree: Array = SKILL_TREES.get(selected_char, [])
	for nd in tree:
		if nd["id"] == skill_id:
			boss_souls -= int(nd.get("cost", 1))
			if not perm_skills_by_char.has(selected_char):
				perm_skills_by_char[selected_char] = []
			perm_skills_by_char[selected_char].append(skill_id)
			_recompute()
			save()
			return true
	return false

func reset_char_skills(char_id: String) -> void:
	perm_skills_by_char.erase(char_id)
	_recompute()
	save()

# ── Curses ──────────────────────────────────────────────────────────────────

func apply_curse(curse_id: String) -> void:
	if curse_id in curses:
		return
	if curses.size() >= 3:
		return
	curses.append(curse_id)
	_recompute()

func remove_curse(curse_id: String) -> void:
	curses.erase(curse_id)
	_recompute()

func has_curse(curse_id: String) -> bool:
	return curse_id in curses

func get_curse_soul_multiplier() -> float:
	return 1.0 + 0.30 * curses.size()

# ── Combat helpers ───────────────────────────────────────────────────────────

func calc_damage_taken(raw: int) -> int:
	if check_dodge():
		return 0
	return maxi(1, raw - armor)

func calc_lifesteal(dmg: int) -> int:
	if lifesteal_pct <= 0.0:
		return 0
	return maxi(0, int(ceil(float(dmg) * lifesteal_pct)))

func roll_crit() -> bool:
	return randf() < clampf(crit_chance, 0.0, 1.0)

func check_dodge() -> bool:
	return randf() < clampf(dodge_chance, 0.0, 0.6)

# ── Triggers helpers (utilisés depuis Player.gd) ────────────────────────────

func increment_trigger_counter(key: String) -> int:
	var v: int = int(_trigger_counters.get(key, 0)) + 1
	_trigger_counters[key] = v
	return v

func reset_trigger_counter(key: String) -> void:
	_trigger_counters[key] = 0

func set_timed_buff(key: String, duration: float) -> void:
	_timed_buffs[key] = duration

func tick_timed_buffs(delta: float) -> void:
	var expired: Array = []
	for k in _timed_buffs.keys():
		_timed_buffs[k] = float(_timed_buffs[k]) - delta
		if _timed_buffs[k] <= 0.0:
			expired.append(k)
	for k in expired:
		_timed_buffs.erase(k)

func has_timed_buff(key: String) -> bool:
	return _timed_buffs.has(key)

# ── Persistence ─────────────────────────────────────────────────────────────

func save() -> void:
	var data := {
		"boss_souls":          boss_souls,
		"kills_total":         kills_total,
		"victories_total":     victories_total,
		"perm_skills_by_char": perm_skills_by_char,
		"unlocked_chars":      unlocked_chars,
		"selected_char":       selected_char,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var result = JSON.parse_string(f.get_as_text())
	if not result is Dictionary:
		return
	boss_souls      = int(result.get("boss_souls",      0))
	kills_total     = int(result.get("kills_total",     0))
	victories_total = int(result.get("victories_total", 0))
	var ps = result.get("perm_skills_by_char", {})
	if ps is Dictionary:
		perm_skills_by_char = {}
		for k in ps:
			var v = ps[k]
			if v is Array:
				perm_skills_by_char[k] = v
	var uc = result.get("unlocked_chars", ["neophyte"])
	if uc is Array:
		unlocked_chars.clear()
		for c in uc:
			unlocked_chars.append(String(c))
	selected_char = String(result.get("selected_char", "neophyte"))

func add_item(item_id: String) -> void:
	items.append(item_id)
	_recompute()

func item_count(item_id: String) -> int:
	var n := 0
	for i in items:
		if i == item_id:
			n += 1
	return n

func item_rarity(item_id: String) -> int:
	var db: Dictionary = ITEM_DB.get(item_id, {})
	return db.get("rarity", 0)

func reset_run() -> void:
	souls        = 0
	player_level = 1
	items.clear()
	curses.clear()
	_trigger_counters.clear()
	_timed_buffs.clear()
	_recompute()

func _recompute() -> void:
	var lvl      := clampi(player_level, 1, 9)
	var base_hp  : int   = BASE_HP_TABLE[lvl]
	var base_dmg : int   = BASE_DMG_TABLE[lvl]
	var base_spd : float = 275.0
	var base_cd  : float = BASE_CD_TABLE[lvl]

	var flat_hp      := 0
	var flat_dmg     := 0
	var flat_spd     := 0.0
	var flat_cd      := 0.0
	var flat_rng     := 0
	var flat_arm     := 0
	var flat_reg     := 0.0
	var flat_soul    := 0.0
	var pct_hp       := 0.0
	var pct_dmg      := 0.0
	var pct_spd      := 0.0
	var pct_cd       := 0.0
	var pct_crit     := 0.0
	var pct_ls       := 0.0
	var pct_dodge    := 0.0
	var flat_proj    := 0
	var flat_pspd    := 0.0
	var flat_pickup  := 0.0

	for item_id in items:
		var db: Dictionary = ITEM_DB.get(item_id as String, {})
		flat_hp     += int(db.get("flat_hp",         0))
		flat_dmg    += int(db.get("flat_damage",     0))
		flat_spd    += float(db.get("flat_speed",    0.0))
		flat_cd     += float(db.get("flat_fire_cd",  0.0))
		flat_rng    += int(db.get("flat_range",      0))
		flat_arm    += int(db.get("flat_armor",      0))
		flat_reg    += float(db.get("flat_regen",    0.0))
		flat_soul   += float(db.get("bonus_soul_rate", 0.0))
		flat_proj   += int(db.get("flat_projectiles",  0))
		flat_pspd   += float(db.get("flat_proj_speed", 0.0))
		flat_pickup += float(db.get("flat_pickup",   0.0))
		pct_hp      += float(db.get("pct_hp",        0.0))
		pct_dmg     += float(db.get("pct_damage",    0.0))
		pct_spd     += float(db.get("pct_speed",     0.0))
		pct_cd      += float(db.get("pct_fire_cd",   0.0))
		pct_crit    += float(db.get("pct_crit",      0.0))
		pct_ls      += float(db.get("pct_lifesteal", 0.0))
		pct_dodge   += float(db.get("pct_dodge",     0.0))

	# coeur_pierre: +2 armor bonus à 3 stacks
	if item_count("coeur_pierre") >= 3:
		flat_arm += 2

	var tree: Array = SKILL_TREES.get(selected_char, [])
	for nd in tree:
		if has_skill(nd["id"]):
			flat_hp   += int(nd.get("flat_hp",           0))
			flat_dmg  += int(nd.get("flat_damage",       0))
			flat_spd  += float(nd.get("flat_speed",      0.0))
			flat_cd   += float(nd.get("flat_fire_cd",    0.0))
			flat_arm  += int(nd.get("flat_armor",        0))
			flat_reg  += float(nd.get("flat_regen",      0.0))
			flat_proj += int(nd.get("flat_projectiles",  0))
			pct_hp    += float(nd.get("pct_hp",          0.0))
			pct_dmg   += float(nd.get("pct_damage",      0.0))
			pct_spd   += float(nd.get("pct_speed",       0.0))
			pct_cd    += float(nd.get("pct_fire_cd",     0.0))

	# Curses
	var curse_cd_mult := 1.0
	var curse_hp_pct  := 0.0
	if has_curse("curse_silence"):
		curse_cd_mult *= 1.15
	if has_curse("curse_blood"):
		curse_hp_pct -= 0.15

	max_hp     = int((base_hp  + flat_hp)  * (1.0 + pct_hp + curse_hp_pct))
	damage     = int((base_dmg + flat_dmg) * (1.0 + pct_dmg))
	speed      = (base_spd + flat_spd) * (1.0 + pct_spd)
	fire_cd    = max(0.10, (base_cd + flat_cd) * (1.0 - pct_cd) * curse_cd_mult)
	flat_range = mini(400, flat_rng)

	armor                = flat_arm
	hp_regen             = flat_reg
	soul_bonus_rate      = flat_soul
	crit_chance          = 0.05 + pct_crit
	crit_multiplier      = 1.5
	lifesteal_pct        = pct_ls
	dodge_chance         = clampf(pct_dodge, 0.0, 0.6)
	pickup_range         = 80.0 + flat_pickup
	projectile_count     = 1 + flat_proj
	projectile_speed_pct = flat_pspd
