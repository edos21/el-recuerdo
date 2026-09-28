extends TopDownScene
# Pueblo real, al que se sale desde la posada. Por ahora es una plaza de prueba
# caminable con dos NPCs y la posada; el guion y el primer recuerdo ajeno vienen
# despues. Mapa, look y sonido estan en Town.tscn.

func _ready() -> void:
	super._ready()
	# El despertar es de la habitacion de la posada. Si el pueblo corre suelto
	# (F6, debug.cfg), no tiene que quedar pendiente para cuando se suba por la
	# escalera.
	GameState.consume_wake()
