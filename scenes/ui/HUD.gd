extends CanvasLayer

const RARITY_BORDER := [
	Color(0.6,  0.6,  0.6,  0.8),
	Color(0.35, 0.65, 1.0,  0.9),
	Color(0.9,  0.45, 1.0,  0.9),
]

var _kills_label : Label = null
var _hp_bar      : ProgressBar = null
var _hp_label    : Label = null
var _stats_bar   : Control = null
var _stats_rtl   : RichTextLabel = null

func _ready() -> void:
	add_to_group("hud")
	_create_hp_bar()
	refresh_hp(PlayerData.max_hp, PlayerData.max_hp)
	refresh_souls(0)
	refresh_level(1)
	refresh_timer(90)
	refresh_keys(0)
	_create_kills_label()
	refresh_kills(PlayerData.kills_total)
	_create_stats_bar()
	_create_dev_shoot_btn()

func _create_hp_bar() -> void:
	%HPHearts.hide()
	var ctrl: Control = %HPHearts.get_parent()

	var bar := ProgressBar.new()
	bar.position = Vector2(20, 20)
	bar.size     = Vector2(280, 26)
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = PlayerData.max_hp
	bar.value     = PlayerData.max_hp

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.12, 0.12, 1.0)
	fill.corner_radius_top_left     = 5
	fill.corner_radius_top_right    = 5
	fill.corner_radius_bottom_left  = 5
	fill.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("fill", fill)

	var bg := StyleBoxFlat.new()
	bg.bg_color     = Color(0.08, 0.02, 0.04, 0.85)
	bg.border_color = Color(0.7, 0.2, 0.2, 0.7)
	bg.border_width_left   = 1
	bg.border_width_right  = 1
	bg.border_width_top    = 1
	bg.border_width_bottom = 1
	bg.corner_radius_top_left     = 5
	bg.corner_radius_top_right    = 5
	bg.corner_radius_bottom_left  = 5
	bg.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("background", bg)

	ctrl.add_child(bar)
	_hp_bar = bar

	var lbl := Label.new()
	lbl.position = Vector2(20, 50)
	lbl.size     = Vector2(280, 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6, 0.9))
	ctrl.add_child(lbl)
	_hp_label = lbl

func _create_dev_shoot_btn() -> void:
	var btn := Button.new()
	btn.text = "🔫 TIR ON"
	btn.position = Vector2(8, 80)
	btn.size = Vector2(110, 30)
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func():
		PlayerData.dev_no_shoot = not PlayerData.dev_no_shoot
		btn.text = "🔇 TIR OFF" if PlayerData.dev_no_shoot else "🔫 TIR ON"
	)
	add_child(btn)

func _create_kills_label() -> void:
	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lbl.position = Vector2(-160, 8)
	lbl.size = Vector2(150, 32)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.65, 0.9, 0.85))
	add_child(lbl)
	_kills_label = lbl

func refresh_kills(count: int) -> void:
	if _kills_label:
		_kills_label.text = "☠ %d" % count

var _items_visible := false

func _create_stats_bar() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(660, 240)
	panel.custom_minimum_size = Vector2(600, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.02, 0.09, 0.93)
	style.border_color = Color(0.55, 0.35, 0.85, 0.6)
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.content_margin_left   = 20.0
	style.content_margin_right  = 20.0
	style.content_margin_top    = 14.0
	style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", style)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.custom_minimum_size = Vector2(560, 0)
	rtl.add_theme_font_size_override("normal_font_size", 14)
	rtl.add_theme_font_size_override("bold_font_size", 14)
	panel.add_child(rtl)

	_stats_rtl = rtl
	_stats_bar = panel
	panel.hide()
	add_child(panel)

