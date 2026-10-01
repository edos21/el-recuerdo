class_name StageMap
extends RefCounted
# Las tres versiones (días) de la ferretería del recuerdo de Tomás, leídas de
# sus mapas ASCII. Los tres mapas miden lo mismo y cada columna es el mismo
# lugar en los tres días: el personaje conserva su posición al cambiar de día,
# así que el puzzle es de espacio. Cada mapa tiene dos filas: la pared del fondo
# (decoración) y el piso que se camina (lo que bloquea, se recoge o habla).
#
# Leyenda, fila de la pared: '.' nada, 'E' estante lleno, 'e' estante vacío,
# 'v' ventana, 'M' mostrador, 'd' puerta del fondo.
# Leyenda, fila del piso: '.' libre, 'C' caja y 'R' reja (bloquean), 'b' la
# bisagra, 'l' el cuaderno, 'V' el vecino, 'T' Tomás, 'g' un bolso armado (solo
# en Ayer; no bloquea), 'S' dónde aparece el jugador (solo en Hoy).

enum Day { ANTES, HOY, AYER }

const DAY_COUNT := 3
const CELL := 32
const COLS := 40
const WALL_ROW := 0
const FLOOR_ROW := 1
const PATHS := {
	Day.ANTES: "res://levels/ferreteria_antes.txt",
	Day.HOY: "res://levels/ferreteria_hoy.txt",
	Day.AYER: "res://levels/ferreteria_ayer.txt",
}
const BLOCKERS := ['C', 'R']
const SPAWN := 'S'
const SPAWN_DAY := Day.HOY
# A cuántas columnas de distancia se alcanza algo para usarlo.
const REACH := 2

var _rows: Dictionary = {}

func _init() -> void:
	for day in PATHS:
		_rows[day] = MapUtils.read_grid(PATHS[day])

static func col_of(x: float) -> int:
	return floori(x / CELL)

static func center_x(col: int) -> float:
	return (col + 0.5) * CELL

func row_text(day: Day, row: int) -> String:
	return _rows[day][row]

func width_of(day: Day) -> int:
	return row_text(day, WALL_ROW).length()

func char_at(day: Day, row: int, col: int) -> String:
	var text := row_text(day, row)
	return text[col] if col >= 0 and col < text.length() else ""

func is_blocked(day: Day, col: int) -> bool:
	return BLOCKERS.has(char_at(day, FLOOR_ROW, col))

# Columnas de un carácter del piso (la bisagra, el vecino): casi siempre una.
func columns_of(day: Day, ch: String, row: int = FLOOR_ROW) -> Array[int]:
	var found: Array[int] = []
	var text := row_text(day, row)
	for col in text.length():
		if text[col] == ch:
			found.append(col)
	return found

func first_column(day: Day, ch: String) -> int:
	var found := columns_of(day, ch)
	return found[0] if not found.is_empty() else -1

# Tramos contiguos [desde, hasta) de columnas de un mismo carácter: así una
# caja de dos celdas se dibuja y colisiona como una sola.
func runs_of(day: Day, row: int, chars: Array) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var text := row_text(day, row)
	var start := -1
	var kind := ""
	for col in text.length() + 1:
		var ch := text[col] if col < text.length() else ""
		if start >= 0 and ch != kind:
			runs.append(Vector2i(start, col))
			start = -1
		if start < 0 and chars.has(ch):
			start = col
			kind = ch
	return runs

func blocker_runs(day: Day) -> Array[Vector2i]:
	return runs_of(day, FLOOR_ROW, BLOCKERS)

# Si un cuerpo de medio ancho `half_width` parado en `x` cabe en ese día: es lo
# que permite o niega cambiar de llave. Se mira el ancho real y no solo la
# celda del centro, para no acabar dentro de una caja que el otro día no tiene.
func fits(day: Day, x: float, half_width: float) -> bool:
	for col in range(col_of(x - half_width), col_of(x + half_width) + 1):
		if is_blocked(day, col):
			return false
	return true

static func within_reach(col: int, other: int) -> bool:
	return absi(col - other) <= REACH
