extends Node3D

@export_enum("survivor", "zombie") var role := "survivor"

const SURVIVOR_SCENE: PackedScene = preload("res://assets/characters/kenney_blocky/Models/GLB format/character-a.glb")
const ZOMBIE_SCENE: PackedScene = preload("res://assets/characters/kenney_blocky/Models/GLB format/character-b.glb")

var moving := false
var sprinting := false
var animation_time := 0.0
var imported_model: Node3D
var animation_player: AnimationPlayer
var current_locomotion: StringName = &""
var active_action: StringName = &""
var resume_locomotion_after_action := true
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: MeshInstance3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_imported_humanoid()
    if imported_model:
        return
    _build_humanoid()

func _build_imported_humanoid() -> void:
    var model_scene := SURVIVOR_SCENE if role == "survivor" else ZOMBIE_SCENE
    imported_model = model_scene.instantiate() as Node3D
    if not imported_model:
        return
    imported_model.position.y = -1.0 if role == "zombie" else -0.8
    add_child(imported_model)

    var animation_nodes := imported_model.find_children("*", "AnimationPlayer", true, false)
    if animation_nodes.is_empty():
        return
    animation_player = animation_nodes[0] as AnimationPlayer
    if not animation_player:
        return
    animation_player.playback_default_blend_time = 0.18
    animation_player.animation_finished.connect(_on_animation_finished)
    _play_locomotion()

func set_moving(value: bool, is_sprinting := false) -> void:
    if moving == value and sprinting == is_sprinting:
        return
    moving = value
    sprinting = is_sprinting
    if animation_player and active_action == &"":
        _play_locomotion()

func uses_imported_model() -> bool:
    return imported_model != null

func play_action(animation_name: StringName, return_to_locomotion := true) -> float:
    if not animation_player or not animation_player.has_animation(animation_name):
        return 0.0
    var animation: Animation = animation_player.get_animation(animation_name)
    active_action = animation_name
    resume_locomotion_after_action = return_to_locomotion
    animation_player.play(animation_name, 0.08)
    return animation.length

func _play_locomotion() -> void:
    var animation_name: StringName = &"idle"
    if role == "survivor":
        animation_name = &"walk" if moving else &"holding-both"
        if moving and sprinting:
            animation_name = &"sprint"
    elif moving:
        animation_name = &"walk"

    if not animation_player.has_animation(animation_name):
        animation_name = &"idle"
    if not animation_player.has_animation(animation_name):
        return
    if current_locomotion == animation_name and animation_player.current_animation == animation_name:
        return

    var animation: Animation = animation_player.get_animation(animation_name)
    animation.loop_mode = Animation.LOOP_LINEAR
    current_locomotion = animation_name
    animation_player.play(animation_name, 0.18)

func _on_animation_finished(animation_name: StringName) -> void:
    if animation_name != active_action:
        return
    active_action = &""
    if resume_locomotion_after_action:
        current_locomotion = &""
        _play_locomotion()

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
    if imported_model:
        return
    animation_time += delta * (7.0 if moving else 1.8)
    var stride := 0.42 if moving else 0.035
    left_leg.rotation.x = sin(animation_time) * stride
    right_leg.rotation.x = sin(animation_time + PI) * stride
    left_arm.rotation.x = -0.95 + sin(animation_time + PI) * stride * 0.35
    right_arm.rotation.x = -0.95 + sin(animation_time) * stride * 0.35
    torso.position.y = 1.02 + sin(animation_time * 2.0) * (0.025 if moving else 0.012)
    torso.rotation.z = sin(animation_time) * (0.035 if moving else 0.018)
