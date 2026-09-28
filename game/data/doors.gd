class_name DoorData
extends RefCounted
# Puertas entre escenas: cada id une dos escenas. Cruzar una guarda el id en
# GameState.arrival_door y la escena del otro lado hace aparecer al jugador en
# la puerta con el mismo id. Una escena puede tener varias puertas (el salón de
# la posada da a la calle y a la escalera).

const POSADA := &"posada"                    # la calle y el salón de la posada
const POSADA_ESCALERA := &"posada_escalera"  # el salón y la habitación de arriba

const LINKS := {
	POSADA: ["res://scenes/Town.tscn", "res://scenes/InnHall.tscn"],
	POSADA_ESCALERA: ["res://scenes/InnHall.tscn", "res://scenes/InnRoom.tscn"],
}

# La escena a la que lleva la puerta `id` vista desde `from_scene`.
static func other_side(id: StringName, from_scene: String) -> String:
	var ends: Array = LINKS[id]
	if not ends.has(from_scene):
		push_error("DoorData: la puerta '%s' no sale de %s." % [id, from_scene])
		return ""
	return ends[1] if ends[0] == from_scene else ends[0]
