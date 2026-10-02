extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_pause.tscn
# Comprueba la pausa y la contratapa sin jugar: Esc abre y cierra pausando el
# arbol, el libro decide entre contratapa y pausa minima segun el contexto, un
# recuerdo ajeno nunca muestra el cuaderno, y el menu y el dialogo del HUD no se
# pisan la pausa. Imprime FAIL por cada chequeo roto y sale con código 1.

const CORE_SCENE := preload("res://scenes/Core.tscn")
const TIMEOUT := 15.0
const SETTLE_FRAMES := 3

func _ready() -> void:
	get_tree().create_timer(TIMEOUT).timeout.connect(_on_timeout)
	await _check_plain_pause()
	await _check_notebook_pages()
	await _check_context()
	await _check_dialogue_does_not_overlap()
	await _check_menu_keeps_dialogue_pause()
	_check_clear()
	_finish("check_pause")

func _on_timeout() -> void:
	_failures += 1
	_finish("check_pause (tiempo agotado)")

func _spawn(context: Core.Context) -> Core:
	var core: Core = CORE_SCENE.instantiate()
	core.context = context
	add_child(core)
	return core

func _despawn(core: Core) -> void:
	Pause.clear()
	core.queue_free()
	await _frames()

# La entrada simulada se procesa en el ciclo siguiente.
func _frames() -> void:
	for i in SETTLE_FRAMES:
		await get_tree().process_frame

func _tap(action: String) -> void:
	_press(action)
	await _frames()

func _check_plain_pause() -> void:
	GameState.reset()
	var core := _spawn(Core.Context.HUB)
	await _frames()
	_expect(not core.menu.is_open(), "el menú arranca cerrado")
	await _tap("pause")
	_expect(core.menu.is_open(), "Esc abre el menú")
	_expect(get_tree().paused, "el menú pausa el árbol")
	_expect(not core.menu.is_notebook_view(), "sin el libro se ve la pausa mínima")
	await _tap("pause")
	_expect(not core.menu.is_open(), "Esc cierra el menú")
	_expect(not get_tree().paused, "cerrar el menú suelta la pausa")
	await _despawn(core)

func _check_notebook_pages() -> void:
	GameState.reset()
	GameState.receive_notebook()
	var core := _spawn(Core.Context.HUB)
	await _frames()
	await _tap("pause")
	_expect(core.menu.is_notebook_view(), "con el libro se ve la contratapa")
	_expect(core.menu.page == PauseMenu.Page.MAIN, "la contratapa abre en la página principal")
	await _tap("move_down")
	await _tap("interact")
	_expect(core.menu.page == PauseMenu.Page.OPTIONS, "la segunda entrada de la contratapa abre Opciones")
	await _tap("pause")
	_expect(core.menu.is_open() and core.menu.page == PauseMenu.Page.MAIN, "Esc en Opciones vuelve a la contratapa sin cerrarla")
	await _tap("interact")
	_expect(not core.menu.is_open() and not get_tree().paused, "Seguir cierra y suelta la pausa")
	await _despawn(core)

func _check_context() -> void:
	GameState.reset()
	var own := _spawn(Core.Context.OWN_MEMORY)
	_expect(not own.notebook_available(), "el Nivel 1 no tiene cuaderno: todavía no se recibió el libro")
	GameState.receive_notebook()
	_expect(own.notebook_available(), "un recuerdo propio tiene cuaderno desde que se recibe el libro")
	await _despawn(own)
	var other := _spawn(Core.Context.OTHER_MEMORY)
	await _frames()
	_expect(not other.notebook_available(), "un recuerdo ajeno no tiene cuaderno aunque ya se tenga el libro")
	await _tap("pause")
	_expect(other.menu.is_open() and not other.menu.is_notebook_view(), "en un recuerdo ajeno Esc abre la pausa mínima")
	await _despawn(other)

func _check_dialogue_does_not_overlap() -> void:
	GameState.reset()
	var core := _spawn(Core.Context.HUB)
	await _frames()
	Events.message_requested.emit("Un mensaje.")
	await _frames()
	_expect(get_tree().paused, "el diálogo pausa el árbol")
	await _tap("pause")
	_expect(not core.menu.is_open(), "Esc no abre el menú encima de un diálogo")
	await _tap("interact")
	_expect(not get_tree().paused, "cerrar el diálogo suelta la pausa")
	await _despawn(core)

func _check_menu_keeps_dialogue_pause() -> void:
	GameState.reset()
	var core := _spawn(Core.Context.HUB)
	await _frames()
	await _tap("pause")
	Events.message_requested.emit("Llegó durante la pausa.")
	await _frames()
	await _tap("interact")
	_expect(not core.menu.is_open(), "Seguir cierra el menú")
	_expect(get_tree().paused, "cerrar el menú no suelta la pausa mientras el diálogo siga abierto")
	await _tap("interact")
	_expect(not get_tree().paused, "al cerrar también el diálogo, se suelta la pausa")
	await _despawn(core)

func _check_clear() -> void:
	Pause.hold(&"a")
	Pause.hold(&"b")
	Pause.release(&"a")
	_expect(get_tree().paused, "con otro dueño la pausa sigue")
	Pause.clear()
	_expect(not get_tree().paused, "clear suelta todas las pausas (cambio de escena)")
