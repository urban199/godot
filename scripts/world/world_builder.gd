extends Node3D

const PickupScript = preload("res://scripts/interactables/pickup.gd")
const GeneratorScript = preload("res://scripts/interactables/generator.gd")
const TerminalScript = preload("res://scripts/interactables/terminal.gd")
const DoorScript = preload("res://scripts/interactables/door.gd")
const StalkerScript = preload("res://scripts/enemies/stalker.gd")
const CheckpointScript = preload("res://scripts/world/checkpoint.gd")
const HidingSpotScript = preload("res://scripts/interactables/hiding_spot.gd")
const HorrorTriggerScript = preload("res://scripts/world/horror_trigger.gd")
const NavigationGraphScript = preload("res://scripts/world/navigation_graph.gd")
const MapDiscoveryScript = preload("res://scripts/world/map_discovery.gd")

var concrete: StandardMaterial3D
var metal: StandardMaterial3D
var ground: StandardMaterial3D
var rust: StandardMaterial3D
var _weather_rng := RandomNumberGenerator.new()
var _lightning: DirectionalLight3D
var _lightning_timer := 10.0
var _lightning_duration := 0.0

func _ready() -> void:
	_weather_rng.randomize()
	concrete = _material(Color(0.17, 0.2, 0.2), 0.85)
	metal = _material(Color(0.12, 0.15, 0.16), 0.65, 0.35)
	ground = _material(Color(0.035, 0.055, 0.052), 0.2)
	rust = _material(Color(0.31, 0.14, 0.075), 0.7, 0.25)
	_build_ground()
	_build_navigation()
	_build_entrance()
	_build_administration()
	_build_corridor()
	_build_service_room()
	_add_terminal(Vector3(2.7, 1.1, -14.8))
	_build_laboratory()
	_build_hiding_spot()
	_build_horror_trigger()
	_add_checkpoint("laboratory", Vector3(8.0, 0.8, -20.5), Vector3(3.0, 1.8, 1.5))
	_add_discovery_zone("corridor", Vector3(0, 1.0, -23.5), Vector3(6.0, 2.0, 4.0))
	_build_forest()
	_build_rain()
	_build_lightning()
	_build_enemy()

func _process(delta: float) -> void:
	_lightning_timer -= delta
	if _lightning_timer <= 0.0 and _lightning_duration <= 0.0:
		_lightning_duration = 0.16
		_lightning_timer = _weather_rng.randf_range(11.0, 24.0)
		var effects_quality := str(SettingsManager.get_value("effects_quality", "medium"))
		_lightning.light_energy = 0.85 if effects_quality == "low" else (2.2 if effects_quality == "high" else 1.5)
		AudioManager.play_thunder()
	elif _lightning_duration > 0.0:
		_lightning_duration -= delta
		if _lightning_duration <= 0.0:
			_lightning.light_energy = 0.0

func _build_ground() -> void:
	_box("Wet ground", Vector3(0, -0.35, -4), Vector3(56, 0.6, 64), ground)

func _build_entrance() -> void:
	_box("Entry left wall", Vector3(-4.5, 1.5, -5), Vector3(1, 3, 12), concrete)
	_box("Entry right upper", Vector3(4.5, 1.5, -0.15), Vector3(1, 3, 2.3), concrete)
	_box("Entry right lower", Vector3(4.5, 1.5, -7.35), Vector3(1, 3, 7.3), concrete)
	_box("Entry ceiling", Vector3(0, 3.2, -5), Vector3(9, 0.4, 12), concrete)
	_box("Warning stripe", Vector3(0, 0.02, -3), Vector3(7, 0.025, 0.12), rust, false)
	_add_pickup("Access card", Vector3(-1.7, 0.65, 1), "keycard", "Staff access card", metal)
	_add_pickup("Battery", Vector3(2.3, 0.45, -1), "battery", "Flashlight battery", rust)
	_box("Service doorway left jamb", Vector3(-3.1, 1.5, -11.5), Vector3(2.8, 3, 0.5), concrete)
	_box("Service doorway right jamb", Vector3(3.1, 1.5, -11.5), Vector3(2.8, 3, 0.5), concrete)
	_box("Service doorway header", Vector3(0, 2.7, -11.5), Vector3(2.5, 0.6, 0.5), concrete)
	_add_door("Service door", Vector3(0, 1.2, -11.5), Vector3(2.4, 2.4, 0.22), false, false, true)
	_add_door("Administration door", Vector3(4.5, 1.2, -2.5), Vector3(1.8, 2.4, 0.22), false, false, false, "administration", deg_to_rad(90))

