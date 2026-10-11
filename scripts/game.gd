extends Node3D

var defeated := 0
var total_enemies := 1
var won := false
var lost := false
var power_restored := false
var pause_open := false
var inventory_open := false
var checkpoint_position := Vector3(0, 1, 7)
const SAVE_SYSTEM = preload("res://scripts/save_system.gd")
var facade_frame_material: StandardMaterial3D
var facade_trim_material: StandardMaterial3D
var facade_roof_detail_material: StandardMaterial3D
var facade_sign_material: StandardMaterial3D
@onready var player = $Player
@onready var objective: Label = $HUD/Objective
@onready var health_label: Label = $HUD/Health
@onready var ammo_label: Label = $HUD/Ammo
@onready var message: Label = $HUD/Message
@onready var exit_door: MeshInstance3D = $ExitDoor
var interaction_prompt_label: Label
var overlay_label: Label

func _ready() -> void:
	add_to_group("game")
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.health_changed.connect(_on_health_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.fired.connect(_on_fired)
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	objective.text = "Tujuan: temukan sekering di minimarket"
	message.text = ""
	$HUD.process_mode = Node.PROCESS_MODE_ALWAYS
	_build_vertical_environment()
	_setup_vertical_slice()
	_build_runtime_hud()
	_restore_checkpoint_if_available()

func _process(_delta: float) -> void:
	if pause_open or inventory_open or won or lost: return
	if defeated >= total_enemies and power_restored:
		objective.text = "Tujuan: keluar dari distrik melalui gerbang utara"
		exit_door.get_active_material(0).emission_enabled = true
	if Input.is_key_pressed(KEY_R) and (won or lost): get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and not pause_open:
		toggle_inventory_menu()
		get_viewport().set_input_as_handled()

func toggle_pause_menu() -> void:
	_toggle_pause()

func toggle_inventory_menu() -> void:
	if pause_open:
		return
	inventory_open = not inventory_open
	get_tree().paused = inventory_open
	_refresh_overlay()

func _toggle_pause() -> void:
	pause_open = not pause_open
	get_tree().paused = pause_open
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pause_open else Input.MOUSE_MODE_CAPTURED
	player.set_controls_locked(pause_open or inventory_open)
	_refresh_overlay()

func _build_runtime_hud() -> void:
	interaction_prompt_label = Label.new()
	interaction_prompt_label.name = "InteractionPrompt"
	interaction_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_prompt_label.position = Vector2(-240, -92)
	interaction_prompt_label.size = Vector2(480, 42)
	interaction_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.64))
	interaction_prompt_label.add_theme_font_size_override("font_size", 20)
	$HUD.add_child(interaction_prompt_label)
	overlay_label = Label.new()
	overlay_label.name = "MenuOverlay"
	overlay_label.set_anchors_preset(Control.PRESET_CENTER)
	overlay_label.position = Vector2(-250, -130)
	overlay_label.size = Vector2(500, 260)
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	overlay_label.add_theme_font_size_override("font_size", 23)
	overlay_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	overlay_label.add_theme_constant_override("shadow_offset_x", 2)
	overlay_label.add_theme_constant_override("shadow_offset_y", 2)
	overlay_label.visible = false
	$HUD.add_child(overlay_label)
	$HUD/Objective.text = "Tujuan: temukan sekering di minimarket"
	$HUD/Health.text = "Kesehatan: %d" % player.health
	$HUD/Ammo.text = "Amunisi: %d / %d" % [player.ammo, player.reserve_ammo]
	$HUD/Title.text = "NEKO NIGHTFALL — MALAM TERAKHIR"

func _refresh_overlay() -> void:
	if not is_instance_valid(overlay_label):
		return
	if pause_open:
		overlay_label.text = "JEDA\nEscape — lanjutkan\nTab — inventaris\nQ — gunakan P3K"
		overlay_label.visible = true
	elif inventory_open:
		var items: Dictionary = player.inventory
		overlay_label.text = "INVENTARIS\nAmunisi: %d / %d\nP3K: %d\nSekering: %d\nTab — tutup" % [player.ammo, player.reserve_ammo, int(items.get("medkit", 0)), int(items.get("fuse", 0))]
		overlay_label.visible = true
	else:
		overlay_label.visible = false
	player.set_controls_locked(pause_open or inventory_open)

func set_interaction_prompt(text: String) -> void:
	if is_instance_valid(interaction_prompt_label):
		interaction_prompt_label.text = text
		interaction_prompt_label.visible = not text.is_empty()

