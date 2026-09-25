class_name EnemyDef
extends Resource
# Stats de un tipo de enemigo del Nivel 1: una entrada de EnemyData
# (data/enemies.tres). level_loader.gd copia cada campo al Enemy antes de
# agregarlo al árbol.
#
# Los valores por defecto son cero, falso o vacío, y no los de enemy.gd: una
# entrada a medio cargar queda sin cuadros, vida o capa y la validación del
# catálogo la marca, en vez de nacer con stats que nadie eligió. Godot no
# escribe en el .tres lo que coincide con el default: cambiar un default acá
# cambia todas las entradas que lo usan.

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
# El por qué de una entrada, para quien la edite en el inspector.
@export_multiline var notes := ""
