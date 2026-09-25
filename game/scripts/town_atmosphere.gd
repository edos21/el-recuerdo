extends Node2D
# Capa de atmosfera del pueblo (prototipo de "look moderno"): luz de tarde,
# glow, sombras de contacto, viento en los arboles y particulas de ambiente.
# El post-proceso es el de Core (looks/town_look.tres). No toca la logica del
# pueblo: lee lo que arma town_loader (grupos town_trees, town_houses,
# town_characters).

const WINDOWS_SHADER := preload("res://shaders/house_windows.gdshader")

# Tarde dorada: la luz ambiente baja un poco para que las luces propias se noten.
const AMBIENT_COLOR := Color(0.86, 0.80, 0.74)
const HOUSE_LIGHT_COLOR := Color(1.0, 0.68, 0.36)
const HOUSE_LIGHT_ENERGY := 0.45
const HOUSE_LIGHT_SCALE := 1.1
const PLAYER_LIGHT_ENERGY := 0.25
const PLAYER_LIGHT_SCALE := 2.4
# Mismo valor que el default del shader: las copas ya estaban afinadas con el.
const SWAY_STRENGTH := 1.6

const CONTACT_SHADOW_SIZE := Vector2(34, 12)
const CONTACT_SHADOW_ALPHA := 0.42
const HOUSE_SHADOW_ALPHA := 0.28

const MOTES_AMOUNT := 70
const MOTES_AREA := Vector2(620, 380)
const LEAVES_PER_TREE := 2
# Copa del arbol en px de mundo, relativa a sus pies.
const CANOPY_CENTER := Vector2(0, -150)
const CANOPY_EXTENTS := Vector2(56, 40)

# Recursos compartidos: todas las casas, arboles y personajes usan la misma
# instancia (menos texturas en GPU y el batcher 2D puede agrupar los dibujos).
var _light_texture: GradientTexture2D
var _shadow_texture: GradientTexture2D
var _puff_texture: GradientTexture2D
var _leaf_texture: ImageTexture
var _sway_material: ShaderMaterial
# Un material por mascara: cada variante de casa tiene sus propias ventanas.
var _windows_materials: Dictionary = {}

func build(player: CharacterBody2D) -> void:
	_build_shared_resources()
	AtmosphereKit.add_ambient(self, AMBIENT_COLOR)
	AtmosphereKit.add_glow(self)
	for tree in get_tree().get_nodes_in_group("town_trees"):
		_decorate_tree(tree)
	for house in get_tree().get_nodes_in_group("town_houses"):
		_decorate_house(house)
	for character in get_tree().get_nodes_in_group("town_characters"):
		var shadow := _contact_shadow()
		character.add_child(shadow)
		character.move_child(shadow, 0)
	player.add_child(_player_light())
	player.add_child(_motes())

func _build_shared_resources() -> void:
	_light_texture = AtmosphereKit.radial_texture(256, Color.WHITE)
	_shadow_texture = AtmosphereKit.radial_texture(64, Color(0.04, 0.03, 0.10, CONTACT_SHADOW_ALPHA))
	_puff_texture = AtmosphereKit.radial_texture(32, Color.WHITE)
	_leaf_texture = _make_leaf_texture()
	_sway_material = AtmosphereKit.sway_material(SWAY_STRENGTH)

func _decorate_tree(tree: Sprite2D) -> void:
	tree.material = _sway_material
	var leaves := _leaves()
	leaves.position = tree.position + CANOPY_CENTER
	add_child(leaves)

func _windows_material(mask: Texture2D) -> ShaderMaterial:
	if not _windows_materials.has(mask):
		var material := ShaderMaterial.new()
		material.shader = WINDOWS_SHADER
		material.set_shader_parameter("window_mask", mask)
		_windows_materials[mask] = material
	return _windows_materials[mask]

