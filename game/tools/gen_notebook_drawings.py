# Genera los dibujos PLACEHOLDER del cuaderno (uno por entrada, assets/notebook/<id>.png)
# hasta que existan los escaneos del dueño. Solo crea los que faltan, asi un
# escaneo con el mismo nombre nunca se pisa.
#   python3 tools/gen_notebook_drawings.py
from PIL import Image, ImageDraw, ImageFilter
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "notebook")
SIZE = (320, 240)
PENCIL = (60, 52, 58, 255)
LINE = 4

def wash(color, box):
    """Mancha de acuarela: elipse con borde corrido y desenfoque suave."""
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=color + (150,))
    return layer.filter(ImageFilter.GaussianBlur(10))

def jitter(points, seed, amount=2):
    rng = random.Random(seed)
    return [(x + rng.uniform(-amount, amount), y + rng.uniform(-amount, amount)) for x, y in points]

def pencil(d, points, seed, closed=False):
    pts = jitter(points + ([points[0]] if closed else []), seed)
    d.line(pts, fill=PENCIL, width=LINE, joint="curve")

def keyring(d):
    d.ellipse((90, 40, 230, 180), outline=PENCIL, width=LINE)
    for i, x in enumerate((120, 160, 200)):
        pencil(d, [(x, 175), (x, 215)], i)
        d.ellipse((x - 10, 205, x + 10, 225), outline=PENCIL, width=LINE)

def bucket(d):
    pencil(d, [(100, 90), (125, 205), (195, 205), (220, 90)], 1)
    d.ellipse((100, 76, 220, 104), outline=PENCIL, width=LINE)
    d.arc((110, 30, 210, 130), 190, 350, fill=PENCIL, width=LINE)

def pot(d):
    d.ellipse((90, 110, 230, 215), outline=PENCIL, width=LINE)
    pencil(d, [(90, 140), (230, 140)], 2)
    for i, x in enumerate((130, 160, 190)):
        pencil(d, [(x, 100), (x + 12, 75), (x - 8, 50), (x + 6, 25)], 10 + i, )

def suitcase(d):
    d.rounded_rectangle((70, 90, 250, 200), radius=12, outline=PENCIL, width=LINE)
    d.arc((125, 55, 195, 120), 180, 360, fill=PENCIL, width=LINE)
    pencil(d, [(70, 140), (250, 140)], 3)
    d.rectangle((150, 132, 170, 150), outline=PENCIL, width=LINE)

def faceless(d):
    d.ellipse((60, 40, 120, 100), outline=PENCIL, width=LINE)
    pencil(d, [(90, 100), (90, 175)], 4)
    pencil(d, [(90, 120), (55, 160)], 5)
    pencil(d, [(90, 120), (125, 160)], 6)
    pencil(d, [(90, 175), (65, 220)], 7)
    pencil(d, [(90, 175), (115, 220)], 8)
    d.rounded_rectangle((170, 150, 270, 215), radius=8, outline=PENCIL, width=LINE)

def inn_at_night(d):
    pencil(d, [(50, 210), (50, 100), (160, 50), (270, 100), (270, 210)], 9, closed=False)
    pencil(d, [(50, 210), (270, 210)], 11)
    for x in (80, 120, 200):
        d.rectangle((x, 120, x + 30, 150), outline=PENCIL, width=LINE)
    d.rectangle((200, 120, 230, 150), fill=(245, 205, 110, 255), outline=PENCIL, width=LINE)

def empty_chair(d):
    pencil(d, [(110, 40), (110, 150), (200, 150), (200, 215)], 12)
    pencil(d, [(110, 150), (110, 215)], 13)
    pencil(d, [(200, 40), (200, 150)], 14)
    pencil(d, [(110, 70), (200, 70)], 15)

DRAWINGS = {
    "woke_up": ((196, 140, 90), suitcase),
    "tomas_keys": ((222, 190, 70), keyring),
    "inn_water": ((90, 150, 200), bucket),
    "broth": ((220, 130, 70), pot),
    "dont_know": ((150, 120, 190), faceless),
    "guest_book": ((60, 70, 130), inn_at_night),
    "flor_husband": ((120, 160, 120), empty_chair),
}

created = 0
os.makedirs(OUT, exist_ok=True)
for name, (tint, draw) in DRAWINGS.items():
    path = os.path.join(OUT, name + ".png")
    if os.path.exists(path):
        continue
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    img.alpha_composite(wash(tint, (30, 20, 290, 225)))
    draw(ImageDraw.Draw(img))
    img.save(path)
    created += 1
print("dibujos creados: %d" % created)
