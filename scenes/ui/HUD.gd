extends CanvasLayer

const RARITY_BORDER := [
	Color(0.6,  0.6,  0.6,  0.8),
	Color(0.35, 0.65, 1.0,  0.9),
	Color(0.9,  0.45, 1.0,  0.9),
]
const HEART_TEX  := preload("res://assets/ui/heart.png")
const HEART_FULL := Rect2(128, 0, 128, 256)
const HEART_EMPTY := Rect2(0,  0, 128, 256)

var _kills_label : Label = null

func _ready() -> void:
	add_to_group("hud")
	refresh_hp(PlayerData.max_hp, PlayerData.max_hp)
	refresh_souls(0)
	refresh_level(1)
	refresh_timer(90)
	refresh_keys(0)
	_create_kills_label()
	refresh_kills(PlayerData.kills_total)

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_items_visible = not _items_visible
			if not PlayerData.items.is_empty():
				%ItemsBar.visible = _items_visible
			get_viewport().set_input_as_handled()

func refresh_hp(current: int, maximum: int) -> void:
	for child in %HPHearts.get_children():
		child.queue_free()
	for i in maximum:
		if i < current:
			var atlas := AtlasTexture.new()
			atlas.atlas = HEART_TEX
			atlas.region = HEART_FULL
			var heart_rect := TextureRect.new()
			heart_rect.texture = atlas
			heart_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			heart_rect.custom_minimum_size = Vector2(36, 36)
			heart_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			heart_rect.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
			heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			%HPHearts.add_child(heart_rect)
		else:
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(36, 36)
			%HPHearts.add_child(spacer)

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
