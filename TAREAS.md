# Tareas — El Recuerdo

Backlog simple en Markdown (sin Linear/Jira). Marcá `[x]` a medida que se completa, y sumá
líneas nuevas donde corresponda — no hace falta pedirme que lo actualice, cualquiera puede
editarlo directo. Referencias: `design/documento_base_diseno.md` tiene las mecánicas y
sistemas, `design/historia_lore.md` tiene el lore y la historia completa; esto es solo el
orden de trabajo.

## Estado actual (2026-09, tras la pasada de progresión)

El Nivel 1 ("El Recuerdo") se reconstruyó como un mapa ASCII (`game/levels/level1.txt`) que
`level_loader.gd` convierte en `TileMapLayer` (pixel art de Kenney) + colisiones + entidades.
Es bastante más largo (6 actos, ~235 celdas) y con curva de dificultad real: cada recuerdo
abre un tramo con 2-3 desafíos que exigen esa habilidad y uno que la combina con la anterior.
Jugador y enemigos migraron a sprites pixel 24px (antes eran del pack vectorial + rectángulos
de color). Input map real (`move_left/right`, `jump`, `sprint`, `attack`, `interact`) en vez
de teclas hardcodeadas. HUD con cola de mensajes (ya no se pisan) y contador de recuerdos.
Checkpoints ahora son nodos propios que curan al tocarlos (antes solo guardaban posición).

Verificado con `godot --headless --quit-after 60` sobre el nivel completo: sin errores ni
warnings. Falta el playtest humano real (ver pendientes abajo).

### Enemigos nuevos
`enemy.gd` ahora tiene tres comportamientos (`PATROL`, `GUARD`, `CHASE`) y detección de borde
(no se caen de una repisa). Además de los zombies/elite de antes: un **guardián** que bloquea
un pasillo de techo bajo (no se puede saltar, hay que matarlo), un **perseguidor** que no se
puede matar y obliga a usar sprint para escapar, y **restos** (chicos, 1 HP, rápidos, en trío).

### Bifurcación opcional
Se movió de después del Corredor a **después del Guerrero** (ahora el jugador ya tiene ataque
cuando llega al elite de la recompensa, así la pelea es real). Sigue dando +10% de Estabilidad
máxima (Recuerdo del Mirador) y sigue siendo 100% opcional (el camino principal no la necesita).

### Balance de Estabilidad
Con más saltos en el camino largo, el costo/recuperación viejo (30 por salto, solo se
recupera parado) se sentía como un freno constante. Se ajustó: salto 15 (antes 30), sprint
drena 10/s (antes 14/s), y ahora también se recupera (más lento) caminando, no solo quieto.
Los checkpoints curan Vida y Estabilidad al tocarlos.

### Arreglo de guardianes (`g`) tras playtest
- Bug: los enemigos buscaban al jugador en `_ready`, pero el loader lo agrega al final, así que
  `_player` era null: el guardián nunca se giraba hacia el jugador (le daba la espalda) y el
  perseguidor `h` nunca perseguía. Ahora se resuelve de forma perezosa en `_physics_process`.
- El guardián ahora golpea con animación propia (`attack`, frames de `attack1` de rvros vía
  `gen_shadow_enemies.py`): el daño cae a mitad del tajo si seguís en rango frontal. Su alcance
  (`GUARD_STRIKE_RANGE` 40) queda por debajo del de la espada del jugador (~46) para poder
  pegarle primero. Sigue sin desplazarse: es un bloqueo.
- Perseguidor: `chase_speed` bajó de 200 a 150 (= caminar del jugador; sprint lo deja atrás) y
  se frena en el borde en vez de tirarse al vacío.
- Perseguidor: solo persigue mientras el jugador está en su misma plataforma (`_home_floor`
  vs. último piso del jugador en `enemy.gd`); si caés o te vas, vuelve a patrullar.
- Pistas con caducidad: `HINT_LAST_STAGE` en `hud.gd` dice hasta qué banco alcanzado tiene
  sentido cada pista (`fall_first`, `fall_with_sprint`, `avoidance`, `chaser`, `guard`). Si el
  jugador ya pasó ese banco sin verla, se descarta. `main.gd` avisa al HUD cada banco nuevo.
- Nivel: el techo de 1 celda se podía pisar desde el costado. Ahora cada guardián está en un
  túnel de bloque 4x4 (más alto que el salto), y en el segundo se rellenó el pozo previo.
