class_name TownNpcData
extends RefCounted
# Personajes del pueblo real, por caracter del mapa (levels/town.txt).
# Los textos son de prueba: todavia falta la sesion de escritura de los NPCs
# (historia_lore.md sec. 15).
#
# `attitude`, `barks` e `idle_emotes` le dan a cada uno una forma de estar en
# el mundo que acompana lo que dice: Marta es la que te encontro y se preocupa;
# Tomas es el que prefiere no mirar lo que pasa en el pueblo.

const LIST := {
	"n": {
		"name": "Marta",
		"frames": "res://assets/characters/topdown_npc_a_frames.tres",
		"lines": [
			"¡Ey! Menos mal. Te vi caer en plena plaza y no reaccionabas.",
			"Tranquilo, respirá. A veces pasa: alguien se pierde en un recuerdo y le cuesta volver.",
		],
		"attitude": Npc.Attitude.CURIOUS,
		"wander_radius": 40.0,
		"walk_speed": 38.0,
		"barks": ["¿Ya estás mejor?", "¡Ahí estás!", "No te alejes mucho, ¿eh?"],
		"idle_emotes": ["?"],
	},
	"N": {
		"name": "Tomás",
		"frames": "res://assets/characters/topdown_npc_b_frames.tres",
		"lines": [
			"El pueblo anda raro estos días. Todos olvidan cosas chicas: dónde dejaron las llaves, cómo se llamaba alguien.",
			"Yo ya no pregunto. Es más fácil hacer como que no pasa.",
		],
		"attitude": Npc.Attitude.EVASIVE,
		"wander_radius": 90.0,
		"walk_speed": 30.0,
		"barks": ["Mm.", "Buen día... creo.", "¿Dónde dejé...?"],
		"idle_emotes": ["?", "..."],
	},
}
