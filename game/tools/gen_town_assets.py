# Prepara el arte del pueblo real (vista cenital) a partir del bundle RPG local.
# Reproducible: python3 tools/gen_town_assets.py  (RPG_BUNDLE=ruta si no esta en
# ~/Downloads/rpg_bundle). Solo recorta/copia lo que usa el juego; los packs
# originales NO viven en el repo (ver assets/town/SOURCE.md).
from PIL import Image
import os, shutil
import house_layout

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

# --- Casas: armadas con el kit modular "Thatch Roof Home" de Mana Seed ---
# El kit trae piezas sueltas (techo, muros, puerta, cimiento) que se encajan en
# una grilla de 16 px; aca se arma una casa de una planta con puerta al centro,
# una ventana a cada lado y chimenea lateral. v1/v2/v3 son variantes de color
# del mismo kit, asi cada casa del pueblo puede ser distinta sin redibujar nada.
HOMES = os.path.join(BUNDLE, "manaseedpixelarttilesetcollection", "20.01b - Thatch Roof Home", "packaged")
ROOF_W = 9 * T          # el techo manda el ancho: el muro va 1 tile mas angosto
EAVE_Y = 150            # donde arranca la planta baja, debajo del alero central
CHIMNEY_X = ROOF_W - 20
HOUSE_W = CHIMNEY_X + 2 * T
# El vidrio del kit comparte color con las rendijas de la puerta y la chimenea:
# solo se lo busca dentro de las piezas de ventana, y con eso se escribe la
# mascara (house_x_windows.png) que usa el shader de ventanas encendidas.
KIT_GLASS = (24, 24, 32)
# Restos de otras piezas que caen dentro del recorte del techo (x0, y0, x1, y1).
ROOF_JUNK = ((0, 0, 34, 64), (32, 0, 64, 16), (128, 0, 144, 16))

def kit_piece(sheet, x0, y0, x1, y1):
    return sheet.crop((x0 * T, y0 * T, x1 * T, y1 * T))

def glass_mask(piece):
    """Blanco opaco donde la pieza tiene vidrio, transparente en el resto."""
    mask = Image.new("RGBA", piece.size, (0, 0, 0, 0))
    src, dst = piece.load(), mask.load()
    for y in range(piece.height):
        for x in range(piece.width):
            if src[x, y][:3] == KIT_GLASS and src[x, y][3]:
                dst[x, y] = (255, 255, 255, 255)
    return mask

def strip(pieces, height):
    out = Image.new("RGBA", (sum(p.width for p in pieces), height), (0, 0, 0, 0))
    x = 0
    for p in pieces:
        out.paste(p, (x, 0))
        x += p.width
    return out

for variant, name in (("v1", "house_a"), ("v2", "house_b"), ("v3", "house_c")):
    kit = Image.open(os.path.join(HOMES, "home exteriors, thatch roof %s.png" % variant)).convert("RGBA")
    roof = kit_piece(kit, 0, 0, 9, 10)
    for box in ROOF_JUNK:
        roof.paste(Image.new("RGBA", (box[2] - box[0], box[3] - box[1]), (0, 0, 0, 0)), box[:2])
    window_left, window_right = kit_piece(kit, 11, 25, 13, 27), kit_piece(kit, 19, 27, 21, 29)
    middle = kit_piece(kit, 22, 25, 26, 27)
    wall = strip([window_left, middle, window_right], 2 * T)
    blank = Image.new("RGBA", middle.size, (0, 0, 0, 0))
    wall_glass = strip([glass_mask(window_left), blank, glass_mask(window_right)], 2 * T)
    # Muro liso detras del alero: tapa el hueco entre el alero lateral y la planta baja.
    backing = strip([kit_piece(kit, 14, 19, 16, 21)] * 4, 2 * T)
    foundation = strip([kit_piece(kit, 10, 30, 12, 31), kit_piece(kit, 22, 30, 26, 31),
                        kit_piece(kit, 18, 30, 20, 31)], T)
    chimney = kit.crop((17 * T, 0, 19 * T, 6 * T))
    height = EAVE_Y + 3 * T
    house = Image.new("RGBA", (HOUSE_W, height), (0, 0, 0, 0))
    wall_x = (ROOF_W - wall.width) // 2
    house.alpha_composite(backing, (wall_x, EAVE_Y - 28))
    house.alpha_composite(wall, (wall_x, EAVE_Y))
    house.alpha_composite(foundation, (wall_x, EAVE_Y + 2 * T))
    house.alpha_composite(chimney, (CHIMNEY_X, height - chimney.height - T))
    house.alpha_composite(roof, (0, 0))
    assert house.size == house_layout.SIZE and house.height == house_layout.FEET[1], "house_layout.py no coincide con la casa armada"
    # El alero puede tapar parte del vidrio: solo cuenta el que quedo visible.
    mask = Image.new("RGBA", house.size, (0, 0, 0, 0))
    mask.alpha_composite(wall_glass, (wall_x, EAVE_Y))
    visible, mask_px, house_px = 0, mask.load(), house.load()
    for y in range(house.height):
        for x in range(house.width):
            if mask_px[x, y][3] and house_px[x, y][:3] != KIT_GLASS:
                mask_px[x, y] = (0, 0, 0, 0)
            elif mask_px[x, y][3]:
                visible += 1
    assert visible, "la casa %s quedo sin ventanas visibles" % name
    house.save(OUT + name + ".png")
    mask.convert("L").point(lambda v: 255 if v else 0).save(OUT + name + "_windows.png")
house_layout.write_layout_gd()
print("ok")
