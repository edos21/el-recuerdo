extends SceneTree
# Ejecutar una vez: godot --headless --script res://tools/setup_project.gd
# Genera el input map real (usando las constantes KEY_* del motor, no
# numeros a mano) y lo persiste en project.godot.

func _build_action(keys: Array) -> Dictionary:
	var events: Array = []
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		events.append(ev)
	return {"deadzone": 0.2, "events": events}

func _initialize() -> void:
	var actions := {
		"move_left": [KEY_LEFT, KEY_A],
		"move_right": [KEY_RIGHT, KEY_D],
		"jump": [KEY_SPACE],
		"sprint": [KEY_SHIFT],
		"attack": [KEY_X],
		"interact": [KEY_ENTER, KEY_KP_ENTER],
	}
	for action_name in actions:
		ProjectSettings.set_setting("input/%s" % action_name, _build_action(actions[action_name]))
	ProjectSettings.save()
	print("input map guardado")
	quit()
