# Prepara el arte del pueblo real (vista cenital) a partir del bundle RPG local.
# Reproducible: python3 tools/gen_town_assets.py  (RPG_BUNDLE=ruta si no esta en
# ~/Downloads/rpg_bundle). Solo recorta/copia lo que usa el juego; los packs
# originales NO viven en el repo (ver assets/town/SOURCE.md).
from PIL import Image
import os, shutil
import house_layout
import map_grid

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
# La posadera: una base humana sin equipo de aventurera.
shutil.copyfile(os.path.join(HEROES, "..", "Base Characters", "Female Base", "mhap_female_human_base_01.png"), OUT + "innkeeper.png")

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
WALL_X = (ROOF_W - 8 * T) // 2   # los pisos miden 8 tiles, centrados bajo el techo
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

def ground_floor(kit):
    window_left, window_right = kit_piece(kit, 11, 25, 13, 27), kit_piece(kit, 19, 27, 21, 29)
    return [window_left, kit_piece(kit, 22, 25, 26, 27), window_right], (True, False, True)

# Piso alto del kit ("Upper Floors"): mismas columnas que la planta baja, seis
# filas mas arriba, con muro liso donde abajo va la puerta.
def upper_floor(kit):
    plain = kit_piece(kit, 14, 19, 16, 21)
    return [kit_piece(kit, 11, 19, 13, 21), plain, plain, kit_piece(kit, 19, 21, 21, 23)], (True, False, False, True)

def building(kit, floors, layout):
    """Techo, pisos (de arriba abajo), cimiento y chimenea; devuelve la imagen y
    la mascara de ventanas con solo el vidrio que quedo visible."""
    roof = kit_piece(kit, 0, 0, 9, 10)
    for box in ROOF_JUNK:
        roof.paste(Image.new("RGBA", (box[2] - box[0], box[3] - box[1]), (0, 0, 0, 0)), box[:2])
    # Muro liso detras del alero: tapa el hueco entre el alero lateral y el piso de arriba.
    backing = strip([kit_piece(kit, 14, 19, 16, 21)] * 4, 2 * T)
    foundation = strip([kit_piece(kit, 10, 30, 12, 31), kit_piece(kit, 22, 30, 26, 31),
                        kit_piece(kit, 18, 30, 20, 31)], T)
    chimney = kit.crop((17 * T, 0, 19 * T, 6 * T))
    height = EAVE_Y + 2 * T * len(floors) + T
    image = Image.new("RGBA", (HOUSE_W, height), (0, 0, 0, 0))
    mask = Image.new("RGBA", image.size, (0, 0, 0, 0))
    image.alpha_composite(backing, (WALL_X, EAVE_Y - 28))
    for i, (pieces, has_glass) in enumerate(floors):
        y = EAVE_Y + 2 * T * i
        image.alpha_composite(strip(pieces, 2 * T), (WALL_X, y))
        glass = [glass_mask(p) if g else Image.new("RGBA", p.size, (0, 0, 0, 0)) for p, g in zip(pieces, has_glass)]
        mask.alpha_composite(strip(glass, 2 * T), (WALL_X, y))
    image.alpha_composite(foundation, (WALL_X, height - T))
    image.alpha_composite(chimney, (CHIMNEY_X, height - chimney.height - T))
    image.alpha_composite(roof, (0, 0))
    assert image.size == layout["size"] and image.height == layout["feet"][1], "house_layout.py no coincide con el edificio armado"
    # El alero puede tapar parte del vidrio: solo cuenta el que quedo visible.
    visible, mask_px, image_px = 0, mask.load(), image.load()
    for y in range(image.height):
        for x in range(image.width):
            if mask_px[x, y][3] and image_px[x, y][:3] != KIT_GLASS:
                mask_px[x, y] = (0, 0, 0, 0)
            elif mask_px[x, y][3]:
                visible += 1
    assert visible, "el edificio quedo sin ventanas visibles"
    return image, mask

