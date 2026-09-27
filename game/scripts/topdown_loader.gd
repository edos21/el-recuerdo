class_name TopDownLoader
extends Node2D
# Base de los intérpretes de mapas cenitales (el pueblo, los interiores): lee el
# ASCII, arma el suelo, ubica objetos, NPCs y al jugador, y cierra el borde.
# Cada mapa decide su suelo en _build_ground y su leyenda en _place; lo común
# (celdas, pies de los sprites, bloqueos, NPCs, 'P') vive acá.

const TILE := 16
const TILE_SCALE := 2
const CELL := float(TILE * TILE_SCALE)
const WALL_THICKNESS := 64.0
# Lo lee la atmósfera para darles sombra de contacto.
const CHARACTERS_GROUP := &"town_characters"

const PLAYER_SCENE := preload("res://scenes/TopDownPlayer.tscn")
const NPC_SCENE := preload("res://scenes/Npc.tscn")

var objects: Node2D
# Rectángulo del mapa en px de mundo; vale después de build().
var bounds: Rect2
var _rows: Array = []
var _cols := 0
var _spawn := Vector2.ZERO

func build(level_path: String) -> CharacterBody2D:
	_rows = MapUtils.read_grid(level_path)
	for row in _rows:
		_cols = maxi(_cols, row.length())
	_build_ground()
	objects = Node2D.new()
	objects.name = "Objects"
	objects.y_sort_enabled = true
	add_child(objects)
	for row in _rows.size():
		for col in _rows[row].length():
			var ch: String = _rows[row][col]
			if ch == 'P':
				_spawn = _feet(col, row)
			elif TownNpcData.LIST.has(ch):
				_add_npc(ch, col, row)
			else:
				_place(ch, col, row)
	bounds = Rect2(0, 0, _cols * CELL, _rows.size() * CELL)
	_add_boundary(bounds)
	var player: CharacterBody2D = PLAYER_SCENE.instantiate()
	player.position = _spawn_position()
	player.add_to_group(CHARACTERS_GROUP)
	objects.add_child(player)
	player.set_camera_limits(bounds)
	return player

# Suelo del mapa: se llama antes de ubicar objetos.
func _build_ground() -> void:
	pass

# Un carácter de la leyenda propia del mapa ('P' y los NPCs ya los resuelve la
# base). Lo que no reconoce (el suelo) se ignora.
func _place(_ch: String, _col: int, _row: int) -> void:
	pass

func _spawn_position() -> Vector2:
	return _spawn

func _cell(col: int, row: int) -> String:
	if row < 0 or row >= _rows.size() or col < 0 or col >= _rows[row].length():
		return ""
	return _rows[row][col]

# El origen de cada sprite queda en sus pies (centro del borde inferior de la
# celda), para que el orden por Y funcione.
func _feet(col: int, row: int) -> Vector2:
	return Vector2((col + 0.5) * CELL, (row + 1) * CELL)

func _add_npc(ch: String, col: int, row: int) -> void:
	var npc := NPC_SCENE.instantiate()
	npc.configure(TownNpcData.LIST[ch])
	npc.position = _feet(col, row)
	npc.add_to_group(CHARACTERS_GROUP)
	objects.add_child(npc)

# Sprite apoyado en `base`, con el origen de la textura en `feet` (px de textura).
func _add_prop(texture: Texture2D, base: Vector2, feet: Vector2, group: StringName = &"") -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = -feet
	sprite.scale = Vector2(TILE_SCALE, TILE_SCALE)
	sprite.position = base
	if group != &"":
		sprite.add_to_group(group)
	objects.add_child(sprite)
	return sprite

# Cuerpo estatico apoyado en `base` (el centro de su borde inferior): la forma
# crece hacia arriba desde los pies del sprite.
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
