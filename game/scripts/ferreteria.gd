class_name Ferreteria
extends Node2D
# Recuerdo de Tomás (prototipo): la ferretería en tres días (Antes, Hoy, Ayer),
# en un escenario fijo de una sola pantalla. Con las teclas del llavero se
# cambia de día sin moverse del lugar, y lo único que viaja es lo que se lleva
# en la mano. Mapas en levels/ferreteria_*.txt; este script es la lógica del
# recuerdo y StageView lo dibuja.

# Al terminar el recuerdo, antes de volver al pueblo.
signal finished

enum Target { NONE, HINGE, BOOK, NEIGHBOR, TOMAS }

const CAMERA_ZOOM := 1.5
# Alto del escenario en px de mundo: con el ancho de los mapas (40 x 32) llena
# el viewport de 1920x1080 a este zoom.
const VIEW_HEIGHT := 720.0
const BLOCKER_HEIGHT := 128.0
const TOWN_SCENE := "res://scenes/Town.tscn"
const ITEM_HINGE := &"bisagra"
const NO_ITEM := &""

# Cada cambio de llave cuesta Estabilidad; Hoy la recupera despacio y Ayer, el
# día que Tomás evita, la gasta. A afinar jugando.
const SWITCH_COST := 1.5
const STABILITY_RATE := {
	StageMap.Day.ANTES: 0.0,
	StageMap.Day.HOY: 0.6,
	StageMap.Day.AYER: -0.8,
}
const PAD_DB := -24.0
const PAD_FADE := 4.0
const FLASH_ALPHA := 0.35
const FLASH_TIME := 0.3
const THOUGHT_HOLD := 4.0
const HINT_OFFSET := Vector2(-70, -96)
const HINT_SIZE := Vector2(140, 26)
const ENDING_BREATH := 0.5
const DELIVERY_THOUGHT_DELAY := 0.4

# Acompañar a Tomás en Ayer: quedarse a su lado mientras dice cada línea.
const ACCOMPANY_HOLD := 1.8
const ACCOMPANY_BREATH := 0.2
const ACCOMPANY_STEP := Hud.THOUGHT_FADE_IN + ACCOMPANY_HOLD + Hud.THOUGHT_FADE_OUT + ACCOMPANY_BREATH

const FIRST_THOUGHT := "Las llaves pesan distinto. Q y E cambian de día, pero el lugar es el mismo."
const NO_ROOM_THOUGHT := "Algo ocupa ese lugar en ese día."
const HINGE_THOUGHT := "Una bisagra. Antes todavía había."
const HANDS_FULL_THOUGHT := "Ya llevas algo en las manos."
const DROP_THOUGHT := "Vuelve a su lugar."
const EXHAUSTED_THOUGHT := "Se te resbala de las manos. Vuelve a su lugar."
const SILENT_THOUGHT := "Tomás se queda callado."
const BOOK_LINES := {
	StageMap.Day.ANTES: "Cuaderno: la letra de su padre, firme. Todo pagado, todo al día.",
	StageMap.Day.HOY: "Cuaderno: fiado de tres clavos, una pintura y una soga. Los precios están tachados y vueltos a escribir.",
	StageMap.Day.AYER: "Cuaderno: esta hoja está en blanco. Nadie escribió nada ese día.",
}
const BOOK_SERVED_LINE := "Última línea: una bisagra, traída de otro día."
const NEIGHBOR_ASKS := "Vecino: Busco una bisagra. Tomás dice que ya no le quedan."
const NEIGHBOR_THANKS := "Vecino: Gracias por la bisagra. Tomás siempre encuentra algo guardado, ¿verdad?"
# Lo que pasa al completar cada entrega, por objeto: lo que dice el cliente, lo
# que le contesta Tomás, lo que cuenta el narrador y lo que piensa el
# protagonista cuando se cierra el cuadro de diálogo.
const DELIVERIES := {
	ITEM_HINGE: {
		"give": "Le das la bisagra al vecino.",
		"client": "Vecino: ¿Cuánto te debo?",
		"tomas": "Tomás: Llévala. Ya me pagarás. O no, anoto igual.",
		"narration": "En Hoy, Tomás anota la línea y no levanta la vista. En Ayer, en cambio, sigue sentado, esperando.",
		"thought": "Anota sin mirar el cuaderno, como quien firma algo que ya sabía.",
	},
}
const TOMAS_NOT_YET := "Tomás: Ahora no."
const TOMAS_OPENS_UP := "Tomás: No sé cómo seguir con esto. Quédate un rato, si quieres."
const TOMAS_LINES: Array[String] = [
	"Tomás: Mi padre abría a las seis. Yo abro cuando me acuerdo.",
	"Tomás: Si pierdo las llaves, nadie puede decir que cerré yo.",
	"Tomás: No las perdí.",
]
const TOMAS_ENDING := "Tomás: Abro mañana. O el jueves. Ya veremos."
const HINT_TEXTS := {
	Target.HINGE: "[Enter] recoger la bisagra",
	Target.BOOK: "[Enter] leer el cuaderno",
	Target.NEIGHBOR: "[Enter] hablar con el vecino",
	Target.TOMAS: "[Enter] hablar con Tomás",
}
const HINT_DROP := "[Enter] soltar"
const HINT_DELIVER := "[Enter] entregar la bisagra"
const TARGET_CHARS := {
	Target.HINGE: StageMap.HINGE,
	Target.BOOK: StageMap.BOOK,
	Target.NEIGHBOR: StageMap.NEIGHBOR,
	Target.TOMAS: StageMap.TOMAS,
}