func _build_administration() -> void:
	_box("Administration outer wall", Vector3(12, 1.5, -5.5), Vector3(0.5, 3, 9), concrete)
	_box("Administration back wall", Vector3(8.25, 1.5, -10), Vector3(8, 3, 0.5), concrete)
	_box("Administration front wall", Vector3(8.25, 1.5, -1), Vector3(8, 3, 0.5), concrete)
	_box("Administration ceiling", Vector3(8.25, 3.2, -5.5), Vector3(8, 0.4, 9), concrete)
	_box("Administration desk", Vector3(8.4, 0.62, -4.2), Vector3(2.2, 0.35, 1.0), metal)
	_box("Filing cabinet", Vector3(10.7, 1.0, -8.2), Vector3(0.8, 2.0, 0.7), rust)
	_add_pickup("Staff memo", Vector3(8.3, 0.88, -4.2), "note", "Staff memo", metal)
	_add_sign("ADMINISTRATION  /  STAFF ONLY", Vector3(8.2, 2.35, -1.27))

func _build_corridor() -> void:
	_box("Corridor left upper", Vector3(-3.5, 1.5, -12.25), Vector3(1, 3, 3.5), concrete)
	_box("Corridor left lower", Vector3(-3.5, 1.5, -22.25), Vector3(1, 3, 10.5), concrete)
	_box("Corridor right upper", Vector3(3.5, 1.5, -12.25), Vector3(1, 3, 3.5), concrete)
	_box("Corridor right lower", Vector3(3.5, 1.5, -22.25), Vector3(1, 3, 10.5), concrete)
	_box("Corridor roof", Vector3(0, 3.2, -19), Vector3(7, 0.4, 17), concrete)
	_box("Exit left wall", Vector3(-2.35, 1.5, -27.5), Vector3(2.3, 3, 0.5), concrete)
	_box("Exit right wall", Vector3(2.35, 1.5, -27.5), Vector3(2.3, 3, 0.5), concrete)
	_box("Exit header", Vector3(0, 2.75, -27.5), Vector3(2.4, 0.5, 0.5), concrete)
	_box("Exit hazard stripe left", Vector3(-1.6, 0.025, -24.7), Vector3(0.16, 0.03, 2.0), rust, false)
	_box("Exit hazard stripe right", Vector3(1.6, 0.025, -24.7), Vector3(0.16, 0.03, 2.0), rust, false)
	_add_door("Exit door", Vector3(0, 1.2, -27.2), Vector3(2.4, 2.4, 0.22), true, true, false)
	for index in range(4):
		var light := OmniLight3D.new()
		light.position = Vector3(0, 2.8, -13.5 - float(index) * 3.4)
		light.light_color = Color(0.36, 0.48, 0.52)
		light.light_energy = 0.28
		light.add_to_group("facility_lights")
		light.omni_range = 4.2
		add_child(light)

func _build_service_room() -> void:
	# The open doorway on the left of the corridor leads into the generator bay.
	_box("Generator room outer wall", Vector3(-8, 1.5, -17), Vector3(0.5, 3, 10), concrete)
	_box("Generator room rear wall", Vector3(-5.8, 1.5, -22), Vector3(4.5, 3, 0.5), concrete)
	_box("Generator", Vector3(-6.8, 0.8, -17), Vector3(1.4, 1.6, 1.5), rust)
	_add_generator(Vector3(-5.8, 1.0, -17))
	_add_pickup("Research note 04", Vector3(-6.8, 0.4, -14.8), "note", "Research log", rust)
	_add_checkpoint()
	_add_sign("GENERATOR ROOM  /  RESTORE POWER", Vector3(-5.8, 2.35, -21.7))

