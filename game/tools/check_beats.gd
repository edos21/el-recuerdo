extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_beats.tscn
# Comprueba los beats de guion y la elección del HUD sin jugar: cada beat cuenta
# una sola vez, el alivio no pasa el tope, madurar no pasa el máximo original, el
# jugador cenital avisa al HUD y una elección llama con la opción elegida y
# suelta la pausa. Imprime FAIL por cada chequeo roto y sale con código 1.

const CORE_SCENE := preload("res://scenes/Core.tscn")
const PLAYER_SCENE := preload("res://scenes/TopDownPlayer.tscn")
const OPTIONS := ["Descansar", "Salir"]

var _frames := 0
var _chosen := -1
var _last_stability_signal := -1.0
var _low_signals := 0

func _ready() -> void:
	_check_wake_up()
	_check_relief()
	_check_maturity()
	_check_player_signal()
	add_child(CORE_SCENE.instantiate())
	Events.message_requested.emit("Antes de la pregunta.")
	Events.choice_requested.emit("¿Qué hacés?", PackedStringArray(OPTIONS), func(index: int) -> void: _chosen = index)

# La elección necesita frames: el HUD procesa la entrada simulada en el
# siguiente ciclo, y el árbol está en pausa mientras tanto.
func _process(_delta: float) -> void:
	_frames += 1
	match _frames:
		2:
			_expect(get_tree().paused, "el cuadro de diálogo pausa el árbol")
			_press("interact")
		4:
			_press("move_down")
		6:
			_press("move_down")
		8:
			_press("move_up")
		10:
			_press("interact")
		12:
			_expect(_chosen == 1, "la elección devuelve la opción marcada (esperado 1, vino %d)" % _chosen)
			_expect(not get_tree().paused, "confirmar la última elección suelta la pausa")
			_finish("check_beats")

func _check_wake_up() -> void:
	GameState.reset()
	GameState.ensure_defaults()
	_expect(is_equal_approx(GameState.stability, GameState.max_stability * GameState.WAKE_STABILITY_RATIO),
		"despierta con WAKE_STABILITY_RATIO del tope")

func _check_relief() -> void:
	var beat := Catalogs.beats.entry("tomas_keys")
	var before := GameState.stability
	_expect(GameState.complete_beat("tomas_keys"), "el alivio se aplica la primera vez")
	_expect(is_equal_approx(GameState.stability, before + beat.amount), "el alivio suma su cantidad a la actual")
	_expect(not GameState.complete_beat("tomas_keys"), "el alivio no se aplica dos veces")
	_expect(is_equal_approx(GameState.stability, before + beat.amount), "repetir el alivio no suma")
	GameState.stability = GameState.max_stability
	GameState.complete_beat("inn_water")
	_expect(is_equal_approx(GameState.stability, GameState.max_stability), "el alivio no pasa el tope")

func _check_maturity() -> void:
	var beat := Catalogs.beats.entry("broth")
	var before := GameState.max_stability
	GameState.stability = before * 0.5
	var before_current := GameState.stability
	_expect(GameState.complete_beat("broth"), "madurar se aplica la primera vez")
	_expect(is_equal_approx(GameState.max_stability, before + beat.amount), "madurar sube el tope")
	_expect(is_equal_approx(GameState.stability, before_current + beat.amount), "madurar sube la actual en lo mismo que el tope")
	GameState.max_stability = GameState.STABILITY_ORIGINAL_MAX - 1.0
	before_current = GameState.stability
	GameState.complete_beat("dont_know_who_i_am")
	_expect(is_equal_approx(GameState.max_stability, GameState.STABILITY_ORIGINAL_MAX), "madurar no pasa el máximo original")
	_expect(is_equal_approx(GameState.stability, before_current + 1.0), "contra el máximo original, la actual sube solo lo que creció el tope")

# Con el jugador real, no solo con GameState: es el que le habla al HUD.
func _check_player_signal() -> void:
	GameState.reset()
	GameState.ensure_defaults()
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	player.stability_changed.connect(func(current: float, _max_value: float) -> void: _last_stability_signal = current)
	player.low_stability_changed.connect(func(_is_low: bool) -> void: _low_signals += 1)
	# Despierta en zona baja y madurar agranda el tope: sigue en zona baja, asi
	# que el umbral no se reavisa (reavisarlo reinicia el parpadeo del HUD).
	GameState.complete_beat("dont_know_who_i_am")
	_expect(_low_signals == 0, "un beat que no cruza el umbral no reavisa la Estabilidad baja")
	GameState.complete_beat("inn_water")
	_expect(is_equal_approx(_last_stability_signal, GameState.stability), "el jugador avisa la Estabilidad nueva al HUD")
	_expect(is_equal_approx(player.stability, GameState.stability), "el jugador expone la Estabilidad de GameState")
	player.queue_free()
