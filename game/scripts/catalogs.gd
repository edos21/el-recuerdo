extends Node
# Dueño de los catálogos de datos editables en el inspector (autoload). Se
# cargan con load() y no con preload porque cada .tres depende del script de su
# catálogo, y ese script llega acá: precargarlo sería un ciclo. Vive en un
# autoload y no en una `static var` porque Godot libera el árbol antes de
# chequear fugas al salir, y una `static var` con un Resource queda reportada.

var memories: MemoryData = load("res://data/memories.tres")
var enemies: EnemyData = load("res://data/enemies.tres")
