extends Control

signal skill_changed

const FONT_CINZEL := "res://assets/fonts/Cinzel-VariableFont_wght.ttf"
const FONT_MONO   := "res://assets/fonts/ShareTechMono-Regular.ttf"

const NODE_W  := 190
const NODE_H  := 105
const COL_W   := 235
const ROW_H   := 140
const OFS_X   := 45.0
const OFS_Y   := 22.0

var _buttons     : Dictionary = {}
var _souls_label : Label
var _tree_area   : Control
var _char_id     : String = ""

var _reset_holding := false
var _reset_timer   := 0.0
const RESET_HOLD   := 5.0
var _reset_btn     : Button

func _ready() -> void:
	_build_ui()

func _process(delta: float) -> void:
	if not _reset_holding:
		return
	_reset_timer += delta
	_reset_btn.text = "⚠  RESET  %.1fs" % (RESET_HOLD - _reset_timer)
	if _reset_timer >= RESET_HOLD:
		_reset_holding = false
		_reset_timer   = 0.0
		_do_reset()

# ── Build UI ─────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.85)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.01, 0.10, 0.97)
	ps.set_border_width_all(1)
	ps.border_color = Color(0.55, 0.28, 0.88, 0.70)
	ps.set_corner_radius_all(8)
	ps.content_margin_left   = 22.0
	ps.content_margin_right  = 22.0
	ps.content_margin_top    = 16.0
	ps.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# ── Header ──────────────────────────────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	vbox.add_child(header)

	var icon_lbl := Label.new()
	icon_lbl.text = "⚔"
	icon_lbl.add_theme_font_size_override("font_size", 22)
	icon_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 0.9))
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(icon_lbl)

	var title := Label.new()
	title.text = "FORGE ÉTERNELLE  —  ARBRE D'ARME"
	title.add_theme_font_override("font", load(FONT_CINZEL))
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.92, 0.78, 0.28, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)

	_souls_label = Label.new()
	_souls_label.add_theme_font_override("font", load(FONT_MONO))
	_souls_label.add_theme_font_size_override("font_size", 13)
	_souls_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2, 0.85))
	_souls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_souls_label)

	vbox.add_child(_divider(Color(0.55, 0.30, 0.85, 0.45)))

	# ── Hint bar ────────────────────────────────────────────────────────────
	var hint := Label.new()
	hint.text = "Chaque amélioration coûte 1 Âme de Boss + des Âmes éternelles  —  gagnées en vainquant les boss"
	hint.add_theme_font_override("font", load(FONT_MONO))
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.6, 0.5, 0.75, 0.65))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	# ── Tree area ────────────────────────────────────────────────────────────
	_tree_area = Control.new()
	_tree_area.custom_minimum_size = Vector2(
		OFS_X * 2 + 2 * COL_W + NODE_W,
		OFS_Y * 2 + 3 * ROW_H + NODE_H
	)
	_tree_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_tree_area)

	vbox.add_child(_divider(Color(0.5, 0.28, 0.78, 0.35)))

	# ── Footer ───────────────────────────────────────────────────────────────
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	vbox.add_child(footer)

	var legend := Label.new()
	legend.text = "  ◆ Or = acheté   ◆ Violet = disponible   ◆ Gris = verrouillé  "
	legend.add_theme_font_override("font", load(FONT_MONO))
	legend.add_theme_font_size_override("font_size", 9)
	legend.add_theme_color_override("font_color", Color(0.5, 0.42, 0.65, 0.6))
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(legend)

	_reset_btn = Button.new()
	_reset_btn.text = "⚠  RESET"
	_reset_btn.add_theme_font_override("font", load(FONT_MONO))
	_reset_btn.add_theme_font_size_override("font_size", 10)
	_reset_btn.add_theme_color_override("font_color", Color(0.85, 0.28, 0.28, 0.80))
	_reset_btn.add_theme_stylebox_override("normal", _mk_style(Color(0,0,0,0),         Color(0.65,0.18,0.18,0.55)))
	_reset_btn.add_theme_stylebox_override("hover",  _mk_style(Color(0.28,0.04,0.04,0.4), Color(0.9,0.3,0.3,0.9)))
	_reset_btn.add_theme_stylebox_override("focus",  _mk_style(Color(0,0,0,0),         Color(0.65,0.18,0.18,0.55)))
	_reset_btn.button_down.connect(_on_reset_down)
	_reset_btn.button_up.connect(_on_reset_up)
	footer.add_child(_reset_btn)

	var close_btn := Button.new()
	close_btn.text = "  FERMER  "
	close_btn.add_theme_font_override("font", load(FONT_MONO))
	close_btn.add_theme_font_size_override("font_size", 11)
	close_btn.add_theme_color_override("font_color", Color(0.72, 0.55, 1.0, 0.90))
	close_btn.add_theme_stylebox_override("normal", _mk_style(Color(0,0,0,0),            Color(0.50,0.30,0.80,0.55)))
	close_btn.add_theme_stylebox_override("hover",  _mk_style(Color(0.22,0.08,0.40,0.35), Color(0.82,0.60,1.0,0.95)))
	close_btn.add_theme_stylebox_override("focus",  _mk_style(Color(0,0,0,0),            Color(0.50,0.30,0.80,0.55)))
	close_btn.pressed.connect(_on_close)
	footer.add_child(close_btn)

