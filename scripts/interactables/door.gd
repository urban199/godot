extends StaticBody3D

@export var requires_power := true
@export var requires_keycard := false
@export var exit_door := false
@export var discovery_area := ""
var is_open := false

func _ready() -> void:
	add_to_group("resettable")
	add_to_group("doors")

func get_interaction_prompt() -> String:
	if is_open:
		return "Door is open"
	if _has_access():
		return "[E] Open door"
	return "Door needs power" if requires_power and not Objectives.completed.has("restore_power") else "Door requires an access card"

func interact(player: Variant) -> void:
	if is_open or not _has_access():
		return
	is_open = true
	if not discovery_area.is_empty():
		Objectives.discover_area(discovery_area)
	var tween := create_tween()
	tween.tween_property(self, "rotation:y", rotation.y + deg_to_rad(92), 0.65)
	if exit_door:
		Objectives.discover_area("exit")
		Objectives.complete("reach_exit")
		SaveSystem.save_game(player)

func _has_access() -> bool:
	var has_power := not requires_power or Objectives.completed.has("restore_power")
	var has_keycard := not requires_keycard or Inventory.has_item("keycard")
	return has_power and has_keycard

func reset_interactable() -> void:
	is_open = false
	rotation.y = 0.0
