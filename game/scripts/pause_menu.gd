class_name PauseMenu
extends CanvasLayer
# Esc: pausa del juego. Con el libro de huespedes se abre el libro a doble
# pagina (indice a la izquierda, lo anotado de cada entrada a la derecha); sin
# el, o en un recuerdo ajeno, una pausa minima. Core lo crea y le pasa como
# decidir cual de las dos corresponde (`notebook_available`). Se arma en
# codigo, como el fundido de SceneRouter.

enum Entry { RESUME, ERRANDS, TOWN, OPTIONS, LOAD, QUIT }

const PAUSE_HOLDER := &"menu"
const CAVEAT := preload("res://assets/fonts/Caveat-VariableFont_wght.ttf")
const HANDWRITING_WEIGHT := 700
# Caveat junta mucho las letras: un poco de aire entre glifos la hace legible.
const HANDWRITING_SPACING := 2
const PLAIN_EMBOLDEN := 1.0

const PLAIN_ENTRIES: Array[Entry] = [Entry.RESUME, Entry.QUIT]
const NOTEBOOK_ENTRIES: Array[Entry] = [Entry.RESUME, Entry.ERRANDS, Entry.TOWN, Entry.OPTIONS, Entry.LOAD, Entry.QUIT]
const ENTRY_LABELS := {
	Entry.RESUME: "Seguir",
	Entry.ERRANDS: "Encargos",
	Entry.TOWN: "El pueblo",
	Entry.OPTIONS: "Opciones",
	Entry.LOAD: "Cargar",
	Entry.QUIT: "Salir",
}
# Lo que el protagonista tiene anotado en cada entrada; el titulo es el de la
# entrada salvo en Seguir. Las que todavia no tienen contenido (encargos,
# pueblo, opciones, cargar) son una nota suya.
const RESUME_NOTE_TITLE := "Instrucciones para detenerse"
const ENTRY_NOTES := {
	Entry.RESUME: "Primero, dejar de moverse. Después, esperar a que el mundo también se dé cuenta.",
	Entry.ERRANDS: "Todavía no anoté ninguno. O me los olvidé, que sería peor.",
	Entry.TOWN: "Una posada, una olla y demasiada gente para tan pocas calles. Anotar nombres antes de que se me olviden.",
	Entry.OPTIONS: "Por ahora no hay nada que ajustar. Si algo molesta, probar con respirar más hondo.",
	Entry.LOAD: "Lo que se guarda, se guarda durmiendo. Por ahora no hay nada que cargar, salvo la valija.",
	Entry.QUIT: "Cerrar el libro. El pueblo va a seguir aquí mañana. Eso espero.",
}
const NAME_VALUE := "Todavía no me acuerdo"
const ROOM_VALUE := "La de arriba"
const HINT := Hud.CHOICE_HINT + "     [Esc] seguir"

const DIM_COLOR := Color(0, 0, 0, 0.5)
const HINT_SIZE := 22
const HINT_COLOR := Color(0.85, 0.85, 0.9)

# Pausa minima: caja translucida con el titulo montado sobre el borde, en el
# azul de la Estabilidad (detenerse es lo que la cuida).
const PLAIN_BOX_SIZE := Vector2(560, 360)
const PLAIN_BOX_COLOR := Color(0.04, 0.05, 0.09, 0.68)
const PLAIN_BORDER_COLOR := Color(Hud.BAR_GROWTH_COLOR, 0.45)
const PLAIN_CORNER := 14
const PLAIN_TITLE := "Pausa"
const PLAIN_TITLE_SIZE := 72
const PLAIN_TITLE_COLOR := Hud.BAR_GROWTH_COLOR
const PLAIN_TITLE_OUTLINE := Color(0.03, 0.04, 0.08)
const PLAIN_TITLE_OUTLINE_SIZE := 14
# El centro de la etiqueta no es el de las letras (sin descendentes, quedan bajas).
const PLAIN_TITLE_LIFT := 12.0
const PLAIN_OPTIONS_TOP := 80.0
const PLAIN_OPTION_SIZE := 38
const PLAIN_OPTION_GAP := 26
const PLAIN_SELECTED := Color(0.95, 0.93, 0.88)
const PLAIN_IDLE := Color(0.95, 0.93, 0.88, 0.55)
const PLAIN_MARKER := "›   %s   ‹"

