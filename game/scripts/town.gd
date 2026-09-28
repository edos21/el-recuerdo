extends TopDownScene
# Pueblo real: donde el protagonista despierta despues de la expulsion. Por
# ahora es una plaza de prueba caminable con dos NPCs y la posada; el guion y
# el primer recuerdo ajeno vienen despues. Mapa, look y sonido estan en Town.tscn.

const WAKE_THOUGHT := "Todo se ve... distinto. Como si me faltara algo."
const WAKE_THOUGHT_DELAY := 2.0

func _ready() -> void:
	super._ready()
	if GameState.consume_wake():
		await get_tree().create_timer(WAKE_THOUGHT_DELAY).timeout
		Events.thought_requested.emit(WAKE_THOUGHT, Events.DEFAULT_THOUGHT_HOLD)
