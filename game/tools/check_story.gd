extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_story.tscn
# Comprueba los beats del primer día por el camino real (los NPCs y objetos de
# las escenas, el HUD, Enter y las flechas): cada beat cuenta una sola vez, la
# cadena de Doña Flor va en orden (agua, caldo, libro) y el recuerdo de Tomás
# espera al libro. Imprime FAIL por cada chequeo roto y sale con código 1.

const TOWN := preload("res://scenes/Town.tscn")
const HALL := preload("res://scenes/InnHall.tscn")
# Cada tecla simulada se deja procesar unos frames antes de la siguiente.
const KEY_GAP_FRAMES := 4
const STEP_TIMEOUT := 20.0
# Cuánto más abajo del libro se para el jugador frente al mostrador, y cuánto se
# corre a cada lado del centro de lo que apunta, dentro de su celda (px de mundo).
const COUNTER_FRONT_OFFSET := 19.0
const SIDE_MARGIN := 12.0

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
		func() -> void: _expect(not GameState.is_beat_done(BeatData.TOMAS_KEYS), "hablarle a Tomás sin las llaves no cuenta"),
		func() -> void: _talk(_object(&"llaves"), []),
		func() -> void: _expect(GameState.has_item(Dialogues.KEYS), "levantar las llaves las deja encima"),
		func() -> void: _expect(not _keys_sprite_left(), "levantadas, las llaves ya no se ven en el suelo"),
		func() -> void: _talk(_npc(&"tomas"), []),
		func() -> void: _check_keys_returned(),
		func() -> void: GameState.rest(),
		func() -> void: _check_tomas_gate_without_book(),
		func() -> void: _talk(_npc(&"tomas"), []),
		func() -> void: _expect(GameState.pending_memory == Dialogues.MEMORY_TOMAS_STORE, "hablarle a Tomás con el recuerdo pendiente no lo cambia"),
		func() -> void: _talk(_npc(&"marta"), ["interact"]),
		func() -> void: _expect(not GameState.is_beat_done(BeatData.DONT_KNOW), "\"Estoy bien\" no cuenta"),
		func() -> void: _max_before = GameState.max_stability,
		func() -> void: _talk(_npc(&"marta"), ["move_down", "interact"]),
		func() -> void: _check_seen(),
		func() -> void: _talk(_object(&"pozo"), []),
		func() -> void: _expect(GameState.has_item(Dialogues.BUCKET), "el pozo da el balde lleno"),
		func() -> void: _load(TOWN),
		func() -> void: _expect(_object(&"llaves") == null, "devueltas, las llaves ya no aparecen en el suelo"),
		func() -> void: _expect(not _npc(&"tomas").barks.has("¿Dónde dejé...?"), "Tomás deja de buscar sus llaves"),
		func() -> void: _load(HALL),
		func() -> void: _check_hall_tables(),
		func() -> void: _talk(_object(&"silla"), []),
		func() -> void: _expect(_object(&"libro") != null, "el libro se ve en el mostrador desde el principio"),
		func() -> void: _stand_in_front_of(_npc(&"posadera"), -SIDE_MARGIN),
		func() -> void: _expect(_nearest_dialogue() == &"posadera", "frente a Doña Flor, a su izquierda, se le habla a ella"),
		func() -> void: _stand_in_front_of(_npc(&"posadera"), SIDE_MARGIN),
		func() -> void: _expect(_nearest_dialogue() == &"posadera", "frente a Doña Flor, a su derecha, se le habla a ella y no al libro"),
		func() -> void: _stand_in_front_of(_object(&"libro"), -SIDE_MARGIN),
		func() -> void: _expect(_nearest_dialogue() == &"libro", "frente al libro, a su izquierda, se mira el libro y no a Doña Flor"),
		func() -> void: _stand_in_front_of(_object(&"libro"), SIDE_MARGIN),
		func() -> void: _expect(_nearest_dialogue() == &"libro", "frente al libro, a su derecha, se mira el libro"),
		func() -> void: _talk(_object(&"libro"), []),
		func() -> void: _expect(not GameState.is_beat_done(BeatData.GUEST_BOOK) and not GameState.has_notebook, "mirar el libro no lo da"),
		func() -> void: GameState.remove_item(Dialogues.BUCKET),
		func() -> void: _talk(_npc(&"posadera"), []),
		func() -> void: _expect(not GameState.is_beat_done(BeatData.BROTH), "sin balde, Doña Flor pide el agua y no ofrece el caldo"),
		func() -> void: GameState.add_item(Dialogues.BUCKET),
		func() -> void: _talk(_npc(&"posadera"), ["interact", "interact", "interact", "move_down", "interact"]),
		func() -> void: _check_water_delivered(),
		func() -> void: _expect(not GameState.is_beat_done(BeatData.BROTH), "rechazar el caldo no cuenta ni cuesta nada"),
		func() -> void: _expect(not GameState.is_beat_done(BeatData.GUEST_BOOK) and not GameState.has_notebook, "sin aceptar el caldo no hay libro"),
		func() -> void: _expect(_object(&"libro") != null, "rechazado el caldo, el libro sigue en el mostrador"),
		func() -> void: _max_before = GameState.max_stability,
		func() -> void: _talk(_npc(&"posadera"), ["interact"]),
		func() -> void: _check_book_given(),
		func() -> void: _load(HALL),
		func() -> void: _expect(_object(&"libro") == null, "con el libro regalado, el mostrador queda sin él al volver"),
		func() -> void: _max_before = GameState.max_stability,
		func() -> void: _talk(_npc(&"posadera"), []),
		func() -> void: _expect(is_equal_approx(GameState.max_stability, _max_before), "la cadena no se repite"),
		func() -> void: _check_tomas_gate_after_book(),
		func() -> void: _check_tomas_gate_book_first(),
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

