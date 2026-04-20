extends CanvasLayer

const JOYSTICK_RADIUS := 90.0
const DEAD_ZONE       := 12.0
const DEFAULT_JOY_POS := Vector2(200, 880)

var _left_id    := -1
var _right_id   := -1
var _joy_origin := DEFAULT_JOY_POS

var _base : Panel
var _knob : Panel
var _cross: Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_ui()
	visible = DisplayServer.is_touchscreen_available()

func _build_ui() -> void:
	_base  = _circle_panel(Vector2(180, 180), Color(1, 1, 1, 0.12))
	_knob  = _circle_panel(Vector2(76,  76),  Color(1, 1, 1, 0.30))
	_cross = _circle_panel(Vector2(56,  56),  Color(1.0, 0.75, 0.2, 0.50))

	add_child(_base)
	add_child(_knob)
	add_child(_cross)

	_cross.visible = false
	_move_panel(_base, _joy_origin)
	_move_panel(_knob, _joy_origin)

	var right_lbl := Label.new()
	right_lbl.text = "VISER"
	right_lbl.position = Vector2(1680, 960)
	right_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.18))
	add_child(right_lbl)

func _circle_panel(sz: Vector2, color: Color) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = sz
	p.size = sz
	var r := int(sz.x / 2)
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left    = r
	s.corner_radius_top_right   = r
	s.corner_radius_bottom_left = r
	s.corner_radius_bottom_right= r
	p.add_theme_stylebox_override("panel", s)
	return p

func _move_panel(p: Panel, center: Vector2) -> void:
	p.position = center - p.size / 2.0

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)

func _on_touch(e: InputEventScreenTouch) -> void:
	var half_w := get_viewport().get_visible_rect().size.x / 2.0
	if e.pressed:
		if e.position.x < half_w and _left_id == -1:
			_left_id = e.index
			_joy_origin = e.position
			_move_panel(_base, _joy_origin)
			_move_panel(_knob, _joy_origin)
		elif e.position.x >= half_w and _right_id == -1:
			_right_id = e.index
			PlayerData.touch_aim_world  = _to_world(e.position)
			PlayerData.touch_shooting   = true
			_cross.visible = true
			_move_panel(_cross, e.position)
	else:
		if e.index == _left_id:
			_left_id = -1
			PlayerData.touch_move = Vector2.ZERO
			_joy_origin = DEFAULT_JOY_POS
			_move_panel(_base, _joy_origin)
			_move_panel(_knob, _joy_origin)
		elif e.index == _right_id:
			_right_id = -1
			PlayerData.touch_shooting  = false
			PlayerData.touch_aim_world = Vector2.ZERO
			_cross.visible = false

func _on_drag(e: InputEventScreenDrag) -> void:
	if e.index == _left_id:
		var delta := e.position - _joy_origin
		PlayerData.touch_move = delta.normalized() if delta.length() > DEAD_ZONE else Vector2.ZERO
		_move_panel(_knob, _joy_origin + delta.limit_length(JOYSTICK_RADIUS))
	elif e.index == _right_id:
		PlayerData.touch_aim_world = _to_world(e.position)
		_move_panel(_cross, e.position)

func _to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos
