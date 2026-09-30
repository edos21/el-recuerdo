extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_expulsion.tscn
# Comprueba que la expulsión dura lo mismo llegues con la Estabilidad que
# llegues (progreso por tiempo), que la Estabilidad se agota antes de perder
# Vida, que un golpe durante la expulsión no se devuelve y que sin la habilidad
# de Vida el desplome llega igual a EXPULSION_DURATION. Imprime FAIL por cada
# chequeo roto y sale con código 1.

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const LevelLoader := preload("res://scripts/level_loader.gd")
const STEP := 1.0 / 60.0
const TOLERANCE := 0.1
const MAX_STEPS := 60 * 60
const LEVEL_PATH := "res://levels/level1.txt"
# La puerta se ve pero no se alcanza: el desplome cae entre estas celdas antes de ella.
const MIN_GAP_CELLS := 3.0
const MAX_GAP_CELLS := 6.0

var _collapsed := false

func _ready() -> void:
	_check_same_duration()
	_check_order()
	_check_hit_is_kept()
	_check_no_health_ability()
	_check_door_out_of_reach()
	_finish("check_expulsion")

func _start(stability_ratio: float, with_health: bool) -> Player:
	GameState.reset()
	if with_health:
		GameState.unlock("health")
	var player := PLAYER_SCENE.instantiate() as Player
	add_child(player)
	# Sin el ciclo de física propio: los ticks los da el chequeo a mano.
	player.set_physics_process(false)
	player.stability = player.max_stability * stability_ratio
	_collapsed = false
	player.collapsed.connect(func() -> void: _collapsed = true)
	player.begin_expulsion()
	return player

func _run_until_collapse(player: Player) -> float:
	var elapsed := 0.0
	for _step in MAX_STEPS:
		if _collapsed:
			break
		player._tick_expulsion(STEP)
		elapsed += STEP
	player.queue_free()
	return elapsed

func _check_same_duration() -> void:
	for ratio in [1.0, 0.5, 0.15, 0.0]:
		var elapsed := _run_until_collapse(_start(ratio, true))
		_expect(absf(elapsed - Player.EXPULSION_DURATION) < TOLERANCE,
			"con %d%% de Estabilidad dura %.2f s (esperado %.1f)" % [ratio * 100.0, elapsed, Player.EXPULSION_DURATION])

func _check_order() -> void:
	var player := _start(1.0, true)
	var health_lost_while_stable := false
	var steps := int(Player.EXPULSION_DURATION * Player.EXPULSION_STABILITY_SHARE / STEP) - 5
	for _step in steps:
		player._tick_expulsion(STEP)
		if player.health < player.max_health:
			health_lost_while_stable = true
	_expect(not health_lost_while_stable, "no se pierde Vida mientras queda Estabilidad")
	_expect(player.stability > 0.0, "la Estabilidad no llega a 0 antes de su tramo")
	for _step in 20:
		player._tick_expulsion(STEP)
	_expect(is_zero_approx(player.stability), "la Estabilidad llega a 0 al terminar su tramo")
	player.queue_free()

func _check_hit_is_kept() -> void:
	var player := _start(1.0, true)
	player._tick_expulsion(STEP)
	player.stability = 5.0
	player._tick_expulsion(STEP)
	_expect(player.stability <= 5.0, "la animación no devuelve la Estabilidad perdida por un golpe")
	player.queue_free()

func _check_no_health_ability() -> void:
	var elapsed := _run_until_collapse(_start(1.0, false))
	_expect(absf(elapsed - Player.EXPULSION_DURATION) < TOLERANCE,
		"sin la habilidad de Vida dura %.2f s (esperado %.1f)" % [elapsed, Player.EXPULSION_DURATION])

# Distancia máxima caminando sin parar (integral del paso, que se enlentece
# linealmente con el progreso) contra la distancia real del trigger a la puerta.
func _check_door_out_of_reach() -> void:
	var trigger_col := -1
	var door_col := -1
	for line: String in MapUtils.read_grid(LEVEL_PATH):
		if trigger_col < 0:
			trigger_col = line.find("X")
		if door_col < 0:
			door_col = line.find("d")
	_expect(trigger_col >= 0 and door_col > trigger_col, "el nivel tiene trigger de expulsión y puerta después")
	var average_factor := (Player.EXPULSION_START_SPEED_FACTOR + Player.EXPULSION_END_SPEED_FACTOR) / 2.0
	var walked := Player.WALK_SPEED * average_factor * Player.EXPULSION_DURATION
	var gap_cells := ((door_col - trigger_col) * LevelLoader.CELL - walked) / LevelLoader.CELL
	_expect(gap_cells >= MIN_GAP_CELLS and gap_cells <= MAX_GAP_CELLS,
		"el desplome queda a %.1f celdas de la puerta (esperado %.0f-%.0f)" % [gap_cells, MIN_GAP_CELLS, MAX_GAP_CELLS])
