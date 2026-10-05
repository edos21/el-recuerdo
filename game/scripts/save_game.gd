extends Node
# Partida guardada en disco (autoload). Se guarda al dormir en la cama y se
# reanuda siempre en esa escena: dentro de un recuerdo no hay cama, así que
# cargar vuelve al hub. El estado vive en GameState (`to_save`/`apply_save`);
# acá solo está el archivo, su versión y el cambio de escena.

const FORMAT_VERSION := 1
const SAVE_PATH := "user://save.json"
# Con un debug.cfg activo se juega en otro archivo: probar no pisa la partida real.
const DEBUG_SAVE_PATH := "user://save_debug.json"
const TEMP_SUFFIX := ".tmp"

var path := SAVE_PATH

func _ready() -> void:
	if DebugConfig.active:
		path = DEBUG_SAVE_PATH

func has_save() -> bool:
	return not _read().is_empty()

# El día de la noche guardada, para que el cuaderno diga a cuál vuelve; 0 sin partida.
func saved_day() -> int:
	return int(_read().get("state", {}).get("day", 0))

# Escribe a un temporal y lo renombra encima: un cierre a mitad no deja la
# partida anterior a medias.
func save_game(scene_path: String) -> bool:
	var data := {"version": FORMAT_VERSION, "scene": scene_path, "state": GameState.to_save()}
	var temp_path := path + TEMP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveGame: no se pudo escribir %s (error %d)." % [temp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	var error := DirAccess.rename_absolute(temp_path, path)
	if error != OK:
		push_error("SaveGame: no se pudo mover el guardado a %s (error %d)." % [path, error])
		return false
	return true

# Devuelve si había algo cargable; si no, no toca el estado ni la escena. Con un
# fundido en curso tampoco carga: SceneRouter descartaría el cambio y el estado
# nuevo quedaría corriendo sobre la escena vieja.
func load_game() -> bool:
	var data := _read()
	if data.is_empty() or SceneRouter.is_busy():
		return false
	GameState.apply_save(data["state"])
	SceneRouter.change_scene(data["scene"])
	return true

func delete_save() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

# Un archivo roto, de una versión futura o con una escena que ya no existe es
# "no hay partida": se avisa, pero no se borra (podría rescatarse a mano).
func _read() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("SaveGame: %s no es un guardado válido." % path)
		return {}
	var data := _migrate(parsed)
	if data.is_empty():
		return {}
	if not data.get("state") is Dictionary or not data.get("scene") is String or not ResourceLoader.exists(data["scene"]):
		push_error("SaveGame: %s no tiene estado o escena válidos." % path)
		return {}
	return data

# Un `match` por versión vieja, que la lleva a la siguiente: acá se absorbe el
# próximo cambio de esquema sin romper partidas. Vacío = no se puede leer.
func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version < 1 or version > FORMAT_VERSION:
		push_error("SaveGame: versión de guardado %d no soportada (la actual es %d)." % [version, FORMAT_VERSION])
		return {}
	return data
