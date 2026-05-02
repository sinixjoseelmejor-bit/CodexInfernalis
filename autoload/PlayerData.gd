extends Node

const PROFILE_COUNT := 3

# Stats de base par niveau de vague (index 1..9)
const BASE_HP_TABLE  := [0,  20,  23,  27,  31,  36,  41,  47,  54,  62]
const BASE_DMG_TABLE := [0,   2,   2,   3,   3,   4,   4,   5,   5,   6]
const BASE_CD_TABLE  := [0.0, 0.85, 0.82, 0.79, 0.76, 0.73, 0.70, 0.67, 0.64, 0.61]
const BASE_SPEED     := 275.0

# rarity: 0=commun, 1=rare, 2=épique
const ITEM_DB: Dictionary = {
	# ─── COMMUNS R1 (rarity 0, max_stacks 5) ────────────────────────────────
	"coeur_pierre":     {"rarity":0,"weight":80, "name":"Cœur de Basalte",      "desc":"+8 HP max\n+2 armure à 3 stacks",     "flat_hp":8},
	"ampoule_vie":      {"rarity":0,"weight":90, "name":"Fiole du Styx",        "desc":"+5 HP max\n+0.3 regen/stack",         "flat_hp":5, "flat_regen":0.3},
	"amulette_foi":     {"rarity":0,"weight":100,"name":"Amulette des Damnés",  "desc":"+4 HP max\n+3% esquive",              "flat_hp":4, "pct_dodge":0.03},
	"dent_loup":        {"rarity":0,"weight":100,"name":"Croc du Cerbère",      "desc":"+1 dégât\n+3% critique",              "flat_damage":1, "pct_crit":0.03},
	"pierre_aceree":    {"rarity":0,"weight":90, "name":"Éclat de Braise",      "desc":"+2 dégâts\n+5% vitesse proj",         "flat_damage":2, "flat_proj_speed":0.05},
	"marteau_fissure":  {"rarity":0,"weight":100,"name":"Marteau du Geôlier",   "desc":"+2 dégâts\nCrit → saignement 3s",    "flat_damage":2},
	"plume_rapide":     {"rarity":0,"weight":90, "name":"Aile de Stryx",        "desc":"+15 vitesse\n+0.1s iframes/stack",   "flat_speed":15.0},
	"bague_tir":        {"rarity":0,"weight":80, "name":"Sceau de l'Inquisiteur","desc":"Tir 5% plus rapide",                "flat_fire_cd":-0.05},
	"sac_trou":         {"rarity":0,"weight":100,"name":"Besace des Limbes",    "desc":"+40 portée ramassage\n+5% âmes bonus","flat_pickup":40.0, "bonus_soul_rate":0.05},
	"pendentif_chance": {"rarity":0,"weight":70, "name":"Pendentif de Belzébuth","desc":"+2% crit\n+1% esquive\n+10 portée", "pct_crit":0.02, "pct_dodge":0.01, "flat_pickup":10.0},
	"bandage_sang":     {"rarity":0,"weight":90, "name":"Linceul Écarlate",     "desc":"+5 HP max\n+1.5% vol de vie\n-1 armure",        "flat_hp":5, "pct_lifesteal":0.015, "flat_armor":-1},
	"fiole_sangsue":    {"rarity":0,"weight":90, "name":"Sang de Léviathan",    "desc":"+1 dégât\n+2% vol de vie\n-5% vitesse",           "flat_damage":1, "pct_lifesteal":0.02, "pct_speed":-0.05},
	"ceinture_aimant":  {"rarity":0,"weight":90, "name":"Ceinture du Tartare",  "desc":"+60 portée ramassage\n+2% esquive",  "flat_pickup":60.0, "pct_dodge":0.02},
	# ─── RARES R1 (rarity 1, max_stacks 3) ──────────────────────────────────
	"vampire_amulet":   {"rarity":1,"weight":90, "name":"Amulette de Charon",      "desc":"+8% HP max\n+2% vol de vie/stack\n-3% cadence de tir/stack",      "pct_hp":0.08, "pct_lifesteal":0.02, "pct_fire_cd":-0.03},
	"fire_boots":       {"rarity":1,"weight":100,"name":"Bottes du Phlégéthon",  "desc":"+12% vitesse\nTraînée de feu",          "pct_speed":0.12},
	"thorn_shield":     {"rarity":1,"weight":100,"name":"Écu des Épines Maudites","desc":"+8% dégâts\nRenvoie 15%×stacks dégâts","pct_damage":0.08},
	"rage_ring":        {"rarity":1,"weight":100,"name":"Sceau du Courroux",      "desc":"+8% dégâts\nEnragé 2s après kill",     "pct_damage":0.08},
	"phantom_step":     {"rarity":1,"weight":100,"name":"Pas du Spectre",         "desc":"+12% vitesse\n+3 armure/stack",        "pct_speed":0.12, "flat_armor":3},
	"oeil_gele":        {"rarity":1,"weight":100,"name":"Œil du Cocyte",          "desc":"+8% dégâts\n7e tir ralentit 40% (2s)","pct_damage":0.08},
	"orbe_mana":        {"rarity":1,"weight":100,"name":"Orbe de l'Achéron",      "desc":"+10% dégâts\n10e tir = proj bonus",   "pct_damage":0.10},
	"cor_guerre":       {"rarity":1,"weight":100,"name":"Cor de Baal",            "desc":"+6% dégâts\n+30% dmg 5s début vague", "pct_damage":0.06},
	"lame_assoiffee":   {"rarity":1,"weight":90, "name":"Lame de Moloch",         "desc":"+8% dégâts\n+3% vol de vie\n+15% dégâts reçus",          "pct_damage":0.08, "pct_lifesteal":0.03, "pct_dmg_reduction":-0.15},
	"cape_predateur":   {"rarity":1,"weight":100,"name":"Cape des Ombres",        "desc":"+10% vitesse\n+70 portée ramassage",  "pct_speed":0.10, "flat_pickup":70.0},
	"couronne_sang":    {"rarity":1,"weight":90, "name":"Couronne de Dis",        "desc":"+10% HP max\n+4% vol de vie\n-10% vitesse",         "pct_hp":0.10, "pct_lifesteal":0.04, "pct_speed":-0.10},
	# ─── ÉPIQUES R1 (rarity 2, max_stacks 2) ────────────────────────────────
	"auto_grenade":     {"rarity":2,"weight":100,"name":"Grenade Automatique","desc":"Grenade toutes les 6s\n+15% dégâts",    "pct_damage":0.15, "icon":"res://assets/items/HolyGrenade1.png"},
	"double_canon":     {"rarity":2,"weight":80, "name":"Diptyque de l'Abîme","desc":"+1 projectile simultané\n+5% dégâts",   "flat_projectiles":1, "pct_damage":0.05, "incompatible_with":["serayne"]},
	"faux_ames":        {"rarity":2,"weight":90, "name":"Faux d'Azraël",    "desc":"+12% dégâts\n+6% vol de vie\n-1 HP/sec",               "pct_damage":0.12, "pct_lifesteal":0.06, "hp_drain":1.0},
	# ─── COMMUNS PRIORITÉ HAUTE ──────────────────────────────────────────────
	"griffe_abaddon":   {"rarity":0,"weight":100,"name":"Griffe d'Abaddon",      "desc":"+2 dégâts\n+5% critique",              "flat_damage":2, "pct_crit":0.05},
	"orbe_limbes":      {"rarity":0,"weight":80, "name":"Orbe des Limbes",        "desc":"Absorbe 1 coup\ntoutes les 8s",        },
	"ceinture_gehenne": {"rarity":0,"weight":100,"name":"Ceinture du Géhenne",    "desc":"+10 vitesse\n+1 dégât",                "flat_speed":10.0, "flat_damage":1},
	"collier_erebe":    {"rarity":0,"weight":100,"name":"Collier de l'Érèbe",     "desc":"+2 dégâts\n-5% dégâts reçus",          "flat_damage":2, "pct_dmg_reduction":0.05},
	"lanterne_acheron": {"rarity":0,"weight":90, "name":"Lanterne de l'Achéron",  "desc":"+20 portée\n+3 HP max",                "flat_pickup":20.0, "flat_hp":3},
	"scarabee_mammon":  {"rarity":0,"weight":90, "name":"Scarabée de Mammon",     "desc":"+10% âmes bonus",                      "bonus_soul_rate":0.10},
	"miroir_supplies":  {"rarity":0,"weight":100,"name":"Miroir des Suppliciés",  "desc":"5% chance de doubler\nles dégâts",     },
	"medaillon_belph":  {"rarity":0,"weight":100,"name":"Médaillon de Belphégor", "desc":"+5% critique\n+3% esquive",            "pct_crit":0.05, "pct_dodge":0.03},
	"sang_courroux":    {"rarity":0,"weight":100,"name":"Sang du Courroux",       "desc":"+3 dégâts 5s\naprès un kill",          },
	"anneau_verre_noir":{"rarity":0,"weight":80, "name":"Anneau de Verre Noir",   "desc":"+5 dégâts\n-5 HP max",                 "flat_damage":5, "flat_hp":-5},
	"ecu_ronces":       {"rarity":0,"weight":100,"name":"Écu des Ronces Maudites","desc":"+2 armure\nRenvoie 10% dégâts reçus",  "flat_armor":2, "pct_reflect":0.10},
	"sac_runes_damnes": {"rarity":0,"weight":100,"name":"Sac de Runes Damnées",   "desc":"+3 HP\n+1 dégât\n+5 vitesse",          "flat_hp":3, "flat_damage":1, "flat_speed":5.0},
	"pierre_purgatoire":{"rarity":0,"weight":90, "name":"Pierre du Purgatoire",   "desc":"+0.5 regen/s",                         "flat_regen":0.5},
	"dague_asmodee":    {"rarity":0,"weight":100,"name":"Dague d'Asmodée",        "desc":"+2 dégâts\nPoison 3s (2 dégâts/s)",   "flat_damage":2},
	# ─── RARES PRIORITÉ HAUTE ────────────────────────────────────────────────
	"anneau_phlegethon":{"rarity":1,"weight":100,"name":"Anneau du Phlégéthon",   "desc":"Kill → +5% vitesse\npendant 3s",       },
	"crane_avarice":    {"rarity":1,"weight":80, "name":"Crâne de l'Avarice",     "desc":"+15% dégâts\n+20% âmes",              "pct_damage":0.15, "bonus_soul_rate":0.20},
	"bottes_lilith":    {"rarity":1,"weight":80, "name":"Bottes de Lilith",       "desc":"+15% vitesse\n+10% esquive",           "pct_speed":0.15, "pct_dodge":0.10},
	"bracelet_pacte":   {"rarity":1,"weight":90, "name":"Bracelet du Pacte",      "desc":"+12% dégâts\n-5 HP\n+10% âmes",        "pct_damage":0.12, "flat_hp":-5, "bonus_soul_rate":0.10},
	"bandeau_inquisiteur":{"rarity":1,"weight":90,"name":"Bandeau de l'Inquisiteur","desc":"+20% dégâts\ndans les 0.5s après l'arrêt", },
	"oeil_tenebres":    {"rarity":1,"weight":90, "name":"Œil de Ténèbres",        "desc":"+15% dégâts\nsi ennemi à >300px",     },
	"chapelet_condamnes":{"rarity":1,"weight":100,"name":"Chapelet des Condamnés","desc":"+2 armure/kill ce round\n(max +10)",   },
	"armure_cranes":    {"rarity":1,"weight":100,"name":"Armure des Crânes",      "desc":"+5 armure\n+5% HP max",               "flat_armor":5, "pct_hp":0.05},
	# ─── ÉPIQUES PRIORITÉ HAUTE ──────────────────────────────────────────────
	"marque_lucifer":   {"rarity":2,"weight":80, "name":"Marque de Lucifer",      "desc":"+25% dégâts\n-20% HP max",            "pct_damage":0.25, "pct_hp":-0.20},
	"griffe_mephisto":  {"rarity":2,"weight":80, "name":"Griffe de Méphistophélès","desc":"+20% dégâts\n+1 HP volé par tir\n-20% cadence de tir",    "pct_damage":0.20, "lifesteal_flat":1, "pct_fire_cd":-0.20},
	"talisman_ire":     {"rarity":2,"weight":100,"name":"Talisman de Ire",        "desc":"+3% dégâts/kill\nce round (max +30%)"},
	"rune_foudre":      {"rarity":2,"weight":100,"name":"Rune de la Foudre Maudite","desc":"Foudre toutes les 5s\n50 dégâts",   },
	"sceptre_tartare":  {"rarity":2,"weight":100,"name":"Sceptre de Tartare",     "desc":"Boule de feu toutes les 4s\n60 dégâts (120px)"},
	"sceau_resurrection":{"rarity":2,"weight":60, "name":"Sceau de la Résurrection","desc":"1 revive automatique\n(reprend à 30% HP)","revive":1},
	"ame_condamnee":    {"rarity":2,"weight":80, "name":"Âme Condamnée",           "desc":"+10% dégâts\n+10% HP max\n+10% vitesse\n+10% âmes", "pct_damage":0.10, "pct_hp":0.10, "pct_speed":0.10, "bonus_soul_rate":0.10},
	"amulette_baal":    {"rarity":2,"weight":100,"name":"Amulette de Baal-Zébuth","desc":"Tous les 3 tirs\n20 dégâts ennemi proche"},
}

