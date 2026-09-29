class_name StoryObject
extends Interactable
# Un objeto del guion en el mapa (unas llaves en el suelo, el pozo): se ve, a
# veces bloquea el paso, y al usarlo corre su diálogo (Dialogues), que decide
# qué pasa según el estado. Los datos vienen de data/story_objects.gd.

var dialogue: StringName

func _init(data: Dictionary) -> void:
	var texture: Texture2D = data.texture
	var feet: Vector2 = data.feet
	var scale_factor := float(TopDownLoader.TILE_SCALE)
	var size := Vector2(texture.get_size()) * scale_factor
	# La zona cubre el objeto con un margen, para usarlo desde cualquier lado.
	var area := Rect2(-feet * scale_factor, size).grow(data.get("reach", 0.0))
	super(area, data.hint)
	dialogue = data.dialogue
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = -feet
	sprite.scale = Vector2(scale_factor, scale_factor)
	add_child(sprite)
	move_child(sprite, 0)

func interact(player: Node2D) -> void:
	Dialogues.run(dialogue, self, player)
