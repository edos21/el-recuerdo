extends Node2D

const LEVEL_PATH := "res://levels/level1.txt"

@onready var level_loader: Node2D = $LevelLoader
@onready var core: Node = $Core
@onready var hud := $Core/HUD
@onready var respawn_sound: AudioStreamPlayer = $RespawnSound
@onready var world_progression: Node = $WorldProgression
@onready var audio_layers: Node = $Core/AudioLayers

# Cielo frio y apagado: el shader lo desatura igual, pero el tono base ya
# no dice "tarde de verano".
const SKY_COLOR := Color(0.36, 0.40, 0.47)

# Para probar combate sin recorrer el nivel entero: todas las habilidades y
# aparecer junto al ultimo banco. Se activa desde el inspector de Main.
@export var debug_start_at_end := false

const TOWN_SCENE := "res://scenes/Town.tscn"
# Tiempo que se queda el pensamiento final sobre el negro antes de despertar.
const COLLAPSE_HOLD_TIME := 6.0

const DEBUG_ABILITIES := ["jump", "sprint", "stability", "health", "attack"]
const DEBUG_START_OFFSET := Vector2(2 * 36.0, 0.0)

var player: Node2D
var _current_checkpoint: Vector2
var _expulsion_started := false
var _reached_checkpoints := {}

func _ready() -> void:
	RenderingServer.set_default_clear_color(SKY_COLOR)
	player = level_loader.build(LEVEL_PATH)
	_current_checkpoint = player.global_position
	world_progression.setup(player, level_loader.props_layer, audio_layers)
	hud.play_title_card()

	player.health_changed.connect(hud.set_health)
	player.stability_changed.connect(hud.set_stability)
	player.ability_unlocked.connect(_on_ability_unlocked)
	player.respawn_requested.connect(_on_respawn_requested)
	player.died.connect(_on_player_died)

	var kill_zone := get_tree().get_first_node_in_group("kill_zone")
	if kill_zone:
		kill_zone.body_entered.connect(_on_kill_zone_entered)

	for trigger in get_tree().get_nodes_in_group("expulsion_trigger"):
		trigger.body_entered.connect(_on_expulsion_triggered)
	player.collapsed.connect(_on_player_collapsed)

	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		checkpoint.activated.connect(_on_checkpoint_activated.bind(checkpoint))

	if debug_start_at_end:
		_apply_debug_start()

func _apply_debug_start() -> void:
	for ability in DEBUG_ABILITIES:
		player.unlock(ability)
	var last_checkpoint: Node2D
	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		_reached_checkpoints[checkpoint] = true
		if not last_checkpoint or checkpoint.global_position.x > last_checkpoint.global_position.x:
			last_checkpoint = checkpoint
	hud.set_checkpoints_reached(_reached_checkpoints.size())
	_current_checkpoint = last_checkpoint.global_position
	# Un par de celdas al costado para no arrancar pisando el banco, que
	# frenaria el juego con su mensaje de primera vez.
	player.global_position = _current_checkpoint + DEBUG_START_OFFSET

func _on_ability_unlocked(ability: String) -> void:
	hud.note_ability_unlocked(ability)
	match ability:
		"health":
			hud.show_health_bar()
			hud.set_health(player.health, player.max_health)
		"stability":
			hud.show_stability_bar()
			hud.set_stability(player.stability, player.max_stability)
	world_progression.advance_to(ability)

func _on_checkpoint_activated(checkpoint: Node2D) -> void:
	_current_checkpoint = checkpoint.global_position
	_reached_checkpoints[checkpoint] = true
	hud.set_checkpoints_reached(_reached_checkpoints.size())

func _on_kill_zone_entered(body: Node2D) -> void:
	if body == player:
		player.request_respawn()

func _on_respawn_requested() -> void:
	respawn_sound.play()
	if player.can_sprint:
		hud.show_hint_once("fall_with_sprint", "Caminando no llego. Tengo que correr antes de saltar.")
	elif player.can_jump:
		hud.show_hint_once("fall_first", "Caí. No pasa nada: el banco me trae de vuelta.")
	player.global_position = _current_checkpoint
	player.velocity = Vector2.ZERO
	player.restore_vitals()

func _on_player_died() -> void:
	# Con un nivel de 15 minutos, recargar la escena entera al morir era
	# perder todo el progreso: la muerte te devuelve al ultimo banco, igual
	# que caer al vacio, pero con un mensaje propio.
	hud.show_hint_once("died", "Todo se apaga un momento. Cuando vuelvo a abrir los ojos estoy en el banco otra vez.")
	_on_respawn_requested()

# El recuerdo expulsa al protagonista: no hay puerta que cruzar, solo el
# desgaste hasta desplomarse. Lo que sigue (despertar en el pueblo real)
# engancha en `player.collapsed`.
func _on_expulsion_triggered(body: Node2D) -> void:
	if body != player or _expulsion_started:
		return
	_expulsion_started = true
	player.begin_expulsion()
	world_progression.begin_expulsion()

func _on_player_collapsed() -> void:
	world_progression.collapse()
	await get_tree().create_timer(COLLAPSE_HOLD_TIME).timeout
	GameState.capture_from_platformer(player)
	GameState.begin_wake_up()
	SceneRouter.change_scene(TOWN_SCENE)
