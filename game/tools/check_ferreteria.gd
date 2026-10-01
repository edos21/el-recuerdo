extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_ferreteria.tscn
# Comprueba el recuerdo de la ferretería sin jugar. Los mapas: los tres días
# miden lo mismo, cada objeto está en el día que le toca y el cuaderno no se
# mueve. El puzzle: tiene solución, no la tiene sin pasar por Ayer, y su costo
# cabe en la Estabilidad con la que se despierta (se busca sobre las celdas,
# con las mismas reglas de pasar, cambiar, recoger y entregar). La escena:
# cambiar de llave cuesta, no se puede cambiar a un día donde hay una caja en
# ese lugar, lo soltado vuelve a su sitio, Hoy recupera y Ayer gasta, agotarse
# suelta lo que se lleva, entregar la bisagra habilita a Tomás y acompañarlo
# termina el recuerdo. Imprime FAIL por cada chequeo roto y sale con código 1.

const SCENE := preload("res://scenes/Ferreteria.tscn")
const PLAYER_HALF_WIDTH := StagePlayer.BODY_WIDTH * 0.5
const LEGEND_WALL := ".EevMd"
const LEGEND_FLOOR := ".CRblVTSg"
const SETTLE_FRAMES := 3
const INPUT_FRAMES := 2
const RATE_FRAMES := 60
const DIALOGUE_TIMEOUT_FRAMES := 600
# Acompañar a Tomás dura unos 13 s de juego.
const ENDING_TIMEOUT := 45.0
const LOW_STABILITY := 1.0
const MID_STABILITY := 10.0
const EPSILON := 0.05

# Columnas de la prueba (ver levels/ferreteria_*.txt).
const COL_BEFORE_CRATE := 5
const COL_FREE_IN_ANTES_ONLY := 7
const COL_HINGE := 8
const COL_NOTHING_NEAR := 12
const COL_FREE_EVERYWHERE := 13
const COL_NEXT_TO_NEIGHBOR := 30
const COL_NEXT_TO_TOMAS := 33

var _finished_memory := false

func _ready() -> void:
	var map := StageMap.new()
	_check_maps(map)
	_check_solvable(map)
	_check_scene()

func _check_maps(map: StageMap) -> void:
	for day in StageMap.DAY_COUNT:
		_expect(map.row_text(day, StageMap.WALL_ROW).length() == StageMap.COLS and map.row_text(day, StageMap.FLOOR_ROW).length() == StageMap.COLS,
				"el día %d mide %d columnas en sus dos filas" % [day, StageMap.COLS])
		for ch in map.row_text(day, StageMap.WALL_ROW):
			_expect(LEGEND_WALL.contains(ch), "carácter '%s' desconocido en la pared del día %d" % [ch, day])
		for ch in map.row_text(day, StageMap.FLOOR_ROW):
			_expect(LEGEND_FLOOR.contains(ch), "carácter '%s' desconocido en el piso del día %d" % [ch, day])
	_expect(map.columns_of(StageMap.Day.HOY, StageMap.SPAWN).size() == 1, "hay un solo lugar de partida, en Hoy")
	for day in [StageMap.Day.ANTES, StageMap.Day.AYER]:
		_expect(map.columns_of(day, StageMap.SPAWN).is_empty(), "el lugar de partida solo está en Hoy")
	_expect(map.columns_of(StageMap.Day.ANTES, 'b').size() == 1, "la bisagra está una vez, en Antes")
	_expect(map.columns_of(StageMap.Day.HOY, 'b').is_empty() and map.columns_of(StageMap.Day.AYER, 'b').is_empty(), "la bisagra solo está en Antes")
	_expect(map.columns_of(StageMap.Day.HOY, 'V').size() == 1, "el vecino está una vez, en Hoy")
	_expect(map.columns_of(StageMap.Day.AYER, 'T').size() == 1, "Tomás está una vez, en Ayer")
	_expect(map.columns_of(StageMap.Day.AYER, 'g').size() == 1, "el bolso está una vez, en Ayer")
	_expect(map.columns_of(StageMap.Day.ANTES, 'g').is_empty() and map.columns_of(StageMap.Day.HOY, 'g').is_empty(), "el bolso solo está en Ayer")
	var book := map.first_column(StageMap.Day.ANTES, 'l')
	for day in StageMap.DAY_COUNT:
		_expect(map.first_column(day, 'l') == book, "el cuaderno está en la misma columna los tres días")