func interaction_prompt(target_node: Node3D, _actor: Node3D) -> String:
	match String(target_node.get("kind")):
		"fuse": return "E — ambil sekering" if not player.has_item("fuse") else "Sekering sudah diambil"
		"panel": return "E — pasang sekering" if player.has_item("fuse") and not power_restored else "Panel listrik: perlu sekering"
		"checkpoint": return "E — simpan di pos pemeriksaan"
		"exit": return "E — buka gerbang" if power_restored and defeated >= total_enemies else "Gerbang terkunci: aktifkan listrik dan bersihkan ancaman"
		_: return "E — berinteraksi"

func interact_with(target_node: Node3D, actor: Node3D) -> void:
	if not is_instance_valid(target_node):
		return
	match String(target_node.get("kind")):
		"fuse":
			if not actor.has_item("fuse"):
				actor.add_item("fuse")
				target_node.queue_free()
				objective.text = "Tujuan: pasang sekering pada panel listrik"
		"panel":
			if actor.consume_item("fuse"):
				power_restored = true
				var panel_light := target_node.get_node_or_null("MeshInstance3D") as MeshInstance3D
				if panel_light and panel_light.mesh:
					var panel_material := _make_emissive_material(Color(0.12, 0.78, 0.42), 1.5)
					panel_light.material_override = panel_material
				objective.text = "Tujuan: kalahkan infected dan capai gerbang"
		"checkpoint":
			checkpoint_position = target_node.global_position + Vector3(0, 1, 1.4)
			_save_checkpoint()
			message.text = "Pos pemeriksaan tersimpan"
		"exit":
			if power_restored and defeated >= total_enemies:
				won = true
			actor.call("set_controls_locked", true)
				message.text = "KAMU BERHASIL KELUAR\nR — mulai ulang"
	set_interaction_prompt("")

func _setup_vertical_slice() -> void:
	# Keep one encounter active for the first playable mission slice.
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
		if enemy != get_node_or_null("ZombieA"):
			enemy.remove_from_group("enemy")
			enemy.queue_free()
	var door_material := exit_door.get_active_material(0) as StandardMaterial3D
	if door_material:
		door_material.emission_enabled = false
	exit_door.position = Vector3(0, 1.5, -42)
	_add_interactable("FusePickup", "fuse", Vector3(0, 0.45, -14), Color(0.8, 0.62, 0.12))
	_add_interactable("PowerPanel", "panel", Vector3(3.2, 1.1, -20), Color(0.52, 0.12, 0.08))
	_add_interactable("Checkpoint", "checkpoint", Vector3(-3.5, 0.45, -9), Color(0.1, 0.55, 0.48))
	_add_interactable("ExitInteraction", "exit", Vector3(0, 1.0, -40), Color(0.06, 0.36, 0.82))
	objective.text = "Tujuan: ambil sekering di ujung gang"
	var enemy := get_node_or_null("ZombieA")
	if enemy:
		enemy.position = Vector3(-2.8, 1, -7)

func _build_vertical_environment() -> void:
	var asphalt := _make_material(Color(0.075, 0.082, 0.095), 0.96)
	var concrete := _make_material(Color(0.23, 0.22, 0.21), 0.94)
	var brick := _make_material(Color(0.19, 0.115, 0.10), 0.92)
	var trim := _make_material(Color(0.075, 0.082, 0.09), 0.84)
	var sign_material := _make_emissive_material(Color(0.56, 0.12, 0.08), 0.8)
	_add_box_prop("SliceRoad", Vector3(0, -0.04, -18), Vector3(18, 0.08, 58), asphalt)
	_add_box_prop("AlleyWallWest", Vector3(-10, 3.3, -18), Vector3(1.0, 6.6, 60), brick, true)
	_add_box_prop("AlleyWallEast", Vector3(10, 3.3, -18), Vector3(1.0, 6.6, 60), concrete, true)
	_add_box_prop("AlleyEndWall", Vector3(0, 3.3, -49), Vector3(21, 6.6, 1.0), brick, true)
	# Compact shop shell with an open front and traversable interior.
	_add_box_prop("ShopBackWall", Vector3(0, 2.0, -29), Vector3(10.5, 4.0, 0.45), concrete, true)
	_add_box_prop("ShopLeftWall", Vector3(-5.2, 2.0, -21.5), Vector3(0.45, 4.0, 15.0), concrete, true)
	_add_box_prop("ShopRightWall", Vector3(5.2, 2.0, -21.5), Vector3(0.45, 4.0, 15.0), concrete, true)
	_add_box_prop("ShopRoof", Vector3(0, 4.1, -21.5), Vector3(10.8, 0.3, 15.4), trim)
	_add_box_prop("ShopSign", Vector3(0, 3.25, -14.0), Vector3(4.8, 0.75, 0.2), sign_material)
	_add_box_prop("CoverVan", Vector3(-6.6, 0.75, -2.0), Vector3(3.4, 1.5, 6.0), trim, true)
	_add_box_prop("RoadBarrier", Vector3(6.2, 0.6, -34.0), Vector3(2.2, 1.2, 1.1), brick, true)
	_add_street_light("SliceStreetLight", Vector3(7.0, 0, -11))
	_add_street_light("ShopLight", Vector3(-3.8, 0, -24))

