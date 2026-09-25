class_name EnemyDef
extends Resource
# Stats de un tipo de enemigo del Nivel 1: una entrada de EnemyData
# (data/enemies.tres). level_loader.gd copia cada campo al Enemy antes de
# agregarlo al árbol.
#
# Los valores por defecto son neutros (cero, falso, vacío) a propósito, aunque
# no coincidan con los @export de enemy.gd: así el .tres guarda cada número de
# balance de forma explícita, y cambiar un default acá no nerfea en silencio a
# los enemigos que lo heredaban. Lo imprescindible se valida al cargar.
#
# Notas de las entradas actuales, que en el .tres no tienen dónde vivir:
# - 'f' usa los mismos cuadros que la sombra común 'z': lo único que la
#   distingue a simple vista es el tinte frío.
# - 'e' (el elite) custodia el recuerdo '5' del camino opcional.
# - 'g' (el guardián) usa las capas 1+2: tiene que ser un cuerpo sólido para el
#   jugador, la idea es que no se pueda atravesar.

# Carácter del mapa ASCII (levels/level1.txt) que ubica a este enemigo.
@export var map_char := ""
@export_file("*.tres") var frames := ""
@export var behavior: Enemy.Behavior = Enemy.Behavior.PATROL
@export var speed := 0.0
@export var patrol_distance := 0.0
@export var max_health := 0
@export var contact_damage := 0
@export var chase_range := 0.0
@export var chase_speed := 0.0
@export var killable := false
@export var tint := Color.WHITE
@export_flags_2d_physics var collision_layer := 0
# Carácter del recuerdo que custodia ("" si ninguno): ese recuerdo no aparece
# hasta que caen todos sus custodios.
@export var guards_memory := ""
