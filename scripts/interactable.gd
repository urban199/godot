extends Area3D

@export_enum("fuse", "panel", "checkpoint", "exit", "note") var kind := "note"

func _ready() -> void:
    add_to_group("interactable")

func get_interaction_prompt(player: Node3D) -> String:
    var game := get_tree().get_first_node_in_group("game")
    if game and game.has_method("interaction_prompt"):
        return String(game.call("interaction_prompt", self, player))
    return "Tekan E untuk berinteraksi"

func interact(player: Node3D) -> void:
    var game := get_tree().get_first_node_in_group("game")
    if game and game.has_method("interact_with"):
        game.call("interact_with", self, player)