func _check_solvable(map: StageMap) -> void:
	var switches := _min_switches(map, true)
	_expect(switches >= 0, "el puzzle tiene solución")
	_expect(_min_switches(map, false) < 0, "sin pasar por Ayer antes de entregar la bisagra no hay solución")
	_expect(switches * Ferreteria.SWITCH_COST < GameState.max_stability * GameState.WAKE_STABILITY_RATIO,
			"los cambios de llave del camino más corto (%d) caben en la Estabilidad del despertar" % switches)

# Menos cambios de llave para recoger la bisagra, entregarla y llegar a Tomás.
# Caminar es gratis; cambiar de día cuesta 1. Son pocos estados (columna, día,
# si lleva la bisagra, si ya la entregó): se relajan las distancias hasta que
# no mejora ninguna. Si `ayer_libre` es falso, Ayer queda vedado hasta entregarla.
func _min_switches(map: StageMap, ayer_libre: bool) -> int:
	var hinge := map.first_column(StageMap.Day.ANTES, 'b')
	var neighbor := map.first_column(StageMap.Day.HOY, 'V')
	var tomas := map.first_column(StageMap.Day.AYER, 'T')
	var start := Vector4i(map.first_column(StageMap.SPAWN_DAY, StageMap.SPAWN), StageMap.SPAWN_DAY, 0, 0)
	var best := {start: 0}
	var changed := true
	while changed:
		changed = false
		for state: Vector4i in best.keys():
			for next: Array in _moves(map, state, ayer_libre, hinge, neighbor):
				var target: Vector4i = next[0]
				var cost: int = best[state] + next[1]
				if not best.has(target) or cost < best[target]:
					best[target] = cost
					changed = true
	var fewest := -1
	for state: Vector4i in best.keys():
		var arrived := state.w == 1 and state.y == StageMap.Day.AYER and StageMap.within_reach(state.x, tomas)
		if arrived and (fewest < 0 or best[state] < fewest):
			fewest = best[state]
	return fewest

# Estado: x = columna, y = día, z = lleva la bisagra, w = la entregó. Cada
# movimiento es [estado siguiente, cambios de llave que cuesta].
func _moves(map: StageMap, state: Vector4i, ayer_libre: bool, hinge: int, neighbor: int) -> Array:
	var moves: Array = []
	var col := state.x
	var day := state.y as StageMap.Day
	for step: int in [-1, 1]:
		var to := col + step
		if to >= 0 and to < StageMap.COLS and not map.is_blocked(day, to):
			moves.append([Vector4i(to, day, state.z, state.w), 0])
	for step: int in [-1, 1]:
		var to_day := day + step
		if to_day < 0 or to_day >= StageMap.DAY_COUNT:
			continue
		if to_day == StageMap.Day.AYER and not ayer_libre and state.w == 0:
			continue
		if map.fits(to_day as StageMap.Day, StageMap.center_x(col), PLAYER_HALF_WIDTH):
			moves.append([Vector4i(col, to_day, state.z, state.w), 1])
	if day == StageMap.Day.ANTES and state.z == 0 and state.w == 0 and StageMap.within_reach(col, hinge):
		moves.append([Vector4i(col, day, 1, 0), 0])
	if day == StageMap.Day.HOY and state.z == 1 and StageMap.within_reach(col, neighbor):
		moves.append([Vector4i(col, day, 0, 1), 0])
	return moves

