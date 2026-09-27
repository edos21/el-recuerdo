class_name InteriorLoader
extends TopDownLoader
# Construye un interior (un cuarto) a partir de su mapa ASCII. La imagen del
# cuarto (piso, paredes, ventanas) la arma tools/gen_town_assets.py leyendo el
# mismo mapa, así las paredes que se ven y las que bloquean son las mismas. Qué
# cuarto es y adónde da su puerta son datos de la escena (@export).
#
# Leyenda: '#' borde, 'W' pared, 'v' ventana, '.' piso, 'D' umbral de la
# puerta, los muebles de FURNITURE, 'o' olla, 'P' donde aparece el jugador, y
# los NPCs de data/town_npcs.gd.

@export var room_texture: Texture2D
# Puerta de DoorData por la que se sale al pueblo.
@export var door_id: StringName

const POT_TEXTURE := preload("res://assets/town/inn_pot.png")
const WALLS := ['#', 'W', 'v']
const DOORS := ['D']

# Muebles del kit, por carácter: textura, pies y huella en px de textura. La
# cama y la valija miden dos celdas de ancho: sus pies van a un cuarto del
# ancho para que arranquen en el borde izquierdo de su celda.
const FURNITURE := {
	'B': {"texture": preload("res://assets/town/inn_bed.png"), "feet": Vector2(8, 64), "body": Vector2(32, 56)},
	'M': {"texture": preload("res://assets/town/inn_trunk.png"), "feet": Vector2(8, 16), "body": Vector2(30, 12)},
	't': {"texture": preload("res://assets/town/inn_table.png"), "feet": Vector2(24, 40), "body": Vector2(34, 16)},
}
const POT_FRAME := Vector2i(32, 32)
const POT_FEET := Vector2(16, 30)
const POT_BODY := Vector2(24, 12)
const POT_FPS := 6.0

# El umbral se dispara en la mitad de abajo de la fila 'D': quien entra aparece
# una celda más arriba, ya adentro.
const DOOR_TRIGGER_DEPTH := 16.0
const DOOR_ARRIVAL_LIFT := 4.0

func _build_ground() -> void:
	var room := Sprite2D.new()
	room.name = "Room"
	room.texture = room_texture
	room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room.centered = false
	room.scale = Vector2(TILE_SCALE, TILE_SCALE)
	add_child(room)
	for row in _rows.size():
		for run in _runs(row, WALLS):
			_add_wall(Rect2(run.x * CELL, row * CELL, (run.y - run.x) * CELL, CELL))
		for run in _runs(row, DOORS):
			_add_room_door(row, run)

func _place(ch: String, col: int, row: int) -> void:
	if FURNITURE.has(ch):
		_add_furniture(FURNITURE[ch], _feet(col, row))
	elif ch == 'o':
		_add_pot(_feet(col, row))

func _add_room_door(row: int, run: Vector2i) -> void:
	var left := run.x * CELL
	var width := (run.y - run.x) * CELL
	var bottom := (row + 1) * CELL
	var trigger := Rect2(left, bottom - DOOR_TRIGGER_DEPTH, width, DOOR_TRIGGER_DEPTH)
	var arrival := Vector2(left + width * 0.5, row * CELL - DOOR_ARRIVAL_LIFT)
	_add_door(door_id, DoorData.OUTSIDE[door_id], trigger, arrival)

# La huella se centra en el sprite, no en la celda: la cama y la valija son
# más anchas que una celda.
func _add_furniture(furniture: Dictionary, base: Vector2) -> void:
	var texture: Texture2D = furniture.texture
	_add_prop(texture, base, furniture.feet)
	var center_x: float = (texture.get_width() * 0.5 - furniture.feet.x) * TILE_SCALE
	_add_blocker(base + Vector2(center_x, 0), furniture.body * TILE_SCALE)

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
