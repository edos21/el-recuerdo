class_name Enemy
extends CharacterBody2D

signal defeated

enum Behavior { PATROL, GUARD, CHASE, CHARGE }
enum ChargeState { IDLE, WINDUP, DASH, RECOVER }

# El alcance del guardian tiene que quedar por debajo del de la espada del
# jugador (~46 px centro a centro): si no, te empuja antes de que puedas pegar.
const GUARD_STRIKE_RANGE := 40.0
const GUARD_STRIKE_HEIGHT := 40.0
const GUARD_WINDUP := 0.3
const GUARD_RECOVERY := 0.2
const GUARD_COOLDOWN := 1.3

const CHASE_HEIGHT := 60.0
const EDGE_PROBE_DISTANCE := 10.0

# La embestida se esquiva saltando o alejandose durante el destello; el
# castigo es el rato que queda aturdido despues, sobre todo si choca contra
# una pared.
const CHARGE_TRIGGER_RANGE := 260.0
const CHARGE_TRIGGER_HEIGHT := 60.0
const CHARGE_WINDUP := 0.6
const CHARGE_SPEED := 330.0
const CHARGE_MAX_DISTANCE := 280.0
const CHARGE_RECOVERY := 0.9
const CHARGE_WALL_RECOVERY := 1.5
const CHARGE_COOLDOWN := 0.8
const CHARGE_WINDUP_TINT := Color(2.4, 2.4, 2.4, 1)
const CHARGE_STUN_TINT := Color(0.65, 0.75, 1.4, 1)

@export var behavior: Behavior = Behavior.PATROL
@export var max_health: int = 2
@export var killable: bool = true
@export var speed: float = 60.0
@export var patrol_distance: float = 80.0
@export var contact_damage: int = 1
@export var chase_range: float = 260.0
@export var chase_speed: float = 200.0
@export var sprite_frames_path: String = ""

var health: int
var _start_x := 0.0
var _direction := 1
var _player: Node2D
var _home_floor: Object
var _player_on_home_floor := false
var _charge_state := ChargeState.IDLE
var _charge_timer := 0.0
var _charge_direction := 1
var _charge_origin_x := 0.0
var _charge_cooldown := 0.0
var _striking := false
var _strike_cooldown := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox
@onready var edge_ray: RayCast2D = $RayDown

func _ready() -> void:
	health = max_health
	_start_x = global_position.x
	if sprite_frames_path != "":
		sprite.sprite_frames = load(sprite_frames_path)
		sprite.play("walk")
	hurt_box.body_entered.connect(_on_hurt_box_body_entered)

# Rayo hacia abajo un paso adelante en `direction`: sin piso ahi, hay un borde.
func _has_floor_ahead(direction: int) -> bool:
	edge_ray.position.x = EDGE_PROBE_DISTANCE * direction
	edge_ray.force_raycast_update()
	return edge_ray.is_colliding()

# El jugador se agrega al arbol despues que los enemigos (level_loader lo suma
# al final), asi que en _ready todavia no existe: hay que buscarlo despues.
func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	if not is_instance_valid(_player):
		_find_player()

	match behavior:
		Behavior.GUARD:
			velocity.x = 0.0
			_process_guard(delta)
		Behavior.CHASE:
			_process_chase()
		Behavior.CHARGE:
			_process_charge(delta)
		_:
			_process_patrol()

	move_and_slide()
	if not _home_floor:
		_home_floor = _floor_of(self)
	if not _striking:
		sprite.play("walk")

func _process_patrol() -> void:
	if global_position.x - _start_x > patrol_distance:
		_direction = -1
	elif global_position.x - _start_x < -patrol_distance:
		_direction = 1

	# No dejamos que un patrullero en una repisa se caiga por el borde: si el
	# rayo hacia abajo, un paso adelante en la direccion actual, no encuentra
	# piso, damos la vuelta antes de llegar a pisar el vacio.
	if not _has_floor_ahead(_direction):
		_direction *= -1

	velocity.x = _direction * speed
	sprite.flip_h = _direction < 0

	_bounce_off_walls()

func _process_guard(delta: float) -> void:
	if not _player:
		return
	var dx := _player.global_position.x - global_position.x
	if not _striking:
		sprite.flip_h = dx < 0
	_strike_cooldown = maxf(_strike_cooldown - delta, 0.0)
	if _striking or _strike_cooldown > 0.0:
		return
	if absf(dx) <= GUARD_STRIKE_RANGE and absf(_player.global_position.y - global_position.y) < GUARD_STRIKE_HEIGHT:
		_strike()

# Golpe telegrafado: la animacion de ataque arma el tajo y el dano cae recien
# a mitad, para que el jugador tenga tiempo de reaccionar o de pegar primero.
func _strike() -> void:
	_striking = true
	var side := 1.0 if _player.global_position.x > global_position.x else -1.0
	sprite.play("attack")
	var tween := create_tween()
	tween.tween_interval(GUARD_WINDUP)
	tween.tween_callback(_strike_hit.bind(side))
	tween.tween_interval(GUARD_RECOVERY)
	tween.tween_callback(_strike_end)

func _strike_hit(side: float) -> void:
	var dx := _player.global_position.x - global_position.x
	var in_front := dx * side >= 0.0 and absf(dx) <= GUARD_STRIKE_RANGE
	if in_front and absf(_player.global_position.y - global_position.y) < GUARD_STRIKE_HEIGHT:
		_player.take_damage(contact_damage, global_position)

func _strike_end() -> void:
	_striking = false
	sprite.play("walk")
	_strike_cooldown = GUARD_COOLDOWN

