extends CheckBase
# godot --headless --fixed-fps 60 --path . res://tools/check_doors.tscn
# Comprueba las puertas entre escenas sin jugar: quien llega por una puerta
# aparece en la puerta con el mismo id de la otra escena, afuera de su umbral
# (si no, volvería a cruzarla al aparecer), y la llegada se consume; sin
# llegada, se aparece en 'P'; cada puerta lleva a la escena del otro lado de
# DoorData; y el despertar se consume al mostrarse, así salir de la posada no
# lo repite. Imprime FAIL por cada chequeo roto y sale con código 1.

const TOWN := "res://scenes/Town.tscn"
const HALL := "res://scenes/InnHall.tscn"
const ROOM := "res://scenes/InnRoom.tscn"
# Cada escena se carga llegando por esa puerta (&"" es sin llegada: se aparece en 'P').
const CASES := [
	[HALL, DoorData.POSADA],
	[TOWN, DoorData.POSADA],
	[HALL, DoorData.POSADA_ESCALERA],
	[ROOM, DoorData.POSADA_ESCALERA],
	[ROOM, &""],
]
# Frames de física para que las áreas registren lo que ya las pisa.
const SETTLE_FRAMES := 3
# El jugador puede aparecer tocando una pared (la 'P' del cuarto está junto al
# borde de abajo) y el motor lo separa por su margen de colisión: fracciones de px.
const POSITION_TOLERANCE := 1.0

var _scene: TopDownScene
var _case := 0
var _frames := 0

func _ready() -> void:
	# Las rutas de DoorData son texto: un .tscn renombrado no las actualiza.
	for id in DoorData.LINKS:
		for path in DoorData.LINKS[id]:
			_expect(ResourceLoader.exists(path), "DoorData: la puerta '%s' apunta a %s, que no existe" % [id, path])
	GameState.reset()
	GameState.ensure_defaults()
	_load(CASES[0])

func _physics_process(_delta: float) -> void:
	_frames += 1
	if _frames < SETTLE_FRAMES:
		return
	_frames = 0
	_check(CASES[_case])
	_case += 1
	if _case < CASES.size():
		_scene.free()
		_load(CASES[_case])
		return
	_check_crossing()
	_finish("check_doors")

func _load(case: Array) -> void:
	GameState.arrival_door = case[1]
	_scene = load(case[0]).instantiate()
	add_child(_scene)

func _check(case: Array) -> void:
	var path: String = case[0]
	var arrival: StringName = case[1]
	var label := "%s por '%s'" % [path.get_file(), arrival]
	_expect(GameState.arrival_door == &"", "%s: la llegada se consume" % label)
	for door in _scene.loader.all_doors():
		_expect(door.target_scene == DoorData.other_side(door.id, path), "%s: la puerta '%s' lleva al otro lado" % [label, door.id])
	if path == TOWN:
		_expect(not GameState.came_from_expulsion, "el pueblo consume el despertar: volver a salir no lo repite")
	if arrival == &"":
		_expect(_scene.player.position.distance_to(_scene.loader.spawn) < POSITION_TOLERANCE, "%s: se aparece en 'P'" % label)
		return
	var door := _scene.loader.door(arrival)
	_expect(door != null, "%s: el mapa tiene la puerta" % label)
	if door == null:
		return
	_expect(_scene.player.position.distance_to(door.spawn_point) < POSITION_TOLERANCE, "%s: se aparece en la puerta de llegada" % label)
	_expect(not door.overlaps_body(_scene.player), "%s: se aparece afuera del umbral" % label)

# Con el jugador real sobre el umbral: la puerta guarda la llegada y pide el
# cambio de escena (el fundido tarda más que lo que queda de este chequeo).
func _check_crossing() -> void:
	var door := _scene.loader.door(DoorData.POSADA_ESCALERA)
	door._on_body_entered(_scene.player)
	_expect(GameState.arrival_door == DoorData.POSADA_ESCALERA, "cruzar la puerta guarda la llegada")
	_expect(_scene.player.is_locked(), "al cruzar la puerta el jugador deja de caminar durante el fundido")
