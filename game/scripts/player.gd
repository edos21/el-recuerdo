extends CharacterBody2D

signal health_changed(current: int, max_value: int)
signal stability_changed(current: float, max_value: float)
# Unico dueno del umbral de Estabilidad baja (GameState.is_low_stability):
# el HUD y world_progression solo reaccionan a este cruce, no lo recalculan.
signal low_stability_changed(is_low: bool)
signal ability_unlocked(ability: String)
signal respawn_requested
signal died
signal collapsed

const WALK_SPEED = 150.0
const RUN_SPEED = 260.0
const JUMP_VELOCITY = -450.0
const ATTACK_DURATION = 0.25
const ATTACK_OFFSET = 22.0
const KNOCKBACK_FORCE = 220.0
const KNOCKBACK_LIFT = 150.0
# Espera antes del aviso de evitar: primero se siente el empujon, despues el texto.
const AVOIDANCE_HINT_DELAY = 0.45
const INVULNERABILITY_TIME = 0.6
const HURT_ANIM_TIME = 0.3
# Pegar no te protege por si solo (si no, spamear el ataque seria una
# invulnerabilidad gratis): el escudo solo aparece cuando el golpe conecta.
const HIT_CONFIRM_SHIELD_TIME = 0.3

# Expulsion del recuerdo: la Estabilidad se drena sola (mas rapido si camina),
# el paso se vuelve pesado y, ya sin Estabilidad, empieza a perder Vida hasta
# desplomarse. No es una muerte: no hay respawn.
const EXPULSION_BASE_DRAIN = 3.0
const EXPULSION_WALK_DRAIN = 5.0
const EXPULSION_HEALTH_INTERVAL = 1.6
# El paso se hace mas pesado con cada paso recorrido (no con la Estabilidad),
# asi el esfuerzo se siente crecer de forma continua hasta el desplome.
const EXPULSION_START_SPEED_FACTOR = 0.7
const EXPULSION_END_SPEED_FACTOR = 0.2
const EXPULSION_FULL_DISTANCE = 1100.0
const STABILITY_HIT_COST = 20.0
const STABILITY_JUMP_COST = 15.0
const STABILITY_ATTACK_COST = 15.0
const STABILITY_SPRINT_DRAIN = 10.0
const STABILITY_REGEN_RATE = 35.0
# Moverse ya no frena del todo la recuperación (con más saltos en el nivel
# largo, "quieto o nada" se sentía como un freno constante) — caminar
# regenera a este porcentaje de la tasa normal; quieto sigue siendo lo más
# rápido, a propósito.
const STABILITY_WALK_REGEN_FACTOR = 0.35
const STABILITY_REGEN_DELAY = 0.7
const STABILITY_BOOST_AMOUNT = 10.0
const JUMPS_BEFORE_EXHAUSTION = 3
const EXHAUSTION_LINES = [
	"Uff.",
	"¿Qué sucede?",
	"¿Por qué no puedo saltar de nuevo?",
	"Siento algo en el pecho, como si me faltara el aire. ¿Qué es esto?",
]

@export var max_health: int = 5
@export var max_stability: float = 90.0

var health: int = max_health
var stability: float = max_stability

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

var _facing := 1
var _attacking := false
var _attack_timer := 0.0
var _invulnerable := false
var _invulnerable_timer := 0.0
var _hit_shield_timer := 0.0
var _expelling := false
var _collapsed := false
var _expulsion_health_timer := 0.0
var _expulsion_distance := 0.0
var _jumps_before_stability := 0
var _exhaustion_attempts := 0
var _idle_timer := 0.0
var _shown_avoidance_hint := false
var _was_on_floor := true
var _hurt_timer := 0.0
var _low_stability := false

func _ready() -> void:
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)