func refresh_stats_bar() -> void:
	if _stats_rtl == null:
		return
	var lvl  := clampi(PlayerData.player_level, 1, 9)
	var G    := "[color=#9988bb]"
	var R    := "[color=#ff6644]"
	var W    := "[color=#ddccff]"
	var E    := "[/color]"

	var base_hp  : int   = PlayerData.BASE_HP_TABLE[lvl]
	var item_hp  : int   = PlayerData.max_hp - base_hp
	var base_dmg : int   = PlayerData.BASE_DMG_TABLE[lvl]
	var item_dmg : int   = PlayerData.damage - base_dmg
	var base_cd  : float = PlayerData.BASE_CD_TABLE[lvl]
	var cd_gain  : float = snappedf(base_cd - PlayerData.fire_cd, 0.001)

	var txt := W + "[b]── STATISTIQUES JOUEUR ──[/b]" + E + "\n\n"

	txt += W + "VIE        " + E + G + str(base_hp) + E
	if item_hp != 0:
		txt += R + ("  +%d" % item_hp if item_hp > 0 else "  %d" % item_hp) + E
	txt += G + "  → %d" % PlayerData.max_hp + E + "\n"

	txt += W + "DÉGÂTS     " + E + G + str(base_dmg) + E
	if item_dmg != 0:
		txt += R + ("  +%d" % item_dmg if item_dmg > 0 else "  %d" % item_dmg) + E
	txt += G + "  → %d" % PlayerData.damage + E + "\n"

	var spd_bonus := PlayerData.speed - 275.0
	txt += W + "VITESSE    " + E + G + "275" + E
	if spd_bonus > 0.5:
		txt += R + "  +%d" % int(spd_bonus) + E
	txt += G + "  → %d" % int(PlayerData.speed) + E + "\n"

	txt += W + "CADENCE    " + E + G + "%.2fs" % base_cd + E
	if cd_gain > 0.005:
		txt += R + "  -%.2fs" % cd_gain + E
	txt += G + "  → %.2fs" % PlayerData.fire_cd + E + "\n"

	txt += W + "ARMURE     " + E + G + str(PlayerData.armor) + E + "\n"
	txt += W + "CRITIQUE   " + E + G + "%d%%" % int(PlayerData.crit_chance * 100.0) + E + "\n"
	txt += W + "VOL DE VIE " + E + G + "%d%%" % int(PlayerData.lifesteal_pct * 100.0) + E + "\n"
	txt += W + "ESQUIVE    " + E + G + "%d%%" % int(PlayerData.dodge_chance * 100.0) + E + "\n"
	txt += W + "PROJECTILES" + E + G + " %d" % PlayerData.projectile_count + E + "\n"
	txt += W + "PORTÉE     " + E + G + "%d" % int(PlayerData.pickup_range) + E + "\n"
	txt += W + "REGEN      " + E + G + "%.1f/s" % PlayerData.hp_regen + E + "\n"

	_stats_rtl.text = txt

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_items_visible = not _items_visible
			if not PlayerData.items.is_empty():
				%ItemsBar.visible = _items_visible
			if _stats_bar:
				if _items_visible:
					refresh_stats_bar()
				_stats_bar.visible = _items_visible
			get_viewport().set_input_as_handled()

func refresh_hp(current: int, maximum: int) -> void:
	if _hp_bar == null:
		return
	_hp_bar.max_value = maximum
	_hp_bar.value     = current
	if _hp_label:
		_hp_label.text = "%d / %d" % [current, maximum]
	var pct := float(current) / float(maximum) if maximum > 0 else 0.0
	var fill := StyleBoxFlat.new()
	fill.corner_radius_top_left     = 5
	fill.corner_radius_top_right    = 5
	fill.corner_radius_bottom_left  = 5
	fill.corner_radius_bottom_right = 5
	if pct > 0.5:
		fill.bg_color = Color(0.85, 0.12, 0.12, 1.0)
	elif pct > 0.25:
		fill.bg_color = Color(0.9, 0.5, 0.05, 1.0)
	else:
		fill.bg_color = Color(1.0, 0.08, 0.08, 1.0)
	_hp_bar.add_theme_stylebox_override("fill", fill)

func refresh_souls(count: int) -> void:
	%SoulsCount.text = str(count)