const CURSE_DB: Dictionary = {
	"curse_chaos":   {"name": "Chaos Éternel",  "desc": "Ennemis +20% plus rapides\n+30% âmes gagnées"},
	"curse_silence": {"name": "Silence du Vide", "desc": "-15% cadence de tir\n+30% âmes gagnées"},
	"curse_blood":   {"name": "Sang du Damné",  "desc": "-15% PV maximum\n+30% âmes gagnées"},
}

const SKILL_TREES: Dictionary = {
	"neophyte": [
		{
			"id": "double_tir", "name": "DOUBLE TIR",
			"desc": "Tire 2 projectiles\ncôte à côte\n+5 PV max", "cost": 1, "soul_cost": 50,
			"requires": [], "row": 0, "col": 1,
			"flat_projectiles": 1, "flat_hp": 5,
		},
		{
			"id": "penetration", "name": "PÉNÉTRATION",
			"desc": "Les balles traversent\njusqu'à 4 ennemis\n+5 PV max", "cost": 1, "soul_cost": 100,
			"requires": ["double_tir"], "row": 1, "col": 0,
			"flat_hp": 5,
		},
		{
			"id": "velocite", "name": "VÉLOCITÉ",
			"desc": "Projectiles\n+60% plus rapides\n+5 PV max", "cost": 1, "soul_cost": 100,
			"requires": ["double_tir"], "row": 1, "col": 2,
			"flat_hp": 5,
		},
		{
			"id": "explosion", "name": "EXPLOSION",
			"desc": "Chaque impact crée\nune explosion (80px)\n+5 PV max", "cost": 1, "soul_cost": 200,
			"requires": ["penetration"], "row": 2, "col": 0,
			"flat_hp": 5,
		},
		{
			"id": "percant", "name": "PERÇANT",
			"desc": "Les projectiles\ntraversent tous les ennemis\n+5 PV max", "cost": 1, "soul_cost": 200,
			"requires": ["penetration"], "row": 2, "col": 1,
			"flat_hp": 5,
		},
		{
			"id": "ricochet", "name": "RICOCHET",
			"desc": "La balle rebondit\nvers l'ennemi le plus proche\n+5 PV max", "cost": 1, "soul_cost": 200,
			"requires": ["velocite"], "row": 2, "col": 2,
			"flat_hp": 5,
		},
		{
			"id": "tempete_acier", "name": "TEMPÊTE\nD'ACIER",
			"desc": "Salve de 12 tirs omni\ntoutes les 10 secondes\n+5 PV max", "cost": 1, "soul_cost": 400,
			"requires": ["explosion", "ricochet"], "row": 3, "col": 1,
			"flat_hp": 5,
		},
	]
}

