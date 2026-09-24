extends Node
# Consumidor de `ability_unlocked`: traduce cada recuerdo en una etapa visual y
# sonora (seccion 15 del documento base). No toca la geometria del nivel;
# solo el post-proceso de Core, el parallax, la capa de props y las capas de
# audio. El punto de partida (gris y frio) es el look del Nivel 1.

const STAGE_TWEEN := 1.8
const STABILITY_SHAKE_STRENGTH := 4.0
const STABILITY_SHAKE_TIME := 0.32

# Expulsion: el color, el parallax y las capas de audio se van apagando en
# orden inverso al que aparecieron, a medida que baja la Estabilidad.
const EXPULSION_MIN_SATURATION := 0.03
const EXPULSION_VIGNETTE_START := 0.4
const EXPULSION_LAYER_CUTS := {
	"melody": 0.8,
	"pad": 0.55,
	"hum": 0.3,
}
const EXPULSION_SILENT_DB := -60.0
const COLLAPSE_FADE_TIME := 2.5
const COLLAPSE_THOUGHT_HOLD := 6.0

# Cada tramo de Estabilidad perdida: un pensamiento (preguntas, no
# explicaciones). Qué recuerdo se apaga en el HUD en cada tramo viene de
# `MemoryData.LIST[ability].fades_at`, en orden inverso al que se ganaron.
const EXPULSION_BEATS := [
	{"ratio": 1.0, "thought": "Algo cambió. No sé qué."},
	{"ratio": 0.75, "thought": "El aire se siente distinto. Más quieto."},
	{"ratio": 0.5, "thought": "Conozco este camino. ¿Por qué me cuesta?"},
	{"ratio": 0.25, "thought": "Los colores se están yendo. ¿Siempre fue tan gris?"},
	{"ratio": 0.0, "thought": "La puerta está ahí. Pero cada paso la aleja."},
]

@export var parallax: Node2D
# Pasto de primer plano: aparece con los props, cuando el mundo recupera detalle.
@export var foreground: CanvasItem

var _player: Node2D
var _world_material: ShaderMaterial
var _props_layer: CanvasItem
var _audio: Node
var _focus_active := false
var _base_vignette := 0.0
var _expelling := false
var _cut_layers := {}
var _beats_fired := 0
var _dimmed_abilities := {}

func _ready() -> void:
	if parallax:
		parallax.modulate.a = 0.0
	if foreground:
		foreground.modulate.a = 0.0

func setup(player: Node2D, props_layer: CanvasItem, audio: Node, world_material: ShaderMaterial) -> void:
	_player = player
	_world_material = world_material
	_props_layer = props_layer
	_audio = audio
	if _props_layer:
		_props_layer.modulate.a = 0.0
	if _audio:
		_audio.set_layer("wind", -14.0, 0.1)
	player.stability_changed.connect(_on_stability_changed)
	player.low_stability_changed.connect(_on_low_stability_changed)
	player.health_changed.connect(_on_health_changed)

func _process(_delta: float) -> void:
	if _focus_active and _player:
		var screen_pos: Vector2 = _player.get_viewport().get_canvas_transform() * _player.global_position
		_set_param("focus_center", screen_pos)

func advance_to(stage: String) -> void:
	match stage:
		"jump":
			_focus_active = true
			_tween("focus_radius", 230.0)
			if _audio:
				_audio.set_layer("hum", -22.0, 3.0)
		"stability":
			_pulse_vignette()
			_shake_camera()
		"sprint":
			_tween("focus_radius", 650.0)
			if parallax:
				create_tween().tween_property(parallax, "modulate:a", 1.0, 2.5)
			if _audio:
				_audio.set_layer("hum", -14.0, 3.0)
		"health":
			_focus_active = false
			_tween("focus_radius", 0.0)
			_tween("saturation", 0.85)
			if _props_layer:
				create_tween().tween_property(_props_layer, "modulate:a", 1.0, 2.5)
			if foreground:
				create_tween().tween_property(foreground, "modulate:a", 1.0, 2.5)
			if _audio:
				_audio.set_layer("pad", -16.0, 4.0)
		"attack":
			_tween("saturation", 1.0)
			_tween("cold_tint", 0.35)
			if _audio:
				_audio.set_layer("melody", -14.0, 4.0)

