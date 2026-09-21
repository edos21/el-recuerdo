extends StaticBody2D
# Personaje del pueblo: se le habla con `interact` estando cerca. Las lineas
# van por la cola de mensajes del HUD (misma tecla y mismo cuadro que los
# textos de recuerdo: el jugador ya sabe como funciona).

@export var npc_name := ""
@export var sprite_frames_path := ""
@export var lines: PackedStringArray = []

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hint: Label = $Hint
@onready var talk_zone: Area2D = $TalkZone

func _ready() -> void:
	if sprite_frames_path != "":
		sprite.sprite_frames = load(sprite_frames_path)
	sprite.play("idle_down")
	hint.visible = false
	talk_zone.area_entered.connect(_on_zone_area_entered)
	talk_zone.area_exited.connect(_on_zone_area_exited)

func interact(player: Node2D) -> void:
	_face(player.global_position)
	for i in lines.size():
		var text := lines[i]
		if i == 0 and npc_name != "":
			text = "%s: %s" % [npc_name, text]
		get_tree().call_group("hud", "show_message", text)

func _face(target: Vector2) -> void:
	var offset := target - global_position
	var dir := "down"
	if absf(offset.x) > absf(offset.y):
		dir = "right" if offset.x > 0.0 else "left"
	elif offset.y < 0.0:
		dir = "up"
	sprite.play("idle_" + dir)

# El area de interaccion del jugador es la que "entra" en la zona del NPC.
func _on_zone_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		hint.visible = true

func _on_zone_area_exited(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		hint.visible = false
