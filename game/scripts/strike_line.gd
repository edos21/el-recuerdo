class_name StrikeLine
extends Control
# El tachón a mano sobre un renglón del índice: una polilínea que sube y baja un
# poco, siempre igual para el mismo renglón (el azar sale del `seed`, no del
# tiempo, así no tiembla al volver a dibujar).

const COLOR := Color(0.08, 0.07, 0.1, 0.8)
const WIDTH := 3.0
const STEP := 24.0
const JITTER := 2.5
const OVERHANG := 6.0
# Fracción del alto del renglón donde cae la línea: el texto va pegado abajo.
const HEIGHT_RATIO := 0.62

var span := 0.0:
	set(value):
		span = value
		queue_redraw()
var seed_value := 0

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if span <= 0.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var y := size.y * HEIGHT_RATIO
	var points := PackedVector2Array()
	var x := -OVERHANG
	while x < span + OVERHANG:
		points.append(Vector2(x, y + rng.randf_range(-JITTER, JITTER)))
		x += STEP
	points.append(Vector2(span + OVERHANG, y + rng.randf_range(-JITTER, JITTER)))
	draw_polyline(points, COLOR, WIDTH)
