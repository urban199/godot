extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const WorldScript = preload("res://scripts/world/world_builder.gd")
const HudScript = preload("res://scripts/ui/hud.gd")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_build_atmosphere()
	var world := Node3D.new()
	world.name = "World"
	world.set_script(WorldScript)
	add_child(world)
	SettingsManager.apply_world(world)
	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D
	player.position = Vector3(0, 0.15, 7)
	add_child(player)
	var hud := CanvasLayer.new()
	hud.set_script(HudScript)
	hud.set("player", player)
	add_child(hud)

func _build_atmosphere() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.012, 0.025, 0.045)
	sky_material.sky_horizon_color = Color(0.055, 0.075, 0.09)
	sky_material.ground_bottom_color = Color(0.012, 0.016, 0.02)
	sky_material.ground_horizon_color = Color(0.035, 0.045, 0.05)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.32, 0.39, 0.48)
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.12, 0.17, 0.2)
	SettingsManager.apply_environment(environment)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var moonlight := DirectionalLight3D.new()
	moonlight.rotation_degrees = Vector3(-48, -28, 0)
	moonlight.light_color = Color(0.42, 0.52, 0.68)
	moonlight.light_energy = 0.35
	moonlight.shadow_enabled = true
	add_child(moonlight)
