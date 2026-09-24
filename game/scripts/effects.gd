class_name Effects
# Rafagas de una sola vez para el combate: se crean en el mundo, se disparan
# y se liberan solas al terminar. Viven en el padre que se pase (el nivel),
# asi sobreviven al nodo que las provoco.

const HIT_DUST_COLOR := Color(0.86, 0.85, 0.92)
const HIT_SPARK_COLOR := Color(1.0, 0.95, 0.85)
const POP_RING_TIME := 0.28
const POP_RING_SCALE := Vector2(0.3, 0.3)
const POP_RING_END_SCALE := Vector2(1.5, 1.5)
const STUN_STAR_COLOR := Color(1.0, 0.9, 0.5)
const STUN_STARS := 3
const STUN_ORBIT := Vector2(20, 6)
# Mismo tamano de pixel que los tiles del nivel.
const STUN_STAR_PIXEL := 2.0
const STUN_TURN_TIME := 0.7

static var _puff_texture: GradientTexture2D
static var _spark_texture: ImageTexture
static var _ring_texture: GradientTexture2D
static var _star_texture: ImageTexture

# Polvo y chispas que salen hacia donde iba el golpe: el impacto empuja aire.
static func hit_dust(parent: Node, at: Vector2, direction: float) -> void:
	_ensure_textures()
	var dust := _burst(16, 0.4, _puff_texture)
	dust.direction = Vector2(direction, -0.35)
	dust.spread = 70.0
	dust.initial_velocity_min = 60.0
	dust.initial_velocity_max = 140.0
	dust.damping_min = 180.0
	dust.damping_max = 260.0
	dust.gravity = Vector2(0, 120)
	dust.scale_amount_min = 0.8
	dust.scale_amount_max = 1.6
	dust.color_ramp = _impact_ramp(HIT_DUST_COLOR, 0.85)
	_spawn(parent, dust, at)
	var sparks := _burst(9, 0.25, _spark_texture)
	sparks.direction = Vector2(direction, -0.2)
	sparks.spread = 35.0
	sparks.initial_velocity_min = 140.0
	sparks.initial_velocity_max = 220.0
	sparks.gravity = Vector2.ZERO
	sparks.color_ramp = _impact_ramp(HIT_SPARK_COLOR, 1.0)
	sparks.material = AtmosphereKit.additive_unshaded()
	_spawn(parent, sparks, at)

# Como un globo que revienta: un anillo que se abre y motas en todas direcciones.
static func pop(parent: Node, at: Vector2, color: Color) -> void:
	_ensure_textures()
	var motes := _burst(22, 0.5, _spark_texture)
	motes.direction = Vector2.UP
	motes.spread = 180.0
	motes.initial_velocity_min = 90.0
	motes.initial_velocity_max = 190.0
	motes.damping_min = 160.0
	motes.damping_max = 240.0
	motes.gravity = Vector2(0, 60)
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 2.0
	motes.color_ramp = _impact_ramp(color, 1.0)
	motes.material = AtmosphereKit.additive_unshaded()
	_spawn(parent, motes, at)
	var ring := Sprite2D.new()
	ring.texture = _ring_texture
	ring.modulate = color
	ring.scale = POP_RING_SCALE
	ring.material = AtmosphereKit.additive_unshaded()
	ring.global_position = at
	ring.z_index = 5
	parent.add_child(ring)
	var tween := ring.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", POP_RING_END_SCALE, POP_RING_TIME)
	tween.tween_property(ring, "modulate:a", 0.0, POP_RING_TIME)
	tween.chain().tween_callback(ring.queue_free)

# Nace solida y solo se apaga al final: el golpe congela el tiempo justo al
# nacer, y una rampa que aparece desde transparente la dejaria invisible
# durante todo el congelado, que es cuando mas se tiene que ver.
static func _impact_ramp(color: Color, peak_alpha: float) -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var solid := Color(color, peak_alpha)
	ramp.colors = PackedColorArray([solid, solid, Color(color, 0.0)])
	return ramp

# Estrellitas que giran sobre la cabeza mientras dure el aturdimiento: la
# ventana para pegarle se ve, no solo se adivina. Cuelgan del que se aturde,
# asi desaparecen con el si muere antes.
static func stun_stars(owner: Node2D, head: Vector2, duration: float) -> Node2D:
	_ensure_textures()
	var orbit := Node2D.new()
	orbit.position = head
	orbit.z_index = 5
	var stars: Array[Sprite2D] = []
	for i in range(STUN_STARS):
		var star := Sprite2D.new()
		star.texture = _star_texture
		star.modulate = STUN_STAR_COLOR
		star.material = AtmosphereKit.additive_unshaded()
		orbit.add_child(star)
		stars.append(star)
	owner.add_child(orbit)
	var place := func(turn: float) -> void:
		for i in range(stars.size()):
			var angle := TAU * (turn + float(i) / stars.size())
			stars[i].position = Vector2(cos(angle), sin(angle)) * STUN_ORBIT
			# La de atras se ve mas chica y apagada: da profundidad a la orbita.
			var near := (sin(angle) + 1.0) * 0.5
			stars[i].scale = Vector2.ONE * STUN_STAR_PIXEL * lerpf(0.7, 1.15, near)
			stars[i].modulate.a = lerpf(0.5, 1.0, near)
	var turns := orbit.create_tween()
	turns.tween_method(place, 0.0, duration / STUN_TURN_TIME, duration)
	turns.tween_callback(orbit.queue_free)
	return orbit

static func _burst(amount: int, lifetime: float, texture: Texture2D) -> CPUParticles2D:
	var burst := AtmosphereKit.particles(amount, lifetime, texture)
	# Una rafaga nace en el momento del golpe: sin la simulacion previa del
	# ambiente, que la haria aparecer ya terminada.
	burst.preprocess = 0.0
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.local_coords = false
	burst.z_index = 5
	return burst

static func _spawn(parent: Node, burst: CPUParticles2D, at: Vector2) -> void:
	parent.add_child(burst)
	burst.global_position = at
	burst.finished.connect(burst.queue_free)
	burst.emitting = true

static func _ensure_textures() -> void:
	if _puff_texture:
		return
	_puff_texture = AtmosphereKit.radial_texture(16, Color.WHITE)
	_spark_texture = AtmosphereKit.pixel_texture(2, Color.WHITE)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.62, 0.8, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color.WHITE, Color(1, 1, 1, 0)])
	_ring_texture = GradientTexture2D.new()
	_ring_texture.gradient = gradient
	_ring_texture.fill = GradientTexture2D.FILL_RADIAL
	_ring_texture.fill_from = Vector2(0.5, 0.5)
	_ring_texture.fill_to = Vector2(1.0, 0.5)
	_ring_texture.width = 64
	_ring_texture.height = 64
	# Destello en cruz de 5x5, al tamano de pixel del pack.
	var star := Image.create(5, 5, false, Image.FORMAT_RGBA8)
	for i in range(5):
		star.set_pixel(2, i, Color.WHITE)
		star.set_pixel(i, 2, Color.WHITE)
	_star_texture = ImageTexture.create_from_image(star)
