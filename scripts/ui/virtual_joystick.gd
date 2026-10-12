extends Control

const DEAD_ZONE := 0.16

var _touch_index := -1
var _stick_vector := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update_stick(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_set_vector(Vector2.ZERO)
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_stick(event.position)
		accept_event()

func _update_stick(position: Vector2) -> void:
	var radius := minf(size.x, size.y) * 0.42
	_set_vector((position - size * 0.5) / maxf(radius, 1.0))

func _set_vector(value: Vector2) -> void:
	_stick_vector = value.limit_length(1.0)
	_apply_action("move_left", maxf(0.0, -_stick_vector.x))
	_apply_action("move_right", maxf(0.0, _stick_vector.x))
	_apply_action("move_forward", maxf(0.0, -_stick_vector.y))
	_apply_action("move_back", maxf(0.0, _stick_vector.y))
	queue_redraw()

func _apply_action(action: String, strength: float) -> void:
	if strength > DEAD_ZONE:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	draw_circle(center, radius, Color(0.025, 0.045, 0.052, 0.76))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.55, 0.65, 0.65, 0.8), 2.0)
	draw_circle(center + _stick_vector * radius, radius * 0.34, Color(0.34, 0.45, 0.46, 0.88))

func _exit_tree() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
