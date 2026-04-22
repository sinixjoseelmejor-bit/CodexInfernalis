@tool
extends CanvasLayer

signal continue_round(remaining_keys: int)

const CRATE_TEXTURES := [
	preload("res://assets/pickups/Lootcrate1.png"),
	preload("res://assets/pickups/Lootcrate2.png"),
	preload("res://assets/pickups/Lootcrate3.png"),
]
const RARITY_NAMES        := ["COMMUN", "RARE", "ÉPIQUE"]
const RARITY_COLORS       := [Color(0.75, 0.75, 0.75, 0.9), Color(0.35, 0.65, 1.0, 1.0), Color(0.9, 0.45, 1.0, 1.0)]
const PANEL_BORDER_COLORS := [Color(0.95, 0.82, 0.35, 0.4), Color(0.35, 0.65, 1.0, 0.6), Color(0.9, 0.45, 1.0, 0.7)]
const RARITY_KEY_COSTS    := [1, 4, 8]   # commun, rare, épique

const REROLL_COSTS := [20, 40, 70, 110]

var _num_slots    := 4
var _keys         := 0
var _level        := 1
var _reroll_count := 0
var _reroll_cost  := 20

# Per-slot state
var _slot_rarities_arr : Array = []
var _crate_items       : Array = []   # Array of Array[3 item Dictionaries]
var _crate_opened      : Array = []
var _crate_chosen      : Array = []   # chosen item id per slot, "" if not yet
var _locked            : Array = []   # persists between waves, max 2 true at once

# UI refs — built dynamically
var _crate_list        : Node  = null
var _crate_panels      : Array = []
var _crate_type_labels : Array = []
var _crate_images      : Array = []
var _crate_names       : Array = []
var _crate_btns        : Array = []
var _crate_lock_btns   : Array = []

# Stats panel (right column)
var _stats_rtlabel : RichTextLabel = null

# 1-parmi-3 choice overlay
var _choice_overlay       : Control = null
var _choice_panels        : Array   = []
var _choice_rarity_labels : Array   = []
var _choice_name_labels   : Array   = []
var _choice_desc_labels   : Array   = []
var _choice_slot_idx      : int     = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# CrateList → CrateSection → Content (HBoxContainer)
	_crate_list = %CrateList
	for child in _crate_list.get_children():
		child.queue_free()
	var content: Node = _crate_list.get_parent().get_parent()
	_build_stats_panel(content)
	_build_choice_overlay()

	if Engine.is_editor_hint():
		_slot_rarities_arr = [0, 0, 0, 1]
		_num_slots   = 4
		_keys        = 3
		_level       = 1
		_reroll_cost = 20
		_crate_opened = [false, false, false, false]
		_crate_chosen = ["",    "",    "",    ""]
		_locked       = [false, false, false, false]
		_crate_items  = [[],    [],    [],    []]
		_build_crate_panels()
		_refresh_all()
		_refresh_lock_btns()
		_refresh_shop_btns()
		show()
	else:
		hide()

# ── Stats panel ───────────────────────────────────────────────────────────────

func _build_stats_panel(parent: Node) -> void:

	var outer := PanelContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color              = Color(0.05, 0.02, 0.12, 0.9)
	style.border_width_left     = 1; style.border_width_top    = 1
	style.border_width_right    = 1; style.border_width_bottom = 1
	style.border_color          = Color(0.55, 0.35, 0.85, 0.6)
	style.content_margin_left   = 18.0; style.content_margin_right  = 18.0
	style.content_margin_top    = 14.0; style.content_margin_bottom = 14.0
	outer.add_theme_stylebox_override("panel", style)
	parent.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	outer.add_child(vbox)

	var title := Label.new()
	title.text = "► STATISTIQUES"
	title.add_theme_color_override("font_color", Color(0.75, 0.55, 1.0, 1.0))
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.add_theme_font_size_override("normal_font_size", 13)
	vbox.add_child(rtl)
	_stats_rtlabel = rtl

