class_name BeatData
extends Resource
# Momentos de guion del mundo real que mueven la Estabilidad, cada uno una sola
# vez (repetir un diálogo no recupera nada). Quién los dispara es del guion (un
# NPC, un objeto); cuánto y de qué tipo vive acá, editable en el inspector.
#
# `kind` sigue la regla de guion del hub:
# - RELIEF (alivio): hacer algo por otro. Sube la Estabilidad actual, hasta el tope.
# - MATURITY (madurar): dejar que te ayuden o que te vean. Sube el tope, hasta
#   el máximo original (rellena el fantasma), y la actual en lo mismo.

enum Kind { RELIEF, MATURITY }

# Ids de los beats que el guion nombra desde código (Dialogues, present_if):
# tienen que existir en data/beats.tres, y GameState avisa si no.
const TOMAS_KEYS := "tomas_keys"
const INN_WATER := "inn_water"
const BROTH := "broth"
const DONT_KNOW := "dont_know_who_i_am"
const GUEST_BOOK := "guest_book"

@export var entries: Array[BeatDef] = []

var _by_id: Dictionary[String, BeatDef] = {}

func entry(beat_id: String) -> BeatDef:
	return _by_id.get(beat_id)

# Lo llama Catalogs al arrancar. Un beat que no mueve nada es un dato a medio
# cargar: se avisa acá en vez de dejar un momento de guion sin efecto.
func index() -> void:
	_by_id.clear()
	for beat in entries:
		if beat.id == "" or _by_id.has(beat.id):
			push_error("BeatData: id vacío o repetido ('%s')." % beat.id)
			continue
		if beat.amount <= 0.0:
			push_error("BeatData: '%s' necesita una cantidad positiva." % beat.id)
		_by_id[beat.id] = beat
