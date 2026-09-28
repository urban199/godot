extends Node3D

@export_enum("survivor", "zombie") var role := "survivor"

var moving := false
var sprinting := false
var animation_time := 0.0
var action_time := 0.0
var dying := false
var visual_root: Node3D
var visual_home_y := 0.0
var torso: Node3D
var head: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visual_root = Node3D.new()
	visual_root.name = "OriginalCharacter"
	# CharacterBody origins are centered in their capsule; lower the art to the floor.
	visual_root.scale = Vector3.ONE * (0.78 if role == "survivor" else 0.85)
	visual_root.position.y = -0.18 if role == "survivor" else -0.74
	visual_home_y = visual_root.position.y
	add_child(visual_root)
	if role == "survivor":
		torso = visual_root
		head = visual_root
		_build_survivor()
	else:
		_build_zombie()

func set_moving(value: bool, is_sprinting := false) -> void:
	moving = value
	sprinting = is_sprinting

func uses_imported_model() -> bool:
	return false

func play_action(animation_name: StringName, _return_to_locomotion := true) -> float:
	if animation_name == &"die":
		dying = true
		return 0.7
	if animation_name == &"holding-both-shoot":
		action_time = 0.24
		return action_time
	return 0.0

func _process(delta: float) -> void:
	if not is_instance_valid(visual_root):
		return
	action_time = maxf(action_time - delta, 0.0)
	animation_time += delta * (10.0 if sprinting else 7.0 if moving else 1.7)
	var stride := 0.52 if sprinting else 0.38 if moving else 0.025
	left_leg.rotation.x = sin(animation_time) * stride
	right_leg.rotation.x = sin(animation_time + PI) * stride
	if role == "survivor":
		var aim_pose := 0.92
		var recoil := 0.28 if action_time > 0.0 else 0.0
		left_arm.rotation.x = aim_pose + sin(animation_time + PI) * stride * 0.2 - recoil
		right_arm.rotation.x = aim_pose + sin(animation_time) * stride * 0.2 - recoil
	else:
		left_arm.rotation.x = 0.22 + sin(animation_time + PI) * (0.24 if moving else 0.04)
		right_arm.rotation.x = 0.22 + sin(animation_time) * (0.24 if moving else 0.04)
	if dying:
		visual_root.rotation.z = move_toward(visual_root.rotation.z, PI * 0.48, delta * 3.2)
		visual_root.position.y = move_toward(visual_root.position.y, -1.1, delta * 1.2)
	else:
		visual_root.position.y = visual_home_y + sin(animation_time * 2.0) * (0.018 if moving else 0.006)
		torso.rotation.z = sin(animation_time * 0.5) * (0.035 if moving else 0.012)
		head.rotation.y = sin(animation_time * 0.35) * 0.035

