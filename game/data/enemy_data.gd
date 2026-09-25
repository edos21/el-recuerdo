class_name EnemyData
extends Resource
# Stats de los enemigos del Nivel 1, por carácter del mapa (levels/level1.txt),
# en data/enemies.tres: el balance se ajusta en el inspector, sin tocar código.
# level_loader.gd los instancia leyendo el carácter; el ASCII solo dice "acá va
# el enemigo X", el balance vive en el .tres.

@export var entries: Array[EnemyDef] = []

var _by_char: Dictionary[String, EnemyDef] = {}

func entry(ch: String) -> EnemyDef:
	return _by_char.get(ch)

# Lo llama Catalogs al arrancar; se puede repetir (load() devuelve la misma
# instancia cacheada del .tres). Un dato mal cargado se avisa ahí, en
# vez de nerfear un enemigo en silencio.
func index() -> void:
	_by_char.clear()
	for enemy in entries:
		if enemy.map_char == "" or _by_char.has(enemy.map_char):
			push_error("EnemyData: carácter vacío o repetido ('%s')." % enemy.map_char)
			continue
		_by_char[enemy.map_char] = enemy
		if enemy.frames == "" or enemy.max_health <= 0 or enemy.collision_layer == 0:
			push_error("EnemyData: '%s' necesita cuadros, vida y capa de colisión." % enemy.map_char)
