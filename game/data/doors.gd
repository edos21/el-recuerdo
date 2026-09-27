class_name DoorData
extends RefCounted
# Puertas entre escenas: cada id une el lado de afuera (el pueblo) con el de
# adentro (un interior). Cruzar una guarda el id en GameState.arrival_door y la
# escena de destino hace aparecer al jugador en la puerta con el mismo id.

const POSADA := &"posada"

const SCENES := {
	POSADA: {"outside": "res://scenes/Town.tscn", "inside": "res://scenes/Inn.tscn"},
}
