class_name NotebookStageDef
extends Resource
# Una etapa de una entrada del cuaderno: desde cuándo vale (`condition`, el mismo
# formato que GameState.is_met) y qué dice. Qué significa cada `Stage` está en
# NotebookData.

@export var stage: NotebookData.Stage = NotebookData.Stage.NOTED
@export var condition: Dictionary = {}
# Vacía = sigue valiendo la nota de la etapa anterior.
@export_multiline var note := ""
# Variante con Estabilidad baja; vacía = la misma nota con el efecto genérico.
@export_multiline var note_low := ""
