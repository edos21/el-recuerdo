extends Node
# godot --headless --fixed-fps 60 --path . res://tools/dump_enemy_stats.tscn
# Vuelca los stats efectivos de cada enemigo del Nivel 1 y el estado de los
# recuerdos antes y despues de vencer a los enemigos. La salida tiene que ser
# identica entre dos versiones del interprete: se compara con diff. Solo mira
# lo que el loader construyo, asi sirve para cualquier cambio del interprete.
# Corre como escena y no como `--script` porque los autoloads (Events,
# GameState) no compilan en ese modo.

const LEVEL := "res://levels/level1.txt"

var _loader: Node2D
var _frames := 0

func _ready() -> void:
	_loader = preload("res://scripts/level_loader.gd").new()
	add_child(_loader)
	_loader.build(LEVEL)
	# Antes del primer frame de fisica: los patrulleros todavia no se movieron y
	# las posiciones son las de aparicion.
	_dump_enemies()

func _process(_delta: float) -> void:
	_frames += 1
	match _frames:
		2:
			_dump_pickups("bloqueado")
			_defeat_all()
		4:
			_dump_pickups("revelado")
			get_tree().quit()

func _dump_enemies() -> void:
	for child in _loader.get_children():
		if child is Enemy:
			var e: Enemy = child
			print("ENEMY pos=%.2f,%.2f beh=%d hp=%d/%d dmg=%d spd=%.1f patrol=%.1f chase=%.1f/%.1f kill=%s tint=%s layer=%d mask=%d frames=%s" % [
				e.position.x, e.position.y, e.behavior, e.health, e.max_health,
				e.contact_damage, e.speed, e.patrol_distance, e.chase_range,
				e.chase_speed, e.killable, e.modulate, e.collision_layer,
				e.collision_mask, e.sprite_frames_path])

# lock() y reveal() usan set_deferred: `monitoring` recien refleja el cambio un
# frame despues.
func _dump_pickups(phase: String) -> void:
	for child in _loader.get_children():
		var script: Script = child.get_script()
		if script and script.resource_path.ends_with("memory_pickup.gd"):
			print("PICKUP %s %s pos=%.2f,%.2f visible=%s monitoring=%s" % [
				phase, child.ability, child.position.x, child.position.y,
				child.visible, child.monitoring])

func _defeat_all() -> void:
	for child in _loader.get_children():
		if child is Enemy and child.killable:
			child.take_hit(child.max_health)
