class_name MemoryDef
extends Resource
# Una habilidad del protagonista: una entrada de MemoryData (data/memories.tres).
# Qué significa cada `Kind` y `fades_at` está explicado en MemoryData.
#
# Los valores por defecto son neutros a propósito: así el .tres guarda cada
# número de balance de forma explícita, y una entrada a medio cargar falla en
# la validación del catálogo en vez de heredar un valor que nadie eligió.

@export var id := ""
@export var kind: MemoryData.Kind = MemoryData.Kind.INNATE
@export var icon: Texture2D
# Ratio de Estabilidad en el que la expulsión apaga el recuerdo.
@export_range(-1.0, 1.0) var fades_at := 0.0

# Solo lo que tiene objeto en el Nivel 1: `pickup_char` es el dígito del mapa
# ASCII que lo ubica ("" si no aparece en el mapa).
@export_group("Objeto en el mapa")
@export var pickup_char := ""
@export var pickup_icon_scale := 1.0
@export_multiline var pickup_message := ""

func has_pickup() -> bool:
	return pickup_char != ""
