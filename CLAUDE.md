# El Recuerdo — guía del proyecto

Juego en **Godot 4.7** con progresión ligada a recuerdos. Proyecto personal de aprendizaje:
la meta es **terminar juegos chicos con identidad propia**, no armar el RPG gigante de una.
Idioma del proyecto: español (textos del juego, comentarios, docs).

**El género no está fijo.** El Nivel 1 es un plataformas 2D, pero lo que se mantiene entre
proyectos es el tono, el lore, la Estabilidad y los recuerdos como habilidades; el género de
cada capítulo puede cambiar (cenital, turnos, cartas, puzzle, lo que sirva para aprender). La
justificación narrativa de los saltos de género vive en `design/historia_lore.md`; la tabla de
géneros candidatos y las reglas técnicas para que el salto no rompa el proyecto, en la sección
16 del documento base.

## Intención en dos líneas

El protagonista recupera habilidades recuperando recuerdos; el mundo se vuelve más nítido a
la vez que él. Tono: 70% aventura, 20% misterio, 10% melancolía. **Hermoso pero algo está
mal.** Nunca "estar mal te hace fuerte", nunca moraleja simplona.

## Dónde está cada cosa

| Qué | Dónde |
|---|---|
| **Lore e historia** (mundo, la Fractura, protagonista, misterio, filosofía narrativa, arco emocional, preguntas abiertas) | `design/historia_lore.md` |
| **Diseño de sistemas y mecánicas** (Estabilidad numérica, skills, niveles, arquitectura técnica, sección 15 de progresión visual, sección 16 de géneros) | `design/documento_base_diseno.md` |
| **Backlog y estado actual** (qué se hizo, qué falta, decisiones tomadas) | `TAREAS.md` |
| Proyecto Godot | `game/` (abrir esa carpeta desde Godot) |
| Nivel 1 (fuente de verdad) | `game/levels/level1.txt` (mapa ASCII, 1 carácter = celda de 36 px) |
| Intérprete del mapa | `game/scripts/level_loader.gd` (leyenda de caracteres en el `match` de `build()`) |
| Datos de los recuerdos | `game/data/memories.gd` |
| Coordinador de señales (Nivel 1) | `game/scripts/main.gd` |
| Núcleo compartido entre géneros (HUD, tinte, audio por capas) | `game/scenes/Core.tscn`, `game/scripts/core.gd` |
| Estado que sobrevive al cambio de escena / cambio con fundido | autoloads `game/scripts/game_state.gd`, `game/scripts/scene_router.gd` |
| Pueblo real (cenital): escena, mapa, cargador, NPCs | `game/scenes/Town.tscn`, `game/levels/town.txt`, `game/scripts/town_loader.gd`, `game/data/town_npcs.gd` |
| Jugador cenital y NPC | `game/scenes/TopDownPlayer.tscn`, `game/scenes/Npc.tscn` (+ `topdown_player.gd`, `npc.gd`) |
| Progresión visual/sonora | `game/scripts/world_progression.gd`, `game/shaders/world_tint.gdshader`, `game/scripts/audio_layers.gd` |
| Prefabs | `game/scenes/` (`Player`, `Enemy`, `MemoryPickup`, `Checkpoint`; `Main` solo tiene infraestructura) |
| Generadores (una sola corrida, reproducibles) | `game/tools/*.gd` (headless), `game/tools/gen_*.py` (enemigos, parallax, props dibujados, arte del pueblo), `tools/gen_audio.py` |
| Packs descargados sin importar | `assets-library/` (no se referencia desde el juego; se copia a `game/assets/`) |
| Licencias de assets | `game/assets/player/SOURCE.md`, `game/assets/town/SOURCE.md` (packs comprados) + `License.txt` de cada pack |

## Arquitectura (cómo se conecta)

- `Main.tscn` **no contiene el nivel**. Al arrancar, `main.gd` llama a `level_loader.build()`,
  que lee el ASCII y construye `TileMapLayer` (visual) + `StaticBody2D` por tramo (colisión)
  + instancias de enemigos, recuerdos, bancos, la zona invisible de expulsión y la zona de muerte. Editar el nivel es
  editar el `.txt`; agregar un tipo de objeto nuevo es agregar un carácter al `match`.
- **Flujo de escenas**: `Main.tscn` (Nivel 1, plataformas) → al desplomarse tras la expulsión,
  `SceneRouter.change_scene()` con fundido → `Town.tscn` (cenital). Cada escena instancia
  `Core.tscn` para HUD/tinte/audio y decide cómo se ve el mundo (`core.set_world_look`). Lo que
  debe sobrevivir al cambio vive en el autoload `GameState`; los jugadores de cada género
  emiten las mismas señales (`health_changed`, `stability_changed`) para que el HUD no cambie.
- Todo se comunica por **señales** desde `player.gd` (`ability_unlocked`, `health_changed`,
  `stability_changed`, `respawn_requested`, `died`) y **grupos** (`player`, `hud`, `audio`,
  `checkpoints`, `expulsion_trigger`, `kill_zone`). `main.gd` es el único que conecta cosas.
- Los nodos se hablan por grupo cuando no se conocen: `get_tree().call_group("hud",
  "show_message", ...)`, `call_group("audio", "play_sfx", "jump")`. Si un grupo no existe, la
  llamada es un no-op silencioso (útil para agregar sistemas sin romper nada).
