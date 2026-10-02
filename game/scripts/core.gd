class_name Core
extends Node
# Nucleo compartido entre generos: HUD (barras, recuerdos, mensajes,
# pensamientos), post-proceso de mundo y audio por capas. Cada escena de juego
# (plataformas, pueblo cenital, lo que venga) lo instancia y solo decide
# como se ve/suena el mundo, sin reescribir nada de esto.

# Orden de pantalla: el mundo y su post-proceso llegan hasta WORLD_MAX (el
# glow de una escena tampoco pasa de ahi); los fundidos sobre el mundo van
# en WORLD_OVERLAY y el HUD queda encima de todo, sin tinte ni glow.
const WORLD_MAX_CANVAS_LAYER := 1
const WORLD_OVERLAY_LAYER := 2
const HUD_LAYER := 3
# El menu va sobre el HUD y bajo el fundido de SceneRouter (capa 20).
const MENU_LAYER := 4
const BLUR_SHADER := preload("res://shaders/world_post.gdshader")
const SHARP_SHADER := preload("res://shaders/world_post_sharp.gdshader")

# Desde donde se juega la escena. Decide que abre Esc: en un recuerdo ajeno el
# cuaderno del protagonista no existe y solo hay una pausa minima.
enum Context { HUB, OWN_MEMORY, OTHER_MEMORY }

@export var context := Context.HUB

@onready var hud: Hud = %HUD
@onready var audio: Node = %AudioLayers
@onready var world_material: ShaderMaterial = %PostRect.material

var menu: PauseMenu
var _camera: Camera2D
var _needs_view := false

func _ready() -> void:
	%WorldPost.layer = WORLD_MAX_CANVAS_LAYER
	hud.layer = HUD_LAYER
	menu = PauseMenu.new()
	menu.layer = MENU_LAYER
	add_child(menu)
	set_process(false)

# Un recuerdo ajeno no tiene cuaderno aunque ya se tenga el libro.
func notebook_available() -> bool:
	return GameState.has_notebook and context != Context.OTHER_MEMORY

func apply_look(look: WorldLook) -> void:
	world_material.shader = BLUR_SHADER if look.needs_blur() else SHARP_SHADER
	_needs_view = look.needs_view()
	set_process(_camera != null and _needs_view)
	var params := look.shader_params()
	for param in params:
		world_material.set_shader_parameter(param, params[param])

# Unico lugar donde la Estabilidad del jugador llega al post-proceso; la
# camara ancla al mundo las nubes y los rayos.
func bind_player(player: CharacterBody2D, camera: Camera2D) -> void:
	_camera = camera
	player.stability_changed.connect(_on_stability_changed)
	# El jugador ya emitio su Estabilidad en su _ready, antes de este enlace.
	_on_stability_changed(player.stability, player.max_stability)
	set_process(_needs_view)

# Conecta las barras a las señales de Vida y Estabilidad del jugador de cada
# género, con el mismo contrato en todos, y las pone al día.
func bind_hud(player: CharacterBody2D) -> void:
	player.health_changed.connect(hud.set_health)
	player.stability_changed.connect(hud.set_stability)
	player.low_stability_changed.connect(hud.set_low_stability)
	# El jugador ya emitio en su _ready, antes de estas conexiones.
	hud.set_health(player.health, player.max_health)
	hud.set_stability(player.stability, player.max_stability)
	hud.set_low_stability(GameState.is_low_stability(player.stability, player.max_stability))

# Los recuerdos ya recuperados siguen encendidos en el HUD al cambiar de escena.
func restore_hud() -> void:
	for ability in GameState.abilities:
		hud.note_ability_unlocked(ability)
	if GameState.has_ability("health"):
		hud.show_health_bar()
	if GameState.has_ability("stability"):
		hud.show_stability_bar()

func _process(_delta: float) -> void:
	var view_size := get_viewport().get_visible_rect().size / _camera.zoom
	world_material.set_shader_parameter("view_size", view_size)
	world_material.set_shader_parameter("view_origin", _camera.get_screen_center_position() - view_size * 0.5)

func _on_stability_changed(current: float, max_value: float) -> void:
	world_material.set_shader_parameter("instability", 1.0 - current / max_value)
