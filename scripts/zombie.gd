extends CharacterBody3D

@export var max_health := 70
@export var move_speed := 2.1
@export var attack_damage := 12
@export var sight_range := 12.0
@export var hearing_range := 24.0
@export var lose_target_after := 4.0

var health := 70
var attack_cooldown := 0.0
var target: Node3D
var limp_time := 0.0
var defeated := false
var state := "idle"
var last_known_position := Vector3.ZERO
var search_time := 0.0

@onready var enemy_model: Node3D = $EnemyModel

func _ready() -> void:
    health = max_health
    add_to_group("enemy")
    target = get_tree().get_first_node_in_group("player")
    if is_instance_valid(target) and target.has_signal("noise_emitted"):
        target.noise_emitted.connect(_on_noise_emitted)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player")
    if not is_instance_valid(target) or target.get("is_dead") == true:
        return
    attack_cooldown = maxf(attack_cooldown - delta, 0.0)
    var offset: Vector3 = target.global_position - global_position
    offset.y = 0.0
    var distance: float = offset.length()
    if distance <= sight_range and _has_line_of_sight():
        state = "chase"
        last_known_position = target.global_position
        search_time = lose_target_after
    elif search_time > 0.0:
        state = "investigate"
        search_time = maxf(search_time - delta, 0.0)
    else:
        state = "idle"
    var chase_offset: Vector3 = last_known_position - global_position
    chase_offset.y = 0.0
    var chase_distance: float = chase_offset.length()
    if state != "idle" and chase_distance > 1.45:
        enemy_model.call("set_moving", true)
        velocity = chase_offset.normalized() * move_speed
        look_at(global_position + Vector3(chase_offset.x, 0.0, chase_offset.z), Vector3.UP)
        move_and_slide()
        limp_time += delta * 6.0
        enemy_model.position.y = sin(limp_time) * 0.06
        enemy_model.rotation.z = sin(limp_time * 0.7) * 0.08
    else:
        enemy_model.call("set_moving", false)
        enemy_model.position.y = move_toward(enemy_model.position.y, 0.0, delta * 0.2)
        enemy_model.rotation.z = move_toward(enemy_model.rotation.z, 0.0, delta * 0.2)
        velocity = Vector3.ZERO
        if state == "chase" and distance <= 1.45 and attack_cooldown <= 0.0 and _has_line_of_sight():
            attack_cooldown = 1.1
            target.call("take_damage", attack_damage)

func _has_line_of_sight() -> bool:
    if not is_instance_valid(target):
        return false
    var from: Vector3 = global_position + Vector3.UP * 1.1
    var to: Vector3 = target.global_position + Vector3.UP * 0.9
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid(), target.get_rid()]
    return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _on_noise_emitted(noise_position: Vector3, radius: float) -> void:
    if defeated or global_position.distance_to(noise_position) > minf(radius, hearing_range):
        return
    last_known_position = noise_position
    search_time = lose_target_after
    state = "investigate"

func take_damage(amount: int) -> void:
    if defeated or amount <= 0:
        return
    health -= amount
    if health <= 0:
        defeated = true
        set_physics_process(false)
        get_tree().call_group("game", "enemy_defeated")
        _play_death_and_remove()

func _play_death_and_remove() -> void:
    var animation_duration: float = float(enemy_model.call("play_action", "die", false))
    if animation_duration > 0.0:
        await get_tree().create_timer(animation_duration).timeout
    queue_free()
