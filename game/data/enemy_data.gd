extends RefCounted
class_name EnemyData
# Stats de los enemigos del Nivel 1, por caracter del mapa (levels/level1.txt).
# level_loader.gd los instancia leyendo el caracter; el ASCII solo dice "aca va
# el enemigo X", el balance vive aca.
#
# Las entradas son homogeneas a proposito: aunque un valor coincida con el
# default del @export de enemy.gd, o el comportamiento no lo use (chase_* en un
# patrullero), se escribe igual. Asi la tabla se lee como tabla, no queda ningun
# numero de balance en el interprete, y una entrada incompleta falla al cargar
# en vez de nerfear un enemigo en silencio.
#
# `guards_memory` es el caracter del recuerdo que el enemigo custodia ("" si
# ninguno): ese recuerdo no aparece hasta que caen todos sus custodios.

const LIST := {
	"z": {
		"frames": "res://assets/characters/enemy_shadow_frames.tres",
		"behavior": Enemy.Behavior.PATROL,
		"speed": 60.0,
		"patrol_distance": 70.0,
		"max_health": 2,
		"contact_damage": 1,
		"chase_range": 260.0,
		"chase_speed": 200.0,
		"killable": true,
		"tint": Color.WHITE,
		"collision_layer": 2,
		"guards_memory": "",
	},
	"f": {
		# Usa los mismos cuadros que la sombra comun: lo unico que la distingue a
		# simple vista es el tinte frio.
		"frames": "res://assets/characters/enemy_shadow_frames.tres",
		"behavior": Enemy.Behavior.PATROL,
		"speed": 115.0,
		"patrol_distance": 70.0,
		"max_health": 2,
		"contact_damage": 1,
		"chase_range": 260.0,
		"chase_speed": 200.0,
		"killable": true,
		"tint": Color(0.8, 0.9, 1.6, 1),
		"collision_layer": 2,
		"guards_memory": "",
	},
	"e": {
		"frames": "res://assets/characters/enemy_elite_frames.tres",
		"behavior": Enemy.Behavior.CHARGE,
		"speed": 90.0,
		"patrol_distance": 25.0,
		"max_health": 5,
		"contact_damage": 2,
		"chase_range": 260.0,
		"chase_speed": 200.0,
		"killable": true,
		"tint": Color.WHITE,
		"collision_layer": 2,
		# El recuerdo del camino opcional no aparece hasta vencer al elite.
		"guards_memory": "5",
	},
	"g": {
		"frames": "res://assets/characters/enemy_guardian_frames.tres",
		"behavior": Enemy.Behavior.GUARD,
		"speed": 60.0,
		"patrol_distance": 80.0,
		"max_health": 2,
		"contact_damage": 1,
		"chase_range": 260.0,
		"chase_speed": 200.0,
		"killable": true,
		"tint": Color.WHITE,
		# El guardian si tiene que ser un cuerpo solido para el jugador
		# (capa 1 ademas de la 2): la idea es que no se pueda atravesar.
		"collision_layer": 3,
		"guards_memory": "",
	},
	"h": {
		"frames": "res://assets/characters/enemy_chaser_frames.tres",
		"behavior": Enemy.Behavior.CHASE,
		"speed": 60.0,
		"patrol_distance": 80.0,
		"max_health": 2,
		"contact_damage": 1,
		"chase_range": 320.0,
		"chase_speed": 150.0,
		"killable": false,
		"tint": Color.WHITE,
		"collision_layer": 2,
		"guards_memory": "",
	},
	"m": {
		"frames": "res://assets/characters/enemy_restos_frames.tres",
		"behavior": Enemy.Behavior.PATROL,
		"speed": 110.0,
		"patrol_distance": 35.0,
		"max_health": 1,
		"contact_damage": 1,
		"chase_range": 260.0,
		"chase_speed": 200.0,
		"killable": true,
		"tint": Color.WHITE,
		"collision_layer": 2,
		"guards_memory": "",
	},
}