func _check_scene() -> void:
	GameState.reset()
	var scene: Ferreteria = SCENE.instantiate()
	add_child(scene)
	await _frames(SETTLE_FRAMES)
	_expect(scene.day == StageMap.Day.HOY and scene.carried == Ferreteria.NO_ITEM and not scene.served, "el recuerdo arranca en Hoy, con las manos vacías")
	_expect(GameState.stability > 0.0, "se entra con Estabilidad")

	# Cambiar de llave cuesta.
	await _teleport(scene, COL_BEFORE_CRATE)
	var before := GameState.stability
	await _press_and_wait("keyring_prev")
	_expect(scene.day == StageMap.Day.ANTES, "Q lleva al día anterior")
	_expect(before - GameState.stability > Ferreteria.SWITCH_COST * 0.5, "cambiar de llave gasta Estabilidad")

	# Donde hay una caja en el otro día no se puede cambiar, y no cuesta.
	await _teleport(scene, COL_FREE_IN_ANTES_ONLY)
	before = GameState.stability
	await _press_and_wait("keyring_next")
	_expect(scene.day == StageMap.Day.ANTES, "no se cambia a un día donde hay una caja en ese lugar")
	_expect(is_equal_approx(before, GameState.stability), "el cambio rechazado no cuesta Estabilidad")

	# Recoger y soltar: lo soltado vuelve a su lugar.
	await _teleport(scene, COL_HINGE)
	await _press_and_wait("interact")
	_expect(scene.carried == Ferreteria.ITEM_HINGE, "se recoge la bisagra junto al estante")
	_expect(not scene.view.hinge_visible, "la bisagra sale del estante mientras se lleva")
	await _teleport(scene, COL_NOTHING_NEAR)
	await _press_and_wait("interact")
	_expect(scene.carried == Ferreteria.NO_ITEM and scene.view.hinge_visible, "lo soltado vuelve al estante")

	# Agotarse suelta lo que se lleva.
	await _teleport(scene, COL_HINGE)
	await _press_and_wait("interact")
	GameState.stability = LOW_STABILITY
	await _teleport(scene, COL_FREE_EVERYWHERE)
	await _press_and_wait("keyring_next")
	_expect(scene.day == StageMap.Day.HOY, "se cambia a Hoy donde cabe")
	_expect(scene.carried == Ferreteria.NO_ITEM, "sin Estabilidad se cae lo que se lleva")

	# Hoy recupera despacio; Ayer gasta.
	GameState.stability = LOW_STABILITY
	await _frames(RATE_FRAMES)
	_expect(GameState.stability > LOW_STABILITY, "Hoy recupera Estabilidad")
	GameState.stability = MID_STABILITY
	await _press_and_wait("keyring_next")
	var at_ayer := GameState.stability
	_expect(scene.day == StageMap.Day.AYER, "E lleva al día siguiente")
	await _frames(RATE_FRAMES)
	_expect(GameState.stability < at_ayer - EPSILON, "Ayer gasta Estabilidad")

	# Tomás no habla hasta que se entregó la bisagra.
	await _teleport(scene, COL_NEXT_TO_TOMAS)
	await _press_and_wait("interact")
	await _dismiss_dialogue()
	_expect(not scene.accompanying, "Tomás no deja que lo acompañen antes de entregar la bisagra")

	# Entregar la bisagra al vecino.
	await _teleport(scene, COL_NEXT_TO_NEIGHBOR)
	await _press_and_wait("keyring_prev")
	scene.carried = Ferreteria.ITEM_HINGE
	await _press_and_wait("interact")
	await _dismiss_dialogue()
	_expect(scene.served and scene.carried == Ferreteria.NO_ITEM, "el vecino se lleva la bisagra")
	_expect(not scene.view.hinge_visible, "entregada, la bisagra no vuelve al estante")

	# Acompañar a Tomás hasta que lo diga termina el recuerdo.
	GameState.stability = GameState.max_stability
	scene.finished.connect(func() -> void: _finished_memory = true)
	await _teleport(scene, COL_NEXT_TO_TOMAS)
	await _press_and_wait("keyring_next")
	await _press_and_wait("interact")
	await _dismiss_dialogue()
	var waited := 0.0
	while not _finished_memory and waited < ENDING_TIMEOUT:
		await get_tree().process_frame
		waited += get_process_delta_time()
	_expect(_finished_memory, "acompañar a Tomás hasta el final termina el recuerdo")
	_finish("check_ferreteria")

func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func _press_and_wait(action: String) -> void:
	_press(action)
	await _frames(INPUT_FRAMES)

func _teleport(scene: Ferreteria, col: int) -> void:
	scene.player.position.x = StageMap.center_x(col)
	await _frames(1)

# Los mensajes pausan el juego hasta apretar Enter.
func _dismiss_dialogue() -> void:
	var waited := 0
	while get_tree().paused and waited < DIALOGUE_TIMEOUT_FRAMES:
		_press("interact")
		await get_tree().process_frame
		waited += 1