func _add_interactable(node_name: String, interaction_kind: String, at: Vector3, color: Color) -> void:
	var area := Area3D.new()
	area.name = node_name
	area.set_script(load("res://scripts/interactable.gd"))
	area.set("kind", interaction_kind)
	area.position = at
	area.collision_layer = 0
	area.collision_mask = 1
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.8
	collision.shape = sphere
	area.add_child(collision)
	var marker := MeshInstance3D.new()
	marker.name = "MeshInstance3D"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.42, 0.72, 0.18)
	marker.mesh = mesh
	var marker_material := _make_emissive_material(color, 0.9)
	marker.material_override = marker_material
	area.add_child(marker)
	add_child(area)

func _save_checkpoint() -> void:
	var data := {"player": player.get_checkpoint_data(), "checkpoint_position": [checkpoint_position.x, checkpoint_position.y, checkpoint_position.z], "power_restored": power_restored, "defeated": defeated}
	SAVE_SYSTEM.save_checkpoint(data)

func _restore_checkpoint_if_available() -> void:
	var data: Dictionary = SAVE_SYSTEM.load_checkpoint()
	if data.is_empty():
		return
	var player_data: Variant = data.get("player", {})
	if player_data is Dictionary:
		player.restore_checkpoint_data(player_data)
	var saved_checkpoint: Variant = data.get("checkpoint_position", [])
	if saved_checkpoint is Array and saved_checkpoint.size() == 3:
		checkpoint_position = Vector3(float(saved_checkpoint[0]), float(saved_checkpoint[1]), float(saved_checkpoint[2]))
	power_restored = bool(data.get("power_restored", false))
	defeated = clampi(int(data.get("defeated", 0)), 0, total_enemies)
	if defeated >= total_enemies:
		for enemy in get_tree().get_nodes_in_group("enemy"):
			enemy.queue_free()

func enemy_defeated() -> void:
	defeated += 1
	objective.text = "Tujuan: aktifkan listrik di panel" if not power_restored else "Tujuan: capai gerbang utara"

func player_died() -> void:
	lost = true
	message.text = "KAMU TUMBANG\nR — mulai ulang"

func collect_pickup(kind: String) -> void:
	if kind == "ammo": player.collect_ammo(12)
	if kind == "medkit": player.add_item("medkit")

func _on_health_changed(value: int) -> void: health_label.text = "Kesehatan: %d" % value
func _on_ammo_changed(current: int, reserve: int) -> void: ammo_label.text = "Amunisi: %d / %d" % [current, reserve]
func _on_fired() -> void: message.text = ""

