extends Camera2D
# Camara del jugador de plataformas: mira hacia adonde corre (lookahead solo
# en X: en vertical manda el salto) y tiembla ante golpes y momentos fuertes.
# El temblor ignora el time_scale para que se sienta tambien durante el hit stop.

const LOOKAHEAD_DISTANCE := 70.0
const LOOKAHEAD_SPEED := 2.2
# Por debajo de esta velocidad el jugador esta casi quieto: la camara no se
# adelanta ni vuelve con cada micro-ajuste.
const LOOKAHEAD_MIN_SPEED := 40.0
const SHAKE_STEP_TIME := 0.04

var _shake_tween: Tween

func _process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	var target := 0.0
	if absf(body.velocity.x) > LOOKAHEAD_MIN_SPEED:
		target = signf(body.velocity.x) * LOOKAHEAD_DISTANCE
	else:
		target = position.x
	position.x = lerpf(position.x, target, 1.0 - exp(-LOOKAHEAD_SPEED * delta))

func shake(strength: float, duration: float) -> void:
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween().set_ignore_time_scale(true)
	var steps := maxi(1, int(duration / SHAKE_STEP_TIME))
	for i in range(steps):
		# Decae hacia el final: el golpe se siente al principio, no al soltar.
		var falloff := 1.0 - float(i) / steps
		var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * falloff
		_shake_tween.tween_property(self, "offset", off, SHAKE_STEP_TIME)
	_shake_tween.tween_property(self, "offset", Vector2.ZERO, SHAKE_STEP_TIME * 2.0)
