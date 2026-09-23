class_name Npc
extends CharacterBody2D
# Personaje del pueblo: se le habla con `interact` estando cerca. Las lineas
# van por la cola de mensajes del HUD (misma tecla y mismo cuadro que los
# textos de recuerdo: el jugador ya sabe como funciona).
#
# La personalidad no esta solo en lo que dice sino en como se mueve: da
# vueltas cerca de su lugar, se detiene a mirar alrededor, reacciona cuando el
# jugador se acerca (segun su `attitude`) y a veces suelta una frase al pasar.

# Como reacciona cuando el jugador se acerca.
enum Attitude {
	CURIOUS,  # se da vuelta a mirarlo y lo sigue con la mirada
	EVASIVE,  # esquiva la mirada y sigue con lo suyo
}

enum State { IDLE, WALK, NOTICE }

const NOTICE_RADIUS := 150.0
const IDLE_TIME_MIN := 1.5
const IDLE_TIME_MAX := 4.0
const GLANCE_CHANCE := 0.5
const WANDER_TIMEOUT := 3.0
const ARRIVE_DISTANCE := 4.0
const EMOTE_CHANCE := 0.25
const BARK_COOLDOWN := 12.0
const BARK_HOLD := 2.6
# Respiracion: el sprite en reposo se estira un poco, casi imperceptible pero
# suficiente para que no parezca una foto.
const BREATH_AMOUNT := 0.025
const BREATH_SPEED := 2.2
const HOP_HEIGHT := 6.0
# El evasivo aguanta un momento mirando para otro lado y despues se aleja.
const EVADE_DELAY := 1.2
const DIRECTIONS := ["down", "left", "right", "up"]

@export var npc_name := ""
@export var sprite_frames_path := ""
@export var lines: PackedStringArray = []
@export var attitude := Attitude.CURIOUS
@export var wander_radius := 48.0
@export var walk_speed := 40.0
# Frases cortas que dice al pasar, sin abrir el cuadro de dialogo.
@export var barks: PackedStringArray = []
# Emotes que muestra solo, sin que nadie le hable ("?" = olvido algo).
@export var idle_emotes: PackedStringArray = []

var _state := State.IDLE
var _state_time := 0.0
var _home: Vector2
var _target: Vector2
var _facing := "down"
var _player: Node2D
var _noticed := false
var _bark_cooldown := 0.0
var _breath_time := 0.0
var _base_scale: Vector2
var _base_offset: Vector2
var _emote_tween: Tween
var _bark_tween: Tween
var _hop_tween: Tween

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hint: Label = $Hint
@onready var emote: Label = $Emote
@onready var bark: Label = $Bark
@onready var talk_zone: Area2D = $TalkZone

# Los datos vienen de data/town_npcs.gd: cada campo nuevo se agrega aca, no en el loader.
func configure(data: Dictionary) -> void:
	npc_name = data.name
	sprite_frames_path = data.frames
	lines = PackedStringArray(data.lines)
	attitude = data.attitude
	wander_radius = data.wander_radius
	walk_speed = data.walk_speed
	barks = PackedStringArray(data.barks)
	idle_emotes = PackedStringArray(data.idle_emotes)

func _ready() -> void:
	if sprite_frames_path != "":
		sprite.sprite_frames = load(sprite_frames_path)
	_home = position
	_base_scale = sprite.scale
	_base_offset = sprite.position
	_breath_time = randf() * TAU
	hint.visible = false
	emote.modulate.a = 0.0
	bark.modulate.a = 0.0
	_enter_idle()
	talk_zone.area_entered.connect(_on_zone_area_entered)
	talk_zone.area_exited.connect(_on_zone_area_exited)

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	_bark_cooldown = maxf(_bark_cooldown - delta, 0.0)
	_state_time -= delta
	_update_awareness()
	match _state:
		State.IDLE:
			_process_idle()
		State.WALK:
			_process_walk()
		State.NOTICE:
			_process_notice()
	sprite.play(("walk_" if _state == State.WALK else "idle_") + _facing)
	_breathe(delta)

func interact(player: Node2D) -> void:
	_face_towards(player.global_position)
	# El dialogo pausa el arbol: hay que girar ya, no en el proximo frame.
	sprite.play("idle_" + _facing)
	_hop()
	for i in lines.size():
		var text := lines[i]
		if i == 0 and npc_name != "":
			text = "%s: %s" % [npc_name, text]
		Events.message_requested.emit(text)

func _update_awareness() -> void:
	if _player == null:
		return
	var near := global_position.distance_to(_player.global_position) < NOTICE_RADIUS
	if near and not _noticed:
		_noticed = true
		_on_player_noticed()
	elif not near and _noticed:
		_noticed = false
		_enter_idle()

