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

func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	var tween := create_tween()
	tween.tween_property(_shade, "modulate:a", 1.0, FADE_OUT_TIME)
	await tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var fade_in := create_tween()
	fade_in.tween_property(_shade, "modulate:a", 0.0, FADE_IN_TIME)
	await fade_in.finished
	_busy = false
