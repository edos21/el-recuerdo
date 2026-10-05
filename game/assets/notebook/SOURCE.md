Dibujos del cuaderno (una lámina por entrada, `<id de la entrada>.png`).

- Las 7 láminas del primer día las aportó el dueño como una sola imagen (collage) y se
  recortaron en una lámina por entrada, sin otro retoque. Mapa: `woke_up` (valija), `tomas_keys`
  (llavero sobre la plaza), `inn_water` (balde con pez), `broth` (olla y vapor), `dont_know`
  (figura borrosa y valija), `guest_book` (posada de noche), `flor_husband` (silla).
- `tools/gen_notebook_drawings.py` genera placeholders y solo crea los que faltan; un archivo
  que ya está acá nunca se pisa (sirve para una entrada nueva sin lámina todavía).
- Para reemplazar una lámina: guardarla con el mismo nombre en esta carpeta. No hace falta
  recortar el fondo del papel: `shaders/drawing_on_paper.gdshader` la mezcla con la página.
