class_name StageView
extends Node2D
# Dibujo provisorio (cajas grises con etiqueta) de la ferretería en cada día:
# sirve para probar si el puzzle es divertido antes de invertir en arte. Lee el
# mismo StageMap que la lógica, así lo que se ve y lo que bloquea no se separan.

const WALL_TOP := 96.0
const WALL_BOTTOM := 496.0
const FLOOR_BOTTOM := 720.0
const SHELF_TOP := 190.0
const SHELF_HEIGHT := 200.0
const WINDOW_TOP := 150.0
const WINDOW_HEIGHT := 150.0
const COUNTER_TOP := 400.0
const DOOR_TOP := 230.0
const CRATE_HEIGHT := 64.0
const GATE_HEIGHT := 120.0
const GATE_BAR_WIDTH := 4.0
const GATE_BARS := 4
const NPC_WIDTH := 26.0
const NPC_HEIGHT := 58.0
const SEATED_HEIGHT := 40.0
const HINGE_SIZE := Vector2(14, 10)
const BOOK_SIZE := Vector2(18, 10)
const SHELF_PLANKS := 3
const STOCK_MARGIN := 8.0
const STOCK_STEP := 22.0
const LABEL_SIZE := 14
const LABEL_OFFSET := 6.0

# Por día: fondo, pared, piso, madera de los estantes y color de la ventana.
const PALETTES := {
	StageMap.Day.ANTES: {"back": Color(0.20, 0.16, 0.12), "wall": Color(0.62, 0.50, 0.36), "floor": Color(0.42, 0.32, 0.22),
			"wood": Color(0.48, 0.34, 0.20), "window": Color(1.0, 0.92, 0.65)},
	StageMap.Day.HOY: {"back": Color(0.16, 0.16, 0.17), "wall": Color(0.50, 0.49, 0.47), "floor": Color(0.34, 0.33, 0.32),
			"wood": Color(0.38, 0.30, 0.22), "window": Color(0.78, 0.82, 0.86)},
	StageMap.Day.AYER: {"back": Color(0.07, 0.08, 0.11), "wall": Color(0.26, 0.30, 0.38), "floor": Color(0.17, 0.19, 0.24),
			"wood": Color(0.20, 0.22, 0.28), "window": Color(0.12, 0.14, 0.22)},
}
const CRATE_COLOR := Color(0.55, 0.42, 0.25)
const GATE_COLOR := Color(0.14, 0.14, 0.16)
const COUNTER_COLOR := Color(0.30, 0.22, 0.15)
const DOOR_COLOR := Color(0.22, 0.17, 0.12)
const STOCK_COLORS: Array[Color] = [Color(0.85, 0.55, 0.25), Color(0.55, 0.65, 0.80), Color(0.75, 0.75, 0.40), Color(0.70, 0.45, 0.55)]
const HINGE_COLOR := Color(0.95, 0.80, 0.25)
const BOOK_COLOR := Color(0.92, 0.90, 0.82)
const NEIGHBOR_COLOR := Color(0.45, 0.62, 0.50)
const TOMAS_COLOR := Color(0.70, 0.50, 0.45)
const BAG_COLOR := Color(0.35, 0.40, 0.30)
const BAG_SIZE := Vector2(34, 26)
const BAG_STRAP := 10.0
const LABEL_COLOR := Color(1, 1, 1, 0.85)

var map: StageMap
var day := StageMap.Day.HOY
# La bisagra está a la vista solo mientras nadie la lleva ni la entregó.
var hinge_visible := true

func show_state(new_day: StageMap.Day, hinge_shown: bool) -> void:
	day = new_day
	hinge_visible = hinge_shown
	queue_redraw()

func _draw() -> void:
	var palette: Dictionary = PALETTES[day]
	var width := map.width_of(day) * StageMap.CELL
	draw_rect(Rect2(0, 0, width, FLOOR_BOTTOM), palette.back)
	draw_rect(Rect2(0, WALL_TOP, width, WALL_BOTTOM - WALL_TOP), palette.wall)
	draw_rect(Rect2(0, WALL_BOTTOM, width, FLOOR_BOTTOM - WALL_BOTTOM), palette.floor)
	_draw_wall(palette)
	_draw_floor()

func _draw_wall(palette: Dictionary) -> void:
	for run in map.runs_of(day, StageMap.WALL_ROW, ['E', 'e']):
		_draw_shelf(run, map.char_at(day, StageMap.WALL_ROW, run.x) == 'E', palette.wood)
	for run in map.runs_of(day, StageMap.WALL_ROW, ['v']):
		draw_rect(_span(run, WINDOW_TOP, WINDOW_HEIGHT), palette.window)
	for run in map.runs_of(day, StageMap.WALL_ROW, ['M']):
		var counter := _span(run, COUNTER_TOP, WALL_BOTTOM - COUNTER_TOP)
		draw_rect(counter, COUNTER_COLOR)
		_label("mostrador", counter.position + Vector2(counter.size.x * 0.5, counter.size.y * 0.5))
	for run in map.runs_of(day, StageMap.WALL_ROW, ['d']):
		var door := _span(run, DOOR_TOP, WALL_BOTTOM - DOOR_TOP)
		draw_rect(door, DOOR_COLOR)
		_label("puerta del fondo", door.position + Vector2(door.size.x * 0.5, door.size.y * 0.5))
	if hinge_visible and day == StageMap.Day.ANTES:
		_draw_hinge()

