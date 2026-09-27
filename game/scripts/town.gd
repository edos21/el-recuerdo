extends TopDownScene
# Pueblo real: donde el protagonista despierta despues de la expulsion. Por
# ahora es una plaza de prueba caminable con dos NPCs y la posada; el guion y
# el primer recuerdo ajeno vienen despues.

const LEVEL_PATH := "res://levels/town.txt"
const GRASS_COLOR := Color(0.31, 0.42, 0.24)
const WAKE_THOUGHT := "Todo se ve... distinto. Como si me faltara algo."
const WAKE_THOUGHT_DELAY := 2.0
const AMBIENT_WIND_DB := -20.0
const AMBIENT_PAD_DB := -24.0
const TOWN_LOOK := preload("res://looks/town_look.tres")

func _ready() -> void:
	super._ready()
	if GameState.came_from_expulsion:
		await get_tree().create_timer(WAKE_THOUGHT_DELAY).timeout
		Events.thought_requested.emit(WAKE_THOUGHT, Events.DEFAULT_THOUGHT_HOLD)

func _level_path() -> String:
	return LEVEL_PATH

# Mundo real: color pleno, sin el frio del recuerdo.
func _look() -> WorldLook:
	return TOWN_LOOK

func _clear_color() -> Color:
	return GRASS_COLOR

func _start_ambience() -> void:
	core.audio.set_layer("wind", AMBIENT_WIND_DB, 2.0)
	core.audio.set_layer("pad", AMBIENT_PAD_DB, 4.0)
