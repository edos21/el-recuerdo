extends RefCounted
# La posadera. Alivio: el agua que no puede ir a buscar. Madurar:
# aceptar el caldo aunque no tenga con qué pagarlo (rechazarlo no cuesta nada:
# se puede aceptar después).

static func run() -> bool:
	if GameState.has_item(Dialogues.BUCKET):
		GameState.remove_item(Dialogues.BUCKET)
		GameState.complete_beat(BeatData.INN_WATER)
		Dialogues.say(TownNpcData.POSADERA_NAME, ["¿Me trajiste agua? ¡Ay, gracias! No podía dejar el mostrador solo."])
		return true
	if not GameState.is_beat_done(BeatData.BROTH):
		Dialogues.ask(TownNpcData.POSADERA_NAME, "Tengo caldo recién hecho. ¿Te sirvo un plato?",
				["Sí, gracias", "No tengo con qué pagar"], _on_broth_chosen)
		return true
	if not GameState.is_beat_done(BeatData.INN_WATER):
		_ask_for_water()
		return true
	return false

static func use_well() -> bool:
	if GameState.has_item(Dialogues.BUCKET):
		Dialogues.say("", ["Ya tengo el balde lleno."])
	elif not GameState.is_beat_done(BeatData.INN_WATER):
		GameState.add_item(Dialogues.BUCKET)
		Dialogues.say("", ["Lleno el balde en el pozo. El agua sale fría y huele a piedra."])
	else:
		Dialogues.say("", ["El pozo. El agua está lejos, allí abajo."])
	return true

static func _on_broth_chosen(index: int) -> void:
	if index == 0:
		GameState.complete_beat(BeatData.BROTH)
		Dialogues.say(TownNpcData.POSADERA_NAME, ["Toma. Despacio, que quema."])
	else:
		Dialogues.say(TownNpcData.POSADERA_NAME, ["¿Y quién te habló de pagar? Bueno... la olla no se va a ningún lado."])
	if not GameState.is_beat_done(BeatData.INN_WATER):
		_ask_for_water()

static func _ask_for_water() -> void:
	Dialogues.say(TownNpcData.POSADERA_NAME, ["Si sales, ¿me traerías un balde del pozo? No puedo dejar el mostrador."])
