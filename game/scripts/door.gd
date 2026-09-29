class_name Door
extends Area2D
# Umbral que se cruza caminando: al pisarlo el jugador, cambia de escena con
# fundido. `spawn_point` es donde aparece quien llega por esta puerta desde la
# otra escena: queda afuera del umbral, para no volver a cruzarlo al aparecer.

var id: StringName
var target_scene := ""
var spawn_point := Vector2.ZERO

func _init(door_id: StringName, scene_path: String, trigger: Rect2, arrival: Vector2) -> void:
	id = door_id
	target_scene = scene_path
	spawn_point = arrival
	collision_layer = 0
	collision_mask = 1
	position = trigger.get_center()
	add_child(MapUtils.rect_shape(trigger.size))
	body_entered.connect(_on_body_entered)

# Los NPCs también están en la capa 1: solo el jugador cruza.
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	# Con un fundido en curso el cambio no ocurriría: la llegada quedaría
	# pendiente para una puerta que nunca se cruzó.
	if SceneRouter.is_busy():
		return
	GameState.arrival_door = id
	# Durante el fundido ya se está yendo: no sigue caminando por la escena que deja.
	body.set_locked(true)
	SceneRouter.change_scene(target_scene)