func _build_city_district() -> void:
    _ensure_facade_detail_materials()
    var building_materials: Array[StandardMaterial3D] = []
    for color in [Color(0.16, 0.22, 0.32), Color(0.32, 0.18, 0.24), Color(0.16, 0.32, 0.30), Color(0.38, 0.25, 0.14), Color(0.24, 0.18, 0.38)]:
        var material := StandardMaterial3D.new()
        material.albedo_color = color
        material.roughness = 0.86
        building_materials.append(material)

    var blocks := [
        Vector3(-25, 5.2, -20), Vector3(-13, 6.1, -20), Vector3(13, 5.7, -20), Vector3(25, 5.0, -20),
        Vector3(-25, 5.0, 20), Vector3(-13, 5.7, 20), Vector3(13, 6.2, 20), Vector3(25, 5.2, 20),
        Vector3(-31, 5.0, -9), Vector3(31, 5.8, -10), Vector3(-31, 6.3, 10), Vector3(31, 5.0, 11),
        Vector3(-48, 5.8, -30), Vector3(0, 5.3, -36), Vector3(48, 6.2, -30),
        Vector3(-48, 5.3, 30), Vector3(0, 5.8, 36), Vector3(48, 5.0, 30),
        Vector3(-48, 5.0, -6), Vector3(48, 5.0, 6), Vector3(-38, 5.5, -38), Vector3(38, 5.5, 38)
    ]
    var sizes := [
        Vector3(13, 10.4, 10), Vector3(12, 12.2, 10), Vector3(12, 11.4, 10), Vector3(13, 10.0, 10),
        Vector3(13, 10.0, 10), Vector3(12, 11.4, 10), Vector3(12, 12.4, 10), Vector3(13, 10.4, 10),
        Vector3(9, 10.0, 14), Vector3(9, 11.6, 14), Vector3(9, 12.6, 14), Vector3(9, 10.0, 14),
        Vector3(14, 11.6, 11), Vector3(16, 10.6, 11), Vector3(14, 12.4, 11),
        Vector3(14, 10.6, 11), Vector3(16, 11.6, 11), Vector3(14, 10.0, 11),
        Vector3(11, 10.0, 12), Vector3(11, 10.0, 12), Vector3(13, 11.0, 10), Vector3(13, 11.0, 10)
    ]

    for index in range(blocks.size()):
        var body := StaticBody3D.new()
        body.name = "CityBuilding_%02d" % index
        body.position = blocks[index]

        var facade := MeshInstance3D.new()
        var facade_mesh := BoxMesh.new()
        facade_mesh.size = sizes[index]
        facade_mesh.material = building_materials[index % building_materials.size()]
        facade.mesh = facade_mesh
        body.add_child(facade)

        var roof_material := _make_material(Color(0.075, 0.085, 0.12, 1.0), 0.92)
        _add_child_box(body, "RoofCap", Vector3(sizes[index].x + 0.55, 0.38, sizes[index].z + 0.55), Vector3(0, sizes[index].y * 0.5 + 0.19, 0), roof_material)

        var door_material := _make_material(Color(0.095, 0.055, 0.045, 1.0), 0.88)
        _add_child_box(body, "EntryDoor", Vector3(1.35, 2.45, 0.16), Vector3(sizes[index].x * 0.24, -sizes[index].y * 0.5 + 1.23, -sizes[index].z * 0.5 - 0.09), door_material)
        var door_light := _make_emissive_material(Color(0.95, 0.48, 0.12, 1.0), 0.65)
        _add_child_box(body, "DoorLamp", Vector3(0.24, 0.18, 0.15), Vector3(sizes[index].x * 0.24 - 0.9, -sizes[index].y * 0.5 + 2.35, -sizes[index].z * 0.5 - 0.14), door_light)

        var trim_material := _make_material(Color(0.10, 0.12, 0.17, 1.0), 0.82)
        _add_child_box(body, "FrontBeltline", Vector3(sizes[index].x + 0.08, 0.16, 0.12), Vector3(0, -sizes[index].y * 0.12, -sizes[index].z * 0.5 - 0.08), trim_material)

        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = sizes[index]
        collision.shape = shape
        body.add_child(collision)
        add_child(body)

        _add_window_strip(body, sizes[index], index)
        _add_facade_architecture(body, sizes[index], index)

    _add_expanded_city()
    _add_city_detail()

func _add_expanded_city() -> void:
    var palette := [
        Color(0.105, 0.13, 0.17, 1.0), Color(0.19, 0.12, 0.13, 1.0),
        Color(0.12, 0.17, 0.16, 1.0), Color(0.22, 0.18, 0.13, 1.0),
        Color(0.14, 0.13, 0.20, 1.0)
    ]
    var roof_material := _make_material(Color(0.045, 0.05, 0.065, 1.0), 0.96)
    var trim_material := _make_material(Color(0.065, 0.07, 0.08, 1.0), 0.88)

    # A connected road grid continues beyond the original compact encounter block.
    var asphalt := _make_material(Color(0.035, 0.04, 0.047, 1.0), 0.98)
    for x in [-140, -110, -80, 80, 110, 140]:
        _add_box_prop("OuterStreet_NS_%d" % x, Vector3(x, 0.018, 0), Vector3(7.5, 0.06, 270), asphalt)
    for z in [-105, -75, 75, 105]:
        _add_box_prop("OuterStreet_EW_%d" % z, Vector3(0, 0.02, z), Vector3(360, 0.06, 7.5), asphalt)

    var x_centers := [-155, -125, -95, -65, 65, 95, 125, 155]
    var z_centers := [-120, -90, -60, 60, 90, 120]
    var building_index := 0
    for x_index in range(x_centers.size()):
        for z_index in range(z_centers.size()):
            var width := 18.0 + float((x_index * 3 + z_index) % 3) * 1.5
            var depth := 17.0 + float((x_index + z_index * 2) % 3)
            var height := 10.0 + float((x_index * 5 + z_index * 3) % 7)
            var size := Vector3(width, height, depth)
            var center := Vector3(x_centers[x_index], height * 0.5, z_centers[z_index])
            var building := StaticBody3D.new()
            building.name = "OuterCityBuilding_%02d" % building_index
            building.position = center

            var facade := MeshInstance3D.new()
            var facade_mesh := BoxMesh.new()
            facade_mesh.size = size
            facade_mesh.material = _make_material(palette[building_index % palette.size()], 0.94)
            facade.mesh = facade_mesh
            building.add_child(facade)
            _add_child_box(building, "FlatRoof", Vector3(width + 0.45, 0.32, depth + 0.45), Vector3(0, height * 0.5 + 0.16, 0), roof_material)
            _add_child_box(building, "ConcreteTrim", Vector3(width + 0.08, 0.18, 0.12), Vector3(0, -height * 0.12, -depth * 0.5 - 0.07), trim_material)

            var collision := CollisionShape3D.new()
            var shape := BoxShape3D.new()
            shape.size = size
            collision.shape = shape
            building.add_child(collision)
            add_child(building)
            var detailed_building := building_index % 3 == 0
            _add_window_strip(building, size, building_index + 1, detailed_building)
            if detailed_building:
                _add_facade_architecture(building, size, building_index + 1)
            building_index += 1

    # Sparse, weak street lamps and abandoned cars extend the horror atmosphere into the outskirts.
    for i in range(8):
        var z := -112 + i * 32
        _add_street_light("OuterLamp_W_%02d" % i, Vector3(-76, 0, z))
        _add_street_light("OuterLamp_E_%02d" % i, Vector3(76, 0, z))
    var wreck_positions := [Vector3(-72, 0.45, -84), Vector3(72, 0.45, -48), Vector3(-72, 0.45, 84), Vector3(72, 0.45, 108)]
    for i in range(wreck_positions.size()):
        _add_abandoned_car("OuterWreck_%02d" % i, wreck_positions[i], _make_material(Color(0.16, 0.055, 0.045, 1.0), 0.9), i % 2 == 0)

