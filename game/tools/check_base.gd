class_name CheckBase
extends Node
# Base de los validadores headless (tools/check_*.tscn): cuenta los fallos,
# simula teclas y cierra con código 1 si algo falló. Corren como escena y no
# como `--script` porque los autoloads no compilan en ese modo.

# La entrada simulada se procesa en el ciclo siguiente.
const INPUT_FRAMES := 2

var _failures := 0

func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		print("FAIL: %s" % description)

func _press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)

func _wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func _press_and_wait(action: String) -> void:
	_press(action)
	await _wait_frames(INPUT_FRAMES)

func _finish(check_name: String) -> void:
	print("%s: %s" % [check_name, "OK" if _failures == 0 else "%d FALLOS" % _failures])
	get_tree().quit(0 if _failures == 0 else 1)
