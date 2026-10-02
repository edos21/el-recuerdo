class_name PauseMenu
extends CanvasLayer
# Esc: pausa del juego. Con el libro de huéspedes es la contratapa del cuaderno
# (con voz propia); sin el, o en un recuerdo ajeno, una pausa minima. Core lo
# crea y decide cual de las dos corresponde (`notebook_available`). Se arma en
# codigo, como el fundido de SceneRouter: son cuatro etiquetas y un panel.

enum Page { MAIN, OPTIONS }
enum Action { RESUME, OPTIONS, QUIT, BACK }

const PAUSE_HOLDER := &"menu"
const CAVEAT := preload("res://assets/fonts/Caveat-VariableFont_wght.ttf")

const PANEL_WIDTH := 760.0
const PANEL_PADDING := 48
const BORDER_WIDTH := 4
const ROW_GAP := 14
const TITLE_SIZE := 46
const BODY_SIZE := 28
const OPTION_SIZE := 34
const HINT_SIZE := 22
const DIM_COLOR := Color(0, 0, 0, 0.55)
const PLAIN_PANEL := Color(0.05, 0.05, 0.08, 0.92)
const PLAIN_TEXT := Color(0.95, 0.93, 0.88)
const PLAIN_HINT := Color(0.75, 0.75, 0.8)
const PAPER_PANEL := Color(0.93, 0.88, 0.76)
const PAPER_BORDER := Color(0.36, 0.25, 0.16)
const INK_TEXT := Color(0.16, 0.12, 0.1)
const INK_HINT := Color(0.4, 0.33, 0.27)
const MARKER := ">  "
const MARKER_PADDING := "    "
const HINT := "[W/S] elegir     [Enter] confirmar     [Esc] volver"

const PLAIN_TITLE := "Pausa"
const NOTEBOOK_TITLE := "Instrucciones para detenerse"
const NOTEBOOK_BODY := "Primero, dejar de moverse. Después, esperar a que el mundo también se dé cuenta."
const OPTIONS_TITLE := "Opciones"
const OPTIONS_BODY := "Por ahora no hay nada que ajustar. Si algo molesta, probar con respirar más hondo."
const ACTION_LABELS := {
	Action.RESUME: "Seguir",
	Action.OPTIONS: "Opciones",
	Action.QUIT: "Salir",
	Action.BACK: "Volver",
}

var page := Page.MAIN

var _core: Core
var _selected := 0
var _actions: Array[Action] = []
var _panel_style := StyleBoxFlat.new()
var _panel := PanelContainer.new()
var _title := Label.new()
var _body := Label.new()
var _options := Label.new()
var _hint := Label.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_core = get_parent()
	visible = false
	_build()

func is_open() -> bool:
	return visible

func is_notebook_view() -> bool:
	return _core.notebook_available()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel_style.set_border_width_all(BORDER_WIDTH)
	_panel_style.set_content_margin_all(PANEL_PADDING)
	_panel.add_theme_stylebox_override("panel", _panel_style)
	_panel.custom_minimum_size.x = PANEL_WIDTH
	center.add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", ROW_GAP)
	_panel.add_child(column)
	for label in [_title, _body, _options, _hint]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(label)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		if visible:
			_back()
		else:
			_open()
		return
	if not visible:
		return
	get_viewport().set_input_as_handled()
	var step := int(event.is_action_pressed(&"move_down")) - int(event.is_action_pressed(&"move_up"))
	if step != 0:
		_selected = posmod(_selected + step, _actions.size())
		_render()
	elif event.is_action_pressed(&"interact"):
		_confirm(_actions[_selected])

# Un dialogo abierto o un fundido en curso tienen prioridad: abrir encima dejaria
# dos cosas pidiendo la misma tecla.
func _open() -> void:
	if Pause.is_held_by_other(PAUSE_HOLDER) or SceneRouter.is_busy():
		return
	page = Page.MAIN
	_selected = 0
	visible = true
	Pause.hold(PAUSE_HOLDER)
	_render()

func _close() -> void:
	visible = false
	Pause.release(PAUSE_HOLDER)

func _back() -> void:
	if page == Page.OPTIONS:
		_show_page(Page.MAIN)
	else:
		_close()

func _show_page(target: Page) -> void:
	page = target
	_selected = 0
	_render()

func _confirm(action: Action) -> void:
	match action:
		Action.RESUME:
			_close()
		Action.OPTIONS:
			_show_page(Page.OPTIONS)
		Action.BACK:
			_show_page(Page.MAIN)
		Action.QUIT:
			get_tree().quit()

func _render() -> void:
	var notebook := is_notebook_view()
	_apply_style(notebook)
	match page:
		Page.MAIN:
			_title.text = NOTEBOOK_TITLE if notebook else PLAIN_TITLE
			_body.text = NOTEBOOK_BODY if notebook else ""
			_actions.assign([Action.RESUME, Action.OPTIONS, Action.QUIT] if notebook else [Action.RESUME, Action.QUIT])
		Page.OPTIONS:
			_title.text = OPTIONS_TITLE
			_body.text = OPTIONS_BODY
			_actions.assign([Action.BACK])
	_body.visible = _body.text != ""
	var rows := PackedStringArray()
	for i in _actions.size():
		rows.append((MARKER if i == _selected else MARKER_PADDING) + ACTION_LABELS[_actions[i]])
	_options.text = "\n".join(rows)
	_hint.text = HINT

# La contratapa es papel con tinta manuscrita; la pausa minima, el mismo panel
# oscuro del cuadro de dialogo.
func _apply_style(notebook: bool) -> void:
	_panel_style.bg_color = PAPER_PANEL if notebook else PLAIN_PANEL
	_panel_style.border_color = PAPER_BORDER if notebook else PLAIN_PANEL
	var text_color := INK_TEXT if notebook else PLAIN_TEXT
	var hint_color := INK_HINT if notebook else PLAIN_HINT
	_style_label(_title, TITLE_SIZE, text_color, notebook)
	_style_label(_body, BODY_SIZE, text_color, notebook)
	_style_label(_options, OPTION_SIZE, text_color, notebook)
	_style_label(_hint, HINT_SIZE, hint_color, notebook)

func _style_label(label: Label, size: int, color: Color, handwritten: bool) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if handwritten:
		label.add_theme_font_override("font", CAVEAT)
	else:
		label.remove_theme_font_override("font")
