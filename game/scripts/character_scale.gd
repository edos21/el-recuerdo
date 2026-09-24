class_name CharacterScale
# Un solo numero decide el tamano de los personajes de plataformas: el sprite,
# el alto de sus cuerpos y el alcance de la espada salen de aca, asi cambiar
# el tamano no deja colisiones ni golpes de otra escala.
#
# Los anchos de los cuerpos no escalan a proposito: el espaciado horizontal
# y los alcances del guardian estan balanceados con ellos.

const PLATFORMER := 2.0
# Los pies de todo cuerpo quedan a esta altura de su origen (la usa el loader
# para apoyarlos sobre el piso).
const FEET_Y := 20.0
# Los frames (50x37, rvros y derivados) apoyan los pies en su borde de abajo.
const FRAME_HALF_HEIGHT := 18.5

static func place_sprite(sprite: Node2D, scale: float) -> void:
	sprite.scale = Vector2(scale, scale)
	sprite.position.y = FEET_Y - FRAME_HALF_HEIGHT * scale

# Alto medido en texels del frame, parado sobre los mismos pies.
static func fit_height(shape: CollisionShape2D, texels: float, scale: float) -> void:
	var rect := shape.shape as RectangleShape2D
	rect.size.y = texels * scale
	shape.position.y = FEET_Y - rect.size.y * 0.5

# Un rectangulo medido en texels respecto del centro del frame, llevado al
# espacio del cuerpo (mirando a la derecha).
static func frame_rect(texels: Rect2, scale: float) -> Rect2:
	var origin_y := FEET_Y - FRAME_HALF_HEIGHT * scale
	return Rect2(texels.position * scale + Vector2(0.0, origin_y), texels.size * scale)
