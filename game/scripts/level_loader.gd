extends Node2D
# Lee un mapa ASCII (levels/level1.txt) y arma el nivel: TileMapLayer visual
# + colisiones simples (StaticBody2D por tramo, como el nivel viejo, pero
# generadas en vez de dibujadas a mano) + enemigos + recuerdos + checkpoints
# + zona de expulsion + zona de muerte. Todo lo que main.gd necesita
# despues queda accesible por grupo ("player", "checkpoints", "expulsion_trigger",
# "kill_zone") o por lo que devuelve build(). La atmosfera (level_atmosphere.gd)
# decora lo que se marca con los grupos "level_ground", "level_props",
# "level_plants" y "level_memories"; aca no se mete ningun efecto.

const CELL := 36.0          # 18px de tile * escala 2
const TILE_SCALE := Vector2(2, 2)
const GROUND_TINT := Color(0.58, 0.55, 0.66)
const PROPS_TINT := Color(0.7, 0.68, 0.78)
# Aire entre los pies y el piso al nacer: el cuerpo cae ese pixel y apoya.
const SPAWN_CLEARANCE := 1.0

const TILE_SET := preload("res://assets/tiles/platformer.tres")
const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const MEMORY_SCENE := preload("res://scenes/MemoryPickup.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/Checkpoint.tscn")

const DOOR_TEXTURE := preload("res://assets/props/door.png")
const PINE_TEXTURE := preload("res://assets/props/plant_pine.png")
const SPROUT_TEXTURE := preload("res://assets/props/plant_sprout.png")

const ATLAS := {
	"ground": Vector2i(1, 6),
	"platform": Vector2i(8, 2),
	"spike": Vector2i(8, 3),
	"sign": Vector2i(4, 4),
}

var tilemap: TileMapLayer
var props_layer: TileMapLayer

func build(level_path: String) -> Node2D:
	var rows := MapUtils.read_grid(level_path)
	tilemap = TileMapLayer.new()
	tilemap.name = "Tiles"
	tilemap.tile_set = TILE_SET
	tilemap.scale = TILE_SCALE
	# Tierra oscura y fria en vez del pasto de Kenney: el nivel no es una
	# tarde de verano ni cuando recupera el color.
	tilemap.modulate = GROUND_TINT
	tilemap.add_to_group("level_ground")
	add_child(tilemap)
	# Los objetos de fondo van en su propia capa para poder aparecerlos
	# recien con el Recuerdo de Vida (WorldProgression le anima el alpha).
	props_layer = TileMapLayer.new()
	props_layer.name = "Props"
	props_layer.tile_set = TILE_SET
	props_layer.scale = TILE_SCALE
	props_layer.z_index = -1
	props_layer.modulate = PROPS_TINT
	props_layer.add_to_group("level_props")
	add_child(props_layer)

	var solid_runs := {}   # row -> array de columnas con '#'
	var platform_runs := {}
	var memory_pickups := {}   # caracter de recuerdo -> Area2D
	var guarded_by := {}       # caracter de recuerdo -> Array de enemigos que lo custodian
	var player: Node2D = null
	var max_row := rows.size() - 1
	var max_col := 0

	for row in range(rows.size()):
		var line: String = rows[row]
		max_col = maxi(max_col, line.length())
		for col in range(line.length()):
			var ch := line[col]
			if ch == '.':
				continue
			match ch:
				'#':
					if not solid_runs.has(row):
						solid_runs[row] = []
					solid_runs[row].append(col)
					tilemap.set_cell(Vector2i(col, row), 0, ATLAS.ground)
				'=':
					if not platform_runs.has(row):
						platform_runs[row] = []
					platform_runs[row].append(col)
					tilemap.set_cell(Vector2i(col, row), 0, ATLAS.platform)
				'^':
					tilemap.set_cell(Vector2i(col, row), 0, ATLAS.spike)
					_add_hazard(col, row)
				's':
					props_layer.set_cell(Vector2i(col, row), 0, ATLAS.sign)
				't':
					_add_plant(PINE_TEXTURE, col, row)
				'o':
					_add_plant(SPROUT_TEXTURE, col, row)
				'd':
					_add_door(col, row)
				'P':
					player = PLAYER_SCENE.instantiate()
					player.position = _standing_on_cell(player, col, row)
				'C':
					var checkpoint := CHECKPOINT_SCENE.instantiate()
					checkpoint.position = _cell_center(col, row)
					add_child(checkpoint)
				'X':
					_add_expulsion_trigger(col, row)
				'1', '2', '3', '4', '5':
					memory_pickups[ch] = _add_memory(MemoryData.by_pickup_char(ch), col, row)
				'z', 'f', 'e', 'g', 'h', 'm':
					_track_guardian(guarded_by, ch, _add_enemy(ch, col, row))

	for memory_ch: String in guarded_by:
		if memory_pickups.has(memory_ch):
			_lock_until_defeated(memory_pickups[memory_ch], guarded_by[memory_ch])

	_build_collision_runs(solid_runs, false)
	_build_collision_runs(platform_runs, true)
	_add_kill_zone(max_col, max_row)
	_add_end_wall(max_col, max_row)

	if player:
		add_child(player)
	return player

