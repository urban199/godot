extends CharacterBody3D

signal health_changed(value: int)
signal ammo_changed(current: int, reserve: int)
signal fired

@export var walk_speed := 4.0
@export var sprint_speed := 6.5
@export var jump_velocity := 5.5
@export var max_health := 100
@export var damage := 35
@export var camera_side_offset := 0.22
@export var camera_collision_margin := 0.08
@export var camera_smoothing := 12.0
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

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var muzzle: Marker3D = $Muzzle
@onready var flashlight: SpotLight3D = $CameraPivot/Camera3D/Flashlight
@onready var player_model: Node3D = $PlayerModel
@onready var weapon_view: Node3D = $CameraPivot/Camera3D/WeaponView
var weapon_home_position := Vector3.ZERO

func _ready() -> void:
    add_to_group("player")
    health = max_health
    weapon_home_position = weapon_view.position
    model_home_position = player_model.position
    camera_yaw = rotation.y
    camera_pivot.rotation.x = pitch
    camera.position = _get_camera_home_position()
    mobile_joystick = get_tree().get_first_node_in_group("mobile_joystick")
    if not DisplayServer.is_touchscreen_available():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    health_changed.emit(health)
    ammo_changed.emit(ammo, reserve_ammo)

func set_mobile_action(action: String, pressed: bool) -> void:
    mobile_actions[action] = pressed

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        camera_yaw -= event.relative.x * 0.0025
        pitch = clamp(pitch - event.relative.y * 0.002, -0.75, 0.35)
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
    weapon_view.position = weapon_home_position + Vector3(0, reload_animation * 0.08, weapon_recoil)
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
    var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * delta * 6.0)
        velocity.z = move_toward(velocity.z, 0.0, speed * delta * 6.0)
    var position_before_slide := global_position
    move_and_slide()
    if direction.length() > 0.01 and global_position.distance_to(position_before_slide) < 0.001:
        global_position += direction * speed * delta
    var movement_amount := Vector2(velocity.x, velocity.z).length()
    player_model.call("set_moving", movement_amount > 0.15)
    if movement_amount > 0.15:
        walk_time += delta * 9.0
        player_model.position = model_home_position + Vector3(0, sin(walk_time) * 0.045, 0)
        player_model.rotation.z = sin(walk_time * 0.5) * 0.025
    else:
        player_model.position.y = move_toward(player_model.position.y, model_home_position.y, delta * 0.18)
        player_model.rotation.z = move_toward(player_model.rotation.z, 0.0, delta * 0.15)
    _update_camera_collision(delta)

func _get_camera_home_position() -> Vector3:
    return Vector3(camera_side_offset * shoulder_side, 0.0, 0.0)

func swap_camera_shoulder() -> void:
    shoulder_side *= -1.0
    weapon_home_position.x = abs(weapon_home_position.x) * shoulder_side

func _update_camera_collision(delta: float) -> void:
    var target_local := _get_camera_home_position()
    var pivot_origin := camera_pivot.global_position
    var target_global := camera_pivot.to_global(target_local)
    var query := PhysicsRayQueryParameters3D.create(pivot_origin, target_global)
    query.exclude = [self]
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    if hit:
        target_global = hit.position + hit.normal * camera_collision_margin
        target_local = camera_pivot.to_local(target_global)
    var weight := 1.0 - exp(-camera_smoothing * delta)
    camera.position = camera.position.lerp(target_local, weight)

func shoot() -> void:
    if not can_shoot or ammo <= 0: return
    can_shoot = false
    weapon_recoil = 0.13
    get_tree().create_timer(0.22).timeout.connect(func(): can_shoot = true)
    ammo -= 1
    ammo_changed.emit(ammo, reserve_ammo)
    fired.emit()
    var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + -camera.global_transform.basis.z * 32.0)
    query.exclude = [self]
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    if hit and hit.collider.has_method("take_damage"): hit.collider.take_damage(damage)

func reload_weapon() -> void:
    if ammo >= 6 or reserve_ammo <= 0: return
    reload_animation = 1.0
    var needed := 6 - ammo
    var loaded := min(needed, reserve_ammo)
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
