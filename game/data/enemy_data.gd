class_name EnemyData
extends Resource
# Stats de los enemigos del Nivel 1, por carácter del mapa (levels/level1.txt),
# en data/enemies.tres: el balance se ajusta en el inspector, sin tocar código.
# level_loader.gd los instancia leyendo el carácter; el ASCII solo dice "acá va
# el enemigo X", el balance vive en el .tres.

@export var enemies: Array[EnemyDef] = []

var _by_char: Dictionary[String, EnemyDef] = {}

static func entry(ch: String) -> EnemyDef:
	return _loaded()._by_char.get(ch)

# El catálogo cargado (ver Catalogs), indexado la primera vez que se lo pide.
static func _loaded() -> EnemyData:
	var catalog := Catalogs.enemies
	if catalog._by_char.is_empty():
		catalog._index()
	return catalog

# Un dato mal cargado se avisa al arrancar, en vez de nerfear un enemigo o
# esconder un recuerdo para siempre en silencio.
func _index() -> void:
	for enemy in enemies:
		if enemy.map_char == "" or _by_char.has(enemy.map_char):
			push_error("EnemyData: carácter vacío o repetido ('%s')." % enemy.map_char)
			continue
		_by_char[enemy.map_char] = enemy
		if enemy.frames == "" or enemy.max_health <= 0 or enemy.collision_layer == 0:
			push_error("EnemyData: '%s' necesita cuadros, vida y capa de colisión." % enemy.map_char)
		if enemy.guards_memory != "" and MemoryData.by_pickup_char(enemy.guards_memory) == "":
			push_error("EnemyData: '%s' custodia el recuerdo '%s', que no existe." % [enemy.map_char, enemy.guards_memory])