for variant, name in (("v1", "house_a"), ("v2", "house_b"), ("v3", "house_c")):
    kit = Image.open(os.path.join(HOMES, "home exteriors, thatch roof %s.png" % variant)).convert("RGBA")
    house, mask = building(kit, [ground_floor(kit)], house_layout.LAYOUTS["house"])
    house.save(OUT + name + ".png")
    mask.convert("L").save(OUT + name + "_windows.png")

# --- Posada: la casa con un piso mas y un cartel colgado junto a la puerta ---
# El cartel del kit "Village Accessories" va en dos partes (ver "a note on signs
# and pendants.txt"): un soporte con una tabla lisa y, encima, la tabla con el
# oficio. La cama dice "posada" sin texto (el cartel "INN" esta en ingles).
ACCESSORIES = os.path.join(BUNDLE, "manaseedpixelarttilesetcollection", "18.10b - Village Accessories", "packaged")
SIGN_BRACKET = (64, 64, 96, 96)     # soporte con tabla lisa, en village accessories 32x32.png
SIGN_BED = (16, 0, 32, 16)          # tabla con la cama, en village accessories 16x16.png
SIGN_BOARD_AREA = (16, 18, 32, 32)  # donde cuelga la tabla lisa dentro del soporte
SIGN_POS = (WALL_X + T, EAVE_Y + 2 * T - 14)  # entre la ventana y la puerta, bajo el piso alto

