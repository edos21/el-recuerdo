extends RefCounted
class_name MemoryData
# Fuente única de las habilidades del protagonista. Antes esta lista estaba
# repartida entre GameState, hud.gd, player.gd y world_progression.gd: agregar
# una habilidad implicaba tocar los cinco archivos. Ahora cada habilidad es
# una sola entrada acá; level_loader.gd instancia el objeto del Nivel 1
# leyendo el carácter '1'..'5' del mapa ASCII vía `by_pickup_char` (el ASCII
# solo dice "acá va el recuerdo N", el contenido vive acá).
#
# `kind` decide cómo la trata el HUD:
# - INNATE: sin ícono ni slot (la Estabilidad se descubre por agotamiento).
# - MEMORY: slot apagado desde el inicio, cuenta en "Recuerdos X/N".
# - OPTIONAL: slot que aparece recién al ganarlo, no cuenta (el bonus del
#   camino secundario).
# - LATER: se gana fuera del Nivel 1 (en un capítulo que todavía no existe):
#   no cuenta en el Nivel 1 ni lo otorga `granted_by_default`, así que el
#   contador y debug_start_at_end no cambian por tenerlo definido.
#
# `fades_at` es el ratio de Estabilidad en el que la expulsión apaga el
# recuerdo (en orden inverso al que se ganaron); `NO_FADE` para lo que nunca
# se apaga.
#
# Las entradas son homogéneas a propósito (como EnemyData): así la tabla se
# lee como tabla y una entrada incompleta falla al cargar en vez de romper
# una habilidad en silencio.

enum Kind { INNATE, MEMORY, OPTIONAL, LATER }
const NO_FADE := -1.0

const LIST := {
	"jump": {
		"kind": Kind.MEMORY,
		"icon": "res://assets/items/rope.png",
		"fades_at": 0.0,
		"pickup": {
			"char": "1",
			"icon_scale": 2.5,
			"message": "Una cuerda de saltar, gastada por el uso. Recuerdo el sonido que hacía al golpear el suelo, una y otra vez, sin pensar. Así se sentía moverse sin dudar. Presioná Espacio para saltar. [Recuerdo del Saltador recuperado]",
		},
	},
	"sprint": {
		"kind": Kind.MEMORY,
		"icon": "res://assets/items/shoes.png",
		"fades_at": 0.25,
		"pickup": {
			"char": "2",
			"icon_scale": 2.5,
			"message": "Unos zapatos viejos, todavía atados. Me gustaba salir a correr con ellos — me sentía ágil, liviano, rápido. Como un corredor. Mantené Shift apretado mientras te movés para correr. [Recuerdo del Corredor recuperado]",
		},
	},
	"stability": {
		"kind": Kind.INNATE,
		"icon": "",
		"fades_at": NO_FADE,
		"pickup": {},
	},
	"health": {
		"kind": Kind.MEMORY,
		"icon": "res://assets/items/heart.png",
		"fades_at": 0.5,
		"pickup": {
			"char": "3",
			"icon_scale": 2.5,
			"message": "Un relicario pequeño, todavía tibio, como si alguien lo hubiera sostenido hace un instante. Recuerdo lo que se siente estar vivo de verdad, con todo lo que eso implica. [Recuerdo de Vida recuperado]",
		},
	},
	"attack": {
		"kind": Kind.MEMORY,
		"icon": "res://assets/items/sword.png",
		"fades_at": 0.75,
		"pickup": {
			"char": "4",
			"icon_scale": 3.0,
			"message": "Una espada corta, con el filo gastado de uso real, no de exhibición. Recuerdo la firmeza de sostenerla, la decisión de no quedarme quieto. Presioná X para atacar. [Recuerdo del Guerrero recuperado]",
		},
	},
	"dash": {
		"kind": Kind.LATER,
		"icon": "",
		"fades_at": NO_FADE,
		"pickup": {},
	},
	"stability_boost": {
		"kind": Kind.OPTIONAL,
		"icon": "res://assets/items/star.png",
		"fades_at": 0.75,
		"pickup": {
			"char": "5",
			"icon_scale": 2.5,
			"message": "Me detengo un momento. No todo es llegar rápido a algún lado — a veces vale la pena desviarse, mirar alrededor, quedarme con lo que casi me pierdo. [Estabilidad máxima ampliada +10%]",
		},
	},
}

static func abilities_of(kinds: Array) -> Array[String]:
	var result: Array[String] = []
	for ability: String in LIST:
		if kinds.has(LIST[ability].kind):
			result.append(ability)
	return result

static func memory_count() -> int:
	return abilities_of([Kind.MEMORY]).size()

# Índice inverso para level_loader.gd: qué habilidad corresponde al dígito
# del mapa ASCII. "" si ninguna entrada tiene ese carácter (mapa mal armado).
static func by_pickup_char(ch: String) -> String:
	for ability: String in LIST:
		if LIST[ability].pickup.get("char") == ch:
			return ability
	return ""
