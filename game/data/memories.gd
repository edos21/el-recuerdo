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
# El orden de `entries` importa: es el de los slots del HUD.

enum Kind { INNATE, MEMORY, OPTIONAL, LATER }
const NO_FADE := -1.0

@export var entries: Array[MemoryDef] = []

var _by_id: Dictionary[String, MemoryDef] = {}
var _by_pickup_char: Dictionary[String, String] = {}

func entry(ability: String) -> MemoryDef:
	return _by_id.get(ability)

func has(ability: String) -> bool:
	return _by_id.has(ability)

func abilities_of(kinds: Array) -> Array[String]:
	var result: Array[String] = []
	for memory in entries:
		if kinds.has(memory.kind):
			result.append(memory.id)
	return result

func memory_count() -> int:
	return abilities_of([Kind.MEMORY]).size()

# Índice inverso para level_loader.gd: qué habilidad corresponde al dígito
# del mapa ASCII. "" si ninguna entrada tiene ese carácter (mapa mal armado).
func by_pickup_char(ch: String) -> String:
	return _by_pickup_char.get(ch, "")

# Lo llama Catalogs al arrancar; se puede repetir (load() devuelve la misma
# instancia cacheada del .tres). Un dato mal cargado en el inspector
# se avisa ahí, en vez de dejar una habilidad sin ícono o un recuerdo
# imposible de recoger en silencio.
func index() -> void:
	_by_id.clear()
	_by_pickup_char.clear()
	for memory in entries:
		if memory.id == "" or _by_id.has(memory.id):
			push_error("MemoryData: id vacío o repetido ('%s')." % memory.id)
			continue
		_by_id[memory.id] = memory
		if memory.kind in [Kind.MEMORY, Kind.OPTIONAL]:
			if memory.icon == null or not memory.has_pickup():
				push_error("MemoryData: '%s' necesita ícono y carácter de mapa." % memory.id)
		if memory.has_pickup():
			if _by_pickup_char.has(memory.pickup_char):
				push_error("MemoryData: carácter de mapa repetido '%s'." % memory.pickup_char)
			_by_pickup_char[memory.pickup_char] = memory.id
