class_name NotebookEntryDef
extends Resource
# Un encargo del cuaderno: título del índice y sus etapas en orden. El dibujo se
# busca por id en assets/notebook (ver NotebookData.drawing_path).

@export var id := ""
@export var title := ""
@export var section: NotebookData.Section = NotebookData.Section.ERRANDS
@export var stages: Array[NotebookStageDef] = []
