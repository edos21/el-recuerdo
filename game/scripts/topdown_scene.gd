class_name TopDownScene
extends Node2D
# Arranque común de las escenas cenitales del mundo real (el pueblo, los
# interiores): arma el mapa, la atmósfera y el look, y conecta al jugador con
# el HUD. Qué mapa, qué look y qué suena son datos de cada .tscn; lo que pasa
# en la escena (pensamientos, guion) lo agrega un script propio que extiende
# este, después de super._ready().

const WIND_FADE := 2.0
const PAD_FADE := 4.0

@export_file("*.txt") var level_path := ""
@export var look: WorldLook
# Lo que queda fuera del mapa (el pasto de afuera, la oscuridad de un cuarto).
@export var clear_color := Color.BLACK
@export var wind_db := -20.0
@export var pad_db := -24.0

@onready var core: Core = $Core
@onready var loader: TopDownLoader = $Loader
@onready var atmosphere: TopDownAtmosphere = $Atmosphere

var player: CharacterBody2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(clear_color)
	GameState.ensure_defaults()
	player = loader.build(level_path)
	atmosphere.build(player, loader.bounds)
	core.apply_look(look)
	core.bind_player(player, player.camera)
	_restore_hud()
	core.audio.set_muffled(false)
	core.audio.set_layer("wind", wind_db, WIND_FADE)
	core.audio.set_layer("pad", pad_db, PAD_FADE)
	player.health_changed.connect(core.hud.set_health)
	player.stability_changed.connect(core.hud.set_stability)
	player.low_stability_changed.connect(core.hud.set_low_stability)
	# El jugador ya emitio en su _ready, antes de estas conexiones.
	core.hud.set_health(player.health, player.max_health)
	core.hud.set_stability(player.stability, player.max_stability)
	core.hud.set_low_stability(GameState.is_low_stability(player.stability, player.max_stability))

# Los recuerdos ya recuperados siguen encendidos en el HUD.
func _restore_hud() -> void:
	for ability in GameState.abilities:
		core.hud.note_ability_unlocked(ability)
	if GameState.has_ability("health"):
		core.hud.show_health_bar()
	if GameState.has_ability("stability"):
		core.hud.show_stability_bar()
