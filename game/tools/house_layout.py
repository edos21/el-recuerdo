# Fuente unica de las medidas de los edificios del pueblo: las usan el generador
# del arte real (gen_town_assets.py) y el de placeholders (gen_placeholder_art.py),
# y de aca sale data/house_layout.gd, que leen el loader y la atmosfera del pueblo.
# Todo en px de la textura del edificio (el juego la dibuja al doble). Cada
# edificio lleva sus propios anclajes: la posada es mas alta que las casas.
#   python3 tools/house_layout.py   (regenera data/house_layout.gd)
import os

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT_GD = os.path.join(HERE, "..", "data", "house_layout.gd")

# size: textura; feet: el origen del sprite, donde toca el suelo; body: huella
# que bloquea el paso, centrada en los pies; chimney: salida del humo; light:
# luz calida de las ventanas; shadow: sombra al pie; door: centro de la puerta
# (todo lo que no es size ni feet, relativo a los pies). placeholder_windows:
# ventanas de los placeholders (x0, y0, x1, y1 inclusivos); el arte real mide su
# propio vidrio al generarse.
HOUSE = {
    "size": (156, 198),
    "feet": (72, 198),
    "body": (136, 75),
    "chimney": (68, -111),
    "light": (0, 12),
    "shadow": ((-66, -2), (86, -2), (98, 6), (-58, 6)),
    "door": (0, 0),
    "placeholder_windows": ((18, 158, 30, 170), (110, 158, 122, 170)),
}
LAYOUTS = {
    "house": HOUSE,
    # La casa con un piso mas (y cartel): mas alta, misma huella y puerta.
    "inn": {
        **HOUSE,
        "size": (156, 230),
        "feet": (72, 230),
        "placeholder_windows": HOUSE["placeholder_windows"] + ((18, 190, 30, 202), (110, 190, 122, 202)),
    },
}


def _vec(v):
    return "Vector2(%d, %d)" % v


def _layout_gd(layout):
    fields = ["\"%s\": %s" % (key, _vec(layout[key])) for key in ("feet", "body", "chimney", "light", "door")]
    fields.append("\"shadow\": [%s]" % ", ".join(_vec(p) for p in layout["shadow"]))
    return "{\n\t%s,\n}" % ",\n\t".join(fields)


def write_layout_gd():
    lines = [
        "extends RefCounted",
        "class_name HouseLayout",
        "# GENERADO por tools/house_layout.py (lo corren gen_town_assets.py y",
        "# gen_placeholder_art.py): no editar a mano. Medidas en px de la textura del",
        "# edificio; todo salvo \"feet\" es relativo a los pies.",
        "",
    ]
    for name, layout in LAYOUTS.items():
        lines.append("const %s := %s" % (name.upper(), _layout_gd(layout)))
    lines.append("")
    with open(LAYOUT_GD, "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    write_layout_gd()