# Libro abierto: tapa de cuero, dos paginas de registro.
const PAGE_SIZE := Vector2(740, 800)
const COVER_COLOR := Color(0.3, 0.17, 0.1)
const COVER_BORDER := Color(0.16, 0.08, 0.04)
const COVER_MARGIN := 20
const COVER_CORNER := 16
const BOOK_HINT_GAP := 18
const INK := Color(0.08, 0.07, 0.1)
const INK_IDLE := Color(0.08, 0.07, 0.1, 0.78)
const MARKER_HIGHLIGHT := Color(0.98, 0.82, 0.3, 0.45)
const MARKER_OVERHANG := 10.0
const FIELD_SIZE := 42
const ENTRY_SIZE := 44
const NOTE_TITLE_SIZE := 48
const NOTE_SIZE := 38
const LEFT_COLUMNS := ["Fecha", "Nombre", "Procedencia"]
const LEFT_COLUMN_STARTS := [0.0, 0.2, 0.72]
const LEFT_WRITING_COLUMN := 1
const RIGHT_COLUMNS := ["Observaciones"]
const RIGHT_COLUMN_STARTS := [0.0]
const RIGHT_PAGE_SEED := 1.0

# Lo pasa Core: si corresponde el cuaderno o la pausa minima.
var notebook_available: Callable
var _notebook := false
var _entries: Array[Entry] = []
var _selected := 0
var _handwriting := FontVariation.new()
var _plain_bold := FontVariation.new()

var _plain_root := Control.new()
var _plain_rows: Array[Label] = []
var _book_root := Control.new()
var _book_rows: Array[Label] = []
var _note_title: Label
var _note_body: Label
var _marker_style := StyleBoxFlat.new()
var _no_style := StyleBoxEmpty.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_handwriting.base_font = CAVEAT
	_handwriting.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): HANDWRITING_WEIGHT}
	_handwriting.spacing_glyph = HANDWRITING_SPACING
	_plain_bold.base_font = ThemeDB.fallback_font
	_plain_bold.variation_embolden = PLAIN_EMBOLDEN
	_marker_style.bg_color = MARKER_HIGHLIGHT
	_marker_style.expand_margin_left = MARKER_OVERHANG
	_marker_style.expand_margin_right = MARKER_OVERHANG
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_build_plain()
	_build_book()

func is_open() -> bool:
	return visible

func is_notebook_view() -> bool:
	return visible and _notebook

func entries() -> Array[Entry]:
	return _entries

func selected_entry() -> Entry:
	return _entries[_selected]

func note_title() -> String:
	return _note_title.text

func _build_plain() -> void:
	var center := _make_centered(_plain_root)
	var box := Control.new()
	box.custom_minimum_size = PLAIN_BOX_SIZE
	center.add_child(box)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = PLAIN_BOX_COLOR
	style.border_color = PLAIN_BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(PLAIN_CORNER)
	panel.add_theme_stylebox_override("panel", style)
	box.add_child(panel)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_top = PLAIN_OPTIONS_TOP
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", PLAIN_OPTION_GAP)
	box.add_child(column)
	for i in PLAIN_ENTRIES.size():
		var row := _make_label(_plain_bold, PLAIN_OPTION_SIZE, PLAIN_IDLE)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(row)
		_plain_rows.append(row)
	column.add_child(_make_hint())

	# Montado sobre el borde de arriba: la mitad adentro y la mitad afuera.
	var title := _make_label(_plain_bold, PLAIN_TITLE_SIZE, PLAIN_TITLE_COLOR)
	title.text = PLAIN_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", PLAIN_TITLE_OUTLINE)
	title.add_theme_constant_override("outline_size", PLAIN_TITLE_OUTLINE_SIZE)
	title.anchor_right = 1.0
	title.offset_top = -PLAIN_TITLE_SIZE * 0.5 - PLAIN_TITLE_LIFT
	title.offset_bottom = PLAIN_TITLE_SIZE * 0.5 - PLAIN_TITLE_LIFT
	box.add_child(title)

