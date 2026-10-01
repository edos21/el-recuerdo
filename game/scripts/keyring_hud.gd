class_name KeyringHud
extends CanvasLayer
# El llavero de Tomás en pantalla: los tres días y cuál está activo. Vive aparte
# del HUD de Core porque es de este recuerdo y no de todos los géneros.

const TOP_MARGIN := 24.0
const FONT_SIZE := 30
const OUTLINE_SIZE := 4
const DAY_NAMES: Array[String] = ["Antes", "Hoy", "Ayer"]
const ACTIVE_COLOR := "#ffe9a0"
const INACTIVE_COLOR := "#6e6e78"
const KEY_COLOR := "#9a9aa6"
const SEPARATOR := "     "

var _label := RichTextLabel.new()

func _ready() -> void:
	layer = Core.HUD_LAYER
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.anchor_right = 1.0
	_label.offset_top = TOP_MARGIN
	_label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	_label.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	add_child(_label)

# Los nombres de las teclas son los de las acciones keyring_prev y keyring_next.
func show_day(day: StageMap.Day) -> void:
	var names: Array[String] = []
	for i in DAY_NAMES.size():
		var active := i == day
		names.append(_tint("[b]%s[/b]" % DAY_NAMES[i] if active else DAY_NAMES[i], ACTIVE_COLOR if active else INACTIVE_COLOR))
	var days := SEPARATOR.join(names)
	_label.text = "[center]%s%s%s%s%s[/center]" % [_tint("Q", KEY_COLOR), SEPARATOR, days, SEPARATOR, _tint("E", KEY_COLOR)]

func _tint(text: String, color: String) -> String:
	return "[color=%s]%s[/color]" % [color, text]
