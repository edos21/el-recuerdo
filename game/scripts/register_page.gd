class_name RegisterPage
extends Control
# Una pagina del libro de huespedes de la posada: papel, renglones, un campo
# impreso arriba y las columnas del registro. Lo impreso es del hotel; lo que
# el protagonista escribe encima va en `field_value` y `body`, a mano. El chiste
# es que usa un registro de hotel como cuaderno: escribe en la columna que le
# queda comoda, no en la que corresponde.

# Hueso apagado, no crema: el amarillo saturado se veia de caricatura.
const PAPER := Color(0.9, 0.87, 0.8)
const PAPER_SHADER := preload("res://shaders/paper.gdshader")
const PRINT_INK := Color(0.55, 0.2, 0.18, 0.8)
const RULE_INK := Color(0.33, 0.47, 0.66, 0.35)
const SPINE_SHADOW := Color(0.25, 0.15, 0.08, 0.4)
const FRAME_INSET := 18.0
const FRAME_GAP := 5.0
const FIELD_HEIGHT := 74.0
const HEADER_HEIGHT := 40.0
const ROW_HEIGHT := 58.0
const PRINT_SIZE := 15
const SPINE_WIDTH := 48.0
const SPINE_STEPS := 8
const TEXT_PADDING := 12.0
const FIELD_LINE_LIFT := 14.0

# Titulo impreso del campo de arriba y de cada columna, con la fraccion del
# ancho donde empieza cada una.
var field_label := ""
var columns: PackedStringArray = []
var column_starts: PackedFloat32Array = []
# Columna donde escribe el protagonista.
var writing_column := 0
# El lomo queda del lado de adentro del libro abierto.
var spine_on_left := false
# Cada pagina con su propio grano, para que no se vean calcadas.
var paper_seed := 0.0

var field_value := Label.new()
var body := VBoxContainer.new()

func _ready() -> void:
	clip_contents = true
	var paper := ShaderMaterial.new()
	paper.shader = PAPER_SHADER
	paper.set_shader_parameter("seed", paper_seed)
	material = paper
	body.add_theme_constant_override("separation", 0)
	add_child(field_value)
	add_child(body)
	resized.connect(_place_children)
	_place_children()

func _frame() -> Rect2:
	return Rect2(Vector2.ONE * FRAME_INSET, size - Vector2.ONE * FRAME_INSET * 2.0)

func _column_x(index: int) -> float:
	var frame := _frame()
	return frame.position.x + frame.size.x * column_starts[index]

func _header_top() -> float:
	return _frame().position.y + FRAME_GAP + FIELD_HEIGHT

func _place_children() -> void:
	(material as ShaderMaterial).set_shader_parameter("page_size", size)
	var frame := _frame()
	var field_x := frame.position.x + FRAME_GAP + TEXT_PADDING + _label_width()
	field_value.position = Vector2(field_x, frame.position.y + FRAME_GAP)
	field_value.size = Vector2(frame.end.x - FRAME_GAP - field_x, FIELD_HEIGHT - FIELD_LINE_LIFT * 0.5)
	field_value.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	var body_x := _column_x(writing_column) + TEXT_PADDING if not columns.is_empty() else frame.position.x + TEXT_PADDING
	var body_top := _header_top() + HEADER_HEIGHT
	body.position = Vector2(body_x, body_top)
	body.size = Vector2(frame.end.x - FRAME_GAP - TEXT_PADDING - body_x, frame.end.y - FRAME_GAP - body_top)
	queue_redraw()

func _label_width() -> float:
	return ThemeDB.fallback_font.get_string_size(field_label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, PRINT_SIZE).x

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	_draw_spine()
	var frame := _frame()
	draw_rect(frame, PRINT_INK, false, 2.0)
	draw_rect(frame.grow(-FRAME_GAP), PRINT_INK, false, 1.0)
	_draw_field(frame)
	var header_top := _header_top()
	var header_bottom := header_top + HEADER_HEIGHT
	draw_line(Vector2(frame.position.x, header_top), Vector2(frame.end.x, header_top), PRINT_INK, 2.0)
	draw_line(Vector2(frame.position.x, header_bottom), Vector2(frame.end.x, header_bottom), PRINT_INK, 1.0)
	var y := header_bottom + ROW_HEIGHT
	while y < frame.end.y - FRAME_GAP:
		draw_line(Vector2(frame.position.x + FRAME_GAP, y), Vector2(frame.end.x - FRAME_GAP, y), RULE_INK, 1.0)
		y += ROW_HEIGHT
	_draw_columns(frame, header_top, header_bottom)

func _draw_field(frame: Rect2) -> void:
	var baseline := frame.position.y + FRAME_GAP + FIELD_HEIGHT - FIELD_LINE_LIFT
	var x := frame.position.x + FRAME_GAP + TEXT_PADDING
	draw_string(ThemeDB.fallback_font, Vector2(x, baseline), field_label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, PRINT_SIZE, PRINT_INK)
	var line_y := baseline + 4.0
	draw_line(Vector2(x + _label_width() + 6.0, line_y), Vector2(frame.end.x - FRAME_GAP - TEXT_PADDING, line_y), PRINT_INK, 1.0)

func _draw_columns(frame: Rect2, header_top: float, header_bottom: float) -> void:
	var baseline := header_bottom - (HEADER_HEIGHT - PRINT_SIZE) * 0.5
	for i in columns.size():
		var x := _column_x(i)
		if i > 0:
			draw_line(Vector2(x, header_top), Vector2(x, frame.end.y - FRAME_GAP), PRINT_INK, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(x + TEXT_PADDING, baseline), columns[i].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, PRINT_SIZE, PRINT_INK)

# Sombra del lomo: se oscurece hacia el centro del libro abierto.
func _draw_spine() -> void:
	var step_width := SPINE_WIDTH / SPINE_STEPS
	for i in SPINE_STEPS:
		var alpha := SPINE_SHADOW.a * (1.0 - float(i) / SPINE_STEPS)
		var x := i * step_width if spine_on_left else size.x - (i + 1) * step_width
		draw_rect(Rect2(x, 0.0, step_width, size.y), Color(SPINE_SHADOW, alpha))
