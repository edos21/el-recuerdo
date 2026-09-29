extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_elite.tscn
# Comprueba el comportamiento del elite sin jugar, con el jugador teletransportado
# en su arena del Nivel 1: se acerca si lo ve lejos, embiste a media distancia con
# recorrido acotado, de cerca pega en vez de embestir, solo se aturde si choca
# contra la pared y avisa a la musica cuando empieza la pelea. Imprime FAIL por
# cada chequeo roto y sale con código 1.

const MAIN_SCENE := preload("res://scenes/Main.tscn")
const AUDIO_LAYERS := preload("res://scripts/audio_layers.gd")
const WAIT_TIMEOUT := 4.0
# Distancias medidas desde el elite; la arena mide 10 celdas de 36 px y el elite
# nace a 2 celdas del muro izquierdo, asi que todo queda dentro de ella.
const FAR_OFFSET := 250.0
const MID_OFFSET := 100.0
const NEAR_OFFSET := 30.0
const BEHIND_OFFSET := 60.0
const DODGE_OFFSET := 150.0
const WALL_TEST_SHIFT := 90.0
const DASH_TOLERANCE := 12.0

var _main: Node
var _elite: Enemy
var _player: Player
var _tension: Array[bool] = []

func _ready() -> void:
	Events.tension_changed.connect(func(active: bool) -> void: _tension.append(active))
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_elite = _find_elite()
	_player = get_tree().get_first_node_in_group("player") as Player
	if not _elite or not _player:
		_expect(false, "el Nivel 1 tiene un elite y un jugador")
		_finish("check_elite")
		return
	await _check_approach()
	await _check_short_dash_without_stun()
	await _check_wall_crash_stuns()
	await _check_melee_instead_of_dash()
	await _check_tension_release()
	_finish("check_elite")

func _find_elite() -> Enemy:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.behavior == Enemy.Behavior.CHARGE:
			return enemy
	for node in find_children("*", "CharacterBody2D", true, false):
		var enemy := node as Enemy
		if enemy and enemy.behavior == Enemy.Behavior.CHARGE:
			return enemy
	return null

# Vuelve al elite a su puesto entre pruebas para que ninguna herede el estado
# de la anterior.
func _reset_elite(shift: float) -> void:
	_elite.global_position.x = _elite._start_x + shift
	_elite.velocity = Vector2.ZERO
	_elite._charge_state = Enemy.ChargeState.IDLE
	_elite._charge_cooldown = 0.0
	_elite._striking = false
	_elite._stun_tween = null
	_elite.sprite.modulate = Color.WHITE
	_elite.sprite.rotation = 0.0

func _place_player(offset: float) -> void:
	_player.global_position = Vector2(_elite.global_position.x + offset, _elite.global_position.y)
	_player.velocity = Vector2.ZERO

func _wait_until(condition: Callable) -> bool:
	var waited := 0.0
	while waited < WAIT_TIMEOUT:
		if condition.call():
			return true
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
	return false

func _in_state(state: Enemy.ChargeState) -> Callable:
	return func() -> bool: return _elite._charge_state == state

# El jugador cae al piso de la arena y el elite, que lo ve lejos, camina hacia él.
func _check_approach() -> void:
	_place_player(FAR_OFFSET)
	await get_tree().create_timer(0.2).timeout
	var start_x := _elite.global_position.x
	await get_tree().create_timer(0.4).timeout
	_expect(_elite.global_position.x > start_x, "de lejos, el elite se acerca al jugador")
	_expect(_tension.has(true), "con el jugador en su arena, avisa a la musica que sube la tension")

# A media distancia embiste; si no choca contra una pared, la embestida es
# acotada y solo toma aire (sin aturdirse).
func _check_short_dash_without_stun() -> void:
	_reset_elite(0.0)
	_place_player(MID_OFFSET)
	_expect(await _wait_until(_in_state(Enemy.ChargeState.WINDUP)), "a media distancia el elite arma la embestida")
	var origin_x := _elite.global_position.x
	_place_player(-BEHIND_OFFSET)
	_expect(await _wait_until(_in_state(Enemy.ChargeState.RECOVER)), "la embestida termina")
	_expect(absf(_elite.global_position.x - origin_x) <= Enemy.CHARGE_MAX_DISTANCE + DASH_TOLERANCE,
		"la embestida no recorre más de CHARGE_MAX_DISTANCE")
	_expect(_elite._stun_tween == null, "si no choca contra la pared no queda aturdido")
	_expect(_elite._charge_timer <= Enemy.CHARGE_BREATHER, "sin choque, la recuperación es la corta")
	_expect(await _wait_until(_in_state(Enemy.ChargeState.IDLE)), "el elite vuelve a esperar después de tomar aire")

# El toreo: el jugador salta al otro lado durante el destello y el elite se estrella.
func _check_wall_crash_stuns() -> void:
	_reset_elite(WALL_TEST_SHIFT)
	_place_player(-MID_OFFSET)
	_expect(await _wait_until(_in_state(Enemy.ChargeState.WINDUP)), "el elite arma otra embestida")
	_place_player(DODGE_OFFSET)
	_expect(await _wait_until(_in_state(Enemy.ChargeState.RECOVER)), "la embestida termina otra vez")
	_expect(_elite._stun_tween != null, "chocar contra la pared lo aturde")
	_expect(_elite._charge_timer > Enemy.CHARGE_BREATHER, "chocar contra la pared lo deja aturdido más que un respiro")
	_expect(await _wait_until(_in_state(Enemy.ChargeState.IDLE)), "el aturdimiento termina")
	_expect(_elite._stun_tween == null, "al recuperarse deja de tambalear")

# Encima del elite no embiste: pega con un tajo telegrafado.
func _check_melee_instead_of_dash() -> void:
	_reset_elite(0.0)
	_place_player(NEAR_OFFSET)
	var struck := await _wait_until(func() -> bool: return _elite._striking)
	_expect(struck, "de cerca el elite pega")
	_expect(_elite._charge_state == Enemy.ChargeState.IDLE, "de cerca no arma la embestida")

# Al terminar la pelea la musica vuelve a su tono y a su volumen sin quedar apagada.
func _check_tension_release() -> void:
	var layer := _main.audio_layers._layers["pad"] as AudioStreamPlayer
	var volume_before := layer.volume_db
	Events.tension_changed.emit(false)
	await get_tree().create_timer(AUDIO_LAYERS.TENSION_FADE_OUT_TIME + AUDIO_LAYERS.TENSION_FADE_IN_TIME + 0.3).timeout
	_expect(is_equal_approx(layer.pitch_scale, 1.0), "al terminar la tension la musica vuelve a su tono")
	_expect(is_equal_approx(layer.volume_db, volume_before), "al terminar la tension la musica recupera su volumen")