func _toon(color: Color, roughness := 0.72, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_TOON
	material.rim_enabled = true
	material.rim = 0.12
	material.rim_tint = 0.18
	return material

func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var material := _toon(color, 0.35, 0.0)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _mesh(mesh: Mesh, position: Vector3, material: Material, parent: Node3D, scale := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.scale = scale
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _box(size: Vector3, position: Vector3, material: Material, parent: Node3D, rotation := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := _mesh(mesh, position, material, parent)
	instance.rotation = rotation
	return instance

func _ellipsoid(position: Vector3, scale: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return _mesh(mesh, position, material, parent, scale)

func _capsule(radius: float, height: float, position: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	return _mesh(mesh, position, material, parent)

func _cylinder(top: float, bottom: float, height: float, position: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12
	return _mesh(mesh, position, material, parent)

func _build_survivor() -> void:
	var skin := _toon(Color(0.98, 0.78, 0.72), 0.82)
	var skin_shadow := _toon(Color(0.72, 0.40, 0.43), 0.9)
	var hair := _toon(Color(0.10, 0.48, 0.82), 0.34, 0.08)
	var hair_shadow := _toon(Color(0.035, 0.16, 0.40), 0.42)
	var hair_light := _toon(Color(0.40, 0.82, 1.0), 0.28, 0.12)
	var coat := _toon(Color(0.80, 0.86, 0.94), 0.78)
	var coat_shadow := _toon(Color(0.31, 0.40, 0.57), 0.82)
	var navy := _toon(Color(0.055, 0.10, 0.23), 0.62)
	var gold := _toon(Color(0.88, 0.61, 0.19), 0.3, 0.58)
	var red := _toon(Color(0.68, 0.045, 0.10), 0.42)
	var eye_white := _toon(Color(1.0, 0.96, 0.91), 0.3)
	var iris := _toon(Color(0.82, 0.10, 0.17), 0.27)
	var pupil := _toon(Color(0.12, 0.025, 0.055), 0.25)
	var boot := _toon(Color(0.045, 0.07, 0.13), 0.36, 0.12)

	# Long ice-blue hair, broad anime fringe and separated back locks.
	_ellipsoid(Vector3(0, 1.72, 0), Vector3(0.56, 0.60, 0.47), skin, visual_root)
	_ellipsoid(Vector3(0, 1.99, 0.06), Vector3(0.64, 0.32, 0.55), hair, visual_root)
	for i in range(5):
		var x := (float(i) - 2.0) * 0.19
		var lock := _capsule(0.105 if i % 2 == 0 else 0.085, 1.18 - absf(x) * 0.35, Vector3(x, 1.05, 0.17 + absf(x) * 0.12), hair if i % 2 == 0 else hair_shadow, visual_root)
		lock.rotation.z = x * 0.42
	for i in range(3):
		var x := (float(i) - 1.0) * 0.17
		var bang := _capsule(0.09, 0.43, Vector3(x, 1.88, -0.225), hair if i != 1 else hair_light, visual_root)
		bang.rotation.z = -x * 1.1
	_ellipsoid(Vector3(-0.31, 1.58, -0.015), Vector3(0.13, 0.36, 0.15), hair, visual_root)
	_ellipsoid(Vector3(0.31, 1.58, -0.015), Vector3(0.13, 0.36, 0.15), hair_shadow, visual_root)

	# Face: red eyes, bright catchlights, lashes and small mouth.
	for side in [-1.0, 1.0]:
		_ellipsoid(Vector3(side * 0.125, 1.75, -0.246), Vector3(0.12, 0.15, 0.045), eye_white, visual_root)
		_ellipsoid(Vector3(side * 0.125, 1.745, -0.283), Vector3(0.066, 0.105, 0.025), iris, visual_root)
		_ellipsoid(Vector3(side * 0.125, 1.74, -0.305), Vector3(0.031, 0.072, 0.018), pupil, visual_root)
		_ellipsoid(Vector3(side * 0.105, 1.79, -0.322), Vector3(0.024, 0.028, 0.012), eye_white, visual_root)
		_box(Vector3(0.17, 0.025, 0.025), Vector3(side * 0.125, 1.835, -0.28), hair_shadow, visual_root, Vector3(0, 0, side * -0.12))
	_box(Vector3(0.09, 0.018, 0.018), Vector3(0, 1.62, -0.285), skin_shadow, visual_root)

	# High-collar officer coat, dark skirt, gold piping and a red neck ribbon.
	_capsule(0.31, 0.78, Vector3(0, 1.03, 0), coat, visual_root)
	_box(Vector3(0.17, 0.78, 0.11), Vector3(-0.145, 0.98, -0.255), coat_shadow, visual_root, Vector3(0, 0, -0.12))
	_box(Vector3(0.17, 0.78, 0.11), Vector3(0.145, 0.98, -0.255), coat_shadow, visual_root, Vector3(0, 0, 0.12))
	_cylinder(0.24, 0.43, 0.48, Vector3(0, 0.61, 0), navy, visual_root)
	_box(Vector3(0.54, 0.055, 0.38), Vector3(0, 0.78, -0.02), gold, visual_root)
	_box(Vector3(0.11, 0.22, 0.07), Vector3(0, 1.37, -0.29), red, visual_root)
	_box(Vector3(0.10, 0.14, 0.08), Vector3(0, 1.24, -0.30), gold, visual_root)
	_capsule(0.16, 0.24, Vector3(0, 1.46, 0), coat, visual_root)
	for y in [1.10, 0.96, 0.82]:
		_ellipsoid(Vector3(0, y, -0.31), Vector3(0.055, 0.055, 0.035), gold, visual_root)
	for side in [-1.0, 1.0]:
		_box(Vector3(0.18, 0.12, 0.30), Vector3(side * 0.34, 1.29, 0), coat_shadow, visual_root)
		_box(Vector3(0.13, 0.16, 0.035), Vector3(side * 0.22, 0.88, -0.23), gold, visual_root)

	# Articulated sleeves, cuffs, gloves, long legs and polished boots.
	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.36, 1.24, 0)
	visual_root.add_child(left_arm)
	_capsule(0.115, 0.58, Vector3(0, -0.24, 0), coat, left_arm)
	_capsule(0.12, 0.18, Vector3(0, -0.51, -0.015), coat_shadow, left_arm)
	_capsule(0.095, 0.18, Vector3(0, -0.64, -0.025), skin, left_arm)
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.36, 1.24, 0)
	visual_root.add_child(right_arm)
	_capsule(0.115, 0.58, Vector3(0, -0.24, 0), coat, right_arm)
	_capsule(0.12, 0.18, Vector3(0, -0.51, -0.015), coat_shadow, right_arm)
	_capsule(0.095, 0.18, Vector3(0, -0.64, -0.025), skin, right_arm)
	left_leg = Node3D.new()
	left_leg.position = Vector3(-0.15, 0.48, 0)
	visual_root.add_child(left_leg)
	_capsule(0.12, 0.57, Vector3(0, -0.29, 0), navy, left_leg)
	_capsule(0.145, 0.43, Vector3(0, -0.74, -0.045), boot, left_leg)
	_box(Vector3(0.24, 0.13, 0.34), Vector3(0, -0.91, -0.12), boot, left_leg)
	right_leg = Node3D.new()
	right_leg.position = Vector3(0.15, 0.48, 0)
	visual_root.add_child(right_leg)
	_capsule(0.12, 0.57, Vector3(0, -0.29, 0), navy, right_leg)
	_capsule(0.145, 0.43, Vector3(0, -0.74, -0.045), boot, right_leg)
	_box(Vector3(0.24, 0.13, 0.34), Vector3(0, -0.91, -0.12), boot, right_leg)

func _build_zombie() -> void:
	head = visual_root
	var skin := _toon(Color(0.43, 0.57, 0.43), 0.95)
	var wound := _toon(Color(0.23, 0.035, 0.045), 0.7)
	var shirt := _toon(Color(0.20, 0.24, 0.20), 0.95)
	var pants := _toon(Color(0.10, 0.13, 0.12), 0.9)
	var eye := _glow(Color(0.92, 0.20, 0.045), 1.8)
	var hair := _toon(Color(0.12, 0.16, 0.12), 0.9)
	torso = Node3D.new()
	torso.position = Vector3(0, 1.02, 0)
	visual_root.add_child(torso)
	_capsule(0.31, 0.78, Vector3.ZERO, shirt, torso)
	_box(Vector3(0.18, 0.24, 0.035), Vector3(-0.12, 0.08, -0.29), wound, torso, Vector3(0, 0, -0.3))
	_capsule(0.24, 0.32, Vector3(0, 1.48 - 1.02, 0), skin, torso)
	_ellipsoid(Vector3(0, 1.96 - 1.02, 0.04), Vector3(0.52, 0.22, 0.48), hair, torso)
	for side in [-1.0, 1.0]:
		_ellipsoid(Vector3(side * 0.115, 1.49 - 1.02, -0.215), Vector3(0.065, 0.07, 0.03), eye, torso)
		_ellipsoid(Vector3(side * 0.22, 1.34 - 1.02, -0.02), Vector3(0.08, 0.12, 0.06), wound, torso)

	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.36, 1.24, 0)
	visual_root.add_child(left_arm)
	_capsule(0.14, 0.68, Vector3(0, -0.28, 0), shirt, left_arm)
	_capsule(0.12, 0.24, Vector3(0, -0.68, -0.04), skin, left_arm)
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.36, 1.24, 0)
	visual_root.add_child(right_arm)
	_capsule(0.14, 0.68, Vector3(0, -0.28, 0), shirt, right_arm)
	_capsule(0.12, 0.24, Vector3(0, -0.68, -0.04), skin, right_arm)
	left_leg = Node3D.new()
	left_leg.position = Vector3(-0.16, 0.67, 0)
	visual_root.add_child(left_leg)
	_capsule(0.15, 0.66, Vector3(0, -0.33, 0), pants, left_leg)
	_capsule(0.16, 0.28, Vector3(0, -0.72, -0.08), wound, left_leg)
	right_leg = Node3D.new()
	right_leg.position = Vector3(0.16, 0.67, 0)
	visual_root.add_child(right_leg)
	_capsule(0.15, 0.66, Vector3(0, -0.33, 0), pants, right_leg)
	_capsule(0.16, 0.28, Vector3(0, -0.72, -0.08), wound, right_leg)
