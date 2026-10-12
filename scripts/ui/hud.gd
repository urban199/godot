extends CanvasLayer

const MapPanelScript = preload("res://scripts/ui/facility_map.gd")
const VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")

var player: Variant
var objective_title: Label
var objective_description: Label
var interaction_label: Label
var status_label: Label
var health_label: Label
var hud_root: Control
var screen_layer: Control
var _notice_timer := 0.0
var _screen_name := ""
var _settings_return := "main"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	Objectives.objective_changed.connect(_on_objective_changed)
	Objectives.objective_completed.connect(_on_objective_completed)
	if is_instance_valid(player):
		player.interaction_changed.connect(_on_interaction_changed)
		player.health_changed.connect(_on_health_changed)
		player.message_requested.connect(_on_message_requested)
	SettingsManager.settings_changed.connect(_apply_settings)
	_add_touch_controls()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_main_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			return
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_show_pause_menu()
	elif event.is_action_pressed("map"):
		if is_instance_valid(screen_layer) and not get_tree().paused:
			_resume_overlay()
			return
		_show_map()
	elif event.is_action_pressed("inventory"):
		if is_instance_valid(screen_layer) and not get_tree().paused:
			_resume_overlay()
			return
		_show_inventory()

func _process(delta: float) -> void:
	_notice_timer = maxf(0.0, _notice_timer - delta)
	if _notice_timer <= 0.0 and status_label != null:
		status_label.text = ""
	if is_instance_valid(player) and status_label != null and _notice_timer <= 0.0:
		status_label.text = "Flashlight %d%%" % int(player.flashlight_battery)

func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)
	objective_title = _label(hud_root, "Find an access card", Vector2(28, 24), 24, Color(0.86, 0.91, 0.9))
	objective_description = _label(hud_root, "Search the entrance area for a staff access card.", Vector2(28, 58), 16, Color(0.66, 0.73, 0.74))
	interaction_label = _label(hud_root, "", Vector2(0, 0), 18, Color(0.93, 0.95, 0.88))
	interaction_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_label.position.y -= 92
	status_label = _label(hud_root, "Flashlight 100%", Vector2(28, 96), 16, Color(0.72, 0.8, 0.81))
	health_label = _label(hud_root, "Health 100", Vector2(28, 120), 16, Color(0.78, 0.57, 0.55))
	_label(hud_root, "+", Vector2.ZERO, 22, Color(0.84, 0.9, 0.88)).set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_label(hud_root, "WASD Move   Shift Run   Ctrl Crouch   F Flashlight   E Interact   I Items   M Map   Esc Pause", Vector2(28, -36), 14, Color(0.55, 0.62, 0.64)).set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)

func _show_main_menu() -> void:
	_show_screen("PROJECT BLACK RAIN", _main_buttons())

func _show_pause_menu() -> void:
	_show_screen("Paused", _pause_buttons())

func _main_buttons() -> Array:
	return [["New Game", _new_game], ["Continue", _continue_game, SaveSystem.has_save()], ["Settings", _show_settings], ["Quit", _quit_game]]

func _pause_buttons() -> Array:
	return [["Resume", _resume_game], ["Save Checkpoint", _save_checkpoint], ["Settings", _show_settings], ["Main Menu", _show_main_menu]]

func _show_screen(title: String, buttons: Array) -> void:
	if is_instance_valid(screen_layer):
		screen_layer.queue_free()
	screen_layer = Control.new()
	screen_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_layer)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.008, 0.014, 0.019, 0.94)
	screen_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 360
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color(0.82, 0.88, 0.86))
	column.add_child(heading)
	if title == "Settings":
		_add_setting_selector(column, "Graphics quality", "graphics_quality", ["low", "medium", "high"])
		_add_setting_selector(column, "Visual effects", "effects_quality", ["low", "medium", "high"])
		_add_setting_selector(column, "View distance", "view_distance", ["low", "medium", "high"])
		_add_setting_selector(column, "Rain density", "rain_quality", ["low", "medium", "high"])
		_add_setting_slider(column, "Mouse sensitivity", "mouse_sensitivity")
		_add_setting_slider(column, "Touch sensitivity", "touch_sensitivity")
		_add_setting_slider(column, "Master volume", "master_volume")
		_add_setting_slider(column, "Music volume", "music_volume")
		_add_setting_slider(column, "Effects volume", "effects_volume")
		_add_menu_button(column, "Save settings", func():
			SettingsManager.save_settings()
			_return_from_settings()
		)
		_add_menu_button(column, "Back", _return_from_settings)
	elif title.begins_with("Facility map"):
		var map_panel := Control.new()
		map_panel.custom_minimum_size = Vector2(460, 150)
		map_panel.set_script(MapPanelScript)
		map_panel.set("player", player)
		column.add_child(map_panel)
	else:
		for entry in buttons:
			var enabled := bool(entry[2]) if entry.size() > 2 else true
			_add_menu_button(column, str(entry[0]), entry[1], enabled)
	_screen_name = "pause" if title == "Paused" else ("settings" if title == "Settings" else "main")

func _add_menu_button(parent: VBoxContainer, text: String, callback: Callable, enabled := true) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 44)
	button.disabled = not enabled
	button.pressed.connect(callback)
	parent.add_child(button)

func _add_setting_selector(parent: VBoxContainer, title: String, key: String, choices: Array) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var selector := OptionButton.new()
	for value in choices:
		selector.add_item(value.capitalize())
	var selected := choices.find(str(SettingsManager.get_value(key, "medium")))
	selector.select(maxi(0, selected))
	selector.item_selected.connect(func(index: int):
		SettingsManager.set_value(key, choices[index])
		SettingsManager.save_settings()
	)
	row.add_child(selector)
	parent.add_child(row)

