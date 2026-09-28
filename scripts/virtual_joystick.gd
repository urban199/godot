extends Control

var input_vector := Vector2.ZERO
var active := false
var pointer_id := -1
var base_radius := 78.0
var knob_radius := 34.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    add_to_group("mobile_joystick")
    queue_redraw()

func _process(_delta: float) -> void:
    if not active or input_vector.length() < 0.12:
        return
    if input_vector.x < -0.12: Input.action_press("move_left", -input_vector.x)
    if input_vector.x > 0.12: Input.action_press("move_right", input_vector.x)
    if input_vector.y < -0.12: Input.action_press("move_forward", -input_vector.y)
    if input_vector.y > 0.12: Input.action_press("move_backward", input_vector.y)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if not get_global_rect().has_point(event.position):
                return
            active = true
            pointer_id = event.index
            _set_vector(event.position - global_position)
        elif active and event.index == pointer_id:
            _release_vector()
    elif event is InputEventScreenDrag and active and event.index == pointer_id:
        _set_vector(event.position - global_position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if not get_global_rect().has_point(event.position):
                return
            active = true
            pointer_id = -2
            _set_vector(event.position - global_position)
        elif active and pointer_id == -2:
            _release_vector()
    elif event is InputEventMouseMotion and active and pointer_id == -2:
        _set_vector(event.position - global_position)

func _set_vector(position: Vector2) -> void:
    var center := size * 0.5
    input_vector = (position - center).limit_length(base_radius) / base_radius
    Input.action_release("move_left")
    Input.action_release("move_right")
    Input.action_release("move_forward")
    Input.action_release("move_backward")
    if input_vector.x < -0.12: Input.action_press("move_left", -input_vector.x)
    if input_vector.x > 0.12: Input.action_press("move_right", input_vector.x)
    if input_vector.y < -0.12: Input.action_press("move_forward", -input_vector.y)
    if input_vector.y > 0.12: Input.action_press("move_backward", input_vector.y)
    queue_redraw()

func _release_vector() -> void:
    active = false
    pointer_id = -1
    input_vector = Vector2.ZERO
    for action in ["move_left", "move_right", "move_forward", "move_backward"]:
        Input.action_release(action)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, base_radius, Color(0.03, 0.05, 0.10, 0.72))
    draw_arc(center, base_radius, 0.0, TAU, 48, Color(0.35, 0.65, 1.0, 0.9), 3.0)
    draw_circle(center + input_vector * base_radius, knob_radius, Color(0.18, 0.55, 0.95, 0.9))
    draw_arc(center + input_vector * base_radius, knob_radius, 0.0, TAU, 32, Color(0.75, 0.9, 1.0, 0.95), 2.0)
