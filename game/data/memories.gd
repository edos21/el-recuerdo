class_name MemoryData
extends Resource
# Fuente única de las habilidades del protagonista. Antes esta lista estaba
# repartida entre GameState, hud.gd, player.gd y world_progression.gd: agregar
# una habilidad implicaba tocar los cinco archivos. Ahora cada habilidad es
# una sola entrada (MemoryDef) de data/memories.tres, que se edita en el
# inspector: ajustar el balance no toca código. level_loader.gd instancia el
# objeto del Nivel 1 leyendo el carácter '1'..'5' del mapa ASCII vía
# `by_pickup_char` (el ASCII solo dice "acá va el recuerdo N", el contenido
# vive acá).
#
# `kind` decide cómo la trata el HUD:
# - INNATE: sin ícono ni slot (la Estabilidad se descubre por agotamiento).
# - MEMORY: slot apagado desde el inicio, cuenta en "Recuerdos X/N".
# - OPTIONAL: slot que aparece recién al ganarlo, no cuenta (el bonus del
#   camino secundario).
# - LATER: se gana fuera del Nivel 1 (en un capítulo que todavía no existe):
#   no cuenta en el Nivel 1 ni lo otorga `granted_by_default` (el pueblo no lo
#   trae de regalo). Solo debug_start_at_end lo da, para poder probarlo.
#
# `fades_at` es el ratio de Estabilidad en el que la expulsión apaga el
# recuerdo (en orden inverso al que se ganaron); `NO_FADE` para lo que nunca
# se apaga.
#
# El orden de `memories` importa: es el de los slots del HUD.

enum Kind { INNATE, MEMORY, OPTIONAL, LATER }
const NO_FADE := -1.0

@export var memories: Array[MemoryDef] = []

var _by_id: Dictionary[String, MemoryDef] = {}

static func entry(ability: String) -> MemoryDef:
	return _loaded()._by_id.get(ability)

static func has(ability: String) -> bool:
	return _loaded()._by_id.has(ability)

static func abilities_of(kinds: Array) -> Array[String]:
	var result: Array[String] = []
	for memory in _loaded().memories:
		if kinds.has(memory.kind):
			result.append(memory.id)
	return result

static func memory_count() -> int:
	return abilities_of([Kind.MEMORY]).size()

# Índice inverso para level_loader.gd: qué habilidad corresponde al dígito
# del mapa ASCII. "" si ninguna entrada tiene ese carácter (mapa mal armado).
static func by_pickup_char(ch: String) -> String:
	for memory in _loaded().memories:
		if memory.pickup_char == ch:
			return memory.id
	return ""

# El catálogo cargado (ver Catalogs), indexado la primera vez que se lo pide.
static func _loaded() -> MemoryData:
	var catalog := Catalogs.memories
	if catalog._by_id.is_empty():
		catalog._index()
	return catalog

# Un dato mal cargado en el inspector se avisa al arrancar, en vez de dejar
# una habilidad sin ícono o un recuerdo imposible de recoger en silencio.
func _index() -> void:
	var chars: Array[String] = []
	for memory in memories:
		if memory.id == "" or _by_id.has(memory.id):
			push_error("MemoryData: id vacío o repetido ('%s')." % memory.id)
			continue
		_by_id[memory.id] = memory
		if memory.kind in [Kind.MEMORY, Kind.OPTIONAL]:
			if memory.icon == null or not memory.has_pickup():
				push_error("MemoryData: '%s' necesita ícono y carácter de mapa." % memory.id)
		if memory.has_pickup():
			if chars.has(memory.pickup_char):
				push_error("MemoryData: carácter de mapa repetido '%s'." % memory.pickup_char)
			chars.append(memory.pickup_char)
