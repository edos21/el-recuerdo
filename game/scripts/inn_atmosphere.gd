extends TopDownAtmosphere
# Capa de atmósfera del interior de la posada: penumbra cálida, el fuego de la
# olla como luz principal y el polvo que flota adentro. Lee lo que arma
# interior_loader (grupos inn_pot y town_characters); no toca la lógica.

const AMBIENT_COLOR := Color(0.62, 0.52, 0.46)
const FIRE_COLOR := Color(1.0, 0.58, 0.28)
const FIRE_ENERGY := 0.9
const FIRE_SCALE := 1.6
const FIRE_OFFSET := Vector2(0, -18)
const FIRE_FLICKER := 0.12
const FIRE_FLICKER_TIME := 0.18
const PLAYER_LIGHT_ENERGY := 0.3
const PLAYER_LIGHT_SCALE := 1.8
const CONTACT_SHADOW_SIZE := Vector2(34, 12)
const CONTACT_SHADOW_ALPHA := 0.5
const DUST_AMOUNT := 30

var _light_texture: GradientTexture2D
var _shadow_texture: GradientTexture2D

func build(player: CharacterBody2D, room: Rect2) -> void:
	_light_texture = AtmosphereKit.radial_texture(256, Color.WHITE)
	_shadow_texture = AtmosphereKit.radial_texture(64, Color(0.04, 0.03, 0.10, CONTACT_SHADOW_ALPHA))
	AtmosphereKit.add_ambient(self, AMBIENT_COLOR)
	AtmosphereKit.add_glow(self)
	for pot in get_tree().get_nodes_in_group(&"inn_pot"):
		_add_fire(pot)
	AtmosphereKit.add_contact_shadows(get_tree().get_nodes_in_group(TopDownLoader.CHARACTERS_GROUP), _shadow_texture, CONTACT_SHADOW_SIZE)
	player.add_child(AtmosphereKit.player_light(_light_texture, PLAYER_LIGHT_ENERGY, PLAYER_LIGHT_SCALE))
	add_child(_dust(room))

# El fuego titila: la única luz fuerte del cuarto no puede quedarse quieta.
func _add_fire(pot: Node2D) -> void:
	var light := AtmosphereKit.point_light(_light_texture, FIRE_COLOR, FIRE_ENERGY, FIRE_SCALE)
	light.position = pot.position + FIRE_OFFSET
	add_child(light)
	var tween := create_tween().set_loops()
	tween.tween_property(light, "energy", FIRE_ENERGY + FIRE_FLICKER, FIRE_FLICKER_TIME)
	tween.tween_property(light, "energy", FIRE_ENERGY - FIRE_FLICKER, FIRE_FLICKER_TIME)

# Polvo en la luz, quieto en el cuarto (no sigue al jugador como el polen de afuera).
func _dust(room: Rect2) -> CPUParticles2D:
	var dust := AtmosphereKit.particles(DUST_AMOUNT, 9.0, AtmosphereKit.pixel_texture(2, Color.WHITE))
	dust.position = room.get_center()
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = room.size * 0.5 - Vector2(TopDownLoader.CELL, TopDownLoader.CELL)
	dust.direction = Vector2(0.3, -1)
	dust.spread = 60.0
	dust.gravity = Vector2(0, -1)
	dust.initial_velocity_min = 1.0
	dust.initial_velocity_max = 5.0
	dust.color_ramp = AtmosphereKit.fade_ramp(Color(1.0, 0.85, 0.6), 0.6)
	dust.material = AtmosphereKit.additive_unshaded()
	dust.z_index = 10
	return dust
