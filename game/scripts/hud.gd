class_name Hud
extends CanvasLayer

const HEALTH_BAR_WIDTH = 240.0
# A diferencia de Vida (que nunca cambia su máximo), la Estabilidad sí puede
# crecer (el bonus del camino secundario). Por eso acá no usamos un ancho
# fijo — el fondo de la barra mide "puntos * este factor", así que una
# Estabilidad máxima más alta se ve como una barra más larga de verdad, no
# solo como el mismo ancho lleno.
const STABILITY_PIXELS_PER_POINT = 2.4
const BAR_TWEEN_TIME = 0.15
# Una caida de Estabilidad mayor a esto de golpe (un golpe recibido) hace destellar
# la barra; el goteo del sprint no.
const STABILITY_HIT_FLASH_DROP = 5.0

const ICON_SIZE = 40.0
const ICON_GAP = 8.0
const ICON_OFF_TINT = Color(0.25, 0.25, 0.3, 0.8)
# Ultimo tramo (cantidad de bancos ya alcanzados) en el que cada pista todavia
# tiene sentido. Pasado ese banco sin haberse mostrado, se descarta: si no,
# una primera caida cerca del final dispararia consejos de principiante.
const HINT_LAST_STAGE = {
	"fall_first": 1,
	"fall_with_sprint": 2,
	"avoidance": 2,
	"chaser": 2,
	"guard": 3,
}
const BAR_GROWTH_COLOR = Color(0.55, 0.72, 1.0, 1)
const BAR_GROWTH_FADE = 1.6
const DIM_TIME = 1.5
const THOUGHT_FADE_IN = 0.8
const THOUGHT_FADE_OUT = 1.2
const TITLE_HOLD = 2.0
const TITLE_FADE = 1.0

@onready var health_row: Control = %HealthRow
@onready var health_fill: ColorRect = %HealthBarFill
@onready var stability_row: Control = %StabilityRow
@onready var stability_bg: ColorRect = %StabilityBarBg
@onready var stability_fill: ColorRect = %StabilityBarFill
@onready var narrative_box: ColorRect = %NarrativeBox
@onready var narrative_label: Label = %NarrativeLabel
@onready var memory_row: Control = %MemoryRow
@onready var memory_label: Label = %MemoryLabel
@onready var memory_icons: HBoxContainer = %Icons
@onready var title_card: Control = %TitleCard
@onready var thought_label: Label = %ThoughtLabel

# Devuelve cuantos bancos lleva alcanzados el jugador; lo asigna la escena.
var stage_provider: Callable
var _message_queue: Array[String] = []
var _memories_found := 0
var _last_health := -1
var _last_stability := -1.0
var _last_max_stability := -1.0
var _icon_slots := {}
var _shown_hints := {}
var _thought_tween: Tween
var _health_tween: Tween
var _stability_tween: Tween
var _flicker_tween: Tween

func _ready() -> void:
	memory_label.text = "Recuerdos 0/%d" % MemoryData.memory_count()
	for ability in MemoryData.abilities_of([MemoryData.Kind.MEMORY]):
		_make_icon_slot(ability).modulate = ICON_OFF_TINT
	memory_icons.add_theme_constant_override("separation", int(ICON_GAP))
	thought_label.modulate.a = 0.0
	Events.hint_requested.connect(_on_hint_requested)
	Events.message_requested.connect(_on_message_requested)
	Events.thought_requested.connect(_on_thought_requested)
	Events.memory_dimmed.connect(_on_memory_dimmed)

# Tarjeta de titulo de una escena: cada una decide si la muestra y con que texto.
func play_title_card(title: String = "", subtitle: String = "") -> void:
	if title != "":
		%Title.text = title
		%Subtitle.text = subtitle
	title_card.visible = true
	title_card.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(TITLE_HOLD)
	tween.tween_property(title_card, "modulate:a", 0.0, TITLE_FADE)
	tween.tween_callback(func() -> void: title_card.visible = false)

func _make_icon_slot(ability: String) -> TextureRect:
	var slot := TextureRect.new()
	slot.texture = load(MemoryData.LIST[ability].icon)
	slot.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	memory_icons.add_child(slot)
	_icon_slots[ability] = slot
	return slot

# Las barras se actualizan casi cada frame (sprint, expulsion): se mata el tween
# anterior en vez de acumular uno nuevo por cada cambio.
func _tween_bar_width(previous: Tween, fill: ColorRect, width: float) -> Tween:
	if previous and previous.is_valid():
		previous.kill()
	var tween := create_tween()
	tween.tween_property(fill, "size:x", width, BAR_TWEEN_TIME)
	return tween

func set_health(current: int, max_value: int) -> void:
	_health_tween = _tween_bar_width(_health_tween, health_fill, HEALTH_BAR_WIDTH * (float(current) / float(max_value)))
	if _last_health >= 0 and current < _last_health:
		_flash(health_fill, Color(1.6, 0.9, 0.9, 1))
	_last_health = current