func refresh_level(lvl: int) -> void:
	%LevelLabel.text = "NIVEAU  %d" % lvl

func refresh_keys(count: int) -> void:
	%KeysCount.text = "x%d" % count

func refresh_timer(seconds: int) -> void:
	if seconds < 0:
		%TimerLabel.text = "∞"
		%TimerLabel.add_theme_color_override("font_color", Color(0.7, 0.3, 1.0, 1.0))
		return
	@warning_ignore("integer_division")
	var m := seconds / 60
	var s := seconds % 60
	%TimerLabel.text = "%d:%02d" % [m, s]
	if seconds <= 10:
		%TimerLabel.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1.0))
	elif seconds <= 30:
		%TimerLabel.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1, 1.0))
	else:
		%TimerLabel.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1.0))

var _boss_bar_root : Control = null
var _boss_progress : ProgressBar = null
var _boss_max_hp   : int = 1

func show_boss_bar(max_hp: int) -> void:
	_boss_max_hp = max_hp
	if _boss_bar_root == null:
		var root := VBoxContainer.new()
		root.position = Vector2(560, 1008)
		root.custom_minimum_size = Vector2(800, 0)
		root.alignment = BoxContainer.ALIGNMENT_CENTER

		var lbl := Label.new()
		lbl.text = "— GOLGOTA —"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(0.85, 0.25, 1.0, 1.0))
		lbl.add_theme_font_size_override("font_size", 16)
		root.add_child(lbl)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(800, 20)
		bar.show_percentage = false
		bar.min_value = 0.0
		bar.max_value = max_hp
		bar.value     = max_hp
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0.65, 0.1, 1.0, 0.9)
		fill.corner_radius_top_left     = 4
		fill.corner_radius_top_right    = 4
		fill.corner_radius_bottom_left  = 4
		fill.corner_radius_bottom_right = 4
		bar.add_theme_stylebox_override("fill", fill)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.08, 0.0, 0.12, 0.9)
		bg.border_color = Color(0.7, 0.2, 1.0, 0.7)
		bg.border_width_left   = 1
		bg.border_width_right  = 1
		bg.border_width_top    = 1
		bg.border_width_bottom = 1
		bar.add_theme_stylebox_override("background", bg)
		root.add_child(bar)

		_boss_progress = bar
		_boss_bar_root = root
		add_child(root)
	else:
		_boss_progress.max_value = max_hp
		_boss_progress.value     = max_hp
		_boss_bar_root.show()

func refresh_boss_hp(current: int) -> void:
	if _boss_progress:
		_boss_progress.value = max(0, current)

func hide_boss_bar() -> void:
	if _boss_bar_root:
		_boss_bar_root.hide()

func refresh_items() -> void:
	refresh_stats_bar()
	var flow := %ItemsFlow
	for child in flow.get_children():
		child.queue_free()

	var counts: Dictionary = {}
	for item_id in PlayerData.items:
		counts[item_id] = counts.get(item_id, 0) + 1

	if counts.is_empty():
		%ItemsBar.hide()
		return
	%ItemsBar.visible = _items_visible

	for item_id in counts:
		var count: int    = counts[item_id]
		var db: Dictionary = PlayerData.ITEM_DB.get(item_id as String, {})
		var icon_path: String = db.get("icon", "res://assets/items/%s.png" % item_id)

		var overlay := Control.new()
		overlay.custom_minimum_size = Vector2(40, 40)
		overlay.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		overlay.size_flags_vertical   = Control.SIZE_SHRINK_CENTER

		var icon := TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		overlay.add_child(icon)

		if count > 1:
			var lbl := Label.new()
			lbl.text = "×%d" % count
			lbl.set_anchor(SIDE_LEFT,   0.35)
			lbl.set_anchor(SIDE_RIGHT,  1.0)
			lbl.set_anchor(SIDE_TOP,    0.55)
			lbl.set_anchor(SIDE_BOTTOM, 1.0)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5, 1.0))
			overlay.add_child(lbl)

		flow.add_child(overlay)
