class_name Facing
extends RefCounted
# Direccion de un personaje cenital (animaciones walk_/idle_ + down/left/right/up),
# compartida por el jugador y los NPCs para que miren igual.

# En diagonal gana el eje mas marcado; en empate, el horizontal.
static func from_direction(direction: Vector2) -> String:
	if absf(direction.x) >= absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y > 0.0 else "up"