- Sin validar jugando: dificultad del golpe, entrar al túnel y saltar el pozo de salida.

### Rediseño de combate (primer paso)
- El swing ya no da inmunidad (`take_damage` solo mira `_invulnerable` y `_hit_shield_timer`).
  Un golpe que conecta (`take_hit` devuelve `true`; el perseguidor, que no se puede matar,
  devuelve `false`) da un escudo corto (`HIT_CONFIRM_SHIELD_TIME` 0.3 s) que no bloquea el
  movimiento. Spamear `X` en el aire ya no protege.
- Elite con `Behavior.CHARGE`: patrulla, y si el jugador está a ≤260 px en su altura, destella
  (0.6 s), embiste (330 px/s, hasta 280 px o el borde) y queda aturdido (tinte azul, 0.9 s; 1.5 s
  si choca contra una pared). Constantes `CHARGE_*` en `enemy.gd`. Se ensanchó 2 celdas su
  plataforma (fila 2, cols 194-195) para que se pueda esquivar.
- Arena del elite (cols 194-205, filas 0-2 del mapa): piso de 12 celdas con un muro de 2 a cada
  lado (así la embestida puede chocar y aturdirlo) y una trampilla de una vía (`=`, cols 200-201).
  Se entra desde abajo por una pasarela (`=`, fila 4, cols 191-201) subiendo por las escaleras
  de siempre y saltando a través de la trampilla. El recuerdo del Mirador (`5`) no existe hasta
  vencer al elite: `memory_pickup.lock()/reveal()` + señal `defeated` de `enemy.gd`, cableado
  en `level_loader.gd` (`ELITE_REWARD_MEMORY`). Si la embestida alcanza al jugador termina ahí
  (antes se quedaba trabada empujándolo).
- Arranque de prueba: `debug_start_at_end` en el nodo Main (checkbox del inspector) da todas las
  habilidades y te pone junto al último banco. **Está en `true` en `Main.tscn`: apagarlo antes
  de compartir una build.**
- Validado en headless: el elite pasa por windup → embestida → aturdido y daña; el arranque de
  debug te deja en (200, 7) con habilidades. Sin validar jugando: si 0.3 s de escudo y los tiempos
  del elite se sienten bien.

### Secuencia de expulsión y fondo (fin del Nivel 1)
- Se quitó la cueva (rectángulo negro y degradado). La `X` del mapa (ahora col 219, tras el
  último enemigo) es una zona invisible `expulsion_trigger`. Se rellenó el pozo de la col 227 y
  hay un muro invisible al final del mapa (`_add_end_wall`) para que no se caiga caminando.
- Al cruzarla: `player.begin_expulsion()` drena Estabilidad sola (3/s, +5/s si camina; sin
  sprint ni regeneración, los bancos no curan). El paso se vuelve más pesado con la distancia
  recorrida, no con la Estabilidad: arranca al 70 % de la velocidad (30 % menos) y baja
  gradualmente hasta el 20 % (80 % menos) a los 1100 px. Con Estabilidad 0 pierde 1 de Vida cada
  1.6 s y con 0 de Vida se **desploma** (`collapsed`, animación `die`): no hay respawn ni `died`.
  Constantes `EXPULSION_*` en `player.gd`. Caminando sin parar, el desplome llega a ~21 s
  (medido en headless), unas 31 celdas después del disparador.
- El mapa se extendió a 258 columnas: tramo final de suelo con árbol, arbusto y cartel, y la
  puerta decorativa (`d`) en la col 254, unas celdas más allá de donde se desploma: se la ve,
  no se llega. El muro invisible del final ya no es lo que lo frena.
- `world_progression.gd` deshace la progresión según la Estabilidad: color, tinte frío,
  parallax y capas de audio (melodía < 80 %, pad < 55 %, hum < 30 %), viñeta que se cierra con la
  pérdida de Vida, y fundido a negro al desplomarse (`COLLAPSE_FADE_TIME`).
- **Lo siguiente (despertar en el pueblo real) engancha en `player.collapsed`**
  (`main.gd::_on_player_collapsed`); hoy solo funde a negro.
- Fondo: el parallax anterior estaba fuera de pantalla (el eje Y seguía a la cámara). Ahora son
  dos capas de colinas con pinos (`tools/gen_parallax.py`, `Parallax2D` con escala Y = 1) y un
  cielo en degradé (`Sky` en `Main.tscn`). El parallax sigue apareciendo con el Recuerdo del
  Corredor y se apaga en la expulsión.
