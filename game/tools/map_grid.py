# Lectura de mapas ASCII para los generadores, con la misma semantica que
# MapUtils (scripts/map_utils.gd): si el arte y el juego leyeran distinto un mismo
# mapa (un CRLF, una fila vacia), la imagen y las colisiones se desincronizarian.


# Interiores: el mapa de cada cuarto (levels/) y la imagen que se arma con el
# (assets/town/). Lo leen el generador del arte real y el de placeholders.
INTERIORS = (("inn_room.txt", "inn_room"), ("inn_hall.txt", "inn_hall"))


def read_grid(path):
    """Filas del mapa sin '\\r' y sin la ultima linea vacia, como MapUtils.read_grid."""
    with open(path, newline="") as f:
        rows = f.read().replace("\r", "").split("\n")
    if rows and rows[-1] == "":
        rows.pop()
    return rows


def cell_hash(col, row):
    """Numero estable por celda, igual a MapUtils.cell_hash."""
    return abs((col * 73856093) ^ (row * 19349663))


def at(rows, col, row):
    return rows[row][col] if 0 <= row < len(rows) and 0 <= col < len(rows[row]) else ""
