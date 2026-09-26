extends Node
# Atajos para probar sin recorrer el juego entero (autoload). Salen de un
# archivo local, `game/debug.cfg`, que está en .gitignore: cambiar de rama no lo
# toca y cada clon decide qué probar. Sin el archivo, o en un build de
# release, todos los valores quedan en los normales del juego. El formato está
# en `debug.cfg.example`.

const CONFIG_PATH := "res://debug.cfg"
const SECTION := "start"

# Escena a la que saltar en vez del Nivel 1; "" es jugar normal.
var start_scene := ""
# En el Nivel 1: aparecer junto al último banco.
var start_at_level_end := false
# Todas las habilidades, incluidas las que se ganan fuera del Nivel 1.
var unlock_all := false
var abilities: Array[String] = []

func _ready() -> void:
	if not OS.is_debug_build():
		return
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_error("DebugConfig: no se pudo leer %s (error %d)." % [CONFIG_PATH, error])
		return
	start_scene = config.get_value(SECTION, "scene", "")
	start_at_level_end = config.get_value(SECTION, "level_end", false)
	unlock_all = config.get_value(SECTION, "unlock_all", false)
	abilities.assign(config.get_value(SECTION, "abilities", []))
	if start_scene != "" and not ResourceLoader.exists(start_scene):
		push_error("DebugConfig: la escena '%s' no existe." % start_scene)
		start_scene = ""

# Habilidades a otorgar al arrancar. GameState.unlock valida cada nombre, así
# que un typo en el archivo se avisa ahí.
func abilities_to_grant() -> Array[String]:
	if not unlock_all:
		return abilities
	var granted: Array[String] = GameState.granted_by_default()
	granted.append_array(Catalogs.memories.abilities_of([MemoryData.Kind.LATER]))
	for ability in abilities:
		if not granted.has(ability):
			granted.append(ability)
	return granted
