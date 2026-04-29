extends CanvasLayer

const JOYSTICK_RADIUS := 90.0
const DEAD_ZONE       := 14.0

var _left_id         := -1
var _right_id        := -1
var _joy_origin      := Vector2.ZERO
var _default_joy_pos := Vector2.ZERO

var _base  : Panel
var _knob  : Panel
var _cross : Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_ui()
	visible = DisplayServer.is_touchscreen_available()

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size
	_default_joy_pos = Vector2(vp.x * 0.115, vp.y * 0.80)
	_joy_origin = _default_joy_pos

	var s := Settings.joystick_size
	_base  = _circle_panel(Vector2(200, 200) * s, Color(1, 1, 1, 0.12))
	_knob  = _circle_panel(Vector2(88,  88)  * s, Color(1, 1, 1, 0.30))
	_cross = _circle_panel(Vector2(64,  64),       Color(1.0, 0.75, 0.2, 0.50))

	add_child(_base)
	add_child(_knob)
	add_child(_cross)

	_cross.visible = false
	_move_panel(_base, _joy_origin)
	_move_panel(_knob, _joy_origin)

	var right_lbl := Label.new()
	right_lbl.text = "VISER"
	right_lbl.position = Vector2(vp.x * 0.875, vp.y * 0.87)
	right_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.18))
	add_child(right_lbl)

	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.custom_minimum_size = Vector2(72, 52)
	pause_btn.position = Vector2(vp.x / 2.0 - 36, 16)
	var sbox := StyleBoxFlat.new()
	sbox.bg_color = Color(0, 0, 0, 0.35)
	sbox.border_width_left   = 1
	sbox.border_width_right  = 1
	sbox.border_width_top    = 1
	sbox.border_width_bottom = 1
	sbox.border_color = Color(1, 1, 1, 0.30)
	sbox.corner_radius_top_left     = 8
	sbox.corner_radius_top_right    = 8
	sbox.corner_radius_bottom_left  = 8
	sbox.corner_radius_bottom_right = 8
	pause_btn.add_theme_stylebox_override("normal", sbox)
	pause_btn.add_theme_stylebox_override("hover",  sbox)
	pause_btn.add_theme_stylebox_override("pressed", sbox)
	pause_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	pause_btn.add_theme_font_size_override("font_size", 18)
	pause_btn.pressed.connect(_on_pause_pressed)
	add_child(pause_btn)

func _circle_panel(sz: Vector2, color: Color) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = sz
	p.size = sz
	var r := int(sz.x / 2)
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = r
	s.corner_radius_top_right    = r
	s.corner_radius_bottom_left  = r
	s.corner_radius_bottom_right = r
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
			InputBus.touch_aim_world = _to_world(e.position)
			InputBus.touch_shooting  = true
			_cross.visible = true
			_move_panel(_cross, e.position)
	else:
		if e.index == _left_id:
			_left_id = -1
			InputBus.touch_move = Vector2.ZERO
			_joy_origin = _default_joy_pos
			_move_panel(_base, _joy_origin)
			_move_panel(_knob, _joy_origin)
		elif e.index == _right_id:
			_right_id = -1
			InputBus.touch_shooting  = false
			InputBus.touch_aim_world = Vector2.ZERO
			_cross.visible = false

func _on_drag(e: InputEventScreenDrag) -> void:
	if e.index == _left_id:
		var delta := e.position - _joy_origin
		var radius := JOYSTICK_RADIUS * Settings.joystick_size
		InputBus.touch_move = delta.normalized() if delta.length() > DEAD_ZONE else Vector2.ZERO
		_move_panel(_knob, _joy_origin + delta.limit_length(radius))
	elif e.index == _right_id:
		InputBus.touch_aim_world = _to_world(e.position)
		_move_panel(_cross, e.position)

func _to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _on_pause_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action  = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
