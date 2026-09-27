extends Node
# Estado del protagonista que sobrevive a un cambio de escena/genero:
# habilidades recuperadas, Vida y Estabilidad. Cada escena lo lee al arrancar y
# lo actualiza al irse (el jugador de plataformas y el cenital comparten estos
# numeros, no la fisica).

# Solo la emite lo que cambia la Estabilidad fuera de un jugador (los beats del
# hub); los valores se leen de aca.
signal stability_changed

const MAX_HEALTH := 5
const MAX_STABILITY := 90.0
# Largo de la barra original, que nunca cambia (kintsugi): el tope actual
# (`max_stability`) crece madurando hasta acá, y lo que falta es el fantasma.
# Tiene que quedar holgado por encima de lo que da el Nivel 1 (base + elite),
# o el fantasma se cierra antes de que madurar en el pueblo signifique algo.
const STABILITY_ORIGINAL_MAX := 130.0
# Por debajo de esta fraccion de la Estabilidad maxima: barra parpadeando, vineta
# cerrada y musica apagada.
const LOW_STABILITY_RATIO := 0.4
# Despierta en la posada con el cuerpo descansado y la cabeza no: Vida completa
# y Estabilidad en zona baja (lo que dejo la expulsion). A afinar jugando.
const WAKE_STABILITY_RATIO := 0.3

var abilities: Array[String] = []
var health: int = MAX_HEALTH
var max_stability: float = MAX_STABILITY
var stability: float = MAX_STABILITY
var came_from_expulsion := false
var completed_beats: Array[String] = []

func has_ability(ability: String) -> bool:
	return abilities.has(ability)

# Unico calculo del umbral de Estabilidad baja: antes se repetia en hud.gd y
# world_progression.gd, cada uno con su propio estado, y podian desincronizarse.
func is_low_stability(current: float, max_value: float) -> bool:
	return (current / max_value) < LOW_STABILITY_RATIO

# Dueño de las habilidades: valida contra MemoryData (un typo o una habilidad
# inexistente se detecta acá en vez de fallar en silencio) y es idempotente,
# asi que volver a tocar un recuerdo ya recuperado (p. ej. con
# DebugConfig) no lo cuenta dos veces. Devuelve si la otorgó de nuevo.
func unlock(ability: String) -> bool:
	if not Catalogs.memories.has(ability):
		push_error("Habilidad desconocida: %s" % ability)
		return false
	if abilities.has(ability):
		return false
	abilities.append(ability)
	return true

# Dueño de los beats de guion, con el mismo contrato que unlock(): valida contra
# BeatData y cada beat cuenta una sola vez aunque la escena se repita. En el
# hub la Estabilidad no cambia sola, asi que GameState es su unica fuente: quien
# dispara el beat no necesita al jugador. Devuelve si el beat se aplico ahora.
func complete_beat(beat_id: String) -> bool:
	var beat := Catalogs.beats.entry(beat_id)
	if beat == null:
		push_error("Beat desconocido: %s" % beat_id)
		return false
	if completed_beats.has(beat_id):
		return false
	completed_beats.append(beat_id)
	match beat.kind:
		BeatData.Kind.RELIEF:
			stability = minf(stability + beat.amount, max_stability)
		BeatData.Kind.MATURITY:
			max_stability = minf(max_stability + beat.amount, STABILITY_ORIGINAL_MAX)
	stability_changed.emit()
	return true

# Lo que se da por ganado al llegar al pueblo (ensure_defaults) y la base de
# DebugConfig: todo lo del Nivel 1 salvo lo opcional, como el bonus del
# camino secundario.
func granted_by_default() -> Array[String]:
	return Catalogs.memories.abilities_of([MemoryData.Kind.INNATE, MemoryData.Kind.MEMORY])

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
	completed_beats.clear()
