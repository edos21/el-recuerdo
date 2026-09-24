class_name AtmosphereKit
# Piezas comunes de las capas de atmosfera (pueblo, Nivel 1): texturas
# generadas, fabrica de particulas y el glow. Cada escena decide la paleta y
# que decora; esto solo evita reescribir lo mismo en cada una.

const GLOW_INTENSITY := 0.7
const GLOW_BLOOM := 0.04
const GLOW_THRESHOLD := 0.88
const SWAY_SHADER := preload("res://shaders/wind_sway.gdshader")

# Un solo material aditivo para todos: el batcher 2D agrupa lo que lo comparte.
static var _additive: CanvasItemMaterial

# Solo las capas del mundo brillan: el HUD queda fuera (ver Core).
static func add_glow(parent: Node, intensity: float = GLOW_INTENSITY) -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = Core.WORLD_MAX_CANVAS_LAYER
	env.glow_enabled = true
	env.glow_intensity = intensity
	env.glow_bloom = GLOW_BLOOM
	env.glow_hdr_threshold = GLOW_THRESHOLD
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	parent.add_child(world_env)
	return world_env

static func add_ambient(parent: Node, color: Color) -> void:
	var ambient := CanvasModulate.new()
	ambient.color = color
	parent.add_child(ambient)

static func point_light(texture: Texture2D, color: Color, energy: float, texture_scale: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = texture
	light.color = color
	light.energy = energy
	light.texture_scale = texture_scale
	return light

static func sway_material(strength: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SWAY_SHADER
	mat.set_shader_parameter("strength", strength)
	return mat

static func particles(amount: int, lifetime: float, texture: Texture2D) -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.amount = amount
	emitter.lifetime = lifetime
	emitter.preprocess = lifetime
	emitter.texture = texture
	emitter.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return emitter

# Aparece, se sostiene y se apaga: ninguna particula nace o muere de golpe.
static func fade_ramp(color: Color, peak_alpha: float) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.75, 1.0])
	var clear := Color(color, 0.0)
	var solid := Color(color, peak_alpha)
	ramp.colors = PackedColorArray([clear, solid, solid, clear])
	return ramp

static func additive_unshaded() -> CanvasItemMaterial:
	if not _additive:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _additive

static func radial_texture(size: int, center: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([center, Color(center, 0.0)])
	return radial_texture_from(gradient, size)

static func radial_texture_from(gradient: Gradient, size: int) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = size
	texture.height = size
	return texture

static func pixel_texture(size: int, color: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