# Los anclajes de HouseLayout van en px de textura; la casa se dibuja escalada.
func _decorate_house(house: Sprite2D) -> void:
	house.material = _windows_material(house.get_meta(TownLoader.WINDOW_MASK_META))
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array(HouseLayout.SHADOW)
	shadow.color = Color(0.05, 0.04, 0.12, HOUSE_SHADOW_ALPHA)
	shadow.show_behind_parent = true
	house.add_child(shadow)
	var light := AtmosphereKit.point_light(_light_texture, HOUSE_LIGHT_COLOR, HOUSE_LIGHT_ENERGY, HOUSE_LIGHT_SCALE)
	light.position = house.position + HouseLayout.LIGHT * house.scale
	add_child(light)
	var smoke := _smoke()
	smoke.position = house.position + HouseLayout.CHIMNEY * house.scale
	add_child(smoke)

func _contact_shadow() -> Sprite2D:
	var shadow := Sprite2D.new()
	shadow.texture = _shadow_texture
	shadow.scale = CONTACT_SHADOW_SIZE / 64.0
	shadow.show_behind_parent = true
	return shadow

func _player_light() -> PointLight2D:
	var light := AtmosphereKit.point_light(_light_texture, Color(1.0, 0.9, 0.75), PLAYER_LIGHT_ENERGY, PLAYER_LIGHT_SCALE)
	light.position = Vector2(0, -20)
	return light

# Polen/polvo en suspension alrededor del jugador: se emite en el mundo, asi
# que las particulas quedan flotando donde nacieron cuando el jugador se aleja.
func _motes() -> CPUParticles2D:
	var motes := AtmosphereKit.particles(MOTES_AMOUNT, 7.0, AtmosphereKit.pixel_texture(2, Color.WHITE))
	motes.local_coords = false
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = MOTES_AREA
	motes.direction = Vector2(1, -0.4)
	motes.spread = 70.0
	motes.gravity = Vector2(0, -3)
	motes.initial_velocity_min = 3.0
	motes.initial_velocity_max = 12.0
	motes.scale_amount_min = 0.8
	motes.scale_amount_max = 1.8
	motes.color_ramp = AtmosphereKit.fade_ramp(Color(1.0, 0.92, 0.65), 0.85)
	motes.material = AtmosphereKit.additive_unshaded()
	motes.z_index = 10
	return motes

func _leaves() -> CPUParticles2D:
	var leaves := AtmosphereKit.particles(LEAVES_PER_TREE, 5.0, _leaf_texture)
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = CANOPY_EXTENTS
	leaves.gravity = Vector2(10, 22)
	leaves.initial_velocity_min = 4.0
	leaves.initial_velocity_max = 14.0
	leaves.angular_velocity_min = -120.0
	leaves.angular_velocity_max = 120.0
	leaves.angle_min = 0.0
	leaves.angle_max = 360.0
	leaves.scale_amount_min = 2.0
	leaves.scale_amount_max = 2.0
	leaves.color_ramp = AtmosphereKit.fade_ramp(Color.WHITE, 1.0)
	leaves.z_index = 10
	return leaves

func _smoke() -> CPUParticles2D:
	var smoke := AtmosphereKit.particles(10, 4.5, _puff_texture)
	smoke.direction = Vector2(0.3, -1)
	smoke.spread = 12.0
	smoke.gravity = Vector2(7, -6)
	smoke.initial_velocity_min = 10.0
	smoke.initial_velocity_max = 16.0
	smoke.scale_amount_min = 0.5
	smoke.scale_amount_max = 0.8
	var growth := Curve.new()
	growth.max_value = 2.0
	growth.add_point(Vector2(0, 0.4))
	growth.add_point(Vector2(1, 1.8))
	smoke.scale_amount_curve = growth
	smoke.color_ramp = AtmosphereKit.fade_ramp(Color(0.85, 0.82, 0.80), 0.35)
	smoke.z_index = 10
	return smoke

# Hoja de 3x2 px en dos verdes, a la escala del pixel art del pack.
func _make_leaf_texture() -> ImageTexture:
	var image := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	var light := Color(0.55, 0.78, 0.30)
	var dark := Color(0.28, 0.52, 0.22)
	image.set_pixel(0, 0, light)
	image.set_pixel(1, 0, light)
	image.set_pixel(1, 1, dark)
	image.set_pixel(2, 1, dark)
	return ImageTexture.create_from_image(image)