- Capas de colisión: **1 = mundo y jugador, 2 = enemigos**. Los enemigos no chocan entre sí ni
  traban al jugador; el daño va por `HurtBox` (Area2D). El guardián usa 1+2 para ser sólido.
- Regla de oro de diseño (sección 12 del doc): cada sistema responde **qué hace** y **qué
  significa**. Si una mecánica nueva no tiene significado narrativo, revisar antes de sumarla.

## Cómo validar (siempre, antes de dar algo por terminado)

```bash
cd game
godot --headless --import                 # tras agregar assets nuevos
godot --headless --quit-after 60          # carga el juego real; sin salida = sin errores
godot --headless --script res://tools/build_tileset.gd   # si cambiaron coords de tiles
```

- La corrida headless **no reemplaza jugarlo**: valida que carga y no crashea, no que se
  siente bien. Números de balance, colores y volúmenes se ajustan jugando.
- Al salir en headless aparecen "8 ObjectDB instances leaked" por los loops de audio: es un
  artefacto del driver de audio simulado, no un bug del juego.
- `tools/dump_level.gd` cuenta entidades del nivel; tiene un problema conocido con los grupos
  al correr fuera de `Main.tscn` (ver `TAREAS.md`).

## Buenas prácticas del proyecto

**Adoptadas**
- Nivel como datos + intérprete (patrón LDtk/Tiled en versión mínima). Escenas chicas y
  muchas; nunca volver a un `Main.tscn` gigante con todo adentro.
- Constantes con nombre para todo número de balance (`player.gd`, `enemy.gd`,
  `world_progression.gd`). Nada de valores mágicos sueltos.
- Assets generados por script, reproducibles, con el script en el repo. Si se cambia un
  sprite o un sonido a mano, anotar la fuente en `SOURCE.md`.
- Comentarios en español, solo para el **por qué**. No comentar el diff ni el qué.
- Input por acciones del input map (`jump`, `sprint`, `attack`, `interact`,
  `move_left/right`), nunca teclas hardcodeadas.

**Pendientes / recomendadas por la industria**
- **Mover datos a `Resource` (`.tres`)**: `data/memories.gd` y los stats por tipo de enemigo
  en `level_loader.gd::_add_enemy` deberían ser `MemoryData` / `EnemyData` resources
  editables en el inspector. Es el siguiente paso natural para que datos y lógica se separen.
- Si aparece un diseñador de niveles (o cansa el texto), migrar el ASCII a **LDtk** y
  reescribir solo el loader; el resto no cambia.
- Cuando el proyecto entre a git: `.tscn`/`.tres` en texto (nunca en LFS), LFS solo para
  imágenes/audio; una persona por escena a la vez; considerar `gdmerge` para merges.
- Máquina de estados formal para el jugador cuando sumen dash/doble salto (hoy son flags
  booleanos, alcanzan para el Nivel 1, no para el árbol de skills del Proyecto 4).
- Señales: no encadenar más de dos o tres saltos; no rebotar señales del hijo al padre.

## Cosas que NO hacer

- No editar `.tscn` a mano cuando hay un script que los genera (sprites, tileset): correr el
  generador. Los `.tscn` de `scenes/` sí se editan (a mano o en el editor).
- No poner IDs de tickets ni fechas en comentarios de código; eso vive en `TAREAS.md`.
- No agregar packs a `game/assets/` sin licencia anotada.
- No "arreglar" un test o validación para que pase: si el headless falla, es un bug.

## Futuras tareas (resumen; detalle en `TAREAS.md`)

1. Playtest humano del nivel largo y ajuste de balance/color/audio a ojo y oído.
2. Datos a `.tres` (recuerdos, enemigos). Núcleo compartido: HUD, tinte y audio ya viven en
   `Core.tscn` y el estado en `GameState`; falta extraer la lógica de Estabilidad/recuerdos
   (hoy en `player.gd`) antes del primer recuerdo ajeno (Proyecto 3, punto 3 abajo).
3. Proyecto 3 (**arrancado**: pueblo cenital de prueba con NPCs, ver `TAREAS.md`; 2026-09-17, ya no es un "mini dungeon en la cueva" — ver
   `design/documento_base_diseno.md` sección 7 y `design/historia_lore.md` sección 13): la
   secuencia de expulsión del recuerdo propio (Nivel 1) devuelve al jugador al **pueblo real**,
   donde arranca el juego de verdad — explorar, hablar con NPCs, entender el lore de a poco —
   y recién después encuentra el primer recuerdo ajeno, jugado en un género distinto al
   plataformas. Qué género, quién es el NPC dueño de ese recuerdo, y si tiene mini-boss/puzzle
   propios, quedan como preguntas abiertas (`design/historia_lore.md` sección 15) hasta la
   próxima sesión de diseño.
4. Semillas (sección 14 del doc): soledad como ritmo ambiental, conexión con costo, humor como
   evitación válida, dash real.

## Convenciones de trabajo con agentes

- Antes de cambiar comportamiento de juego, leer `TAREAS.md` (estado y decisiones ya tomadas)
  y la sección que corresponda de `design/documento_base_diseno.md` (mecánicas) o
  `design/historia_lore.md` (lore/historia). Si una decisión de diseño cambia, anotarla ahí.
- Al terminar una pasada: correr el headless, actualizar `TAREAS.md` (tildar, sumar lo nuevo,
  registrar desvíos respecto a lo planificado) y decir explícitamente qué **no** se validó
  jugando.
