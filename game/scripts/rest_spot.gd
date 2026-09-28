class_name RestSpot
extends Node2D
# Un lugar donde descansar (la cama de la posada): acercarse muestra la pista y
# `interact` pregunta si descansar. Se puede repetir: GameState.rest() devuelve
# la Vida y sube la Estabilidad solo hasta el piso del despertar.

const PROMPT := "¿Descansar un rato?"
const OPTIONS := ["Descansar", "Todavía no"]
const HINT_TEXT := "[Enter] descansar"
const HINT_OFFSET := Vector2(-60, -96)
const HINT_SIZE := Vector2(120, 26)
const HINT_FONT_SIZE := 14
const HINT_OUTLINE := 4
# Cuánto dura la pantalla negra: lo justo para que se lea como un rato de sueño.
const REST_HOLD := 1.2

var _hint := Label.new()

# `area` es la huella donde el jugador tiene que estar para descansar (px de mundo,
# relativa a este nodo).
func _init(area: Rect2) -> void:
	var zone := Area2D.new()
	zone.collision_layer = 8
	zone.collision_mask = 8
	zone.position = area.get_center()
	zone.add_child(MapUtils.rect_shape(area.size))
	zone.area_entered.connect(_on_zone_area_entered)
	zone.area_exited.connect(_on_zone_area_exited)
	add_child(zone)
	_hint.text = HINT_TEXT
	_hint.position = HINT_OFFSET
	_hint.size = HINT_SIZE
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", HINT_OUTLINE)
	_hint.visible = false
	add_child(_hint)

var _resting_player: Node2D

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

func _on_zone_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		_hint.visible = true

func _on_zone_area_exited(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		_hint.visible = false
