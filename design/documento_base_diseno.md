# Proyecto Godot — Documento base de diseño

Este documento es la referencia de **sistemas y mecánicas**: números, estructura de niveles,
árbol de skills, arquitectura técnica y las reglas de cada género. El **lore, la premisa del
mundo (la Fractura), el protagonista, el mensaje central y la historia completa** viven en
`design/historia_lore.md` — empezar ahí si la pregunta es "qué significa esto", no "cómo se
implementa".

## 1. Sistema de MP / Estabilidad

En lugar de maná convencional, el personaje tiene una reserva mental.

Nombres posibles:

- Estabilidad
- Claridad
- Presencia
- Integridad

**Nombre provisional: Estabilidad.**

Las habilidades consumen Estabilidad porque interactuar profundamente con recuerdos tiene un costo psicológico.

Ejemplos:

- Dash → coste bajo
- Ataque especial → coste medio
- Entrar profundamente en un recuerdo → coste alto
- Alterar un recuerdo → coste muy alto

## Estados de Estabilidad

### 70–100%

Estado normal.

- Percepción estable
- Mundo relativamente coherente
- Control completo de las habilidades

### 40–70%

Percepción alterada.

- aparecen detalles ocultos
- pueden aparecer figuras o frases que otros no perciben
- algunos caminos alternativos se vuelven visibles
- los recuerdos empiezan a filtrarse en el mundo

### 20–40%

Fragmentación.

- habitaciones pueden cambiar
- sonidos pueden distorsionarse
- enemigos pueden adoptar brevemente formas diferentes
- recuerdos distintos pueden mezclarse
- aparecen pistas imposibles de encontrar en estado normal

### 0–20%

Estado crítico.

- percepción poco fiable
- peligro aumentado
- recuerdos pueden imponerse sobre el presente
- algunas habilidades pueden comportarse de forma diferente

Importante: estos estados no deben convertirse simplemente en "más bajo = peor".

Cierta percepción alterada puede revelar información útil.

El jugador debe aprender a navegar entre estabilidad y vulnerabilidad.

## Costo de Estabilidad por género (decisión 2026-09-17)

El costo no es una lista fija de acciones (saltar, atacar) válida para todo el juego — eso
solo tenía sentido mientras el único género era el plataformas. Con el primer recuerdo ajeno
en un género distinto (sección 7), saltar deja de ser una acción del juego.

Principio general, no lista cerrada: **cuesta Estabilidad forzar el recuerdo más allá de su
forma natural** — cuanto más el jugador empuja contra las reglas de quien lo recordaba, más
paga. Cada género define qué significa "empujar" en sus propios términos:

- **Plataformas** (Nivel 1, ya implementado en `player.gd`): salto, sprint, ataque.
- **Cenital con luz** (candidato para el primer recuerdo ajeno): saltar/esprintar no
  aplican — el costo lógico sería la percepción activa (linterna encendida, "mirar" en la
  oscuridad), no el movimiento. Sin definir todavía.
- Géneros futuros: cada capítulo define el costo cuando se diseñe, no antes. No hace falta
  una tabla universal — la Estabilidad como recurso compartido (sección 16, hilo común) es lo
  que une los géneros, no una lista idéntica de acciones que la gastan.

Esto implica que el costo de Estabilidad deja de vivir solo en `player.gd`: cada escena de
género tendrá su propia lógica de costo, todas escribiendo al mismo recurso.

---

# 2. Recuperación de Estabilidad

La Estabilidad no debería recuperarse exclusivamente mediante pociones.

La recuperación puede estar vinculada a:

- descansar
- regresar a lugares seguros
- conversar
- ayudar a otros
- recibir ayuda
- recordar experiencias positivas
- reconstruir vínculos
- aceptar determinados recuerdos

Esto conecta directamente mecánica y narrativa.

## Concepto importante

**La conexión es un recurso.**

No necesariamente una moneda o estadística literal, sino un principio sistémico.

El protagonista puede hacer cosas solo, pero ciertas heridas y recuerdos requieren de otras personas.

## Recuperación distinta dentro de un recuerdo vs. en el mundo real (decisión 2026-09-17)

