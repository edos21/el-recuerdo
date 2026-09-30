extends TopDownScene
# Habitación de la posada: donde el protagonista despierta la primera vez,
# con Marta junto a la cama. La primera elección no castiga ninguna opción:
# descansar da un destello de la llegada; salir, orientación. Mapa, look y
# sonido están en InnRoom.tscn.

const FIRST_THOUGHT_DELAY := 1.5
# Un pensamiento nuevo pisa al anterior: se espera a que termine de leerse
# (aparece, se sostiene, se va, con los tiempos del HUD) y un respiro más.
const THOUGHT_BREATH := 0.3
const THOUGHT_STEP := Hud.THOUGHT_FADE_IN + Events.DEFAULT_THOUGHT_HOLD + Hud.THOUGHT_FADE_OUT + THOUGHT_BREATH
const FIRST_THOUGHT := "...¿Dónde estoy?"
# La valija queda al pie de la cama, a la izquierda de donde despierta.
const TRUNK_FACING := "left"
const TRUNK_THOUGHT := "Esto... ¿es mío?"
const MARTA_LINES := [
	"Marta: ¡Ey! Menos mal. Te encontramos en el puerto y no reaccionabas. Te trajimos entre varios.",
	"Marta: Dormiste casi un día entero. Todavía tienes la mirada lejos, ¿eh?",
]
const CHOICE_PROMPT := "Marta: Quédate a descansar un rato, o si quieres aire, la puerta está ahí."
const CHOICES := ["Descansar", "Salir"]
# Al descansar: un destello de la llegada, sin explicarla todavía.
const REST_THOUGHT := "...agua. El ruido de un barco. ¿Un barco?"
const LEAVE_LINE := "Marta: Abajo está la posadera, te va a querer ver. Afuera tienes el mercado, la iglesia, y el puerto... por allí. Despacio, ¿sí?"

func _ready() -> void:
	super._ready()
	if GameState.consume_wake():
		_wake_up()

# Recién despierto no se camina ni se habla: el jugador vuelve a moverse al elegir.
func _wake_up() -> void:
	player.set_locked(true)
	await _wait(FIRST_THOUGHT_DELAY)
	Events.thought_requested.emit(FIRST_THOUGHT, Events.DEFAULT_THOUGHT_HOLD)
	await _wait(THOUGHT_STEP)
	player.face(TRUNK_FACING)
	Events.thought_requested.emit(TRUNK_THOUGHT, Events.DEFAULT_THOUGHT_HOLD)
	await _wait(THOUGHT_STEP)
	for line in MARTA_LINES:
		Events.message_requested.emit(line)
	Events.choice_requested.emit(CHOICE_PROMPT, PackedStringArray(CHOICES), _on_first_choice)

# Un Timer hijo de la escena y no uno del árbol: si la escena se cierra a mitad
# de la secuencia, el Timer se va con ella y la secuencia no sigue sobre nodos
# liberados.
func _wait(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	timer.queue_free()

# Descansar suelta al jugador cuando termina el fundido; salir, en el acto.
func _on_first_choice(index: int) -> void:
	if index == 0:
		RestSpot.rest.call_deferred(player, REST_THOUGHT)
	else:
		player.set_locked(false)
		Events.message_requested.emit(LEAVE_LINE)
