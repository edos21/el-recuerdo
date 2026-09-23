extends Node2D
# Capa de atmosfera del Nivel 1: profundidad bajo el piso, luces, particulas y
# viento. No toca el loader: decora lo que marca con grupos (level_ground,
# level_props, level_plants, level_memories, checkpoints). Todo pasa por el
# post-proceso de Core, asi que tambien arranca gris y gana color con cada
# recuerdo: la luz no le adelanta el color al mundo.
#
# Cada efecto significa algo: la luz del jugador se achica con la Estabilidad,
# la niebla se espesa cuando el protagonista esta menos estable y los
# recuerdos que faltan brillan mas cuantos mas se recuperaron.

const LevelLoader := preload("res://scripts/level_loader.gd")
const SWAY_SHADER := preload("res://shaders/wind_sway.gdshader")
const TUFT_TEXTURES := [
	preload("res://assets/props/plant_sprout.png"),
	preload("res://assets/props/plant_sprout_tall.png"),
]

# Penumbra fria: la luz ambiente baja para que las luces propias guien.
const AMBIENT_COLOR := Color(0.8, 0.8, 0.86)
const GLOW_INTENSITY := 0.5

const PLAYER_LIGHT_COLOR := Color(1.0, 0.93, 0.82)
const PLAYER_LIGHT_ENERGY := 0.55
const PLAYER_LIGHT_OFFSET := Vector2(0, -8)
# Radio de la luz sin Estabilidad y con la barra llena.
const PLAYER_LIGHT_SCALE_MIN := 0.9
const PLAYER_LIGHT_SCALE_MAX := 2.6
const PLAYER_LIGHT_FOLLOW_SPEED := 3.0

const MEMORY_LIGHT_COLOR := Color(1.0, 0.9, 0.62)
const MEMORY_LIGHT_BASE_ENERGY := 0.45
const MEMORY_LIGHT_ENERGY_PER_RECOVERED := 0.2
const MEMORY_LIGHT_SCALE := 1.3
const MEMORY_HALO_ALPHA := 0.35
const MEMORY_HALO_SCALE := 1.1
const MEMORY_PULSE_TIME := 1.6

const BENCH_LIGHT_COLOR := Color(1.0, 0.72, 0.45)
const BENCH_LIGHT_IDLE_ENERGY := 0.18
const BENCH_LIGHT_ACTIVE_ENERGY := 0.6
const BENCH_LIGHT_SCALE := 1.2
const BENCH_LIGHT_OFFSET := Vector2(0, -12)

# Tierra que se funde en niebla: el mundo no termina en el cielo de abajo.
const UNDERGROUND_DEPTH := 320.0
const UNDERGROUND_TOP := Color(0.12, 0.11, 0.15)
const UNDERGROUND_BOTTOM := Color(0.26, 0.28, 0.34)
const UNDERGROUND_MARGIN := 1200.0
# Cuanto relleno deja ver la camara bajo el piso: poco, para que el encuadre
# le de el espacio al horizonte y no a la tierra (tampoco baja al caer a un pozo).
const CAMERA_BELOW_GROUND := 100.0

# Una de cada TUFT_EVERY celdas de suelo con aire encima lleva una mata.
const TUFT_EVERY := 3
const SWAY_STRENGTH := 1.2
const FOREGROUND_SWAY_STRENGTH := 2.0

const MOTES_AMOUNT := 40
const MOTES_AREA := Vector2(560, 300)
const FOG_AMOUNT := 22
const FOG_AREA := Vector2(700, 14)
const FOG_ALPHA_STABLE := 0.45
const MEMORY_SPARKS := 8

var _player: CharacterBody2D
var _player_light: PointLight2D
var _fog: CPUParticles2D
var _light_scale_target := PLAYER_LIGHT_SCALE_MAX
var _memory_lights: Array[PointLight2D] = []

var _light_texture: GradientTexture2D
var _puff_texture: GradientTexture2D
var _mote_texture: ImageTexture
var _sway_material: ShaderMaterial

func _ready() -> void:
	set_process(false)