func _draw_shelf(run: Vector2i, stocked: bool, wood: Color) -> void:
	var shelf := _span(run, SHELF_TOP, SHELF_HEIGHT)
	draw_rect(shelf, wood, false, 3.0)
	for plank in SHELF_PLANKS:
		var y := shelf.position.y + shelf.size.y * (plank + 1) / (SHELF_PLANKS + 1)
		draw_line(Vector2(shelf.position.x, y), Vector2(shelf.end.x, y), wood, 3.0)
		if not stocked:
			continue
		for i in int((shelf.size.x - STOCK_MARGIN * 2) / STOCK_STEP):
			var color := STOCK_COLORS[(i + plank) % STOCK_COLORS.size()]
			draw_rect(Rect2(shelf.position.x + STOCK_MARGIN + i * STOCK_STEP, y - 22, 16, 18), color)
	_label("estante" if stocked else "estante vacío", shelf.position + Vector2(shelf.size.x * 0.5, -LABEL_OFFSET))

func _draw_hinge() -> void:
	for col in map.columns_of(StageMap.Day.ANTES, 'b'):
		var at := Vector2(StageMap.center_x(col), SHELF_TOP + SHELF_HEIGHT * 0.5)
		draw_rect(Rect2(at - HINGE_SIZE * 0.5, HINGE_SIZE), HINGE_COLOR)
		_label("bisagra", at + Vector2(0, -LABEL_OFFSET * 2))

func _draw_floor() -> void:
	var feet := Ferreteria.FEET_Y
	for run in map.runs_of(day, StageMap.FLOOR_ROW, ['C']):
		var crate := _span(run, feet - CRATE_HEIGHT, CRATE_HEIGHT)
		draw_rect(crate, CRATE_COLOR)
		_label("caja", crate.position + Vector2(crate.size.x * 0.5, crate.size.y * 0.5))
	for run in map.runs_of(day, StageMap.FLOOR_ROW, ['R']):
		var gate := _span(run, feet - GATE_HEIGHT, GATE_HEIGHT)
		draw_rect(gate, GATE_COLOR, false, GATE_BAR_WIDTH)
		for bar in GATE_BARS:
			var x := gate.position.x + gate.size.x * (bar + 1) / (GATE_BARS + 1)
			draw_line(Vector2(x, gate.position.y), Vector2(x, gate.end.y), GATE_COLOR, GATE_BAR_WIDTH)
		_label("reja", gate.position + Vector2(gate.size.x * 0.5, -LABEL_OFFSET))
	for col in map.columns_of(day, 'l'):
		var at := Vector2(StageMap.center_x(col), COUNTER_TOP)
		draw_rect(Rect2(at - BOOK_SIZE * 0.5 - Vector2(0, BOOK_SIZE.y), BOOK_SIZE), BOOK_COLOR)
		_label("cuaderno", at + Vector2(0, -BOOK_SIZE.y - LABEL_OFFSET * 2))
	for col in map.columns_of(day, 'g'):
		_draw_bag(StageMap.center_x(col))
	_draw_person('V', NPC_HEIGHT, NEIGHBOR_COLOR, "vecino")
	_draw_person('T', SEATED_HEIGHT, TOMAS_COLOR, "Tomás")

# Armado y listo junto a Tomás: dice que está listo para irse sin decirlo.
func _draw_bag(center_x: float) -> void:
	var bag := Rect2(center_x - BAG_SIZE.x * 0.5, Ferreteria.FEET_Y - BAG_SIZE.y, BAG_SIZE.x, BAG_SIZE.y)
	draw_rect(bag, BAG_COLOR)
	draw_line(bag.position + Vector2(BAG_STRAP, 0), bag.position + Vector2(BAG_STRAP, -BAG_STRAP), BAG_COLOR, 3.0)
	draw_line(bag.position + Vector2(bag.size.x - BAG_STRAP, 0), bag.position + Vector2(bag.size.x - BAG_STRAP, -BAG_STRAP), BAG_COLOR, 3.0)
	draw_line(bag.position + Vector2(BAG_STRAP, -BAG_STRAP), bag.position + Vector2(bag.size.x - BAG_STRAP, -BAG_STRAP), BAG_COLOR, 3.0)
	_label("bolso", bag.position + Vector2(bag.size.x * 0.5, -BAG_STRAP - LABEL_OFFSET))

func _draw_person(ch: String, height: float, color: Color, name_text: String) -> void:
	for col in map.columns_of(day, ch):
		var body := Rect2(StageMap.center_x(col) - NPC_WIDTH * 0.5, Ferreteria.FEET_Y - height, NPC_WIDTH, height)
		draw_rect(body, color)
		_label(name_text, body.position + Vector2(body.size.x * 0.5, -LABEL_OFFSET))

func _span(run: Vector2i, top: float, height: float) -> Rect2:
	return Rect2(run.x * StageMap.CELL, top, (run.y - run.x) * StageMap.CELL, height)

func _label(text: String, center: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	draw_string(font, center + Vector2(-width * 0.5, LABEL_SIZE * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, LABEL_COLOR)
