class_name MemoryDef
extends Resource
# Una habilidad del protagonista: una entrada de MemoryData (data/memories.tres).
# Qué significa cada `Kind` y `fades_at` está explicado en MemoryData.
#
# Godot no escribe en el .tres lo que coincide con el default: cambiar un
# default acá cambia todas las entradas que lo usan.

@export var id := ""
@export var kind: MemoryData.Kind = MemoryData.Kind.INNATE
@export var icon: Texture2D
@export_range(-1.0, 1.0) var fades_at := 0.0

# Solo lo que tiene objeto en el Nivel 1: `pickup_char` es el dígito del mapa
# ASCII que lo ubica ("" si no aparece en el mapa).
@export_group("Objeto en el mapa")
@export var pickup_char := ""
@export var pickup_icon_scale := 1.0
@export_multiline var pickup_message := ""

func has_pickup() -> bool:
	return pickup_char != ""
