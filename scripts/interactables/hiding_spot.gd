extends StaticBody3D

@export var label := "Storage locker"

func _ready() -> void:
	add_to_group("hiding_spots")

func get_interaction_prompt() -> String:
	return "[E] Hide in %s" % label

func interact(player: Variant) -> void:
	if player != null and player.has_method("enter_hiding_spot"):
		player.call("enter_hiding_spot", self)