func _add_window_strip(parent: Node3D, size: Vector3, index: int, detailed := true) -> void:
    var window_colors := [Color(0.82, 0.24, 0.09), Color(0.12, 0.46, 0.66), Color(0.48, 0.18, 0.62), Color(0.76, 0.52, 0.16)]
    var window_material := _make_emissive_material(window_colors[index % window_colors.size()], 0.75)
    var dark_glass := _make_material(Color(0.025, 0.045, 0.065, 1.0), 0.28)
    var window_width := maxf(1.3, size.x * 0.42)
    var front_z := -size.z * 0.5 - 0.08

    for row in range(3):
        var window_y := -size.y * 0.30 + row * 2.15
        var glass_material := dark_glass if (row + index) % 4 == 0 else window_material
        var window_position := Vector3(-size.x * 0.12, window_y, front_z)
        if detailed:
            _add_child_box(parent, "WindowFrame_%d" % row, Vector3(window_width + 0.28, 0.96, 0.14), window_position, facade_frame_material)
            _add_child_box(parent, "WindowGlass_%d" % row, Vector3(window_width, 0.68, 0.055), window_position + Vector3(0, 0, -0.095), glass_material)
            _add_child_box(parent, "WindowSill_%d" % row, Vector3(window_width + 0.42, 0.10, 0.22), window_position + Vector3(0, -0.52, -0.04), facade_trim_material)
        else:
            _add_child_box(parent, "WindowGlass_%d" % row, Vector3(window_width, 0.72, 0.10), window_position, glass_material)

func _ensure_facade_detail_materials() -> void:
    if facade_frame_material:
        return
    facade_frame_material = _make_material(Color(0.055, 0.065, 0.078, 1.0), 0.62)
    facade_trim_material = _make_material(Color(0.27, 0.29, 0.31, 1.0), 0.78)
    facade_roof_detail_material = _make_material(Color(0.075, 0.085, 0.095, 1.0), 0.86)
    facade_sign_material = _make_emissive_material(Color(0.42, 0.055, 0.035, 1.0), 0.9)

func _add_facade_architecture(parent: Node3D, size: Vector3, index: int) -> void:
    var front_z := -size.z * 0.5 - 0.10
    var column_height := maxf(size.y - 0.45, 1.0)
    for side in [-1.0, 1.0]:
        _add_child_box(parent, "FacadePier_%s" % str(side), Vector3(0.22, column_height, 0.20), Vector3(side * (size.x * 0.5 - 0.18), 0, front_z), facade_trim_material)
    var floor_count := floori(size.y / 3.0)
    for floor_index in range(1, floor_count):
        var band_y := -size.y * 0.5 + floor_index * 3.0
        _add_child_box(parent, "FloorBand_%d" % floor_index, Vector3(size.x + 0.16, 0.12, 0.20), Vector3(0, band_y, front_z), facade_trim_material)
    # Rooftop HVAC units and exhaust stacks add a readable skyline without lights or heavy assets.
    for unit_index in range(2):
        var unit_x := -size.x * 0.22 + unit_index * size.x * 0.44
        _add_child_box(parent, "RoofHVAC_%d" % unit_index, Vector3(1.5, 0.72, 1.1), Vector3(unit_x, size.y * 0.5 + 0.52, 0), facade_roof_detail_material)
        _add_child_box(parent, "RoofHVACGrille_%d" % unit_index, Vector3(0.92, 0.10, 0.07), Vector3(unit_x, size.y * 0.5 + 0.54, -0.57), facade_trim_material)
    if index % 5 == 0:
        _add_child_box(parent, "FadedShopSign", Vector3(minf(size.x * 0.48, 4.8), 0.52, 0.12), Vector3(0, -size.y * 0.5 + 3.35, front_z - 0.12), facade_sign_material)