func _refresh_stats_panel() -> void:
	if _stats_rtlabel == null:
		return
	var R := "[color=#ff7755]"
	var E := "[/color]"
	var G := "[color=#888888]"
	if Engine.is_editor_hint():
		_stats_rtlabel.text = (
			"[b]VIE[/b]   20 PV\n  %s20%s\n\n" +
			"[b]DÉGÂTS[/b]   2\n  %s2%s\n\n" +
			"[b]VITESSE[/b]   275\n  %s275%s\n\n" +
			"[b]CADENCE[/b]   1.18 tirs/s\n  %s0.85s%s\n\n" +
			"[b]ARMURE[/b]   %s0%s\n\n" +
			"[b]CRITIQUE[/b]   5%%\n  %s5%%%s\n\n" +
			"[b]PROJECTILES[/b]   1\n  %s1%s\n\n" +
			"[b]PORTÉE[/b]   80\n  %s80%s\n\n" +
			"[b]REGEN[/b]   %s0%s"
		) % [G,E, G,E, G,E, G,E, G,E, G,E, G,E, G,E, G,E]
		return
	var lvl := clampi(PlayerData.player_level, 1, 9)

	var txt := ""

	# VIE
	var hp_lv1  : int = PlayerData.BASE_HP_TABLE[1]
	var hp_lvl  : int = PlayerData.BASE_HP_TABLE[lvl]
	var hp_item : int = PlayerData.max_hp - hp_lvl
	txt += "[b]VIE[/b]   %d PV\n" % PlayerData.max_hp
	txt += "  %s%d%s" % [G, hp_lv1, E]
	if hp_lvl - hp_lv1 > 0:
		txt += "  %s+%d (niv.%d)%s" % [R, hp_lvl - hp_lv1, lvl, E]
	if hp_item != 0:
		txt += "  %s%+d (items)%s" % [R, hp_item, E]
	txt += "\n\n"

	# DÉGÂTS
	var dmg_lv1  : int = PlayerData.BASE_DMG_TABLE[1]
	var dmg_lvl  : int = PlayerData.BASE_DMG_TABLE[lvl]
	var dmg_item : int = PlayerData.damage - dmg_lvl
	txt += "[b]DÉGÂTS[/b]   %d\n" % PlayerData.damage
	txt += "  %s%d%s" % [G, dmg_lv1, E]
	if dmg_lvl - dmg_lv1 > 0:
		txt += "  %s+%d (niv.%d)%s" % [R, dmg_lvl - dmg_lv1, lvl, E]
	if dmg_item != 0:
		txt += "  %s%+d (items)%s" % [R, dmg_item, E]
	txt += "\n\n"

	# VITESSE
	var spd_item : float = PlayerData.speed - 275.0
	txt += "[b]VITESSE[/b]   %.0f\n" % PlayerData.speed
	txt += "  %s275%s" % [G, E]
	if spd_item > 0.5:
		txt += "  %s+%.0f (items)%s" % [R, spd_item, E]
	txt += "\n\n"

	# CADENCE
	var cd_lv1  : float = PlayerData.BASE_CD_TABLE[1]
	var cd_lvl  : float = PlayerData.BASE_CD_TABLE[lvl]
	var cd_item : float = cd_lvl - PlayerData.fire_cd
	txt += "[b]CADENCE[/b]   %.2f tirs/s\n" % (1.0 / PlayerData.fire_cd)
	txt += "  %s%.2fs%s" % [G, cd_lv1, E]
	if cd_lv1 - cd_lvl > 0.001:
		txt += "  %s-%.2f (niv.%d)%s" % [R, cd_lv1 - cd_lvl, lvl, E]
	if cd_item > 0.001:
		txt += "  %s-%.2f (items)%s" % [R, cd_item, E]
	txt += "\n\n"

	# ARMURE
	txt += "[b]ARMURE[/b]   "
	if PlayerData.armor > 0:
		txt += "%s+%d (items)%s" % [R, PlayerData.armor, E]
	else:
		txt += "%s0%s" % [G, E]
	txt += "\n\n"

	# CRITIQUE
	var crit_base := 5
	var crit_item := int(PlayerData.crit_chance * 100.0) - crit_base
	txt += "[b]CRITIQUE[/b]   %d%%\n" % int(PlayerData.crit_chance * 100.0)
	txt += "  %s%d%%%s" % [G, crit_base, E]
	if crit_item > 0:
		txt += "  %s+%d%% (items)%s" % [R, crit_item, E]
	txt += "\n\n"

	# VOL DE VIE
	if PlayerData.lifesteal_pct > 0.0:
		txt += "[b]VOL DE VIE[/b]   %s+%d%% (items)%s\n\n" % [R, int(PlayerData.lifesteal_pct * 100.0), E]

	# ESQUIVE
	if PlayerData.dodge_chance > 0.0:
		txt += "[b]ESQUIVE[/b]   %s+%d%% (items)%s\n\n" % [R, int(PlayerData.dodge_chance * 100.0), E]

	# PROJECTILES
	var proj_item := PlayerData.projectile_count - 1
	txt += "[b]PROJECTILES[/b]   %d\n" % PlayerData.projectile_count
	txt += "  %s1%s" % [G, E]
	if proj_item > 0:
		txt += "  %s+%d (items)%s" % [R, proj_item, E]
	txt += "\n\n"

	# PORTÉE RAMASSAGE
	var pickup_item := int(PlayerData.pickup_range) - 80
	txt += "[b]PORTÉE[/b]   %d\n" % int(PlayerData.pickup_range)
	txt += "  %s80%s" % [G, E]
	if pickup_item > 0:
		txt += "  %s+%d (items)%s" % [R, pickup_item, E]
	txt += "\n\n"

	# REGEN
	txt += "[b]REGEN[/b]   "
	if PlayerData.hp_regen > 0.0:
		txt += "%s+%.1f/s (items)%s" % [R, PlayerData.hp_regen, E]
	else:
		txt += "%s0%s" % [G, E]
	txt += "\n"

	_stats_rtlabel.text = txt

