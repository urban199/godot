extends Area3D

@export var checkpoint_id := "service_corridor"
var _activated := false

func _ready() -> void:
	add_to_group("resettable")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Variant) -> void:
	if not body.is_in_group("player"):
		return
	if _activated:
		SaveSystem.save_game(body, checkpoint_id)
		return
	_activated = true
	Objectives.discover_area("service")
	SaveSystem.save_game(body, checkpoint_id)
	body.show_message("Checkpoint saved")

func reset_interactable() -> void:
	_activated = false
