class_name NotebookErrands
extends RefCounted
# Sub-vista de Encargos del cuaderno: el índice de lo anotado en la página
# izquierda (los cumplidos tachados, al final) y el dibujo de la entrada elegida
# en la derecha. Solo arma y muestra; qué hay y en qué etapa lo dice NotebookData
# y la nota la escribe PauseMenu en sus rótulos de siempre.

const MAX_ROWS := 10
const DRAWING_ROWS := 3
# El título ocupa el primer renglón de la página derecha; el dibujo va debajo.
const DRAWING_SLOT := 1

var rows: Array[Label] = []
var entries: Array[NotebookEntryDef] = []
var _strikes: Array[StrikeLine] = []
var _drawing := TextureRect.new()

func _init(left_body: Control, right_body: Control, make_row: Callable) -> void:
	for i in MAX_ROWS:
		var row: Label = make_row.call()
		var strike := StrikeLine.new()
		strike.seed_value = i
		row.add_child(strike)
		row.visible = false
		left_body.add_child(row)
		rows.append(row)
		_strikes.append(strike)
	_drawing.custom_minimum_size.y = RegisterPage.ROW_HEIGHT * DRAWING_ROWS
	_drawing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_drawing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_drawing.visible = false
	right_body.add_child(_drawing)
	right_body.move_child(_drawing, DRAWING_SLOT)

# Vuelve a leer el catálogo: lo que se hizo desde la última vez cambia de etapa.
func refresh() -> void:
	entries = Catalogs.notebook.visible_entries().slice(0, MAX_ROWS)
	for i in MAX_ROWS:
		var shown := i < entries.size()
		rows[i].visible = shown
		if not shown:
			continue
		rows[i].text = entries[i].title
		var font := rows[i].get_theme_font("font")
		var size := rows[i].get_theme_font_size("font_size")
		_strikes[i].span = font.get_string_size(entries[i].title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x if Catalogs.notebook.is_done(entries[i]) else 0.0

# Muestra u oculta toda la sub-vista (el dibujo solo con algo que dibujar).
func set_active(active: bool) -> void:
	if not active:
		for row in rows:
			row.visible = false
	_drawing.visible = active and not entries.is_empty()

func show_drawing(entry: NotebookEntryDef) -> void:
	var path := Catalogs.notebook.drawing_path(entry)
	_drawing.texture = load(path) if ResourceLoader.exists(path) else null
