class_name TownNpcData
extends RefCounted
# Personajes del pueblo real, por caracter del mapa (levels/town.txt).
# Los textos son de prueba: todavia falta la sesion de escritura de los NPCs
# (historia_lore.md sec. 15).
#
# `attitude`, `barks` e `idle_emotes` le dan a cada uno una forma de estar en
# el mundo que acompana lo que dice: Marta es la que te encontro y se preocupa;
# Tomas es el que prefiere no mirar lo que pasa en el pueblo.
#
# Con `wander_radius` 0 no pasea (sentado, detras de un mostrador). Opcionales:
# `facing` (hacia donde mira al aparecer), `dialogue` (lo que dice segun el
# estado, en Dialogues) y `present_if` (cuando esta: GameState.is_met; Marta
# junto a la cama solo mientras el despertar no se mostro).

const MARTA_NAME := "Marta"
const TOMAS_NAME := "Tomás"
const POSADERA_NAME := "Posadera"
const MARTA_FRAMES := "res://assets/characters/topdown_npc_a_frames.tres"

const LIST := {
	"n": {
		"name": MARTA_NAME,
		"dialogue": &"marta",
		"frames": MARTA_FRAMES,
		"lines": [
			"¡Ey! ¿Ya tomaste aire? No te exijas, que te acabas de levantar.",
			"Tranquilo, respira. A veces pasa: alguien se pierde en un recuerdo y le cuesta volver.",
		],
		"attitude": Npc.Attitude.CURIOUS,
		"wander_radius": 40.0,
		"walk_speed": 38.0,
		"barks": ["¿Ya estás mejor?", "¡Ahí estás!", "No te alejes mucho, ¿eh?"],
		"idle_emotes": ["?"],
	},
	# Marta junto a la cama de la posada, la primera vez que despierta.
	"a": {
		"name": MARTA_NAME,
		"dialogue": &"marta",
		"frames": MARTA_FRAMES,
		"lines": [
			"Tranquilo, aquí estás a salvo. Tómate tu tiempo.",
		],
		"attitude": Npc.Attitude.CURIOUS,
		"wander_radius": 0.0,
		"walk_speed": 0.0,
		"barks": ["Despacio.", "Estoy aquí."],
		"idle_emotes": [],
		"facing": "down",
		"present_if": {"wake_pending": true},
	},
	"p": {
		"name": POSADERA_NAME,
		"dialogue": &"posadera",
		"frames": "res://assets/characters/topdown_innkeeper_frames.tres",
		"lines": [
			"Ah, te levantaste. Marta no se movió de tu lado en toda la noche.",
			"Si necesitas algo, estoy aquí. La cama es tuya mientras te haga falta.",
		],
		"attitude": Npc.Attitude.CURIOUS,
		"wander_radius": 0.0,
		"walk_speed": 0.0,
		"barks": ["Buenas.", "¿Dormiste algo?"],
		"idle_emotes": ["..."],
		"facing": "down",
	},
	"N": {
		"name": TOMAS_NAME,
		"dialogue": &"tomas",
		"frames": "res://assets/characters/topdown_npc_b_frames.tres",
		"lines": [
			"El pueblo anda raro estos días. Todos olvidan cosas pequeñas: dónde dejaron las llaves, cómo se llamaba alguien.",
			"Yo ya no pregunto. Es más fácil hacer como que no pasa.",
		],
		"attitude": Npc.Attitude.EVASIVE,
		"wander_radius": 90.0,
		"walk_speed": 30.0,
		"barks": ["Mm.", "Buen día... creo.", "¿Dónde dejé...?"],
		"idle_emotes": ["?", "..."],
	},
}