# ── Slot rarity roll ──────────────────────────────────────────────────────────

func _roll_slot_rarity() -> int:
	var epic_chance := 0
	var rare_chance := 0
	match _level:
		1:    epic_chance =  0; rare_chance = 10
		2:    epic_chance =  2; rare_chance = 18
		3:    epic_chance =  5; rare_chance = 25
		4:    epic_chance = 10; rare_chance = 35
		5:    epic_chance = 15; rare_chance = 45
		6:    epic_chance = 25; rare_chance = 45
		7:    epic_chance = 40; rare_chance = 40
		8:    epic_chance = 55; rare_chance = 35
		_:    epic_chance = 70; rare_chance = 25
	var roll := randi() % 100
	if roll < epic_chance:                  return 2
	elif roll < epic_chance + rare_chance:  return 1
	return 0

func _get_slot_rarities(_level_unused: int) -> Array:
	var count := 4
	var result: Array = []
	for _i in count:
		result.append(_roll_slot_rarity())
	return result

# ── Dynamic UI construction ────────────────────────────────────────────────────

func _build_crate_panels() -> void:
	for child in _crate_list.get_children():
		child.queue_free()
	_crate_panels.clear()
	_crate_type_labels.clear()
	_crate_images.clear()
	_crate_names.clear()
	_crate_btns.clear()
	_crate_lock_btns.clear()

	for i in _num_slots:
		var panel := PanelContainer.new()
		_apply_crate_style(panel, 0)
		_crate_list.add_child(panel)
		_crate_panels.append(panel)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)

		var img := TextureRect.new()
		img.custom_minimum_size = Vector2(56, 56)
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(img)
		_crate_images.append(img)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		row.add_child(info)

		var type_lbl := Label.new()
		type_lbl.add_theme_font_size_override("font_size", 11)
		info.add_child(type_lbl)
		_crate_type_labels.append(type_lbl)

		var name_lbl := Label.new()
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.visible = false
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		info.add_child(name_lbl)
		_crate_names.append(name_lbl)

		var btn_col := VBoxContainer.new()
		btn_col.add_theme_constant_override("separation", 4)
		row.add_child(btn_col)

		var ci := i
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(148, 0)
		btn.pressed.connect(_on_crate_pressed.bind(ci))
		btn_col.add_child(btn)
		_crate_btns.append(btn)

		var lock_btn := Button.new()
		lock_btn.text = "🔓"
		lock_btn.pressed.connect(_on_lock_crate.bind(ci))
		btn_col.add_child(lock_btn)
		_crate_lock_btns.append(lock_btn)

func _apply_crate_style(panel: PanelContainer, rarity: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color            = Color(0.07, 0.04, 0.14, 0.85)
	style.border_width_left   = 1
	style.border_width_top    = 1
	style.border_width_right  = 1
	style.border_width_bottom = 1
	style.border_color        = PANEL_BORDER_COLORS[rarity]
	style.content_margin_left   = 12.0
	style.content_margin_right  = 12.0
	style.content_margin_top    = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)

