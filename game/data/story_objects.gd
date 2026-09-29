class_name StoryObjectData
extends RefCounted
# Objetos del guion por carácter del mapa (como town_npcs.gd): textura, pies
# (px de textura), huella que bloquea (px de textura; cero si no bloquea),
# pista, diálogo (Dialogues) y cuándo están (`present_if`, GameState.is_met).
# `reach` agranda la zona para usarlo (px de mundo).

const LIST := {
	# Las llaves que Tomás no encuentra: están mientras no se las devolvió ni se
	# las llevó el protagonista.
	"L": {
		"texture": preload("res://assets/town/keys.png"),
		"feet": Vector2(8, 8),
		"body": Vector2.ZERO,
		"hint": "[Enter] mirar",
		"dialogue": &"llaves",
		"present_if": {"beat_pending": "tomas_keys", "lacks_item": "llaves_de_tomas"},
		"reach": 24.0,
	},
	"O": {
		"texture": preload("res://assets/town/well.png"),
		"feet": Vector2(24, 79),
		"body": Vector2(40, 22),
		"hint": "[Enter] usar el pozo",
		"dialogue": &"pozo",
		"reach": 16.0,
	},
}
