extends Node
# Capas de ambiente/musica (loops que suben de volumen con cada recuerdo) y
# reproductor de SFX. Se conecta una vez a Events.sfx_requested: cualquier
# nodo dispara un efecto con Events.sfx_requested.emit("jump").

const SILENT_DB := -80.0
const LAYERS := {
	"wind": ["res://assets/audio/amb_wind.wav", "Ambient"],
	"hum": ["res://assets/audio/amb_hum.wav", "Ambient"],
	"pad": ["res://assets/audio/music_pad.wav", "Music"],
	"melody": ["res://assets/audio/music_melody.wav", "Music"],
}
const SFX := {
	"jump": "res://assets/audio/sfx_jump.wav",
	"land": "res://assets/audio/sfx_land.wav",
	"attack": "res://assets/audio/sfx_attack.wav",
	"hit_take": "res://assets/audio/sfx_hit_take.wav",
	"enemy_die": "res://assets/audio/sfx_enemy_die.wav",
	"checkpoint": "res://assets/audio/sfx_checkpoint.wav",
	"spike": "res://assets/audio/sfx_spike.wav",
	"dash": "res://assets/audio/sfx_dash.wav",
}
const SFX_VOICES := 6
const MUFFLED_CUTOFF := 900.0
const OPEN_CUTOFF := 20500.0
# Tension de pelea: musica y zumbido mas rapidos (sube tambien el tono). Al
# terminar no se baja el pitch a la vista (suena a cinta que se frena): las
# capas se apagan, vuelven a su tono en silencio y reaparecen.
const TENSION_LAYERS: Array[String] = ["hum", "pad", "melody"]
const TENSION_PITCH := 1.25
const TENSION_RISE_TIME := 1.2
const TENSION_FADE_OUT_TIME := 0.5
const TENSION_FADE_IN_TIME := 1.5

var _layers := {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _tension_tween: Tween
# Volumen de cada capa antes de apagarla al salir de la tension.
var _volumes_before_fade := {}

func _ready() -> void:
	Events.sfx_requested.connect(play_sfx)
	Events.tension_changed.connect(set_tension)
	for name in LAYERS:
		var player := AudioStreamPlayer.new()
		var stream: AudioStreamWAV = load(LAYERS[name][0])
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2
		player.stream = stream
		player.bus = LAYERS[name][1]
		player.volume_db = SILENT_DB
		add_child(player)
		player.play()
		_layers[name] = player
	for i in range(SFX_VOICES):
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_sfx_pool.append(voice)

func set_layer(name: String, db: float, time: float) -> void:
	if not _layers.has(name):
		return
	var tween := create_tween()
	tween.tween_property(_layers[name], "volume_db", db, time)

func silence_all(time: float) -> void:
	for layer_name in _layers:
		set_layer(layer_name, SILENT_DB, time)

func play_sfx(name: String) -> void:
	if not SFX.has(name):
		push_error("SFX desconocido: %s" % name)
		return
	var voice := _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % SFX_VOICES
	voice.stream = load(SFX[name])
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.play()

func set_tension(active: bool) -> void:
	_stop_tension_tween()
	if active:
		_tension_tween = create_tween().set_parallel()
		for layer_name in TENSION_LAYERS:
			_tension_tween.tween_property(_layers[layer_name], "pitch_scale", TENSION_PITCH, TENSION_RISE_TIME)
		return
	for layer_name in TENSION_LAYERS:
		_volumes_before_fade[layer_name] = _layers[layer_name].volume_db
	_tension_tween = create_tween()
	_tension_tween.tween_method(_fade_tension_layers.bind(false), 0.0, 1.0, TENSION_FADE_OUT_TIME)
	_tension_tween.tween_callback(_reset_tension_pitch)
	_tension_tween.tween_method(_fade_tension_layers.bind(true), 0.0, 1.0, TENSION_FADE_IN_TIME)
	_tension_tween.tween_callback(_finish_tension_fade)

# Si la pelea vuelve a empezar a mitad del fundido, las capas recuperan su volumen.
func _stop_tension_tween() -> void:
	if _tension_tween:
		_tension_tween.kill()
	for layer_name in _volumes_before_fade:
		_layers[layer_name].volume_db = _volumes_before_fade[layer_name]
	_volumes_before_fade.clear()

func _fade_tension_layers(progress: float, fading_in: bool) -> void:
	for layer_name in _volumes_before_fade:
		var from: float = SILENT_DB if fading_in else _volumes_before_fade[layer_name]
		var to: float = _volumes_before_fade[layer_name] if fading_in else SILENT_DB
		_layers[layer_name].volume_db = lerpf(from, to, progress)

func _finish_tension_fade() -> void:
	_volumes_before_fade.clear()

func _reset_tension_pitch() -> void:
	for layer_name in TENSION_LAYERS:
		_layers[layer_name].pitch_scale = 1.0

# Estabilidad baja: la musica se apaga como si viniera de otra habitacion.
func set_muffled(muffled: bool) -> void:
	var bus := AudioServer.get_bus_index("Music")
	var effect := AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
	if effect == null:
		return
	var tween := create_tween()
	tween.tween_property(effect, "cutoff_hz", MUFFLED_CUTOFF if muffled else OPEN_CUTOFF, 1.0)

func _exit_tree() -> void:
	for name in _layers:
		_layers[name].stop()