**Dentro de un recuerdo** (cualquier género), la Estabilidad se recupera con un punto de
descanso propio de ese género — en el plataformas son los bancos/checkpoints (ya
implementados, curan Vida y Estabilidad al tocarlos). Cada género nuevo define el suyo (un
lugar iluminado en cenital, por ejemplo). Es, en esencia, un recurso de videojuego con puntos
de recarga: se comporta igual sin importar de quién sea el recuerdo.

**En el mundo real**, la Estabilidad deja de comportarse así — no tiene sentido que suba sola
por estar parado, porque ahí no está "jugando" un recuerdo, está viviendo. Recupera con
acciones de conexión real, que es justo lo que esta sección ya anticipaba ("la conexión es un
recurso") sin haberlo bajado a mecánica todavía. Candidatos concretos, sin decidir cuál (o
cuál combinación):

1. **Conversar** — hablar con un NPC devuelve un poco de Estabilidad, pero solo la primera vez
   por NPC en cada visita/capítulo (para que no sea grindeable repitiendo el mismo diálogo).
2. **Ayudar con algo puntual** — una tarea chica y acotada (no una quest larga, para no
   contradecir "ayudar a alguien no significa solucionar su vida") da una recuperación mayor
   que solo conversar.
3. **Volver a un lugar personalmente significativo** — no cualquier banco, un lugar concreto
   (su casa, quizás) con recuperación pasiva lenta — pocos lugares así, no uno por esquina.
4. **Aceptar un fragmento ajeno resuelto** — ya cubierto en `historia_lore.md` sección 14
   (el tope máximo sube al cerrar fragmentos).

La idea detrás de cualquier combinación: en el mundo real la Estabilidad se comporta como lo
que significa (sección 12, Regla de oro) — no se cura sola, requiere hacer algo con alguien.
Sigue como pregunta abierta en `historia_lore.md` sección 15 hasta que se decida.

---

# 3. Progresión y Skills

Las skills son recuerdos que el protagonista puede conservar.

Ejemplos:

### Recuerdo del Corredor

Permite realizar un dash.

### Recuerdo del Guerrero

Ataque cuerpo a cuerpo más potente.

### Recuerdo del Pájaro

Doble salto.

### Recuerdo de la Puerta

Permite atravesar determinados obstáculos o espacios.

### Recuerdo del Refugio

Recuperación de Estabilidad más eficiente.

### Recuerdo del Otro

Permite interactuar con determinados recuerdos acompañado.

Las habilidades no deberían sentirse como una lista arbitraria de poderes.

Cada skill debe tener:

- origen
- significado
- personaje o recuerdo asociado
- función mecánica

---

# 4. Árbol de habilidades

Una dirección posible:

```text
                         MEMORIA
                            |
             +--------------+--------------+
             |              |              |
          ACEPTAR        CONECTAR       COMPRENDER
             |              |              |
         Resiliencia       Empatía       Percepción
             |              |              |
         Fortaleza         Apoyo         Distorsión
             |              |              |
       Supervivencia    Cooperación    Manipulación
```

## ACEPTAR

Orientado a:

- defensa
- resistencia
- recuperación
- combate directo
- estabilidad

## CONECTAR

Orientado a:

- aliados
- cooperación
- recuperación de Estabilidad
- habilidades combinadas
- apoyo

## COMPRENDER

Orientado a:

- percepción
- recuerdos
- ilusiones
- manipulación del entorno
- descubrimiento de caminos secretos

Estas ramas no necesitan ser presentadas al jugador como categorías psicológicas explícitas.

Pueden ser interpretadas a través de la historia.

---

# 5. Primer arco narrativo

El primer proyecto debe ser pequeño y terminable.

No construir el RPG completo.

## Proyecto 1 — El Recuerdo

Una pequeña zona.

El protagonista llega a un pueblo aparentemente abandonado.

Encuentra:

- un pequeño conjunto de plataformas
- 1–2 tipos de enemigos
- un objeto extraño
- una casa
- un recuerdo incompleto

### Gameplay

El jugador aprende:

- movimiento
- salto
- ataque
- daño
- vida
- enemigo
- animaciones
- estados

### Final

El protagonista encuentra una llave.

Al tocarla, aparece un recuerdo:

Una niña entrando en una casa.

Pero el recuerdo termina abruptamente.

---

# 6. Proyecto 2 — Vida, daño y conexión

Se agregan:

