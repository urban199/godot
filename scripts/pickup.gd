extends Area3D
@export var kind := "ammo"
func _ready() -> void:
    body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        get_tree().current_scene.collect_pickup(kind)
        queue_free()