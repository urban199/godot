extends SceneTree

const CHARACTER_PATH := "res://assets/characters/player/neko_nightfall_anime_complete/models/neko_nightfall_rigged.glb"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const REQUIRED_CLIPS := ["Idle", "Walk", "Run", "Aim", "Shoot", "Reload", "Hit", "Death"]

var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var character_scene := load(CHARACTER_PATH) as PackedScene
	if character_scene == null:
		_fail("Character GLB did not import as a PackedScene: %s" % CHARACTER_PATH)
		_finish()
		return

	var character_root := character_scene.instantiate()
	root.add_child(character_root)
	await process_frame
	var skeleton := _find_node_of_type(character_root, Skeleton3D) as Skeleton3D
	var mesh_instance := _find_node_of_type(character_root, MeshInstance3D) as MeshInstance3D
	var animation_player := _find_node_of_type(character_root, AnimationPlayer) as AnimationPlayer
	if skeleton == null:
		_fail("Imported character has no Skeleton3D.")
	elif skeleton.get_bone_count() < 18:
		_fail("Expected the humanoid skeleton (18+ bones); found %d." % skeleton.get_bone_count())
	elif skeleton.find_bone("Hand_R") < 0:
		_fail("Humanoid skeleton is missing the right-hand weapon attachment bone.")
	if mesh_instance == null or mesh_instance.mesh == null:
		_fail("Imported character has no mesh geometry.")
	else:
		if mesh_instance.mesh.get_surface_count() == 0:
			_fail("Imported character mesh has no surfaces.")
		if mesh_instance.mesh.get_aabb().size.length() < 0.5:
			_fail("Imported character mesh bounds are empty or implausibly small.")
		if mesh_instance.skin == null:
			_fail("Imported character mesh has no Skin resource; it is not skinned.")
		else:
			var surface_arrays: Array = mesh_instance.mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = surface_arrays[Mesh.ARRAY_VERTEX]
			var uvs: PackedVector2Array = surface_arrays[Mesh.ARRAY_TEX_UV]
			if vertices.is_empty() or uvs.size() != vertices.size():
				_fail("Imported character surface is missing vertex geometry or matching UV0 coordinates.")
		var has_albedo_texture := false
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var surface_material := mesh_instance.get_active_material(surface_index) as BaseMaterial3D
			if surface_material != null and surface_material.albedo_texture != null:
				has_albedo_texture = true
				break
		if not has_albedo_texture:
			_fail("Imported character materials do not resolve an albedo texture resource.")
	if animation_player == null:
		_fail("Imported character has no AnimationPlayer.")
	else:
		_validate_animations(animation_player)

	var main_scene := load(MAIN_SCENE_PATH) as PackedScene
	if main_scene == null:
		_fail("Main gameplay scene could not be loaded: %s" % MAIN_SCENE_PATH)
	else:
		var game_root := main_scene.instantiate()
		root.add_child(game_root)
		await process_frame
		var player_model := game_root.get_node_or_null("Player/PlayerModel")
		if player_model == null:
			_fail("Main scene has no Player/PlayerModel node.")
		elif not player_model.has_method("uses_imported_model") or not player_model.call("uses_imported_model"):
			_fail("Main scene fell back instead of instantiating the imported survivor GLB.")
		else:
			var gameplay_mesh := _find_node_of_type(player_model, MeshInstance3D) as MeshInstance3D
			if gameplay_mesh == null or not gameplay_mesh.is_visible_in_tree():
				_fail("Imported survivor mesh is not visible in the gameplay scene tree.")
			elif gameplay_mesh.mesh != null:
				for surface_index in range(gameplay_mesh.mesh.get_surface_count()):
					var material := gameplay_mesh.get_active_material(surface_index) as BaseMaterial3D
					if material != null and (material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.albedo_color.a < 0.99):
						_fail("Gameplay character has a transparent material on surface %d." % surface_index)
			var socket: Node3D = player_model.call("get_weapon_socket") as Node3D
			var weapon: Node = _find_node_named(game_root, "WeaponView")
			var muzzle: Node = _find_node_named(game_root, "Muzzle")
			if socket == null or weapon == null or weapon.get_parent() != socket:
				_fail("Gameplay weapon is not attached to the rig's right-hand bone socket.")
			if muzzle == null or (weapon != null and muzzle.get_parent() != weapon):
				_fail("Gameplay muzzle marker does not follow the attached weapon.")
			var player: Node = game_root.get_node_or_null("Player")
			var player_animation_player: AnimationPlayer = _find_node_of_type(player_model, AnimationPlayer) as AnimationPlayer
			if player == null:
				_fail("Main scene has no player gameplay node for damage animation testing.")
			else:
				player.call("take_damage", 1)
			if player_animation_player == null or not String(player_animation_player.current_animation).to_lower().ends_with("hit"):
				_fail("Gameplay Hit event did not start the imported Hit clip.")
			if player != null:
				player.call("take_damage", 999)
			if player_animation_player == null or not String(player_animation_player.current_animation).to_lower().ends_with("death"):
				_fail("Lethal gameplay damage did not start the imported Death clip.")

	_finish()

func _validate_animations(animation_player: AnimationPlayer) -> void:
	var animations := animation_player.get_animation_list()
	var signatures: Dictionary = {}
	for expected_name in REQUIRED_CLIPS:
		var matched_name := ""
		for clip_name in animations:
			var candidate := String(clip_name)
			if candidate.to_lower() == expected_name.to_lower() or candidate.to_lower().ends_with("/" + expected_name.to_lower()):
				matched_name = candidate
				break
		if matched_name.is_empty():
			_fail("Required animation clip is missing: %s. Imported: %s" % [expected_name, animations])
			continue
		var animation := animation_player.get_animation(matched_name)
		if animation == null or animation.length <= 0.0 or animation.get_track_count() == 0:
			_fail("Animation clip has no usable keyed tracks: %s" % expected_name)
			continue
		var signature := ""
		for track_index in range(animation.get_track_count()):
			signature += str(animation.track_get_path(track_index))
			for key_index in range(animation.track_get_key_count(track_index)):
				signature += str(animation.track_get_key_time(track_index, key_index))
				signature += str(animation.track_get_key_value(track_index, key_index))
		if signatures.has(signature):
			_fail("Animation %s duplicates the keyed content of %s." % [expected_name, signatures[signature]])
		else:
			signatures[signature] = expected_name
	print("Verified animation clips: ", REQUIRED_CLIPS)

func _find_node_of_type(current: Node, wanted_type: Variant) -> Node:
	if is_instance_of(current, wanted_type):
		return current
	for child in current.get_children():
		var found := _find_node_of_type(child, wanted_type)
		if found != null:
			return found
	return null

func _find_node_named(current: Node, wanted_name: String) -> Node:
	if current.name == wanted_name:
		return current
	for child in current.get_children():
		var found := _find_node_named(child, wanted_name)
		if found != null:
			return found
	return null

func _fail(message: String) -> void:
	errors.append(message)
	push_error(message)

func _finish() -> void:
	if errors.is_empty():
		print("Character asset and main-scene integration validation passed.")
		quit(0)
	else:
		push_error("Character validation failed with %d issue(s)." % errors.size())
		quit(1)
