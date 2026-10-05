extends Control
# Escena de arranque. Sin partida guardada (o con un debug.cfg, que manda) pasa
# derecho al Nivel 1 como siempre; con partida pregunta si seguir donde se
# durmió o empezar de nuevo. Usa el estilo de la pausa mínima.

enum Choice { CONTINUE, NEW_GAME, QUIT }

const MAIN_SCENE := "res://scenes/Main.tscn"
const LABELS := {
	Choice.CONTINUE: "Seguir donde dormí",
	Choice.NEW_GAME: "Empezar de nuevo",
	Choice.QUIT: "Salir",
}
const NEW_GAME_CONFIRM := "¿Seguro? Lo dormido se pierde"
const BACKDROP_COLOR := Color.BLACK

var _selected := 0
var _new_game_armed := false
var _rows: Array[Label] = []
var _bold := FontVariation.new()

func _ready() -> void:
	if DebugConfig.start_scene != "" or not SaveGame.has_save():
		_start_new.call_deferred(false)
		return
	_bold.base_font = ThemeDB.fallback_font
	_bold.variation_embolden = PauseMenu.PLAIN_EMBOLDEN
	_build()
	_render()

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", PauseMenu.PLAIN_OPTION_GAP)
	center.add_child(column)
	for choice in LABELS:
		var row := Label.new()
		row.add_theme_font_override("font", _bold)
		row.add_theme_font_size_override("font_size", PauseMenu.PLAIN_OPTION_SIZE)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(row)
		_rows.append(row)

func _unhandled_input(event: InputEvent) -> void:
	var step := int(event.is_action_pressed(&"move_down")) - int(event.is_action_pressed(&"move_up"))
	if step != 0:
		_selected = posmod(_selected + step, LABELS.size())
		_new_game_armed = false
		_render()
	elif event.is_action_pressed(&"interact"):
		_confirm()

func _confirm() -> void:
	match _selected:
		Choice.CONTINUE:
			SaveGame.load_game()
		Choice.NEW_GAME:
			if not _new_game_armed:
				_new_game_armed = true
				_render()
				return
			_start_new(true)
		Choice.QUIT:
			get_tree().quit()

func _start_new(erase_save: bool) -> void:
	if erase_save:
		SaveGame.delete_save()
	get_tree().change_scene_to_file(MAIN_SCENE)

func _render() -> void:
	for i in _rows.size():
		var label: String = NEW_GAME_CONFIRM if i == Choice.NEW_GAME and _new_game_armed else LABELS[i]
		var chosen := i == _selected
		_rows[i].text = PauseMenu.PLAIN_MARKER % label if chosen else label
		_rows[i].add_theme_color_override("font_color", PauseMenu.PLAIN_SELECTED if chosen else PauseMenu.PLAIN_IDLE)
