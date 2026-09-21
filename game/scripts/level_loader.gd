extends Node2D
# Lee un mapa ASCII (levels/level1.txt) y arma el nivel: TileMapLayer visual
# + colisiones simples (StaticBody2D por tramo, como el nivel viejo, pero
# generadas en vez de dibujadas a mano) + enemigos + recuerdos + checkpoints
# + entrada de la cueva + zona de muerte. Todo lo que main.gd necesita
# despues queda accesible por grupo ("player", "checkpoints", "expulsion_trigger",
# "kill_zone") o por lo que devuelve build().

# El recuerdo del camino opcional no aparece hasta vencer al elite de la arena.
const ELITE_REWARD_MEMORY := '5'
const CELL := 36.0          # 18px de tile * escala 2
const TILE_SCALE := Vector2(2, 2)
const GROUND_TINT := Color(0.58, 0.55, 0.66)
const PROPS_TINT := Color(0.7, 0.68, 0.78)

const TILE_SET := preload("res://assets/tiles/platformer.tres")
const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const MEMORY_SCENE := preload("res://scenes/MemoryPickup.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/Checkpoint.tscn")

const DOOR_TEXTURE := preload("res://assets/props/door.png")

const ATLAS := {
	"ground_top": Vector2i(1, 6),
	"ground_fill": Vector2i(1, 6),
	"platform": Vector2i(8, 2),
	"spike": Vector2i(8, 3),
	"sign": Vector2i(4, 4),
	"tree": Vector2i(6, 6),
	"bush": Vector2i(4, 6),
}

const ENEMY_FRAMES := {
	"z": "res://assets/characters/enemy_shadow_frames.tres",
	"f": "res://assets/characters/enemy_shadow_frames.tres",
	"e": "res://assets/characters/enemy_elite_frames.tres",
	"g": "res://assets/characters/enemy_guardian_frames.tres",
	"h": "res://assets/characters/enemy_chaser_frames.tres",
	"m": "res://assets/characters/enemy_restos_frames.tres",
}

var arena_elite: CharacterBody2D
var reward_pickup: Area2D

var tilemap: TileMapLayer
var props_layer: TileMapLayer

func build(level_path: String) -> Node2D:
	var rows := _read_grid(level_path)
	tilemap = TileMapLayer.new()
	tilemap.name = "Tiles"
	tilemap.tile_set = TILE_SET
	tilemap.scale = TILE_SCALE
	# Tierra oscura y fria en vez del pasto de Kenney: el nivel no es una
	# tarde de verano ni cuando recupera el color.
	tilemap.modulate = GROUND_TINT
	add_child(tilemap)
	# Los objetos de fondo van en su propia capa para poder aparecerlos
	# recien con el Recuerdo de Vida (WorldProgression le anima el alpha).
	props_layer = TileMapLayer.new()
	props_layer.name = "Props"
	props_layer.tile_set = TILE_SET
	props_layer.scale = TILE_SCALE
	props_layer.z_index = -1
	props_layer.modulate = PROPS_TINT
	add_child(props_layer)

	var solid_runs := {}   # row -> array de columnas con '#'
	var platform_runs := {}
	var player: Node2D = null
	var min_row := 0
	var max_row := rows.size() - 1
	var max_col := 0

	for row in range(rows.size()):
		var line: String = rows[row]
		max_col = maxi(max_col, line.length())
		for col in range(line.length()):
			var ch := line[col]
			if ch == '.' or ch == '':
				continue
			match ch:
				'#':
					if not solid_runs.has(row):
						solid_runs[row] = []
					solid_runs[row].append(col)
					var above_empty: bool = row == 0 or rows[row - 1].length() <= col or rows[row - 1][col] == '.'
					tilemap.set_cell(Vector2i(col, row), 0, ATLAS.ground_top if above_empty else ATLAS.ground_fill)
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
					props_layer.set_cell(Vector2i(col, row), 0, ATLAS.tree)
				'o':
					props_layer.set_cell(Vector2i(col, row), 0, ATLAS.bush)
				'd':
					_add_door(col, row)
				'P':
					player = PLAYER_SCENE.instantiate()
					player.position = _cell_center(col, row)
				'C':
					var checkpoint := CHECKPOINT_SCENE.instantiate()
					checkpoint.position = _cell_center(col, row)
					add_child(checkpoint)
				'X':
					_add_expulsion_trigger(col, row)
				'1', '2', '3', '4', '5':
					var pickup := _add_memory(ch, col, row)
					if ch == ELITE_REWARD_MEMORY:
						reward_pickup = pickup
				'z', 'f', 'e', 'g', 'h', 'm':
					var enemy := _add_enemy(ch, col, row)
					if ch == 'e':
						arena_elite = enemy

	if arena_elite and reward_pickup:
		reward_pickup.lock()
		arena_elite.defeated.connect(reward_pickup.reveal)

	_build_collision_runs(solid_runs, false)
	_build_collision_runs(platform_runs, true)
	_add_kill_zone(max_col, max_row)
	_add_end_wall(max_col, max_row)

	if player:
		add_child(player)
	return player

