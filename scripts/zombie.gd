extends CharacterBody3D

@export var max_health := 70
@export var move_speed := 2.1
@export var attack_damage := 12
var health := 70
var attack_cooldown := 0.0
var target: Node3D
var limp_time := 0.0
var defeated := false
@onready var enemy_model: Node3D = $EnemyModel

func _ready() -> void:
    health = max_health
    add_to_group("enemy")
    target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target): target = get_tree().get_first_node_in_group("player")
    if not target: return
    attack_cooldown = max(attack_cooldown - delta, 0.0)
    var offset := target.global_position - global_position
    offset.y = 0
    var distance := offset.length()
    if distance > 1.45:
        enemy_model.call("set_moving", true)
        velocity = offset.normalized() * move_speed
        look_at(global_position + Vector3(offset.x, 0, offset.z), Vector3.UP)
        move_and_slide()
        limp_time += delta * 6.0
        enemy_model.position.y = sin(limp_time) * 0.06
        enemy_model.rotation.z = sin(limp_time * 0.7) * 0.08
    else:
        enemy_model.call("set_moving", false)
        enemy_model.position.y = move_toward(enemy_model.position.y, 0.0, delta * 0.2)
        enemy_model.rotation.z = move_toward(enemy_model.rotation.z, 0.0, delta * 0.2)
        velocity = Vector3.ZERO
        if attack_cooldown <= 0.0:
            attack_cooldown = 1.1
            target.take_damage(attack_damage)

func take_damage(amount: int) -> void:
    if defeated:
        return
    health -= amount
    if health <= 0:
        defeated = true
        set_physics_process(false)
        get_tree().call_group("game", "enemy_defeated")
        _play_death_and_remove()

func _play_death_and_remove() -> void:
    var animation_duration := float(enemy_model.call("play_action", "die", false))
    if animation_duration > 0.0:
        await get_tree().create_timer(animation_duration).timeout
    queue_free()
