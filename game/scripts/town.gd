extends Node2D
# Pueblo real: donde el protagonista despierta despues de la expulsion. Por
# ahora es una plaza de prueba caminable con dos NPCs; el guion, los interiores
# y el primer recuerdo ajeno vienen despues.

const LEVEL_PATH := "res://levels/town.txt"
const GRASS_COLOR := Color(0.31, 0.42, 0.24)
const WAKE_THOUGHT := "Todo se ve... distinto. Como si me faltara algo."
const WAKE_THOUGHT_DELAY := 2.0
const AMBIENT_WIND_DB := -20.0
const AMBIENT_PAD_DB := -24.0

@onready var core: Node = $Core
@onready var town_loader: Node2D = $TownLoader
@onready var atmosphere: Node2D = $Atmosphere

var player: CharacterBody2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(GRASS_COLOR)
	GameState.ensure_defaults()
	player = town_loader.build(LEVEL_PATH)
	atmosphere.build(player)
	# Mundo real: color pleno, sin el frio ni la vineta del recuerdo.
	core.set_world_look(1.0, 0.0, 0.0)
	_restore_hud()
	_start_ambience()
	player.health_changed.connect(core.hud.set_health)
	player.stability_changed.connect(core.hud.set_stability)
	player.health_changed.emit(player.health, player.max_health)
	player.stability_changed.emit(player.stability, player.max_stability)
	if GameState.came_from_expulsion:
		await get_tree().create_timer(WAKE_THOUGHT_DELAY).timeout
		core.hud.show_thought(WAKE_THOUGHT)

# Los recuerdos ya recuperados siguen encendidos en el HUD.
func _restore_hud() -> void:
	for ability in GameState.abilities:
		core.hud.note_ability_unlocked(ability)
	if GameState.has_ability("health"):
		core.hud.show_health_bar()
	if GameState.has_ability("stability"):
		core.hud.show_stability_bar()

func _start_ambience() -> void:
	core.audio.set_muffled(false)
	core.audio.set_layer("wind", AMBIENT_WIND_DB, 2.0)
	core.audio.set_layer("pad", AMBIENT_PAD_DB, 4.0)