- HP
- HUD
- daño
- señales
- recuperación
- enemigos con vida
- interacción con NPCs

El protagonista conoce a una persona que recuerda a la niña.

Pero su recuerdo contradice parcialmente lo que mostró la llave.

El jugador descubre que **dos personas pueden recordar el mismo acontecimiento de formas diferentes.**

---

# 7. Proyecto 3 — El pueblo real y el primer recuerdo ajeno

(Actualizado 2026-09-17: reemplaza el diseño anterior de "mini dungeon en la cueva" — ver
`design/historia_lore.md` sección 13, "Qué sigue después de la expulsión". Ya no hay cueva ni
dungeon; el "dungeon" no es lo siguiente.)

## Parte A — El pueblo real (hub)

El jugador despierta de la expulsión de su propio recuerdo (Nivel 1) y puede explorar el
pueblo real por primera vez: caminar, hablar con NPCs reales, ir entendiendo la Fractura y el
lore de a poco a través de esas conversaciones. Es la primera vez que el jugador ve el mundo
sin el filtro del recuerdo — no hay combate ni dungeon acá todavía.

## Parte B — El primer recuerdo ajeno

En algún punto del pueblo real, el jugador encuentra el primer fragmento de recuerdo suelto
de otra persona y entra en él. Ese recuerdo se juega con un género distinto al plataformas
(sección 16, tabla de géneros candidatos) — el contraste plataformas-propio vs. género-nuevo-
ajeno es lo que le muestra al jugador que cada recuerdo tiene sus propias reglas, sin que
nadie lo explique con diálogo.

Pendiente de definir (ver `historia_lore.md` sección 15, Preguntas abiertas):

- qué género concreto tiene ese primer recuerdo ajeno
- quién es el NPC dueño de ese recuerdo
- si tiene una criatura/mini-boss como manifestación de lo evitado
- la skill de recompensa al resolverlo

Principio que se mantiene del diseño anterior: al resolver el recuerdo ajeno, el jugador no lo
"borra" — lo integra, y eso da una nueva habilidad (ejemplo previo: Recuerdo del Pájaro →
doble salto — sigue siendo válido como ejemplo de skill, aunque ya no está atado a un mini-boss
de cueva).

---

# 8. Primer mini-arco emocional

Una posible historia:

1. El protagonista llega al pueblo.
2. Descubre que sus habitantes olvidaron a una persona.
3. Encuentra objetos que parecen pertenecerle.
4. Los objetos contienen fragmentos de recuerdos.
5. Cada persona recuerda una versión diferente.
6. El protagonista descubre que todos están evitando hablar de lo ocurrido.
7. La casa de esa persona se ha convertido en una zona inestable.
8. Aparece una criatura formada por los recuerdos fragmentados.
9. El protagonista intenta enfrentarse a ella solo.
10. No puede estabilizar el recuerdo.
11. Un NPC decide acompañarlo.
12. Juntos pueden atravesarlo.
13. Descubren que no necesitan reconstruir cada detalle.
14. La persona olvidada finalmente vuelve a formar parte de la historia del pueblo.
15. El protagonista obtiene una nueva habilidad.
16. Pero descubre que, al recuperar ese recuerdo, él mismo olvidó algo personal.

Esto introduce desde temprano el conflicto principal.

---

# 9. Diseño de niveles

Los niveles pueden funcionar como pequeñas historias.

Estructura recomendada:

```text
Exploración
    ↓
Encuentro
    ↓
Pista
    ↓
Recuerdo
    ↓
Conflicto
    ↓
Combate
    ↓
Revelación
    ↓
Nueva habilidad
    ↓
Nueva forma de explorar el mundo
```

Esto conecta narrativa y metroidvania/progresión.

---

# 10. Arquitectura técnica futura en Godot

La historia también sirve como excusa para aprender arquitectura escalable.

## Primeros sistemas

- CharacterBody2D
- movimiento
- gravedad
- salto
- ataque
- enemigos
- colisiones
- AnimatedSprite2D / AnimationPlayer
- máquina de estados

Estados iniciales:

```text
IDLE
RUN
JUMP
FALL
ATTACK
HURT
DEAD
```

## Después

- Health component/system
- Damage events
- Signals
- HUD
- checkpoints
- interacción

## Posteriormente

