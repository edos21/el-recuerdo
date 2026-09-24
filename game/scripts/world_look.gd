class_name WorldLook
extends Resource
# Como se ve el mundo de una escena a traves del post-proceso de Core
# (world_post.gdshaderinc). Cada escena elige el suyo; lo que cambia en juego
# (progresion de color, Estabilidad) lo mueven otros scripts encima de esto.
# Los valores por defecto no hacen nada: un look nuevo arranca neutro.

@export_group("Color")
@export_range(0.0, 1.0) var saturation := 1.0
@export_range(0.0, 1.0) var cold_tint := 0.0
@export_range(0.0, 1.0) var vignette := 0.0
@export_range(0.0, 1.0) var grade_strength := 0.0

@export_group("Foco (tilt-shift)")
@export var tilt_center := 0.56
@export var tilt_band := 0.32
@export var tilt_soft := 0.32
# Desenfoque con Estabilidad plena (min) y sin Estabilidad (max).
@export var blur_lod_min := 0.0
@export var blur_lod_max := 0.0
@export var aberration_px := 0.0

@export_group("Cielo")
@export var cloud_strength := 0.0
@export var cloud_scale := 1100.0
@export var cloud_wind := Vector2(14.0, 6.0)
@export var ray_strength := 0.0

# Solo el desenfoque necesita mipmaps de la pantalla (ver world_post.gdshaderinc).
func needs_blur() -> bool:
	return blur_lod_min > 0.0 or blur_lod_max > 0.0

# Nubes y rayos se anclan al mundo: necesitan saber donde mira la camara.
func needs_view() -> bool:
	return cloud_strength > 0.0 or ray_strength > 0.0

func shader_params() -> Dictionary:
	return {
		"saturation": saturation,
		"cold_tint": cold_tint,
		"vignette": vignette,
		"grade_strength": grade_strength,
		"tilt_center": tilt_center,
		"tilt_band": tilt_band,
		"tilt_soft": tilt_soft,
		"blur_lod_min": blur_lod_min,
		"blur_lod_max": blur_lod_max,
		"aberration_px": aberration_px,
		"cloud_strength": cloud_strength,
		"cloud_scale": cloud_scale,
		"cloud_wind": cloud_wind,
		"ray_strength": ray_strength,
		# El parche de color es de la progresion del Nivel 1, no del look.
		"focus_radius": 0.0,
	}
