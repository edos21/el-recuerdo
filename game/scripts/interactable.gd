class_name Interactable
extends Node2D
# Base de todo lo que se usa acercándose y apretando Enter y no es un NPC (la
# cama, unas llaves en el suelo, el pozo): una zona en la capa de interacción
# y la pista con la acción. El jugador busca `interact` en el padre de las
# áreas que toca (topdown_player.gd).

const HINT_OFFSET := Vector2(-60, -96)
const HINT_SIZE := Vector2(120, 26)
const HINT_FONT_SIZE := 14
const HINT_OUTLINE := 4

var _hint := Label.new()

# `area`: dónde tiene que estar el jugador (px de mundo, relativa a este nodo);
# `hint_text`: la acción que muestra la pista ("[Enter] descansar").
func _init(area: Rect2, hint_text: String) -> void:
	var zone := Area2D.new()
	zone.collision_layer = 8
	zone.collision_mask = 8
	zone.position = area.get_center()
	zone.add_child(MapUtils.rect_shape(area.size))
	zone.area_entered.connect(_on_zone_area_entered)
	zone.area_exited.connect(_on_zone_area_exited)
	add_child(zone)
	_hint.text = hint_text
	_hint.position = HINT_OFFSET
	_hint.size = HINT_SIZE
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", HINT_OUTLINE)
	_hint.visible = false
	add_child(_hint)

func interact(_player: Node2D) -> void:
	pass

func _on_zone_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		_hint.visible = true

func _on_zone_area_exited(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		_hint.visible = false