func _add_city_detail() -> void:
    var asphalt := _make_material(Color(0.055, 0.06, 0.07, 1.0), 0.96)
    var sidewalk := _make_material(Color(0.22, 0.22, 0.24, 1.0), 0.9)
    var stripe := _make_emissive_material(Color(0.95, 0.78, 0.22, 1.0), 0.35)
    var metal := _make_material(Color(0.09, 0.10, 0.12, 1.0), 0.82)
    var car_red := _make_material(Color(0.45, 0.05, 0.04, 1.0), 0.68)
    var car_blue := _make_material(Color(0.04, 0.12, 0.34, 1.0), 0.68)
    var wood := _make_material(Color(0.28, 0.15, 0.07, 1.0), 0.86)

    _add_box_prop("MainRoad_NS", Vector3(0, 0.02, 0), Vector3(13.5, 0.08, 270), asphalt)
    _add_box_prop("MainRoad_EW", Vector3(0, 0.03, 0), Vector3(360, 0.08, 13.5), asphalt)
    _add_box_prop("NorthRoad", Vector3(0, 0.025, -28), Vector3(360, 0.08, 8), asphalt)
    _add_box_prop("SouthRoad", Vector3(0, 0.025, 28), Vector3(360, 0.08, 8), asphalt)
    _add_box_prop("WestRoad", Vector3(-40, 0.025, 0), Vector3(8, 0.08, 86), asphalt)
    _add_box_prop("EastRoad", Vector3(40, 0.025, 0), Vector3(8, 0.08, 86), asphalt)

    for x in [-53, -28, -14, 14, 28, 53]:
        _add_box_prop("Sidewalk_N_%d" % x, Vector3(x, 0.07, -34), Vector3(10, 0.12, 2.2), sidewalk)
        _add_box_prop("Sidewalk_S_%d" % x, Vector3(x, 0.07, 34), Vector3(10, 0.12, 2.2), sidewalk)
    for z in [-38, -22, 22, 38]:
        _add_box_prop("Sidewalk_W_%d" % z, Vector3(-46, 0.07, z), Vector3(2.2, 0.12, 12), sidewalk)
        _add_box_prop("Sidewalk_E_%d" % z, Vector3(46, 0.07, z), Vector3(2.2, 0.12, 12), sidewalk)

    for z in range(-36, 41, 12):
        _add_box_prop("RoadStripe_NS_%d" % z, Vector3(0, 0.09, z), Vector3(0.34, 0.04, 4.8), stripe)
    for x in range(-48, 53, 12):
        _add_box_prop("RoadStripe_EW_%d" % x, Vector3(x, 0.1, 0), Vector3(4.8, 0.04, 0.34), stripe)

    var car_positions := [
        Vector3(-8, 0.45, -12), Vector3(9, 0.45, 13), Vector3(-34, 0.45, 16), Vector3(35, 0.45, -18), Vector3(-18, 0.45, 30), Vector3(20, 0.45, -29)
    ]
    for i in range(car_positions.size()):
        _add_abandoned_car("AbandonedCar_%02d" % i, car_positions[i], car_red if i % 2 == 0 else car_blue, i % 2 == 0)

    var light_positions := [
        Vector3(-8, 0, -30), Vector3(8, 0, -30), Vector3(-8, 0, 30), Vector3(8, 0, 30),
        Vector3(-36, 0, -8), Vector3(-36, 0, 8), Vector3(36, 0, -8), Vector3(36, 0, 8),
        Vector3(-52, 0, -36), Vector3(52, 0, -36), Vector3(-52, 0, 36), Vector3(52, 0, 36)
    ]
    for i in range(light_positions.size()):
        _add_street_light("StreetLight_%02d" % i, light_positions[i])

    for x in [-54, -42, -30, 30, 42, 54]:
        _add_procedural_tree("Tree_%d_N" % x, Vector3(x, 0, -40), 2.2)
        _add_procedural_tree("Tree_%d_S" % x, Vector3(x, 0, 40), 2.2)
    for z in [-30, -18, 18, 30]:
        _add_procedural_planter("Planter_W_%d" % z, Vector3(-52, 0, z), 2.4)
        _add_procedural_planter("Planter_E_%d" % z, Vector3(52, 0, z), 2.4)

    for i in range(10):
        var x := -48 + i * 10
        _add_box_prop("LargeCrate_%02d" % i, Vector3(x, 0.55, -6 if i % 2 == 0 else 6), Vector3(1.25, 1.1, 1.25), wood, true)
    for i in range(8):
        var z := -32 + i * 9
        _add_bench("Bench_%02d" % i, Vector3(-12 if i % 2 == 0 else 12, 0.42, z), wood, metal)

    for z in [-34, -22, -10, 10, 22, 34]:
        _add_fence_section("FenceLeft_%d" % z, Vector3(-57, 0, z), 9.0)
        _add_fence_section("FenceRight_%d" % z, Vector3(57, 0, z), 9.0)

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    return material

