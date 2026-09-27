extends TopDownScene
# Interior de la posada: el cuarto donde el protagonista despierta y adonde
# vuelve a descansar. Por ahora se puede recorrer; el despertar viene aparte.

const LEVEL_PATH := "res://levels/inn.txt"
const DARK_COLOR := Color(0.07, 0.06, 0.09)
const AMBIENT_WIND_DB := -34.0
const AMBIENT_PAD_DB := -24.0
const INN_LOOK := preload("res://looks/inn_look.tres")

func _level_path() -> String:
	return LEVEL_PATH

# Adentro no hay cielo ni desenfoque de distancia: solo penumbra.
func _look() -> WorldLook:
	return INN_LOOK

# Lo que rodea el cuarto se lee como oscuridad, no como un color de relleno.
func _clear_color() -> Color:
	return DARK_COLOR

# El viento se oye apagado desde adentro.
func _start_ambience() -> void:
	core.audio.set_layer("wind", AMBIENT_WIND_DB, 2.0)
	core.audio.set_layer("pad", AMBIENT_PAD_DB, 4.0)
