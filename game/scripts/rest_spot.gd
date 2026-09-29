class_name RestSpot
extends Interactable
# Un lugar donde descansar (la cama de la posada): `interact` pregunta si
# descansar. Se puede repetir: GameState.rest() devuelve la Vida y sube la
# Estabilidad solo hasta el piso del despertar.

const PROMPT := "¿Descansar un rato?"
const OPTIONS := ["Descansar", "Todavía no"]
const HINT_TEXT := "[Enter] descansar"
# Cuánto dura la pantalla negra: lo justo para que se lea como un rato de sueño.
const REST_HOLD := 1.2

var _resting_player: Node2D

func _init(area: Rect2) -> void:
	super(area, HINT_TEXT)

func interact(player: Node2D) -> void:
	_resting_player = player
	Events.choice_requested.emit(PROMPT, PackedStringArray(OPTIONS), _on_chosen)

# Descansar con fundido; `thought`, si viene, se piensa al abrir los ojos. El
# jugador no se mueve hasta que vuelve la imagen: con la pantalla negra podría
# llegar a una puerta sin verla.
static func rest(player: Node2D, thought := "") -> void:
	player.set_locked(true)
	await SceneRouter.blink(REST_HOLD, GameState.rest)
	if is_instance_valid(player):
		player.set_locked(false)
	if thought != "":
		Events.thought_requested.emit(thought, Events.DEFAULT_THOUGHT_HOLD)

# La elección corre con el árbol en pausa: el fundido arranca cuando se suelta.
func _on_chosen(index: int) -> void:
	if index == 0:
		rest.call_deferred(_resting_player)
