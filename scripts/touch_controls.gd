extends CanvasLayer

const TOUCH_BUTTON_NAMES: Array[String] = [
    "MoveUp", "MoveLeft", "MoveDown", "MoveRight", "Sprint",
    "Fire", "Reload", "Flashlight", "Shoulder", "View"
]

var held_actions: Dictionary = {}

func _ready() -> void:
    _bind_hold("MoveUp", "move_forward")
    _bind_hold("MoveLeft", "move_left")
    _bind_hold("MoveDown", "move_backward")
    _bind_hold("MoveRight", "move_right")
    _style_round($MoveUp, Color(0.08, 0.22, 0.42, 0.88))
    _style_round($MoveLeft, Color(0.08, 0.22, 0.42, 0.88))
    _style_round($MoveDown, Color(0.08, 0.22, 0.42, 0.88))
    _style_round($MoveRight, Color(0.08, 0.22, 0.42, 0.88))
    _style_round($Fire, Color(0.78, 0.12, 0.10, 0.9))
    _style_round($Reload, Color(0.12, 0.34, 0.68, 0.9))
    _style_round($Flashlight, Color(0.72, 0.42, 0.08, 0.9))
    _style_round($Shoulder, Color(0.34, 0.18, 0.62, 0.9))
    _style_round($View, Color(0.18, 0.34, 0.34, 0.92))
    _style_round($Sprint, Color(0.18, 0.42, 0.28, 0.92))
    $Fire.pressed.connect(_one_shot.bind("fire"))
    $Reload.pressed.connect(_one_shot.bind("reload"))
    $Flashlight.pressed.connect(_one_shot.bind("flashlight"))
    $Shoulder.pressed.connect(_one_shot.bind("shoulder_swap"))
    $View.pressed.connect(_toggle_view)
    _bind_hold("Sprint", "sprint")
    if DisplayServer.is_touchscreen_available():
        # Button controls are retained for their visuals and desktop input. On
        # touch devices, transparent TouchScreenButtons provide independent
        # touch tracking so RUN can stay held while another button is tapped.
        for button_name in TOUCH_BUTTON_NAMES:
            var visual_button: Button = get_node(button_name)
            visual_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
        call_deferred("_create_multitouch_overlays")

func _create_multitouch_overlays() -> void:
    for button_name in TOUCH_BUTTON_NAMES:
        var visual_button: Button = get_node(button_name)
        var button_rect: Rect2 = visual_button.get_global_rect()
        if button_rect.size.x <= 0.0 or button_rect.size.y <= 0.0:
            continue

        var hit_button := TouchScreenButton.new()
        hit_button.name = "Touch_" + button_name
        hit_button.position = button_rect.position + button_rect.size * 0.5
        var hit_shape := RectangleShape2D.new()
        hit_shape.size = button_rect.size
        hit_button.shape = hit_shape
        hit_button.shape_visible = false
        hit_button.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
        hit_button.pressed.connect(_on_touch_button_pressed.bind(button_name))
        hit_button.released.connect(_on_touch_button_released.bind(button_name))
        add_child(hit_button)

func _on_touch_button_pressed(button_name: String) -> void:
    var visual_button: Button = get_node(button_name)
    visual_button.set_pressed_no_signal(true)
    match button_name:
        "MoveUp": _press("move_forward")
        "MoveLeft": _press("move_left")
        "MoveDown": _press("move_backward")
        "MoveRight": _press("move_right")
        "Sprint": _press("sprint")
        "Fire": _one_shot("fire")
        "Reload": _one_shot("reload")
        "Flashlight": _one_shot("flashlight")
        "Shoulder": _one_shot("shoulder_swap")
        "View": _toggle_view()

func _on_touch_button_released(button_name: String) -> void:
    var visual_button: Button = get_node(button_name)
    visual_button.set_pressed_no_signal(false)
    match button_name:
        "MoveUp": _release("move_forward")
        "MoveLeft": _release("move_left")
        "MoveDown": _release("move_backward")
        "MoveRight": _release("move_right")
        "Sprint": _release("sprint")

func _style_round(button: Button, color: Color) -> void:
    var normal := StyleBoxFlat.new()
    normal.bg_color = color
    normal.corner_radius_top_left = 60
    normal.corner_radius_top_right = 60
    normal.corner_radius_bottom_left = 60
    normal.corner_radius_bottom_right = 60
    normal.border_width_left = 2
    normal.border_width_top = 2
    normal.border_width_right = 2
    normal.border_width_bottom = 2
    normal.border_color = Color(0.8, 0.9, 1.0, 0.85)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", normal)
    button.add_theme_stylebox_override("pressed", normal)

func _bind_hold(button_name: String, action: String) -> void:
    var button: Button = get_node(button_name)
    button.button_down.connect(_press.bind(action))
    button.button_up.connect(_release.bind(action))

func _press(action: String) -> void:
    held_actions[action] = true
    Input.action_press(action)
    var player := get_tree().get_first_node_in_group("player")
    if player: player.call("set_mobile_action", action, true)

func _release(action: String) -> void:
    held_actions.erase(action)
    Input.action_release(action)
    var player := get_tree().get_first_node_in_group("player")
    if player: player.call("set_mobile_action", action, false)

func _process(_delta: float) -> void:
    for action in held_actions:
        Input.action_press(action)

func _one_shot(action: String) -> void:
    var player := get_tree().get_first_node_in_group("player")
    if not player:
        return
    match action:
        "fire": player.call("shoot")
        "reload": player.call("reload_weapon")
        "flashlight": player.call("toggle_flashlight")
        "shoulder_swap": player.call("swap_camera_shoulder")

func _toggle_view() -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player:
        var is_first_person: bool = player.call("toggle_camera_view")
        $View.text = "3RD" if is_first_person else "1ST"
