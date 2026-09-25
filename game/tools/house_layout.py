# Fuente unica de las medidas de las casas del pueblo: las usan el generador del
# arte real (gen_town_assets.py) y el de placeholders (gen_placeholder_art.py), y
# de aca sale data/house_layout.gd, que leen el loader y la atmosfera del pueblo.
# Todo en px de la textura de la casa (el juego la dibuja al doble).
#   python3 tools/house_layout.py   (regenera data/house_layout.gd)
import os

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT_GD = os.path.join(HERE, "..", "data", "house_layout.gd")

SIZE = (156, 198)
FEET = (72, 198)          # el origen del sprite: donde la casa toca el suelo
BODY = (136, 75)          # huella que bloquea el paso, centrada en los pies
CHIMNEY = (68, -111)      # salida del humo, relativa a los pies
LIGHT = (0, 12)           # luz calida de las ventanas, relativa a los pies
SHADOW = ((-66, -2), (86, -2), (98, 6), (-58, 6))   # sombra al pie, relativa a los pies

# Ventanas de los placeholders (x0, y0, x1, y1 inclusivos). El arte real mide su
# propio vidrio al generarse; estos rectangulos solo imitan su posicion.
PLACEHOLDER_WINDOWS = ((18, 158, 30, 170), (110, 158, 122, 170))


def _vec(v):
    return "Vector2(%d, %d)" % v


def write_layout_gd():
    lines = [
        "extends RefCounted",
        "class_name HouseLayout",
        "# GENERADO por tools/house_layout.py (lo corren gen_town_assets.py y",
        "# gen_placeholder_art.py): no editar a mano. Medidas en px de la textura de la casa.",
        "",
        "const FEET := %s" % _vec(FEET),
        "const BODY := %s" % _vec(BODY),
        "const CHIMNEY := %s" % _vec(CHIMNEY),
        "const LIGHT := %s" % _vec(LIGHT),
        "const SHADOW := [%s]" % ", ".join(_vec(p) for p in SHADOW),
        "",
    ]
    with open(LAYOUT_GD, "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    write_layout_gd()