# ── Open ──────────────────────────────────────────────────────────────────────

func open(char_id: String) -> void:
	if char_id != _char_id:
		_char_id = char_id
		_rebuild_tree()
	show()
	_refresh()

# ── Tree building ─────────────────────────────────────────────────────────────

func _rebuild_tree() -> void:
	for c in _tree_area.get_children():
		_tree_area.remove_child(c)
		c.free()
	_buttons.clear()

	var tree: Array = PlayerData.SKILL_TREES.get(_char_id, [])

	# Connection lines (drawn first, behind nodes)
	for nd in tree:
		var cp := _node_center(nd["row"], nd["col"])
		for req in nd.get("requires", []):
			for pd in tree:
				if pd["id"] == req:
					var pp   := _node_center(pd["row"], pd["col"])
					var line := Line2D.new()
					line.add_point(pp)
					line.add_point(cp)
					line.width = 2.0
					var grad := Gradient.new()
					grad.set_color(0, Color(0.55, 0.30, 0.85, 0.55))
					grad.set_color(1, Color(0.38, 0.20, 0.58, 0.30))
					line.gradient = grad
					_tree_area.add_child(line)

	for nd in tree:
		_create_node(nd)

func _node_center(row: int, col: int) -> Vector2:
	return Vector2(OFS_X + col * COL_W + NODE_W * 0.5,
				   OFS_Y + row * ROW_H  + NODE_H * 0.5)

func _create_node(data: Dictionary) -> void:
	var pos := Vector2(OFS_X + data["col"] * COL_W, OFS_Y + data["row"] * ROW_H)

	var cont := Control.new()
	cont.position             = pos
	cont.custom_minimum_size  = Vector2(NODE_W, NODE_H)
	_tree_area.add_child(cont)

	var btn := Button.new()
	btn.position      = Vector2.ZERO
	btn.size          = Vector2(NODE_W, NODE_H)
	btn.clip_contents = true
	cont.add_child(btn)

	var sid: String = data["id"]
	btn.pressed.connect(func(): _on_buy(sid))
	_buttons[sid] = btn

	# Inner layout
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.add_theme_font_override("font", load(FONT_CINZEL))
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	name_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color               = Color(1, 1, 1, 0.08)
	sep.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)

	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.add_theme_font_override("font", load(FONT_MONO))
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	desc_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_lbl)

	var soul_cost_nd: int = data.get("soul_cost", 0)
	var cost_lbl := Label.new()
	if soul_cost_nd > 0:
		cost_lbl.text = "1 boss  +  %d âmes" % soul_cost_nd
	else:
		cost_lbl.text = "1 âme de boss"
	cost_lbl.add_theme_font_override("font", load(FONT_MONO))
	cost_lbl.add_theme_font_size_override("font_size", 8)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.22, 0.65))
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_lbl)

# ── Refresh ───────────────────────────────────────────────────────────────────

