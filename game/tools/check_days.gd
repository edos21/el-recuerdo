extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_days.tscn
# Comprueba los días del hub y el bloqueo de recuerdos sin jugar: descansar suma
# un día y lo avisa, reset() lo reinicia, `slept_since` pide una noche desde el
# beat, el bloqueo no deja fijar un segundo recuerdo, un recuerdo no está listo
# el día de la entrega pero sí tras dormir, dormir no lo libera y solo vivirlo
# lo hace. Imprime FAIL por cada chequeo roto y sale con código 1.

const MEMORY_A := &"memory_a"
const MEMORY_B := &"memory_b"

var _announced_day := 0

func _ready() -> void:
	_check_days()
	_check_slept_since()
	_check_memory_lock()
	_finish.bind("check_days").call_deferred()

func _check_days() -> void:
	GameState.reset()
	_expect(GameState.day == GameState.FIRST_DAY, "el primer día es el primero")
	GameState.day_advanced.connect(_on_day_advanced)
	GameState.rest()
	GameState.day_advanced.disconnect(_on_day_advanced)
	_expect(GameState.day == GameState.FIRST_DAY + 1, "descansar suma un día")
	_expect(_announced_day == GameState.day, "descansar avisa el día nuevo")
	GameState.rest()
	_expect(GameState.day == GameState.FIRST_DAY + 2, "descansar de nuevo suma otro")
	GameState.reset()
	_expect(GameState.day == GameState.FIRST_DAY, "reset() reinicia el día")

func _check_slept_since() -> void:
	GameState.reset()
	var condition := {"slept_since": BeatData.TOMAS_KEYS}
	_expect(not GameState.is_met(condition), "sin el beat, no pasó una noche desde él")
	GameState.complete_beat(BeatData.TOMAS_KEYS)
	_expect(GameState.beat_day[BeatData.TOMAS_KEYS] == GameState.day, "el beat guarda el día en que se completó")
	_expect(not GameState.is_met(condition), "el mismo día del beat, no pasó una noche")
	GameState.rest()
	_expect(GameState.is_met(condition), "tras dormir, pasó una noche desde el beat")
	GameState.reset()
	_expect(GameState.beat_day.is_empty(), "reset() olvida los días de los beats")

func _check_memory_lock() -> void:
	GameState.reset()
	_expect(not GameState.is_met({"memory_locked": true}), "al empezar no hay recuerdo pendiente")
	_expect(GameState.is_met({"memory_locked": false}), "al empezar el bloqueo está libre")
	_expect(GameState.lock_memory(MEMORY_A), "se puede fijar un recuerdo pendiente")
	_expect(GameState.is_met({"memory_locked": true}), "con uno fijado, el bloqueo está activo")
	_expect(GameState.is_memory_pending(MEMORY_A), "el recuerdo fijado está pendiente")
	_expect(not GameState.is_memory_pending(MEMORY_B), "otro recuerdo no está pendiente por el bloqueo del primero")
	_expect(not GameState.lock_memory(MEMORY_B), "con uno fijado, no se puede fijar otro")
	_expect(GameState.pending_memory == MEMORY_A, "el segundo intento no pisa al primero")
	_expect(not GameState.is_memory_ready(MEMORY_A), "el mismo día de la entrega no está listo")
	GameState.rest()
	_expect(GameState.is_memory_ready(MEMORY_A), "tras dormir está listo")
	_expect(not GameState.is_memory_ready(MEMORY_B), "otro recuerdo no está listo")
	_expect(GameState.is_memory_locked(), "dormir no libera el bloqueo")
	GameState.release_memory(MEMORY_B)
	_expect(GameState.is_memory_locked(), "soltar otro recuerdo no libera el pendiente")
	GameState.release_memory(MEMORY_A)
	_expect(not GameState.is_memory_locked(), "vivir el recuerdo libera el bloqueo")
	_expect(GameState.lock_memory(MEMORY_B), "liberado, otro recuerdo se puede fijar")
	GameState.reset()
	_expect(not GameState.is_memory_locked(), "reset() libera el bloqueo")

func _on_day_advanced(day: int) -> void:
	_announced_day = day