func _read_grid(level_path: String) -> Array:
	var file := FileAccess.open(level_path, FileAccess.READ)
	var rows: Array = []
	while not file.eof_reached():
		var line := file.get_line()
		if line == "" and file.eof_reached():
			break
		rows.append(line)
	return rows

func _cell_center(col: int, row: int) -> Vector2:
	return Vector2((col + 0.5) * CELL, (row + 0.5) * CELL)

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
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, CELL if not one_way else 10.0)
	shape.shape = rect
	if one_way:
		shape.one_way_collision = true
		shape.position.y = -CELL * 0.5 + 5.0
	body.add_child(shape)
	add_child(body)

func _add_hazard(col: int, row: int) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.position = _cell_center(col, row)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(CELL * 0.8, CELL * 0.6)
	shape.shape = rect
	shape.position.y = CELL * 0.2
	area.add_child(shape)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("take_damage"):
			body.take_damage(1, area.global_position + Vector2(0, -40))
			get_tree().call_group("audio", "play_sfx", "spike")
	)
	add_child(area)

func _add_memory(digit: String, col: int, row: int) -> Area2D:
	var data: Dictionary = MemoryData.LIST[digit]
	var pickup := MEMORY_SCENE.instantiate()
	pickup.position = _cell_center(col, row)
	pickup.memory_id = data.memory_id
	pickup.ability = data.ability
	pickup.message = data.message
	pickup.icon = load(data.icon)
	pickup.icon_scale = data.icon_scale
	add_child(pickup)
	return pickup

func _add_enemy(ch: String, col: int, row: int) -> CharacterBody2D:
	var enemy := ENEMY_SCENE.instantiate()
	enemy.position = _cell_center(col, row)
	enemy.sprite_frames_path = ENEMY_FRAMES[ch]
	match ch:
		'z':
			enemy.behavior = 0  # PATROL
			enemy.speed = 60.0
			enemy.patrol_distance = 70.0
		'f':
			enemy.behavior = 0
			enemy.speed = 115.0
			enemy.patrol_distance = 70.0
			enemy.modulate = Color(0.8, 0.9, 1.6, 1)
		'e':
			enemy.behavior = 3  # CHARGE
			enemy.speed = 90.0
			enemy.patrol_distance = 25.0
			enemy.max_health = 5
			enemy.contact_damage = 2
		'g':
			enemy.behavior = 1  # GUARD
			enemy.max_health = 2
			# El guardian si tiene que ser un cuerpo solido para el jugador
			# (capa 1 ademas de la 2): la idea es que no se pueda atravesar.
			enemy.collision_layer = 3
		'h':
			enemy.behavior = 2  # CHASE
			enemy.killable = false
			enemy.chase_range = 320.0
			enemy.chase_speed = 150.0
		'm':
			enemy.behavior = 0
			enemy.speed = 110.0
			enemy.patrol_distance = 35.0
			enemy.max_health = 1
	add_child(enemy)
	return enemy

# Zona invisible: al cruzarla arranca la secuencia de expulsion del recuerdo.
func _add_expulsion_trigger(col: int, row: int) -> void:
	var area := Area2D.new()
	area.name = "ExpulsionTrigger"
	area.add_to_group("expulsion_trigger")
	area.collision_layer = 0
	area.position = _cell_center(col, row)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(CELL, CELL * 3.0)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)

# Sin borde de mapa, el jugador debilitado de la expulsion caminaria hasta
# caerse al vacio antes de desplomarse.
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

func _add_end_wall(max_col: int, max_row: int) -> void:
	var height := (max_row + 6) * CELL
	var body := StaticBody2D.new()
	body.position = Vector2((max_col - 1) * CELL + CELL * 0.5, height * 0.5 - 6 * CELL)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(CELL, height)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

func _add_kill_zone(max_col: int, max_row: int) -> void:
	var area := Area2D.new()
	area.add_to_group("kill_zone")
	area.collision_layer = 0
	var width := (max_col + 4) * CELL
	var y := (max_row + 3) * CELL
	area.position = Vector2(width * 0.5, y)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, CELL)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