var active_profile      : int          = 1

# ── Persistant entre sessions (disque) ──────────────────────────────────────
var boss_souls          : int          = 0
var eternal_souls       : int          = 0
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
var dmg_reduction_pct       := 0.0
var reflect_pct             := 0.0
var lifesteal_flat_per_shot := 0
var revive_count            := 0
var hp_drain_rate           := 0.0
var bonus_armor_round       := 0
var soul_bonus_rate      := 0.0

# Trigger state (run-only)
var _trigger_counters : Dictionary = {}
var _timed_buffs      : Dictionary = {}

# ── Dev flags ───────────────────────────────────────────────────────────────
var dev_no_shoot := false

func _ready() -> void:
	if not OS.is_debug_build():
		dev_no_shoot = false
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
			if eternal_souls < int(nd.get("soul_cost", 0)):
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
			boss_souls    -= int(nd.get("cost", 1))
			eternal_souls -= int(nd.get("soul_cost", 0))
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
	var reduced := int(ceil(float(raw) * (1.0 - dmg_reduction_pct)))
	return maxi(1, reduced - armor - bonus_armor_round)

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

func get_timed_buff_remaining(key: String) -> float:
	return float(_timed_buffs.get(key, 0.0))

# ── Persistence ─────────────────────────────────────────────────────────────