func _on_player_noticed() -> void:
	_state = State.NOTICE
	velocity = Vector2.ZERO
	match attitude:
		Attitude.CURIOUS:
			_show_emote("!")
			_hop()
		Attitude.EVASIVE:
			_show_emote("...")
			_face(Facing.from_direction(global_position - _player.global_position))
			_state_time = EVADE_DELAY
	_try_bark()

func _process_notice() -> void:
	# El curioso sigue al jugador con la mirada; el evasivo ya miro para otro lado.
	if attitude == Attitude.CURIOUS:
		_face_towards(_player.global_position)
	elif _state_time <= 0.0:
		_start_walk(_home - _player.global_position)

func _process_idle() -> void:
	if _state_time > 0.0:
		return
	if randf() < GLANCE_CHANCE:
		# Mira alrededor antes de moverse, como quien busca algo que no encuentra.
		_face(DIRECTIONS[randi() % DIRECTIONS.size()])
		if not idle_emotes.is_empty() and randf() < EMOTE_CHANCE:
			_show_emote(idle_emotes[randi() % idle_emotes.size()])
		_state_time = randf_range(IDLE_TIME_MIN, IDLE_TIME_MAX)
		return
	_start_walk()

# `away` != cero sesga el paseo en esa direccion (el evasivo se aleja del jugador).
func _start_walk(away := Vector2.ZERO) -> void:
	var direction := Vector2.from_angle(randf() * TAU)
	if away != Vector2.ZERO:
		direction = (away.normalized() + direction * 0.4).normalized()
	_target = _home + direction * randf_range(wander_radius * 0.3, wander_radius)
	_state = State.WALK
	_state_time = WANDER_TIMEOUT

func _process_walk() -> void:
	var offset := _target - position
	# Si choca con algo (una casa, el jugador) no insiste: se queda y vuelve a pensar.
	if offset.length() < ARRIVE_DISTANCE or _state_time <= 0.0:
		_enter_idle()
		return
	velocity = offset.normalized() * walk_speed
	move_and_slide()
	_facing = Facing.from_direction(velocity)

func _enter_idle() -> void:
	_state = State.IDLE
	velocity = Vector2.ZERO
	_state_time = randf_range(IDLE_TIME_MIN, IDLE_TIME_MAX)

func _breathe(delta: float) -> void:
	if _state == State.WALK:
		sprite.scale = _base_scale
		return
	_breath_time += delta * BREATH_SPEED
	var stretch := sin(_breath_time) * BREATH_AMOUNT
	sprite.scale = _base_scale * Vector2(1.0 - stretch * 0.5, 1.0 + stretch)

func _hop() -> void:
	sprite.position = _base_offset
	_hop_tween = _restart(_hop_tween)
	_hop_tween.tween_property(sprite, "position:y", _base_offset.y - HOP_HEIGHT, 0.09) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop_tween.tween_property(sprite, "position:y", _base_offset.y, 0.14) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

# El globo aparece con un rebote (escala de 0 a un poco mas de 1) y se desvanece.
func _show_emote(symbol: String) -> void:
	emote.text = symbol
	emote.pivot_offset = emote.size * 0.5
	emote.scale = Vector2.ZERO
	emote.modulate.a = 1.0
	_emote_tween = _restart(_emote_tween)
	_emote_tween.tween_property(emote, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_emote_tween.tween_interval(1.2)
	_emote_tween.tween_property(emote, "modulate:a", 0.0, 0.3)

func _try_bark() -> void:
	if barks.is_empty() or _bark_cooldown > 0.0:
		return
	_bark_cooldown = BARK_COOLDOWN
	bark.text = barks[randi() % barks.size()]
	bark.modulate.a = 0.0
	_bark_tween = _restart(_bark_tween)
	_bark_tween.tween_interval(0.4)
	_bark_tween.tween_property(bark, "modulate:a", 1.0, 0.25)
	_bark_tween.tween_interval(BARK_HOLD)
	_bark_tween.tween_property(bark, "modulate:a", 0.0, 0.5)

# Un tween por efecto: el nuevo reemplaza al anterior en vez de pelearse con el.
func _restart(previous: Tween) -> Tween:
	if previous:
		previous.kill()
	return create_tween()

func _face_towards(target: Vector2) -> void:
	_face(Facing.from_direction(target - global_position))

func _face(dir: String) -> void:
	_facing = dir


# El area de interaccion del jugador es la que "entra" en la zona del NPC.
func _on_zone_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		hint.visible = true
		if _bark_tween:
			_bark_tween.kill()
		bark.modulate.a = 0.0

func _on_zone_area_exited(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		hint.visible = false