Usar `Resource` para separar datos de lógica.

Ejemplos conceptuales:

```text
CharacterStats
SkillData
EnemyData
MemoryData
ItemData
```

Esto permitirá eventualmente:

- múltiples personajes
- múltiples skills
- diferentes builds
- enemigos configurables
- progresión RPG

---

# 11. Principio de diseño del proyecto

Cada proyecto de aprendizaje debe ser un juego pequeño y terminable.

## Proyecto 1

Platformer + combate.

## Proyecto 2

Vida + daño + HUD.

## Proyecto 3

Pueblo real (hub, NPCs, diálogo) + primer recuerdo ajeno en un género distinto (sección 7).

## Proyecto 4

RPG pequeño con:

- niveles
- árbol de skills
- estadísticas
- varios enemigos
- varios recuerdos
- NPCs
- narrativa ramificada limitada

## Proyecto 5+

Escalar únicamente si sigue siendo divertido.

No intentar construir desde el principio:

- mundo abierto
- 20 personajes
- 100 skills
- inventario gigantesco
- crafting
- procedural generation
- cientos de enemigos
- diálogos infinitos

El objetivo inicial es terminar juegos.

---

# 12. Regla de oro narrativa

Cada sistema importante debería responder dos preguntas:

### ¿Qué hace?

Función jugable.

### ¿Qué significa?

Función narrativa/emocional.

Ejemplo:

**Estabilidad**

- Mecánica: recurso para habilidades.
- Narrativa: capacidad de permanecer conectado con el presente.

**Recuerdos**

- Mecánica: desbloquean skills.
- Narrativa: experiencias que forman nuestra identidad.

**Aliados**

- Mecánica: nuevas capacidades y recuperación.
- Narrativa: conexión y apoyo.

**Enemigos**

- Mecánica: obstáculos y combate.
- Narrativa: historias fragmentadas y dolor no procesado.

**Progresión**

- Mecánica: más poder.
- Narrativa: aprender nuevas maneras de relacionarse con el pasado.

---

# 13. Objetivo creativo

El objetivo no es hacer un RPG gigantesco.

Es construir un juego pequeño que tenga:

- una identidad propia
- mecánicas coherentes con su mundo
- misterio
- personajes memorables
- progresión satisfactoria
- una metáfora emocional que no necesite explicarse constantemente

La ambición inicial debe ser:

> **Que el jugador termine una pequeña historia y se quede pensando en ella después de apagar el juego.**

---

# 14. Semillas de diferenciación (evitación / soledad / conexión)

Notas para no repetir el tono genérico de "walking sim melancólico" (GRIS, Spiritfarer,
Sea of Solitude). No desarrollar todavía — son semillas para cuando haya base técnica.

## Evitación como verbo jugable (sembrar en Proyecto 1)

Enemigos que se fortalecen si se los enfrenta de frente y se debilitan si se los rodea,
se los ignora un rato, o se los atrae a otra zona. Combate por elusión, no solo por daño.

- Mecánica: el enemigo tiene un estado que escala con confrontación directa sostenida.
- Significado: la evitación no se "resuelve" atacando de frente — a veces hay que rodear
  el problema y volver después.
- Costo técnico: bajo (una máquina de estados simple), compatible con lo que ya hay que
  aprender en el Proyecto 1.

## Soledad como ritmo ambiental (Proyecto 3+)

En vez de una barra de "conexión" visible, un reloj social ambiental: pasar mucho tiempo
sin interactuar con un NPC/aliado altera despacio cámara/sonido/color, sin número explícito.

- Significado: la soledad no avisa con una alarma, se filtra de a poco.

## Conexión con costo real (Proyecto 3+)

Llevar a un aliado a un recuerdo ajeno también lo afecta a él (le cuesta Estabilidad, o
recuerda algo que no quería). Elegís a quién llevás, no solo si llevás compañía.

- Significado: pedir ayuda no es gratis para el otro — la conexión implica reciprocidad.

## Humor como evitación válida (Proyecto 3+/4)

NPC que deflecta con chistes cerca de temas incómodos. El juego no lo obliga a "abrirse"
para tener valor narrativo — el humor como mecanismo de afrontamiento se trata como
legítimo, no como máscara a romper. Reconcilia el tono de comedia original con el tema.

