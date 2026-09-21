class_name TownNpcData
extends RefCounted
# Personajes del pueblo real, por caracter del mapa (levels/town.txt).
# Los textos son de prueba: todavia falta la sesion de escritura de los NPCs
# (historia_lore.md sec. 15).

const LIST := {
	"n": {
		"name": "Marta",
		"frames": "res://assets/characters/topdown_npc_a_frames.tres",
		"lines": [
			"¡Ey! Menos mal. Te vi caer en plena plaza y no reaccionabas.",
			"Tranquilo, respirá. A veces pasa: alguien se pierde en un recuerdo y le cuesta volver.",
		],
	},
	"N": {
		"name": "Tomás",
		"frames": "res://assets/characters/topdown_npc_b_frames.tres",
		"lines": [
			"El pueblo anda raro estos días. Todos olvidan cosas chicas: dónde dejaron las llaves, cómo se llamaba alguien.",
			"Yo ya no pregunto. Es más fácil hacer como que no pasa.",
		],
	},
}