func _profile_path(n: int) -> String:
	return "user://profile_%d.json" % n

func get_profile_info(n: int) -> Dictionary:
	var path := _profile_path(n)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var result = JSON.parse_string(f.get_as_text())
	if result is Dictionary:
		return result as Dictionary
	return {}

func has_run_in_progress(n: int) -> bool:
	var info := get_profile_info(n)
	if info.is_empty():
		return false
	return int(info.get("player_level", 1)) > 1 or (info.get("items", []) as Array).size() > 0

func load_profile(n: int) -> void:
	active_profile = n
	load_save()
	_recompute()

func save() -> void:
	var data := {
		"boss_souls":          boss_souls,
		"eternal_souls":       eternal_souls,
		"kills_total":         kills_total,
		"victories_total":     victories_total,
		"perm_skills_by_char": perm_skills_by_char,
		"unlocked_chars":      unlocked_chars,
		"selected_char":       selected_char,
		"player_level":        player_level,
		"souls":               souls,
		"items":               items,
		"curses":              curses,
	}
	var f := FileAccess.open(_profile_path(active_profile), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_save() -> void:
	var path := _profile_path(active_profile)
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var result = JSON.parse_string(f.get_as_text())
	if not result is Dictionary:
		return
	boss_souls      = int(result.get("boss_souls",      0))
	eternal_souls   = int(result.get("eternal_souls",   0))
	kills_total     = int(result.get("kills_total",     0))
	victories_total = int(result.get("victories_total", 0))
	player_level    = int(result.get("player_level",    1))
	souls           = int(result.get("souls",           0))
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
	var it = result.get("items", [])
	items.clear()
	if it is Array:
		for i in it:
			items.append(String(i))
	var cr = result.get("curses", [])
	curses.clear()
	if cr is Array:
		for c in cr:
			curses.append(String(c))

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

func delete_profile(n: int) -> void:
	var path := _profile_path(n)
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string("{}")
	if active_profile == n:
		boss_souls          = 0
		eternal_souls       = 0
		kills_total         = 0
		victories_total     = 0
		perm_skills_by_char = {}
		unlocked_chars.clear()
		unlocked_chars.append("neophyte")
		selected_char       = "neophyte"
		reset_run()

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
	var base_spd : float = BASE_SPEED
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
	var flat_proj      := 0
	var flat_pspd      := 0.0
	var flat_pickup    := 0.0
	var flat_dmg_reduc := 0.0
	var flat_reflect   := 0.0
	var flat_ls_shot   := 0
	var flat_revive    := 0
	var flat_drain     := 0.0

	for item_id in items:
		var db: Dictionary = ITEM_DB.get(item_id as String, {})
		flat_hp     += int(db.get("flat_hp",            0))
		flat_dmg    += int(db.get("flat_damage",        0))
		flat_spd    += float(db.get("flat_speed",       0.0))
		flat_cd     += float(db.get("flat_fire_cd",     0.0))
		flat_rng    += int(db.get("flat_range",         0))
		flat_arm    += int(db.get("flat_armor",         0))
		flat_reg    += float(db.get("flat_regen",       0.0))
		flat_soul   += float(db.get("bonus_soul_rate",  0.0))
		flat_proj   += int(db.get("flat_projectiles",   0))
		flat_pspd   += float(db.get("flat_proj_speed",  0.0))
		flat_pickup += float(db.get("flat_pickup",      0.0))
		pct_hp      += float(db.get("pct_hp",           0.0))
		pct_dmg     += float(db.get("pct_damage",       0.0))
		pct_spd     += float(db.get("pct_speed",        0.0))
		pct_cd      += float(db.get("pct_fire_cd",      0.0))
		pct_crit    += float(db.get("pct_crit",         0.0))
		pct_ls      += float(db.get("pct_lifesteal",    0.0))
		pct_dodge   += float(db.get("pct_dodge",        0.0))
		flat_dmg_reduc += float(db.get("pct_dmg_reduction", 0.0))
		flat_reflect   += float(db.get("pct_reflect",       0.0))
		flat_ls_shot   += int(db.get("lifesteal_flat",       0))
		flat_revive    += int(db.get("revive",               0))
		flat_drain     += float(db.get("hp_drain",           0.0))

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
	speed      = minf(550.0, (base_spd + flat_spd) * (1.0 + pct_spd))  # 550 = vitesse plafond Android
	fire_cd    = max(0.28, (base_cd + flat_cd) * (1.0 - pct_cd) * curse_cd_mult)
	flat_range = mini(400, flat_rng)

	armor                = flat_arm
	hp_regen             = flat_reg
	soul_bonus_rate      = flat_soul
	crit_chance          = clampf(0.05 + pct_crit, 0.0, 0.55)
	crit_multiplier      = 1.5
	lifesteal_pct           = clampf(pct_ls, 0.0, 0.20)
	dodge_chance            = clampf(pct_dodge, 0.0, 0.50)
	pickup_range            = 80.0 + flat_pickup
	var _proj_cap           := 8 if has_skill("double_tir") else 4
	projectile_count        = mini(_proj_cap, 1 + flat_proj)
	projectile_speed_pct    = flat_pspd
	dmg_reduction_pct       = clampf(flat_dmg_reduc, -0.50, 0.40)
	reflect_pct             = flat_reflect
	lifesteal_flat_per_shot = mini(flat_ls_shot, 2)
	revive_count            = mini(flat_revive, 1)
	hp_drain_rate           = flat_drain
	bonus_armor_round       = 0
