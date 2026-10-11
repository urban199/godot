extends CharacterBody3D

signal health_changed(value: int)
signal ammo_changed(current: int, reserve: int)
signal fired

@export var walk_speed := 4.0
@export var sprint_speed := 6.5
@export var jump_velocity := 5.5
@export var max_health := 100
@export var damage := 35
@export var camera_side_offset := 0.42
@export var camera_distance := 3.6
@export var aim_ray_distance := 60.0
var health := 100
var ammo := 6
var reserve_ammo := 24
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch := -0.18
var camera_yaw := 0.0
var shoulder_side := 1.0
var can_shoot := true
var flashlight_on := true
var walk_time := 0.0
var weapon_recoil := 0.0
var reload_animation := 0.0
var model_home_position := Vector3.ZERO
var look_touch_id := -1
var last_look_position := Vector2.ZERO
var mobile_move_vector := Vector2.ZERO
var mobile_joystick = null
var mobile_actions: Dictionary = {}
var first_person := false
var camera_pivot_home_position := Vector3.ZERO
var camera_arm_home_length := 0.0
var weapon_home_scale := Vector3.ONE
var first_person_arms: Node3D

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var muzzle: Marker3D = $PlayerModel/Muzzle
@onready var flashlight: SpotLight3D = $CameraPivot/SpringArm3D/Camera3D/Flashlight
@onready var player_model: Node3D = $PlayerModel
@onready var weapon_view: Node3D = $PlayerModel/WeaponView
var weapon_home_position := Vector3.ZERO
var weapon_base_position := Vector3.ZERO

func _ready() -> void:
    add_to_group("player")
    health = max_health
    weapon_home_position = weapon_view.position
    weapon_base_position = weapon_home_position
    weapon_home_scale = weapon_view.scale
    camera_pivot_home_position = camera_pivot.position
    camera_arm_home_length = camera_distance
    model_home_position = player_model.position
    camera_yaw = rotation.y
    camera_pivot.rotation.x = pitch
    camera_arm.position.x = camera_side_offset * shoulder_side
    camera_arm.spring_length = camera_distance
    camera_arm.add_excluded_object(get_rid())
    _create_first_person_arms()
    mobile_joystick = get_tree().get_first_node_in_group("mobile_joystick")
    if not DisplayServer.is_touchscreen_available():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    health_changed.emit(health)
    ammo_changed.emit(ammo, reserve_ammo)

func set_mobile_action(action: String, pressed: bool) -> void:
    mobile_actions[action] = pressed

func toggle_camera_view() -> bool:
    first_person = not first_person
    if first_person:
        player_model.visible = false
        first_person_arms.visible = true
        weapon_view.reparent(camera, false)
        weapon_base_position = Vector3(0.28, -0.25, -0.58)
        weapon_view.position = weapon_base_position
        weapon_view.rotation = Vector3(-0.04, -0.08, -0.03)
        weapon_view.scale = Vector3.ONE * 0.62
        camera_pivot.position = Vector3(0, 1.58, 0.08)
        camera_arm.position.x = 0.0
        camera_arm.spring_length = 0.0
        camera.fov = 76.0
    else:
        first_person_arms.visible = false
        weapon_view.reparent(player_model, false)
        weapon_base_position = weapon_home_position
        weapon_view.position = weapon_base_position
        weapon_view.rotation = Vector3.ZERO
        weapon_view.scale = weapon_home_scale
        player_model.visible = true
        camera_pivot.position = camera_pivot_home_position
        camera_arm.position.x = camera_side_offset * shoulder_side
        camera_arm.spring_length = camera_arm_home_length
        camera.fov = 68.0
    return first_person

func _create_first_person_arms() -> void:
    first_person_arms = Node3D.new()
    first_person_arms.name = "FirstPersonArms"
    first_person_arms.visible = false
    camera.add_child(first_person_arms)
    var sleeve := _first_person_material(Color(0.30, 0.035, 0.045, 1.0))
    var glove := _first_person_material(Color(0.13, 0.10, 0.09, 1.0))
    _add_first_person_capsule("LeftSleeve", Vector3(-0.36, -0.49, -0.28), 0.105, 0.72, sleeve, Vector3(-1.12, 0, -0.36))
    _add_first_person_capsule("RightSleeve", Vector3(0.38, -0.48, -0.30), 0.105, 0.72, sleeve, Vector3(-1.12, 0, 0.30))
    _add_first_person_ellipsoid("LeftGlove", Vector3(-0.08, -0.32, -0.67), Vector3(0.11, 0.085, 0.14), glove)
    _add_first_person_ellipsoid("RightGlove", Vector3(0.30, -0.34, -0.56), Vector3(0.095, 0.085, 0.14), glove)

func _first_person_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.86
    return material

func _add_first_person_capsule(part_name: String, part_position: Vector3, radius: float, height: float, material: Material, part_rotation: Vector3) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = part_name
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    mesh.radial_segments = 16
    mesh.rings = 8
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    mesh_instance.position = part_position
    mesh_instance.rotation = part_rotation
    first_person_arms.add_child(mesh_instance)

