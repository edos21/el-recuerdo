extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_story.tscn
# Comprueba los beats del primer día por el camino real (los NPCs y objetos de
# las escenas, el HUD, Enter y las flechas): hablarle a Tomás sin las llaves no
# cuenta; levantarlas y devolvérselas es el alivio, y después no vuelven a
# aparecer en el suelo; "Estoy bien" con Marta no cuenta y "No sé quién soy"
# sí; el pozo da el balde y la posadera lo recibe; rechazar el caldo no cuesta
# nada y aceptarlo después cuenta. Imprime FAIL por cada chequeo roto y sale con
# código 1.

const TOWN := preload("res://scenes/Town.tscn")
const HALL := preload("res://scenes/InnHall.tscn")
# Cada tecla simulada se deja procesar unos frames antes de la siguiente.
const KEY_GAP_FRAMES := 4
const STEP_TIMEOUT := 20.0

var _scene: TopDownScene
var _steps: Array[Callable] = []
var _keys: Array[String] = []
var _frames := 0
var _elapsed := 0.0
var _max_before := 0.0

func _ready() -> void:
	GameState.reset()
	GameState.ensure_defaults()
	GameState.consume_wake()
	_steps = [
		func() -> void: _load(TOWN),
		func() -> void: _talk(_npc(&"tomas"), []),
		func() -> void: _expect(not GameState.is_beat_done("tomas_keys"), "hablarle a Tomás sin las llaves no cuenta"),
		func() -> void: _talk(_object(&"llaves"), []),
		func() -> void: _expect(GameState.has_item(Dialogues.KEYS), "levantar las llaves las deja encima"),
		func() -> void: _talk(_npc(&"tomas"), []),
		func() -> void: _check_keys_returned(),
		func() -> void: _talk(_npc(&"marta"), ["interact"]),
		func() -> void: _expect(not GameState.is_beat_done("dont_know_who_i_am"), "\"Estoy bien\" no cuenta"),
		func() -> void: _max_before = GameState.max_stability,
		func() -> void: _talk(_npc(&"marta"), ["move_down", "interact"]),
		func() -> void: _check_seen(),
		func() -> void: _talk(_object(&"pozo"), []),
		func() -> void: _expect(GameState.has_item(Dialogues.BUCKET), "el pozo da el balde lleno"),
		func() -> void: _load(TOWN),
		func() -> void: _expect(_object(&"llaves") == null, "devueltas, las llaves ya no aparecen en el suelo"),
		func() -> void: _expect(not _npc(&"tomas").barks.has("¿Dónde dejé...?"), "Tomás deja de buscar sus llaves"),
		func() -> void: _load(HALL),
		func() -> void: _talk(_npc(&"posadera"), []),
		func() -> void: _check_water_delivered(),
		func() -> void: _talk(_npc(&"posadera"), ["move_down", "interact"]),
		func() -> void: _expect(not GameState.is_beat_done("broth"), "rechazar el caldo no cuenta ni cuesta nada"),
		func() -> void: _talk(_npc(&"posadera"), ["interact"]),
		func() -> void: _expect(GameState.is_beat_done("broth"), "aceptar el caldo después cuenta"),
	]

func _process(delta: float) -> void:
	_frames += 1
	_elapsed += delta
	if _frames % KEY_GAP_FRAMES != 0:
		return
	# Un diálogo abierto se avanza con las teclas pedidas y después con Enter.
	if get_tree().paused:
		_press(_keys.pop_front() if not _keys.is_empty() else "interact")
		if _elapsed > STEP_TIMEOUT:
			_expect(false, "un diálogo se cierra (quedó abierto)")
			_finish("check_story")
		return
	if _steps.is_empty():
		_finish("check_story")
		return
	_elapsed = 0.0
	_steps.pop_front().call()

func _load(scene: PackedScene) -> void:
	if _scene:
		_scene.free()
	_scene = scene.instantiate()
	add_child(_scene)

# Usa `target` como lo haría el jugador; `keys` son las teclas para la elección
# (la primera opción se elige con Enter; la segunda, con abajo y Enter).
func _talk(target: Node2D, keys: Array[String]) -> void:
	if target == null:
		_expect(false, "está a quien hablarle")
		return
	_keys = keys.duplicate()
	target.interact(_scene.player)

func _check_keys_returned() -> void:
	_expect(GameState.is_beat_done("tomas_keys"), "devolverle las llaves a Tomás es el alivio")
	_expect(not GameState.has_item(Dialogues.KEYS), "las llaves ya no están encima")

func _check_seen() -> void:
	_expect(GameState.is_beat_done("dont_know_who_i_am"), "\"No sé quién soy\" es madurar")
	_expect(GameState.max_stability > _max_before, "madurar sube el tope")

func _check_water_delivered() -> void:
	_expect(GameState.is_beat_done("inn_water"), "llevarle el balde a la posadera es el alivio")
	_expect(not GameState.has_item(Dialogues.BUCKET), "el balde ya no está encima")

func _npc(dialogue: StringName) -> Npc:
	for node in _scene.find_children("*", "Npc", true, false):
		if node.dialogue == dialogue:
			return node
	return null

func _object(dialogue: StringName) -> StoryObject:
	for node in _scene.find_children("*", "StoryObject", true, false):
		if node.dialogue == dialogue and not node.is_queued_for_deletion():
			return node
	return null
