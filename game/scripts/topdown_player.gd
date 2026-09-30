extends CharacterBody2D
# Protagonista en vista cenital. Comparte con el de plataformas lo que el
# resto del juego necesita (senales de Vida/Estabilidad para el HUD, grupo
# "player", accion `interact`), pero no la fisica: sin gravedad ni saltos.

signal health_changed(current: int, max_value: int)
signal stability_changed(current: float, max_value: float)
signal low_stability_changed(is_low: bool)

const SPEED := 150.0
const CAMERA_ZOOM := 1.5
# La camara mira un poco hacia donde camina el jugador, y vuelve sola al parar.
const CAMERA_LOOKAHEAD := 48.0
const CAMERA_LOOKAHEAD_SPEED := 2.5
# Rebote al caminar: el sprite de 4 cuadros se siente mas vivo con un poco de
# squash & stretch sincronizado con los pasos.
const STEP_BOB_HEIGHT := 2.0
const STEP_SQUASH := 0.06
const STEP_FREQUENCY := 11.0
const STEP_SETTLE_SPEED := 12.0

var max_health := GameState.MAX_HEALTH
# En el hub la Vida y la Estabilidad son de GameState (beats, descanso): el
# jugador solo las expone con la misma interfaz que el de plataformas.
var health: int:
	get:
		return GameState.health
var stability: float:
	get:
		return GameState.stability
var max_stability: float:
	get:
		return GameState.max_stability

var _low_stability := false

var _facing := "down"
# Bloqueado (una escena guionada): no camina ni interactúa, pero sigue vivo
# (animación, cámara, puede girar con face()).
var _locked := false
var _step_time := 0.0
var _base_scale: Vector2
var _base_offset: Vector2
var _base_camera: Vector2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea
@onready var camera: Camera2D = $Camera2D
@onready var dust: CPUParticles2D = $Dust

func _ready() -> void:
	GameState.ensure_defaults()
	GameState.vitals_changed.connect(_emit_vitals)
	camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	_base_scale = sprite.scale
	_base_offset = sprite.position
	_base_camera = camera.position
	_emit_vitals()

# Unico punto que emite health_changed y stability_changed, con el mismo
# contrato que player.gd: el umbral de Estabilidad baja se avisa solo al
# cruzarlo (reemitirlo reinicia el parpadeo del HUD).
func _emit_vitals() -> void:
	health_changed.emit(health, max_health)
	stability_changed.emit(stability, max_stability)
	var low := GameState.is_low_stability(stability, max_stability)
	if low != _low_stability:
		_low_stability = low
		low_stability_changed.emit(low)

func set_locked(locked: bool) -> void:
	_locked = locked

func is_locked() -> bool:
	return _locked

func face(direction: String) -> void:
	_facing = direction
	sprite.play("idle_" + _facing)

func set_camera_limits(bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO if _locked else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()
	var walking := direction != Vector2.ZERO
	if walking:
		_facing = Facing.from_direction(direction)
		sprite.play("walk_" + _facing)
	else:
		sprite.play("idle_" + _facing)
	_animate_step(walking, delta)
	dust.emitting = walking
	var target := _base_camera + direction * CAMERA_LOOKAHEAD
	camera.position = camera.position.lerp(target, 1.0 - exp(-CAMERA_LOOKAHEAD_SPEED * delta))

func _animate_step(walking: bool, delta: float) -> void:
	if not walking:
		_step_time = 0.0
		var settle := 1.0 - exp(-STEP_SETTLE_SPEED * delta)
		sprite.scale = sprite.scale.lerp(_base_scale, settle)
		sprite.position = sprite.position.lerp(_base_offset, settle)
		return
	_step_time += delta * STEP_FREQUENCY
	var bounce := absf(sin(_step_time))
	sprite.position = _base_offset + Vector2(0, -bounce * STEP_BOB_HEIGHT)
	var squash := (1.0 - bounce) * STEP_SQUASH
	sprite.scale = _base_scale * Vector2(1.0 + squash, 1.0 - squash)


func _unhandled_input(event: InputEvent) -> void:
	if _locked or not event.is_action_pressed("interact"):
		return
	var target := _nearest_interactable()
	if target:
		get_viewport().set_input_as_handled()
		target.interact(self)

func _nearest_interactable() -> Node:
	var nearest: Node = null
	var best := INF
	for area in interact_area.get_overlapping_areas():
		var owner_node := area.get_parent()
		if not owner_node.has_method("interact"):
			continue
		var distance := global_position.distance_squared_to(owner_node.global_position)
		if distance < best:
			best = distance
			nearest = owner_node
	return nearest
