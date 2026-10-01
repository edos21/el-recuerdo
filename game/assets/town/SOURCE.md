Arte del pueblo real (vista cenital). Son recortes/copias de packs COMPRADOS, no
CC0. Por eso NO estan en el repositorio (ver .gitignore): solo se versiona este
archivo. `tools/gen_placeholder_art.py` crea placeholders.

Licencia de Mana Seed (Seliel the Shaper): https://selieltheshaper.weebly.com/user-license.html
Comprado en GameDevMarket (https://www.gamedevmarket.net/asset/mana-seed-pixel-art-tileset-collection).
Resumen: se puede usar en un juego (incluso comercial), recolorear y modificar, y no exige
credito. NO se puede revender ni redistribuir el asset suelto. Una build del juego con el arte
empaquetado (demo, prueba con amigos) entra en el uso permitido; el repo publico no debe
llevar los PNG. Uso de este proyecto: personal, sin venta.

- `ground.png`, `tree_a.png`, `tree_b.png`: Mana Seed "Summer Forest" (Seliel the
  Shaper, https://seliel-the-shaper.itch.io/). Tiles sueltos de `summer forest.png` y
  arboles de `summer trees 80x112.png`. Licencia de compra: no redistribuir el asset por
  separado.
- `hero.png`, `npc_a.png`, `npc_b.png`: "Mini Adventure Heroes - Humans" (Beowulf,
  https://beowulf.itch.io/). Hojas copiadas tal cual (`mhap_male_hero_02`,
  `mhap_female_cultivator_01`, `mhap_male_cultivator_01`). Licencia de compra.
- `innkeeper.png` (la posadera): mismo pack, `Base Characters/Female Base/mhap_female_human_base_01.png`,
  copiada tal cual. Licencia de compra.
- `house_a.png`, `house_b.png`, `house_c.png`: Mana Seed "Thatch Roof Home" (Seliel the
  Shaper). Casas armadas por script con piezas del kit modular (`home exteriors, thatch
  roof v1/v2/v3.png`: una variante de color por casa). Junto a cada casa el generador escribe
  `house_x_windows.png` (mascara de ventanas, blanco donde hay vidrio visible; derivada del vidrio del kit,
  la lee el shader de ventanas encendidas) y `data/house_layout.gd` (anclajes, desde
  `tools/house_layout.py`). El vidrio conserva su color original. Licencia de compra.

- `inn.png`, `inn_windows.png`: la posada, armada por script con el mismo kit "Thatch Roof
  Home" (variante v3) y un piso alto de su seccion "Upper Floors". El cartel sale de Mana Seed
  "Village Accessories" (Seliel the Shaper): el soporte con tabla lisa de
  `village accessories 32x32.png` y, encima, la tabla con la cama de
  `village accessories 16x16.png`. Licencia de compra.

- `inn_room.png`: la habitacion de la posada, armada por script leyendo `levels/inn_room.txt` con
  piezas de `home interiors, thatch roof v2.png` (Mana Seed "Thatch Roof Home": empedrado,
  pared de madera y revoque, ventana encendida, umbral) y el paisaje enmarcado de
  `cozy furnishings 32x32.png` (Mana Seed "Cozy Furnishings"). Licencia de compra.
- `inn_hall.png`: el salon de la posada, armado igual que `inn_room.png` leyendo
  `levels/inn_hall.txt`, con la escalera de `_extras/bonus wooden stairs.png` (Mana Seed, extras
  de la coleccion). Licencia de compra.
- `inn_counter.png` (el mostrador): escritorio ancho de `cozy furnishings 48x32.png`.
  `inn_table_set.png`: la mesa redonda de `cozy furnishings 32x32.png` con una silla de
  `cozy furnishings 16x32.png` a cada lado (la derecha, espejada). `inn_pot.png` (tira de 5
  cuadros): copia de `thatch roof sliceable/animated cooking pot 32x32.png`. Todo Mana Seed,
  licencia de compra.
- `inn_bed.png`: copia de `thatch roof sliceable/thatch roof bed 32x64.png` (Thatch Roof Home).
  `inn_trunk.png` (la valija): recorte del baul de `cozy furnishings 32x32.png`.
  `inn_desk.png`: el escritorio con cajones de ese mismo archivo con una pila de libros y un libro
  abierto de `cozy furnishings 16x16.png`. Todo Mana Seed (Seliel the Shaper), licencia de compra.
- `inn_candle.png` (tira de 4 cuadros): la vela en candelero de
  `animated candles anim 16x16 v01.png`, Mana Seed "Animated Candles". Licencia de compra.

- `well.png`: el pozo con manivela de `village accessories 48x80.png` (Mana Seed "Village
  Accessories"). Licencia de compra.
- `keys.png`: la llave de `PNGs/key.png` del pack "Pixel Art Dungeon Level 4" (Acasas), sin la
  sombra que trae pegada. Es la unica pieza del pueblo que no es Mana Seed (no hay llaves en la
  coleccion); a reemplazar en la pasada de arte (#65). Licencia de compra.

Los packs originales viven fuera del repo (por defecto en ~/Downloads/rpg_bundle;
variable RPG_BUNDLE para cambiarlo). Regenerar: `python3 tools/gen_town_assets.py`
y luego `godot --headless --script res://tools/build_topdown_frames.gd`.
