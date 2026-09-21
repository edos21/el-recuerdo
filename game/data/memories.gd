extends RefCounted
class_name MemoryData
# Datos de los 5 recuerdos del Nivel 1. level_loader.gd los instancia leyendo
# el caracter '1'..'5' del mapa ASCII; el ASCII solo dice "acá va el recuerdo
# N", el contenido narrativo vive acá.

const LIST := {
	"1": {
		"ability": "jump",
		"icon": "res://assets/items/rope.png",
		"icon_scale": 2.5,
		"message": "Una cuerda de saltar, gastada por el uso. Recuerdo el sonido que hacía al golpear el suelo, una y otra vez, sin pensar. Así se sentía moverse sin dudar. Presioná Espacio para saltar. [Recuerdo del Saltador recuperado]",
	},
	"2": {
		"ability": "sprint",
		"icon": "res://assets/items/shoes.png",
		"icon_scale": 2.5,
		"message": "Unos zapatos viejos, todavía atados. Me gustaba salir a correr con ellos — me sentía ágil, liviano, rápido. Como un corredor. Mantené Shift apretado mientras te movés para correr. [Recuerdo del Corredor recuperado]",
	},
	"3": {
		"ability": "health",
		"icon": "res://assets/items/heart.png",
		"icon_scale": 2.5,
		"message": "Un relicario pequeño, todavía tibio, como si alguien lo hubiera sostenido hace un instante. Recuerdo lo que se siente estar vivo de verdad, con todo lo que eso implica. [Recuerdo de Vida recuperado]",
	},
	"4": {
		"ability": "attack",
		"icon": "res://assets/items/sword.png",
		"icon_scale": 3.0,
		"message": "Una espada corta, con el filo gastado de uso real, no de exhibición. Recuerdo la firmeza de sostenerla, la decisión de no quedarme quieto. Presioná X para atacar. [Recuerdo del Guerrero recuperado]",
	},
	"5": {
		"ability": "stability_boost",
		"icon": "res://assets/items/star.png",
		"icon_scale": 2.5,
		"message": "Me detengo un momento. No todo es llegar rápido a algún lado — a veces vale la pena desviarse, mirar alrededor, quedarme con lo que casi me pierdo. [Estabilidad máxima ampliada +10%]",
	},
}
