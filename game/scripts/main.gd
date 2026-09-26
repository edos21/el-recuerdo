extends Node2D

const LEVEL_PATH := "res://levels/level1.txt"
const LEVEL1_LOOK := preload("res://looks/level1_look.tres")

@onready var level_loader: Node2D = $LevelLoader
@onready var core: Core = $Core
@onready var atmosphere: Node2D = $Atmosphere
@onready var foreground: CanvasItem = $Foreground
@onready var hud: Hud = core.hud
@onready var respawn_sound: AudioStreamPlayer = $RespawnSound
@onready var world_progression: Node = $WorldProgression
@onready var audio_layers: Node = core.audio

# Cielo frio y apagado: el shader lo desatura igual, pero el tono base ya
# no dice "tarde de verano".
const SKY_COLOR := Color(0.36, 0.40, 0.47)

const TOWN_SCENE := "res://scenes/Town.tscn"
# Tiempo que se queda el pensamiento final sobre el negro antes de despertar.
const COLLAPSE_HOLD_TIME := 6.0

const DEBUG_START_CELLS := 2

var player: Node2D
var _current_checkpoint: Vector2
var _expulsion_started := false
var _reached_checkpoints := {}

func _ready() -> void:
	RenderingServer.set_default_clear_color(SKY_COLOR)
	# GameState es el dueño de las habilidades: si el Nivel 1 se vuelve a
	# cargar (F6, otra corrida), no debe arrancar con las de la vez anterior.
	GameState.reset()
	if DebugConfig.start_scene != "":
		_start_in_debug_scene()
		return
	player = level_loader.build(LEVEL_PATH)
	_current_checkpoint = player.global_position
	core.apply_look(LEVEL1_LOOK)
	core.bind_player(player, player.camera)
	world_progression.setup(player, level_loader.props_layer, audio_layers, core.world_material)
	atmosphere.build(player, foreground)
	hud.stage_provider = _reached_checkpoint_count
	hud.play_title_card()

	player.health_changed.connect(hud.set_health)
	player.stability_changed.connect(hud.set_stability)
	player.low_stability_changed.connect(hud.set_low_stability)
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

	_apply_debug_start()

# Lo que se gana fuera del Nivel 1 (LATER) no tiene objeto en el mapa: sin
# otorgarlo desde acá no habría forma de probarlo jugando.
func _start_in_debug_scene() -> void:
	for ability in DebugConfig.abilities_to_grant():
		GameState.unlock(ability)
	GameState.begin_wake_up()
	SceneRouter.change_scene.call_deferred(DebugConfig.start_scene)

func _apply_debug_start() -> void:
	for ability in DebugConfig.abilities_to_grant():
		player.unlock(ability)
	if not DebugConfig.start_at_level_end:
		return
	var last_checkpoint: Node2D
	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		_reached_checkpoints[checkpoint] = true
		if not last_checkpoint or checkpoint.global_position.x > last_checkpoint.global_position.x:
			last_checkpoint = checkpoint
	_current_checkpoint = last_checkpoint.global_position
	# Un par de celdas al costado para no arrancar pisando el banco, que
	# frenaria el juego con su mensaje de primera vez.
	player.global_position = _current_checkpoint + Vector2(DEBUG_START_CELLS * level_loader.CELL, 0.0)

func _reached_checkpoint_count() -> int:
	return _reached_checkpoints.size()

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

func _on_kill_zone_entered(body: Node2D) -> void:
	if body == player:
		player.request_respawn()

func _on_respawn_requested() -> void:
	respawn_sound.play()
	if GameState.has_ability("sprint"):
		Events.hint_requested.emit("fall_with_sprint", "Caminando no llego. Tengo que correr antes de saltar.")
	elif GameState.has_ability("jump"):
		Events.hint_requested.emit("fall_first", "Caí. No pasa nada: el banco me trae de vuelta.")
	player.global_position = _current_checkpoint
	player.velocity = Vector2.ZERO
	player.restore_vitals()

func _on_player_died() -> void:
	# Con un nivel de 15 minutos, recargar la escena entera al morir era
	# perder todo el progreso: la muerte te devuelve al ultimo banco, igual
	# que caer al vacio, pero con un mensaje propio.
	Events.hint_requested.emit("died", "Todo se apaga un momento. Cuando vuelvo a abrir los ojos estoy en el banco otra vez.")
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
