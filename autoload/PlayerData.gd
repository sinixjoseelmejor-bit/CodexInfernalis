extends Node

const UPGRADE_COSTS := [10, 25, 50, 100, 200]
const MAX_LEVEL := 5
const SAVE_PATH := "user://save.json"

# rarity: 0=commun, 1=rare, 2=épique
const ITEM_DB: Dictionary = {
	# COMMUNS — bonus flat uniquement
	"ampoule_vie":    {"rarity":0,"name":"Ampoule de Vie",    "desc":"+2 HP maximum",           "flat_hp":2},
	"dent_loup":      {"rarity":0,"name":"Dent de Loup",      "desc":"+1 dégât",                "flat_damage":1},
	"plume_rapide":   {"rarity":0,"name":"Plume Rapide",      "desc":"+15 vitesse",             "flat_speed":15.0},
	"bague_tir":      {"rarity":0,"name":"Bague du Tireur",   "desc":"Tir 8% plus rapide",      "flat_fire_cd":-0.08},
	"coeur_pierre":   {"rarity":0,"name":"Cœur de Pierre",    "desc":"+3 HP maximum",           "flat_hp":3},
	"bottes_course":  {"rarity":0,"name":"Bottes de Course",  "desc":"+12 vitesse",             "flat_speed":12.0},
	"epee_courte":    {"rarity":0,"name":"Épée Courte",       "desc":"+1 dégât",                "flat_damage":1},
	"bouclier_bois":  {"rarity":0,"name":"Bouclier de Bois",  "desc":"+4 HP maximum",           "flat_hp":4},
	"anneau_vitesse": {"rarity":0,"name":"Anneau de Vitesse", "desc":"+20 vitesse",             "flat_speed":20.0},
	"pierre_aceree":  {"rarity":0,"name":"Pierre Acérée",     "desc":"+2 dégâts",               "flat_damage":2},
	# RARES
	"vampire_amulet": {"rarity":1,"name":"Amulette Vampire",  "desc":"Soigne 2% des dégâts\n+8% HP max (passif)",         "pct_hp":0.08},
	"fire_boots":     {"rarity":1,"name":"Bottes de Feu",     "desc":"Traînée de feu 2s\n+12% vitesse (passif)",          "pct_speed":0.12},
	"thorn_shield":   {"rarity":1,"name":"Bouclier Épineux",  "desc":"Renvoie 15% des dégâts\n+8% dégâts (passif)",       "pct_damage":0.08},
	"rage_ring":      {"rarity":1,"name":"Anneau de Rage",    "desc":"Enrage 2s après un kill\n+8% dégâts (passif)",      "pct_damage":0.08},
	"phantom_step":   {"rarity":1,"name":"Pas Fantôme",       "desc":"1.5s invincible après coup\n+12% vitesse (passif)", "pct_speed":0.12},
	# ÉPIQUES
	"auto_grenade":   {"rarity":2,"name":"La Sainte Grenade", "desc":"Grenade toutes les 8s\n+15% dégâts (passif)",       "pct_damage":0.15, "icon":"res://assets/items/HolyGrenade1.png"},
	"storm_ring":     {"rarity":2,"name":"Anneau de Tempête", "desc":"Salve de 8 tirs / 15s\n+12% cadence (passif)",      "pct_fire_cd":0.12},
	"soul_harvester": {"rarity":2,"name":"Faucheur d'Âmes",   "desc":"Double âmes par kill\n+20% HP max (passif)",        "pct_hp":0.20},
}

