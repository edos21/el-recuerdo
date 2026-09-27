class_name TopDownScene
extends Node2D
# Arranque común de las escenas cenitales del mundo real (el pueblo, los
# interiores): arma el mapa, la atmósfera y el look, y conecta al jugador con
# el HUD. Cada escena dice qué mapa, qué look y qué suena; lo que pasa en ella
# (pensamientos, guion) lo agrega su propio script después de super._ready().

@onready var core: Core = $Core
@onready var loader: TopDownLoader = $Loader
@onready var atmosphere: Node2D = $Atmosphere

var player: CharacterBody2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(_clear_color())
	GameState.ensure_defaults()
	player = loader.build(_level_path())
	atmosphere.build(player, loader.bounds)
	core.apply_look(_look())
	core.bind_player(player, player.camera)
	_restore_hud()
	core.audio.set_muffled(false)
	_start_ambience()
	player.health_changed.connect(core.hud.set_health)
	player.stability_changed.connect(core.hud.set_stability)
	player.low_stability_changed.connect(core.hud.set_low_stability)
	# El jugador ya emitio en su _ready, antes de estas conexiones.
	core.hud.set_health(player.health, player.max_health)
	core.hud.set_stability(player.stability, player.max_stability)
	core.hud.set_low_stability(GameState.is_low_stability(player.stability, player.max_stability))

func _level_path() -> String:
	return ""

func _look() -> WorldLook:
	return null

func _clear_color() -> Color:
	return Color.BLACK

func _start_ambience() -> void:
	pass

# Los recuerdos ya recuperados siguen encendidos en el HUD.
func _restore_hud() -> void:
	for ability in GameState.abilities:
		core.hud.note_ability_unlocked(ability)
	if GameState.has_ability("health"):
		core.hud.show_health_bar()
	if GameState.has_ability("stability"):
		core.hud.show_stability_bar()