func _add_setting_slider(parent: VBoxContainer, title: String, key: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 160
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.05 if key.contains("sensitivity") else 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(SettingsManager.get_value(key, 0.5))
	slider.value_changed.connect(func(value: float): SettingsManager.set_value(key, value))
	row.add_child(slider)
	parent.add_child(row)

func _show_settings() -> void:
	_settings_return = _screen_name
	_show_screen("Settings", [])

func _return_from_settings() -> void:
	SettingsManager.save_settings()
	if _settings_return == "pause":
		_show_pause_menu()
	else:
		_show_main_menu()

func _apply_settings() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var world := scene.get_node_or_null("World")
	if world != null:
		SettingsManager.apply_world(world)
	if get_viewport().world_3d != null:
		SettingsManager.apply_environment(get_viewport().world_3d.environment)

func _new_game() -> void:
	SaveSystem.delete_save()
	Inventory.clear()
	Objectives.restore([])
	for interactable in get_tree().get_nodes_in_group("resettable"):
		if interactable.has_method("reset_interactable"):
			interactable.reset_interactable()
	player.global_position = Vector3(0, 0.15, 7)
	player.rotation = Vector3.ZERO
	player.health = 100.0
	player.flashlight_battery = 100.0
	player.flashlight.visible = false
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	player.health_changed.emit(player.health)
	_resume_game()

func _continue_game() -> void:
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	if SaveSystem.load_game(player):
		_resume_game()
	else:
		_new_game()

func _resume_game() -> void:
	if is_instance_valid(screen_layer):
		screen_layer.queue_free()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _resume_overlay() -> void:
	if is_instance_valid(screen_layer):
		screen_layer.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _save_checkpoint() -> void:
	SaveSystem.save_game(player)
	_resume_game()

func _quit_game() -> void:
	get_tree().quit()

func _show_map() -> void:
	var position_text := "Outside" if player.global_position.z > 0.0 else ("Administration" if player.global_position.x > 4.0 and player.global_position.z > -11.0 else ("Service bay" if player.global_position.x < -4.0 else ("Entrance" if player.global_position.z > -11.0 else ("Research laboratory" if player.global_position.x > 4.0 else "Research corridor / exit"))))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_screen("Facility map\n\nYou are here: " + position_text + "\n\nEntrance → Service bay → Corridor → Exit\nM to close", [["Close", _resume_overlay]])

func _show_inventory() -> void:
	var contents := ", ".join(Inventory.items) if not Inventory.items.is_empty() else "Empty"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_screen("Inventory\n\n" + contents + "\n\nI to close", [["Close", _resume_overlay]])

func _on_message_requested(message: String) -> void:
	status_label.text = message
	_notice_timer = 8.0

func _label(parent: Control, text: String, at: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func _on_objective_changed(title: String, description: String) -> void:
	objective_title.text = title
	objective_description.text = description

func _on_objective_completed(_objective_id: String) -> void:
	status_label.text = "Objective updated"
	_notice_timer = 3.0

func _on_interaction_changed(prompt: String) -> void:
	interaction_label.text = prompt

func _on_health_changed(value: float) -> void:
	health_label.text = "Health %d" % int(value)
	if value <= 0.0:
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_show_screen("You were caught", [["Try Again", _retry_checkpoint], ["Main Menu", _show_main_menu]])

func _retry_checkpoint() -> void:
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	player.set("is_hidden", false)
	if SaveSystem.load_game(player):
		_resume_game()
	else:
		_new_game()

func _add_touch_controls() -> void:
	if not OS.has_feature("mobile"):
		return
	var joystick := Control.new()
	joystick.name = "MoveJoystick"
	joystick.set_script(VirtualJoystickScript)
	joystick.position = Vector2(24, get_viewport().get_visible_rect().size.y - 178)
	joystick.size = Vector2(150, 150)
	add_child(joystick)
	var actions := {
		"RUN": ["run", Vector2(-300, -100), "right"],
		"CROUCH": ["crouch", Vector2(-300, -175), "right"],
		"USE": ["interact", Vector2(-130, -150), "right"],
		"LIGHT": ["flashlight", Vector2(-130, -240), "right"]
	}
	for text in actions:
		var config: Array = actions[text]
		var base: Vector2 = Vector2(0, get_viewport().get_visible_rect().size.y) if config[2] == "left" else get_viewport().get_visible_rect().size
		var button_offset: Vector2 = config[1]
		var center: Vector2 = base + button_offset
		var background := Panel.new()
		background.position = center - Vector2(32, 32)
		background.size = Vector2(64, 64)
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.07, 0.08, 0.65)
		style.border_color = Color(0.62, 0.72, 0.72, 0.65)
		style.set_border_width_all(2)
		style.set_corner_radius_all(32)
		background.add_theme_stylebox_override("panel", style)
		add_child(background)
		var button := TouchScreenButton.new()
		button.action = str(config[0])
		button.position = center
		var shape := CircleShape2D.new()
		shape.radius = 30.0
		button.shape = shape
		button.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
		var caption := Label.new()
		caption.text = text
		caption.position = center + Vector2(-23, -10)
		caption.add_theme_font_size_override("font_size", 13)
		caption.add_theme_color_override("font_color", Color(0.88, 0.92, 0.9, 0.8))
		add_child(button)
		add_child(caption)
