extends Node
# godot --headless --fixed-fps 60 --path . res://tools/check_inn.tscn
# Comprueba el despertar en la posada sin jugar: el despertar se consume una
# sola vez; descansar devuelve la Vida y sube la Estabilidad solo hasta el piso
# del despertar; el jugador cenital refleja los dos valores; Marta está junto a
# la cama solo mientras el despertar no se mostró; la cama se puede usar; y la
# secuencia entera (pensamientos, líneas de Marta, elegir "Descansar", fundido)
# termina con el jugador libre y la Estabilidad en el piso. Imprime FAIL por
# cada chequeo roto y sale con código 1. Corre como escena y no como `--script`
# porque los autoloads no compilan en ese modo.

const ROOM_SCENE := preload("res://scenes/InnRoom.tscn")
const PLAYER_SCENE := preload("res://scenes/TopDownPlayer.tscn")
# Tope de la secuencia: pensamientos y mensajes tardan unos 14 s de juego.
const WAKE_TIMEOUT := 30.0
const REST_TIMEOUT := 8.0
const SETTLE_FRAMES := 3

enum Step { CHECK_ROOMS, WAIT_CHOICE, WAIT_REST, DONE }

var _failures := 0
var _step := Step.CHECK_ROOMS
var _frames := 0
var _elapsed := 0.0
var _room: TopDownScene
var _vitals_signals := 0

func _ready() -> void:
	_check_consume_wake()
	_check_rest_rules()
	_check_player_reflects_rest()
	GameState.reset()
	GameState.begin_wake_up()
	_room = ROOM_SCENE.instantiate()
	add_child(_room)

func _process(delta: float) -> void:
	_frames += 1
	_elapsed += delta
	match _step:
		Step.CHECK_ROOMS:
			if _frames < SETTLE_FRAMES:
				return
			_expect(_marta(_room) != null, "con el despertar pendiente, Marta está junto a la cama")
			_expect(_rest_spot(_room) != null, "la cama se puede usar para descansar")
			_expect(not GameState.came_from_expulsion, "la habitación consume el despertar")
			_expect(not _room.player.is_physics_processing(), "recién despierto no se camina")
			# El despertar ya deja la Estabilidad en el piso y la Vida llena: se
			# bajan para que descansar tenga algo que devolver.
			GameState.stability = GameState.max_stability * GameState.WAKE_STABILITY_RATIO * 0.5
			GameState.health = 1
			_step = Step.WAIT_CHOICE
			_elapsed = 0.0
		Step.WAIT_CHOICE:
			# Los mensajes de Marta pausan el árbol: se avanzan hasta la elección.
			if get_tree().paused and _frames % 10 == 0:
				_press("interact")
			if _room.player.is_physics_processing():
				_step = Step.WAIT_REST
				_elapsed = 0.0
			elif _elapsed > WAKE_TIMEOUT:
				_fail_and_quit("la secuencia del despertar llega a la elección")
		Step.WAIT_REST:
			var floor_value := GameState.max_stability * GameState.WAKE_STABILITY_RATIO
			if _elapsed > REST_TIMEOUT:
				_expect(GameState.stability >= floor_value - 0.01, "descansar deja la Estabilidad en el piso")
				_expect(GameState.health == GameState.MAX_HEALTH, "descansar devuelve la Vida")
				_expect(not get_tree().paused, "después de elegir, el juego sigue")
				_room.free()
				_check_no_marta_without_wake()
				_step = Step.DONE
		Step.DONE:
			print("check_inn: %s" % ("OK" if _failures == 0 else "%d FALLOS" % _failures))
			get_tree().quit(0 if _failures == 0 else 1)

func _check_consume_wake() -> void:
	GameState.reset()
	GameState.begin_wake_up()
	_expect(GameState.consume_wake(), "el despertar pendiente se consume")
	_expect(not GameState.consume_wake(), "el despertar no se consume dos veces")

func _check_rest_rules() -> void:
	GameState.reset()
	GameState.vitals_changed.connect(_count_vitals)
	GameState.max_stability = 100.0
	GameState.stability = 10.0
	GameState.health = 2
	GameState.rest()
	_expect(is_equal_approx(GameState.stability, 100.0 * GameState.WAKE_STABILITY_RATIO), "por debajo del piso, descansar sube la Estabilidad hasta el piso")
	_expect(GameState.health == GameState.MAX_HEALTH, "descansar devuelve la Vida entera")
	_expect(_vitals_signals == 1, "descansar avisa una vez")
	GameState.stability = 50.0
	GameState.rest()
	_expect(is_equal_approx(GameState.stability, 50.0), "por encima del piso, descansar no sube la Estabilidad")
	GameState.vitals_changed.disconnect(_count_vitals)

# Con el jugador real, que es el que le habla al HUD.
func _check_player_reflects_rest() -> void:
	GameState.reset()
	GameState.ensure_defaults()
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	var shown := {"health": -1}
	player.health_changed.connect(func(current: int, _max_value: int) -> void: shown.health = current)
	GameState.health = 1
	GameState.rest()
	_expect(player.health == GameState.MAX_HEALTH, "el jugador cenital refleja la Vida de GameState")
	_expect(shown.health == GameState.MAX_HEALTH, "el jugador avisa la Vida nueva al HUD")
	player.free()

func _check_no_marta_without_wake() -> void:
	var room: TopDownScene = ROOM_SCENE.instantiate()
	add_child(room)
	_expect(_marta(room) == null, "sin despertar pendiente, Marta ya no está en la habitación")
	room.free()

func _marta(room: TopDownScene) -> Npc:
	for node in get_tree().get_nodes_in_group(TopDownLoader.CHARACTERS_GROUP):
		if node is Npc and node.npc_name == "Marta" and room.is_ancestor_of(node):
			return node
	return null

func _rest_spot(room: TopDownScene) -> RestSpot:
	for child in room.loader.get_children():
		if child is RestSpot:
			return child
	return null

func _count_vitals() -> void:
	_vitals_signals += 1

func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)

func _fail_and_quit(description: String) -> void:
	_expect(false, description)
	print("check_inn: %d FALLOS" % _failures)
	get_tree().quit(1)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % description)
