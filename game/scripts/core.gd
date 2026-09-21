extends Node
# Nucleo compartido entre generos: HUD (barras, recuerdos, mensajes,
# pensamientos), tinte de mundo y audio por capas. Cada escena de juego
# (plataformas, pueblo cenital, lo que venga) lo instancia y solo decide
# como se ve/suena el mundo, sin reescribir nada de esto.

@onready var hud: CanvasLayer = $HUD
@onready var audio: Node = $AudioLayers
@onready var tint_rect: ColorRect = $WorldTint/TintRect

# Mundo "real" o ya recuperado: colores plenos, sin frio ni vineta.
func set_world_look(saturation: float, cold_tint: float, vignette: float) -> void:
	var mat := tint_rect.material as ShaderMaterial
	mat.set_shader_parameter("saturation", saturation)
	mat.set_shader_parameter("cold_tint", cold_tint)
	mat.set_shader_parameter("vignette", vignette)
	mat.set_shader_parameter("focus_radius", 0.0)
