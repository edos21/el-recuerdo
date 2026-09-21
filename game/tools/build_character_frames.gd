extends SceneTree
# godot --headless --script res://tools/build_character_frames.gd
# Genera los SpriteFrames (pixel art 24px) para el jugador y cada variante
# de enemigo a partir de la hoja de personajes de Kenney.

const SHEET := "res://assets/characters/characters_packed.png"
const CELL := 24
const SEP := 1
const OUT_DIR := "res://assets/characters/"

func _rect(col: int, row: int) -> Rect2:
	return Rect2(col * (CELL + SEP), row * (CELL + SEP), CELL, CELL)

func _atlas(tex: Texture2D, col: int, row: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = _rect(col, row)
	return at

func _make(tex: Texture2D, name: String, anims: Dictionary) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in anims:
		var coords: Array = anims[anim_name]
		var loop: bool = true
		var speed: float = 6.0
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, loop)
		frames.set_animation_speed(anim_name, speed)
		for c in coords:
			frames.add_frame(anim_name, _atlas(tex, c[0], c[1]))
	var path := OUT_DIR + name + ".tres"
	var err := ResourceSaver.save(frames, path)
	print(name, " -> ", path, " (", err, ")")

const PLAYER_DIR := "res://assets/player/"

# Jugador: frames sueltos del pack de rvros (50x37), uno por PNG.
func _make_player() -> void:
	var anims := {
		"idle": ["idle", 4, 6.0, true],
		"run": ["run", 6, 10.0, true],
		"jump": ["jump", 4, 8.0, false],
		"fall": ["fall", 2, 6.0, true],
		"attack": ["attack1", 5, 20.0, false],
		"hurt": ["hurt", 3, 10.0, false],
		"die": ["die", 7, 8.0, false],
	}
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in anims:
		var spec: Array = anims[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, spec[2])
		frames.set_animation_loop(anim_name, spec[3])
		for i in range(spec[1]):
			var tex: Texture2D = load(PLAYER_DIR + "adventurer-%s-%02d.png" % [spec[0], i])
			frames.add_frame(anim_name, tex)
	var path := OUT_DIR + "player_frames.tres"
	print("player_frames -> ", path, " (", ResourceSaver.save(frames, path), ")")

const ENEMY_DIR := "res://assets/enemies/"

# Enemigos: siluetas de sombra generadas por tools/gen_shadow_enemies.py.
func _make_shadow(name: String, prefix: String, count: int, fps: float) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("walk")
	frames.set_animation_speed("walk", fps)
	for i in range(count):
		frames.add_frame("walk", load(ENEMY_DIR + "%s-walk-%02d.png" % [prefix, i]))
	var path := OUT_DIR + name + ".tres"
	print(name, " -> ", path, " (", ResourceSaver.save(frames, path), ")")

func _make_guardian() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 5.0)
	for i in range(4):
		frames.add_frame("walk", load(ENEMY_DIR + "guardian-walk-%02d.png" % i))
	frames.add_animation("attack")
	frames.set_animation_speed("attack", 10.0)
	frames.set_animation_loop("attack", false)
	for i in range(5):
		frames.add_frame("attack", load(ENEMY_DIR + "guardian-attack-%02d.png" % i))
	var path := OUT_DIR + "enemy_guardian_frames.tres"
	print("enemy_guardian_frames -> ", path, " (", ResourceSaver.save(frames, path), ")")

func _initialize() -> void:
	var tex: Texture2D = load(SHEET)

	_make_player()
	_make_shadow("enemy_shadow_frames", "shadow", 6, 9.0)
	_make_guardian()
	_make_shadow("enemy_chaser_frames", "chaser", 6, 12.0)
	_make_shadow("enemy_elite_frames", "elite", 6, 8.0)
	_make_shadow("enemy_restos_frames", "restos", 3, 8.0)
	quit()
