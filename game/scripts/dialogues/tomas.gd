extends RefCounted
# Tomás y sus llaves. Alivio: devolverle algo que "perdió". No las perdió del
# todo, y por eso el agradecimiento no le sale del todo aliviado.

const BARKS_AFTER := ["Mm.", "Buen día... creo.", "Hoy no perdí nada. Todavía."]

static func run() -> bool:
	if GameState.has_item(Dialogues.KEYS):
		GameState.remove_item(Dialogues.KEYS)
		GameState.complete_beat(BeatData.TOMAS_KEYS)
		GameState.lock_memory(Dialogues.MEMORY_TOMAS_STORE)
		Dialogues.say(TownNpcData.TOMAS_NAME, [
			"¿Esas son...? Mis llaves.",
			"Gracias. De verdad. Hace mucho que nadie me devolvía nada.",
			"...Ya me había acostumbrado a no tenerlas.",
		])
		return true
	# Con el recuerdo pendiente no se cierra la conversación ni se adelanta nada:
	# responde algo neutro hasta que llegue el momento.
	if GameState.is_memory_locked():
		Dialogues.say(TownNpcData.TOMAS_NAME, [
			"Hoy no perdí nada. Bueno, todavía no.",
			"Estoy cansado. Hablamos con calma, ¿sí?",
		])
		return true
	if GameState.is_beat_done(BeatData.TOMAS_KEYS):
		Dialogues.say(TownNpcData.TOMAS_NAME, [
			"Hoy no perdí nada. Bueno, todavía no.",
			"Yo ya no pregunto. Pero lo de las llaves... gracias.",
		])
		return true
	# Lo olvidó, pero no del todo: la pista de dónde buscarlas.
	Dialogues.say(TownNpcData.TOMAS_NAME, [
		"El pueblo anda raro estos días. Todos olvidan cosas pequeñas.",
		"Yo mismo... juraría que esta mañana tenía las llaves en la mano. Bajando por el camino del sur, creo. ¿O era ayer?",
		"Ya no pregunto. Es más fácil hacer como que no pasa.",
	])
	return true

static func barks(default: PackedStringArray) -> PackedStringArray:
	if GameState.is_beat_done(BeatData.TOMAS_KEYS):
		return PackedStringArray(BARKS_AFTER)
	return default

static func pick_up_keys(keys: StoryObject) -> bool:
	GameState.add_item(Dialogues.KEYS)
	Dialogues.say("", ["Unas llaves en el suelo, de las viejas, con un cordón gastado. Alguien las debe estar buscando."])
	keys.vanish()
	return true
