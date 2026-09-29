class_name StoryObject
extends Interactable
# Un objeto del guion en el mapa (unas llaves en el suelo, el pozo): la zona
# para usarlo y su diálogo (Dialogues), que decide qué pasa según el estado. El
# sprite lo pone el loader como cualquier objeto del mapa; este nodo lo conoce
# para poder hacerlo desaparecer. Los datos vienen de data/story_objects.gd.

var dialogue: StringName
var _prop: Node2D

func _init(area: Rect2, hint_text: String, dialogue_id: StringName, prop: Node2D) -> void:
	super(area, hint_text)
	dialogue = dialogue_id
	_prop = prop

func interact(_player: Node2D) -> void:
	Dialogues.run(dialogue, self)

# Se lo lleva el protagonista (las llaves): se va con su sprite.
func vanish() -> void:
	_prop.queue_free()
	queue_free()
