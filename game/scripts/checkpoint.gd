extends Area2D

signal activated

const INACTIVE_TINT := Color(0.55, 0.55, 0.6, 1)

var _active := false

@onready var visual: Sprite2D = $Visual

func _ready() -> void:
	visual.modulate = INACTIVE_TINT
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not _active:
		_active = true
		var tween := create_tween()
		tween.tween_property(visual, "modulate", Color.WHITE, 0.4)
		get_tree().call_group("audio", "play_sfx", "checkpoint")
		get_tree().call_group("hud", "show_hint_once", "checkpoint", "Acá puedo respirar un momento.")
		if body.has_method("restore_vitals"):
			body.restore_vitals()
	activated.emit()