# Unico punto que emite stability_changed: ademas del valor, avisa si el
# cambio cruzo el umbral de Estabilidad baja (antes cada listener lo
# recalculaba por su cuenta y podian desincronizarse).
func _emit_stability() -> void:
	stability_changed.emit(stability, max_stability)
	var low := GameState.is_low_stability(stability, max_stability)
	if low != _low_stability:
		_low_stability = low
		low_stability_changed.emit(low)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	if _collapsed:
		velocity.x = 0.0
		move_and_slide()
		return

	if Input.is_action_just_pressed("jump"):
		_try_jump()

	var direction := Input.get_axis("move_left", "move_right")

	# Mientras dura la invulnerabilidad, no dejamos que el input del jugador
	# pise la velocidad del empujón: si no, mantener la tecla apretada hacia
	# el enemigo cancela el knockback en el mismo frame y nunca llegás a
	# separarte lo suficiente para volver a tocarlo (el contacto solo se
	# detecta al "entrar" al área, no mientras seguís adentro).
	if not _invulnerable:
		var speed := _current_speed(direction, delta)
		if direction:
			velocity.x = direction * speed
			_facing = 1 if direction > 0 else -1
		else:
			velocity.x = move_toward(velocity.x, 0, speed)

	sprite.flip_h = _facing < 0
	attack_area.position.x = ATTACK_OFFSET * _facing

	if _attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_end_attack()

	if _invulnerable:
		_invulnerable_timer -= delta
		if _invulnerable_timer <= 0.0:
			_invulnerable = false

	if _hurt_timer > 0.0:
		_hurt_timer -= delta

	_hit_shield_timer = maxf(_hit_shield_timer - delta, 0.0)

	if _expelling:
		_tick_expulsion(direction, delta)
	else:
		_regen_stability(direction, delta)

	move_and_slide()

	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		Events.sfx_requested.emit("land")
	_was_on_floor = on_floor

	if not _attacking and _hurt_timer <= 0.0 and not _collapsed:
		_update_animation()

func _current_speed(direction: float, delta: float) -> float:
	if _expelling:
		var progress := clampf(_expulsion_distance / EXPULSION_FULL_DISTANCE, 0.0, 1.0)
		return WALK_SPEED * lerpf(EXPULSION_START_SPEED_FACTOR, EXPULSION_END_SPEED_FACTOR, progress)
	var sprinting := GameState.has_ability("sprint") and direction != 0.0 and Input.is_action_pressed("sprint")
	if not sprinting:
		return WALK_SPEED
	if GameState.has_ability("stability"):
		if stability <= 0.0:
			return WALK_SPEED
		stability = maxf(stability - STABILITY_SPRINT_DRAIN * delta, 0.0)
		_emit_stability()
	return RUN_SPEED

func _try_jump() -> void:
	if not GameState.has_ability("jump") or not is_on_floor():
		return

	if not GameState.has_ability("stability"):
		if _jumps_before_stability < JUMPS_BEFORE_EXHAUSTION:
			_jumps_before_stability += 1
			_do_jump()
		else:
			_handle_exhaustion_attempt()
		return

	if stability >= STABILITY_JUMP_COST:
		stability -= STABILITY_JUMP_COST
		_emit_stability()
		_do_jump()

func _do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	Events.sfx_requested.emit("jump")

func _handle_exhaustion_attempt() -> void:
	if _exhaustion_attempts >= EXHAUSTION_LINES.size():
		return
	Events.message_requested.emit(EXHAUSTION_LINES[_exhaustion_attempts])
	_exhaustion_attempts += 1
	if _exhaustion_attempts == EXHAUSTION_LINES.size():
		unlock("stability")

func _regen_stability(direction: float, delta: float) -> void:
	if not GameState.has_ability("stability"):
		return

	if not is_on_floor():
		_idle_timer = 0.0
		return

	_idle_timer += delta
	if _idle_timer < STABILITY_REGEN_DELAY or stability >= max_stability:
		return

	var rate := STABILITY_REGEN_RATE
	if direction != 0.0:
		rate *= STABILITY_WALK_REGEN_FACTOR

	stability = minf(stability + rate * delta, max_stability)
	_emit_stability()

func begin_expulsion() -> void:
	_expelling = true

func _tick_expulsion(direction: float, delta: float) -> void:
	_expulsion_distance += absf(velocity.x) * delta
	if stability > 0.0:
		var drain := EXPULSION_BASE_DRAIN
		if direction != 0.0:
			drain += EXPULSION_WALK_DRAIN
		stability = maxf(stability - drain * delta, 0.0)
		_emit_stability()
		return
	if not GameState.has_ability("health"):
		_collapse()
		return
	_expulsion_health_timer += delta
	if _expulsion_health_timer < EXPULSION_HEALTH_INTERVAL:
		return
	_expulsion_health_timer = 0.0
	health = maxi(health - 1, 0)
	health_changed.emit(health, max_health)
	Events.sfx_requested.emit("hit_take")
	if health <= 0:
		_collapse()