def inn_sign():
    bracket = Image.open(os.path.join(ACCESSORIES, "village accessories 32x32.png")).convert("RGBA").crop(SIGN_BRACKET)
    sign = Image.open(os.path.join(ACCESSORIES, "village accessories 16x16.png")).convert("RGBA").crop(SIGN_BED)
    board = bracket.crop(SIGN_BOARD_AREA).getbbox()
    center = (SIGN_BOARD_AREA[0] + (board[0] + board[2]) // 2, SIGN_BOARD_AREA[1] + (board[1] + board[3]) // 2)
    bracket.alpha_composite(sign, (center[0] - sign.width // 2, center[1] - sign.height // 2))
    return bracket

kit = Image.open(os.path.join(HOMES, "home exteriors, thatch roof v3.png")).convert("RGBA")
inn, mask = building(kit, [upper_floor(kit), ground_floor(kit)], house_layout.LAYOUTS["inn"])
inn.alpha_composite(inn_sign(), SIGN_POS)
inn.save(OUT + "inn.png")
mask.convert("L").save(OUT + "inn_windows.png")
# --- Interiores: cada cuarto sale del mismo mapa que lee el juego ---
# (levels/<cuarto>.txt), asi la imagen y las paredes que bloquean no se desincronizan.
# '#' borde oscuro, 'W' pared, 'v' ventana (bloques de 2x2 sobre el revoque),
# 'c' cuadro colgado (su esquina de arriba a la izquierda, sobre el revoque), 'D'
# umbral de la puerta, 'r'/'S'/'U' la escalera (baranda, escalones, tope: se
# pinta entera sobre su bloque); el resto es piso. Los muebles van como sprites
# sueltos para ordenarse por Y con los personajes.
# El piso del kit es un autotile (empedrado con parches de tierra): solo la
# primera columna es empedrado puro, y esas cuatro variantes se mezclan sin cortes.
FLOOR_TILES = [(0, r) for r in range(3, 7)]
WALL_ROWS = (6, 7, 8, 9)        # madera, madera, revoque, revoque
WALL_COLUMNS = (14, 15, 16)     # columnas sueltas, se pueden mezclar
WALL_POST = 17                  # la columna con poste, cada tantas
WALL_POST_EVERY = 4
WINDOW = (25, 2)                # ventana encendida de 2x2
WINDOW_BAND_ROW = 2             # las ventanas van en el revoque
THRESHOLD = (25, 7)             # piedras del umbral
BOUNDARY_SAMPLE = (6 * T + 4, 2 * T + 4)
COZY = os.path.join(BUNDLE, "manaseedpixelarttilesetcollection", "19.04b - Cozy Furnishings", "packaged")
PAINTING = (5 * 32, 0, 6 * 32, 32)   # paisaje enmarcado, en cozy furnishings 32x32.png
STAIRS = (10, 160, 54, 240)          # escalera que sube, en _extras/bonus wooden stairs.png
STAIRS_CELLS = "rSU"

def sheet_tile(sheet, col, row):
    return kit_piece(sheet, col, row, col + 1, row + 1)

def room_image(map_path, interiors, painting, stairs):
    """Dos pasadas: primero piso, pared y umbral celda por celda; despues lo que
    ocupa varias celdas (ventanas, cuadros, la escalera), que si se pintara en su
    primera celda quedaria tapado por las siguientes."""
    rows = map_grid.read_grid(map_path)
    wall_top = min(r for r, line in enumerate(rows) if "W" in line)
    room = Image.new("RGBA", (max(len(r) for r in rows) * T, len(rows) * T), interiors.getpixel(BOUNDARY_SAMPLE))
    overlays = []
    stairs_cells = []
    for row, line in enumerate(rows):
        for col, ch in enumerate(line):
            at = (col * T, row * T)
            band = row - wall_top
            if ch in STAIRS_CELLS:
                stairs_cells.append((col, row))
            if ch == "#":
                continue
            if ch in "Wvc" or (ch in STAIRS_CELLS and 0 <= band < len(WALL_ROWS)):
                assert 0 <= band < len(WALL_ROWS), "%s: la pared mide %d filas" % (map_path, len(WALL_ROWS))
                source = WALL_POST if (col - line.index("W")) % WALL_POST_EVERY == WALL_POST_EVERY - 1 \
                    else WALL_COLUMNS[map_grid.cell_hash(col, row) % len(WALL_COLUMNS)]
                room.alpha_composite(sheet_tile(interiors, source, WALL_ROWS[band]), at)
                first = map_grid.at(rows, col - 1, row) != ch and map_grid.at(rows, col, row - 1) != ch
                if ch == "v" and first:
                    assert band == WINDOW_BAND_ROW, "%s: la ventana tiene que caer sobre el revoque" % map_path
                    overlays.append((kit_piece(interiors, WINDOW[0], WINDOW[1], WINDOW[0] + 2, WINDOW[1] + 2), at))
                if ch == "c":
                    assert band == WINDOW_BAND_ROW, "%s: el cuadro tiene que colgar del revoque" % map_path
                    box = painting.getbbox()
                    overlays.append((painting.crop(box), (col * T + (2 * T - (box[2] - box[0])) // 2,
                                                          row * T + (2 * T - (box[3] - box[1])) // 2)))
            elif ch == "D":
                offset = 1 if map_grid.at(rows, col - 1, row) == "D" else 0
                room.alpha_composite(sheet_tile(interiors, THRESHOLD[0] + offset, THRESHOLD[1]), at)
            else:
                floor = FLOOR_TILES[map_grid.cell_hash(col, row) % len(FLOOR_TILES)]
                room.alpha_composite(sheet_tile(interiors, *floor), at)
    # La escalera sube hacia la pared: se pinta sobre la pared y el piso de su bloque.
    if stairs_cells:
        left, top = min(c for c, _ in stairs_cells), min(r for _, r in stairs_cells)
        width = (max(c for c, _ in stairs_cells) - left + 1) * T
        assert (max(r for _, r in stairs_cells) - top + 1) * T == stairs.height, "%s: la escalera mide %d filas" % (map_path, stairs.height // T)
        overlays.append((stairs, (left * T + (width - stairs.width) // 2, top * T)))
    for image, at in overlays:
        room.alpha_composite(image, at)
    return room

interiors = Image.open(os.path.join(HOMES, "home interiors, thatch roof v2.png")).convert("RGBA")
cozy_32 = Image.open(os.path.join(COZY, "cozy furnishings 32x32.png")).convert("RGBA")
cozy_16 = Image.open(os.path.join(COZY, "cozy furnishings 16x16.png")).convert("RGBA")
stairs = Image.open(os.path.join(BUNDLE, "manaseedpixelarttilesetcollection", "_extras", "bonus wooden stairs.png")).convert("RGBA").crop(STAIRS)
for map_name, image_name in map_grid.INTERIORS:
    room_image(os.path.join(HERE, "..", "levels", map_name), interiors, cozy_32.crop(PAINTING), stairs).save(OUT + image_name + ".png")

SLICEABLE = os.path.join(HOMES, "thatch roof sliceable")
CANDLES = os.path.join(BUNDLE, "manaseedpixelarttilesetcollection", "19.03a - Animated Candles", "packaged")
TRUNK = (8 * 32, 3 * 32 + 16, 9 * 32, 4 * 32)   # baul con correas y candado: la valija
# Escritorio con cajones y, encima, una pila de libros y uno abierto. La imagen
# lleva margen arriba para que los libros no se recorten; la vela va aparte
# porque es animada (ver interior_loader.gd).
DESK = (1 * 32, 2 * 32, 2 * 32, 3 * 32)
DESK_TOP_MARGIN = 8
BOOK_STACK, BOOK_STACK_AT = (19 * 16, 0, 20 * 16, 16), (0, 5)
OPEN_BOOK, OPEN_BOOK_AT = (18 * 16, 0, 19 * 16, 16), (9, 7)
# Vela en su candelero: la primera fila de la hoja; el cuadro 0 esta apagado.
CANDLE_FRAMES = [(c * 16, 0, (c + 1) * 16, 16) for c in range(1, 5)]
# Salon: el escritorio ancho de cajones hace de mostrador; cada mesa redonda
# lleva una silla a cada lado (la de la derecha es la misma, espejada).
COUNTER = (1 * 48, 3 * 32, 2 * 48, 4 * 32)   # en cozy furnishings 48x32.png
ROUND_TABLE = (5 * 32, 3 * 32, 6 * 32, 4 * 32)
CHAIR = (3 * 16, 2 * 32, 4 * 16, 3 * 32)     # mira a la derecha, en cozy furnishings 16x32.png

shutil.copyfile(os.path.join(SLICEABLE, "thatch roof bed 32x64.png"), OUT + "inn_bed.png")
cozy_32.crop(TRUNK).save(OUT + "inn_trunk.png")
desk = Image.new("RGBA", (32, 32 + DESK_TOP_MARGIN), (0, 0, 0, 0))
desk.alpha_composite(cozy_32.crop(DESK), (0, DESK_TOP_MARGIN))
desk.alpha_composite(cozy_16.crop(BOOK_STACK), BOOK_STACK_AT)
desk.alpha_composite(cozy_16.crop(OPEN_BOOK), OPEN_BOOK_AT)
desk.save(OUT + "inn_desk.png")
candles = Image.open(os.path.join(CANDLES, "animated candles anim 16x16 v01.png")).convert("RGBA")
strip([candles.crop(box) for box in CANDLE_FRAMES], 16).save(OUT + "inn_candle.png")
Image.open(os.path.join(COZY, "cozy furnishings 48x32.png")).convert("RGBA").crop(COUNTER).save(OUT + "inn_counter.png")
chair = Image.open(os.path.join(COZY, "cozy furnishings 16x32.png")).convert("RGBA").crop(CHAIR)
table_set = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
table_set.alpha_composite(chair, (0, 0))
table_set.alpha_composite(cozy_32.crop(ROUND_TABLE), (16, 0))
table_set.alpha_composite(chair.transpose(Image.FLIP_LEFT_RIGHT), (48, 0))
table_set.save(OUT + "inn_table_set.png")
shutil.copyfile(os.path.join(SLICEABLE, "animated cooking pot 32x32.png"), OUT + "inn_pot.png")

house_layout.write_layout_gd()
print("ok")
