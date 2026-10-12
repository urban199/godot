extends Area3D

@export var area_id := "corridor"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		Objectives.discover_area(area_id)