func _build_book() -> void:
	var center := _make_centered(_book_root)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", BOOK_HINT_GAP)
	center.add_child(stack)

	var cover := PanelContainer.new()
	var leather := StyleBoxFlat.new()
	leather.bg_color = COVER_COLOR
	leather.border_color = COVER_BORDER
	leather.set_border_width_all(4)
	leather.set_corner_radius_all(COVER_CORNER)
	leather.set_content_margin_all(COVER_MARGIN)
	cover.add_theme_stylebox_override("panel", leather)
	stack.add_child(cover)
	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 0)
	cover.add_child(spread)

	var left := _make_page("Nombre", NAME_VALUE)
	left.columns = PackedStringArray(LEFT_COLUMNS)
	left.column_starts = PackedFloat32Array(LEFT_COLUMN_STARTS)
	left.writing_column = LEFT_WRITING_COLUMN
	spread.add_child(left)
	for i in NOTEBOOK_ENTRIES.size():
		var row := _make_row(ENTRY_SIZE, INK_IDLE)
		left.body.add_child(row)
		_book_rows.append(row)

	var right := _make_page("Habitación", ROOM_VALUE)
	right.columns = PackedStringArray(RIGHT_COLUMNS)
	right.column_starts = PackedFloat32Array(RIGHT_COLUMN_STARTS)
	right.spine_on_left = true
	right.paper_seed = RIGHT_PAGE_SEED
	spread.add_child(right)
	_note_title = _make_row(NOTE_TITLE_SIZE, INK)
	right.body.add_child(_note_title)
	_note_body = _make_label(_handwriting, NOTE_SIZE, INK)
	_note_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Cada linea de la nota cae sobre un renglon del registro.
	_note_body.add_theme_constant_override("line_spacing", int(RegisterPage.ROW_HEIGHT - _handwriting.get_height(NOTE_SIZE)))
	right.body.add_child(_note_body)

	stack.add_child(_make_hint())

# Raiz de una vista a pantalla completa, con su contenido centrado.
func _make_centered(root: Control) -> CenterContainer:
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	return center

func _make_hint() -> Label:
	var hint := _make_label(ThemeDB.fallback_font, HINT_SIZE, HINT_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = HINT
	return hint

func _make_page(field: String, value: String) -> RegisterPage:
	var page := RegisterPage.new()
	page.custom_minimum_size = PAGE_SIZE
	page.field_label = field
	_style_label(page.field_value, _handwriting, FIELD_SIZE, INK)
	page.field_value.text = value
	return page

# Un renglon escrito a mano, alineado con las lineas de la pagina.
func _make_row(size: int, color: Color) -> Label:
	var row := _make_label(_handwriting, size, color)
	row.custom_minimum_size.y = RegisterPage.ROW_HEIGHT
	row.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return row

func _make_label(font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	_style_label(label, font, size, color)
	return label

func _style_label(label: Label, font: Font, size: int, color: Color) -> void:
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		if visible:
			_close()
		else:
			_open()
		return
	if not visible:
		return
	get_viewport().set_input_as_handled()
	var step := int(event.is_action_pressed(&"move_down")) - int(event.is_action_pressed(&"move_up"))
	if step != 0:
		_selected = posmod(_selected + step, _entries.size())
		_render()
	elif event.is_action_pressed(&"interact"):
		_confirm(selected_entry())

# Un dialogo abierto o un fundido en curso tienen prioridad: abrir encima dejaria
# dos cosas pidiendo la misma tecla.
func _open() -> void:
	if get_tree().paused or SceneRouter.is_busy():
		return
	_notebook = notebook_available.call()
	_entries = NOTEBOOK_ENTRIES if _notebook else PLAIN_ENTRIES
	_selected = 0
	_plain_root.visible = not _notebook
	_book_root.visible = _notebook
	visible = true
	Pause.hold(PAUSE_HOLDER)
	_render()

func _close() -> void:
	visible = false
	Pause.release(PAUSE_HOLDER)

# Las entradas sin contenido todavia solo muestran su nota a la derecha.
func _confirm(entry: Entry) -> void:
	match entry:
		Entry.RESUME:
			_close()
		Entry.QUIT:
			get_tree().quit()

func _render() -> void:
	if _notebook:
		_render_book()
	else:
		_render_plain()

func _render_plain() -> void:
	for i in _plain_rows.size():
		var label: String = ENTRY_LABELS[_entries[i]]
		var chosen := i == _selected
		_plain_rows[i].text = PLAIN_MARKER % label if chosen else label
		_plain_rows[i].add_theme_color_override("font_color", PLAIN_SELECTED if chosen else PLAIN_IDLE)

func _render_book() -> void:
	for i in _book_rows.size():
		var chosen := i == _selected
		_book_rows[i].text = ENTRY_LABELS[_entries[i]]
		_book_rows[i].add_theme_stylebox_override("normal", _marker_style if chosen else _no_style)
		_book_rows[i].add_theme_color_override("font_color", INK if chosen else INK_IDLE)
	var entry := selected_entry()
	_note_title.text = RESUME_NOTE_TITLE if entry == Entry.RESUME else ENTRY_LABELS[entry]
	_note_body.text = ENTRY_NOTES[entry]