func _add_first_person_ellipsoid(part_name: String, part_position: Vector3, part_scale: Vector3, material: Material) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = part_name
    var mesh := SphereMesh.new()
    mesh.radial_segments = 20
    mesh.rings = 12
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    mesh_instance.position = part_position
    mesh_instance.scale = part_scale
    first_person_arms.add_child(mesh_instance)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        camera_yaw -= event.screen_relative.x * 0.0025
        pitch = clamp(pitch - event.screen_relative.y * 0.002, -0.75, 0.35)
        rotation.y = camera_yaw
        camera_pivot.rotation.x = pitch
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.35:
            look_touch_id = event.index
            last_look_position = event.position
        elif not event.pressed and event.index == look_touch_id:
            look_touch_id = -1
    if event is InputEventScreenDrag and event.index == look_touch_id:
        var drag_delta: Vector2 = event.position - last_look_position
        last_look_position = event.position
        camera_yaw -= drag_delta.x * 0.006
        pitch = clamp(pitch - drag_delta.y * 0.004, -0.75, 0.35)
        rotation.y = camera_yaw
        camera_pivot.rotation.x = pitch
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
    weapon_recoil = move_toward(weapon_recoil, 0.0, delta * 0.9)
    reload_animation = move_toward(reload_animation, 0.0, delta * 2.4)
    weapon_view.position = weapon_base_position + Vector3(0, reload_animation * 0.08, weapon_recoil * 0.35)
    weapon_view.rotation.x = -0.02 - reload_animation * 0.55
    if not is_on_floor(): velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = jump_velocity
    if Input.is_action_just_pressed("reload"): reload_weapon()
    if Input.is_action_just_pressed("flashlight"):
        flashlight_on = not flashlight_on
        flashlight.visible = flashlight_on
    if Input.is_action_just_pressed("fire"): shoot()
    if Input.is_action_just_pressed("shoulder_swap"): swap_camera_shoulder()
    if not mobile_joystick:
        mobile_joystick = get_tree().get_first_node_in_group("mobile_joystick")
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    if mobile_actions.get("move_left", false): input_vector.x = -1.0
    if mobile_actions.get("move_right", false): input_vector.x = 1.0
    if mobile_actions.get("move_forward", false): input_vector.y = -1.0
    if mobile_actions.get("move_backward", false): input_vector.y = 1.0
    if mobile_joystick and mobile_joystick.input_vector.length() > 0.08:
        input_vector = mobile_joystick.input_vector
    if Input.is_physical_key_pressed(KEY_A): input_vector.x = -1.0
    if Input.is_physical_key_pressed(KEY_D): input_vector.x = 1.0
    if Input.is_physical_key_pressed(KEY_W): input_vector.y = -1.0
    if Input.is_physical_key_pressed(KEY_S): input_vector.y = 1.0
    var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
    var is_sprinting := Input.is_action_pressed("sprint")
    var speed := sprint_speed if is_sprinting else walk_speed
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * delta * 6.0)
        velocity.z = move_toward(velocity.z, 0.0, speed * delta * 6.0)
    move_and_slide()
    var movement_amount := Vector2(velocity.x, velocity.z).length()
    player_model.call("set_moving", movement_amount > 0.15, is_sprinting and movement_amount > 0.15)
    if not player_model.call("uses_imported_model"):
        if movement_amount > 0.15:
            walk_time += delta * 9.0
            player_model.position = model_home_position + Vector3(0, sin(walk_time) * 0.045, 0)
            player_model.rotation.z = sin(walk_time * 0.5) * 0.025
        else:
            player_model.position.y = move_toward(player_model.position.y, model_home_position.y, delta * 0.18)
            player_model.rotation.z = move_toward(player_model.rotation.z, 0.0, delta * 0.15)
    if first_person:
        var bob := sin(walk_time * 2.0) * 0.018 if movement_amount > 0.15 else 0.0
        camera_pivot.position = Vector3(0, 1.58 + bob, 0.08)

func swap_camera_shoulder() -> void:
    shoulder_side *= -1.0
    camera_arm.position.x = camera_side_offset * shoulder_side

func shoot() -> void:
    if not can_shoot or ammo <= 0: return
    can_shoot = false
    weapon_recoil = 0.13
    get_tree().create_timer(0.22).timeout.connect(func(): can_shoot = true)
    ammo -= 1
    ammo_changed.emit(ammo, reserve_ammo)
    fired.emit()
    weapon_view.call("fire_effect")
    player_model.call("play_action", "holding-both-shoot")
    var aim_start := camera.global_position
    var aim_end := aim_start + -camera.global_transform.basis.z * aim_ray_distance
    var aim_query := PhysicsRayQueryParameters3D.create(aim_start, aim_end)
    aim_query.exclude = [self]
    var aim_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(aim_query)
    if aim_hit:
        aim_end = aim_hit.position

    var shot_query := PhysicsRayQueryParameters3D.create(muzzle.global_position, aim_end)
    shot_query.exclude = [self]
    var shot_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(shot_query)
    if shot_hit and shot_hit.collider.has_method("take_damage"):
        shot_hit.collider.take_damage(damage)

func reload_weapon() -> void:
    if ammo >= 6 or reserve_ammo <= 0: return
    reload_animation = 1.0
    var needed := 6 - ammo
    var loaded: int = mini(needed, reserve_ammo)
    ammo += loaded
    reserve_ammo -= loaded
    ammo_changed.emit(ammo, reserve_ammo)

func take_damage(amount: int) -> void:
    health = max(health - amount, 0)
    health_changed.emit(health)
    if health == 0: get_tree().call_group("game", "player_died")

func collect_ammo(amount: int) -> void:
    reserve_ammo += amount
    ammo_changed.emit(ammo, reserve_ammo)

func heal(amount: int) -> void:
    health = min(health + amount, max_health)
    health_changed.emit(health)
