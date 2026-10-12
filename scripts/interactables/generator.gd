extends StaticBody3D

var is_active := false

func _ready() -> void:
	add_to_group("resettable")
	add_to_group("generators")

func get_interaction_prompt() -> String:
	is_active = is_active or Objectives.completed.has("restore_power")
	return "[E] Start generator" if not is_active else "Generator is running"

func interact(player: Variant) -> void:
	if is_active or not Inventory.has_item("keycard"):
		return
	is_active = true
	Objectives.complete("restore_power")
	SaveSystem.save_game(player)

func reset_interactable() -> void:
	is_active = false
