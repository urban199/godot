extends RefCounted

## Loads a glTF/GLB source file directly, without depending on the editor's
## generated .godot/imported cache. This keeps runtime and headless CI behavior
## consistent when a clean checkout has not retained import artifacts.
static func load_scene(source_path: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var import_error := document.append_from_file(source_path, state)
	if import_error != OK:
		push_error("Could not parse glTF scene '%s' (error %d)." % [source_path, import_error])
		return null
	var generated_scene := document.generate_scene(state)
	if not generated_scene is Node3D:
		push_error("glTF scene '%s' did not produce a Node3D root." % source_path)
		if is_instance_valid(generated_scene):
			generated_scene.free()
		return null
	return generated_scene as Node3D
