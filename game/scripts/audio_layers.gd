extends Node
# Capas de ambiente/musica (loops que suben de volumen con cada recuerdo) y
# reproductor de SFX. Esta en el grupo "audio": cualquier nodo dispara un
# efecto con get_tree().call_group("audio", "play_sfx", "jump").

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
}
const SFX_VOICES := 6
const MUFFLED_CUTOFF := 900.0
const OPEN_CUTOFF := 20500.0

var _layers := {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next := 0

func _ready() -> void:
	add_to_group("audio")
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
		return
	var voice := _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % SFX_VOICES
	voice.stream = load(SFX[name])
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.play()

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
