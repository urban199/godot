extends Node
@export var third_person_camera: Camera3D
@export var first_person_camera: Camera3D
var first_person := false
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_camera"):
        first_person = not first_person
        if is_instance_valid(third_person_camera):
            third_person_camera.current = not first_person
        if is_instance_valid(first_person_camera):
            first_person_camera.current = first_person
