extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_notebook.tscn
# Comprueba el cuaderno sin jugar: el catálogo es válido, cada entrada aparece,
# avanza y se tacha según el estado, lo hecho antes de recibir el libro ya está
# anotado al abrirlo, una etapa sin nota hereda la anterior, y la sub-vista de
# Encargos se abre y se cierra con Esc en dos niveles. Imprime FAIL por cada
# chequeo roto y sale con código 1.

const CORE_SCENE := preload("res://scenes/Core.tscn")
const TIMEOUT := 15.0
const SETTLE_FRAMES := 3

func _ready() -> void:
	get_tree().create_timer(TIMEOUT).timeout.connect(_on_timeout)
	_check_catalog()
	_check_stages()
	_check_inheritance_and_low_note()
	_check_retroactive_entries()
	await _check_errands_view()
	await _check_empty_errands()
	await _check_town_view()
	_finish("check_notebook")

func _on_timeout() -> void:
	_failures += 1
	_finish("check_notebook (tiempo agotado)")

func _entry(entry_id: String) -> NotebookEntryDef:
	var entry := Catalogs.notebook.find_entry(entry_id)
	_expect(entry != null, "la entrada '%s' existe" % entry_id)
	return entry

func _stage_of(entry_id: String) -> NotebookData.Stage:
	var stage := Catalogs.notebook.current_stage(_entry(entry_id))
	return stage.stage if stage != null else -1 as NotebookData.Stage

func _is_listed(entry_id: String) -> bool:
	var entry := Catalogs.notebook.find_entry(entry_id)
	return Catalogs.notebook.visible_entries(entry.section).has(entry)

func _check_catalog() -> void:
	GameState.reset()
	var notebook := Catalogs.notebook
	for section in NotebookData.Section.values():
		var count := notebook.entries.filter(func(entry: NotebookEntryDef) -> bool: return entry.section == section).size()
		_expect(count <= NotebookIndex.MAX_ROWS, "las entradas de la sección %d caben en el índice" % section)
	var known_keys := ["wake_pending", "beat_done", "beat_pending", "has_item", "lacks_item", "slept_since", "memory_locked", "knows"]
	for entry in notebook.entries:
		_expect(ResourceLoader.exists(notebook.drawing_path(entry)), "'%s' tiene dibujo" % entry.id)
		for stage in entry.stages:
			for key in stage.condition:
				_expect(known_keys.has(key), "'%s': condición conocida '%s'" % [entry.id, key])
	_expect(notebook.name_value() != "", "el campo Nombre tiene texto")

func _check_stages() -> void:
	GameState.reset()
	_expect(_is_listed("woke_up"), "Desperté está anotado desde el principio")
	_expect(not _is_listed("tomas_keys"), "las llaves no aparecen hasta que Tomás cuenta")
	GameState.learn(StoryFacts.TOMAS_TOLD_KEYS)
	_expect(_stage_of("tomas_keys") == NotebookData.Stage.NOTED, "con la pista, las llaves quedan anotadas")
	GameState.add_item(Dialogues.KEYS)
	_expect(_stage_of("tomas_keys") == NotebookData.Stage.IN_PROGRESS, "con las llaves en la mano, el encargo está en curso")
	GameState.remove_item(Dialogues.KEYS)
	GameState.complete_beat(BeatData.TOMAS_KEYS)
	_expect(_stage_of("tomas_keys") == NotebookData.Stage.DONE, "devueltas, el encargo se cumple")
	var listed := Catalogs.notebook.visible_entries(NotebookData.Section.ERRANDS)
	_expect(listed.back().id == "tomas_keys", "lo cumplido va al final del índice")
	_expect(Catalogs.notebook.is_done(_entry("tomas_keys")), "is_done refleja el tachado")
	GameState.add_item(Dialogues.BUCKET)
	_expect(_stage_of("inn_water") == NotebookData.Stage.IN_PROGRESS, "con el balde lleno el agua aparece aunque nadie la haya pedido")
	_expect(not _is_listed("broth"), "el caldo no aparece antes de entregar el agua")

func _check_inheritance_and_low_note() -> void:
	GameState.reset()
	GameState.learn(StoryFacts.TOMAS_TOLD_KEYS)
	GameState.add_item(Dialogues.KEYS)
	var keys := _entry("tomas_keys")
	var noted: String = keys.stages[0].note
	_expect(Catalogs.notebook.note_for(keys, false) == noted, "una etapa sin nota hereda la anterior")
	var original: String = keys.stages[1].note_low
	keys.stages[1].note_low = "Versión baja."
	_expect(Catalogs.notebook.note_for(keys, true) == "Versión baja.", "con Estabilidad baja se usa la variante escrita")
	_expect(Catalogs.notebook.note_for(keys, false) == noted, "con Estabilidad normal no")
	keys.stages[1].note_low = original
	_expect(Catalogs.notebook.note_for(keys, true) == noted, "sin variante escrita queda la nota normal")

