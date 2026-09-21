extends CharacterBody2D
# Protagonista en vista cenital. Comparte con el de plataformas lo que el
# resto del juego necesita (senales de Vida/Estabilidad para el HUD, grupo
# "player", accion `interact`), pero no la fisica: sin gravedad ni saltos.

signal health_changed(current: int, max_value: int)
signal stability_changed(current: float, max_value: float)

const SPEED := 130.0
const CAMERA_ZOOM := 1.5

var health: int
var max_health := GameState.MAX_HEALTH
var stability: float
var max_stability: float

var _facing := "down"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	GameState.ensure_defaults()
	health = GameState.health
	max_stability = GameState.max_stability
	stability = GameState.stability
	camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	health_changed.emit(health, max_health)
	stability_changed.emit(stability, max_stability)

func set_camera_limits(bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()
	if direction != Vector2.ZERO:
		_facing = _facing_from(direction)
		sprite.play("walk_" + _facing)
	else:
		sprite.play("idle_" + _facing)

# En diagonal gana el eje mas marcado; en empate, el horizontal.
func _facing_from(direction: Vector2) -> String:
	if absf(direction.x) >= absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y > 0.0 else "up"

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
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