func _cell_center(col: int, row: int) -> Vector2:
	return Vector2((col + 0.5) * CELL, (row + 0.5) * CELL)

# Apoya los pies del cuerpo justo sobre el borde de abajo de su celda. Si
# naciera un poco hundido, un piso solido lo empujaria arriba, pero una
# plataforma de un solo sentido lo ignora y lo deja caer.
func _standing_on_cell(body: Node2D, col: int, row: int) -> Vector2:
	var shape := body.get_node("CollisionShape2D") as CollisionShape2D
	var feet := shape.position.y + (shape.shape as RectangleShape2D).size.y * 0.5
	return Vector2((col + 0.5) * CELL, (row + 1) * CELL - feet - SPAWN_CLEARANCE)

func _build_collision_runs(runs: Dictionary, one_way: bool) -> void:
	for row in runs:
		var cols: Array = runs[row]
		cols.sort()
		var run_start = cols[0]
		var prev = cols[0]
		for i in range(1, cols.size() + 1):
			var col = cols[i] if i < cols.size() else -999
			if col != prev + 1:
				_add_solid_body(run_start, prev, row, one_way)
				run_start = col
			prev = col

func _add_solid_body(col_start: int, col_end: int, row: int, one_way: bool) -> void:
	var width := float(col_end - col_start + 1) * CELL
	var body := StaticBody2D.new()
	body.position = Vector2(col_start * CELL + width * 0.5, row * CELL + CELL * 0.5)
	var shape := MapUtils.rect_shape(Vector2(width, CELL if not one_way else 10.0))
	if one_way:
		shape.one_way_collision = true
		shape.position.y = -CELL * 0.5 + 5.0
	body.add_child(shape)
	add_child(body)

func _add_hazard(col: int, row: int) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.position = _cell_center(col, row)
	var shape := MapUtils.rect_shape(Vector2(CELL * 0.8, CELL * 0.6))
	shape.position.y = CELL * 0.2
	area.add_child(shape)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("take_damage"):
			body.take_damage(1, area.global_position + Vector2(0, -40))
			Events.sfx_requested.emit("spike")
	)
	add_child(area)

func _add_memory(ability: String, col: int, row: int) -> Area2D:
	var data: Dictionary = MemoryData.LIST[ability]
	var pickup := MEMORY_SCENE.instantiate()
	pickup.position = _cell_center(col, row)
	pickup.ability = ability
	pickup.message = data.pickup.message
	pickup.icon = load(data.icon)
	pickup.icon_scale = data.pickup.icon_scale
	pickup.add_to_group("level_memories")
	add_child(pickup)
	return pickup

# Todo se asigna antes de add_child porque Enemy._ready() copia max_health a
# health: un stat seteado despues llega tarde.
func _add_enemy(ch: String, col: int, row: int) -> Enemy:
	var data: Dictionary = EnemyData.LIST[ch]
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = _standing_on_cell(enemy, col, row)
	enemy.sprite_frames_path = data.frames
	enemy.behavior = data.behavior
	enemy.speed = data.speed
	enemy.patrol_distance = data.patrol_distance
	enemy.max_health = data.max_health
	enemy.contact_damage = data.contact_damage
	enemy.chase_range = data.chase_range
	enemy.chase_speed = data.chase_speed
	enemy.killable = data.killable
	enemy.modulate = data.tint
	enemy.collision_layer = data.collision_layer
	add_child(enemy)
	return enemy

