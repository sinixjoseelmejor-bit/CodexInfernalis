extends Control

const CHAR_DELAY    := 0.04
const BLINK_SPEED   := 0.6
const FADE_DUR      := 0.5
const PAN_DUR       := 10.0
const PAN_EXTRA     := 0.1
const CROSSFADE_DUR := 1.0

var _panels := [
	"On disait de Valdris qu'il était le royaume choyé des cieux.\n\nPendant deux siècles, une paix insolente y avait élu domicile, transformant chaque moisson en triomphe et chaque bataille en une simple formalité.",
	"Sous le sceptre d'un roi sage, les cités de marbre s'élevaient, invaincues, portées par la certitude que rien ne pourrait jamais ternir cet âge d'or.\n\nLe peuple se complaisait dans cette protection divine, ignorant avec superbe le prix qu'une telle prospérité exigeait dans l'ombre.",
	"Mais la lumière la plus vive projette toujours les ombres les plus noires.",
	"L'horreur survint sans le moindre avertissement, au cœur de la Forêt des Cendres.\n\nUne déchirure s'ouvrit dans la trame même du monde, laissant apparaître un portail de feu noir, une plaie béante et silencieuse.\n\nEn l'espace de trois jours, une brume violette, lourde et surnaturelle, commença à ramper sur les plaines fertiles.",
	"Le fléau ne tuait pas.\n\nIl figeait.\n\nCeux que la brume effleurait se transformaient instantanément en statues de chair, prisonniers d'une seconde éternelle. Des milliers de citoyens, des phalanges entières de soldats et des enfants en plein jeu — pétrifiés, debout, les yeux grands ouverts sur un monde qu'ils ne percevaient plus.",
	"Acculés, les mages royaux finirent par identifier le mal : une énergie corrompue s'échappait du portail, liée à un artefact que l'on croyait n'être qu'une légende oubliée.\n\nLe Codex Maudit.\n\nUn grimoire de sorcellerie abyssale, enfoui dans les racines mêmes de l'Enfer. Tant que l'artefact demeurerait intact là-bas, la malédiction s'étendrait ici, jusqu'au dernier souffle de vie.",
	"Face à l'abîme, le roi lança un ultime appel — un cri de détresse qui ne trouva d'écho que chez quatre âmes.\n\nQuatre aventuriers, portés par des raisons que seuls les désespérés connaissent, se portèrent volontaires pour l'impossible.",
	"Alors qu'ils s'avançaient vers la gueule béante du portail, le roi les regarda s'éloigner.\n\nMais dans son regard, il n'y avait aucune trace d'espoir. On y lisait seulement le soulagement sinistre d'un homme qui vient de verser son dernier tribut.",
	"Sans un mot,\n\nils franchirent le portail de feu noir.",
]

var _backgrounds := [
	"res://assets/Intro/Intro1.png",
	"res://assets/Intro/Intro2.png",
	"res://assets/Intro/Intro2.png",
	"res://assets/Intro/Intro3.png",
	"res://assets/Intro/Intro4.png",
	"res://assets/Intro/Intro5.png",
	"",
	"res://assets/Intro/Intro6.png",
	"res://assets/Intro/Intro6.png",
]

var _current       := 0
var _char_idx      := 0
var _typing        := false
var _blink_t       := 0.0
var _blink_visible := true
var _current_bg    := ""
var _pan_tween     : Tween
var _leaving       := false

var _music_base_vol := -12.0
var _track_len      := 0.0
var _crossfading    := false
var _music_next     : AudioStreamPlayer

@onready var _label    : RichTextLabel      = $Text
@onready var _prompt   : Label              = $Prompt
@onready var _bg_img   : TextureRect        = $BGImage
@onready var _click    : AudioStreamPlayer  = $ClickSFX
@onready var _music    : AudioStreamPlayer  = $Music
@onready var _skip_btn : Button             = $SkipBtn


func _ready() -> void:
	_label.bbcode_enabled = true
	_prompt.text       = "[ Appuyer pour continuer ]"
	_prompt.modulate.a = 0.0
	_bg_img.modulate.a = 0.0
	_music_base_vol    = _music.volume_db
	_skip_btn.pressed.connect(_on_skip_pressed)
	_show_panel(_current)