# Parado frente al mostrador, bajo `target`: lo que el jugador alcanza de verdad
# (las zonas se solapan en el mostrador, así que hay que probar cuál gana).
func _stand_in_front_of(target: Node2D, side_offset: float) -> void:
	_scene.player.global_position = Vector2(target.global_position.x + side_offset, _object(&"libro").global_position.y + COUNTER_FRONT_OFFSET)

func _nearest_dialogue() -> Variant:
	var target: Node = _scene.player._nearest_interactable()
	return target.get("dialogue") if target else null

func _check_keys_returned() -> void:
	_expect(GameState.is_beat_done(BeatData.TOMAS_KEYS), "devolverle las llaves a Tomás es el alivio")
	_expect(not GameState.has_item(Dialogues.KEYS), "las llaves ya no están encima")
	_expect(GameState.pending_memory == Dialogues.MEMORY_TOMAS_STORE, "devolver las llaves deja pendiente el recuerdo de Tomás")
	_expect(not GameState.is_memory_ready(Dialogues.MEMORY_TOMAS_STORE), "el mismo día de la entrega el recuerdo no está listo")

func _check_seen() -> void:
	_expect(GameState.is_beat_done(BeatData.DONT_KNOW), "\"No sé quién soy\" es madurar")
	_expect(GameState.max_stability > _max_before, "madurar sube el tope")

func _check_water_delivered() -> void:
	_expect(GameState.is_beat_done(BeatData.INN_WATER), "llevarle el balde a la posadera es el alivio")
	_expect(not GameState.has_item(Dialogues.BUCKET), "el balde ya no está encima")

func _check_book_given() -> void:
	_expect(GameState.is_beat_done(BeatData.BROTH), "aceptar el caldo después cuenta")
	_expect(GameState.is_beat_done(BeatData.GUEST_BOOK), "después del caldo, Doña Flor regala el libro")
	_expect(GameState.has_notebook, "recibir el libro prende el cuaderno")
	_expect(GameState.max_stability > _max_before, "recibir el libro es madurar: sube el tope")
	_expect(_object(&"libro") == null, "regalado, el libro se va del mostrador")

# Con las llaves entregadas y una noche dormida pero sin libro, el recuerdo de
# Tomás todavía no se puede pedir.
func _check_tomas_gate_without_book() -> void:
	_expect(GameState.is_memory_ready(Dialogues.MEMORY_TOMAS_STORE), "pasada una noche, el recuerdo de Tomás está listo")
	_expect(not Dialogues.tomas_memory_ready(), "sin el libro, Tomás todavía no pide que lo acompañen")

func _check_tomas_gate_after_book() -> void:
	_expect(not Dialogues.tomas_memory_ready(), "la noche del libro todavía no alcanza")
	GameState.rest()
	_expect(Dialogues.tomas_memory_ready(), "una noche después del libro, Tomás ya puede pedirlo")

# Al revés: el libro primero y las llaves después; el bloqueo se fija al entregarlas.
func _check_tomas_gate_book_first() -> void:
	GameState.reset()
	GameState.complete_beat(BeatData.GUEST_BOOK)
	GameState.rest()
	GameState.lock_memory(Dialogues.MEMORY_TOMAS_STORE)
	_expect(not Dialogues.tomas_memory_ready(), "con el libro de antes, la noche de las llaves no alcanza")
	GameState.rest()
	_expect(Dialogues.tomas_memory_ready(), "con el libro de antes, una noche después de las llaves se puede pedir")

# La letra de las mesas del salón chocaba con la de Marta: las mesas no se
# dibujaban (y con el despertar pendiente habrían aparecido dos Martas).
func _check_hall_tables() -> void:
	var table_texture: Texture2D = InteriorLoader.FURNITURE["m"].texture
	var tables := 0
	for sprite in _scene.find_children("*", "Sprite2D", true, false):
		if sprite.texture == table_texture:
			tables += 1
	_expect(tables == 2, "el salón tiene sus dos mesas (hay %d)" % tables)

func _keys_sprite_left() -> bool:
	var keys_texture: Texture2D = StoryObjectData.LIST["L"].texture
	for sprite in _scene.find_children("*", "Sprite2D", true, false):
		if sprite.texture == keys_texture and not sprite.is_queued_for_deletion():
			return true
	return false

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
