# Genera arte PLACEHOLDER para lo que el repo no incluye por licencia (packs de
# terceros): el heroe de plataformas, los enemigos y el pueblo cenital. Solo
# crea los archivos que faltan, con los mismos nombres y tamanos que los reales,
# para que el proyecto abra y se pueda jugar aunque se vea con figuras simples.
#   python3 tools/gen_placeholder_art.py
# Con los packs originales se reemplaza por el arte real (ver README, "Arte").
from PIL import Image, ImageDraw
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "..", "assets") + os.sep
created = 0

def save(path, img):
    global created
    full = ASSETS + path
    if os.path.exists(full):
        return
    os.makedirs(os.path.dirname(full), exist_ok=True)
    img.save(full)
    created += 1

def person(w, h, body, head, foot_y, pose="stand", frame=0, sword=False):
    """Figura simple de perfil/frente, con los pies en foot_y."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx = w // 2
    step = (-2, 0, 2, 0)[frame % 4] if pose == "walk" else 0
    if pose == "down":
        d.rectangle((cx - 9, foot_y - 6, cx + 9, foot_y), fill=body)
        d.ellipse((cx - 5, foot_y - 14, cx + 5, foot_y - 6), fill=head)
        return im
    d.rectangle((cx - 4 + step, foot_y - 8, cx - 1 + step, foot_y), fill=body)   # piernas
    d.rectangle((cx + 1 - step, foot_y - 8, cx + 4 - step, foot_y), fill=body)
    d.rectangle((cx - 5, foot_y - 18, cx + 5, foot_y - 8), fill=body)            # torso
    d.ellipse((cx - 5, foot_y - 27, cx + 5, foot_y - 17), fill=head)             # cabeza
    if sword:
        d.line((cx + 5, foot_y - 12, cx + 17, foot_y - 20), fill=(220, 225, 231, 255), width=2)
    return im

# --- Heroe de plataformas (frames de 50x37, ver tools/build_character_frames.gd) ---
BODY, SKIN = (96, 64, 72, 255), (232, 190, 160, 255)
PLAYER = {"idle": 4, "run": 6, "jump": 4, "fall": 2, "attack1": 5, "hurt": 3, "die": 7}
for name, count in PLAYER.items():
    for i in range(count):
        pose = "walk" if name == "run" else "stand"
        body = (200, 80, 80, 255) if name == "hurt" else BODY
        img = person(50, 37, body, SKIN, 34, pose, i, sword=name == "attack1")
        if name == "die":
            img = img.rotate(90 * min(i, 3) / 3, expand=False, center=(25, 34))
        save("player/adventurer-%s-%02d.png" % (name, i), img)

# --- Enemigos (siluetas oscuras; ver tools/gen_shadow_enemies.py) ---
ENEMIES = {
    "shadow-walk": (6, (34, 28, 48, 255), 1.0),
    "guardian-walk": (4, (18, 14, 26, 255), 1.0),
    "guardian-attack": (5, (18, 14, 26, 255), 1.0),
    "chaser-walk": (6, (55, 45, 75, 255), 1.0),
    "elite-walk": (6, (110, 40, 50, 255), 1.0),
    "restos-walk": (3, (40, 34, 54, 255), 0.8),
}
for prefix, (count, color, scale) in ENEMIES.items():
    for i in range(count):
        img = person(50, 37, color, color, 34, "walk", i, sword=prefix == "guardian-attack")
        if scale != 1.0:
            img = img.resize((int(50 * scale), int(37 * scale)), Image.NEAREST)
        save("enemies/%s-%02d.png" % (prefix, i), img)

# --- Pueblo cenital (hojas de 64x64: filas abajo/izquierda/derecha/arriba) ---
GRASS = [(96, 122, 62, 255), (90, 116, 58, 255), (102, 128, 66, 255), (94, 120, 60, 255)]
DIRT, DIRT_EDGE = (130, 100, 74, 255), (96, 122, 62, 255)
T = 16
ground = Image.new("RGBA", (8 * T, 4 * T), (0, 0, 0, 0))
gd = ImageDraw.Draw(ground)
def tile(col, row, fill, edges=""):
    x, y = col * T, row * T
    gd.rectangle((x, y, x + T - 1, y + T - 1), fill=fill)
    if "t" in edges: gd.rectangle((x, y, x + T - 1, y + 2), fill=DIRT_EDGE)
    if "b" in edges: gd.rectangle((x, y + T - 3, x + T - 1, y + T - 1), fill=DIRT_EDGE)
    if "l" in edges: gd.rectangle((x, y, x + 2, y + T - 1), fill=DIRT_EDGE)
    if "r" in edges: gd.rectangle((x + T - 3, y, x + T - 1, y + T - 1), fill=DIRT_EDGE)
for i in range(4):
    tile(i, 0, GRASS[i])
    tile(4 + i, 0, GRASS[i])
    gd.point((4 * T + i * T + 5, 6), fill=(240, 240, 220, 255))
tile(0, 1, DIRT); tile(0, 2, DIRT)
for (c, r), edges in {(1, 1): "tl", (2, 1): "t", (3, 1): "tr", (1, 2): "l", (2, 2): "", (3, 2): "r",
                      (1, 3): "bl", (2, 3): "b", (3, 3): "br"}.items():
    tile(c, r, DIRT, edges)
save("town/ground.png", ground)

for name, canopy in (("tree_a", (70, 130, 60, 255)), ("tree_b", (50, 110, 80, 255))):
    tree = Image.new("RGBA", (80, 112), (0, 0, 0, 0))
    td = ImageDraw.Draw(tree)
    td.rectangle((34, 66, 46, 100), fill=(96, 68, 48, 255))
    td.ellipse((8, 4, 72, 76), fill=canopy)
    save("town/%s.png" % name, tree)

DIRS = ["down", "left", "right", "up"]
for name, body in (("hero", (70, 80, 130, 255)), ("npc_a", (200, 120, 150, 255)), ("npc_b", (130, 130, 140, 255))):
    sheet = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    for r, direction in enumerate(DIRS):
        for c in range(4):
            cell = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
            cd = ImageDraw.Draw(cell)
            lift = 1 if c in (1, 3) else 0
            cd.rectangle((5, 9 - lift, 10, 14 - lift), fill=body)
            cd.ellipse((4, 2, 11, 9), fill=(232, 190, 160, 255) if direction != "up" else (96, 64, 48, 255))
            if direction == "down":
                cd.point((6, 5), fill=(40, 30, 30, 255)); cd.point((9, 5), fill=(40, 30, 30, 255))
            elif direction == "left":
                cd.point((5, 5), fill=(40, 30, 30, 255))
            elif direction == "right":
                cd.point((10, 5), fill=(40, 30, 30, 255))
            sheet.paste(cell, (c * 16, r * 16))
    save("town/%s.png" % name, sheet)

print("placeholders creados:", created)