# Un enemigo que custodia un recuerdo se anota como su custodio. Si no se lo
# puede vencer, el recuerdo quedaria escondido para siempre: se avisa y no se lo
# cuenta, asi un dato mal cargado no deja el nivel incompletable.
func _track_guardian(guarded_by: Dictionary, ch: String, enemy: Enemy) -> void:
	var memory_ch: String = EnemyData.LIST[ch].guards_memory
	if memory_ch == "":
		return
	if not enemy.killable:
		push_warning("El enemigo '%s' custodia el recuerdo '%s' pero no se lo puede vencer." % [ch, memory_ch])
		return
	if not guarded_by.has(memory_ch):
		guarded_by[memory_ch] = []
	guarded_by[memory_ch].append(enemy)

# El recuerdo custodiado no existe hasta que cae el ultimo de sus custodios.
# Se usa erase y no is_instance_valid porque Enemy emite `defeated` antes de
# queue_free: en ese momento el nodo sigue siendo valido. Mientras quede un
# custodio el recuerdo esta bloqueado (no se puede recoger ni liberar), asi que
# el ultimo en morir siempre lo encuentra vivo.
func _lock_until_defeated(pickup: Area2D, guardians: Array) -> void:
	pickup.lock()
	for guardian: Enemy in guardians:
		guardian.defeated.connect(func() -> void:
			guardians.erase(guardian)
			if guardians.is_empty():
				pickup.reveal()
		)

# Zona invisible: al cruzarla arranca la secuencia de expulsion del recuerdo.
func _add_expulsion_trigger(col: int, row: int) -> void:
	var area := Area2D.new()
	area.name = "ExpulsionTrigger"
	area.add_to_group("expulsion_trigger")
	area.collision_layer = 0
	area.position = _cell_center(col, row)
	area.add_child(MapUtils.rect_shape(Vector2(CELL, CELL * 3.0)))
	add_child(area)

# La puerta no es un tile del atlas (el tile que se usaba era una llave): es un
# sprite propio, hijo de la capa de props para heredar su aparicion gradual.
func _add_door(col: int, row: int) -> void:
	var door := Sprite2D.new()
	door.texture = DOOR_TEXTURE
	door.centered = false
	door.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var size := DOOR_TEXTURE.get_size()
	# La capa de props ya escala x2, asi que las coordenadas van en unidades de tile.
	door.position = Vector2((col + 0.5) * CELL / 2.0 - size.x / 2.0, (row + 1) * CELL / 2.0 - size.y)
	props_layer.add_child(door)

# Las plantas son sprites y no celdas para que el viento pueda moverlas una
# por una. Cuelgan de la capa de props (aparecen con ella) y apoyan los pies
# en el fondo de su celda, igual que la puerta.
func _add_plant(texture: Texture2D, col: int, row: int) -> void:
	var plant := Sprite2D.new()
	plant.texture = texture
	plant.centered = false
	plant.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var size := texture.get_size()
	plant.position = Vector2((col + 0.5) * CELL / 2.0 - size.x / 2.0, (row + 1) * CELL / 2.0 - size.y)
	plant.add_to_group("level_plants")
	props_layer.add_child(plant)

# Sin borde de mapa, el jugador debilitado de la expulsion caminaria hasta
# caerse al vacio antes de desplomarse.
func _add_end_wall(max_col: int, max_row: int) -> void:
	var height := (max_row + 6) * CELL
	var body := StaticBody2D.new()
	body.position = Vector2((max_col - 1) * CELL + CELL * 0.5, height * 0.5 - 6 * CELL)
	body.add_child(MapUtils.rect_shape(Vector2(CELL, height)))
	add_child(body)

func _add_kill_zone(max_col: int, max_row: int) -> void:
	var area := Area2D.new()
	area.add_to_group("kill_zone")
	area.collision_layer = 0
	var width := (max_col + 4) * CELL
	var y := (max_row + 3) * CELL
	area.position = Vector2(width * 0.5, y)
	area.add_child(MapUtils.rect_shape(Vector2(width, CELL)))
	add_child(area)