---

# 15. Progresión visual/sonora del Nivel 1 (crecimiento, no un proyecto aparte)

Decisión de diseño (2026-09): esto **no es "Proyecto 1.5" como paso separado**, sino que el
Nivel 1 ("El Recuerdo") va sumando fidelidad visual y sonora sobre la marcha, usando los
mismos disparadores que ya existen (los 4 recuerdos + el momento de la Estabilidad + la
entrada de la cueva). Nadie construye un nivel nuevo: el nivel actual crece con él.

## Principio

El mundo se vuelve más nítido/vivo en la misma medida en que el protagonista recupera su
identidad. No es una progresión técnica de "arte mejor porque sí" — es la sección 12
(la Regla de oro) aplicada a la dirección de arte: cada salto de fidelidad visual también
significa algo.

## Orden de progresión propuesto (6 etapas, reusando triggers existentes)

1. **Estado inicial (sin recuerdos)** — mundo casi en blanco y negro/desaturado, solo el
   viento de fondo. Es el estado actual del nivel (rectángulos planos), no hace falta tocar
   nada para esta etapa.
2. **Recuerdo del Saltador** — la zona inmediata alrededor del jugador recupera un primer
   parche de color/detalle (no todo el nivel todavía). Empieza un hum ambiental muy tenue.
3. **Estabilidad (momento del pecho agitado)** — a propósito NO es un cambio de color del
   mundo, sino algo corporal/de cámara (viñeta, un pulso sutil) — distingue lo interno
   (el cuerpo del protagonista) de lo externo (el mundo).
4. **Recuerdo del Corredor** — aparece por primera vez el fondo de parallax (siluetas
   lejanas, hasta ahora vacío). "El movimiento le devolvió el horizonte."
5. **Recuerdo de Vida** — acá sí, el color/detalle se vuelve la norma de ahí en adelante
   (no un parche, todo el resto del nivel). Empiezan a aparecer objetos de fondo sin función
   jugable (banco, cartel, algo abandonado).
6. **Recuerdo del Guerrero** — se suma una capa musical simple (ya no solo ambiente).
7. **Entrada de la cueva** — nivel visualmente completo, pero la cueva en sí queda oscura/
   en silueta a propósito. (Actualizado 2026-09-17: este punto ya no es la entrada a un
   dungeon — es donde arranca la secuencia de expulsión de vuelta al mundo real, sección 7.
   La oscuridad sigue siendo el contraste deliberado, ahora enganchando con esa expulsión en
   vez de con un misterio de cueva.)

## Viabilidad técnica (respuesta a "¿se puede mezclar en la misma escena?")

Sí, sin ninguna transición forzada — todo esto vive en **una sola** `Main.tscn`, igual que
ahora. No hace falta separar "mundo viejo" y "mundo nuevo" en escenas distintas. Piezas:

- **Color/saturación global**: un `CanvasModulate` (o un overlay a pantalla completa en el
  HUD) que main.gd ajusta en cada `ability_unlocked` — no requiere tocar ni un solo nodo de
  la geometría del nivel.
- **Parallax**: un `ParallaxBackground`/`ParallaxLayer` que ya existe en la escena desde el
  principio, solo con `visible = false` hasta el Recuerdo del Corredor.
- **Detalle del piso (rectángulos → `TileMapLayer`)**: esto es **independiente** de la
  progresión de color — se puede hacer en cualquier momento, incluso después, sin esperar
  a este sistema. El cambio de art del suelo y el cambio de saturación/parallax no están
  atados entre sí técnicamente, aunque narrativamente se sientan parte de la misma idea.
- **Audio**: dos `AudioStreamPlayer` (ambiente y música) con `volume_db` que main.gd sube
  gradualmente en los mismos callbacks que ya conectan las señales de habilidad.

Nada de esto exige rehacer la arquitectura actual (señales + `main.gd` como coordinador) —
son consumidores nuevos de las mismas señales que ya emite `player.gd`.

## Fuera de alcance por ahora

Todavía no se construye nada de esto — queda anotado para cuando el Nivel 1 esté
jugativamente cerrado y sea momento de la pasada de pulido visual/sonoro.

## Actualización (2026-09): Nivel 1 extendido antes de esta pasada visual

