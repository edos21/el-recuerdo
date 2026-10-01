class_name KeyringHud
extends CanvasLayer
# El llavero de Tomás en pantalla: los tres días y cuál está activo. Vive aparte
# del HUD de Core porque es de este recuerdo y no de todos los géneros.

const TOP_MARGIN := 24.0
const FONT_SIZE := 30
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
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)

func show_day(day: int) -> void:
	var names: Array[String] = []
	for i in DAY_NAMES.size():
		var color := ACTIVE_COLOR if i == day else INACTIVE_COLOR
		var text := "[b]%s[/b]" % DAY_NAMES[i] if i == day else DAY_NAMES[i]
		names.append("[color=%s]%s[/color]" % [color, text])
	var keys := "[color=%s]%s[/color]"
	_label.text = "[center]%s%s%s%s%s[/center]" % [keys % [KEY_COLOR, "Q"], SEPARATOR, SEPARATOR.join(names), SEPARATOR, keys % [KEY_COLOR, "E"]]
