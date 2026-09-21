extends SceneTree
# godot --headless --script res://tools/build_topdown_frames.gd
# SpriteFrames cenitales a partir de las hojas 64x64 de "Mini Adventure Heroes"
# (4 columnas de caminata; filas: abajo, izquierda, derecha, arriba, verificado
# contra los gif del pack: south/west/east/north).

const TOWN_DIR := "res://assets/town/"
const OUT_DIR := "res://assets/characters/"
const CELL := 16
const DIRECTIONS := ["down", "left", "right", "up"]
const WALK_FPS := 8.0

func _make(sheet_name: String, out_name: String) -> void:
	var sheet: Texture2D = load(TOWN_DIR + sheet_name + ".png")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for row in range(DIRECTIONS.size()):
		var dir: String = DIRECTIONS[row]
		frames.add_animation("walk_" + dir)
		frames.set_animation_speed("walk_" + dir, WALK_FPS)
		frames.add_animation("idle_" + dir)
		frames.set_animation_speed("idle_" + dir, 1.0)
		for col in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * CELL, row * CELL, CELL, CELL)
			frames.add_frame("walk_" + dir, atlas)
			if col == 0:
				frames.add_frame("idle_" + dir, atlas)
	var path := OUT_DIR + out_name + ".tres"
	print(out_name, " -> ", path, " (", ResourceSaver.save(frames, path), ")")

func _initialize() -> void:
	_make("hero", "topdown_hero_frames")
	_make("npc_a", "topdown_npc_a_frames")
	_make("npc_b", "topdown_npc_b_frames")
	quit()
