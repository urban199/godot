extends Node3D

@export_enum("survivor", "zombie") var role := "survivor"

var moving := false
var animation_time := 0.0
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: MeshInstance3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_humanoid()

func set_moving(value: bool) -> void:
    moving = value

func _material(color: Color, roughness := 0.7) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    return material

func _part(mesh: Mesh, position: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.mesh = mesh
    instance.position = position
    instance.material_override = material
    (self if parent == null else parent).add_child(instance)
    return instance

func _capsule(radius: float, height: float, position: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    return _part(mesh, position, material, parent)

func _build_humanoid() -> void:
    var is_zombie := role == "zombie"
    var skin := _material(Color(0.72, 0.38, 0.27) if not is_zombie else Color(0.34, 0.52, 0.32))
    var jacket := _material(Color(0.08, 0.18, 0.32) if not is_zombie else Color(0.12, 0.20, 0.15))
    var shirt := _material(Color(0.72, 0.78, 0.82) if not is_zombie else Color(0.26, 0.30, 0.26))
    var pants := _material(Color(0.08, 0.10, 0.14) if not is_zombie else Color(0.16, 0.18, 0.14))
    var boots := _material(Color(0.035, 0.028, 0.025), 0.9)
    var hair := _material(Color(0.025, 0.018, 0.014), 0.95)

    var torso_mesh := CapsuleMesh.new()
    torso_mesh.radius = 0.30
    torso_mesh.height = 0.78
    torso = _part(torso_mesh, Vector3(0, 1.02, 0), jacket)
    _capsule(0.24, 0.32, Vector3(0, 1.48, 0), shirt)

    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.25
    head_mesh.height = 0.5
    _part(head_mesh, Vector3(0, 1.72, 0), skin)
    var hair_mesh := SphereMesh.new()
    hair_mesh.radius = 0.26
    hair_mesh.height = 0.25
    _part(hair_mesh, Vector3(0, 1.91, -0.015), hair)

    left_arm = Node3D.new()
    left_arm.position = Vector3(-0.34, 1.27, 0)
    add_child(left_arm)
    _capsule(0.11, 0.58, Vector3(0, -0.25, 0), jacket, left_arm)
    right_arm = Node3D.new()
    right_arm.position = Vector3(0.34, 1.27, 0)
    add_child(right_arm)
    _capsule(0.11, 0.58, Vector3(0, -0.25, 0), jacket, right_arm)

    left_leg = Node3D.new()
    left_leg.position = Vector3(-0.16, 0.70, 0)
    add_child(left_leg)
    _capsule(0.13, 0.65, Vector3(0, -0.34, 0), pants, left_leg)
    _capsule(0.14, 0.28, Vector3(0, -0.70, -0.08), boots, left_leg)
    right_leg = Node3D.new()
    right_leg.position = Vector3(0.16, 0.70, 0)
    add_child(right_leg)
    _capsule(0.13, 0.65, Vector3(0, -0.34, 0), pants, right_leg)
    _capsule(0.14, 0.28, Vector3(0, -0.70, -0.08), boots, right_leg)

func _process(delta: float) -> void:
    animation_time += delta * (7.0 if moving else 1.8)
    var stride := 0.42 if moving else 0.035
    left_leg.rotation.x = sin(animation_time) * stride
    right_leg.rotation.x = sin(animation_time + PI) * stride
    left_arm.rotation.x = -0.95 + sin(animation_time + PI) * stride * 0.35
    right_arm.rotation.x = -0.95 + sin(animation_time) * stride * 0.35
    torso.position.y = 1.02 + sin(animation_time * 2.0) * (0.025 if moving else 0.012)
    torso.rotation.z = sin(animation_time) * (0.035 if moving else 0.018)