func _refresh() -> void:
	_souls_label.text = "%d boss  ·  %d âmes" % [
		PlayerData.boss_souls,
		PlayerData.eternal_souls,
	]
	var tree: Array = PlayerData.SKILL_TREES.get(_char_id, [])
	for nd in tree:
		var sid: String = nd["id"]
		if _buttons.has(sid):
			_style_node(_buttons[sid], sid)

func _style_node(btn: Button, sid: String) -> void:
	var vbox     : VBoxContainer = btn.get_child(0)
	var name_lbl : Label         = vbox.get_child(0)
	var desc_lbl : Label         = vbox.get_child(2)

	if PlayerData.has_skill(sid):
		btn.add_theme_stylebox_override("normal", _mk_style(Color(0.13,0.09,0.01,1.0), Color(1.0,0.75,0.22,0.90)))
		btn.add_theme_stylebox_override("hover",  _mk_style(Color(0.13,0.09,0.01,1.0), Color(1.0,0.75,0.22,0.90)))
		btn.add_theme_stylebox_override("focus",  _mk_style(Color(0.13,0.09,0.01,1.0), Color(1.0,0.75,0.22,0.90)))
		name_lbl.add_theme_color_override("font_color", Color(1.00, 0.85, 0.32, 1.0))
		desc_lbl.add_theme_color_override("font_color", Color(0.88, 0.75, 0.48, 0.82))
		btn.disabled = true

	elif PlayerData.can_buy_skill(sid):
		btn.add_theme_stylebox_override("normal", _mk_style(Color(0.07,0.03,0.13,1.0), Color(0.65,0.35,1.00,0.85)))
		btn.add_theme_stylebox_override("hover",  _mk_style(Color(0.18,0.08,0.30,1.0), Color(0.88,0.62,1.00,1.00)))
		btn.add_theme_stylebox_override("pressed",_mk_style(Color(0.10,0.05,0.20,1.0), Color(0.70,0.40,1.00,1.00)))
		btn.add_theme_stylebox_override("focus",  _mk_style(Color(0.07,0.03,0.13,1.0), Color(0.65,0.35,1.00,0.85)))
		name_lbl.add_theme_color_override("font_color", Color(0.90, 0.80, 1.00, 1.0))
		desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.62, 0.90, 0.82))
		btn.disabled = false

	else:
		btn.add_theme_stylebox_override("normal", _mk_style(Color(0.04,0.02,0.07,0.92), Color(0.22,0.15,0.32,0.38)))
		btn.add_theme_stylebox_override("hover",  _mk_style(Color(0.04,0.02,0.07,0.92), Color(0.22,0.15,0.32,0.38)))
		btn.add_theme_stylebox_override("focus",  _mk_style(Color(0.04,0.02,0.07,0.92), Color(0.22,0.15,0.32,0.38)))
		name_lbl.add_theme_color_override("font_color", Color(0.30, 0.22, 0.40, 0.48))
		desc_lbl.add_theme_color_override("font_color", Color(0.24, 0.18, 0.32, 0.38))
		btn.disabled = true

func _mk_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(1)
	s.border_color = border
	s.set_corner_radius_all(5)
	s.content_margin_left   = 7.0
	s.content_margin_right  = 7.0
	s.content_margin_top    = 5.0
	s.content_margin_bottom = 5.0
	return s

func _divider(col: Color) -> ColorRect:
	var d := ColorRect.new()
	d.custom_minimum_size = Vector2(0, 1)
	d.color               = col
	return d

# ── Actions ───────────────────────────────────────────────────────────────────

func _on_buy(skill_id: String) -> void:
	PlayerData.selected_char = _char_id
	if PlayerData.buy_skill(skill_id):
		_refresh()
		skill_changed.emit()

func _on_close() -> void:
	hide()
	skill_changed.emit()

func _on_reset_down() -> void:
	_reset_holding = true
	_reset_timer   = 0.0

func _on_reset_up() -> void:
	_reset_holding = false
	_reset_timer   = 0.0
	_reset_btn.text = "⚠  RESET"

func _do_reset() -> void:
	PlayerData.reset_char_skills(_char_id)
	_reset_btn.text = "⚠  RESET"
	_rebuild_tree()
	_refresh()
	skill_changed.emit()
