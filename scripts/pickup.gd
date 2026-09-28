extends Area3D

@export_enum("ammo", "medkit") var kind := "ammo"

var visual_root: Node3D
var float_time := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var placeholder := get_node_or_null("Mesh") as MeshInstance3D
	if placeholder:
		placeholder.visible = false
	visual_root = Node3D.new()
	visual_root.name = "OriginalPickupVisual"
	add_child(visual_root)
	if kind == "ammo":
		_build_ammo_box()
	else:
		_build_medkit()

func _process(delta: float) -> void:
	if not is_instance_valid(visual_root):
		return
	float_time += delta
	visual_root.position.y = sin(float_time * 2.2) * 0.075
	visual_root.rotation.y = sin(float_time * 0.8) * 0.12

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().current_scene.collect_pickup(kind)
		queue_free()

func _material(color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _box(part_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.position = position
	visual_root.add_child(instance)
	return instance

func _cylinder(part_name: String, top_radius: float, bottom_radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.material = material
	instance.mesh = mesh
	instance.position = position
	visual_root.add_child(instance)
	return instance

func _build_ammo_box() -> void:
	var casing := _material(Color(0.12, 0.17, 0.12), 0.83)
	var lid := _material(Color(0.19, 0.24, 0.16), 0.68)
	var brass := _material(Color(0.72, 0.47, 0.16), 0.27, 0.78)
	var copper := _material(Color(0.46, 0.16, 0.075), 0.31, 0.72)
	var dark := _material(Color(0.045, 0.055, 0.047), 0.74)
	_box("AmmoCase", Vector3(0.48, 0.25, 0.34), Vector3.ZERO, casing)
	_box("RaisedLid", Vector3(0.45, 0.055, 0.32), Vector3(0, 0.145, 0), lid)
	_box("FrontLabelBand", Vector3(0.31, 0.07, 0.016), Vector3(0, 0.015, -0.18), brass)
	_box("TopLabelBand", Vector3(0.31, 0.016, 0.08), Vector3(0, 0.176, -0.08), brass)
	_box("CaseLatch", Vector3(0.085, 0.095, 0.025), Vector3(0, -0.015, -0.19), dark)
	for side in [-1.0, 1.0]:
		_box("CaseRidge_%d" % int(side), Vector3(0.025, 0.19, 0.018), Vector3(side * 0.205, 0, -0.18), lid)
	for i in range(6):
		var x := (float(i) - 2.5) * 0.065
		_cylinder("BrassCartridge_%d" % i, 0.022, 0.022, 0.12, Vector3(x, 0.245, 0.035), brass)
		_cylinder("CopperBullet_%d" % i, 0.003, 0.022, 0.055, Vector3(x, 0.332, 0.035), copper)

func _build_medkit() -> void:
	var case_white := _material(Color(0.83, 0.84, 0.79), 0.68)
	var edge_white := _material(Color(0.61, 0.65, 0.63), 0.76)
	var emergency_red := _material(Color(0.72, 0.045, 0.07), 0.42)
	var handle_dark := _material(Color(0.085, 0.10, 0.11), 0.62, 0.16)
	var clasp_metal := _material(Color(0.48, 0.51, 0.50), 0.28, 0.82)
	_box("MedicalCase", Vector3(0.52, 0.34, 0.40), Vector3.ZERO, case_white)
	_box("LidSeam", Vector3(0.53, 0.035, 0.41), Vector3(0, 0.105, 0), edge_white)
	_box("FrontCrossVertical", Vector3(0.085, 0.23, 0.025), Vector3(0, 0.005, -0.208), emergency_red)
	_box("FrontCrossHorizontal", Vector3(0.25, 0.085, 0.025), Vector3(0, 0.005, -0.21), emergency_red)
	_box("TopCrossVertical", Vector3(0.085, 0.02, 0.24), Vector3(0, 0.18, 0), emergency_red)
	_box("TopCrossHorizontal", Vector3(0.26, 0.02, 0.085), Vector3(0, 0.18, 0), emergency_red)
	_box("CarryHandleBase", Vector3(0.24, 0.055, 0.10), Vector3(0, 0.195, 0.06), handle_dark)
	_box("FrontClasp", Vector3(0.09, 0.10, 0.028), Vector3(0, -0.08, -0.216), clasp_metal)
	for side in [-1.0, 1.0]:
		_box("SideRedBand_%d" % int(side), Vector3(0.018, 0.08, 0.32), Vector3(side * 0.267, -0.025, 0), emergency_red)
