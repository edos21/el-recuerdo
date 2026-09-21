Arte del pueblo real (vista cenital). Son recortes/copias de packs COMPRADOS, no
CC0. Por eso NO estan en el repositorio (ver .gitignore): solo se versiona `house.png`
(propia) y este archivo. `tools/gen_placeholder_art.py` crea placeholders.

- `ground.png`, `tree_a.png`, `tree_b.png`: Mana Seed "Summer Forest" (Seliel the
  Shaper, https://seliel-the-shaper.itch.io/). Tiles sueltos de `summer forest.png` y
  arboles de `summer trees 80x112.png`. Licencia de compra en itch.io: no
  redistribuir el asset por separado.
- `hero.png`, `npc_a.png`, `npc_b.png`: "Mini Adventure Heroes - Humans" (Beowulf,
  https://beowulf.itch.io/). Hojas copiadas tal cual (`mhap_male_hero_02`,
  `mhap_female_cultivator_01`, `mhap_male_cultivator_01`). Licencia de compra.
- `house.png`: dibujada a mano por script (`tools/gen_town_assets.py`), placeholder
  hasta tener casas definitivas. Sin licencia externa.

Los packs originales viven fuera del repo (por defecto en ~/Downloads/rpg_bundle;
variable RPG_BUNDLE para cambiarlo). Regenerar: `python3 tools/gen_town_assets.py`
y luego `godot --headless --script res://tools/build_topdown_frames.gd`.