func _build_laboratory() -> void:
	# An open bay off the main corridor expands the route through research spaces.
	_box("Laboratory outer wall", Vector3(12, 1.5, -17), Vector3(0.5, 3, 10), concrete)
	_box("Laboratory rear wall", Vector3(7.75, 1.5, -22), Vector3(8, 3, 0.5), concrete)
	_box("Laboratory ceiling", Vector3(7.75, 3.2, -17), Vector3(8, 0.4, 10), concrete)
	_box("Lab workbench", Vector3(9.8, 0.65, -17.2), Vector3(2.5, 0.35, 1.2), metal)
	_box("Lab cabinet", Vector3(10.6, 1.2, -19.8), Vector3(0.9, 2.4, 0.65), rust)
	_add_pickup("Research note 05", Vector3(9.5, 0.9, -17.2), "note", "Research log", metal)
	_add_pickup("Emergency medkit", Vector3(8.5, 0.5, -19.8), "medkit", "Emergency medkit", rust)
	_add_sign("RESEARCH LAB  /  LEVEL 02", Vector3(7.75, 2.35, -21.7))
	var lab_light := OmniLight3D.new()
	lab_light.name = "LaboratoryFixture"
	lab_light.position = Vector3(7.0, 2.7, -17.0)
	lab_light.light_color = Color(0.52, 0.62, 0.58)
	lab_light.light_energy = 0.45
	lab_light.omni_range = 6.0
	lab_light.add_to_group("facility_lights")
	add_child(lab_light)

func _build_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8301
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.48
	trunk_mesh.height = 2.0
	var trunk_material := _material(Color(0.11, 0.09, 0.075), 0.95)
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = 1.0
	canopy_mesh.height = 1.7
	var canopy_material := _material(Color(0.025, 0.075, 0.055), 1.0)
	var trunks := MultiMesh.new()
	trunks.transform_format = MultiMesh.TRANSFORM_3D
	trunks.mesh = trunk_mesh
	var canopies := MultiMesh.new()
	canopies.transform_format = MultiMesh.TRANSFORM_3D
	canopies.mesh = canopy_mesh
	var tree_data: Array[Dictionary] = []
	for index in range(38):
		var x := rng.randf_range(-24, 24)
		var z := rng.randf_range(-30, 20)
		if absf(x) < 7 and z > -12:
			continue
		var trunk_scale := rng.randf_range(0.8, 1.25)
		var canopy_scale := rng.randf_range(1.6, 2.8)
		var trunk_transform := Transform3D(Basis.from_scale(Vector3(trunk_scale, 2.2, trunk_scale)), Vector3(x, 2.2, z))
		var canopy_transform := Transform3D(Basis.from_scale(Vector3(canopy_scale, canopy_scale, canopy_scale)), Vector3(x, 5.1, z))
		tree_data.append({"trunk": trunk_transform, "canopy": canopy_transform, "x": x, "z": z, "scale": trunk_scale})
	trunks.instance_count = tree_data.size()
	canopies.instance_count = tree_data.size()
	for index in range(tree_data.size()):
		trunks.set_instance_transform(index, tree_data[index].trunk)
		canopies.set_instance_transform(index, tree_data[index].canopy)
	var trunk_instances := MultiMeshInstance3D.new()
	trunk_instances.name = "ForestTrunks"
	trunk_instances.multimesh = trunks
	trunk_instances.material_override = trunk_material
	add_child(trunk_instances)
	var canopy_instances := MultiMeshInstance3D.new()
	canopy_instances.name = "ForestCanopies"
	canopy_instances.multimesh = canopies
	canopy_instances.material_override = canopy_material
	add_child(canopy_instances)
	for tree in tree_data:
		var obstacle := StaticBody3D.new()
		obstacle.position = Vector3(tree.x, 2.2, tree.z)
		var trunk_shape := CylinderShape3D.new()
		trunk_shape.radius = 0.48 * tree.scale
		trunk_shape.height = 4.4
		var trunk_collision := CollisionShape3D.new()
		trunk_collision.shape = trunk_shape
		obstacle.add_child(trunk_collision)
		add_child(obstacle)

