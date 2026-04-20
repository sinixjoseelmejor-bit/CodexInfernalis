extends CanvasLayer

signal continue_round(remaining_keys: int)

const CRATE_TEXTURES := [
	preload("res://assets/pickups/Lootcrate1.png"),
	preload("res://assets/pickups/Lootcrate2.png"),
	preload("res://assets/pickups/Lootcrate3.png"),
]
const RARITY_NAMES  := ["COMMUN",  "RARE",              "ÉPIQUE"]
const RARITY_COLORS := [Color(0.75, 0.75, 0.75, 0.9), Color(0.35, 0.65, 1.0, 1.0), Color(0.9, 0.45, 1.0, 1.0)]
const RARITY_KEY_COST := [1, 2, 3]
const PANEL_BORDER_COLORS := [
	Color(0.95, 0.82, 0.35, 0.4),
	Color(0.35, 0.65, 1.0,  0.6),
	Color(0.9,  0.45, 1.0,  0.7),
]

const STAT_IDS   := ["hp",       "damage",  "speed",    "fire_cd"]

var _keys := 0
var _crate_items: Array    = []
var _crate_rarities: Array = []
var _crate_opened          := [false, false, false]
var _locked      := [false, false, false]
var _reroll_cost := 30

var _crate_panels: Array
var _crate_images: Array
var _crate_rarity_labels: Array
var _crate_names: Array
var _crate_descs: Array
var _crate_btns: Array
var _crate_lock_btns: Array
var _stat_lvl_labels: Array
var _stat_cost_labels: Array
var _stat_btns: Array

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crate_panels        = [%Crate1Btn.get_parent().get_parent(), %Crate2Btn.get_parent().get_parent(), %Crate3Btn.get_parent().get_parent()]
	_crate_images        = [%Crate1Image, %Crate2Image, %Crate3Image]
	_crate_rarity_labels = [%Crate1Rarity, %Crate2Rarity, %Crate3Rarity]
	_crate_names         = [%Crate1Name,   %Crate2Name,   %Crate3Name]
	_crate_descs         = [%Crate1Desc,   %Crate2Desc,   %Crate3Desc]
	_crate_btns          = [%Crate1Btn,    %Crate2Btn,    %Crate3Btn]
	_crate_lock_btns     = [%LockBtn1,     %LockBtn2,     %LockBtn3]
	_stat_lvl_labels     = [%HPLevel,   %DmgLevel,  %SpdLevel,  %CdLevel]
	_stat_cost_labels    = [%HPCost,    %DmgCost,   %SpdCost,   %CdCost]
	_stat_btns           = [%HPBtn,     %DmgBtn,    %SpdBtn,    %CdBtn]

func show_shop(keys: int) -> void:
	_keys = keys
	_crate_opened = [false, false, false]
	_reroll_cost  = 30
	_roll_crates_unlocked()
	_refresh_all()
	_refresh_lock_btns()
	_refresh_shop_btns()
	show()
	get_tree().paused = true

func _roll_rarity() -> int:
	var roll := randi() % 100
	if roll < 10:  return 2
	elif roll < 40: return 1
	return 0

func _roll_crates() -> void:
	_crate_items    = []
	_crate_rarities = []
	for _i in 3:
		_crate_items.append({})
		_crate_rarities.append(0)
	_roll_crates_unlocked()

func _roll_crates_unlocked() -> void:
	if _crate_items.size() < 3:
		_crate_items    = [{}, {}, {}]
		_crate_rarities = [0, 0, 0]
	for i in 3:
		if _locked[i]:
			continue
		var rarity := _roll_rarity()
		var pool: Array = []
		for id in PlayerData.ITEM_DB:
			if int(PlayerData.ITEM_DB[id]["rarity"]) == rarity:
				pool.append(id)
		pool.shuffle()
		var chosen_id: String = pool[0]
		var entry: Dictionary = PlayerData.ITEM_DB[chosen_id].duplicate()
		entry["id"] = chosen_id
		_crate_items[i]    = entry
		_crate_rarities[i] = rarity

func _refresh_all() -> void:
	_refresh_currency()
	_refresh_crates()
	_refresh_stats()

func _refresh_currency() -> void:
	%KeysLabel.text  = "x%d" % _keys
	%SoulsLabel.text = "☽  %d âmes" % PlayerData.souls

