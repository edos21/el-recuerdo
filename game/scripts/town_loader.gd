class_name TownLoader
extends TopDownLoader
# Construye el pueblo real a partir de un mapa ASCII (levels/town.txt), igual
# que level_loader.gd hace con el Nivel 1: editar el pueblo es editar el .txt.
#
# Leyenda: '.' pasto, ',' camino de tierra, 'T' arbol, 'H' casa e 'I' posada
# (la letra marca el centro de su base), 'n'/'N' NPCs (data/town_npcs.gd), 'P'
# donde aparece el jugador.

const GROUND_TEXTURE := preload("res://assets/town/ground.png")
const HOUSE_TEXTURES := [
	preload("res://assets/town/house_a.png"),
	preload("res://assets/town/house_b.png"),
	preload("res://assets/town/house_c.png"),
]
# Mascara de ventanas de cada casa, en el mismo orden que HOUSE_TEXTURES.
const HOUSE_WINDOW_MASKS := [
	preload("res://assets/town/house_a_windows.png"),
	preload("res://assets/town/house_b_windows.png"),
	preload("res://assets/town/house_c_windows.png"),
]
const INN_TEXTURE := preload("res://assets/town/inn.png")
const INN_WINDOW_MASK := preload("res://assets/town/inn_windows.png")
const TREE_TEXTURES := [
	preload("res://assets/town/tree_a.png"),
	preload("res://assets/town/tree_b.png"),
]

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

# Dimensiones de las imagenes de arboles (px de la textura) y metas con las que
# cada edificio lleva a la atmosfera su mascara de ventanas y sus anclajes
# (data/house_layout.gd): la posada no mide lo mismo que una casa.
const TREE_FEET := Vector2(40, 100)
const TREE_TRUNK := Vector2(16, 8)
const WINDOW_MASK_META := &"window_mask"
const LAYOUT_META := &"layout"
# Umbral delante de la puerta de un edificio (px de mundo) y cuánto más abajo
# aparece quien sale por ella.
const DOOR_TRIGGER := Vector2(48, 16)
const DOOR_ARRIVAL_DEPTH := 40.0

func _build_ground() -> void:
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = _make_tile_set()
	ground.scale = Vector2(TILE_SCALE, TILE_SCALE)
	add_child(ground)
	for row in _rows.size():
		for col in _rows[row].length():
			ground.set_cell(Vector2i(col, row), 0, _ground_tile(col, row))

func _place(ch: String, col: int, row: int) -> void:
	match ch:
		'T':
			_add_tree(col, row)
		'H':
			var variant := MapUtils.cell_hash(col, row) % HOUSE_TEXTURES.size()
			_add_building(col, row, HOUSE_TEXTURES[variant], HOUSE_WINDOW_MASKS[variant], HouseLayout.HOUSE)
		'I':
			_add_building(col, row, INN_TEXTURE, INN_WINDOW_MASK, HouseLayout.INN)
			_add_building_door(col, row, HouseLayout.INN, DoorData.POSADA)

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
	return _cell(col, row) == ','

func _ground_tile(col: int, row: int) -> Vector2i:
	var roll := MapUtils.cell_hash(col, row)
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
	return MOBILE_OBJECTS.has(_cell(col, row)) and _has_path_neighbor(col, row)

func _add_tree(col: int, row: int) -> void:
	var texture: Texture2D = TREE_TEXTURES[MapUtils.cell_hash(col, row) % TREE_TEXTURES.size()]
	_add_prop(texture, _feet(col, row), TREE_FEET, &"town_trees")
	_add_blocker(_feet(col, row), TREE_TRUNK * TILE_SCALE)

func _add_building(col: int, row: int, texture: Texture2D, window_mask: Texture2D, layout: Dictionary) -> void:
	var sprite := _add_prop(texture, _feet(col, row), layout.feet, &"town_houses")
	sprite.set_meta(WINDOW_MASK_META, window_mask)
	sprite.set_meta(LAYOUT_META, layout)
	_add_blocker(_feet(col, row), layout.body * TILE_SCALE)

# La puerta sale de los anclajes del edificio, así siempre coincide con el arte.
func _add_building_door(col: int, row: int, layout: Dictionary, id: StringName) -> void:
	var door: Vector2 = _feet(col, row) + layout.door * TILE_SCALE
	var trigger := Rect2(door - Vector2(DOOR_TRIGGER.x * 0.5, 0), DOOR_TRIGGER)
	_add_door(id, DoorData.SCENES[id].inside, trigger, door + Vector2(0, DOOR_ARRIVAL_DEPTH))