@export var looks: Array[WorldLook] = []

@onready var core: Core = $Core
@onready var view: StageView = $View
@onready var camera: Camera2D = $Camera2D
@onready var keyring: KeyringHud = $Keyring

var map := StageMap.new()
var day := StageMap.Day.HOY
var carried := NO_ITEM
var served := false
var player: StagePlayer
# Quedarse junto a Tomás en Ayer hasta que termine de hablar.
var accompanying := false

var _blockers: Dictionary = {}
var _hint := Label.new()
var _flash := ColorRect.new()
var _flash_tween: Tween
var _accompany_time := 0.0
var _lines_said := 0
var _ending := false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	GameState.ensure_defaults()
	view.map = map
	_build_blockers()
	_build_player()
	_build_overlays()
	camera.position = Vector2(map.width_of(day) * StageMap.CELL, VIEW_HEIGHT) * 0.5
	camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	core.bind_player(player, camera)
	core.restore_hud()
	core.bind_hud(player)
	core.audio.set_muffled(false)
	core.audio.set_layer("pad", PAD_DB, PAD_FADE)
	_apply_day()
	Events.thought_requested.emit(FIRST_THOUGHT, THOUGHT_HOLD)

func _build_blockers() -> void:
	for d in StageMap.DAY_COUNT:
		var bodies: Array[StaticBody2D] = []
		for run in map.blocker_runs(d as StageMap.Day):
			var body := StaticBody2D.new()
			body.position = Vector2((run.x + run.y) * StageMap.CELL * 0.5, StageMap.FEET_Y - BLOCKER_HEIGHT * 0.5)
			body.add_child(MapUtils.rect_shape(Vector2((run.y - run.x) * StageMap.CELL, BLOCKER_HEIGHT)))
			add_child(body)
			bodies.append(body)
		_blockers[d] = bodies

func _build_player() -> void:
	player = preload("res://scenes/StagePlayer.tscn").instantiate()
	player.position = Vector2(StageMap.center_x(map.first_column(StageMap.SPAWN_DAY, StageMap.SPAWN)), StageMap.FEET_Y - CharacterScale.FEET_Y)
	player.min_x = 0.0
	player.max_x = map.width_of(day) * StageMap.CELL
	add_child(player)

func _build_overlays() -> void:
	_hint.size = HINT_SIZE
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", Interactable.HINT_FONT_SIZE)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", Interactable.HINT_OUTLINE)
	_hint.visible = false
	add_child(_hint)
	var layer := CanvasLayer.new()
	layer.layer = Core.WORLD_OVERLAY_LAYER
	_flash.color = Color.WHITE
	_flash.modulate.a = 0.0
	_flash.anchor_right = 1.0
	_flash.anchor_bottom = 1.0
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_flash)
	add_child(layer)

func _process(delta: float) -> void:
	GameState.shift_stability(STABILITY_RATE[day] * delta)
	_drop_if_exhausted()
	_update_accompany(delta)
	_update_hint()

func _unhandled_input(event: InputEvent) -> void:
	if _ending:
		return
	if event.is_action_pressed("keyring_prev"):
		_switch_day(day - 1)
	elif event.is_action_pressed("keyring_next"):
		_switch_day(day + 1)
	elif event.is_action_pressed("interact"):
		_interact()

func _switch_day(target: int) -> void:
	if target < 0 or target >= StageMap.DAY_COUNT:
		return
	if not map.fits(target as StageMap.Day, player.position.x, StagePlayer.BODY_WIDTH * 0.5):
		Events.thought_requested.emit(NO_ROOM_THOUGHT, THOUGHT_HOLD)
		return
	day = target as StageMap.Day
	GameState.shift_stability(-SWITCH_COST)
	_apply_day()
	_flash_screen()
	_drop_if_exhausted()

func _apply_day() -> void:
	_refresh_view()
	keyring.show_day(day)
	core.apply_look(looks[day])
	for d in _blockers:
		for body in _blockers[d]:
			body.collision_layer = 1 if d == day else 0

# Lo que se ve del día actual y de lo que se lleva; cambiar de día además
# cambia el llavero, el look y qué cajas bloquean (_apply_day).
func _refresh_view() -> void:
	view.show_state(day, _hinge_on_shelf())

func _flash_screen() -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash.modulate.a = FLASH_ALPHA
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "modulate:a", 0.0, FLASH_TIME)