func _refresh_crates() -> void:
	for i in 3:
		var item: Dictionary    = _crate_items[i]
		var rarity: int         = _crate_rarities[i]
		var key_cost: int       = RARITY_KEY_COST[rarity]
		var opened: bool        = _crate_opened[i]

		if opened:
			var item_id: String = (_crate_items[i] as Dictionary)["id"]
			var db: Dictionary  = PlayerData.ITEM_DB.get(item_id, {})
			var icon_path: String = db.get("icon", "res://assets/items/%s.png" % item_id)
			if ResourceLoader.exists(icon_path):
				(_crate_images[i] as TextureRect).texture = load(icon_path)
			(_crate_images[i] as TextureRect).modulate = Color(1, 1, 1, 1)
		else:
			(_crate_images[i] as TextureRect).texture = CRATE_TEXTURES[rarity]
			(_crate_images[i] as TextureRect).modulate = Color(1, 1, 1, 1)
		(_crate_rarity_labels[i] as Label).text = RARITY_NAMES[rarity]
		(_crate_rarity_labels[i] as Label).add_theme_color_override("font_color", RARITY_COLORS[rarity])
		(_crate_names[i] as Label).text = item["name"]
		(_crate_descs[i] as Label).text = item["desc"]

		var btn: Button = _crate_btns[i]
		btn.disabled = opened or _keys < key_cost
		if opened:
			btn.text = "✓  OBTENU"
		else:
			btn.text = "🗝 x%d  OUVRIR" % key_cost

		var style := StyleBoxFlat.new()
		style.bg_color           = Color(0.07, 0.04, 0.14, 0.85)
		style.border_width_left  = 1
		style.border_width_top   = 1
		style.border_width_right = 1
		style.border_width_bottom= 1
		style.border_color       = PANEL_BORDER_COLORS[rarity]
		style.content_margin_left  = 18.0
		style.content_margin_right = 18.0
		style.content_margin_top   = 14.0
		style.content_margin_bottom= 14.0
		(_crate_panels[i] as PanelContainer).add_theme_stylebox_override("panel", style)

func _stat_value_text(stat: String, lvl: int) -> String:
	match stat:
		"hp":      return "%d PV  (Nv.%d)" % [PlayerData.max_hp, lvl]
		"damage":  return "%d dmg  (Nv.%d)" % [PlayerData.damage, lvl]
		"speed":   return "%.0f  (Nv.%d)" % [PlayerData.speed, lvl]
		"fire_cd": return "%.2f tirs/s  (Nv.%d)" % [1.0 / PlayerData.fire_cd, lvl]
	return ""

func _refresh_stats() -> void:
	for i in 4:
		var stat: String = STAT_IDS[i]
		var lvl: int     = PlayerData.get_level(stat)
		var cost: int    = PlayerData.next_cost(stat)
		(_stat_lvl_labels[i] as Label).text = _stat_value_text(stat, lvl)
		var cost_lbl: Label = _stat_cost_labels[i]
		var btn: Button     = _stat_btns[i]
		if cost < 0:
			cost_lbl.text = "MAX"
			btn.disabled  = true
		else:
			cost_lbl.text = "%d ☽" % cost
			btn.disabled  = not PlayerData.can_upgrade(stat)

func _on_crate_pressed(idx: int) -> void:
	var key_cost: int = RARITY_KEY_COST[int(_crate_rarities[idx])]
	if _crate_opened[idx] or _keys < key_cost:
		return
	_keys -= key_cost
	_crate_opened[idx] = true
	_locked[idx]       = false
	PlayerData.add_item((_crate_items[idx] as Dictionary)["id"])
	_refresh_all()
	_refresh_lock_btns()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_items()

func _on_crate1_pressed() -> void: _on_crate_pressed(0)
func _on_crate2_pressed() -> void: _on_crate_pressed(1)
func _on_crate3_pressed() -> void: _on_crate_pressed(2)

func _on_stat_upgrade(idx: int) -> void:
	PlayerData.upgrade(STAT_IDS[idx])
	_refresh_all()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_souls(PlayerData.souls)

func _on_hp_upgrade_pressed()  -> void: _on_stat_upgrade(0)
func _on_dmg_upgrade_pressed() -> void: _on_stat_upgrade(1)
func _on_spd_upgrade_pressed() -> void: _on_stat_upgrade(2)
func _on_cd_upgrade_pressed()  -> void: _on_stat_upgrade(3)

func _refresh_lock_btns() -> void:
	for i in 3:
		var btn: Button = _crate_lock_btns[i]
		btn.text     = "🔒" if _locked[i] else "🔓"
		btn.disabled = _crate_opened[i]

func _refresh_shop_btns() -> void:
	%RerollBtn.text     = "↺  RECHARGER  %d ☽" % _reroll_cost
	%RerollBtn.disabled = PlayerData.souls < _reroll_cost


func _on_reroll_pressed() -> void:
	if PlayerData.souls < _reroll_cost:
		return
	PlayerData.souls -= _reroll_cost
	_reroll_cost     += 50
	for i in 3:
		if _crate_opened[i] or _locked[i]:
			continue
		var rarity := _roll_rarity()
		var pool: Array = []
		for id in PlayerData.ITEM_DB:
			if int(PlayerData.ITEM_DB[id]["rarity"]) == rarity:
				pool.append(id)
		pool.shuffle()
		var entry: Dictionary = PlayerData.ITEM_DB[pool[0]].duplicate()
		entry["id"] = pool[0]
		_crate_items[i]    = entry
		_crate_rarities[i] = rarity
	_refresh_all()
	_refresh_lock_btns()
	_refresh_shop_btns()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_souls(PlayerData.souls)

func _on_lock_crate(idx: int) -> void:
	if _crate_opened[idx]:
		return
	_locked[idx] = not _locked[idx]
	_refresh_lock_btns()

func _on_lock1_pressed() -> void: _on_lock_crate(0)
func _on_lock2_pressed() -> void: _on_lock_crate(1)
func _on_lock3_pressed() -> void: _on_lock_crate(2)

func _on_continue_pressed() -> void:
	get_tree().paused = false
	hide()
	continue_round.emit(_keys)
