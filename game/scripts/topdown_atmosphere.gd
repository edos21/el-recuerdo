class_name TopDownAtmosphere
extends Node2D
# Base de las capas de atmósfera de las escenas cenitales: decoran lo que armó
# el loader (grupos) sin tocar la lógica. `bounds` es el mapa en px de mundo,
# para lo que se reparte por todo el lugar y no alrededor del jugador.

func build(_player: CharacterBody2D, _bounds: Rect2) -> void:
	pass
