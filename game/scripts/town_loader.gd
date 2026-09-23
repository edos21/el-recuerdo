extends Node2D
# Construye el pueblo real a partir de un mapa ASCII (levels/town.txt), igual
# que level_loader.gd hace con el Nivel 1: editar el pueblo es editar el .txt.
#
# Leyenda: '.' pasto, ',' camino de tierra, 'T' arbol, 'H' casa (la 'H' marca
# el centro de su base), 'n'/'N' NPCs (data/town_npcs.gd), 'P' donde aparece
# el jugador.

const TILE := 16
const TILE_SCALE := 2
const CELL := float(TILE * TILE_SCALE)

const GROUND_TEXTURE := preload("res://assets/town/ground.png")
const HOUSE_TEXTURES := [
	preload("res://assets/town/house_a.png"),
	preload("res://assets/town/house_b.png"),
	preload("res://assets/town/house_c.png"),
]
const TREE_TEXTURES := [
	preload("res://assets/town/tree_a.png"),
	preload("res://assets/town/tree_b.png"),
]
const PLAYER_SCENE := preload("res://scenes/TopDownPlayer.tscn")
const NPC_SCENE := preload("res://scenes/Npc.tscn")

# Posiciones en el atlas de ground.png (ver tools/gen_town_assets.py).
const GRASS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const FLOWERS := [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)]
const FLOWER_CHANCE := 0.12
const DIRT_FULL := [Vector2i(0, 1), Vector2i(0, 2)]
const DIRT_EDGES := {
	"tl": Vector2i(1, 1), "t": Vector2i(2, 1), "tr": Vector2i(3, 1),
	"l": Vector2i(1, 2), "c": Vector2i(2, 2), "r": Vector2i(3, 2),
	"bl": Vector2i(1, 3), "b": Vector2i(2, 3), "br": Vector2i(3, 3),
}

# Objetos que se paran sobre el suelo de su entorno (camino si hay camino al lado).
const MOBILE_OBJECTS := ['P', 'n', 'N']

# Dimensiones de las imagenes de arboles y casas (px de la textura): el origen
# de cada sprite queda en sus pies, para que el orden por Y (y_sort) funcione.
const TREE_FEET := Vector2(40, 100)
const TREE_TRUNK := Vector2(16, 8)
const HOUSE_FEET := Vector2(72, 198)
const HOUSE_BODY := Vector2(272, 150)
const WALL_THICKNESS := 64.0

var objects: Node2D
var _rows: Array = []

func build(level_path: String) -> CharacterBody2D:
	_rows = MapUtils.read_grid(level_path)
	var cols := 0
	for row in _rows:
		cols = maxi(cols, row.length())

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = _make_tile_set()
	ground.scale = Vector2(TILE_SCALE, TILE_SCALE)
	add_child(ground)

	objects = Node2D.new()
	objects.name = "Objects"
	objects.y_sort_enabled = true
	add_child(objects)

	var player: CharacterBody2D
	for row in _rows.size():
		for col in _rows[row].length():
			var ch: String = _rows[row][col]
			ground.set_cell(Vector2i(col, row), 0, _ground_tile(col, row))
			match ch:
				'T':
					_add_tree(col, row)
				'H':
					_add_house(col, row)
				'n', 'N':
					_add_npc(ch, col, row)
				'P':
					player = PLAYER_SCENE.instantiate()
					player.position = _feet(col, row)
					player.add_to_group("town_characters")

	var bounds := Rect2(0, 0, cols * CELL, _rows.size() * CELL)
	_add_boundary(bounds)
	objects.add_child(player)
	player.set_camera_limits(bounds)
	return player

func _make_tile_set() -> TileSet:
	var source := TileSetAtlasSource.new()
	source.texture = GROUND_TEXTURE
	source.texture_region_size = Vector2i(TILE, TILE)
	var used: Array[Vector2i] = []
	used.append_array(GRASS)
	used.append_array(FLOWERS)
	used.append_array(DIRT_FULL)
	used.append_array(DIRT_EDGES.values())
	for coord in used:
		source.create_tile(coord)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_source(source, 0)
	return tile_set

# Los objetos (arboles, casas, NPCs, spawn) se paran sobre el suelo de su
# entorno: camino si tienen camino al lado, pasto si no.
func _is_path(col: int, row: int) -> bool:
	if row < 0 or row >= _rows.size() or col < 0 or col >= _rows[row].length():
		return false
	return _rows[row][col] == ','