func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
    var material := _make_material(color, 0.55)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = energy
    return material

func _add_child_box(parent: Node3D, name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    instance.mesh = mesh
    instance.position = position
    parent.add_child(instance)
    return instance

func _add_child_ellipsoid(parent: Node3D, name: String, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = name
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.material = material
    instance.mesh = mesh
    instance.position = position
    instance.scale = size
    parent.add_child(instance)
    return instance

func _add_procedural_tree(name: String, position: Vector3, scale: float) -> void:
    var tree := StaticBody3D.new()
    tree.name = name
    tree.position = position
    add_child(tree)
    var bark := _make_material(Color(0.16, 0.105, 0.075, 1.0), 0.96)
    var trunk_height := 3.25 * scale
    var trunk := CylinderMesh.new()
    trunk.top_radius = 0.18 * scale
    trunk.bottom_radius = 0.34 * scale
    trunk.height = trunk_height
    trunk.radial_segments = 8
    trunk.material = bark
    var trunk_mesh := MeshInstance3D.new()
    trunk_mesh.mesh = trunk
    trunk_mesh.position.y = trunk_height * 0.5
    tree.add_child(trunk_mesh)
    var foliage := [
        _make_material(Color(0.055, 0.15, 0.12, 1.0), 0.98),
        _make_material(Color(0.075, 0.21, 0.16, 1.0), 0.98),
        _make_material(Color(0.11, 0.24, 0.18, 1.0), 0.98)
    ]
    _add_child_ellipsoid(tree, "CanopyCore", Vector3(0, trunk_height + 0.6 * scale, 0), Vector3(2.35, 2.0, 2.25) * scale, foliage[0])
    _add_child_ellipsoid(tree, "CanopyLeft", Vector3(-0.72 * scale, trunk_height + 0.1 * scale, 0.12 * scale), Vector3(1.55, 1.45, 1.6) * scale, foliage[1])
    _add_child_ellipsoid(tree, "CanopyRight", Vector3(0.68 * scale, trunk_height + 0.15 * scale, -0.08 * scale), Vector3(1.6, 1.55, 1.65) * scale, foliage[2])
    var trunk_collision := CollisionShape3D.new()
    var trunk_shape := CapsuleShape3D.new()
    trunk_shape.radius = 0.34 * scale
    trunk_shape.height = trunk_height
    trunk_collision.shape = trunk_shape
    trunk_collision.position.y = trunk_height * 0.5
    tree.add_child(trunk_collision)

func _add_procedural_planter(name: String, position: Vector3, scale: float) -> void:
    var planter := Node3D.new()
    planter.name = name
    planter.position = position
    add_child(planter)
    var stone := _make_material(Color(0.24, 0.25, 0.27, 1.0), 0.94)
    var soil := _make_material(Color(0.075, 0.055, 0.04, 1.0), 1.0)
    var leaf := _make_material(Color(0.08, 0.25, 0.15, 1.0), 0.95)
    _add_child_box(planter, "StoneTrough", Vector3(0.95, 0.30, 0.52) * scale, Vector3(0, 0.25 * scale, 0), stone)
    _add_child_box(planter, "Soil", Vector3(0.82, 0.08, 0.40) * scale, Vector3(0, 0.43 * scale, 0), soil)
    for i in range(4):
        var x := (float(i) - 1.5) * 0.18 * scale
        _add_child_ellipsoid(planter, "Shrub_%d" % i, Vector3(x, 0.72 * scale + absf(x) * 0.18, 0), Vector3(0.34, 0.66, 0.38) * scale, leaf)

func _add_fence_section(name: String, position: Vector3, length: float) -> void:
    var fence := StaticBody3D.new()
    fence.name = name
    fence.position = position
    add_child(fence)
    var wood := _make_material(Color(0.18, 0.15, 0.13, 1.0), 0.94)
    var rail_size := Vector3(0.14, 0.16, length)
    _add_child_box(fence, "UpperRail", rail_size, Vector3(0, 1.18, 0), wood)
    _add_child_box(fence, "LowerRail", rail_size, Vector3(0, 0.56, 0), wood)
    for i in range(5):
        var z := -length * 0.5 + float(i) * length / 4.0
        _add_child_box(fence, "Post_%d" % i, Vector3(0.20, 1.55, 0.22), Vector3(0, 0.76, z), wood)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.22, 1.55, length)
    collision.shape = shape
    collision.position.y = 0.76
    fence.add_child(collision)

func _add_box_prop(name: String, position: Vector3, size: Vector3, material: Material, solid := false) -> Node3D:
    var parent: Node3D = StaticBody3D.new() if solid else Node3D.new()
    parent.name = name
    parent.position = position
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh.material = material
    mesh_instance.mesh = mesh
    parent.add_child(mesh_instance)
    if solid:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        parent.add_child(collision)
    add_child(parent)
    return parent

func _add_cylinder_prop(name: String, position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = name
    mesh_instance.position = position
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 12
    mesh.material = material
    mesh_instance.mesh = mesh
    add_child(mesh_instance)
    return mesh_instance

func _add_street_light(name: String, position: Vector3) -> void:
    var metal := _make_material(Color(0.06, 0.06, 0.07, 1.0), 0.65)
    var glow := _make_emissive_material(Color(1.0, 0.58, 0.22, 1.0), 2.2)
    _add_cylinder_prop(name + "_Pole", position + Vector3(0, 2.0, 0), 0.08, 4.0, metal)
    _add_box_prop(name + "_Lamp", position + Vector3(0, 4.08, 0), Vector3(0.75, 0.22, 0.75), glow)
    var light := OmniLight3D.new()
    light.name = name + "_Light"
    light.position = position + Vector3(0, 3.8, 0)
    light.omni_range = 10.5
    light.light_color = Color(1.0, 0.48, 0.20, 1.0)
    light.light_energy = 2.6
    add_child(light)

func _add_abandoned_car(name: String, position: Vector3, paint: Material, rotate_sideways: bool) -> void:
    var car := StaticBody3D.new()
    car.name = name
    car.position = position
    car.rotation.y = PI * 0.5 if rotate_sideways else 0.0
    add_child(car)

    var body_mesh := MeshInstance3D.new()
    var body_box := BoxMesh.new()
    body_box.size = Vector3(2.4, 0.7, 4.0)
    body_box.material = paint
    body_mesh.mesh = body_box
    car.add_child(body_mesh)

    var cabin_mesh := MeshInstance3D.new()
    var cabin_box := BoxMesh.new()
    cabin_box.size = Vector3(1.7, 0.75, 1.8)
    cabin_box.material = _make_material(Color(0.04, 0.06, 0.08, 1.0), 0.35)
    cabin_mesh.position = Vector3(0, 0.62, -0.2)
    cabin_mesh.mesh = cabin_box
    car.add_child(cabin_mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.5, 1.3, 4.1)
    collision.position = Vector3(0, 0.28, 0)
    collision.shape = shape
    car.add_child(collision)

func _add_bench(name: String, position: Vector3, wood: Material, metal: Material) -> void:
    var bench := Node3D.new()
    bench.name = name
    bench.position = position
    add_child(bench)

    var seat := MeshInstance3D.new()
    var seat_mesh := BoxMesh.new()
    seat_mesh.size = Vector3(2.4, 0.18, 0.55)
    seat_mesh.material = wood
    seat.mesh = seat_mesh
    bench.add_child(seat)

    var back := MeshInstance3D.new()
    var back_mesh := BoxMesh.new()
    back_mesh.size = Vector3(2.4, 0.2, 0.22)
    back_mesh.material = wood
    back.position = Vector3(0, 0.42, 0.35)
    back.rotation.x = deg_to_rad(-14.0)
    back.mesh = back_mesh
    bench.add_child(back)

    for x in [-0.85, 0.85]:
        var leg := MeshInstance3D.new()
        var leg_mesh := BoxMesh.new()
        leg_mesh.size = Vector3(0.14, 0.8, 0.14)
        leg_mesh.material = metal
        leg.position = Vector3(x, -0.35, 0.0)
        leg.mesh = leg_mesh
        bench.add_child(leg)
