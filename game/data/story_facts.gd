class_name StoryFacts
extends RefCounted
# Cosas que el protagonista supo por boca de alguien sin que cambiaran nada en el
# mundo (a diferencia de un beat, que mueve la Estabilidad). Sirven para que el
# cuaderno anote un encargo desde que se lo piden. GameState valida contra ALL:
# un typo se detecta al usarlo en vez de dejar un encargo sin anotar para siempre.

const TOMAS_TOLD_KEYS := &"tomas_told_keys"
const WATER_ASKED := &"water_asked"
const MARTA_ASKED := &"marta_asked"

const ALL: Array[StringName] = [TOMAS_TOLD_KEYS, WATER_ASKED, MARTA_ASKED]