func _ground_tile(col: int, row: int) -> Vector2i:
	var roll := _hash(col, row)
	if not _is_dirt(col, row):
		if roll % 100 < int(FLOWER_CHANCE * 100.0):
			return FLOWERS[roll % FLOWERS.size()]
		return GRASS[roll % GRASS.size()]
	var up := _is_dirt(col, row - 1)
	var down := _is_dirt(col, row + 1)
	var left := _is_dirt(col - 1, row)
	var right := _is_dirt(col + 1, row)
	if (not left and not right) or (not up and not down):
		return DIRT_FULL[roll % DIRT_FULL.size()]
	var vertical := "t" if not up else ("b" if not down else "")
	var horizontal := "l" if not left else ("r" if not right else "")
	if vertical == "" and horizontal == "":
		return DIRT_EDGES["c"]
	if vertical == "":
		return DIRT_EDGES[horizontal]
	if horizontal == "":
		return DIRT_EDGES[vertical]
	return DIRT_EDGES[vertical + horizontal]

# Suelo de tierra: el camino en si, o un objeto movil (spawn, NPC) parado sobre uno.
func _is_dirt(col: int, row: int) -> bool:
	return _is_path(col, row) or _is_object_on_path(col, row)

func _has_path_neighbor(col: int, row: int) -> bool:
	return _is_path(col - 1, row) or _is_path(col + 1, row) \
			or _is_path(col, row - 1) or _is_path(col, row + 1)

func _is_object_on_path(col: int, row: int) -> bool:
	if row < 0 or row >= _rows.size() or col < 0 or col >= _rows[row].length():
		return false
	var ch: String = _rows[row][col]
	return MOBILE_OBJECTS.has(ch) and _has_path_neighbor(col, row)

# Hash determinista por celda: el pasto no cambia de una corrida a otra.
func _hash(col: int, row: int) -> int:
	return absi((col * 73856093) ^ (row * 19349663))

func _feet(col: int, row: int) -> Vector2:
	return Vector2((col + 0.5) * CELL, (row + 1) * CELL)

func _add_tree(col: int, row: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = TREE_TEXTURES[_hash(col, row) % TREE_TEXTURES.size()]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = -TREE_FEET
	sprite.scale = Vector2(TILE_SCALE, TILE_SCALE)
	sprite.position = _feet(col, row)
	sprite.add_to_group("town_trees")
	objects.add_child(sprite)
	_add_blocker(_feet(col, row), TREE_TRUNK * TILE_SCALE)

func _add_house(col: int, row: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = HOUSE_TEXTURES[_hash(col, row) % HOUSE_TEXTURES.size()]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = -HOUSE_FEET
	sprite.scale = Vector2(TILE_SCALE, TILE_SCALE)
	sprite.position = _feet(col, row)
	sprite.add_to_group("town_houses")
	objects.add_child(sprite)
	_add_blocker(_feet(col, row), HOUSE_BODY)

func _add_npc(ch: String, col: int, row: int) -> void:
	var data: Dictionary = TownNpcData.LIST[ch]
	var npc := NPC_SCENE.instantiate()
	npc.configure(data)
	npc.position = _feet(col, row)
	npc.add_to_group("town_characters")
	objects.add_child(npc)

# Cuerpo estatico apoyado en `base` (el centro de su borde inferior), para
# arboles y casas: la forma crece hacia arriba desde los pies del sprite.
func _add_blocker(base: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = base
	var shape := MapUtils.rect_shape(size)
	shape.position = Vector2(0, -size.y * 0.5)
	body.add_child(shape)
	add_child(body)

func _add_boundary(bounds: Rect2) -> void:
	var t := WALL_THICKNESS
	var sides := [
		Rect2(bounds.position.x - t, bounds.position.y - t, bounds.size.x + 2 * t, t),
		Rect2(bounds.position.x - t, bounds.end.y, bounds.size.x + 2 * t, t),
		Rect2(bounds.position.x - t, bounds.position.y, t, bounds.size.y),
		Rect2(bounds.end.x, bounds.position.y, t, bounds.size.y),
	]
	for side in sides:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = side.get_center()
		body.add_child(MapUtils.rect_shape(side.size))
		add_child(body)
