# Genera los sprites de enemigos como siluetas de sombra del propio aventurero
# (rvros), desdibujadas con ruido. Reproducible: python3 tools/gen_shadow_enemies.py
from PIL import Image, ImageFilter
import random, os
random.seed(7)
HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "..", "assets-library", "rvros-adventurer", "Individual Sprites") + os.sep
OUT = os.path.join(HERE, "..", "assets", "enemies") + os.sep
os.makedirs(OUT, exist_ok=True)

def silhouette(name, color, alpha, dropout, blur, extra_wisps=0, scale=1.0):
    im = Image.open(SRC + name).convert("RGBA")
    w, h = im.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load(); op = out.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                continue
            edge = any(px[x + dx, y + dy][3] == 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                       if 0 <= x + dx < w and 0 <= y + dy < h)
            if random.random() < (dropout * 2.2 if edge else dropout):
                continue
            v = random.randint(-12, 12)
            op[x, y] = tuple(max(0, min(255, c + v)) for c in color) + (alpha,)
    for _ in range(extra_wisps):
        x = random.randint(10, w - 11); y = random.randint(4, h - 3)
        if op[x, y][3] == 0 and any(op[x + dx, y + dy][3] > 0 for dx in range(-2, 3) for dy in range(-2, 3)
                                    if 0 <= x + dx < w and 0 <= y + dy < h):
            op[x, y] = color + (alpha // 2,)
    if blur > 0:
        out = out.filter(ImageFilter.GaussianBlur(blur))
        d = out.load()
        for y in range(h):
            for x in range(w):
                r, g, b, a = d[x, y]
                d[x, y] = (r, g, b, 0 if a < 70 else min(alpha, a))
    if scale != 1.0:
        out = out.resize((int(w * scale), int(h * scale)), Image.NEAREST)
    return out

def frames(prefix, n):
    return ["adventurer-%s-%02d.png" % (prefix, i) for i in range(n)]

for i, f in enumerate(frames("run", 6)):       # 'z'/'f': sombra que camina
    silhouette(f, (34, 28, 48), 240, 0.05, 0.35).save(OUT + "shadow-walk-%02d.png" % i)
for i, f in enumerate(frames("idle-2", 4)):    # 'g': guardian, quieto, espada afuera
    silhouette(f, (18, 14, 26), 245, 0.03, 0.4).save(OUT + "guardian-walk-%02d.png" % i)
for i, f in enumerate(frames("run", 6)):       # 'h': perseguidor, humo con jirones
    silhouette(f, (55, 45, 75), 205, 0.16, 0.6, extra_wisps=40).save(OUT + "chaser-walk-%02d.png" % i)
for i, f in enumerate(frames("attack2", 6)):   # 'e': elite, rojo apagado
    silhouette(f, (70, 22, 30), 240, 0.05, 0.4).save(OUT + "elite-walk-%02d.png" % i)
for i, f in enumerate(frames("hurt", 3)):      # 'm': restos, fragmentos chicos
    silhouette(f, (40, 34, 54), 230, 0.22, 0.4, extra_wisps=20, scale=0.8).save(OUT + "restos-walk-%02d.png" % i)
for i, f in enumerate(frames("attack1", 5)):   # 'g': tajo del guardian
    silhouette(f, (18, 14, 26), 245, 0.03, 0.4).save(OUT + "guardian-attack-%02d.png" % i)
print("ok", len(os.listdir(OUT)))
