# Dibuja a mano (pixel a pixel) el ícono de los zapatos y la puerta del final.
# Reproducible: python3 tools/gen_pixel_props.py
from PIL import Image
import os
HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "..", "assets") + os.sep

def from_rows(rows, palette, size=None):
    w = max(len(r) for r in rows)
    im = Image.new("RGBA", size or (w, len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in palette:
                im.putpixel((x, y), palette[ch])
    return im

# --- Zapatilla de perfil, apuntando a la derecha (Recuerdo del Corredor) ---
SHOE_PAL = {
    "O": (58, 44, 58, 255),      # contorno
    "U": (232, 222, 200, 255),   # tela
    "S": (190, 172, 146, 255),   # sombra de la tela
    "L": (120, 96, 88, 255),     # cordones
    "T": (248, 244, 232, 255),   # puntera
    "W": (250, 248, 240, 255),   # suela clara
    "R": (200, 70, 70, 255),     # franja roja
    "K": (96, 84, 92, 255),      # goma de la suela
}
SHOE = [
    "..................",
    "..................",
    "..................",
    "..OOOOOO..........",
    ".OUUUUUSO.........",
    ".OUUUUUSO.........",
    ".OUSSSUUOOOO......",
    ".OUUUUULLUUOO.....",
    ".OUUUUUULLUUOO....",
    ".OUUUUUUULLUUUOO..",
    ".OUUUUUUUUUUUUUUO.",
    ".OUUUUUUUUUTTTTTO.",
    ".OWWWWWWWWWWWWWWO.",
    ".ORRRRRRRRRRRRRRO.",
    ".OKKKKKKKKKKKKKKO.",
    "..OOOOOOOOOOOOOO..",
    "..................",
    "..................",
]
from_rows(SHOE, SHOE_PAL, (18, 18)).save(ASSETS + "items" + os.sep + "shoes.png")

# --- Puerta entreabierta con luz del otro lado (umbral que no se cruza) ---
DOOR_W, DOOR_H = 26, 42
OUT = (58, 44, 58, 255)
WOOD = (150, 100, 70, 255)
WOOD_HI = (184, 130, 92, 255)
LEAF = (112, 74, 58, 255)
LEAF_HI = (138, 92, 70, 255)
STONE = (128, 126, 140, 255)
door = Image.new("RGBA", (DOOR_W, DOOR_H), (0, 0, 0, 0))
px = door.load()

def rect(x0, y0, x1, y1, color):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = color

rect(0, 0, DOOR_W - 1, DOOR_H - 3, OUT)              # contorno del marco
rect(1, 1, DOOR_W - 2, DOOR_H - 4, WOOD)             # marco
rect(1, 1, DOOR_W - 2, 2, WOOD_HI)                   # dintel iluminado
rect(3, 3, DOOR_W - 4, DOOR_H - 4, OUT)              # hueco
top, bottom = 4, DOOR_H - 4
for y in range(top, bottom):                         # luz: mas calida hacia abajo
    t = (y - top) / (bottom - top)
    color = (255, int(248 - 40 * t), int(220 - 90 * t), 255)
    for x in range(4, DOOR_W - 4):
        px[x, y] = color
for i, x in enumerate(range(4, 12)):                 # hoja entreabierta, en perspectiva
    inset = i // 3 + (0 if i < 7 else 1)
    for y in range(top + inset, bottom - inset):
        px[x, y] = LEAF_HI if i in (1, 5) else LEAF
    px[x, top + inset] = OUT
    px[x, bottom - inset - 1] = OUT
rect(4, top, 4, bottom - 1, OUT)
rect(11, top + 3, 11, bottom - 4, OUT)               # canto de la hoja
rect(9, 21, 9, 22, (214, 180, 120, 255))             # picaporte
rect(0, DOOR_H - 2, DOOR_W - 1, DOOR_H - 1, STONE)   # umbral de piedra
rect(0, DOOR_H - 1, DOOR_W - 1, DOOR_H - 1, OUT)
door.save(ASSETS + "props" + os.sep + "door.png")
print("ok")
