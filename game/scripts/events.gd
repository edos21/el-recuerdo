extends Node
# Bus de eventos entre gameplay y presentacion (HUD, audio): reemplaza
# get_tree().call_group("hud"|"audio", "<metodo>", ...), donde un typo en el
# grupo o en el nombre del metodo era un no-op silencioso. Solo declara las
# senales; no tiene estado ni logica propia.

signal hint_requested(key: String, text: String)
signal message_requested(text: String)
# Elección en el cuadro de diálogo: pausa como un mensaje y, al confirmar, llama
# a `on_chosen` con el índice de la opción elegida.
signal choice_requested(prompt: String, options: PackedStringArray, on_chosen: Callable)
signal thought_requested(text: String, hold: float)
signal memory_dimmed(ability: String)
signal sfx_requested(sfx: String)
# Una pelea que pide mas tension en la musica (el elite con el jugador en su arena).
signal tension_changed(active: bool)

# show_thought() en hud.gd tenia un default propio; las senales no aceptan
# defaults, asi que los emisores que no pasan hold usan esta constante.
const DEFAULT_THOUGHT_HOLD := 4.0