func _on_skip_pressed() -> void:
	if _typing:
		_typing    = false
		_label.text = _panels[_current]
		_char_idx   = _panels[_current].length()
		_prompt.modulate.a = 1.0


func _process(delta: float) -> void:
	if not _typing:
		_blink_t += delta
		if _blink_t >= BLINK_SPEED:
			_blink_t = 0.0
			_blink_visible = not _blink_visible
			_prompt.modulate.a = 1.0 if _blink_visible else 0.0

	if _leaving or _crossfading:
		return
	if _track_len <= 0.0 and _music.playing:
		_track_len = _music.stream.get_length()
		return
	if _track_len > 0.0 and _music.playing:
		if _music.get_playback_position() >= _track_len - CROSSFADE_DUR:
			_do_crossfade()


func _do_crossfade() -> void:
	_crossfading = true
	_music_next = AudioStreamPlayer.new()
	_music_next.stream    = _music.stream
	_music_next.volume_db = -80.0
	add_child(_music_next)
	_music_next.play()
	create_tween().tween_property(_music_next, "volume_db", _music_base_vol, CROSSFADE_DUR)
	create_tween().tween_property(_music,      "volume_db", -80.0,           CROSSFADE_DUR)
	await get_tree().create_timer(CROSSFADE_DUR).timeout
	if _leaving or not is_instance_valid(self):
		return
	_music.queue_free()
	_music        = _music_next
	_music_next   = null
	_music.volume_db = _music_base_vol
	_track_len    = 0.0
	_crossfading  = false


func _show_panel(idx: int) -> void:
	_label.text        = ""
	_char_idx          = 0
	_typing            = true
	_prompt.modulate.a = 0.0
	_crossfade_bg(_backgrounds[idx])
	_type_panel(_panels[idx])


func _crossfade_bg(path: String) -> void:
	if path == _current_bg:
		return
	_current_bg = path
	var tween := create_tween()
	tween.tween_property(_bg_img, "modulate:a", 0.0, FADE_DUR)
	tween.tween_callback(func() -> void:
		_bg_img.texture = null if path == "" else load(path)
		_start_pan()
		create_tween().tween_property(_bg_img, "modulate:a", 1.0, FADE_DUR)
	)


func _start_pan() -> void:
	if _pan_tween:
		_pan_tween.kill()
	if _bg_img.texture == null:
		return
	var vp    := get_viewport_rect().size
	var extra := vp.x * PAN_EXTRA
	var tex   := _bg_img.texture.get_size()
	# scale pour que la largeur couvre exactement viewport + déplacement du pan
	var tex_scale := (vp.x + extra) / tex.x
	var new_w := tex.x * tex_scale
	var new_h := tex.y * tex_scale
	_bg_img.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_bg_img.size     = Vector2(new_w, new_h)
	_bg_img.position = Vector2(0.0, -(new_h - vp.y) / 2.0)
	_pan_tween = create_tween()
	_pan_tween.tween_property(_bg_img, "position:x", -extra, PAN_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _type_panel(text: String) -> void:
	for i in text.length():
		if not _typing:
			return
		_char_idx   = i
		var ch      := text[i]
		_label.text = text.substr(0, i + 1)
		if ch != " " and ch != "\n":
			_click.play()
		await get_tree().create_timer(CHAR_DELAY).timeout
	if _typing:
		_typing  = false
		_blink_t = 0.0


func _input(event: InputEvent) -> void:
	if _typing:
		return
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	get_viewport().set_input_as_handled()
	_current += 1
	if _current >= _panels.size():
		_fade_out_and_go()
	else:
		_show_panel(_current)


func _fade_out_and_go() -> void:
	_leaving = true
	var t := create_tween()
	t.tween_property(_music, "volume_db", -80.0, 0.5)
	if is_instance_valid(_music_next):
		t.parallel().tween_property(_music_next, "volume_db", -80.0, 0.5)
	t.parallel().tween_property(_label,  "modulate:a", 0.0, 0.5)
	t.parallel().tween_property(_prompt, "modulate:a", 0.0, 0.5)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/SelectCharacter.tscn")
	)
