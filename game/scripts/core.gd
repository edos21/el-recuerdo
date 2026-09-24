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
const BLUR_SHADER := preload("res://shaders/world_post.gdshader")
const SHARP_SHADER := preload("res://shaders/world_post_sharp.gdshader")

@onready var hud: CanvasLayer = $HUD
@onready var audio: Node = $AudioLayers
@onready var world_material: ShaderMaterial = $WorldPost/PostRect.material

var _camera: Camera2D
var _needs_view := false

func _ready() -> void:
	$WorldPost.layer = WORLD_MAX_CANVAS_LAYER
	hud.layer = HUD_LAYER
	set_process(false)

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

func _process(_delta: float) -> void:
	var view_size := get_viewport().get_visible_rect().size / _camera.zoom
	world_material.set_shader_parameter("view_size", view_size)
	world_material.set_shader_parameter("view_origin", _camera.get_screen_center_position() - view_size * 0.5)

func _on_stability_changed(current: float, max_value: float) -> void:
	world_material.set_shader_parameter("instability", 1.0 - current / max_value)