- Pensamientos del personaje (`EXPULSION_BEATS` en `world_progression.gd`): subtítulo sin pausa
  (`hud.show_thought`) al arrancar, a 75, 50, 25 y 0 % de Estabilidad, y "Todavía no estoy
  listo." al desplomarse. En cada tramo se apaga un ícono del HUD en orden inverso al ganado
  (espada y estrella, corazón, zapatos, cuerda) y el contador baja (`hud.dim_memory_icon`).
- Puerta: el tile que se usaba (8,6) era una llave, no una puerta. Ahora es un sprite dibujado
  (`assets/props/door.png`, entreabierta con luz al otro lado), hijo de la capa de props.
  Zapatos: ícono nuevo de zapatilla de perfil (`assets/items/shoes.png`). Ambos salen de
  `tools/gen_pixel_props.py`.
- Bug del arranque de debug: contaba los recuerdos dos veces (8/4); corregido.
- Sin validar jugando: los tiempos de la expulsión (≈21 s en total), si la puerta decorativa del
  final (`d`) confunde, y cómo se ve el fundido.

### Preparación del pueblo real (vista cenital)
- **Núcleo compartido** (tarea 2 de `CLAUDE.md`, primera parte): HUD, tinte de mundo y audio por
  capas salieron de `Main.tscn` a `scenes/Core.tscn` (`scripts/core.gd`), que instancian tanto el
  Nivel 1 como el pueblo. La tarjeta de título ahora es opt-in (`hud.play_title_card`). Falta
  todavía extraer Estabilidad/recuerdos como lógica reusable (hoy viven en `player.gd`).
- **Estado entre escenas**: autoload `GameState` (`scripts/game_state.gd`) guarda habilidades,
  Vida y Estabilidad; autoload `SceneRouter` (`scripts/scene_router.gd`) hace el cambio con
  fundido. Al desplomarse (`player.collapsed`) `main.gd` espera 6 s (`COLLAPSE_HOLD_TIME`),
  captura el estado y va a `scenes/Town.tscn`. Cadena completa validada en headless (~27 s).
- **Pueblo de prueba** (`scenes/Town.tscn`): mapa ASCII `levels/town.txt` (48x30) cargado por
  `town_loader.gd` (pasto, camino con bordes, árboles, 4 casas, 2 NPCs). Jugador cenital
  (`scenes/TopDownPlayer.tscn`, 8 direcciones, sin gravedad) y `Npc.tscn` que habla por la cola
  de mensajes del HUD con `interact` (Enter). Nuevas acciones `move_up`/`move_down`. Textos de
  NPCs en `data/town_npcs.gd` (**de prueba**, falta la sesión de escritura).
- Al despertar: Vida completa y Estabilidad al 40 % (`WAKE_STABILITY_RATIO`, **placeholder**:
  qué la recupera en el mundo real sigue abierto), colores plenos y un pensamiento de prueba.
  Correr `Town.tscn` suelta (F6) simula ese estado (`GameState.ensure_defaults`).
- Arte: Mana Seed (suelo y árboles) y Mini Adventure Heroes (personajes) del bundle local,
  recortados por `tools/gen_town_assets.py` + `tools/build_topdown_frames.gd`; la casa es un
  placeholder dibujado por script. Son packs comprados: ver `game/assets/town/SOURCE.md`. Los
  personajes (16 px) se dibujan al doble de escala que el suelo para respetar las proporciones
  de Mana Seed.
- Correcciones tras el primer playtest del pueblo: las filas de las hojas de personajes son
  abajo/izquierda/derecha/arriba (verificado contra los gif del pack; antes estaban izquierda y
  derecha cruzadas). La ampliación de Estabilidad máxima del recuerdo del Mirador ya funcionaba
  (90 → 100, barra 216 → 240 px) pero el tramo nuevo de la barra era oscuro sobre oscuro: ahora
  se ilumina y la barra destella al crecer (`hud._highlight_bar_growth`).
- Sin validar jugando: cámara/zoom (1.5) y velocidad (130 px/s) del jugador cenital, colisiones
  de árboles y casas, y cómo se siente la llegada. Sin hacer: interiores, salida del pueblo,
  primer recuerdo ajeno, música propia del pueblo.

