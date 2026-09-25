Arte del pueblo real (vista cenital). Son recortes/copias de packs COMPRADOS, no
CC0. Por eso NO estan en el repositorio (ver .gitignore): solo se versiona este
archivo. `tools/gen_placeholder_art.py` crea placeholders.

- `ground.png`, `tree_a.png`, `tree_b.png`: Mana Seed "Summer Forest" (Seliel the
  Shaper, https://seliel-the-shaper.itch.io/). Tiles sueltos de `summer forest.png` y
  arboles de `summer trees 80x112.png`. Licencia de compra en itch.io: no
  redistribuir el asset por separado.
- `hero.png`, `npc_a.png`, `npc_b.png`: "Mini Adventure Heroes - Humans" (Beowulf,
  https://beowulf.itch.io/). Hojas copiadas tal cual (`mhap_male_hero_02`,
  `mhap_female_cultivator_01`, `mhap_male_cultivator_01`). Licencia de compra.
- `house_a.png`, `house_b.png`, `house_c.png`: Mana Seed "Thatch Roof Home" (Seliel the
  Shaper). Casas armadas por script con piezas del kit modular (`home exteriors, thatch
  roof v1/v2/v3.png`: una variante de color por casa). Junto a cada casa el generador escribe
  `house_x_windows.png` (mascara de ventanas, blanco donde hay vidrio visible; derivada del vidrio del kit,
  la lee el shader de ventanas encendidas) y `data/house_layout.gd` (anclajes, desde
  `tools/house_layout.py`). El vidrio conserva su color original. Licencia de compra.

Los packs originales viven fuera del repo (por defecto en ~/Downloads/rpg_bundle;
variable RPG_BUNDLE para cambiarlo). Regenerar: `python3 tools/gen_town_assets.py`
y luego `godot --headless --script res://tools/build_topdown_frames.gd`.
