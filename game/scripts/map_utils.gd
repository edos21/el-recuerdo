class_name MapUtils
extends RefCounted
# Utilidades compartidas por los cargadores de mapas ASCII (level_loader y
# town_loader): leer la grilla y armar formas de colision rectangulares.

static func read_grid(path: String) -> Array:
	var rows: Array = []
	# Un mapa guardado con CRLF no debe dejar '\r' como una columna mas de cada fila.
	for line in FileAccess.get_file_as_string(path).replace("\r", "").split("\n"):
		rows.append(line)
	if not rows.is_empty() and rows.back() == "":
		rows.pop_back()
	return rows

# Numero estable por celda para variar decoracion sin azar entre corridas.
static func cell_hash(col: int, row: int) -> int:
	return absi((col * 73856093) ^ (row * 19349663))

static func rect_shape(size: Vector2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	return shape