func build(player: CharacterBody2D, foreground: CanvasItem) -> void:
	_player = player
	_build_shared_resources()
	var ambient := CanvasModulate.new()
	ambient.color = AMBIENT_COLOR
	add_child(ambient)
	AtmosphereKit.add_glow(self, GLOW_INTENSITY)

	var ground := get_tree().get_first_node_in_group("level_ground") as TileMapLayer
	var props := get_tree().get_first_node_in_group("level_props") as TileMapLayer
	var underground_top := _add_underground(ground)
	player.camera.limit_bottom = int(underground_top + CAMERA_BELOW_GROUND)
	_add_tufts(ground, props)
	for plant in get_tree().get_nodes_in_group("level_plants"):
		plant.material = _sway_material
	foreground.material = _foreground_sway_material()

	for memory in get_tree().get_nodes_in_group("level_memories"):
		_decorate_memory(memory)
	for bench in get_tree().get_nodes_in_group("checkpoints"):
		_decorate_bench(bench)

	_player_light = _make_light(PLAYER_LIGHT_COLOR, PLAYER_LIGHT_ENERGY, PLAYER_LIGHT_SCALE_MAX)
	_player_light.position = PLAYER_LIGHT_OFFSET
	player.add_child(_player_light)
	player.add_child(_motes())
	_fog = _make_fog()
	_fog.position.y = underground_top
	add_child(_fog)

	player.stability_changed.connect(_on_stability_changed)
	player.ability_unlocked.connect(_on_ability_unlocked)
	_on_stability_changed(player.stability, player.max_stability)
	_update_memory_glow()
	set_process(true)

func _process(delta: float) -> void:
	_player_light.texture_scale = lerpf(_player_light.texture_scale, _light_scale_target, 1.0 - exp(-PLAYER_LIGHT_FOLLOW_SPEED * delta))
	_fog.position.x = _player.global_position.x

func _on_stability_changed(current: float, max_value: float) -> void:
	var ratio := current / max_value
	_light_scale_target = lerpf(PLAYER_LIGHT_SCALE_MIN, PLAYER_LIGHT_SCALE_MAX, ratio)
	_fog.modulate.a = lerpf(1.0, FOG_ALPHA_STABLE, ratio)

func _on_ability_unlocked(_ability: String) -> void:
	_update_memory_glow()

# Cuantos mas recuerdos vuelven, mas llaman los que faltan.
func _update_memory_glow() -> void:
	var recovered := 0
	for ability in MemoryData.abilities_of([MemoryData.Kind.MEMORY]):
		if GameState.has_ability(ability):
			recovered += 1
	var energy := MEMORY_LIGHT_BASE_ENERGY + MEMORY_LIGHT_ENERGY_PER_RECOVERED * recovered
	for light in _memory_lights:
		if is_instance_valid(light):
			create_tween().tween_property(light, "energy", energy, 1.5)

func _build_shared_resources() -> void:
	_light_texture = AtmosphereKit.radial_texture(256, Color.WHITE)
	_puff_texture = AtmosphereKit.radial_texture(64, Color.WHITE)
	_mote_texture = AtmosphereKit.pixel_texture(2, Color.WHITE)
	_sway_material = ShaderMaterial.new()
	_sway_material.shader = SWAY_SHADER
	_sway_material.set_shader_parameter("strength", SWAY_STRENGTH)

func _foreground_sway_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SWAY_SHADER
	mat.set_shader_parameter("strength", FOREGROUND_SWAY_STRENGTH)
	return mat