func _build_navigation() -> void:
	var navigation := Node.new()
	navigation.name = "NavigationGraph"
	navigation.set_script(NavigationGraphScript)
	add_child(navigation)

func _build_hiding_spot() -> void:
	var locker := StaticBody3D.new()
	locker.name = "LaboratoryLocker"
	locker.position = Vector3(10.8, 1.0, -7.0)
	locker.set_script(HidingSpotScript)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.85, 2.0, 0.8)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	locker.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	mesh.material_override = rust
	locker.add_child(mesh)
	add_child(locker)

func _build_horror_trigger() -> void:
	var trigger := Area3D.new()
	trigger.name = "LaboratoryHorrorEvent"
	trigger.position = Vector3(6.0, 1.0, -17.0)
	trigger.set_script(HorrorTriggerScript)
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.0, 2.0)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	trigger.add_child(collision)
	add_child(trigger)

func _build_rain() -> void:
	var rain := GPUParticles3D.new()
	rain.name = "Rain"
	rain.position = Vector3(0, 8, -4)
	rain.amount = 500
	rain.lifetime = 1.8
	rain.visibility_aabb = AABB(Vector3(-28, -9, -32), Vector3(56, 20, 60))
	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.02, -1, 0)
	process_material.initial_velocity_min = 15.0
	process_material.initial_velocity_max = 21.0
	process_material.gravity = Vector3(0, -5, 0)
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(28, 0.2, 30)
	rain.process_material = process_material
	var drop := QuadMesh.new()
	drop.size = Vector2(0.025, 0.32)
	drop.material = _material(Color(0.5, 0.64, 0.75, 0.55), 0.25)
	rain.draw_pass_1 = drop
	add_child(rain)
	rain.emitting = true

func _build_lightning() -> void:
	_lightning = DirectionalLight3D.new()
	_lightning.name = "StormFlash"
	_lightning.rotation_degrees = Vector3(-58, 18, 0)
	_lightning.light_color = Color(0.72, 0.8, 0.95)
	_lightning.light_energy = 0.0
	_lightning.shadow_enabled = false
	add_child(_lightning)

func _build_enemy() -> void:
	var enemy := CharacterBody3D.new()
	enemy.name = "Stalker"
	enemy.position = Vector3(0, 0.9, -22)
	enemy.set_script(StalkerScript)
	enemy.set("patrol_points", [Vector3(0, 0, -18), Vector3(0, 0, -25)])
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.9
	enemy.add_child(collision)
	var visual := Node3D.new()
	visual.name = "VisualBody"
	visual.position.y = 0.9
	enemy.add_child(visual)
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.42
	mesh.height = 1.8
	body.mesh = mesh
	body.material_override = _material(Color(0.12, 0.025, 0.03), 0.95)
	visual.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.27
	head_mesh.height = 0.52
	head.mesh = head_mesh
	head.position.y = 0.94
	head.material_override = body.material_override
	visual.add_child(head)
	for side in [-1, 1]:
		var arm := MeshInstance3D.new()
		arm.name = "ArmLeft" if side < 0 else "ArmRight"
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.12
		arm_mesh.height = 1.0
		arm.mesh = arm_mesh
		arm.position = Vector3(float(side) * 0.43, -0.04, 0)
		arm.rotation.z = deg_to_rad(float(side) * 13.0)
		arm.material_override = body.material_override
		visual.add_child(arm)
	var eye_material := _material(Color(0.62, 0.035, 0.025), 0.35, 0.0)
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.045
		eye_mesh.height = 0.09
		eye.mesh = eye_mesh
		eye.position = Vector3(float(side) * 0.1, 1.0, -0.225)
		eye.material_override = eye_material
		visual.add_child(eye)
	add_child(enemy)