func _build_choice_overlay() -> void:
	_choice_overlay = Control.new()
	_choice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_overlay.visible = false
	add_child(_choice_overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.05, 0.82)
	_choice_overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_overlay.add_child(center)

	var outer := PanelContainer.new()
	outer.custom_minimum_size = Vector2(960, 0)
	var os := StyleBoxFlat.new()
	os.bg_color            = Color(0.05, 0.02, 0.12, 0.97)
	os.border_width_left   = 2; os.border_width_top    = 2
	os.border_width_right  = 2; os.border_width_bottom = 2
	os.border_color        = Color(0.55, 0.35, 0.85, 0.9)
	os.content_margin_left = 28.0; os.content_margin_right  = 28.0
	os.content_margin_top  = 22.0; os.content_margin_bottom = 22.0
	outer.add_theme_stylebox_override("panel", os)
	center.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	outer.add_child(vbox)

	var title := Label.new()
	title.text = "CHOISISSEZ UN ITEM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4, 1.0))
	vbox.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox)

	for c in 3:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color            = Color(0.08, 0.04, 0.16, 0.9)
		cs.border_width_left   = 1; cs.border_width_top    = 1
		cs.border_width_right  = 1; cs.border_width_bottom = 1
		cs.border_color        = Color(0.6, 0.4, 0.85, 0.7)
		cs.content_margin_left = 14.0; cs.content_margin_right  = 14.0
		cs.content_margin_top  = 12.0; cs.content_margin_bottom = 12.0
		card.add_theme_stylebox_override("panel", cs)
		hbox.add_child(card)
		_choice_panels.append(card)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		card.add_child(cv)

		var rl := Label.new()
		rl.add_theme_font_size_override("font_size", 11)
		cv.add_child(rl)
		_choice_rarity_labels.append(rl)

		var nl := Label.new()
		nl.add_theme_font_size_override("font_size", 15)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD
		cv.add_child(nl)
		_choice_name_labels.append(nl)

		var dl := Label.new()
		dl.add_theme_font_size_override("font_size", 12)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD
		dl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85, 1.0))
		cv.add_child(dl)
		_choice_desc_labels.append(dl)

		var ci_c := c
		var choose_btn := Button.new()
		choose_btn.text = "CHOISIR"
		choose_btn.pressed.connect(_on_choice_selected.bind(ci_c))
		cv.add_child(choose_btn)

# ── Shop lifecycle ─────────────────────────────────────────────────────────────

func show_shop(keys: int, level: int = 1) -> void:
	_keys  = keys
	_level = level
	_slot_rarities_arr = _get_slot_rarities(level)
	_num_slots = _slot_rarities_arr.size()
	# Resize _locked preserving existing values
	while _locked.size() < _num_slots:
		_locked.append(false)
	while _locked.size() > _num_slots:
		_locked.pop_back()
	_crate_opened = []
	_crate_chosen = []
	for _i in _num_slots:
		_crate_opened.append(false)
		_crate_chosen.append("")
	_reroll_count = 0
	_reroll_cost  = REROLL_COSTS[0]
	_build_crate_panels()
	_roll_crates_unlocked()
	_refresh_all()
	_refresh_lock_btns()
	_refresh_shop_btns()
	show()
	get_tree().paused = true

# ── Roll logic ─────────────────────────────────────────────────────────────────

func _roll_3_items(rarity: int) -> Array:
	var pool: Array = []
	for id in PlayerData.ITEM_DB:
		if int(PlayerData.ITEM_DB[id]["rarity"]) == rarity:
			pool.append(id)
	pool.shuffle()
	var choices: Array = []
	for c in mini(3, pool.size()):
		var entry: Dictionary = PlayerData.ITEM_DB[pool[c]].duplicate()
		entry["id"] = pool[c]
		choices.append(entry)
	while choices.size() < 3 and not choices.is_empty():
		choices.append(choices[0])
	return choices

func _roll_crates_unlocked() -> void:
	_crate_items = []
	for _i in _num_slots:
		_crate_items.append([])
	for i in _num_slots:
		if _locked[i]:
			continue
		var rarity: int = _slot_rarities_arr[i]
		_crate_items[i] = _roll_3_items(rarity)

# ── Refresh ────────────────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_refresh_currency()
	_refresh_crates()
	_refresh_stats_panel()

func _refresh_currency() -> void:
	%KeysLabel.text  = "x%d" % _keys
	%SoulsLabel.text = "☽  %d âmes" % (0 if Engine.is_editor_hint() else PlayerData.souls)

func _refresh_crates() -> void:
	for i in _num_slots:
		var rarity: int    = _slot_rarities_arr[i]
		var opened: bool   = _crate_opened[i]
		var cost: int      = RARITY_KEY_COSTS[rarity]
		var chosen: String = _crate_chosen[i]

		(_crate_type_labels[i] as Label).text = RARITY_NAMES[rarity]
		(_crate_type_labels[i] as Label).add_theme_color_override("font_color", RARITY_COLORS[rarity])

		if opened and chosen != "":
			var db: Dictionary    = PlayerData.ITEM_DB.get(chosen, {})
			var icon_path: String = db.get("icon", "res://assets/items/%s.png" % chosen)
			if ResourceLoader.exists(icon_path):
				(_crate_images[i] as TextureRect).texture = load(icon_path)
			else:
				(_crate_images[i] as TextureRect).texture = CRATE_TEXTURES[mini(rarity, CRATE_TEXTURES.size() - 1)]
		else:
			(_crate_images[i] as TextureRect).texture = CRATE_TEXTURES[mini(rarity, CRATE_TEXTURES.size() - 1)]

		var name_lbl := _crate_names[i] as Label
		if opened and chosen != "":
			var db: Dictionary = PlayerData.ITEM_DB.get(chosen, {})
			name_lbl.text    = str(db.get("name", ""))
			name_lbl.visible = true
		else:
			name_lbl.text    = ""
			name_lbl.visible = false

		var btn: Button = _crate_btns[i]
		if opened:
			btn.text     = "✓  OBTENU"
			btn.disabled = true
		else:
			btn.text     = "🗝 x%d  OUVRIR" % cost
			btn.disabled = _keys < cost

		_apply_crate_style(_crate_panels[i] as PanelContainer, rarity)