func _check_retroactive_entries() -> void:
	GameState.reset()
	GameState.learn(StoryFacts.TOMAS_TOLD_KEYS)
	GameState.complete_beat(BeatData.TOMAS_KEYS)
	GameState.learn(StoryFacts.WATER_ASKED)
	GameState.complete_beat(BeatData.INN_WATER)
	GameState.complete_beat(BeatData.BROTH)
	GameState.complete_beat(BeatData.GUEST_BOOK)
	GameState.receive_notebook()
	for entry_id in ["woke_up", "tomas_keys", "inn_water", "broth", "guest_book", "flor_husband"]:
		_expect(_is_listed(entry_id), "recién recibido el libro, '%s' ya está anotado" % entry_id)
	_expect(_stage_of("broth") == NotebookData.Stage.DONE, "el caldo ya está cumplido")
	_expect(_stage_of("flor_husband") == NotebookData.Stage.NOTED, "el marido de Doña Flor queda abierto")
	_expect(_entry("woke_up").section == NotebookData.Section.TOWN, "Desperté es un hecho del pueblo y no un encargo")
	_expect(not Catalogs.notebook.visible_entries(NotebookData.Section.ERRANDS).has(_entry("flor_husband")), "el marido de Doña Flor no es un encargo")
	_expect(Catalogs.notebook.visible_entries(NotebookData.Section.TOWN).has(_entry("flor_husband")), "el marido de Doña Flor es una curiosidad del pueblo")

func _check_errands_view() -> void:
	GameState.reset()
	GameState.receive_notebook()
	GameState.learn(StoryFacts.TOMAS_TOLD_KEYS)
	GameState.add_item(Dialogues.BUCKET)
	var core: Core = CORE_SCENE.instantiate()
	core.context = Core.Context.HUB
	add_child(core)
	await _wait_frames(SETTLE_FRAMES)
	await _press_and_wait("pause")
	await _press_and_wait("move_down")
	await _press_and_wait("interact")
	_expect(core.menu.view() == PauseMenu.View.ERRANDS, "confirmar Encargos abre la lista")
	_expect(core.menu.index_titles() == ["Las llaves de Tomás", "Agua para la posada"], "el índice lista los encargos anotados y no las curiosidades")
	await _press_and_wait("move_down")
	_expect(core.menu.note_title() == "Agua para la posada", "la página derecha muestra el encargo elegido")
	await _press_and_wait("move_down")
	_expect(core.menu.note_title() == "Las llaves de Tomás", "bajar desde el último vuelve al primero")
	await _press_and_wait("pause")
	_expect(core.menu.is_open() and core.menu.view() == PauseMenu.View.CONTENTS, "Esc vuelve a la contratapa sin cerrar el libro")
	_expect(get_tree().paused, "el libro sigue pausando")
	await _press_and_wait("pause")
	_expect(not core.menu.is_open() and not get_tree().paused, "el segundo Esc cierra el libro")
	Pause.clear()
	core.queue_free()
	await _wait_frames(SETTLE_FRAMES)

# Con el libro por el atajo de depuración y sin haber recibido nada, no hay encargos.
func _check_empty_errands() -> void:
	GameState.reset()
	GameState.receive_notebook()
	var core: Core = CORE_SCENE.instantiate()
	core.context = Core.Context.HUB
	add_child(core)
	await _wait_frames(SETTLE_FRAMES)
	await _press_and_wait("pause")
	await _press_and_wait("move_down")
	await _press_and_wait("interact")
	_expect(core.menu.view() == PauseMenu.View.CONTENTS, "Encargos sin nada anotado no abre la lista")
	await _press_and_wait("pause")
	Pause.clear()
	core.queue_free()
	await _wait_frames(SETTLE_FRAMES)

func _check_town_view() -> void:
	GameState.reset()
	GameState.complete_beat(BeatData.GUEST_BOOK)
	GameState.receive_notebook()
	var core: Core = CORE_SCENE.instantiate()
	core.context = Core.Context.HUB
	add_child(core)
	await _wait_frames(SETTLE_FRAMES)
	await _press_and_wait("pause")
	await _press_and_wait("move_down")
	await _press_and_wait("move_down")
	await _press_and_wait("interact")
	_expect(core.menu.view() == PauseMenu.View.TOWN, "confirmar El pueblo abre sus curiosidades")
	_expect(core.menu.index_titles() == ["Desperté", "El marido de Doña Flor"], "El pueblo lista las curiosidades y no los encargos")
	await _press_and_wait("pause")
	_expect(core.menu.is_open() and core.menu.view() == PauseMenu.View.CONTENTS, "Esc vuelve a la contratapa desde El pueblo")
	await _press_and_wait("pause")
	Pause.clear()
	core.queue_free()
	await _wait_frames(SETTLE_FRAMES)
