extends TopDownScene
# Habitación de la posada: donde el protagonista despierta la primera vez,
# con Marta junto a la cama. La primera elección no castiga ninguna opción:
# descansar da un destello de la llegada; salir, orientación. Mapa, look y
# sonido están en InnRoom.tscn.

const FIRST_THOUGHT_DELAY := 1.5
# Un pensamiento nuevo pisa al anterior: se espera a que termine de leerse
# (aparece, se sostiene, se va) y un respiro más.
const THOUGHT_STEP := 6.0
const FIRST_THOUGHT := "...¿Dónde estoy?"
# La valija queda al pie de la cama, a la izquierda de donde despierta.
const TRUNK_FACING := "left"
const TRUNK_THOUGHT := "Esto... ¿es mío?"
const MARTA_LINES := [
	"Marta: ¡Ey! Menos mal. Te encontramos en el puerto y no reaccionabas. Te trajimos entre varios.",
	"Marta: Dormiste casi un día entero. Todavía tenés la mirada lejos, ¿eh?",
]
const CHOICE_PROMPT := "Marta: Quedate a descansar un rato, o si querés aire, la puerta está ahí."
const CHOICES := ["Descansar", "Salir"]
# Al descansar: un destello de la llegada, sin explicarla todavía.
const REST_THOUGHT := "...agua. El ruido de un barco. ¿Un barco?"
const LEAVE_LINE := "Marta: Abajo está la posadera, te va a querer ver. Afuera tenés el mercado, la iglesia, y el puerto... por allá. Despacio, ¿sí?"

func _ready() -> void:
	super._ready()
	if GameState.consume_wake():
		_wake_up()

# Recién despierto no se camina: el jugador se mueve después de elegir.
func _wake_up() -> void:
	player.set_physics_process(false)
	await get_tree().create_timer(FIRST_THOUGHT_DELAY).timeout
	Events.thought_requested.emit(FIRST_THOUGHT, Events.DEFAULT_THOUGHT_HOLD)
	await get_tree().create_timer(THOUGHT_STEP).timeout
	player.face(TRUNK_FACING)
	Events.thought_requested.emit(TRUNK_THOUGHT, Events.DEFAULT_THOUGHT_HOLD)
	await get_tree().create_timer(THOUGHT_STEP).timeout
	for line in MARTA_LINES:
		Events.message_requested.emit(line)
	Events.choice_requested.emit(CHOICE_PROMPT, PackedStringArray(CHOICES), _on_first_choice)

func _on_first_choice(index: int) -> void:
	player.set_physics_process(true)
	if index == 0:
		RestSpot.rest.call_deferred(REST_THOUGHT)
	else:
		Events.message_requested.emit(LEAVE_LINE)