# Mientras alguien la lleva o ya se entregó, deja de estar en el estante.
func _hinge_on_shelf() -> bool:
	return carried != ITEM_HINGE and not served

func _nearest_target() -> Target:
	var col := StageMap.col_of(player.position.x)
	var best := Target.NONE
	var best_distance := StageMap.REACH + 1
	for target: Target in TARGET_CHARS:
		if target == Target.HINGE and not _hinge_on_shelf():
			continue
		var at := map.first_column(day, TARGET_CHARS[target])
		if at < 0:
			continue
		var distance := absi(col - at)
		if distance < best_distance:
			best_distance = distance
			best = target
	return best

func _update_hint() -> void:
	var target := _nearest_target()
	var text := ""
	if target == Target.NEIGHBOR and carried == ITEM_HINGE:
		text = HINT_DELIVER
	elif target != Target.NONE:
		text = HINT_TEXTS[target]
	elif carried != NO_ITEM:
		text = HINT_DROP
	_hint.visible = text != "" and not _ending
	if _hint.text != text:
		_hint.text = text
	_hint.position = player.position + HINT_OFFSET

func _interact() -> void:
	match _nearest_target():
		Target.HINGE:
			_pick_up(ITEM_HINGE)
		Target.BOOK:
			_read_book()
		Target.NEIGHBOR:
			_talk_to_neighbor()
		Target.TOMAS:
			_talk_to_tomas()
		Target.NONE:
			if carried != NO_ITEM:
				_drop(DROP_THOUGHT)

func _pick_up(item: StringName) -> void:
	if carried != NO_ITEM:
		Events.thought_requested.emit(HANDS_FULL_THOUGHT, THOUGHT_HOLD)
		return
	carried = item
	_refresh_view()
	Events.thought_requested.emit(HINGE_THOUGHT, THOUGHT_HOLD)

# Lo soltado vuelve a su lugar: no hay suelo donde dejar cosas, así que cargar
# algo es siempre una decisión.
func _drop(thought: String) -> void:
	carried = NO_ITEM
	_refresh_view()
	Events.thought_requested.emit(thought, THOUGHT_HOLD)

func _drop_if_exhausted() -> void:
	if carried != NO_ITEM and GameState.stability <= 0.0:
		_drop(EXHAUSTED_THOUGHT)

func _read_book() -> void:
	Events.message_requested.emit(BOOK_LINES[day])
	if day == StageMap.Day.HOY and served:
		Events.message_requested.emit(BOOK_SERVED_LINE)

func _talk_to_neighbor() -> void:
	if served:
		Events.message_requested.emit(NEIGHBOR_THANKS)
	elif carried != NO_ITEM:
		_deliver(DELIVERIES[carried])
	else:
		Events.message_requested.emit(NEIGHBOR_ASKS)

func _deliver(lines: Dictionary) -> void:
	carried = NO_ITEM
	served = true
	_refresh_view()
	for key in ["give", "client", "tomas", "narration"]:
		Events.message_requested.emit(lines[key])
	# El mensaje pausa la escena: el pensamiento llega recién cuando se lo cierra.
	await _wait(DELIVERY_THOUGHT_DELAY)
	Events.thought_requested.emit(lines.thought, THOUGHT_HOLD)

func _talk_to_tomas() -> void:
	if not served:
		Events.message_requested.emit(TOMAS_NOT_YET)
		return
	if accompanying:
		return
	accompanying = true
	_accompany_time = 0.0
	_lines_said = 0
	Events.message_requested.emit(TOMAS_OPENS_UP)

# Acompañar es quedarse: si te vas o cambias de día, Tomás calla y hay que
# volver a empezar.
func _update_accompany(delta: float) -> void:
	if not accompanying or _ending:
		return
	var at := map.first_column(day, StageMap.TOMAS)
	if at < 0 or not StageMap.within_reach(StageMap.col_of(player.position.x), at):
		accompanying = false
		Events.thought_requested.emit(SILENT_THOUGHT, THOUGHT_HOLD)
		return
	_accompany_time += delta
	if _accompany_time < _lines_said * ACCOMPANY_STEP:
		return
	if _lines_said < TOMAS_LINES.size():
		Events.thought_requested.emit(TOMAS_LINES[_lines_said], ACCOMPANY_HOLD)
		_lines_said += 1
	else:
		_finish()

func _finish() -> void:
	finished.emit()
	_ending = true
	accompanying = false
	player.set_locked(true)
	Events.message_requested.emit(TOMAS_ENDING)
	await _wait(ENDING_BREATH)
	SceneRouter.change_scene(TOWN_SCENE)

# Un Timer hijo de la escena y no uno del árbol: si la escena se cierra a mitad
# de la secuencia, el Timer se va con ella. Como la escena se pausa con el
# mensaje, espera también a que se lea.
func _wait(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(seconds)
	await timer.timeout
	timer.queue_free()