Se agregó un tramo de más desafío después del Recuerdo del Guerrero, todavía sin tocar nada
de arte: un gauntlet de 3 enemigos (uno más rápido, mismo `enemy.gd` con `speed`/
`patrol_distance` ahora exportados en vez de fijos), y una bifurcación **opcional** — un
tramo de parkour vertical (sprint+salto obligatorio, no un salto cualquiera) que termina en
un enemigo "elite" (más vida) y una recompensa permanente: +10% de Estabilidad máxima, con
un mensaje de cierre que premia explícitamente desviarse a explorar en vez de solo correr al
objetivo. La pasada visual de arriba sigue pendiente, ahora sobre este nivel ya más largo.

## Actualización (2026-09): reconstrucción por actos + migración a TileMapLayer

Se rehizo el Nivel 1 completo como un nivel largo por actos (uno por recuerdo: Saltador,
Corredor, Vida, Guerrero, más un acto de llegada y uno de cierre en la cueva), cada uno con
desafíos que exigen la habilidad recién obtenida y un desafío final que la combina con la
anterior. La geometría dejó de ser rectángulos de color a mano: ahora es un mapa ASCII
(`game/levels/level1.txt`) que un loader convierte en `TileMapLayer` (tiles de Kenney) +
colisiones — es decir, el ítem de TileMapLayer de la sección de abajo **ya se hizo**, antes
de la pasada de color/parallax/audio (quedó desacoplado de esa pasada, tal como se preveía).

Dos cambios respecto al diseño original de esta sección:

- **La bifurcación opcional (Mirador) se movió de después del Corredor a después del
  Guerrero.** Con el orden viejo, el enemigo "elite" de la recompensa se enfrentaba sin poder
  atacar todavía (solo evitación); ahora el jugador ya tiene el Recuerdo del Guerrero al
  llegar, así que la pelea es real en vez de un obstáculo que solo se puede esquivar.
- Se sumaron tres comportamientos de enemigo nuevos (`enemy.gd`: `PATROL`/`GUARD`/`CHASE`) que
  antes no existían: un **guardián** que bloquea un pasillo sin salida posible por arriba (hay
  que matarlo), un **perseguidor** que no se puede matar y obliga a usar el Recuerdo del
  Corredor para escapar, y **restos** (varios, chicos, de 1 golpe, rápidos). Esto le da a cada
  habilidad un desafío que de verdad la necesita, no solo enemigos intercambiables por stats.

La pasada de color/parallax/audio de esta sección ya está implementada: ver
`game/scripts/world_progression.gd`, `game/shaders/world_tint.gdshader` y
`game/scripts/audio_layers.gd`. Sus valores numéricos siguen pendientes de ajuste jugando
(issue "Ajustar color, viñeta y volúmenes").


---

# 16. Género variable: un lore, muchas formas de jugarlo

Decisión (2026-09-13): el proyecto no se ata a un género. Lo fijo es el tono, la premisa,
la Estabilidad, los recuerdos como habilidades y los personajes. Cada capítulo/proyecto
puede cambiar de género, porque el objetivo es aprender y porque el lore lo permite.

## Justificación narrativa de los saltos de género