func _add_pickup(label: String, location: Vector3, kind: String, prompt_name: String, surface: Material) -> void:
	var item := StaticBody3D.new()
	item.name = label
	item.position = location
	item.set_script(PickupScript)
	item.set("item_type", kind)
	item.set("display_name", prompt_name)
	if kind == "note":
		item.set("note_id", label.to_snake_case())
		var note_text := "STAFF MEMO: Keep the west service door secured."
		if label == "Research note 04":
			note_text = "RESEARCH LOG 04: The power failure was deliberate. Do not open the lower wing."
		elif label == "Research note 05":
			note_text = "RESEARCH LOG 05: The generator can power the service exit. Do not approach the lower wing."
		item.set("note_text", note_text)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.45, 0.16, 0.32)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	item.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	mesh.material_override = surface
	item.add_child(mesh)
	add_child(item)

func _add_generator(location: Vector3) -> void:
	var generator := StaticBody3D.new()
	generator.name = "GeneratorControls"
	generator.position = location
	generator.set_script(GeneratorScript)
	generator.set("is_active", Objectives.completed.has("restore_power"))
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.65, 0.55, 0.5)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	generator.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	mesh.material_override = metal
	generator.add_child(mesh)
	add_child(generator)

func _add_checkpoint(checkpoint_id := "service_corridor", location := Vector3(0, 0.8, -17.5), bounds := Vector3(5.5, 1.8, 1.0)) -> void:
	var checkpoint := Area3D.new()
	checkpoint.name = "%sCheckpoint" % checkpoint_id.capitalize()
	checkpoint.position = location
	checkpoint.set_script(CheckpointScript)
	checkpoint.set("checkpoint_id", checkpoint_id)
	var shape := BoxShape3D.new()
	shape.size = bounds
	var collision := CollisionShape3D.new()
	collision.shape = shape
	checkpoint.add_child(collision)
	add_child(checkpoint)

func _add_discovery_zone(area_id: String, location: Vector3, bounds: Vector3) -> void:
	var zone := Area3D.new()
	zone.name = "%sDiscovery" % area_id.capitalize()
	zone.position = location
	zone.set_script(MapDiscoveryScript)
	zone.set("area_id", area_id)
	var shape := BoxShape3D.new()
	shape.size = bounds
	var collision := CollisionShape3D.new()
	collision.shape = shape
	zone.add_child(collision)
	add_child(zone)

func _add_sign(text: String, location: Vector3) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "FacilitySign"
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(2.4, 0.55, 0.1)
	panel.mesh = panel_mesh
	panel.position = location
	panel.material_override = metal
	add_child(panel)
	var lettering := Label3D.new()
	lettering.name = "SignLettering"
	lettering.text = text
	lettering.position = location + Vector3(0, 0, 0.06)
	lettering.font_size = 28
	lettering.pixel_size = 0.004
	lettering.modulate = Color(0.8, 0.69, 0.43)
	lettering.outline_size = 5
	lettering.outline_modulate = Color(0.025, 0.035, 0.036)
	add_child(lettering)

func _add_terminal(location: Vector3) -> void:
	var terminal := StaticBody3D.new()
	terminal.name = "FacilityTerminal"
	terminal.position = location
	terminal.set_script(TerminalScript)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.55, 0.8, 0.3)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	terminal.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	mesh.mesh = box
	mesh.material_override = metal
	terminal.add_child(mesh)
	add_child(terminal)

func _add_door(label: String, location: Vector3, size: Vector3, needs_power: bool, is_exit: bool, needs_keycard: bool, discovery_area := "", initial_rotation := 0.0) -> void:
	var door := StaticBody3D.new()
	door.name = label
	door.position = location
	door.set_script(DoorScript)
	door.set("requires_power", needs_power)
	door.set("requires_keycard", needs_keycard)
	door.set("exit_door", is_exit)
	door.set("discovery_area", discovery_area)
	door.rotation.y = initial_rotation
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	door.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = metal
	door.add_child(mesh)
	add_child(door)

func _box(label: String, location: Vector3, size: Vector3, surface: Material, solid := true) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = location
	mesh_instance.material_override = surface
	add_child(mesh_instance)
	if solid:
		var body := StaticBody3D.new()
		body.name = "%sCollision" % label
		body.position = location
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)

func _material(color: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
