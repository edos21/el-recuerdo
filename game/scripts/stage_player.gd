class_name StagePlayer
extends CharacterBody2D
# Protagonista del escenario fijo (el recuerdo de Tomás): solo camina a
# izquierda y derecha, sin saltar (cada recuerdo se juega con las reglas de
# quien lo recordaba). Comparte con los otros jugadores lo que el resto del
# juego necesita: señales de Vida/Estabilidad para el HUD y el grupo "player".

signal health_changed(current: int, max_value: int)
signal stability_changed(current: float, max_value: float)
signal low_stability_changed(is_low: bool)

const SPEED := 170.0
const BODY_HEIGHT_TEXELS := 24.0
const BODY_WIDTH := 26.0

var max_health := GameState.MAX_HEALTH
var health: int:
	get:
		return GameState.health
var stability: float:
	get:
		return GameState.stability
var max_stability: float:
	get:
		return GameState.max_stability

# Hasta dónde llega el cuerpo: el escenario no tiene paredes físicas en los bordes.
var min_x := 0.0
var max_x := 0.0

var _last_health := -1
var _last_stability := -1.0
var _last_max_stability := -1.0
var _low_stability := false
var _facing := 1
var _locked := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	GameState.ensure_defaults()
	GameState.vitals_changed.connect(_emit_vitals)
	CharacterScale.place_sprite(sprite, CharacterScale.PLATFORMER)
	CharacterScale.fit_height($CollisionShape2D, BODY_HEIGHT_TEXELS, CharacterScale.PLATFORMER)
	_emit_vitals()

# Mismo contrato que los otros jugadores, salvo que acá solo se emite lo que
# cambió: la Estabilidad se mueve casi todos los cuadros y cada emisión de la
# Vida reiniciaría la animación de su barra sin motivo. El umbral de
# Estabilidad baja se avisa solo al cruzarlo (reemitirlo reinicia el parpadeo
# del HUD).
func _emit_vitals() -> void:
	if health != _last_health:
		_last_health = health
		health_changed.emit(health, max_health)
	if not is_equal_approx(stability, _last_stability) or not is_equal_approx(max_stability, _last_max_stability):
		_last_stability = stability
		_last_max_stability = max_stability
		stability_changed.emit(stability, max_stability)
	var low := GameState.is_low_stability(stability, max_stability)
	if low != _low_stability:
		_low_stability = low
		low_stability_changed.emit(low)

func set_locked(locked: bool) -> void:
	_locked = locked

func _physics_process(_delta: float) -> void:
	var direction := 0.0 if _locked else Input.get_axis("move_left", "move_right")
	velocity = Vector2(direction * SPEED, 0.0)
	move_and_slide()
	position.x = clampf(position.x, min_x + BODY_WIDTH * 0.5, max_x - BODY_WIDTH * 0.5)
	if direction != 0.0:
		_facing = 1 if direction > 0.0 else -1
	sprite.flip_h = _facing < 0
	sprite.play("run" if direction != 0.0 else "idle")
