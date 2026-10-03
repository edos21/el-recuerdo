extends RefCounted
# Doña Flor, la posadera. Cadena de tres: alivio con el agua que no puede ir a
# buscar, madurar al aceptar el caldo aunque no tenga con qué pagarlo, y madurar
# otra vez al recibir el libro de huéspedes, un regalo que no puede devolver.
# Rechazar el caldo no cuesta nada: se puede aceptar después, y el libro espera.

const GUEST_BOOK_HINT := "Un libro de registro para anotar lo que pasa. Con Esc se abre."

static func run() -> bool:
	if GameState.has_item(Dialogues.BUCKET):
		GameState.remove_item(Dialogues.BUCKET)
		GameState.complete_beat(BeatData.INN_WATER)
		Dialogues.say(TownNpcData.POSADERA_NAME, [
			"¿Me trajiste agua? ¡Ay, gracias! No podía dejar el mostrador solo.",
			"¿Sabes para qué más sirve un balde? Cuando alguien se va del pueblo, se le tira agua por detrás, para que vuelva.",
			"Estos años se gastó mucha agua aquí.",
		])
		_offer_broth()
		return true
	if not GameState.is_beat_done(BeatData.INN_WATER):
		_ask_for_water()
		return true
	if not GameState.is_beat_done(BeatData.BROTH):
		_offer_broth()
		return true
	if not GameState.is_beat_done(BeatData.GUEST_BOOK):
		_give_book()
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

# Nadie la usa y no junta polvo: el pueblo no se sorprende, el jugador decide.
static func look_at_chair() -> bool:
	Dialogues.say("", [
		"Una silla en el rincón, girada hacia la mesa. Nadie la usa. Aun así, no tiene polvo.",
		"...Juraría que hace un rato estaba girada para el otro lado.",
	])
	return true

# Se puede mirar desde el principio: el regalo llega después, pero el libro ya
# estaba ahí, casi vacío.
static func look_at_book() -> bool:
	Dialogues.say("", ["El libro de registro de la posada, abierto sobre el mostrador. Casi todas las filas están en blanco."])
	Dialogues.say(TownNpcData.POSADERA_NAME, ["Es el libro de los huéspedes."])
	Dialogues.say("", ["¿Y quién llegó?"])
	Dialogues.say(TownNpcData.POSADERA_NAME, ["Tú. Hace tiempo que eres el único."])
	return true

static func _offer_broth() -> void:
	Dialogues.ask(TownNpcData.POSADERA_NAME, "Tengo caldo recién hecho. ¿Te sirvo un plato?",
			["Sí, gracias", "No tengo con qué pagar"], _on_broth_chosen)

static func _on_broth_chosen(index: int) -> void:
	if index == 0:
		GameState.complete_beat(BeatData.BROTH)
		Dialogues.say(TownNpcData.POSADERA_NAME, [
			"Toma. Despacio, que quema.",
			"Hoy me salió contento. Los días que cocino triste, aquí nadie habla.",
		])
		_give_book()
	else:
		Dialogues.say(TownNpcData.POSADERA_NAME, ["¿Y quién te habló de pagar? Bueno... la olla no se va a ningún lado."])

static func _ask_for_water() -> void:
	Dialogues.say(TownNpcData.POSADERA_NAME, ["Si sales, ¿me traerías un balde del pozo? No puedo dejar el mostrador."])

static func _give_book() -> void:
	GameState.complete_beat(BeatData.GUEST_BOOK)
	GameState.receive_notebook()
	Dialogues.say(TownNpcData.POSADERA_NAME, [
		"Este es el libro de los huéspedes. Hace mucho que no viene nadie a quien anotar. Quédatelo, es un regalo. A ver si te ayuda a acordarte de quién eres.",
		"Mi primer marido decía que un libro vacío es una casa sin gente. Todavía lo dice, pero ya no le hago caso.",
	])
	Events.hint_requested.emit("guest_book", GUEST_BOOK_HINT)
	Dialogues.vanish_object(&"libro")
