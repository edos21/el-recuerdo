extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_save.tscn
# Comprueba el guardado sin jugar: guardar, reiniciar GameState y cargar da el
# mismo estado; todo campo de GameState está guardado o declarado transitorio;
# un archivo roto, de versión futura o ausente no cargan ni rompen; un id que
# ya no existe se descarta; dormir en la cama real guarda con el día nuevo; y
# Cargar del cuaderno pide confirmación y restaura. Imprime FAIL por cada
# chequeo roto y sale con código 1.

const ROOM_SCENE := preload("res://scenes/InnRoom.tscn")
const CORE_SCENE := preload("res://scenes/Core.tscn")
const TEST_PATH := "user://check_save.json"
const TIMEOUT := 30.0
const SETTLE_FRAMES := 3
const SAVED_DAY := 3
const LOAD_ENTRY_STEPS := 4
const UNKNOWN_ID := "no_existe"

func _ready() -> void:
	get_tree().create_timer(TIMEOUT).timeout.connect(_on_timeout)
	SaveGame.path = TEST_PATH
	SaveGame.delete_save()
	_check_round_trip()
	_check_field_coverage()
	_check_unreadable_files()
	_check_unknown_ids()
	await _check_sleeping_saves()
	await _check_menu_load()

func _on_timeout() -> void:
	_failures += 1
	_cleanup()
	_finish("check_save (tiempo agotado)")

func _cleanup() -> void:
	SaveGame.delete_save()
	Pause.clear()

func _fill_state() -> void:
	GameState.reset()
	GameState.abilities.assign(GameState.granted_by_default())
	GameState.complete_beat(BeatData.TOMAS_KEYS)
	GameState.complete_beat(BeatData.INN_WATER)
	GameState.max_stability = 100.5
	GameState.stability = 33.25
	GameState.health = 2
	GameState.day = SAVED_DAY
	GameState.beat_day[BeatData.INN_WATER] = SAVED_DAY - 1
	GameState.lock_memory(Dialogues.MEMORY_TOMAS_STORE)
	GameState.pending_since_day = SAVED_DAY - 1
	GameState.add_item(&"keys")
	GameState.receive_notebook()
	GameState.learn(StoryFacts.MARTA_ASKED)

func _check_round_trip() -> void:
	_fill_state()
	var before := GameState.to_save()
	_expect(SaveGame.save_game("res://scenes/Start.tscn"), "guardar escribe el archivo")
	_expect(SaveGame.has_save() and SaveGame.saved_day() == SAVED_DAY, "hay partida y recuerda el día")
	GameState.reset()
	_expect(GameState.to_save() != before, "reset deja el estado distinto del guardado")
	var data: Dictionary = SaveGame._read()
	GameState.apply_save(data["state"])
	_expect(GameState.to_save() == before, "cargar da el mismo estado que se guardó")
	_expect(GameState.pending_memory == Dialogues.MEMORY_TOMAS_STORE and GameState.items.has(&"keys"), "los ids vuelven como StringName")
	_expect(GameState.knows(StoryFacts.MARTA_ASKED), "los hechos del cuaderno se guardan")
	_expect(GameState.beat_day[BeatData.INN_WATER] == SAVED_DAY - 1, "el día de cada beat vuelve como entero")
	SaveGame.delete_save()
	_expect(not SaveGame.has_save(), "borrar quita la partida")

func _check_field_coverage() -> void:
	var saved := GameState.to_save()
	for property in GameState.get_script().get_script_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		var covered: bool = saved.has(property.name) or GameState.TRANSIENT_FIELDS.has(StringName(property.name))
		_expect(covered, "el campo '%s' de GameState se guarda o es transitorio" % property.name)

func _write_raw(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _check_unreadable_files() -> void:
	SaveGame.delete_save()
	_expect(not SaveGame.has_save() and not SaveGame.load_game(), "sin archivo no hay partida ni carga")
	_write_raw("{ esto no es json")
	_expect(not SaveGame.has_save(), "un archivo roto no cuenta como partida")
	_write_raw(JSON.stringify({"version": SaveGame.FORMAT_VERSION + 1, "scene": "res://scenes/Start.tscn", "state": {}}))
	_expect(not SaveGame.has_save(), "un guardado de versión futura no se lee")
	_write_raw(JSON.stringify({"version": SaveGame.FORMAT_VERSION, "scene": "res://scenes/NoExiste.tscn", "state": {}}))
	_expect(not SaveGame.has_save(), "un guardado con una escena que no existe no se lee")
	_expect(FileAccess.file_exists(TEST_PATH), "un archivo ilegible no se borra")
	SaveGame.delete_save()

func _check_unknown_ids() -> void:
	_fill_state()
	var state := GameState.to_save()
	state["abilities"].append(UNKNOWN_ID)
	state["completed_beats"].append(UNKNOWN_ID)
	state["facts"].append(UNKNOWN_ID)
	GameState.apply_save(state)
	_expect(not GameState.abilities.has(UNKNOWN_ID), "una habilidad desconocida se descarta")
	_expect(not GameState.completed_beats.has(UNKNOWN_ID), "un beat desconocido se descarta")
	_expect(not GameState.facts.has(StringName(UNKNOWN_ID)), "un hecho desconocido se descarta")
	_expect(GameState.completed_beats.has(BeatData.TOMAS_KEYS) and GameState.day == SAVED_DAY, "el resto del guardado sí carga")

# Con la cama real y el jugador real: dormir cierra el día y deja el archivo.
func _check_sleeping_saves() -> void:
	GameState.reset()
	GameState.ensure_defaults()
	GameState.consume_wake()
	var room: TopDownScene = ROOM_SCENE.instantiate()
	add_child(room)
	await _wait_frames(SETTLE_FRAMES)
	var day_before := GameState.day
	await RestSpot.rest(room.player)
	_expect(SaveGame.has_save(), "dormir guarda la partida")
	_expect(SaveGame.saved_day() == day_before + 1, "lo guardado es el día que empieza al dormir")
	room.free()
	SaveGame.delete_save()

# Termina antes de que el fundido de la carga cambie la escena: eso liberaría
# este validador.
func _check_menu_load() -> void:
	_fill_state()
	SaveGame.save_game("res://scenes/InnRoom.tscn")
	GameState.day = SAVED_DAY + 10
	var core: Core = CORE_SCENE.instantiate()
	core.context = Core.Context.HUB
	add_child(core)
	await _wait_frames(SETTLE_FRAMES)
	await _press_and_wait("pause")
	for step in LOAD_ENTRY_STEPS:
		await _press_and_wait("move_down")
	_expect(core.menu.selected_entry() == PauseMenu.Entry.LOAD, "Cargar queda elegida")
	await _press_and_wait("interact")
	_expect(core.menu.is_open() and GameState.day == SAVED_DAY + 10, "el primer Enter en Cargar solo pide confirmación")
	await _press_and_wait("interact")
	_expect(not core.menu.is_open(), "el segundo Enter cierra el cuaderno")
	_expect(GameState.day == SAVED_DAY, "cargar restaura el estado guardado")
	_cleanup()
	_finish("check_save")
