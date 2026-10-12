extends Area3D

@export var event_id := "laboratory_power_flicker"
@export var event_message := "Something moved beyond the laboratory glass."
var _fired := false

func _ready() -> void:
	add_to_group("resettable")
	body_entered.connect(_on_body_entered)
	call_deferred("_restore_event_state")

func _restore_event_state() -> void:
	_fired = SaveSystem.has_world_event(event_id)

func _on_body_entered(body: Node3D) -> void:
	if _fired or not body.is_in_group("player"):
		return
	_fired = true
	SaveSystem.mark_world_event(event_id)
	Objectives.discover_area("laboratory")
	SaveSystem.save_game(body, "laboratory_event")
	body.call("show_message", event_message)
	AudioManager.play_stinger()
	var lights := get_tree().get_nodes_in_group("facility_lights")
	for light in lights:
		if light is OmniLight3D:
			var tween := create_tween()
			tween.tween_property(light, "light_energy", 0.0, 0.08)
			tween.tween_property(light, "light_energy", 0.45, 0.12)
			tween.tween_property(light, "light_energy", 0.0, 0.07)
			tween.tween_property(light, "light_energy", 0.28, 0.35)

func reset_interactable() -> void:
	_fired = SaveSystem.has_world_event(event_id)
