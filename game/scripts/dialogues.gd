class_name Dialogues
extends RefCounted
# Lo que dicen los NPCs y lo que pasa con los objetos del guion según el estado
# (GameState: beats, objetos que se llevan encima). Cada NPC u objeto nombra su
# diálogo en sus datos; `run` devuelve false si no hay nada especial y el NPC
# dice sus líneas de siempre. Los textos son provisorios (#54).

const KEYS := &"llaves_de_tomas"
const BUCKET := &"balde_de_agua"

const TOMAS_BARKS_AFTER := ["Mm.", "Buen día... creo.", "Hoy no perdí nada. Todavía."]

static func run(id: StringName, speaker: Node2D, _player: Node2D) -> bool:
	match id:
		&"tomas":
			return _tomas(speaker)
		&"posadera":
			return _posadera()
		&"marta":
			return _marta()
		&"llaves":
			return _keys(speaker)
		&"pozo":
			return _well()
	push_error("Dialogues: no hay diálogo '%s'." % id)
	return false

# Los ladridos que cambian con lo que ya pasó (Tomás deja de buscar sus llaves).
static func barks(id: StringName, default: PackedStringArray) -> PackedStringArray:
	if id == &"tomas" and GameState.is_beat_done("tomas_keys"):
		return PackedStringArray(TOMAS_BARKS_AFTER)
	return default

static func _say(lines: Array) -> void:
	for line in lines:
		Events.message_requested.emit(line)

# Alivio: devolverle a Tomás algo que perdió.
static func _tomas(tomas: Node2D) -> bool:
	if GameState.has_item(KEYS):
		GameState.remove_item(KEYS)
		GameState.complete_beat("tomas_keys")
		tomas.barks = PackedStringArray(TOMAS_BARKS_AFTER)
		_say([
			"Tomás: ¿Esas son...? ¡Mis llaves! Las busqué toda la mañana.",
			"Tomás: Gracias. De verdad. Hace mucho que nadie me devolvía nada.",
		])
		return true
	if GameState.is_beat_done("tomas_keys"):
		_say([
			"Tomás: Hoy no perdí nada. Bueno, todavía no.",
			"Tomás: Yo ya no pregunto. Pero lo de las llaves... gracias.",
		])
		return true
	return false

# Alivio: el agua que la posadera no puede ir a buscar. Madurar: aceptar el
# caldo aunque no tenga con qué pagarlo (rechazarlo no cuesta nada: se puede
# aceptar después).
static func _posadera() -> bool:
	if GameState.has_item(BUCKET):
		GameState.remove_item(BUCKET)
		GameState.complete_beat("inn_water")
		_say(["Posadera: ¿Me trajiste agua? ¡Ay, gracias! No podía dejar el mostrador solo."])
		return true
	if not GameState.is_beat_done("broth"):
		Events.choice_requested.emit("Posadera: Tengo caldo recién hecho. ¿Te sirvo un plato?",
				PackedStringArray(["Sí, gracias", "No tengo con qué pagar"]), _on_broth_chosen)
		return true
	if not GameState.is_beat_done("inn_water"):
		_ask_for_water()
		return true
	return false

static func _on_broth_chosen(index: int) -> void:
	if index == 0:
		GameState.complete_beat("broth")
		_say(["Posadera: Tomá. Despacio, que quema."])
	else:
		_say(["Posadera: ¿Y quién te habló de pagar? Bueno... la olla no se va a ningún lado."])
	if not GameState.is_beat_done("inn_water"):
		_ask_for_water()

static func _ask_for_water() -> void:
	_say(["Posadera: Si salís, ¿me traerías un balde del pozo? No puedo dejar el mostrador."])

# Madurar: dejar que te vean. "Estoy bien" no castiga: solo deja el beat pendiente.
static func _marta() -> bool:
	if GameState.is_beat_done("dont_know_who_i_am"):
		return false
	Events.choice_requested.emit("Marta: ¿Cómo estás? Pero de verdad.",
			PackedStringArray(["Estoy bien", "No sé quién soy"]), _on_marta_chosen)
	return true

static func _on_marta_chosen(index: int) -> void:
	if index == 1:
		GameState.complete_beat("dont_know_who_i_am")
		_say([
			"Marta: ...",
			"Marta: Gracias por decírmelo. No tenés que saberlo hoy. Lo vamos a ir viendo.",
		])
	else:
		_say(["Marta: Mm. Bueno. Si cambia, acá estoy."])

static func _keys(keys: Node2D) -> bool:
	GameState.add_item(KEYS)
	_say(["Unas llaves en el suelo, de las viejas, con un cordón gastado. Alguien las debe estar buscando."])
	keys.queue_free()
	return true

static func _well() -> bool:
	if GameState.has_item(BUCKET):
		_say(["Ya tengo el balde lleno."])
	elif not GameState.is_beat_done("inn_water"):
		GameState.add_item(BUCKET)
		_say(["Lleno el balde en el pozo. El agua sale fría y huele a piedra."])
	else:
		_say(["El pozo. El agua está lejos, allá abajo."])
	return true
