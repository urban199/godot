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

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var muzzle: Marker3D = $PlayerModel/Muzzle
@onready var flashlight: SpotLight3D = $CameraPivot/SpringArm3D/Camera3D/Flashlight
@onready var player_model: Node3D = $PlayerModel
@onready var weapon_view: Node3D = $PlayerModel/WeaponView
var weapon_home_position := Vector3.ZERO

func _ready() -> void:
    add_to_group("player")
    health = max_health
    weapon_home_position = weapon_view.position
    model_home_position = player_model.position
    camera_yaw = rotation.y
    camera_pivot.rotation.x = pitch
    camera_arm.position.x = camera_side_offset * shoulder_side
    camera_arm.spring_length = camera_distance
    camera_arm.add_excluded_object(get_rid())
    mobile_joystick = get_tree().get_first_node_in_group("mobile_joystick")
    if not DisplayServer.is_touchscreen_available():
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    health_changed.emit(health)
    ammo_changed.emit(ammo, reserve_ammo)

func set_mobile_action(action: String, pressed: bool) -> void:
    mobile_actions[action] = pressed

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
    weapon_view.position = weapon_home_position + Vector3(0, reload_animation * 0.08, weapon_recoil * 0.35)
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
