extends CanvasLayer

const TOUCH_ACTIONS: Dictionary = {
    "MoveUp": "move_forward",
    "MoveLeft": "move_left",
    "MoveDown": "move_backward",
    "MoveRight": "move_right",
    "Sprint": "sprint",
    "Fire": "fire",
    "Reload": "reload",
    "Flashlight": "flashlight",
    "Shoulder": "shoulder_swap"
}
const TOUCH_BUTTON_NAMES: Array[String] = [
    "MoveUp", "MoveLeft", "MoveDown", "MoveRight", "Sprint",
    "Fire", "Reload", "Flashlight", "Shoulder", "View"
]

var held_actions: Dictionary = {}
var touch_targets: Dictionary = {}
var touch_button_counts: Dictionary = {}
var touch_action_counts: Dictionary = {}

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
    if _is_mobile_input():
        for button_name in TOUCH_BUTTON_NAMES:
            var visual_button: Button = get_node(button_name)
            visual_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _is_mobile_input() -> bool:
    return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

func _input(event: InputEvent) -> void:
    if not _is_mobile_input():
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _begin_touch(event.index, event.position)
        else:
            _end_touch(event.index)
    elif event is InputEventScreenDrag and touch_targets.has(event.index):
        get_viewport().set_input_as_handled()

func _begin_touch(pointer_id: int, viewport_position: Vector2) -> void:
    if touch_targets.has(pointer_id):
        return
    for button_name in TOUCH_BUTTON_NAMES:
        var visual_button: Button = get_node(button_name)
        var local_position: Vector2 = visual_button.get_global_transform_with_canvas().affine_inverse() * viewport_position
        if not Rect2(Vector2.ZERO, visual_button.size).has_point(local_position):
            continue
        touch_targets[pointer_id] = button_name
        var button_count: int = int(touch_button_counts.get(button_name, 0)) + 1
        touch_button_counts[button_name] = button_count
        visual_button.set_pressed_no_signal(true)
        var action: String = TOUCH_ACTIONS.get(button_name, "")
        if not action.is_empty():
            _press_touch_action(action)
        elif button_name == "View":
            _toggle_view()
        else:
            _one_shot(button_name.to_lower())
        get_viewport().set_input_as_handled()
        return

func _end_touch(pointer_id: int) -> void:
    if not touch_targets.has(pointer_id):
        return
    var button_name: String = touch_targets[pointer_id]
    touch_targets.erase(pointer_id)
    var visual_button: Button = get_node(button_name)
    var button_count: int = int(touch_button_counts.get(button_name, 1)) - 1
    if button_count <= 0:
        touch_button_counts.erase(button_name)
        visual_button.set_pressed_no_signal(false)
    else:
        touch_button_counts[button_name] = button_count
    var action: String = TOUCH_ACTIONS.get(button_name, "")
    if not action.is_empty():
        _release_touch_action(action)
    get_viewport().set_input_as_handled()

func _press_touch_action(action: String) -> void:
    var count: int = int(touch_action_counts.get(action, 0))
    touch_action_counts[action] = count + 1
    if count == 0:
        _press(action)

func _release_touch_action(action: String) -> void:
    var count: int = int(touch_action_counts.get(action, 0)) - 1
    if count <= 0:
        touch_action_counts.erase(action)
        _release(action)
    else:
        touch_action_counts[action] = count

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