# Skill tree for meta-progression (per character)
const SKILL_TREES: Dictionary = {
	"neophyte": [
		{
			"id": "double_tir", "name": "DOUBLE TIR",
			"desc": "Tire 2 projectiles\ncôte à côte", "cost": 1,
			"requires": [], "row": 0, "col": 1,
		},
		{
			"id": "penetration", "name": "PÉNÉTRATION",
			"desc": "Les balles traversent\njusqu'à 3 ennemis", "cost": 1,
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

# Persistant entre les sessions (sauvegardé sur disque)
var boss_souls          : int        = 0
var kills_total         : int        = 0
var perm_skills_by_char : Dictionary = {}  # char_id -> Array of skill IDs
var selected_char       : String     = "neophyte"

# Temporaire (resetté entre les runs)
var souls      := 0
var lvl_hp     := 0
var lvl_damage := 0
var lvl_speed  := 0
var lvl_fire_cd := 0

var max_hp  := 5
var damage  := 1
var speed   := 275.0
var fire_cd := 0.85

var items: Array[String] = []

var touch_move: Vector2      = Vector2.ZERO
var touch_aim_world: Vector2 = Vector2.ZERO
var touch_shooting: bool     = false

func _ready() -> void:
	load_save()

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

# ── Persistence ─────────────────────────────────────────────────────────────

func save() -> void:
	var data := {
		"boss_souls": boss_souls,
		"kills_total": kills_total,
		"perm_skills_by_char": perm_skills_by_char,
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
	boss_souls  = int(result.get("boss_souls",  0))
	kills_total = int(result.get("kills_total", 0))
	var ps = result.get("perm_skills_by_char", {})
	if ps is Dictionary:
		perm_skills_by_char = {}
		for k in ps:
			var v = ps[k]
			if v is Array:
				perm_skills_by_char[k] = v

# ── Run upgrades ─────────────────────────────────────────────────────────────

func get_level(stat: String) -> int:
	match stat:
		"hp":      return lvl_hp
		"damage":  return lvl_damage
		"speed":   return lvl_speed
		"fire_cd": return lvl_fire_cd
	return 0

func next_cost(stat: String) -> int:
	var lvl := get_level(stat)
	return UPGRADE_COSTS[lvl] if lvl < MAX_LEVEL else -1

func can_upgrade(stat: String) -> bool:
	var cost := next_cost(stat)
	return cost > 0 and souls >= cost

func upgrade(stat: String) -> bool:
	if not can_upgrade(stat):
		return false
	souls -= next_cost(stat)
	match stat:
		"hp":      lvl_hp += 1
		"damage":  lvl_damage += 1
		"speed":   lvl_speed += 1
		"fire_cd": lvl_fire_cd += 1
	_recompute()
	return true

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
	souls = 0
	lvl_hp = 0; lvl_damage = 0; lvl_speed = 0; lvl_fire_cd = 0
	items.clear()
	_recompute()

func _recompute() -> void:
	var base_hp  := 5 + lvl_hp * 2
	var base_dmg := 1 + lvl_damage
	var base_spd := 275.0 + lvl_speed * 20.0
	var base_cd  := 0.10 - lvl_fire_cd * 0.09

	var flat_hp  := 0
	var flat_dmg := 0
	var flat_spd := 0.0
	var flat_cd  := 0.0
	var pct_hp   := 0.0
	var pct_dmg  := 0.0
	var pct_spd  := 0.0
	var pct_cd   := 0.0

	for item_id in items:
		var db: Dictionary = ITEM_DB.get(item_id as String, {})
		flat_hp  += int(db.get("flat_hp",      0))
		flat_dmg += int(db.get("flat_damage",  0))
		flat_spd += float(db.get("flat_speed",   0.0))
		flat_cd  += float(db.get("flat_fire_cd", 0.0))
		pct_hp   += float(db.get("pct_hp",      0.0))
		pct_dmg  += float(db.get("pct_damage",  0.0))
		pct_spd  += float(db.get("pct_speed",   0.0))
		pct_cd   += float(db.get("pct_fire_cd", 0.0))

	# Apply permanent skill tree bonuses
	var tree: Array = SKILL_TREES.get(selected_char, [])
	for nd in tree:
		if has_skill(nd["id"]):
			flat_hp  += int(nd.get("flat_hp",      0))
			flat_dmg += int(nd.get("flat_damage",  0))
			flat_spd += float(nd.get("flat_speed",   0.0))
			flat_cd  += float(nd.get("flat_fire_cd", 0.0))
			pct_hp   += float(nd.get("pct_hp",      0.0))
			pct_dmg  += float(nd.get("pct_damage",  0.0))
			pct_spd  += float(nd.get("pct_speed",   0.0))
			pct_cd   += float(nd.get("pct_fire_cd", 0.0))

	max_hp  = int((base_hp  + flat_hp)  * (1.0 + pct_hp))
	damage  = int((base_dmg + flat_dmg) * (1.0 + pct_dmg))
	speed   = (base_spd + flat_spd) * (1.0 + pct_spd)
	fire_cd = max(0.25, (base_cd + flat_cd) * (1.0 - pct_cd))
