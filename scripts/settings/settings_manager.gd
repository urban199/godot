extends Node

signal settings_changed

const SETTINGS_PATH := "user://player_settings.json"
const DEFAULTS := {
	"mouse_sensitivity": 0.5,
	"touch_sensitivity": 0.5,
	"master_volume": 1.0,
	"music_volume": 0.8,
	"effects_volume": 1.0,
	"graphics_quality": "medium",
	"effects_quality": "medium",
	"view_distance": "medium",
	"rain_quality": "medium"
}

var values: Dictionary = DEFAULTS.duplicate(true)

func _ready() -> void:
	load_settings()
	_apply_audio()

func get_value(key: String, fallback: Variant = null) -> Variant:
	return values.get(key, fallback)

func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key):
		return
	values[key] = value
	_apply_audio()
	settings_changed.emit()

func save_settings() -> bool:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save settings: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(values, "\t"))
	return file.get_error() == OK

func load_settings() -> void:
	values = DEFAULTS.duplicate(true)
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("Settings file is invalid; using defaults.")
		return
	for key in DEFAULTS:
		if parsed.has(key) and typeof(parsed[key]) == typeof(DEFAULTS[key]):
			values[key] = parsed[key]
	settings_changed.emit()

func apply_environment(environment: Environment) -> void:
	var quality := str(values.get("graphics_quality", "medium"))
	var view_distance := str(values.get("view_distance", "medium"))
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var fog_for_quality := 0.025 if quality == "high" else (0.04 if quality == "low" else 0.032)
	environment.fog_density = 0.02 if view_distance == "high" else (0.052 if view_distance == "low" else fog_for_quality)

func apply_world(world: Node) -> void:
	var rain := world.get_node_or_null("Rain")
	if rain is GPUParticles3D:
		var setting := str(values.get("rain_quality", "medium"))
		rain.amount = 180 if setting == "low" else (900 if setting == "high" else 500)
	var quality := str(values.get("graphics_quality", "medium"))
	for light in world.find_children("*", "OmniLight3D", true, false):
		light.set("shadow_enabled", quality == "high")
	for light in world.find_children("*", "DirectionalLight3D", true, false):
		light.set("shadow_enabled", quality != "low")

func _apply_audio() -> void:
	if AudioServer.get_bus_count() > 0:
		AudioServer.set_bus_volume_linear(0, clampf(float(values.get("master_volume", 1.0)), 0.0, 1.0))
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_linear(music_bus, clampf(float(values.get("music_volume", 0.8)), 0.0, 1.0))
	var effects_bus := AudioServer.get_bus_index("Effects")
	if effects_bus >= 0:
		AudioServer.set_bus_volume_linear(effects_bus, clampf(float(values.get("effects_volume", 1.0)), 0.0, 1.0))