func begin_expulsion() -> void:
	_expelling = true
	_focus_active = false
	_set_param("focus_radius", 0.0)
	_advance_beats(1.0)

func collapse() -> void:
	Events.thought_requested.emit("Todavía no estoy listo.", COLLAPSE_THOUGHT_HOLD)
	var layer := CanvasLayer.new()
	# Debajo del HUD: el pensamiento final se lee sobre el negro.
	layer.layer = Core.WORLD_OVERLAY_LAYER
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.anchor_right = 1.0
	black.anchor_bottom = 1.0
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.modulate.a = 0.0
	layer.add_child(black)
	add_child(layer)
	create_tween().tween_property(black, "modulate:a", 1.0, COLLAPSE_FADE_TIME)
	if _audio:
		_audio.silence_all(COLLAPSE_FADE_TIME)

func _advance_beats(ratio: float) -> void:
	while _beats_fired < EXPULSION_BEATS.size() and ratio <= EXPULSION_BEATS[_beats_fired].ratio:
		Events.thought_requested.emit(EXPULSION_BEATS[_beats_fired].thought, Events.DEFAULT_THOUGHT_HOLD)
		_beats_fired += 1
	for ability in GameState.abilities:
		var fades_at: float = MemoryData.LIST[ability].fades_at
		if fades_at != MemoryData.NO_FADE and ratio <= fades_at and not _dimmed_abilities.has(ability):
			_dimmed_abilities[ability] = true
			Events.memory_dimmed.emit(ability)

func _apply_expulsion(ratio: float) -> void:
	_advance_beats(ratio)
	_set_param("saturation", lerpf(EXPULSION_MIN_SATURATION, 1.0, ratio))
	_set_param("cold_tint", lerpf(1.0, 0.35, ratio))
	_set_param("vignette", lerpf(EXPULSION_VIGNETTE_START, _base_vignette, ratio))
	if parallax:
		parallax.modulate.a = ratio
	if not _audio:
		return
	for layer_name in EXPULSION_LAYER_CUTS:
		if ratio < EXPULSION_LAYER_CUTS[layer_name] and not _cut_layers.has(layer_name):
			_cut_layers[layer_name] = true
			_audio.set_layer(layer_name, EXPULSION_SILENT_DB, 3.0)

# Ya sin Estabilidad, perder Vida cierra la viñeta hacia el desmayo.
func _on_health_changed(current: int, max_value: int) -> void:
	if not _expelling or max_value <= 0:
		return
	var lost := 1.0 - float(current) / float(max_value)
	_set_param("vignette", lerpf(EXPULSION_VIGNETTE_START, 0.95, lost))

func _on_stability_changed(current: float, max_value: float) -> void:
	if _expelling:
		_apply_expulsion(current / max_value)

# El jugador es el unico dueno del umbral (GameState.is_low_stability): acá
# solo reaccionamos al cruce, ya no lo recalculamos.
func _on_low_stability_changed(is_low: bool) -> void:
	if not _expelling:
		_tween("vignette", 0.45 if is_low else _base_vignette, 0.8)
	if _audio:
		_audio.set_muffled(is_low)

func _pulse_vignette() -> void:
	_base_vignette = 0.15
	_tween("vignette", 0.55, 0.5).tween_callback(_tween.bind("vignette", _base_vignette, 1.6))

func _shake_camera() -> void:
	if _player:
		_player.camera.shake(STABILITY_SHAKE_STRENGTH, STABILITY_SHAKE_TIME)

func _set_param(param: String, value) -> void:
	_world_material.set_shader_parameter(param, value)

func _tween(param: String, target: float, time: float = STAGE_TWEEN) -> Tween:
	var from: float = _world_material.get_shader_parameter(param)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _world_material.set_shader_parameter(param, v), from, target, time)
	return tween
