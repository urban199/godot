extends StaticBody3D

@export_enum("keycard", "battery", "note", "medkit") var item_type := "keycard"
@export var display_name := "Staff access card"
@export var note_id := "research_note_04"
@export_multiline var note_text := "RESEARCH LOG 04: The power failure was deliberate. Do not open the lower wing."

func _ready() -> void:
	add_to_group("resettable")
	add_to_group("pickups")

func get_interaction_prompt() -> String:
	return "[E] Pick up %s" % display_name

func interact(player: Variant) -> void:
	if item_type == "keycard":
		if not Inventory.add_item("keycard"):
			player.show_message("Inventory full")
			return
		Objectives.complete("find_keycard")
	elif item_type == "battery":
		if not Inventory.add_item("battery"):
			player.show_message("Inventory full")
			return
		player.add_flashlight_battery(40.0)
	elif item_type == "medkit":
		player.heal(35.0)
	elif item_type == "note":
		if not Inventory.add_item(note_id):
			player.show_message("Inventory full")
			return
		player.show_message(note_text)
	SaveSystem.save_game(player)
	visible = false
	for child in find_children("*", "CollisionShape3D", true, false):
		child.set_deferred("disabled", true)

func reset_interactable() -> void:
	visible = true
	for child in find_children("*", "CollisionShape3D", true, false):
		child.set_deferred("disabled", false)
