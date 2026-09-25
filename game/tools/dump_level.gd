extends Node
# godot --headless --path . res://tools/dump_level.tscn
# Carga el nivel de forma aislada (sin Main.tscn) y cuenta entidades para
# comparar contra lo esperado del ASCII. Corre como escena y no como
# `--script` porque los autoloads (Events, GameState) no compilan en ese modo.

func _ready() -> void:
	var loader := preload("res://scripts/level_loader.gd").new()
	add_child(loader)
	var player := loader.build("res://levels/level1.txt")

	# Los grupos solo registran nodos que ya estan dentro del arbol: el loader
	# tiene que colgarse de el antes de build().
	var checkpoints := get_tree().get_nodes_in_group("checkpoints")
	var expulsion := get_tree().get_nodes_in_group("expulsion_trigger")
	var kill := get_tree().get_nodes_in_group("kill_zone")

	var enemies := 0
	var memories := 0
	var solids := 0
	var platforms := 0
	var hazards := 0
	for child in loader.get_children():
		if child is CharacterBody2D and child != player:
			enemies += 1
		elif child.get_script() != null and child.get_script().resource_path.ends_with("memory_pickup.gd"):
			memories += 1
		elif child is StaticBody2D:
			var shape: CollisionShape2D = child.get_child(0)
			if shape and shape.one_way_collision:
				platforms += 1
			else:
				solids += 1
		elif child is Area2D and not child.is_in_group("expulsion_trigger") and not child.is_in_group("kill_zone") and not child.is_in_group("checkpoints"):
			hazards += 1

	print("player: ", player != null, " at ", player.position if player else "?")
	print("checkpoints: ", checkpoints.size())
	print("expulsion_trigger: ", expulsion.size())
	print("kill_zone: ", kill.size())
	print("enemies: ", enemies)
	print("memory pickups: ", memories)
	print("solid bodies (merged): ", solids)
	print("one-way platforms (merged): ", platforms)
	print("hazard areas: ", hazards)
	get_tree().quit()
