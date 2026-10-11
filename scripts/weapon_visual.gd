extends Node3D

@onready var slide: MeshInstance3D = $Slide
@onready var grip: MeshInstance3D = $Grip
@onready var barrel: MeshInstance3D = $Barrel

var muzzle_flash: MeshInstance3D
var muzzle_light: OmniLight3D

func _ready() -> void:
	var steel := _material(Color(0.105, 0.125, 0.15), 0.32, 0.82)
	var polymer := _material(Color(0.055, 0.068, 0.078), 0.76, 0.0)
	var grip_material := _material(Color(0.095, 0.065, 0.052), 0.91, 0.0)
	var dark_steel := _material(Color(0.025, 0.032, 0.04), 0.48, 0.66)
	var sight_material := _material(Color(0.84, 0.20, 0.075), 0.42, 0.08)
	var brass := _material(Color(0.63, 0.39, 0.12), 0.28, 0.76)
	var steel_edge := _material(Color(0.36, 0.39, 0.41), 0.24, 0.9)

	slide.material_override = steel
	grip.material_override = grip_material
	barrel.material_override = dark_steel
	_box("PolymerFrame", Vector3(0.205, 0.18, 0.56), Vector3(0, -0.055, 0.075), polymer)
	_box("DustCoverRail", Vector3(0.15, 0.055, 0.26), Vector3(0, -0.13, -0.18), dark_steel)
	_box("MagazineBase", Vector3(0.18, 0.055, 0.19), Vector3(0, -0.245, 0.18), steel)
	_box("MagazineRelease", Vector3(0.035, 0.075, 0.065), Vector3(0.112, -0.105, 0.17), steel_edge)
	_box("SlideEjectionPort", Vector3(0.014, 0.065, 0.17), Vector3(0.093, 0.102, -0.03), dark_steel)
	_box("FrontSight", Vector3(0.045, 0.045, 0.06), Vector3(0, 0.17, -0.30), steel_edge)
	_box("RearSightLeft", Vector3(0.035, 0.07, 0.065), Vector3(-0.066, 0.16, 0.27), steel_edge)
	_box("RearSightRight", Vector3(0.035, 0.07, 0.065), Vector3(0.066, 0.16, 0.27), steel_edge)
	_box("FrontSightDot", Vector3(0.018, 0.018, 0.012), Vector3(0, 0.195, -0.326), sight_material)
	for side in [-1.0, 1.0]:
		for groove in range(5):
			_box("SlideSerration_%d_%d" % [int(side), groove], Vector3(0.012, 0.11, 0.025), Vector3(side * 0.096, 0.075, 0.16 + groove * 0.035), dark_steel)
		_box("GripPanel_%d" % int(side), Vector3(0.012, 0.20, 0.22), Vector3(side * 0.086, -0.105, 0.19), polymer)
		_box("FramePin_%d" % int(side), Vector3(0.014, 0.028, 0.028), Vector3(side * 0.108, -0.035, 0.08), steel_edge)
	_box("TriggerGuardTop", Vector3(0.13, 0.025, 0.035), Vector3(0, -0.145, 0.015), steel)
	_box("TriggerGuardFront", Vector3(0.025, 0.11, 0.035), Vector3(0, -0.195, -0.045), steel)
	_box("Trigger", Vector3(0.018, 0.075, 0.025), Vector3(0, -0.19, 0.015), brass, Vector3(-0.18, 0, 0))
	_box("SlideStop", Vector3(0.022, 0.055, 0.10), Vector3(0.11, -0.025, 0.11), steel_edge)
	_box("SafetyMark", Vector3(0.012, 0.018, 0.05), Vector3(-0.108, 0.035, 0.08), sight_material)
	_make_muzzle_effect()

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _box(part_name: String, size: Vector3, position: Vector3, material: Material, rotation := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	add_child(instance)
	return instance

func _make_muzzle_effect() -> void:
	var flash_material := StandardMaterial3D.new()
	flash_material.albedo_color = Color(1.0, 0.52, 0.12, 1.0)
	flash_material.emission_enabled = true
	flash_material.emission = Color(1.0, 0.24, 0.035, 1.0)
	flash_material.emission_energy_multiplier = 3.2
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.name = "MuzzleFlash"
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.5
	flash_mesh.height = 1.0
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.material_override = flash_material
	muzzle_flash.position = Vector3(0, 0.08, -0.62)
	muzzle_flash.scale = Vector3(0.13, 0.13, 0.34)
	muzzle_flash.visible = false
	add_child(muzzle_flash)
	muzzle_light = OmniLight3D.new()
	muzzle_light.name = "MuzzleFlashLight"
	muzzle_light.light_color = Color(1.0, 0.42, 0.12)
	muzzle_light.light_energy = 2.6
	muzzle_light.omni_range = 3.0
	muzzle_light.shadow_enabled = false
	muzzle_light.position = muzzle_flash.position
	muzzle_light.visible = false
	add_child(muzzle_light)

func fire_effect() -> void:
	muzzle_flash.visible = true
	muzzle_light.visible = true
	await get_tree().create_timer(0.055).timeout
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = false
		muzzle_light.visible = false