### Segunda pasada (mismo día, tras el primer playtest)
- Jugador con sprites humanos de rvros ("Animated Pixel Adventurer" v1.5, ver
  `game/assets/player/SOURCE.md`): idle, run, jump, fall, ataque real con espada, herido, muerte.
- Enemigos en capa de colisión propia: ya no se traban entre ellos ni traban al jugador. El
  guardián sigue siendo sólido a propósito.
- HUD: fila de íconos de recuerdos que se encienden al recuperarlos, tarjeta de título al
  arrancar, flash de barras al recibir daño.
- Checkpoint dibujado como banco (gris hasta activarse). Íconos nuevos: cuerda de saltar
  (Saltador, antes era un diamante) y estrella (Mirador).
- Pistas de una sola vez: primera caída, caída ya con sprint, primer toque del perseguidor,
  guardián sin ataque, primer banco, y muerte.
- Morir ya no recarga la escena (perdías 15 minutos): vuelve al último banco con su mensaje.
- Enemigos rehechos como **siluetas de sombra del propio aventurero**, desdibujadas con ruido y
  sin rostro (`game/tools/gen_shadow_enemies.py`, reproducible): sombra gris-violeta para la
  patrulla, guardián negro sólido con la espada afuera, perseguidor casi humo con jirones,
  elite rojo apagado, restos como fragmentos chicos. Ya no quedan cajitas de Kenney en juego
  (la hoja `assets/characters/characters_packed.png` queda por si sirve para otra cosa).

### Bug corregido
`enemy.gd` inicializaba `health` con el valor por defecto del script en vez del `max_health`
exportado por instancia — el elite peleaba con 2 HP en vez de 5. Ya usa el valor real.

## Pulido pendiente (corto plazo)

- [ ] Pasarle el nivel nuevo (mucho más largo) a más gente y anotar qué no se entiende sin
      que se lo expliques antes — especialmente el guardián/perseguidor, que son mecánicas
      nuevas.
- [ ] Revisar el balance con vida propia: ¿los costos de Estabilidad ajustados (15/sprint 10)
      se sienten bien en un nivel largo? ¿el guardián es demasiado/poco tanque con 2 HP?
- [ ] Considerar si el HUD necesita más ajustes de tamaño/posición en distintos monitores.
- [ ] `game/tools/dump_level.gd` (script de verificación que cuenta entidades del nivel) tiene
      un problema pendiente: los grupos `checkpoints`/`cave_entrance`/`kill_zone` dan 0 cuando
      se corre el loader aislado (fuera de `Main.tscn`) aunque el juego real anda bien — no
      se investigó a fondo, es una herramienta de debug, no bloquea nada del juego.

## Proyecto 1.5 — Progresión visual y sonora (implementado 2026-09-12)

Sección 15 del documento base, hecha. Todo cuelga de `main.gd::_on_ability_unlocked`, que
delega en `WorldProgression` (`scripts/world_progression.gd`):

- [x] Shader de saturación (`shaders/world_tint.gdshader`) en un `CanvasLayer` debajo del HUD:
      el mundo arranca casi gris y frío; Saltador abre un parche de color alrededor del
      jugador; Corredor lo agranda; Vida vuelve el color la norma; Guerrero lo completa.
- [x] Estabilidad: pulso de viñeta + sacudida de cámara (corporal, no de color). Con
      Estabilidad < 40 % la viñeta se cierra y la música se apaga (filtro pasa-bajos).
- [x] `Parallax2D` con colinas en silueta (`assets/tiles/parallax_hills.png`), invisible hasta
      el Recuerdo del Corredor. Color de cielo base frío (`SKY_COLOR` en `main.gd`).
- [x] Props (cartel, árbol, puerta) en una `TileMapLayer` aparte que aparece con Vida.
- [x] Boca de la cueva en penumbra: degradado a negro sobre las últimas 7 celdas.
- [x] Audio sintetizado (`tools/gen_audio.py`, numpy, reproducible): viento, hum, pad de
      acordes menores, melodía, y 7 SFX. `scripts/audio_layers.gd` (grupo `"audio"`) sube cada
      capa con cada recuerdo y baja todo menos el viento al llegar a la cueva. Buses
      `Ambient`/`Music`/`SFX` en `assets/audio/default_bus_layout.tres`.

Ajuste posterior (mismo día): el suelo dejó de ser pasto verde (tiles de tierra oscura con un
tinte frío, `GROUND_TINT` en `level_loader.gd`) y los pinchos pasaron al tile gris (8,3),
porque el anterior parecía un buzón. Se agregó `CLAUDE.md` en la raíz con estructura,
intención, dónde vive el lore y prácticas.

