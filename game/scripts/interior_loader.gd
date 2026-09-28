class_name InteriorLoader
extends TopDownLoader
# Construye un interior (un cuarto) a partir de su mapa ASCII. La imagen del
# cuarto (piso, paredes, ventanas, escalera) la arma tools/gen_town_assets.py
# leyendo el mismo mapa, así las paredes que se ven y las que bloquean son las
# mismas. Qué cuarto es y adónde da cada puerta son datos de la escena (@export).
#
# Leyenda: '#' borde, 'W' pared, 'v' ventana, 'c' cuadro, '.' piso, 'D' puerta
# en la pared de abajo (se sale hacia abajo), 'U' tope de una escalera (se sube),
# 'S' escalones, 'r' baranda, los muebles de FURNITURE, 'P' donde aparece el
# jugador, y los NPCs de data/town_npcs.gd.

@export var room_texture: Texture2D
# Qué puerta de DoorData es cada carácter de puerta del mapa ('D', 'U').
@export var doors: Dictionary[String, StringName] = {}

const WALLS := ['#', 'W', 'v', 'c', 'r']
const STEP := 'S'
const EXIT_DOWN := 'D'
const EXIT_UP := 'U'
# Lo lee la atmósfera: cada llama (vela, fuego) es una luz del cuarto. El meta
# FLAME_META es dónde está la llama dentro del cuadro, en px de textura.
const FLAMES_GROUP := &"interior_flames"
const FLAME_META := &"flame"
const CANDLE_TEXTURE := preload("res://assets/town/inn_candle.png")
const CANDLE_FRAMES := 4
const CANDLE_FLAME := Vector2(8, 4)
const FLAME_FPS := 8.0

# Muebles del kit, por carácter: textura, pies y huella en px de textura;
# opcionales: cuadros de animación ("frames", la textura es una tira), dónde
# está su llama ("flame") y dónde va una vela encendida encima ("candle_at",
# esquina de arriba a la izquierda). Los pies van a un cuarto del ancho de una
# celda para que el mueble arranque en el borde izquierdo de su celda.
const FURNITURE := {
	'B': {"texture": preload("res://assets/town/inn_bed.png"), "feet": Vector2(8, 64), "body": Vector2(32, 56)},
	'M': {"texture": preload("res://assets/town/inn_trunk.png"), "feet": Vector2(8, 16), "body": Vector2(30, 12)},
	'd': {"texture": preload("res://assets/town/inn_desk.png"), "feet": Vector2(8, 40), "body": Vector2(30, 12),
			"candle_at": Vector2(17, 1)},
	'k': {"texture": preload("res://assets/town/inn_counter.png"), "feet": Vector2(8, 32), "body": Vector2(46, 14)},
	'm': {"texture": preload("res://assets/town/inn_table_set.png"), "feet": Vector2(8, 32), "body": Vector2(60, 12)},
	'o': {"texture": preload("res://assets/town/inn_pot.png"), "feet": Vector2(8, 30), "body": Vector2(24, 12),
			"frames": 5, "flame": Vector2(16, 26)},
}

# El umbral se dispara en la mitad de la celda más lejana del cuarto: quien
# llega aparece una celda hacia adentro, ya fuera del umbral.
const DOOR_TRIGGER_DEPTH := 16.0
const DOOR_ARRIVAL_INSET := 4.0

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
		for exit in doors:
			for run in _runs(row, [exit]):
				_add_room_door(exit, row, run)

func _place(ch: String, col: int, row: int) -> void:
	if FURNITURE.has(ch):
		_add_furniture(FURNITURE[ch], _feet(col, row))

# Por la 'D' se sale bajando por el borde de abajo y se llega una celda más
# arriba; por la 'U' (una escalera) se sale subiendo y se llega al pie de sus
# escalones.
func _add_room_door(exit: String, row: int, run: Vector2i) -> void:
	var left := run.x * CELL
	var width := (run.y - run.x) * CELL
	var center_x := left + width * 0.5
	var trigger: Rect2
	var arrival: Vector2
	match exit:
		EXIT_UP:
			trigger = Rect2(left, row * CELL, width, DOOR_TRIGGER_DEPTH)
			var foot := row + 1
			while _cell(run.x, foot) == STEP:
				foot += 1
			arrival = Vector2(center_x, (foot + 1) * CELL - DOOR_ARRIVAL_INSET)
		EXIT_DOWN:
			var bottom := (row + 1) * CELL
			trigger = Rect2(left, bottom - DOOR_TRIGGER_DEPTH, width, DOOR_TRIGGER_DEPTH)
			arrival = Vector2(center_x, row * CELL - DOOR_ARRIVAL_INSET)
		_:
			push_error("InteriorLoader: '%s' no es una salida ('%s' o '%s')." % [exit, EXIT_DOWN, EXIT_UP])
			return
	_add_door(doors[exit], trigger, arrival)

# La huella se centra en el sprite, no en la celda: casi todos los muebles son
# más anchos que una celda.
func _add_furniture(furniture: Dictionary, base: Vector2) -> void:
	var texture: Texture2D = furniture.texture
	var frames: int = furniture.get("frames", 1)
	var width := texture.get_width() / frames
	var sprite: Node2D
	if frames > 1:
		sprite = _animated(texture, frames, furniture.feet)
		_place_prop(sprite, base)
	else:
		sprite = _add_prop(texture, base, furniture.feet)
	if furniture.has("flame"):
		_mark_flame(sprite, furniture.flame - furniture.feet)
	var center_x: float = (width * 0.5 - furniture.feet.x) * TILE_SCALE
	_add_blocker(base + Vector2(center_x, 0), furniture.body * TILE_SCALE)
	if furniture.has("candle_at"):
		_add_candle(sprite, furniture.candle_at - furniture.feet)

# Hija del mueble, para ordenarse por Y con él (va encima, no detrás); hereda
# su escala.
func _add_candle(furniture: Node2D, at: Vector2) -> void:
	var candle := _animated(CANDLE_TEXTURE, CANDLE_FRAMES, Vector2.ZERO)
	candle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	candle.position = at
	_mark_flame(candle, CANDLE_FLAME)
	furniture.add_child(candle)

func _mark_flame(sprite: Node2D, flame: Vector2) -> void:
	sprite.set_meta(FLAME_META, flame)
	sprite.add_to_group(FLAMES_GROUP)

# Tira de cuadros iguales en fila, con el origen en `feet` (px de textura).
func _animated(strip: Texture2D, count: int, feet: Vector2) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", FLAME_FPS)
	var size := Vector2(strip.get_width() / count, strip.get_height())
	for i in count:
		var frame := AtlasTexture.new()
		frame.atlas = strip
		frame.region = Rect2(Vector2(i * size.x, 0), size)
		frames.add_frame(&"default", frame)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = -feet
	sprite.play()
	return sprite
