extends RefCounted
# Marta. Madurar: dejar que te vean. "Estoy bien" no castiga: solo deja el beat
# pendiente. Sabe más de lo que dice, así que lo que dice tiene que poder
# releerse después sin mentir.

static func run() -> bool:
	if GameState.is_beat_done(BeatData.DONT_KNOW):
		return false
	Dialogues.ask(TownNpcData.MARTA_NAME, "¿Cómo estás? Pero de verdad.", ["Estoy bien", "No sé quién soy"], _on_chosen)
	return true

static func _on_chosen(index: int) -> void:
	if index == 1:
		GameState.complete_beat(BeatData.DONT_KNOW)
		Dialogues.say(TownNpcData.MARTA_NAME, [
			"...",
			"Gracias por decírmelo. No tienes que saberlo hoy. Lo vamos a ir viendo.",
		])
	else:
		Dialogues.say(TownNpcData.MARTA_NAME, ["Mm. Bueno. Si cambia, aquí estoy."])
