extends Node
# Estado del protagonista que sobrevive a un cambio de escena/genero:
# habilidades recuperadas, Vida y Estabilidad. Cada escena lo lee al arrancar y
# lo actualiza al irse (el jugador de plataformas y el cenital comparten estos
# numeros, no la fisica).

# Solo la emite lo que cambia la Vida o la Estabilidad fuera de un jugador (los
# beats y el descanso del hub); los valores se leen de aca.
signal vitals_changed
# Al descansar: pasó una noche. Las escenas ya abiertas reaccionan acá; las que
# se cargan después leen `day` al entrar.
signal day_advanced(day: int)

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
const FIRST_DAY := 1

var abilities: Array[String] = []
var health: int = MAX_HEALTH
var max_stability: float = MAX_STABILITY
var stability: float = MAX_STABILITY
var came_from_expulsion := false
var completed_beats: Array[String] = []
# Un tick narrativo, no un reloj: solo sube al dormir. Lo que pasa "un día
# después" se pregunta con `slept_since` / `is_memory_ready`, no con horas.
var day := FIRST_DAY
# El día en que se completó cada beat, para preguntar si pasó una noche desde él.
var beat_day: Dictionary[String, int] = {}
# El recuerdo que una entrega dejó pendiente (vacío = ninguno) y el día en que se
# fijó. Mientras haya uno, nada más puede disparar otro: así dos entregas no se
# encolan al dormir.
var pending_memory: StringName = &""
var pending_since_day := FIRST_DAY
# Puerta por la que se sale de una escena (DoorData): la de destino hace aparecer
# al jugador en la puerta con el mismo id y la limpia.
var arrival_door: StringName = &""
# Lo que el protagonista lleva encima para dárselo a alguien (las llaves que
# encontró, un balde lleno). No es un inventario: son encargos del guion.
var items: Array[StringName] = []

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
	if is_beat_done(beat_id):
		return false
	completed_beats.append(beat_id)
	beat_day[beat_id] = day
	match beat.kind:
		BeatData.Kind.RELIEF:
			stability = minf(stability + beat.amount, max_stability)
		BeatData.Kind.MATURITY:
			# El tramo reparado llega lleno: si solo creciera el tope, el
			# porcentaje bajaria y crecer podria reencender el aviso de
			# Estabilidad baja.
			var grown := minf(max_stability + beat.amount, STABILITY_ORIGINAL_MAX) - max_stability
			max_stability += grown
			stability += grown
	vitals_changed.emit()
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

# Fija el recuerdo pendiente. Devuelve false si ya hay uno: quien entrega algo
# que dispara un recuerdo decide qué hacer (no es un error, es una condición del
# juego que `is_memory_locked` permite consultar antes).
func lock_memory(memory_id: StringName) -> bool:
	if is_memory_locked():
		return false
	pending_memory = memory_id
	pending_since_day = day
	return true

func is_memory_locked() -> bool:
	return pending_memory != &""

# Listo para dispararse: es el recuerdo pendiente y pasó al menos una noche
# desde la entrega. Dormir no lo libera, solo lo deja listo.
func is_memory_ready(memory_id: StringName) -> bool:
	return pending_memory == memory_id and day > pending_since_day

# Al vivir el recuerdo. Soltar uno que no está pendiente no hace nada: los
# recuerdos se pueden entrar sin pasar por el bloqueo (DebugConfig).
func release_memory(memory_id: StringName) -> void:
	if pending_memory == memory_id:
		pending_memory = &""

func has_item(item: StringName) -> bool:
	return items.has(item)

func add_item(item: StringName) -> void:
	if not items.has(item):
		items.append(item)

func remove_item(item: StringName) -> void:
	items.erase(item)

# Un id que no está en el catálogo daría false para siempre sin avisar (el NPC
# nunca cambia, el objeto nunca desaparece): se avisa acá, igual que al completarlo.
func is_beat_done(beat_id: String) -> bool:
	if Catalogs.beats.entry(beat_id) == null:
		push_error("Beat desconocido: %s" % beat_id)
	return completed_beats.has(beat_id)

# Condición de guion para que algo esté o pase (un NPC presente, un objeto en
# el suelo): se cumplen todas las claves. Vacía, siempre se cumple.
# wake_pending: bool; beat_done / beat_pending: id de beat; has_item / lacks_item: objeto;
# slept_since: id de beat (pasó al menos una noche desde que se completó);
# memory_locked: bool (hay un recuerdo pendiente).
func is_met(condition: Dictionary) -> bool:
	for key in condition:
		var value: Variant = condition[key]
		var holds: bool
		match key:
			"wake_pending":
				holds = came_from_expulsion == value
			"beat_done":
				holds = is_beat_done(value)
			"beat_pending":
				holds = not is_beat_done(value)
			"has_item":
				holds = has_item(value)
			"lacks_item":
				holds = not has_item(value)
			"slept_since":
				holds = is_beat_done(value) and day > beat_day[value]
			"memory_locked":
				holds = is_memory_locked() == value
			_:
				push_error("GameState: condición desconocida '%s'." % key)
				holds = false
		if not holds:
			return false
	return true

# Descansar (la cama de la posada, se puede repetir) devuelve la Vida entera y
# levanta la Estabilidad hasta el piso del despertar, nunca mas: es para no
# quedar sin salida, no una fuente de Estabilidad (esa es alivio y madurar).
func rest() -> void:
	day += 1
	health = MAX_HEALTH
	stability = maxf(stability, max_stability * WAKE_STABILITY_RATIO)
	vitals_changed.emit()
	day_advanced.emit(day)

# Lo que cuesta o devuelve un recuerdo ajeno mientras se juega (cambiar de día,
# quedarse en uno), sin pasar del tope ni bajar de cero.
func shift_stability(delta: float) -> void:
	var shifted := clampf(stability + delta, 0.0, max_stability)
	if is_equal_approx(shifted, stability):
		return
	stability = shifted
	vitals_changed.emit()

# El despertar se muestra una sola vez: la escena que lo muestra lo consume. Si
# no, volver a entrar a esa escena (por una puerta) lo repetiria.
func consume_wake() -> bool:
	var waking := came_from_expulsion
	came_from_expulsion = false
	return waking

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
	day = FIRST_DAY
	beat_day.clear()
	pending_memory = &""
	pending_since_day = FIRST_DAY
	arrival_door = &""
	items.clear()
