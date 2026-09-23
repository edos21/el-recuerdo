# Recorta del atlas de Kenney (Pixel Platformer, CC0) las plantas del Nivel 1
# como sprites sueltos. Tienen que ser texturas propias y no celdas del
# TileMapLayer: wind_sway.gdshader ancla el balanceo con el UV del sprite
# entero y saca la fase de su posicion, y las celdas comparten ambas cosas.
# Reproducible: python3 tools/gen_level_props.py
from PIL import Image
import os
HERE = os.path.dirname(os.path.abspath(__file__))
ATLAS = os.path.join(HERE, "..", "assets", "tiles", "tilemap_packed.png")
OUT = os.path.join(HERE, "..", "assets", "props") + os.sep
TILE = 18

# Coordenadas de celda en el atlas (las mismas que usaba level_loader.ATLAS).
PLANTS = {
    "plant_pine.png": (6, 6),
    "plant_sprout.png": (4, 6),
    "plant_sprout_tall.png": (5, 6),
}

atlas = Image.open(ATLAS).convert("RGBA")
for name, (col, row) in PLANTS.items():
    tile = atlas.crop((col * TILE, row * TILE, (col + 1) * TILE, (row + 1) * TILE))
    tile.save(OUT + name)
print("ok")
