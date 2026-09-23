extends Area2D

@export var ability: String = ""
@export_multiline var message: String = ""
@export var icon: Texture2D
@export var icon_scale: float = 2.5

@onready var sound: AudioStreamPlayer = $Sound

func _ready() -> void:
	# Un override de escena instanciada (definido en Main.tscn) puede
	# aplicarse DESPUÉS de que esta escena corra su propio _ready(), así
	# que leer `icon` acá mismo puede ver todavía el valor por defecto
	# (null). call_deferred lo pospone al final del frame, cuando toda
	# la jerarquía de overrides ya se terminó de aplicar.
	call_deferred("_apply_icon")
	body_entered.connect(_on_body_entered)

func _apply_icon() -> void:
	$Icon.texture = icon
	$Icon.scale = Vector2(icon_scale, icon_scale)

# Un recuerdo "custodiado" no existe hasta que se cumple lo que lo custodia
# (por ejemplo, vencer al elite de su arena).
func lock() -> void:
	set_deferred("monitoring", false)
	hide()

func reveal() -> void:
	show()
	set_deferred("monitoring", true)

func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("unlock"):
		return

	body.unlock(ability)
	Events.message_requested.emit(message)

	# Frenamos la detección y escondemos el objeto ya, pero esperamos a que
	# termine de sonar el jingle antes de destruirnos: si liberáramos el nodo
	# ahora, el AudioStreamPlayer se corta a mitad de sonido.
	set_deferred("monitoring", false)
	hide()
	sound.play()
	await sound.finished
	queue_free()