# Cuerpo estatico sobre el que esta parado un CharacterBody2D (o null en el aire).
func _floor_of(body: CharacterBody2D) -> Object:
	for i in body.get_slide_collision_count():
		var collision := body.get_slide_collision(i)
		if collision.get_normal().y < -0.5:
			return collision.get_collider()
	return null

func _process_charge(delta: float) -> void:
	match _charge_state:
		ChargeState.IDLE:
			_process_patrol()
			_charge_cooldown = maxf(_charge_cooldown - delta, 0.0)
			if _charge_cooldown <= 0.0 and _player_in_charge_range():
				_start_windup()
		ChargeState.WINDUP:
			velocity.x = 0.0
			_charge_timer -= delta
			if _charge_timer <= 0.0:
				_charge_state = ChargeState.DASH
				_charge_origin_x = global_position.x
		ChargeState.DASH:
			_process_dash()
		ChargeState.RECOVER:
			velocity.x = 0.0
			_charge_timer -= delta
			if _charge_timer <= 0.0:
				_end_recovery()

func _player_in_charge_range() -> bool:
	if not _player:
		return false
	return absf(_player.global_position.x - global_position.x) <= CHARGE_TRIGGER_RANGE \
			and absf(_player.global_position.y - global_position.y) < CHARGE_TRIGGER_HEIGHT

func _start_windup() -> void:
	_charge_state = ChargeState.WINDUP
	_charge_timer = CHARGE_WINDUP
	_charge_direction = 1 if _player.global_position.x > global_position.x else -1
	sprite.flip_h = _charge_direction < 0
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", CHARGE_WINDUP_TINT, CHARGE_WINDUP)

func _process_dash() -> void:
	velocity.x = _charge_direction * CHARGE_SPEED
	sprite.flip_h = _charge_direction < 0
	var connected := false
	for body in hurt_box.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(contact_damage, global_position)
			connected = true

	var hit_wall := _touching_wall()
	var traveled := absf(global_position.x - _charge_origin_x)
	# Si te alcanza, la embestida termina ahi: seguir empujando contra el
	# jugador la dejaria trabada en el mismo lugar.
	if connected or hit_wall or not _has_floor_ahead(_charge_direction) or traveled >= CHARGE_MAX_DISTANCE:
		_start_recovery(CHARGE_WALL_RECOVERY if hit_wall else CHARGE_RECOVERY)

func _start_recovery(duration: float) -> void:
	_charge_state = ChargeState.RECOVER
	_charge_timer = duration
	velocity.x = 0.0
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", CHARGE_STUN_TINT, 0.1)

func _end_recovery() -> void:
	_charge_state = ChargeState.IDLE
	_charge_cooldown = CHARGE_COOLDOWN
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)

# El perseguidor solo persigue mientras el jugador esta en su misma plataforma:
# si te "ve" desde otra, o se tira al vacio o te espera pegado al borde y no
# hay forma de evitarlo. En el aire se conserva el ultimo estado, asi un salto
# o una caida no lo apagan a mitad de camino.
func _process_chase() -> void:
	if _home_floor and _player and _player.is_on_floor():
		_player_on_home_floor = _floor_of(_player) == _home_floor
	if not _player_on_home_floor:
		_process_patrol()
		return
	if _player and absf(_player.global_position.x - global_position.x) <= chase_range \
			and absf(_player.global_position.y - global_position.y) < CHASE_HEIGHT:
		_direction = 1 if _player.global_position.x > global_position.x else -1
		# Si te ve en una plataforma de al lado, se frena en el borde en vez de
		# tirarse al vacio persiguiendote.
		velocity.x = _direction * chase_speed if _has_floor_ahead(_direction) else 0.0
	else:
		_process_patrol()
		return

	sprite.flip_h = _direction < 0
	_bounce_off_walls()

func _bounce_off_walls() -> void:
	# Si el calculo de distancia de patrulla no alcanza a darle la vuelta a
	# tiempo (por ejemplo, algo solido quedo mas cerca de lo esperado), esto
	# lo saca del atasco: al chocar de costado contra algo fijo, invierte
	# direccion en el momento. Ojo: el piso tambien es un StaticBody2D, asi
	# que hay que fijarse en la normal del contacto (horizontal = pared,
	# vertical = piso) — si no, rebotaria en cada frame solo por estar parado.
	if _touching_wall():
		_direction *= -1

func _touching_wall() -> bool:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() is StaticBody2D and absf(collision.get_normal().x) > 0.5:
			return true
	return false

# Devuelve si el golpe realmente hizo efecto (el jugador se cubre solo entonces).
func take_hit(amount: int = 1) -> bool:
	if not killable:
		return false
	health -= amount
	_flash()
	if health <= 0:
		get_tree().call_group("audio", "play_sfx", "enemy_die")
		defeated.emit()
		queue_free()
	return true

func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(3, 3, 3, 1), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if behavior == Behavior.CHASE and body.is_in_group("player"):
		get_tree().call_group("hud", "show_hint_once", "chaser", "A esto no lo puedo enfrentar. Pero sí puedo correr más rápido que él.")
	if behavior == Behavior.GUARD and body.is_in_group("player") and not GameState.has_ability("attack"):
		get_tree().call_group("hud", "show_hint_once", "guard", "No hay forma de rodearlo. Todavía no.")
	# `killable = false` solo significa que no recibe golpes: el contacto
	# sigue siendo dano normal con empujon, no una muerte instantanea.
	if body.has_method("take_damage"):
		body.take_damage(contact_damage, global_position)
