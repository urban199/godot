extends Node

const SAVE_PATH := "user://game_state.json"
const SAVE_VERSION := 1
var _loaded_world_flags: Dictionary = {}
var _world_events: Array[String] = []

func has_world_event(event_id: String) -> bool:
	return _world_events.has(event_id)

func mark_world_event(event_id: String) -> void:
	if not _world_events.has(event_id):
		_world_events.append(event_id)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(player: Node3D, checkpoint: String = "forest_entrance") -> bool:
	var collected_pickups: Array[String] = []
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if not bool(pickup.get("visible")):
			collected_pickups.append(str(pickup.name))
	var open_doors: Array[String] = []
	for door in get_tree().get_nodes_in_group("doors"):
		if bool(door.get("is_open")):
			open_doors.append(str(door.name))
	var state := {
		"version": SAVE_VERSION,
		"checkpoint": checkpoint,
		"player": {"position": [player.global_position.x, player.global_position.y, player.global_position.z], "rotation_y": player.rotation.y, "health": player.get("health"), "flashlight_battery": player.get("flashlight_battery")},
		"inventory": Inventory.items.duplicate(),
		"objectives_completed": Objectives.completed.duplicate(),
		"world_flags": {"generator_on": Objectives.completed.has("restore_power"), "collected_pickups": collected_pickups, "open_doors": open_doors, "map_rooms": Objectives.discovered_areas.duplicate(), "events": _world_events.duplicate()},
		"last_saved": Time.get_datetime_string_from_system(true)
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file for writing: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(state, "\t"))
	return file.get_error() == OK

func load_game(player: Node3D) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary) or int(parsed.get("version", -1)) != SAVE_VERSION:
		push_warning("Save file is invalid or uses an unsupported version.")
		return false
	var player_data: Variant = parsed.get("player", {})
	var position_data: Variant = player_data.get("position", []) if player_data is Dictionary else []
	if position_data is Array and position_data.size() == 3:
		player.global_position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
		player.rotation.y = float(player_data.get("rotation_y", 0.0))
		player.set("health", clampf(float(player_data.get("health", 100.0)), 0.0, 100.0))
		player.set("flashlight_battery", clampf(float(player_data.get("flashlight_battery", 100.0)), 0.0, 100.0))
		player.emit_signal("health_changed", player.get("health"))
	var saved_inventory: Variant = parsed.get("inventory", [])
	if saved_inventory is Array:
		Inventory.restore(saved_inventory)
	var saved_objectives: Variant = parsed.get("objectives_completed", [])
	var world_flags: Variant = parsed.get("world_flags", {})
	_loaded_world_flags = world_flags if world_flags is Dictionary else {}
	_world_events.clear()
	var saved_events: Variant = _loaded_world_flags.get("events", [])
	if saved_events is Array:
		for event_id in saved_events:
			if event_id is String and not _world_events.has(event_id):
				_world_events.append(event_id)
	if saved_objectives is Array:
		var saved_areas: Variant = _loaded_world_flags.get("map_rooms", [])
		Objectives.restore(saved_objectives, saved_areas if saved_areas is Array else [])
	for key in ["collected_pickups", "open_doors"]:
		if not (_loaded_world_flags.get(key, []) is Array):
			_loaded_world_flags[key] = []
	apply_world_state()
	return true

func apply_world_state() -> void:
	for pickup_name in _loaded_world_flags.get("collected_pickups", []):
		var pickup := get_tree().current_scene.find_child(str(pickup_name), true, false)
		if pickup != null and pickup.has_method("interact"):
			pickup.set("visible", false)
			for shape in pickup.find_children("*", "CollisionShape3D", true, false):
				shape.set_deferred("disabled", true)
	for door_name in _loaded_world_flags.get("open_doors", []):
		var door := get_tree().current_scene.find_child(str(door_name), true, false)
		if door != null and door.has_method("interact"):
			door.set("is_open", true)
			var door_node := door as Node3D
			door_node.rotation.y = deg_to_rad(92)

func delete_save() -> void:
	_loaded_world_flags.clear()
	_world_events.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
