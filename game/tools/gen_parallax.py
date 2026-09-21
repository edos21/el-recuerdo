# Genera las capas de colinas del fondo (siluetas frias con transparencia real).
# Periodicas en X para que el Parallax2D las repita sin costura.
# Reproducible: python3 tools/gen_parallax.py
from PIL import Image
import math, os, random
random.seed(11)
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "tiles") + os.sep
W, H = 640, 220
FADE_START = 150  # por debajo del suelo las colinas se desvanecen en vez de cortarse en seco

def ridge(x, base, waves):
    y = base
    for amp, freq, phase in waves:
        y += amp * math.sin(2 * math.pi * freq * x / W + phase)
    return int(round(y))

def layer(color, base, waves, trees=0, tree_h=(14, 26)):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    heights = [ridge(x, base, waves) for x in range(W)]
    for x in range(W):
        for y in range(heights[x], H):
            fade = 1.0 if y < FADE_START else max(0.0, 1.0 - (y - FADE_START) / (H - FADE_START))
            px[x, y] = color[:3] + (int(color[3] * fade),)
    for _ in range(trees):
        cx = random.randrange(W)
        th = random.randint(*tree_h)
        for i in range(th):
            half = int((i / th) * (th * 0.32)) + 1
            for dx in range(-half, half + 1):
                x = (cx + dx) % W
                y = heights[cx] - th + i
                if 0 <= y < H:
                    px[x, y] = color
    return im

far = layer((66, 76, 98, 255), 84, [(18, 1, 0.0), (10, 3, 1.3), (4, 7, 0.4)])
near = layer((46, 54, 74, 255), 112, [(9, 2, 2.1), (5, 5, 0.7), (2, 11, 1.9)], trees=26)
far.save(OUT + "parallax_far.png")
near.save(OUT + "parallax_near.png")
print("ok")
