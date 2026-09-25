extends Node
# Dueño de los catálogos de datos editables en el inspector (autoload): los
# carga, los indexa y los valida una sola vez al arrancar. Se cargan con load()
# y no con preload porque cada .tres depende del script de su catálogo, y ese
# script se usa acá: precargarlo sería un ciclo. Vive en un autoload y no en
# una `static var` porque Godot libera el árbol antes de chequear fugas al
# salir, y una `static var` con un Resource queda reportada.

var memories: MemoryData = load("res://data/memories.tres")
var enemies: EnemyData = load("res://data/enemies.tres")

func _init() -> void:
	memories.index()
	enemies.index()
	_check_guardians()

# Regla que cruza los dos catálogos: un recuerdo custodiado tiene que existir y
# poder liberarse, o el nivel queda incompletable.
func _check_guardians() -> void:
	for enemy in enemies.entries:
		if enemy.guards_memory == "":
			continue
		if memories.by_pickup_char(enemy.guards_memory) == "":
			push_error("Catalogs: '%s' custodia el recuerdo '%s', que no existe." % [enemy.map_char, enemy.guards_memory])
		elif not enemy.killable:
			push_error("Catalogs: '%s' custodia el recuerdo '%s' pero no se lo puede vencer." % [enemy.map_char, enemy.guards_memory])