Pendiente de esta fase: escuchar/mirar en el juego real y ajustar números (los valores de
`WorldProgression` y los volúmenes en dB son un primer tiro a ciegas, validado solo headless).
El audio sintético es un placeholder honesto: si el tono no convence, se reemplaza por packs
sin tocar código (mismos nombres de archivo en `assets/audio/`).

## Proyecto 3 — El pueblo real y el primer recuerdo ajeno (después del Nivel 1)

Actualizado 2026-09-17: ya **no** es un mini-dungeon en una cueva — ese diseño quedó
descartado. Del documento base, sección 7 en adelante; contexto narrativo completo en
`historia_lore.md` sección 13 ("Qué sigue después de la expulsión").

### Assets comprados para esto (2026-09-17)

"The Complete RPG Creator Bundle" (GameDev Market, vía Humble Bundle) — 79 assets, licencia
comercial perpetua sin límite de proyectos (confirmada en la página de términos de GameDev
Market). Descarga y key de canje quedan del lado del usuario, no en el repo.

De los 79, los que están pensados para Proyecto 3 (aún sin descargar/importar a `game/`):
- **2D Buildings Town** — pueblo exterior.
- **Pixel Art Medieval Interiors** — interiores de casas.
- **2D Top Down Character Bundle** + **Pixel Art RPG Top Down Characters** — variedad de NPCs.
- **Mini City Asset Pack** + **Mini City Interiors Tilesets** — alternativa/complemento del mismo autor.
- **Fantasy Character Avatars** (retratos Orcs/Goblins/Undeads/Humans/Dwarves/Elves) — candidato para portraits de diálogo, incluidos los "Colapsados".
- **Mana Seed Pixel Art Tileset Collection** — colección grande aparte, incluye protagonista base; revisar antes de decidir si reemplaza o complementa lo de arriba.

Pendiente: abrir los archivos, confirmar que combinan en paleta/escala entre sí (son de
autores distintos dentro del mismo bundle), y recién ahí importar a `game/assets/` con su
`SOURCE.md` correspondiente (mismo patrón que `game/assets/player/SOURCE.md`).

### Parte A — Secuencia de expulsión (fin del Nivel 1)

- [ ] Drenaje automático de Estabilidad después del último acto (Guerrero), sin input del
      jugador (`historia_lore.md` sección 13).
- [ ] Reversión de `WorldProgression`/`audio_layers` en función de la Estabilidad que baja
      (desaturar, apagar parallax, perder capas de audio) — es la misma infraestructura de la
      sección 15 del doc base, corrida al revés.
- [ ] Movimiento más pesado a medida que baja la Estabilidad.
- [ ] Al llegar a 0%, expulsión al mundo real (no una puerta que el jugador cruza a voluntad).

### Parte B — El pueblo real (hub)

- [ ] Nueva escena/mapa para el pueblo real (no reusa `level1.txt` — es un espacio distinto).
- [ ] Primer(os) NPC(s) de verdad, con diálogo real (no solo un objeto que se toca).
- [ ] Revelar el lore/la Fractura de a poco a través de esas conversaciones, sin exposición de
      una sola vez.

### Parte C — El primer recuerdo ajeno

- [ ] Definir género, NPC dueño del recuerdo, y si tiene mini-boss/puzzle propios —
      pendiente de decisión de diseño (`historia_lore.md` sección 15, Preguntas abiertas).
- [ ] Umbral visible en pantalla (objeto/persona/lugar) que dispara el cambio de género al
      entrar (sección 16 del doc base, reglas del salto de género).
- [ ] Nueva habilidad de recompensa al resolverlo (ej. Recuerdo del Pájaro → doble salto, si
      se mantiene ese ejemplo).

## Semillas de diseño para más adelante

De la sección 14 del doc — todavía no tienen dueño de cuándo se implementan:

- [ ] Soledad como ritmo ambiental (reloj social sin barra visible).
- [ ] Conexión con costo real (llevar a un aliado a un recuerdo también lo afecta a él).
- [ ] Humor como evitación válida (NPC que deflecta con chistes).
- [ ] Dash real ("Recuerdo de la Centella", distinto del sprint actual).
- [ ] Doble salto ("Recuerdo del Pájaro").
