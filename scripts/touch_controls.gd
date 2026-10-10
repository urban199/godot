extends CanvasLayer

var held_actions: Dictionary = {}
var touch_buttons: Dictionary = {}
var touch_action_holders: Dictionary = {}

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
    if DisplayServer.is_touchscreen_available():
        for button_name in ["MoveUp", "MoveLeft", "MoveDown", "MoveRight", "Sprint", "Fire", "Reload", "Flashlight", "Shoulder", "View"]:
            (get_node(button_name) as Button).mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Fire.pressed.connect(_one_shot.bind("fire"))
    $Reload.pressed.connect(_one_shot.bind("reload"))
    $Flashlight.pressed.connect(_one_shot.bind("flashlight"))
    $Shoulder.pressed.connect(_one_shot.bind("shoulder_swap"))
    $View.pressed.connect(_toggle_view)
    _bind_hold("Sprint", "sprint")

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

func _input(event: InputEvent) -> void:
    if not event is InputEventScreenTouch:
        return
    if event.pressed:
        var button_name := _button_at_position(event.position)
        if button_name.is_empty():
            return
        touch_buttons[event.index] = button_name
        (get_node(button_name) as Button).set_pressed_no_signal(true)
        _handle_touch_button(button_name, event.index, true)
        get_viewport().set_input_as_handled()
    elif touch_buttons.has(event.index):
        var button_name: String = touch_buttons[event.index]
        touch_buttons.erase(event.index)
        (get_node(button_name) as Button).set_pressed_no_signal(false)
        _handle_touch_button(button_name, event.index, false)
        get_viewport().set_input_as_handled()

func _button_at_position(position: Vector2) -> String:
    for button_name in ["MoveUp", "MoveLeft", "MoveDown", "MoveRight", "Sprint", "Fire", "Reload", "Flashlight", "Shoulder", "View"]:
        var button := get_node(button_name) as Button
        if button.get_global_rect().has_point(position):
            return button_name
    return ""

func _handle_touch_button(button_name: String, pointer_id: int, pressed: bool) -> void:
    var action := ""
    match button_name:
        "MoveUp": action = "move_forward"
        "MoveLeft": action = "move_left"
        "MoveDown": action = "move_backward"
        "MoveRight": action = "move_right"
        "Sprint": action = "sprint"
    if not action.is_empty():
        var holders: Dictionary = touch_action_holders.get(action, {})
        if pressed:
            holders[pointer_id] = true
        else:
            holders.erase(pointer_id)
        touch_action_holders[action] = holders
        var player := get_tree().get_first_node_in_group("player")
        if player:
            player.call("set_mobile_action", action, not holders.is_empty())
        return
    if not pressed:
        return
    match button_name:
        "Fire": _one_shot("fire")
        "Reload": _one_shot("reload")
        "Flashlight": _one_shot("flashlight")
        "Shoulder": _one_shot("shoulder_swap")
        "View": _toggle_view()

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
