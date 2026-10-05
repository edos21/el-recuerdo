class_name NotebookData
extends Resource
# Entradas del cuaderno por etapas, hermano de beats.tres. Una entrada no guarda
# estado: su etapa se deriva de GameState.is_met, así que abrir el libro por
# primera vez ya muestra lo que se hizo antes de recibirlo.
#
# `Stage`: NOTED (anotada: lo supo), IN_PROGRESS (en curso: ya lo está haciendo),
# DONE (cumplida: se tacha) y CHANGED (el encargo se reescribió solo). Solo DONE
# manda la entrada al final del índice.

enum Stage { NOTED, IN_PROGRESS, DONE, CHANGED }
# Dónde se lista una entrada: los encargos son cosas por hacer (se tachan); lo del pueblo,
# curiosidades que no se cumplen ni se tachan.
enum Section { ERRANDS, TOWN }

const DRAWING_DIR := "res://assets/notebook/%s.png"

@export var entries: Array[NotebookEntryDef] = []
# Etapas del campo Nombre del registro (lo que sabe de sí): vale la última cuya
# condición se cumple.
@export var name_stages: Array[NotebookStageDef] = []

var _by_id: Dictionary[String, NotebookEntryDef] = {}

# Lo llama Catalogs al arrancar. Una entrada sin etapas o sin nota inicial se
# avisa acá en vez de quedar muda; las condiciones las prueba check_notebook.
func index() -> void:
	_by_id.clear()
	for entry in entries:
		if entry.id == "" or _by_id.has(entry.id):
			push_error("NotebookData: id vacío o repetido ('%s')." % entry.id)
			continue
		_by_id[entry.id] = entry
		if entry.title == "" or entry.stages.is_empty():
			push_error("NotebookData: '%s' necesita título y al menos una etapa." % entry.id)
		elif entry.stages[0].note == "":
			push_error("NotebookData: la primera etapa de '%s' necesita nota." % entry.id)
	if name_stages.is_empty() or name_stages[0].note == "":
		push_error("NotebookData: el campo Nombre necesita una etapa inicial con texto.")

func find_entry(entry_id: String) -> NotebookEntryDef:
	return _by_id.get(entry_id)

func drawing_path(of: NotebookEntryDef) -> String:
	return DRAWING_DIR % of.id

# La última etapa que se cumple; null si la entrada todavía no aparece.
func current_stage(of: NotebookEntryDef) -> NotebookStageDef:
	return _last_met(of.stages)

func is_done(of: NotebookEntryDef) -> bool:
	var stage := current_stage(of)
	return stage != null and stage.stage == Stage.DONE

# Con Estabilidad baja y variante escrita se usa esa; una etapa sin nota (o sin
# variante) cae a la anterior que sí la tiene.
func note_for(of: NotebookEntryDef, low: bool) -> String:
	var current := current_stage(of)
	if current == null:
		return ""
	if low and current.note_low != "":
		return current.note_low
	for i in range(of.stages.find(current), -1, -1):
		if of.stages[i].note != "":
			return of.stages[i].note
	return ""

# De una sección: en curso en el orden del catálogo, cumplidas al final.
func visible_entries(section: Section) -> Array[NotebookEntryDef]:
	var open: Array[NotebookEntryDef] = []
	var done: Array[NotebookEntryDef] = []
	for entry in entries:
		var stage := current_stage(entry)
		if stage == null or entry.section != section:
			continue
		if stage.stage == Stage.DONE:
			done.append(entry)
		else:
			open.append(entry)
	return open + done

func name_value() -> String:
	return _last_met(name_stages).note

func _last_met(stages: Array[NotebookStageDef]) -> NotebookStageDef:
	var met: NotebookStageDef = null
	for stage in stages:
		if GameState.is_met(stage.condition):
			met = stage
	return met