func _make_light(color: Color, energy: float, texture_scale: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _light_texture
	light.color = color
	light.energy = energy
	light.texture_scale = texture_scale
	return light

# Devuelve la Y (mundo) donde empieza el relleno: el borde de abajo del piso
# mas bajo.
func _add_underground(ground: TileMapLayer) -> float:
	var used := ground.get_used_rect()
	var top := (used.end.y) * LevelLoader.CELL
	var left := used.position.x * LevelLoader.CELL - UNDERGROUND_MARGIN
	var width := used.size.x * LevelLoader.CELL + UNDERGROUND_MARGIN * 2.0
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([UNDERGROUND_TOP, UNDERGROUND_BOTTOM])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	texture.width = 4
	texture.height = 128
	var band := Sprite2D.new()
	band.texture = texture
	band.centered = false
	band.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	band.position = Vector2(left, top)
	band.scale = Vector2(width / texture.width, UNDERGROUND_DEPTH / texture.height)
	# Delante de las colinas del parallax y detras de los tiles y los props.
	band.z_index = -2
	add_child(band)
	return top

# Matas sobre el suelo firme, en la capa de props: aparecen con el Recuerdo
# de Vida, como el resto del detalle del mundo.
func _add_tufts(ground: TileMapLayer, props: TileMapLayer) -> void:
	for cell in ground.get_used_cells():
		if ground.get_cell_atlas_coords(cell) != LevelLoader.ATLAS.ground:
			continue
		if ground.get_cell_source_id(cell + Vector2i.UP) != -1:
			continue
		var roll := absi(cell.x * 7919 + cell.y * 104729)
		if roll % TUFT_EVERY != 0:
			continue
		var texture: Texture2D = TUFT_TEXTURES[(roll / TUFT_EVERY) % TUFT_TEXTURES.size()]
		var tuft := Sprite2D.new()
		tuft.texture = texture
		tuft.centered = false
		tuft.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tuft.material = _sway_material
		var size := texture.get_size()
		var tile := LevelLoader.CELL / props.scale.x
		# Los pies apoyan en el borde de arriba de la celda de suelo.
		tuft.position = Vector2((cell.x + 0.5) * tile - size.x / 2.0, cell.y * tile - size.y + 1.0)
		props.add_child(tuft)

# Las luces y chispas son hijas del recuerdo: si esta custodiado (oculto) o ya
# se recogio, se apagan con el.
func _decorate_memory(memory: Node2D) -> void:
	var light := _make_light(MEMORY_LIGHT_COLOR, MEMORY_LIGHT_BASE_ENERGY, MEMORY_LIGHT_SCALE)
	memory.add_child(light)
	_memory_lights.append(light)
	var halo := Sprite2D.new()
	halo.texture = _puff_texture
	halo.material = AtmosphereKit.additive_unshaded()
	halo.modulate = Color(MEMORY_LIGHT_COLOR, MEMORY_HALO_ALPHA)
	halo.scale = Vector2.ONE * MEMORY_HALO_SCALE
	halo.show_behind_parent = true
	memory.add_child(halo)
	var pulse := halo.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(halo, "scale", Vector2.ONE * MEMORY_HALO_SCALE * 1.25, MEMORY_PULSE_TIME)
	pulse.tween_property(halo, "scale", Vector2.ONE * MEMORY_HALO_SCALE, MEMORY_PULSE_TIME)
	memory.add_child(_memory_sparks())

func _decorate_bench(bench: Area2D) -> void:
	var light := _make_light(BENCH_LIGHT_COLOR, BENCH_LIGHT_IDLE_ENERGY, BENCH_LIGHT_SCALE)
	light.position = BENCH_LIGHT_OFFSET
	bench.add_child(light)
	bench.activated.connect(func() -> void:
		create_tween().tween_property(light, "energy", BENCH_LIGHT_ACTIVE_ENERGY, 0.6)
	)

# Motas que suben desde el recuerdo, como si algo se desprendiera de el.
func _memory_sparks() -> CPUParticles2D:
	var sparks := AtmosphereKit.particles(MEMORY_SPARKS, 1.8, _mote_texture)
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(12, 6)
	sparks.direction = Vector2(0, -1)
	sparks.spread = 20.0
	sparks.gravity = Vector2(0, -14)
	sparks.initial_velocity_min = 4.0
	sparks.initial_velocity_max = 12.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 1.6
	sparks.color_ramp = AtmosphereKit.fade_ramp(MEMORY_LIGHT_COLOR, 0.9)
	sparks.material = AtmosphereKit.additive_unshaded()
	return sparks

# Polvo en suspension alrededor del jugador, emitido en el mundo: las motas
# quedan flotando donde nacieron.
func _motes() -> CPUParticles2D:
	var motes := AtmosphereKit.particles(MOTES_AMOUNT, 7.0, _mote_texture)
	motes.local_coords = false
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = MOTES_AREA
	motes.direction = Vector2(1, -0.3)
	motes.spread = 70.0
	motes.gravity = Vector2(0, -2)
	motes.initial_velocity_min = 3.0
	motes.initial_velocity_max = 10.0
	motes.scale_amount_min = 0.8
	motes.scale_amount_max = 1.5
	motes.color_ramp = AtmosphereKit.fade_ramp(Color(0.85, 0.88, 1.0), 0.6)
	motes.material = AtmosphereKit.additive_unshaded()
	motes.z_index = 10
	return motes

# Niebla baja sobre el borde del piso; sigue al jugador en X.
func _make_fog() -> CPUParticles2D:
	var fog := AtmosphereKit.particles(FOG_AMOUNT, 6.0, _puff_texture)
	fog.local_coords = false
	fog.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fog.emission_rect_extents = FOG_AREA
	fog.direction = Vector2(1, 0)
	fog.spread = 15.0
	fog.gravity = Vector2.ZERO
	fog.initial_velocity_min = 4.0
	fog.initial_velocity_max = 10.0
	fog.scale_amount_min = 2.5
	fog.scale_amount_max = 4.5
	fog.color_ramp = AtmosphereKit.fade_ramp(Color(0.72, 0.74, 0.82), 0.16)
	fog.z_index = 1
	return fog
