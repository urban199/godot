extends StaticBody3D

var inspected := false

func get_interaction_prompt() -> String:
	return "[E] Read terminal log"

func interact(player: Variant) -> void:
	inspected = true
	Objectives.discover_area("service")
	Objectives.discover_area("laboratory")
	Objectives.discover_area("corridor")
	if Inventory.has_item("keycard"):
		player.show_message("FACILITY LOG: Generator access restored. Service exit power is now available.")
	else:
		player.show_message("FACILITY LOG: Access denied. Staff keycard required.")
