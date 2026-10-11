extends RefCounted
## Small versioned JSON checkpoint store. Runtime data stays in user://.

const SAVE_PATH := "user://neko_nightfall_checkpoint.json"
const SAVE_VERSION := 1

static func save_checkpoint(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open checkpoint save: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "checkpoint": data}))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("Checkpoint save failed with error %d." % write_error)
		return false
	return true

static func load_checkpoint() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Checkpoint file could not be opened; starting a new game.")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_warning("Checkpoint file is invalid; starting a new game.")
		return {}
	var payload: Dictionary = parsed
	if int(payload.get("version", -1)) != SAVE_VERSION or not (payload.get("checkpoint", {}) is Dictionary):
		push_warning("Checkpoint version is unsupported; starting a new game.")
		return {}
	return payload["checkpoint"] as Dictionary

static func has_checkpoint() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func clear_checkpoint() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
