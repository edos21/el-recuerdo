class_name Dialogues
extends RefCounted
# Lo que dicen los NPCs y lo que pasa con los objetos del guion según el estado
# (GameState: beats, objetos que se llevan encima). Cada NPC u objeto nombra su
# diálogo en sus datos; `run` devuelve false si no hay nada especial y el NPC
# dice sus líneas de siempre. No toca al NPC: lo que cambia se lee del estado
# (barks). Cada personaje tiene su script en `dialogues/`, con los objetos de
# sus beats: así el elenco crece sin un único `match` gigante.

const TOMAS := preload("res://scripts/dialogues/tomas.gd")
const MARTA := preload("res://scripts/dialogues/marta.gd")
const POSADERA := preload("res://scripts/dialogues/posadera.gd")

const KEYS := &"llaves_de_tomas"
const BUCKET := &"balde_de_agua"
# Ids de los recuerdos que una entrega deja pendientes (GameState.lock_memory).
const MEMORY_TOMAS_STORE := &"tomas_store"

# El recuerdo de Tomás se puede pedir una noche después de las llaves y una noche
# después de recibir el libro de huéspedes (en cualquier orden). Es la condición
# del disparo; lo que se sume (los recados de orientación) se agrega acá.
static func tomas_memory_ready() -> bool:
	return GameState.is_memory_ready(MEMORY_TOMAS_STORE) and GameState.is_met({"slept_since": BeatData.GUEST_BOOK})

static func run(id: StringName, speaker: Node2D) -> bool:
	match id:
		&"tomas":
			return TOMAS.run()
		&"llaves":
			return TOMAS.pick_up_keys(speaker as StoryObject)
		&"posadera":
			return POSADERA.run()
		&"pozo":
			return POSADERA.use_well()
		&"silla":
			return POSADERA.look_at_chair()
		&"libro":
			return POSADERA.look_at_book()
		&"marta":
			return MARTA.run()
	push_error("Dialogues: no hay diálogo '%s'." % id)
	return false

# Los comentarios al pasar según lo que ya pasó (Tomás deja de buscar sus llaves).
static func barks(id: StringName, default: PackedStringArray) -> PackedStringArray:
	if id == &"tomas":
		return TOMAS.barks(default)
	return default

# Saca de la escena el objeto del guion con ese diálogo, para lo que un NPC le
# da al protagonista desde otro lado (el libro del mostrador).
static func vanish_object(id: StringName) -> void:
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group(StoryObject.GROUP):
		var story_object := node as StoryObject
		if story_object.dialogue == id:
			story_object.vanish()

# Como los NPCs: el nombre de quien habla solo en la primera línea.
static func say(speaker_name: String, lines: Array) -> void:
	for i in lines.size():
		var text: String = lines[i]
		if i == 0 and speaker_name != "":
			text = "%s: %s" % [speaker_name, text]
		Events.message_requested.emit(text)

static func ask(speaker_name: String, prompt: String, options: Array, on_chosen: Callable) -> void:
	Events.choice_requested.emit("%s: %s" % [speaker_name, prompt], PackedStringArray(options), on_chosen)
