extends Node3D
## Demo controller for imported skinned GLB, animation clips, and camera modes.
const WALK_SPEED := 3.0
const RUN_SPEED := 5.0
const GRAVITY := 18.0
var body: CharacterBody3D
var model: Node3D
var anim_player: AnimationPlayer
var camera_pivot: Node3D
var camera: Camera3D
var third_person := true
var active_clip := ""

func _ready() -> void:
    body = $CharacterBody3D
    model = body.get_node("Model")
    anim_player = _find_animation_player(model)
    _make_world()
    _make_camera()
    _make_hud()
    _play_clip("Idle")
    print("Animations found: ", anim_player.get_animation_list() if anim_player else "none")

func _physics_process(delta: float) -> void:
    var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var moving := input_vec.length() > 0.1
    var sprint := Input.is_action_pressed("run")
    var speed := RUN_SPEED if sprint else WALK_SPEED
    var dir := Vector3(input_vec.x, 0, input_vec.y)
    if dir.length() > 0.01:
        dir = dir.normalized()
        body.velocity.x = dir.x * speed
        body.velocity.z = dir.z * speed
        body.rotation.y = lerp_angle(body.rotation.y, atan2(-dir.x, -dir.z), delta * 8.0)
    else:
        body.velocity.x = move_toward(body.velocity.x, 0.0, speed * 5.0 * delta)
        body.velocity.z = move_toward(body.velocity.z, 0.0, speed * 5.0 * delta)
    if not body.is_on_floor():
        body.velocity.y -= GRAVITY * delta
    elif Input.is_action_just_pressed("jump"):
        body.velocity.y = 5.0
    body.move_and_slide()
    if moving:
        _play_clip("Run" if sprint else "Walk")
    elif active_clip in ["Walk", "Run"]:
        _play_clip("Idle")
    if Input.is_action_just_pressed("camera_toggle"):
        third_person = not third_person
        _update_camera()
    if Input.is_action_just_pressed("mode_idle"): _play_clip("Idle")
    if Input.is_action_just_pressed("mode_walk"): _play_clip("Walk")
    if Input.is_action_just_pressed("mode_run"): _play_clip("Run")
    if Input.is_action_just_pressed("mode_aim"): _play_clip("Aim")
    if Input.is_action_just_pressed("mode_shoot"): _play_clip("Shoot")
    if Input.is_action_just_pressed("mode_reload"): _play_clip("Reload")

func _find_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer: return root
    for child in root.get_children():
        var found := _find_animation_player(child)
        if found: return found
    return null

func _play_clip(wanted: String) -> void:
    if anim_player == null: return
    var list := anim_player.get_animation_list()
    for clip in list:
        if clip.to_lower().ends_with("/" + wanted.to_lower()) or clip.to_lower() == wanted.to_lower():
            if active_clip != wanted:
                active_clip = wanted
                anim_player.play(clip)
            return
    # Imported glTF animation names may be exposed as a library-prefixed name.
    if wanted == "Shoot":
        for clip in list:
            if "shoot" in clip.to_lower():
                active_clip = wanted
                anim_player.play(clip)
                return
    push_warning("Klip animasi tidak ditemukan: %s. Tersedia: %s" % [wanted, list])

func _make_camera() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0, 1.45, 0)
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.name = "PlayerCamera"
    camera_pivot.add_child(camera)
    _update_camera()

func _update_camera() -> void:
    if not is_instance_valid(camera): return
    if third_person:
        camera.position = Vector3(0.8, 0.45, 3.8)
        camera_pivot.position = Vector3(0, 1.35, 0)
        camera.look_at(Vector3(0, 0.15, 0), Vector3.UP)
        camera.fov = 52
    else:
        camera.position = Vector3(0, 0.02, -0.05)
        camera_pivot.position = Vector3(0, 1.58, 0)
        camera.rotation = Vector3.ZERO
        camera.fov = 75
    camera.current = true

func _make_world() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.015, 0.025, 0.06)
    sky_mat.sky_horizon_color = Color(0.12, 0.14, 0.20)
    env.sky.sky_material = sky_mat
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.55, 0.60, 0.78)
    env.ambient_light_energy = 0.8
    env_node.environment = env
    add_child(env_node)
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(100,100)
    floor.mesh = plane
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.055,0.065,0.09)
    mat.roughness = 0.9
    floor.material_override = mat
    floor.position.y = -0.03
    add_child(floor)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45,-25,0)
    light.light_energy = 1.25
    add_child(light)
    var rim := OmniLight3D.new()
    rim.position = Vector3(-2,3,-2)
    rim.light_color = Color(0.25,0.40,1.0)
    rim.light_energy = 1.5
    rim.omni_range = 8
    add_child(rim)

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(16,16)
    panel.custom_minimum_size = Vector2(340,0)
    layer.add_child(panel)
    var box := VBoxContainer.new()
    panel.add_child(box)
    var title := Label.new()
    title.text = "NEKO NIGHTFALL — CHARACTER DEMO"
    title.add_theme_font_size_override("font_size",18)
    box.add_child(title)
    var label := Label.new()
    label.text = "WASD gerak • Shift lari • Space lompat • F kamera\n1 Idle • 2 Walk • 3 Run • 4 Aim • 5 Reload • 6 Shoot"
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(label)