func set_stability(current: float, max_value: float) -> void:
	if max_value != _last_max_stability:
		if _last_max_stability >= 0.0 and max_value > _last_max_stability:
			_highlight_bar_growth()
		_last_max_stability = max_value
		stability_bg.size.x = STABILITY_PIXELS_PER_POINT * max_value
	_stability_tween = _tween_bar_width(_stability_tween, stability_fill, STABILITY_PIXELS_PER_POINT * current)
	if _last_stability >= 0.0 and current < _last_stability - STABILITY_HIT_FLASH_DROP:
		_flash(stability_fill, Color(1.1, 1.3, 1.8, 1))
	_last_stability = current

# Dueño del umbral: player.gd (unico emisor de low_stability_changed).
func set_low_stability(is_low: bool) -> void:
	_set_stability_flicker(is_low)

# El tramo nuevo de la barra es oscuro sobre fondo oscuro: sin esto, ampliar la
# Estabilidad maxima pasa desapercibido.
func _highlight_bar_growth() -> void:
	var resting: Color = stability_bg.color
	stability_bg.color = BAR_GROWTH_COLOR
	create_tween().tween_property(stability_bg, "color", resting, BAR_GROWTH_FADE)
	_flash(stability_fill, Color(1.6, 1.9, 2.4, 1))

func _flash(rect: ColorRect, tint: Color) -> void:
	var tween := create_tween()
	tween.tween_property(rect, "modulate", tint, 0.06)
	tween.tween_property(rect, "modulate", Color(1, 1, 1, rect.modulate.a), 0.2)

func _set_stability_flicker(active: bool) -> void:
	if _flicker_tween and _flicker_tween.is_valid():
		_flicker_tween.kill()
	stability_fill.modulate.a = 1.0
	if active:
		_flicker_tween = create_tween().set_loops()
		_flicker_tween.tween_property(stability_fill, "modulate:a", 0.4, 0.6)
		_flicker_tween.tween_property(stability_fill, "modulate:a", 1.0, 0.6)

func show_health_bar() -> void:
	health_row.visible = true

func show_stability_bar() -> void:
	stability_row.visible = true

func note_ability_unlocked(ability: String) -> void:
	if MemoryData.LIST[ability].kind == MemoryData.Kind.OPTIONAL:
		_make_icon_slot(ability)
		return
	if MemoryData.LIST[ability].kind != MemoryData.Kind.MEMORY:
		return
	_memories_found += 1
	memory_label.text = "Recuerdos %d/%d" % [_memories_found, MemoryData.memory_count()]
	var slot: TextureRect = _icon_slots[ability]
	var tween := create_tween()
	tween.tween_property(slot, "modulate", Color(1.8, 1.8, 1.8, 1), 0.15)
	tween.tween_property(slot, "modulate", Color.WHITE, 0.4)

# Los recuerdos se pierden: el ícono se apaga y el contador baja.
func _on_memory_dimmed(ability: String) -> void:
	if not _icon_slots.has(ability):
		return
	var slot: TextureRect = _icon_slots[ability]
	create_tween().tween_property(slot, "modulate", ICON_OFF_TINT, DIM_TIME)
	if MemoryData.LIST[ability].kind == MemoryData.Kind.MEMORY:
		_memories_found = maxi(_memories_found - 1, 0)
		memory_label.text = "Recuerdos %d/%d" % [_memories_found, MemoryData.memory_count()]

# Pensamiento del personaje: subtítulo que aparece y se va solo, sin pausar el
# juego (a diferencia de _on_message_requested, que frena todo hasta apretar Enter).
func _on_thought_requested(text: String, hold: float) -> void:
	if _thought_tween and _thought_tween.is_valid():
		_thought_tween.kill()
	thought_label.text = text
	_thought_tween = create_tween()
	_thought_tween.tween_property(thought_label, "modulate:a", 1.0, THOUGHT_FADE_IN)
	_thought_tween.tween_interval(hold)
	_thought_tween.tween_property(thought_label, "modulate:a", 0.0, THOUGHT_FADE_OUT)

# Mensajes de una sola vez (pistas de fallo, línea del primer checkpoint):
# la misma clave nunca se vuelve a mostrar, y las de HINT_LAST_STAGE caducan.
# El progreso es de la escena, no del HUD: sin proveedor cuenta como tramo 0.
func _current_stage() -> int:
	return stage_provider.call() if stage_provider.is_valid() else 0

func _on_hint_requested(key: String, text: String) -> void:
	if _shown_hints.has(key):
		return
	if HINT_LAST_STAGE.has(key) and _current_stage() > HINT_LAST_STAGE[key]:
		_shown_hints[key] = true
		return
	_shown_hints[key] = true
	_on_message_requested(text)

func _on_message_requested(text: String) -> void:
	_message_queue.append(text)
	if not narrative_box.visible:
		_show_next_message()

func _show_next_message() -> void:
	if _message_queue.is_empty():
		return
	narrative_label.text = _message_queue.front()
	narrative_box.visible = true
	# Un pensamiento suelto no debe encimarse con un cuadro de dialogo.
	if _thought_tween and _thought_tween.is_valid():
		_thought_tween.kill()
	thought_label.modulate.a = 0.0
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if not narrative_box.visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_message_queue.pop_front()
		if _message_queue.is_empty():
			narrative_box.visible = false
			get_tree().paused = false
		else:
			_show_next_message()
