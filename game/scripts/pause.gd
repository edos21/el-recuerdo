extends Node
# Dueño único de la pausa del arbol. Varios sistemas pausan (el dialogo del
# HUD, el menu): cada uno pide con su nombre y el arbol sigue pausado mientras
# quede alguno, en vez de que el primero que termina despause al resto.

var _holders: Dictionary[StringName, bool] = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func hold(holder: StringName) -> void:
	_holders[holder] = true
	get_tree().paused = true

func release(holder: StringName) -> void:
	_holders.erase(holder)
	get_tree().paused = not _holders.is_empty()

# Una pausa es de la escena que la pidio: al cambiar de escena se suelta toda.
func clear() -> void:
	_holders.clear()
	get_tree().paused = false
