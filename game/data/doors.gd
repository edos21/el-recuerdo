class_name DoorData
extends RefCounted
# Puertas entre escenas: cada id une el lado de afuera (el pueblo) con el de
# adentro (un interior). Cruzar una guarda el id en GameState.arrival_door y la
# escena de destino hace aparecer al jugador en la puerta con el mismo id.

const POSADA := &"posada"

# Escena a la que lleva cada puerta desde afuera y desde adentro.
const INSIDE := {POSADA: "res://scenes/Inn.tscn"}
const OUTSIDE := {POSADA: "res://scenes/Town.tscn"}
