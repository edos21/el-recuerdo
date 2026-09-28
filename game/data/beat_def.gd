class_name BeatDef
extends Resource
# Un momento de guion que mueve la Estabilidad una sola vez: una entrada de
# BeatData (data/beats.tres). Qué significa cada `Kind` está en BeatData.
#
# Godot no escribe en el .tres lo que coincide con el default: cambiar un
# default acá cambia todas las entradas que lo usan.

@export var id := ""
@export var kind: BeatData.Kind = BeatData.Kind.RELIEF
@export var amount := 0.0
