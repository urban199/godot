extends CharacterBody3D
class_name PlayerController

signal health_changed(value: float)
signal interaction_changed(prompt: String)
signal message_requested(message: String)
signal noise_emitted(position: Vector3, strength: float)

const WALK_SPEED := 4.0
const RUN_SPEED := 6.2
const CROUCH_SPEED := 2.0
const GRAVITY := 18.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var body_collision: CollisionShape3D = $CollisionShape3D

var health := 100.0
var flashlight_battery := 100.0
var is_crouching := false
var _interaction_prompt := ""
var _noise_timer := 0.0
var is_hidden := false
var _hiding_spot: Node3D

func _ready() -> void:
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if is_hidden:
		if event.is_action_pressed("interact"):
			exit_hiding_spot()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.relative)
	if event is InputEventScreenDrag:
		_look(event.relative * 0.45)
	if event.is_action_pressed("flashlight"):
		flashlight.visible = not flashlight.visible and flashlight_battery > 0.0
	if event.is_action_pressed("interact"):
		_interact()
func _look(delta: Vector2) -> void:
	var sensitivity_key := "touch_sensitivity" if OS.has_feature("mobile") else "mouse_sensitivity"
	var sensitivity := float(SettingsManager.get_value(sensitivity_key, 0.5)) * 0.0044
	rotate_y(-delta.x * sensitivity)
	head.rotate_x(-delta.y * sensitivity)
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-82), deg_to_rad(82))

func _physics_process(delta: float) -> void:
	if is_hidden:
		velocity = Vector3.ZERO
		return
	_update_crouch_shape(Input.is_action_pressed("crouch"))
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (global_transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	var speed := CROUCH_SPEED if is_crouching else (RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	move_and_slide()
	_update_interaction_prompt()
	_noise_timer -= delta
	if _noise_timer <= 0.0 and velocity.length() > 0.8:
		_noise_timer = 0.65 if Input.is_action_pressed("run") else (1.8 if is_crouching else 1.4)
		var noise_strength := 0.12 if is_crouching else (1.0 if Input.is_action_pressed("run") else 0.45)
		noise_emitted.emit(global_position, noise_strength)
		AudioManager.play_step(global_position, Input.is_action_pressed("run"))
	if flashlight.visible:
		flashlight_battery = maxf(0.0, flashlight_battery - delta * 1.4)
		if flashlight_battery <= 0.0:
			flashlight.visible = false

func _update_interaction_prompt() -> void:
	var prompt := ""
	if interaction_ray.is_colliding():
		var target := interaction_ray.get_collider()
		if target != null and target.has_method("get_interaction_prompt"):
			prompt = str(target.call("get_interaction_prompt"))
	if prompt != _interaction_prompt:
		_interaction_prompt = prompt
		interaction_changed.emit(prompt)

func _interact() -> void:
	if not interaction_ray.is_colliding():
		return
	var target := interaction_ray.get_collider()
	if target != null and target.has_method("interact"):
		target.call("interact", self)

func enter_hiding_spot(spot: Node3D) -> void:
	if is_hidden or not is_instance_valid(spot):
		return
	_hiding_spot = spot
	global_position = spot.global_position + spot.global_transform.basis.z * 0.48
	velocity = Vector3.ZERO
	is_hidden = true
	body_collision.set_deferred("disabled", true)
	flashlight.visible = false
	interaction_changed.emit("[E] Leave hiding spot")
	show_message("Hidden. Press E to leave.")

func exit_hiding_spot() -> void:
	if not is_hidden:
		return
	is_hidden = false
	body_collision.set_deferred("disabled", false)
	global_position = _hiding_spot.global_position + _hiding_spot.global_transform.basis.z * 1.4
	_hiding_spot = null
	show_message("You leave cover.")

func receive_damage(amount: float) -> void:
	if is_hidden:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health)
	if health <= 0.0:
		set_physics_process(false)
		set_process_unhandled_input(false)

func _update_crouch_shape(wants_crouch: bool) -> void:
	var capsule := body_collision.shape as CapsuleShape3D
	if capsule == null:
		return
	if wants_crouch:
		is_crouching = true
		capsule.height = 1.15
		body_collision.position.y = 0.575
		head.position.y = 1.0
	elif capsule.height < 1.8 and _has_standing_room():
		is_crouching = false
		capsule.height = 1.8
		body_collision.position.y = 0.9
		head.position.y = 1.62
	elif capsule.height >= 1.8:
		is_crouching = false

func _has_standing_room() -> bool:
	var standing_shape := CapsuleShape3D.new()
	standing_shape.radius = 0.32
	standing_shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = standing_shape
	var standing_transform := global_transform
	standing_transform.origin += Vector3.UP * 0.9
	query.transform = standing_transform
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func add_flashlight_battery(amount: float) -> void:
	flashlight_battery = minf(100.0, flashlight_battery + amount)

func show_message(message: String) -> void:
	message_requested.emit(message)

func heal(amount: float) -> void:
	health = minf(100.0, health + amount)
	health_changed.emit(health)
