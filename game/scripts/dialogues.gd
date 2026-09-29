class_name Dialogues
extends RefCounted
# Lo que dicen los NPCs y lo que pasa con los objetos del guion según el estado
# (GameState: beats, objetos que se llevan encima). Cada NPC u objeto nombra su
# diálogo en sus datos; `run` devuelve false si no hay nada especial y el NPC
# dice sus líneas de siempre. No toca al NPC: lo que cambia se lee del estado
# (barks). Los textos son provisorios (#54).

const KEYS := &"llaves_de_tomas"
const BUCKET := &"balde_de_agua"

const TOMAS_BARKS_AFTER := ["Mm.", "Buen día... creo.", "Hoy no perdí nada. Todavía."]

static func run(id: StringName, speaker: Node2D) -> bool:
	match id:
		&"tomas":
			return _tomas()
		&"posadera":
			return _posadera()
		&"marta":
			return _marta()
		&"llaves":
			return _keys(speaker as StoryObject)
		&"pozo":
			return _well()
	push_error("Dialogues: no hay diálogo '%s'." % id)
	return false

# Los comentarios al pasar según lo que ya pasó (Tomás deja de buscar sus llaves).
static func barks(id: StringName, default: PackedStringArray) -> PackedStringArray:
	if id == &"tomas" and GameState.is_beat_done(BeatData.TOMAS_KEYS):
		return PackedStringArray(TOMAS_BARKS_AFTER)
	return default

# Como los NPCs: el nombre de quien habla solo en la primera línea.
static func _say(speaker_name: String, lines: Array) -> void:
	for i in lines.size():
		var text: String = lines[i]
		if i == 0 and speaker_name != "":
			text = "%s: %s" % [speaker_name, text]
		Events.message_requested.emit(text)

static func _ask(speaker_name: String, prompt: String, options: Array, on_chosen: Callable) -> void:
	Events.choice_requested.emit("%s: %s" % [speaker_name, prompt], PackedStringArray(options), on_chosen)

# Alivio: devolverle a Tomás algo que perdió.
static func _tomas() -> bool:
	if GameState.has_item(KEYS):
		GameState.remove_item(KEYS)
		GameState.complete_beat(BeatData.TOMAS_KEYS)
		_say(TownNpcData.TOMAS_NAME, [
			"¿Esas son...? ¡Mis llaves! Las busqué toda la mañana.",
			"Gracias. De verdad. Hace mucho que nadie me devolvía nada.",
		])
		return true
	if GameState.is_beat_done(BeatData.TOMAS_KEYS):
		_say(TownNpcData.TOMAS_NAME, [
			"Hoy no perdí nada. Bueno, todavía no.",
			"Yo ya no pregunto. Pero lo de las llaves... gracias.",
		])
		return true
	return false

# Alivio: el agua que la posadera no puede ir a buscar. Madurar: aceptar el
# caldo aunque no tenga con qué pagarlo (rechazarlo no cuesta nada: se puede
# aceptar después).
static func _posadera() -> bool:
	if GameState.has_item(BUCKET):
		GameState.remove_item(BUCKET)
		GameState.complete_beat(BeatData.INN_WATER)
		_say(TownNpcData.POSADERA_NAME, ["¿Me trajiste agua? ¡Ay, gracias! No podía dejar el mostrador solo."])
		return true
	if not GameState.is_beat_done(BeatData.BROTH):
		_ask(TownNpcData.POSADERA_NAME, "Tengo caldo recién hecho. ¿Te sirvo un plato?",
				["Sí, gracias", "No tengo con qué pagar"], _on_broth_chosen)
		return true
	if not GameState.is_beat_done(BeatData.INN_WATER):
		_ask_for_water()
		return true
	return false

static func _on_broth_chosen(index: int) -> void:
	if index == 0:
		GameState.complete_beat(BeatData.BROTH)
		_say(TownNpcData.POSADERA_NAME, ["Tomá. Despacio, que quema."])
	else:
		_say(TownNpcData.POSADERA_NAME, ["¿Y quién te habló de pagar? Bueno... la olla no se va a ningún lado."])
	if not GameState.is_beat_done(BeatData.INN_WATER):
		_ask_for_water()

static func _ask_for_water() -> void:
	_say(TownNpcData.POSADERA_NAME, ["Si salís, ¿me traerías un balde del pozo? No puedo dejar el mostrador."])

# Madurar: dejar que te vean. "Estoy bien" no castiga: solo deja el beat pendiente.
static func _marta() -> bool:
	if GameState.is_beat_done(BeatData.DONT_KNOW):
		return false
	_ask(TownNpcData.MARTA_NAME, "¿Cómo estás? Pero de verdad.", ["Estoy bien", "No sé quién soy"], _on_marta_chosen)
	return true

static func _on_marta_chosen(index: int) -> void:
	if index == 1:
		GameState.complete_beat(BeatData.DONT_KNOW)
		_say(TownNpcData.MARTA_NAME, [
			"...",
			"Gracias por decírmelo. No tenés que saberlo hoy. Lo vamos a ir viendo.",
		])
	else:
		_say(TownNpcData.MARTA_NAME, ["Mm. Bueno. Si cambia, acá estoy."])

static func _keys(keys: StoryObject) -> bool:
	GameState.add_item(KEYS)
	_say("", ["Unas llaves en el suelo, de las viejas, con un cordón gastado. Alguien las debe estar buscando."])
	keys.vanish()
	return true

static func _well() -> bool:
	if GameState.has_item(BUCKET):
		_say("", ["Ya tengo el balde lleno."])
	elif not GameState.is_beat_done(BeatData.INN_WATER):
		GameState.add_item(BUCKET)
		_say("", ["Lleno el balde en el pozo. El agua sale fría y huele a piedra."])
	else:
		_say("", ["El pozo. El agua está lejos, allá abajo."])
	return true
