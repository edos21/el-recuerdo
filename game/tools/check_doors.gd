extends Node
# godot --headless --fixed-fps 60 --path . res://tools/check_doors.tscn
# Comprueba las puertas entre el pueblo y la posada sin jugar: quien llega por
# una puerta aparece en la puerta con el mismo id de la otra escena, afuera de
# su umbral (si no, volvería a cruzarla al aparecer), y la llegada se consume;
# sin llegada, se aparece en 'P'; y pisar el umbral guarda la puerta de llegada.
# Imprime FAIL por cada chequeo roto y sale con código 1. Corre como escena y
# no como `--script` porque los autoloads no compilan en ese modo.

const TOWN_SCENE := preload("res://scenes/Town.tscn")
const INN_SCENE := preload("res://scenes/Inn.tscn")
# Frames de física para que las áreas registren lo que ya las pisa.
const SETTLE_FRAMES := 3
# El jugador puede aparecer tocando una pared (la 'P' del cuarto está junto al
# borde de abajo) y el motor lo separa por su margen de colisión: fracciones de px.
const POSITION_TOLERANCE := 1.0

var _failures := 0
var _scene: TopDownScene
var _step := 0
var _frames := 0

func _ready() -> void:
	GameState.reset()
	GameState.ensure_defaults()
	_load(INN_SCENE, DoorData.POSADA)

func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames < SETTLE_FRAMES:
		return
	_frames = 0
	match _step:
		0:
			_check_arrival("posada por dentro")
			_swap(TOWN_SCENE, DoorData.POSADA)
		1:
			_check_arrival("posada por fuera")
			_swap(INN_SCENE, &"")
		2:
			_check_default_spawn()
			_check_crossing()
		3:
			print("check_doors: %s" % ("OK" if _failures == 0 else "%d FALLOS" % _failures))
			get_tree().quit(0 if _failures == 0 else 1)
	_step += 1

func _load(scene: PackedScene, arrival: StringName) -> void:
	GameState.arrival_door = arrival
	_scene = scene.instantiate()
	add_child(_scene)

func _swap(scene: PackedScene, arrival: StringName) -> void:
	_scene.free()
	_load(scene, arrival)

func _door(id: StringName) -> Door:
	for door in _scene.loader._doors:
		if door.id == id:
			return door
	return null

func _check_arrival(label: String) -> void:
	var door := _door(DoorData.POSADA)
	_expect(door != null, "%s: el mapa tiene la puerta" % label)
	if door == null:
		return
	_expect(_scene.player.position.distance_to(door.spawn_point) < POSITION_TOLERANCE, "%s: se aparece en la puerta de llegada" % label)
	_expect(not door.overlaps_body(_scene.player), "%s: se aparece afuera del umbral" % label)
	_expect(GameState.arrival_door == &"", "%s: la llegada se consume" % label)

func _check_default_spawn() -> void:
	_expect(_scene.player.position.distance_to(_scene.loader._spawn) < POSITION_TOLERANCE, "sin llegada, se aparece en 'P'")

# Con el jugador real sobre el umbral: la puerta guarda la llegada y pide el
# cambio de escena (el fundido tarda más que lo que queda de este chequeo).
func _check_crossing() -> void:
	var door := _door(DoorData.POSADA)
	door._on_body_entered(_scene.player)
	_expect(GameState.arrival_door == DoorData.POSADA, "cruzar la puerta guarda la llegada")

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % description)