> Desarrollo completo en `design/historia_lore.md` → "Cómo se unen la capa interior y la
> exterior". Resumen: **cada recuerdo se juega con las reglas de quien lo recordaba** —
> los recuerdos no son archivos perfectos (`historia_lore.md` → "La Fractura — premisa del
> mundo"), tampoco tienen por qué tener la misma "física".

Refuerzos diegéticos posibles:
- El cambio de reglas se **ve**: el shader de tinte ya existe; al cruzar el umbral de un
  recuerdo el mundo se desatura, cambia la cámara y "vuelve" con otras reglas.
- Un NPC lo nombra sin explicarlo: "Cada uno guarda las cosas a su manera. No esperes que
  lo suyo se parezca a lo tuyo."
- La Estabilidad es el hilo común: cualquiera sea el género, gastarla y recuperarla
  funciona igual y se ve igual en el HUD. Es lo que le dice al jugador "seguís siendo vos".
- Opcional, más adelante: el protagonista **aprende** la forma de recordar del otro y se la
  lleva (una skill "de género": después del primer recuerdo ajeno puede "ver desde arriba" en cualquier
  lugar, lo que abre rutas nuevas en niveles viejos; metroidvania de géneros).

## Géneros candidatos y qué parte del lore sostienen

| Género | Qué del lore lo sostiene | Mecánica puente | Para aprender |
|---|---|---|---|
| Cenital con luz (linterna/antorcha) | Lo que alguien no quiso mirar (candidato para el primer recuerdo ajeno, sección 7) | La luz gasta Estabilidad; a oscuras aparecen cosas (sección 1, percepción alterada) | Navegación 2D top-down, luces 2D, niebla |
| Turnos (JRPG/táctico) | Enemigos como recuerdos; "huir" como acción legítima (evitación) | Estabilidad = MP; "Evitar" es una acción que a veces es la correcta | Máquinas de estado, UI de combate, datos en `.tres` |
| Cartas / deck-building | "¿Cuántas historias podés cargar antes de olvidar la tuya?" | Cada carta es un fragmento de recuerdo ajeno; cargar muchas diluye tus cartas propias | Resources, sistemas data-driven, balance |
| Investigación / point & click | `historia_lore.md` → "Sistema de recuerdos": fragmento, contradicción, nueva perspectiva | Reconstruir un recuerdo con testimonios que se contradicen; no hay "versión correcta" | Diálogo, inventario, estado narrativo |
| Ritmo | "Una canción que nadie consigue terminar" (`historia_lore.md` → "La Fractura", literal) | Completar la canción = recuperar el recuerdo; fallar no castiga, distorsiona | Sincronía audio/juego, timing |
| Puzzle de perspectiva | `historia_lore.md` → "Estética — el porqué": perspectivas imposibles, arquitectura que no encaja | El nivel se resuelve cambiando cómo lo mirás | Cámaras, transformaciones, diseño de puzzles |
| Roguelike corto | La casa inestable, fragmentación | Cada intento reordena las salas; lo que "aceptaste" se queda fijo entre intentos | Generación procedural acotada, persistencia |
| Sigilo | `historia_lore.md` → "Enemigos como recuerdos incompletos": criaturas de evitación que huyen y persiguen | Vos también evitás; a veces esconderse es lo correcto | IA de percepción, cono de visión |
| Aventura de texto | Recuerdos donde solo quedaron palabras | Parser mínimo dentro de un recuerdo destruido | Texto, estado, escritura |
| Social / gestión (pueblo) | "Nadie se salva solo"; reconstruir vínculos | Conexión como recurso (sección 2); ayudar cuesta al que ayuda (sección 14) | Simulación, tiempo, relaciones |

## Reglas para que el salto de género no rompa el proyecto

1. **Núcleo compartido primero.** Estabilidad, recuerdos, HUD, cola de mensajes, audio por
   capas y el shader de tinte son escenas/scripts reusables. Cada género los importa, no
   los reescribe. Esto es la tarea 2 de `CLAUDE.md`.
2. **Un género por proyecto, chico y terminable** (sección 11). No mezclar dos géneros en el
   mismo capítulo hasta tener dos capítulos terminados.
3. **El cambio de género es un momento de la historia**, no un menú: siempre hay un umbral
   (una puerta, un objeto, un NPC) y siempre se ve en pantalla.
4. **Lo que el jugador ya sabe se respeta.** Las mismas teclas para lo mismo (interact,
   cancel), el mismo HUD, los mismos textos de recuerdo.
5. Si un género no engancha en dos semanas, se cierra chico y se pasa al siguiente. El
   objetivo es aprender, y un capítulo corto también cuenta la historia.

## Para el primer recuerdo ajeno (Proyecto 3), sugerencia sin cerrar

(Ya no hay cueva — ver sección 7. Esto queda como candidato, no como decisión.)

Cenital con luz sigue siendo un salto natural desde el plataformas (mismos sprites, misma
Estabilidad; enseña luces 2D y navegación top-down), y "lo que alguien no quiso mirar" puede
pedir oscuridad literal sin necesitar una cueva física — puede ser cualquier recuerdo ajeno
oscuro. La linterna que gasta Estabilidad conectaría directo con la sección 1: a oscuras (baja
Estabilidad) se ven cosas que con luz no. Pendiente confirmar si este es el género del primer
recuerdo ajeno o si conviene otro de la tabla (`historia_lore.md` sección 15).
