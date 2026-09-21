# Prepara el arte del pueblo real (vista cenital) a partir del bundle RPG local.
# Reproducible: python3 tools/gen_town_assets.py  (RPG_BUNDLE=ruta si no esta en
# ~/Downloads/rpg_bundle). Solo recorta/copia lo que usa el juego; los packs
# originales NO viven en el repo (ver assets/town/SOURCE.md).
from PIL import Image, ImageDraw
import os, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "town") + os.sep
BUNDLE = os.environ.get("RPG_BUNDLE", os.path.expanduser("~/Downloads/rpg_bundle"))
MANA = os.path.join(BUNDLE, "manaseedpixelarttilesetcollection", "20.04c - Summer Forest", "packaged", "summer sheets")
HEROES = os.path.join(BUNDLE, "miniadventureheroeshumans", "HUMANS_PACK", "Spritesheets", "Heroes Characters")
os.makedirs(OUT, exist_ok=True)
T = 16

# --- Suelo: atlas de 8x4 tiles de 16 px armado con tiles sueltos de Summer Forest ---
forest = Image.open(os.path.join(MANA, "summer forest.png")).convert("RGBA")
def tile(col, row):
    return forest.crop((col * T, row * T, (col + 1) * T, (row + 1) * T))

LAYOUT = {  # (col, row) en el atlas de salida -> (col, row) en la hoja original
    (0, 0): (0, 1), (1, 0): (0, 2), (2, 0): (0, 3), (3, 0): (0, 4),    # pasto liso
    (4, 0): (5, 6), (5, 0): (6, 6), (6, 0): (7, 6), (7, 0): (8, 6),    # pasto con flores
    (0, 1): (8, 1),                                                    # tierra llena
    (1, 1): (5, 0), (2, 1): (6, 0), (3, 1): (7, 0),                    # camino: arriba
    (0, 2): (8, 2), (1, 2): (5, 1), (2, 2): (6, 1), (3, 2): (7, 1),    # camino: medio
    (1, 3): (5, 2), (2, 3): (6, 2), (3, 3): (7, 2),                    # camino: abajo
}
atlas = Image.new("RGBA", (8 * T, 4 * T), (0, 0, 0, 0))
for (ox, oy), (sx, sy) in LAYOUT.items():
    atlas.paste(tile(sx, sy), (ox * T, oy * T))
atlas.save(OUT + "ground.png")

# --- Arboles (80x112 cada uno) ---
trees = Image.open(os.path.join(MANA, "summer trees 80x112.png")).convert("RGBA")
for i, name in enumerate(("tree_a", "tree_b")):
    trees.crop((i * 80, 0, (i + 1) * 80, 112)).save(OUT + name + ".png")

# --- Personajes (hojas de 64x64: 4 columnas de caminata x filas abajo/derecha/izquierda/arriba) ---
for src, name in (("Male Characters/mhap_male_hero_02.png", "hero"),
                  ("Female Characters/mhap_female_cultivator_01.png", "npc_a"),
                  ("Male Characters/mhap_male_cultivator_01.png", "npc_b")):
    shutil.copyfile(os.path.join(HEROES, src), OUT + name + ".png")

# --- Casa de prueba, dibujada a mano (placeholder hasta tener arte de casas) ---
W, H = 80, 80
OUTLINE = (58, 44, 58, 255)
THATCH, THATCH_DK, THATCH_HI = (214, 182, 72, 255), (170, 138, 52, 255), (240, 214, 112, 255)
WALL, BEAM = (232, 218, 176, 255), (128, 88, 60, 255)
DOOR, GLASS = (96, 64, 48, 255), (150, 190, 210, 255)
house = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(house)
d.rectangle((6, 44, 73, 77), fill=OUTLINE)                     # muro
d.rectangle((7, 45, 72, 76), fill=WALL)
d.rectangle((7, 45, 10, 76), fill=BEAM)
d.rectangle((69, 45, 72, 76), fill=BEAM)
d.rectangle((6, 76, 73, 77), fill=BEAM)
d.rectangle((33, 52, 46, 77), fill=OUTLINE)                    # puerta
d.rectangle((34, 53, 45, 77), fill=DOOR)
d.point((43, 66), fill=(214, 180, 120, 255))
for x0 in (14, 54):                                            # ventanas
    d.rectangle((x0, 54, x0 + 12, 66), fill=OUTLINE)
    d.rectangle((x0 + 1, 55, x0 + 11, 65), fill=GLASS)
    d.line((x0 + 6, 55, x0 + 6, 65), fill=BEAM)
    d.line((x0 + 1, 60, x0 + 11, 60), fill=BEAM)
d.polygon([(0, 46), (12, 8), (67, 8), (79, 46)], fill=OUTLINE)  # techo
d.polygon([(2, 44), (13, 10), (66, 10), (77, 44)], fill=THATCH)
for y in range(12, 44, 5):                                     # paja
    d.line((13 - (y - 10) * 0.33 + 1, y, 66 + (y - 10) * 0.33 - 1, y), fill=THATCH_DK)
    d.line((13 - (y - 10) * 0.33 + 3, y + 1, 66 + (y - 10) * 0.33 - 3, y + 1), fill=THATCH_HI)
d.rectangle((2, 44, 77, 46), fill=OUTLINE)                     # alero
house.save(OUT + "house.png")
print("ok")