func _refresh_lock_btns() -> void:
	for i in _num_slots:
		var btn: Button = _crate_lock_btns[i]
		btn.text     = "🔒" if _locked[i] else "🔓"
		btn.disabled = _crate_opened[i]

func _refresh_shop_btns() -> void:
	%RerollBtn.text     = "↺  RECHARGER  %d ☽" % _reroll_cost
	%RerollBtn.disabled = (not Engine.is_editor_hint()) and PlayerData.souls < _reroll_cost

# ── Crate interactions ─────────────────────────────────────────────────────────

func _on_crate_pressed(idx: int) -> void:
	var rarity: int = _slot_rarities_arr[idx]
	var cost: int   = RARITY_KEY_COSTS[rarity]
	if _crate_opened[idx] or _keys < cost:
		return
	_keys -= cost
	_crate_opened[idx] = true
	_locked[idx]       = false
	_choice_slot_idx   = idx
	_refresh_currency()
	_populate_choice_overlay(idx)
	_choice_overlay.visible = true

func _populate_choice_overlay(slot_idx: int) -> void:
	var choices: Array = _crate_items[slot_idx]
	var rarity: int    = _slot_rarities_arr[slot_idx]
	for c in 3:
		if c >= choices.size() or not (choices[c] is Dictionary) or (choices[c] as Dictionary).is_empty():
			_choice_panels[c].visible = false
			continue
		_choice_panels[c].visible = true
		var item: Dictionary = choices[c]
		(_choice_rarity_labels[c] as Label).text = RARITY_NAMES[rarity]
		(_choice_rarity_labels[c] as Label).add_theme_color_override("font_color", RARITY_COLORS[rarity])
		(_choice_name_labels[c] as Label).text = str(item.get("name", "?"))
		(_choice_desc_labels[c] as Label).text = str(item.get("desc", ""))

func _on_choice_selected(choice_idx: int) -> void:
	if _choice_slot_idx < 0:
		return
	var choices: Array = _crate_items[_choice_slot_idx]
	if choice_idx >= choices.size():
		return
	var chosen: Dictionary = choices[choice_idx]
	var chosen_id: String  = str(chosen.get("id", ""))
	if chosen_id.is_empty():
		return
	_crate_chosen[_choice_slot_idx] = chosen_id
	PlayerData.add_item(chosen_id)
	_choice_overlay.visible = false
	_choice_slot_idx = -1
	_refresh_all()
	_refresh_lock_btns()
	_refresh_shop_btns()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_items()

func _on_lock_crate(idx: int) -> void:
	if _crate_opened[idx]:
		return
	if not _locked[idx] and _locked.count(true) >= 2:
		return
	_locked[idx] = not _locked[idx]
	_refresh_lock_btns()

# ── Reroll ─────────────────────────────────────────────────────────────────────

func _on_reroll_pressed() -> void:
	if PlayerData.souls < _reroll_cost:
		return
	PlayerData.souls -= _reroll_cost
	_reroll_count += 1
	if _reroll_count < REROLL_COSTS.size():
		_reroll_cost = REROLL_COSTS[_reroll_count]
	else:
		_reroll_cost = REROLL_COSTS[REROLL_COSTS.size() - 1] + 50 * (_reroll_count - REROLL_COSTS.size() + 1)
	for i in _num_slots:
		if _crate_opened[i] or _locked[i]:
			continue
		var rarity: int = _slot_rarities_arr[i]
		_crate_items[i] = _roll_3_items(rarity)
	_refresh_all()
	_refresh_lock_btns()
	_refresh_shop_btns()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.refresh_souls(PlayerData.souls)

# ── Continue ───────────────────────────────────────────────────────────────────

func _on_continue_pressed() -> void:
	get_tree().paused = false
	hide()
	continue_round.emit(_keys)
