extends CanvasLayer
# Cambios de escena con fundido. Es un umbral de historia, no un menu (doc base
# sec. 16, regla 3): siempre se ve en pantalla.

const FADE_OUT_TIME := 1.2
const FADE_IN_TIME := 1.8

var _shade := ColorRect.new()
var _busy := false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shade.color = Color.BLACK
	_shade.anchor_right = 1.0
	_shade.anchor_bottom = 1.0
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.modulate.a = 0.0
	add_child(_shade)

func is_busy() -> bool:
	return _busy

# Fundido a negro y vuelta sin cambiar de escena (descansar, un salto de
# tiempo): `on_dark` corre con la pantalla negra. Si hay otro fundido en curso
# (recién se entró a la escena) espera a que termine: descartarlo dejaría el
# descanso sin efecto.
func blink(hold: float, on_dark: Callable) -> void:
	while _busy:
		await get_tree().process_frame
	_busy = true
	await _fade(1.0, FADE_OUT_TIME)
	on_dark.call()
	await get_tree().create_timer(hold).timeout
	await _fade(0.0, FADE_IN_TIME)
	_busy = false

func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0, FADE_OUT_TIME)
	get_tree().change_scene_to_file(path)
	# Una pausa es de la escena que la pidio (un dialogo abierto durante el
	# fundido): la escena nueva arranca sin ella, o quedaria congelada.
	get_tree().paused = false
	await get_tree().process_frame
	await _fade(0.0, FADE_IN_TIME)
	_busy = false

func _fade(alpha: float, time: float) -> void:
	var tween := create_tween()
	tween.tween_property(_shade, "modulate:a", alpha, time)
	await tween.finished
