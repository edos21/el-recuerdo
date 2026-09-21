extends Node
# Estado del protagonista que sobrevive a un cambio de escena/genero:
# habilidades recuperadas, Vida y Estabilidad. Cada escena lo lee al arrancar y
# lo actualiza al irse (el jugador de plataformas y el cenital comparten estos
# numeros, no la fisica).

const ALL_ABILITIES := ["jump", "sprint", "stability", "health", "attack"]
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

func capture_from_platformer(player: Node) -> void:
	abilities.clear()
	for ability in ALL_ABILITIES:
		if player.has_ability(ability):
			abilities.append(ability)
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
	abilities.assign(ALL_ABILITIES)
	begin_wake_up()