func _collapse() -> void:
	if _collapsed:
		return
	_collapsed = true
	velocity.x = 0.0
	attack_area.monitoring = false
	sprite.play("die")
	collapsed.emit()

func unlock(ability: String) -> void:
	if not GameState.unlock(ability):
		return
	match ability:
		"health":
			health = max_health
		"stability_boost":
			# Fijo, no relativo: el punto es que arrancás un 10% más bajo
			# de lo "normal" y esto te devuelve exactamente a esa base
			# (90 -> 100) — la exploración opcional te deja como se supone
			# que deberías estar, no te da una ventaja extra.
			max_stability += STABILITY_BOOST_AMOUNT
			stability += STABILITY_BOOST_AMOUNT
			_emit_stability()
	ability_unlocked.emit(ability)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and GameState.has_ability("attack") and not _attacking and not _collapsed:
		_try_attack()

func _try_attack() -> void:
	if GameState.has_ability("stability"):
		if stability < STABILITY_ATTACK_COST:
			return
		stability -= STABILITY_ATTACK_COST
		_emit_stability()
	_start_attack()

func _start_attack() -> void:
	_attacking = true
	_attack_timer = ATTACK_DURATION
	attack_area.monitoring = true
	sprite.play("attack")
	Events.sfx_requested.emit("attack")

func _end_attack() -> void:
	_attacking = false
	attack_area.monitoring = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit") and body.take_hit():
		_hit_shield_timer = HIT_CONFIRM_SHIELD_TIME

func take_damage(amount: int, from_position: Vector2) -> void:
	# Un golpe que conecta te cubre un instante: el área de ataque y el
	# hurtbox del enemigo quedan tan cerca que, sin esto, pegarle a alguien
	# cuerpo a cuerpo te haría daño a vos en el mismo momento.
	if _invulnerable or _hit_shield_timer > 0.0 or _collapsed:
		return

	# El empujón pasa siempre que te tocan, tengas o no Vida todavía — así
	# un enemigo nunca se siente como una pared muda. La pérdida de HP en
	# sí solo aplica una vez que existe la barra de Vida.
	_invulnerable = true
	_invulnerable_timer = INVULNERABILITY_TIME
	_hurt_timer = HURT_ANIM_TIME
	sprite.play("hurt")
	Events.sfx_requested.emit("hit_take")

	var push_direction := signf(global_position.x - from_position.x)
	velocity.x = push_direction * KNOCKBACK_FORCE
	velocity.y = -KNOCKBACK_LIFT

	if not GameState.has_ability("attack") and not _shown_avoidance_hint:
		_shown_avoidance_hint = true
		_show_avoidance_hint_delayed()

	if not GameState.has_ability("health") or health <= 0:
		return

	health = maxi(health - amount, 0)
	stability = maxf(stability - STABILITY_HIT_COST, 0.0)
	health_changed.emit(health, max_health)
	_emit_stability()

	if health <= 0:
		if _expelling:
			_collapse()
		else:
			died.emit()

func _show_avoidance_hint_delayed() -> void:
	# Esperamos un instante para que primero se sienta el empujón — si el
	# mensaje (que pausa el juego) apareciera en el mismo frame del golpe,
	# se comería la reacción física.
	await get_tree().create_timer(AVOIDANCE_HINT_DELAY).timeout
	Events.hint_requested.emit("avoidance", "No estoy en condiciones de enfrentar esto todavía. No pasa nada — a veces evitarlo es la decisión correcta.")

func request_respawn() -> void:
	respawn_requested.emit()

func restore_vitals() -> void:
	if _expelling:
		return
	health = max_health
	stability = max_stability
	health_changed.emit(health, max_health)
	_emit_stability()

func _update_animation() -> void:
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0 else "fall")
	elif absf(velocity.x) > 10.0:
		sprite.play("run")
	else:
		sprite.play("idle")
