extends CharacterBody3D

enum State { PATROL, INVESTIGATE, CHASE, SEARCH }

@export var patrol_points: Array[Vector3] = []
@export var detection_range := 13.0
@export var attack_range := 1.6
@export var move_speed := 2.2
@export var chase_speed := 4.0

var state := State.PATROL
var _patrol_index := 0
var _search_time := 0.0
var _attack_cooldown := 0.0
var _last_known_position := Vector3.ZERO
var _player: Node3D
var _noise_connected := false
var _spawn_position := Vector3.ZERO
var _navigation: Node
var _animation_time := 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("resettable")
	_spawn_position = global_position
	_navigation = get_tree().current_scene.find_child("NavigationGraph", true, false)
	_find_player()
	if patrol_points.is_empty():
		patrol_points = [global_position + Vector3(-5, 0, 0), global_position + Vector3(5, 0, 0)]

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_find_player()
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var distance := global_position.distance_to(_player.global_position)
	if bool(_player.get("is_hidden")):
		if state == State.CHASE:
			state = State.SEARCH
			_search_time = 2.5
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
		move_and_slide()
		return
	if distance <= detection_range and _can_see_player():
		if state != State.CHASE:
			AudioManager.play_stinger()
		state = State.CHASE
		_last_known_position = _player.global_position
	elif state == State.CHASE:
		state = State.SEARCH
		_search_time = 4.0
	if state == State.PATROL:
		_move_towards(patrol_points[_patrol_index], move_speed)
		if global_position.distance_to(patrol_points[_patrol_index]) < 0.8:
			_patrol_index = (_patrol_index + 1) % patrol_points.size()
	elif state == State.CHASE:
		_move_towards(_player.global_position, chase_speed)
		if distance <= attack_range and _attack_cooldown <= 0.0:
			_player.call("receive_damage", 12.0)
			_attack_cooldown = 1.2
	elif state == State.INVESTIGATE:
		_move_towards(_last_known_position, move_speed * 1.25)
		_search_time -= delta
		if _search_time <= 0.0 or global_position.distance_to(_last_known_position) < 0.8:
			state = State.SEARCH
			_search_time = 3.0
	elif state == State.SEARCH:
		_move_towards(_last_known_position, move_speed)
		_search_time -= delta
		if _search_time <= 0.0 or global_position.distance_to(_last_known_position) < 0.9:
			state = State.PATROL
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _process(delta: float) -> void:
	_animation_time += delta
	var visual := get_node_or_null("VisualBody")
	if visual == null:
		return
	var stride_rate := 13.0 if state == State.CHASE else 7.0
	var stride := sin(_animation_time * stride_rate) * 0.42
	var is_moving := Vector2(velocity.x, velocity.z).length() > 0.35
	visual.position.y = 0.9 + (absf(stride) * 0.055 if is_moving else sin(_animation_time * 1.8) * 0.025)
	visual.rotation.z = sin(_animation_time * 2.2) * 0.045
	var left_arm := visual.get_node_or_null("ArmLeft")
	var right_arm := visual.get_node_or_null("ArmRight")
	if left_arm != null and right_arm != null:
		left_arm.rotation.x = stride if is_moving else 0.08
		right_arm.rotation.x = -stride if is_moving else -0.08

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(_player) and _player.has_signal("noise_emitted") and not _noise_connected:
		_player.connect("noise_emitted", _on_player_noise)
		_noise_connected = true

func _on_player_noise(noise_position: Vector3, strength: float) -> void:
	if state == State.CHASE or global_position.distance_to(noise_position) > 18.0 * strength:
		return
	state = State.INVESTIGATE
	_last_known_position = noise_position
	_search_time = 4.0

func reset_interactable() -> void:
	global_position = _spawn_position
	velocity = Vector3.ZERO
	state = State.PATROL
	_patrol_index = 0
	_search_time = 0.0
	_attack_cooldown = 0.0

func _move_towards(target: Vector3, speed: float) -> void:
	if is_instance_valid(_navigation):
		target = _navigation.call("get_waypoint", global_position, target)
	var offset := target - global_position
	offset.y = 0.0
	if offset.length_squared() > 0.05:
		var direction := offset.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

func _can_see_player() -> bool:
	var origin := global_position + Vector3.UP * 1.5
	var target := _player.global_position + Vector3.UP
	var to_player := (target - origin).normalized()
	var forward := -global_transform.basis.z
	if forward.dot(to_player) < cos(deg_to_rad(55.0)):
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == _player
