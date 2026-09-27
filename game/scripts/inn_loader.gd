class_name InnLoader
extends TopDownLoader
# Construye el interior de la posada a partir de levels/inn.txt. La imagen del
# cuarto (piso, paredes, ventanas) la arma tools/gen_town_assets.py leyendo el
# mismo mapa, así las paredes que se ven y las que bloquean son las mismas.
#
# Leyenda: '#' borde, 'W' pared, 'v' ventana, '.' piso, 'D' umbral de la
# puerta, 'B' cama, 'M' valija, 't' mesa, 'o' olla, 'P' donde aparece el
# jugador, y los NPCs de data/town_npcs.gd.

const ROOM_TEXTURE := preload("res://assets/town/inn_room.png")
const BED_TEXTURE := preload("res://assets/town/inn_bed.png")
const TRUNK_TEXTURE := preload("res://assets/town/inn_trunk.png")
const TABLE_TEXTURE := preload("res://assets/town/inn_table.png")
const POT_TEXTURE := preload("res://assets/town/inn_pot.png")

const WALLS := ['#', 'W', 'v']

# Pies y huella de cada mueble, en px de textura. La cama y la valija miden dos
# celdas de ancho: sus pies van a un cuarto del ancho para que arranquen en el
# borde izquierdo de su celda.
const BED_FEET := Vector2(8, 64)
const BED_BODY := Vector2(32, 56)
const TRUNK_FEET := Vector2(8, 16)
const TRUNK_BODY := Vector2(30, 12)
const TABLE_FEET := Vector2(24, 40)
const TABLE_BODY := Vector2(34, 16)
const POT_FRAME := Vector2i(32, 32)
const POT_FEET := Vector2(16, 30)
const POT_BODY := Vector2(24, 12)
const POT_FPS := 6.0

func _build_ground() -> void:
	var room := Sprite2D.new()
	room.name = "Room"
	room.texture = ROOM_TEXTURE
	room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room.centered = false
	room.scale = Vector2(TILE_SCALE, TILE_SCALE)
	add_child(room)
	for row in _rows.size():
		_add_wall_runs(row)

func _place(ch: String, col: int, row: int) -> void:
	var feet := _feet(col, row)
	match ch:
		'B':
			_add_furniture(BED_TEXTURE, feet, BED_FEET, BED_BODY)
		'M':
			_add_furniture(TRUNK_TEXTURE, feet, TRUNK_FEET, TRUNK_BODY)
		't':
			_add_furniture(TABLE_TEXTURE, feet, TABLE_FEET, TABLE_BODY)
		'o':
			_add_pot(feet)

# Un bloqueo por tramo seguido de pared, no uno por celda.
func _add_wall_runs(row: int) -> void:
	var col := 0
	while col < _rows[row].length():
		if not WALLS.has(_cell(col, row)):
			col += 1
			continue
		var start := col
		while WALLS.has(_cell(col, row)):
			col += 1
		var width := (col - start) * CELL
		_add_blocker(Vector2(start * CELL + width * 0.5, (row + 1) * CELL), Vector2(width, CELL))

# La huella se centra en el sprite, no en la celda: la cama y la valija son
# más anchas que una celda.
func _add_furniture(texture: Texture2D, base: Vector2, feet: Vector2, body: Vector2) -> Sprite2D:
	var sprite := _add_prop(texture, base, feet)
	var center_x := (texture.get_width() * 0.5 - feet.x) * TILE_SCALE
	_add_blocker(base + Vector2(center_x, 0), body * TILE_SCALE)
	return sprite

func _add_pot(base: Vector2) -> void:
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", POT_FPS)
	for i in POT_TEXTURE.get_width() / POT_FRAME.x:
		var frame := AtlasTexture.new()
		frame.atlas = POT_TEXTURE
		frame.region = Rect2(Vector2(i * POT_FRAME.x, 0), Vector2(POT_FRAME))
		frames.add_frame(&"default", frame)
	var pot := AnimatedSprite2D.new()
	pot.sprite_frames = frames
	pot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pot.centered = false
	pot.offset = -POT_FEET
	pot.scale = Vector2(TILE_SCALE, TILE_SCALE)
	pot.position = base
	pot.add_to_group(&"inn_pot")
	objects.add_child(pot)
	pot.play()
	_add_blocker(base, POT_BODY * TILE_SCALE)
