extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_pause.tscn
# Comprueba la pausa y la contratapa sin jugar: Esc abre y cierra pausando el
# arbol, el libro decide entre el cuaderno y la pausa minima segun el contexto, un
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
	await _wait_frames(SETTLE_FRAMES)

func _check_plain_pause() -> void:
	GameState.reset()
	var core := _spawn(Core.Context.HUB)
	await _wait_frames(SETTLE_FRAMES)
	_expect(not core.menu.is_open(), "el menú arranca cerrado")
	await _press_and_wait("pause")
	_expect(core.menu.is_open(), "Esc abre el menú")
	_expect(get_tree().paused, "el menú pausa el árbol")
	_expect(not core.menu.is_notebook_view(), "sin el libro se ve la pausa mínima")
	_expect(core.menu.entries() == PauseMenu.PLAIN_ENTRIES, "la pausa mínima solo tiene Seguir y Salir")
	await _press_and_wait("pause")
	_expect(not core.menu.is_open(), "Esc cierra el menú")
	_expect(not get_tree().paused, "cerrar el menú suelta la pausa")
	await _despawn(core)

func _check_notebook_pages() -> void:
	GameState.reset()
	GameState.receive_notebook()
	var core := _spawn(Core.Context.HUB)
	await _wait_frames(SETTLE_FRAMES)
	await _press_and_wait("pause")
	_expect(core.menu.is_notebook_view(), "con el libro se ve el cuaderno abierto")
	_expect(core.menu.entries() == PauseMenu.NOTEBOOK_ENTRIES, "el índice del cuaderno tiene todas sus entradas")
	_expect(core.menu.selected_entry() == PauseMenu.Entry.RESUME, "el cuaderno abre con Seguir elegido")
	await _press_and_wait("move_down")
	_expect(core.menu.selected_entry() == PauseMenu.Entry.ERRANDS, "bajar elige la entrada siguiente")
	_expect(core.menu.note_title() == PauseMenu.ENTRY_LABELS[PauseMenu.Entry.ERRANDS], "la página derecha muestra la entrada elegida")
	await _press_and_wait("interact")
	_expect(core.menu.is_open(), "confirmar una entrada sin contenido no cierra el cuaderno")
	await _press_and_wait("move_up")
	await _press_and_wait("move_up")
	_expect(core.menu.selected_entry() == PauseMenu.Entry.QUIT, "subir desde la primera vuelve a la última")
	await _press_and_wait("pause")
	_expect(not core.menu.is_open() and not get_tree().paused, "Esc cierra el cuaderno y suelta la pausa")
	await _press_and_wait("pause")
	await _press_and_wait("interact")
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
	await _wait_frames(SETTLE_FRAMES)
	_expect(not other.notebook_available(), "un recuerdo ajeno no tiene cuaderno aunque ya se tenga el libro")
	await _press_and_wait("pause")
	_expect(other.menu.is_open() and not other.menu.is_notebook_view(), "en un recuerdo ajeno Esc abre la pausa mínima")
	await _despawn(other)

func _check_dialogue_does_not_overlap() -> void:
	GameState.reset()
	var core := _spawn(Core.Context.HUB)
	await _wait_frames(SETTLE_FRAMES)
	Events.message_requested.emit("Un mensaje.")
	await _wait_frames(SETTLE_FRAMES)
	_expect(get_tree().paused, "el diálogo pausa el árbol")
	await _press_and_wait("pause")
	_expect(not core.menu.is_open(), "Esc no abre el menú encima de un diálogo")
	await _press_and_wait("interact")
	_expect(not get_tree().paused, "cerrar el diálogo suelta la pausa")
	await _despawn(core)

func _check_menu_keeps_dialogue_pause() -> void:
	GameState.reset()
	var core := _spawn(Core.Context.HUB)
	await _wait_frames(SETTLE_FRAMES)
	await _press_and_wait("pause")
	Events.message_requested.emit("Llegó durante la pausa.")
	await _wait_frames(SETTLE_FRAMES)
	await _press_and_wait("interact")
	_expect(not core.menu.is_open(), "Seguir cierra el menú")
	_expect(get_tree().paused, "cerrar el menú no suelta la pausa mientras el diálogo siga abierto")
	await _press_and_wait("interact")
	_expect(not get_tree().paused, "al cerrar también el diálogo, se suelta la pausa")
	await _despawn(core)

func _check_clear() -> void:
	Pause.hold(&"a")
	Pause.hold(&"b")
	Pause.release(&"a")
	_expect(get_tree().paused, "con otro dueño la pausa sigue")
	Pause.clear()
	_expect(not get_tree().paused, "clear suelta todas las pausas (cambio de escena)")
