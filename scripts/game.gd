extends Node3D

var defeated := 0
var total_enemies := 3
var won := false
var lost := false
@onready var player = $Player
@onready var objective: Label = $HUD/Objective
@onready var health_label: Label = $HUD/Health
@onready var ammo_label: Label = $HUD/Ammo
@onready var message: Label = $HUD/Message
@onready var exit_door: MeshInstance3D = $ExitDoor

func _ready() -> void:
    add_to_group("game")
    player.health_changed.connect(_on_health_changed)
    player.ammo_changed.connect(_on_ammo_changed)
    player.fired.connect(_on_fired)
    objective.text = "Objective: survive and reach the exit"
    message.text = ""
    _build_city_district()

func _process(_delta: float) -> void:
    if won or lost: return
    if defeated >= total_enemies:
        objective.text = "Objective: the exit is unlocked — reach the blue door"
        exit_door.get_active_material(0).emission_enabled = true
        if player.global_position.distance_to(exit_door.global_position) < 2.2:
            won = true
            message.text = "YOU ESCAPED THE NIGHTFALL\nPress R to restart"
    if Input.is_key_pressed(KEY_R) and (won or lost): get_tree().reload_current_scene()

func enemy_defeated() -> void:
    defeated += 1
    objective.text = "Enemies remaining: %d" % (total_enemies - defeated)

func player_died() -> void:
    lost = true
    message.text = "YOU DID NOT MAKE IT OUT\nPress R to restart"

func collect_pickup(kind: String) -> void:
    if kind == "ammo": player.collect_ammo(12)
    if kind == "medkit": player.heal(35)

func _on_health_changed(value: int) -> void: health_label.text = "Health: %d" % value
func _on_ammo_changed(current: int, reserve: int) -> void: ammo_label.text = "Ammo: %d / %d" % [current, reserve]
func _on_fired() -> void: message.text = ""

func _build_city_district() -> void:
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
            _add_window_strip(building, size, building_index + 1)
            building_index += 1

    # Sparse, weak street lamps and abandoned cars extend the horror atmosphere into the outskirts.
    for i in range(8):
        var z := -112 + i * 32
        _add_street_light("OuterLamp_W_%02d" % i, Vector3(-76, 0, z))
        _add_street_light("OuterLamp_E_%02d" % i, Vector3(76, 0, z))
    var wreck_positions := [Vector3(-72, 0.45, -84), Vector3(72, 0.45, -48), Vector3(-72, 0.45, 84), Vector3(72, 0.45, 108)]
    for i in range(wreck_positions.size()):
        _add_abandoned_car("OuterWreck_%02d" % i, wreck_positions[i], _make_material(Color(0.16, 0.055, 0.045, 1.0), 0.9), i % 2 == 0)

func _add_window_strip(parent: Node3D, size: Vector3, index: int) -> void:
    var window_material := StandardMaterial3D.new()
    var window_colors := [Color(1.0, 0.27, 0.08), Color(0.10, 0.65, 1.0), Color(0.75, 0.20, 1.0), Color(1.0, 0.72, 0.12)]
    window_material.albedo_color = window_colors[index % window_colors.size()]
    window_material.emission_enabled = true
    window_material.emission = window_colors[index % window_colors.size()]
    window_material.emission_energy_multiplier = 1.4

    for row in range(3):
        var window := MeshInstance3D.new()
        var window_mesh := BoxMesh.new()
        window_mesh.size = Vector3(maxf(1.3, size.x * 0.42), 0.72, 0.10)
        window_mesh.material = window_material
        window.mesh = window_mesh
        window.position = Vector3(-size.x * 0.12, -size.y * 0.30 + row * 2.15, -size.z * 0.5 - 0.08)
        parent.add_child(window)

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
