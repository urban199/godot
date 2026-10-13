extends Node

const CHARACTER_DATA := [
	{"id": "kairo", "name": "Kairo", "role": "Balanced", "description": "A versatile fighter with steady speed and power.", "hp": 100.0, "speed": 280.0, "power": 12.0, "color": Color("#2a9dca"), "accent": Color("#d9f3ff"), "sprite_path": "res://assets/sprites/kairo_atlas.png", "unlocked": true},
	{"id": "ren", "name": "Ren", "role": "Fast", "description": "A quick striker who relies on movement.", "hp": 86.0, "speed": 350.0, "power": 9.0, "color": Color("#bd5ad6"), "accent": Color("#f1caff"), "sprite_path": "res://assets/sprites/ren_atlas.png", "unlocked": true},
	{"id": "daigo", "name": "Daigo", "role": "Heavy", "description": "A durable fighter with powerful attacks.", "hp": 125.0, "speed": 220.0, "power": 17.0, "color": Color("#c56c3c"), "accent": Color("#ffe0aa"), "sprite_path": "res://assets/sprites/daigo_atlas.png", "unlocked": true},
]

const ARENA_DATA := [
	{"id": "forest_shrine", "name": "Forest Shrine", "description": "A quiet shrine beneath the mountain moon.", "scene_path": "res://scenes/arenas/forest_shrine.tscn", "left_bound": 28.0, "right_bound": 1252.0, "player_spawn": Vector2(430, 535), "opponent_spawn": Vector2(820, 535), "color": Color("#101a36"), "accent": Color("#426b63"), "unlocked": true},
	{"id": "training_dojo", "name": "Training Dojo", "description": "A clean practice ground for new techniques.", "scene_path": "res://scenes/arenas/training_dojo.tscn", "left_bound": 28.0, "right_bound": 1252.0, "player_spawn": Vector2(430, 535), "opponent_spawn": Vector2(820, 535), "color": Color("#202038"), "accent": Color("#8b6e4e"), "unlocked": true},
	{"id": "ruined_outpost", "name": "Ruined Outpost", "description": "An abandoned watch post at dusk.", "scene_path": "res://scenes/arenas/ruined_outpost.tscn", "left_bound": 28.0, "right_bound": 1252.0, "player_spawn": Vector2(430, 535), "opponent_spawn": Vector2(820, 535), "color": Color("#281c2c"), "accent": Color("#94514c"), "unlocked": true},
]

var selected_mode := "quick_battle"
var player_character_id := "kairo"
var opponent_character_id := "ren"
var selected_arena_id := "forest_shrine"
var match_result: Dictionary = {}
var settings := {"master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 1.0, "control_sensitivity": 1.0, "mobile_layout": "classic", "effects_quality": "medium", "screen_shake": true, "reduced_effects": false, "flash_intensity": 1.0}
var progress := {"wins": 0, "losses": 0, "draws": 0}

func _ready() -> void:
	_ensure_audio_buses()
	_load_settings()
	apply_audio_settings()
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("jump", [KEY_W, KEY_SPACE, KEY_UP])
	_bind("attack", [KEY_J])
	_bind("skill", [KEY_K])
	_bind("skill_alt", [KEY_U])
	_bind("dash", [KEY_L])
	_bind("guard", [KEY_H, KEY_SHIFT])
	_bind("ui_cancel", [KEY_ESCAPE, KEY_BACK])

func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var bus_index := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, "Master")

func apply_audio_settings() -> void:
	set_audio_volume("Master", settings.master_volume)
	set_audio_volume("Music", settings.music_volume)
	set_audio_volume("SFX", settings.sfx_volume)

func set_audio_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))
	AudioServer.set_bus_mute(bus_index, value <= 0.0)

func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func character_by_id(character_id: String) -> Dictionary:
	for character in CHARACTER_DATA:
		if character.id == character_id:
			return character
	return CHARACTER_DATA[0]

func arena_by_id(arena_id: String) -> Dictionary:
	for arena in ARENA_DATA:
		if arena.id == arena_id:
			return arena
	return ARENA_DATA[0]

func save_settings() -> void:
	var file := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file == null:
		push_warning("Settings could not be saved; defaults will be used next time.")
		return
	file.store_string(JSON.stringify({"version": 1, "settings": settings}))

func record_result(outcome: String) -> void:
	if outcome == "victory":
		progress.wins += 1
	elif outcome == "defeat":
		progress.losses += 1
	else:
		progress.draws += 1
	var file := FileAccess.open("user://progress.json", FileAccess.WRITE)
	if file == null:
		push_warning("Progress could not be saved; this result is only available for this session.")
		return
	file.store_string(JSON.stringify({"version": 1, "progress": progress}))

func _load_settings() -> void:
	_load_progress()
	if not FileAccess.file_exists("user://settings.json"):
		return
	var file := FileAccess.open("user://settings.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.get("version", 0) == 1 and parsed.get("settings") is Dictionary:
		var stored: Dictionary = parsed.settings
		settings.master_volume = clampf(float(stored.get("master_volume", 1.0)), 0.0, 1.0)
		settings.music_volume = clampf(float(stored.get("music_volume", 0.8)), 0.0, 1.0)
		settings.sfx_volume = clampf(float(stored.get("sfx_volume", 1.0)), 0.0, 1.0)
		settings.control_sensitivity = clampf(float(stored.get("control_sensitivity", 1.0)), 0.5, 1.5)
		var layout: String = str(stored.get("mobile_layout", "classic"))
		settings.mobile_layout = layout if layout in ["classic", "compact"] else "classic"
		var quality: String = str(stored.get("effects_quality", "medium"))
		settings.effects_quality = quality if quality in ["low", "medium", "high"] else "medium"
		settings.screen_shake = bool(stored.get("screen_shake", true))
		settings.reduced_effects = bool(stored.get("reduced_effects", false))
		settings.flash_intensity = clampf(float(stored.get("flash_intensity", 1.0)), 0.0, 1.0)

func _load_progress() -> void:
	if not FileAccess.file_exists("user://progress.json"):
		return
	var file := FileAccess.open("user://progress.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.get("version", 0) == 1 and parsed.get("progress") is Dictionary:
		var stored: Dictionary = parsed.progress
		progress.wins = maxi(0, int(stored.get("wins", 0)))
		progress.losses = maxi(0, int(stored.get("losses", 0)))
		progress.draws = maxi(0, int(stored.get("draws", 0)))
