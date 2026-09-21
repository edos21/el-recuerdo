extends SceneTree
# Ejecutar una vez (o cada vez que cambien los indices):
#   godot --headless --script res://tools/build_tileset.gd
# Arma el TileSet de visuales a partir de la hoja de Kenney. Sin capas de
# fisica: la colision del nivel la arma level_loader.gd con StaticBody2D
# simples (mismo enfoque que ya probo funcionar en el nivel viejo), asi que
# este TileSet es puramente decorativo.

const SHEET := "res://assets/tiles/tilemap_packed.png"
const OUT := "res://assets/tiles/platformer.tres"
const TILE_PX := 18

# Coordenadas (col,row) elegidas a mano mirando la hoja etiquetada.
const TILES := {
	"ground": Vector2i(1, 6),
	"platform": Vector2i(8, 2),
	"spike": Vector2i(8, 3),
	"sign": Vector2i(4, 4),
	"tree": Vector2i(6, 6),
	"bush": Vector2i(4, 6),
	"door": Vector2i(8, 6),
}

func _initialize() -> void:
	var tex: Texture2D = load(SHEET)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE_PX, TILE_PX)
	source.separation = Vector2i(1, 1)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_PX, TILE_PX)
	var source_id := tile_set.add_source(source)

	for key in TILES:
		var coord: Vector2i = TILES[key]
		if not source.has_tile(coord):
			source.create_tile(coord)

	var err := ResourceSaver.save(tile_set, OUT)
	if err != OK:
		push_error("No se pudo guardar el TileSet: %s" % err)
	else:
		print("TileSet guardado en %s (source_id=%d)" % [OUT, source_id])
	quit()
