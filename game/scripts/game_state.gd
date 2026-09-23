extends Node
# Estado del protagonista que sobrevive a un cambio de escena/genero:
# habilidades recuperadas, Vida y Estabilidad. Cada escena lo lee al arrancar y
# lo actualiza al irse (el jugador de plataformas y el cenital comparten estos
# numeros, no la fisica).

const MAX_HEALTH := 5
const MAX_STABILITY := 90.0
# Por debajo de esta fraccion de la Estabilidad maxima: barra parpadeando, vineta
# cerrada y musica apagada.
const LOW_STABILITY_RATIO := 0.4
# Todavia sin cerrar (historia_lore.md sec. 15): con cuanto despierta en el
# pueblo real. Placeholder: Vida completa y Estabilidad a media barra.
const WAKE_STABILITY_RATIO := 0.4

var abilities: Array[String] = []
var health: int = MAX_HEALTH
var max_stability: float = MAX_STABILITY
var stability: float = MAX_STABILITY
var came_from_expulsion := false

func has_ability(ability: String) -> bool:
	return abilities.has(ability)

# Unico calculo del umbral de Estabilidad baja: antes se repetia en hud.gd y
# world_progression.gd, cada uno con su propio estado, y podian desincronizarse.
func is_low_stability(current: float, max_value: float) -> bool:
	return (current / max_value) < LOW_STABILITY_RATIO

# Dueño de las habilidades: valida contra MemoryData (un typo o una habilidad
# inexistente se detecta acá en vez de fallar en silencio) y es idempotente,
# asi que volver a tocar un recuerdo ya recuperado (p. ej. con
# debug_start_at_end) no lo cuenta dos veces. Devuelve si la otorgó de nuevo.
func unlock(ability: String) -> bool:
	if not MemoryData.LIST.has(ability):
		push_error("Habilidad desconocida: %s" % ability)
		return false
	if abilities.has(ability):
		return false
	abilities.append(ability)
	return true

# Lo que se da por ganado al llegar al pueblo (ensure_defaults) y la base de
# debug_start_at_end: todo lo del Nivel 1 salvo lo opcional, como el bonus del
# camino secundario.
func granted_by_default() -> Array[String]:
	return MemoryData.abilities_of([MemoryData.Kind.INNATE, MemoryData.Kind.MEMORY])

func capture_from_platformer(player: Node) -> void:
	max_stability = player.max_stability

func begin_wake_up() -> void:
	came_from_expulsion = true
	health = MAX_HEALTH
	stability = max_stability * WAKE_STABILITY_RATIO

# Si una escena se corre suelta (F6) sin haber pasado por el Nivel 1, se
# simula el estado con el que se llega al pueblo, para poder probarla directo.
func ensure_defaults() -> void:
	if not abilities.is_empty():
		return
	abilities.assign(granted_by_default())
	begin_wake_up()

# Al arrancar el Nivel 1 de nuevo (F6, o volver a jugar) el estado no debe
# heredar habilidades de una corrida anterior.
func reset() -> void:
	abilities.clear()
	health = MAX_HEALTH
	max_stability = MAX_STABILITY
	stability = MAX_STABILITY
	came_from_expulsion = false
