extends CanvasLayer
class_name ArenaHUD

signal pause_requested

var player: ArenaFighter
var enemy: ArenaFighter
var player_health: ColorRect
var enemy_health: ColorRect
var player_energy: ColorRect
var enemy_energy: ColorRect
var status_label: Label
var timer_label: Label
var arena_label: Label
var player_name_label: Label
var enemy_name_label: Label
var skill_cooldown_labels: Array[Label] = []
var skill_cooldown_fills: Array[ColorRect] = []
var skill_banner: PanelContainer
var skill_banner_fighter: Label
var skill_banner_name: Label
var skill_banner_timer := 0.0
var touch_buttons: Array[Button] = []
const BAR_WIDTH := 414.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _process(delta: float) -> void:
	if skill_banner_timer <= 0.0:
		return
	skill_banner_timer = maxf(0.0, skill_banner_timer - delta)
	if is_instance_valid(skill_banner):
		skill_banner.visible = skill_banner_timer > 0.0
		skill_banner.modulate.a = clampf(skill_banner_timer / 0.2, 0.0, 1.0)

func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var title := _label(root, "SHINOBI  /  ARENA", Vector2(28, 16), 21, Color("#d9f2ff"))
	title.size = Vector2(320, 30)
	arena_label = _label(root, "", Vector2(30, 47), 12, Color("#8ba7c9"))
	arena_label.size = Vector2(420, 22)
	player_name_label = _label(root, "PLAYER", Vector2(30, 76), 12, Color("#29c3ed"))
	player_name_label.size = Vector2(BAR_WIDTH, 20)
	enemy_name_label = _label(root, "RIVAL", Vector2(836, 76), 12, Color("#e8a64d"))
	enemy_name_label.size = Vector2(BAR_WIDTH, 20)
	player_health = _bar(root, Vector2(30, 96), Color("#29c3ed"))
	enemy_health = _bar(root, Vector2(836, 96), Color("#e8a64d"))
	player_energy = _energy(root, Vector2(30, 130))
	enemy_energy = _energy(root, Vector2(836, 130))
	timer_label = _label(root, "99", Vector2(606, 68), 30, Color("#f4f7ff"))
	timer_label.size = Vector2(68, 42)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label = _label(root, "ELIMINATE THE RIVAL", Vector2(420, 166), 17, Color("#f4f7ff"))
	status_label.size = Vector2(440, 32)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var controls := _label(root, "MOVE A/D  •  JUMP W/SPACE  •  COMBO J  •  BOLT K  •  RISING U  •  DASH L  •  GUARD H", Vector2(250, 140), 9, Color("#c5d5e8"))
	controls.size = Vector2(780, 18)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_skill_cooldown(root, "K  ENERGY BOLT", Vector2(445, 195))
	_add_skill_cooldown(root, "U  RISING STRIKE", Vector2(650, 195))
	_add_skill_banner(root)
	var pause := Button.new()
	pause.text = "Ⅱ"
	pause.custom_minimum_size = Vector2(52, 42)
	pause.position = Vector2(1200, 18)
	pause.add_theme_font_size_override("font_size", 20)
	pause.pressed.connect(func(): pause_requested.emit())
	root.add_child(pause)
	_add_touch_controls(root)

func _label(root: Control, text: String, position: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	return label

func _bar(root: Control, position: Vector2, color: Color) -> ColorRect:
	var back := ColorRect.new()
	back.position = position
	back.size = Vector2(BAR_WIDTH, 28)
	back.color = Color("#172033")
	root.add_child(back)
	var fill := ColorRect.new()
	fill.position = position + Vector2(4, 4)
	fill.size = Vector2(BAR_WIDTH - 8, 20)
	fill.color = color
	root.add_child(fill)
	return fill

func _energy(root: Control, position: Vector2) -> ColorRect:
	var fill := ColorRect.new()
	fill.position = position
	fill.size = Vector2(BAR_WIDTH, 7)
	fill.color = Color("#9c79ff")
	root.add_child(fill)
	return fill

func _add_skill_cooldown(root: Control, title: String, position: Vector2) -> void:
	var label := _label(root, title, position, 11, Color("#d8e4f0"))
	label.size = Vector2(185, 18)
	var back := ColorRect.new()
	back.position = position + Vector2(0, 19)
	back.size = Vector2(178, 6)
	back.color = Color("#182235")
	root.add_child(back)
	var fill := ColorRect.new()
	fill.position = back.position
	fill.size = Vector2(178, 6)
	fill.color = Color("#59cbe3") if title.begins_with("K") else Color("#f2a66e")
	root.add_child(fill)
	skill_cooldown_labels.append(label)
	skill_cooldown_fills.append(fill)

func _add_skill_banner(root: Control) -> void:
	skill_banner = PanelContainer.new()
	skill_banner.position = Vector2(445, 245)
	skill_banner.size = Vector2(390, 78)
	skill_banner.visible = false
	skill_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.09, 0.94)
	style.border_color = Color("#68d9ef")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	skill_banner.add_theme_stylebox_override("panel", style)
	root.add_child(skill_banner)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	skill_banner.add_child(column)
	skill_banner_fighter = _label(column, "", Vector2.ZERO, 11, Color("#80ddf0"))
	skill_banner_fighter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_banner_fighter.add_theme_color_override("font_color", Color("#80ddf0"))
	skill_banner_name = _label(column, "", Vector2.ZERO, 22, Color("#f1f6ff"))
	skill_banner_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_banner_name.add_theme_color_override("font_color", Color("#f1f6ff"))

func show_skill_banner(fighter_name: String, skill_name: String, team: int) -> void:
	if not is_instance_valid(skill_banner):
		return
	skill_banner_fighter.text = fighter_name.to_upper()
	skill_banner_name.text = skill_name.to_upper()
	var accent := Color("#68d9ef") if team == 0 else Color("#f1a365")
	var style := skill_banner.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = accent
	skill_banner.add_theme_stylebox_override("panel", style)
	skill_banner.modulate.a = 1.0
	skill_banner.visible = true
	skill_banner_timer = 1.45

func _add_touch_controls(root: Control) -> void:
	var specs := [["◀", "move_left"], ["▶", "move_right"], ["JUMP", "jump"], ["GUARD", "guard"], ["ATK", "attack"], ["BOLT", "skill"], ["RISING", "skill_alt"], ["DASH", "dash"]]
	for spec in specs:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(62, 62)
		button.add_theme_font_size_override("font_size", 11)
		button.modulate = Color(0.75, 0.9, 1.0, 0.88)
		button.visible = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
		root.add_child(button)
		var action_name: String = spec[1]
		button.set_meta("action_name", action_name)
		touch_buttons.append(button)
		button.button_down.connect(func(): Input.action_press(action_name))
		button.button_up.connect(func(): Input.action_release(action_name))
	apply_mobile_layout(GameSession.settings.mobile_layout)

func apply_mobile_layout(layout: String) -> void:
	var compact := layout == "compact"
	var button_size := 54.0 if compact else 62.0
	var button_positions := {
		"move_left": Vector2(28, 50), "move_right": Vector2(98, 50),
		"jump": Vector2(334, 50), "guard": Vector2(264, 50), "attack": Vector2(194, 50),
		"skill": Vector2(124, 120), "skill_alt": Vector2(54, 120), "dash": Vector2(124, 50),
	}
	if compact:
		button_positions = {
			"move_left": Vector2(24, 38), "move_right": Vector2(84, 38),
			"jump": Vector2(322, 38), "guard": Vector2(262, 38), "attack": Vector2(202, 38),
			"skill": Vector2(142, 98), "skill_alt": Vector2(82, 98), "dash": Vector2(142, 38),
		}
	for button in touch_buttons:
		var action_name: String = button.get_meta("action_name")
		var on_left := action_name in ["move_left", "move_right"]
		button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT if on_left else Control.PRESET_BOTTOM_RIGHT)
		button.custom_minimum_size = Vector2(button_size, button_size)
		var margins: Vector2 = button_positions[action_name]
		button.offset_left = margins.x if on_left else -margins.x - button_size
		button.offset_right = margins.x + button_size if on_left else -margins.x
		button.offset_top = -margins.y - button_size
		button.offset_bottom = -margins.y

func set_match_info(arena_name: String, player_name: String, enemy_name: String) -> void:
	if is_instance_valid(arena_label):
		arena_label.text = "%s  •  ROUND 01" % arena_name.to_upper()
		player_name_label.text = player_name.to_upper()
		enemy_name_label.text = enemy_name.to_upper()

func update_status(seconds_left: float, practice_mode: bool) -> void:
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	player_health.size.x = (BAR_WIDTH - 8.0) * player.health / maxf(1.0, player.max_health)
	enemy_health.size.x = (BAR_WIDTH - 8.0) * enemy.health / maxf(1.0, enemy.max_health)
	enemy_health.position.x = 836.0 + BAR_WIDTH - enemy_health.size.x - 4.0
	player_name_label.text = "%s   HP %03d / %03d" % [player.character_name.to_upper(), int(player.health), int(player.max_health)]
	enemy_name_label.text = "%s   HP %03d / %03d" % [enemy.character_name.to_upper(), int(enemy.health), int(enemy.max_health)]
	player_energy.size.x = BAR_WIDTH * player.energy / 100.0
	enemy_energy.size.x = BAR_WIDTH * enemy.energy / 100.0
	timer_label.text = "—" if practice_mode else "%02d" % int(ceil(seconds_left))
	var bolt_cooldown := clampf(player.skill_timer / 1.1, 0.0, 1.0)
	var rising_cooldown := clampf(player.rising_strike_timer / 2.4, 0.0, 1.0)
	if bolt_cooldown > 0.0:
		skill_cooldown_labels[0].text = "K  BOLT  %.1fs" % player.skill_timer
	else:
		skill_cooldown_labels[0].text = "K  BOLT  LOW ENERGY" if player.energy < 28.0 else "K  BOLT  READY"
	if rising_cooldown > 0.0:
		skill_cooldown_labels[1].text = "U  RISING  %.1fs" % player.rising_strike_timer
	else:
		skill_cooldown_labels[1].text = "U  RISING  LOW ENERGY" if player.energy < 36.0 else "U  RISING  READY"
	skill_cooldown_fills[0].size.x = 178.0 * (1.0 - bolt_cooldown)
	skill_cooldown_fills[1].size.x = 178.0 * (1.0 - rising_cooldown)
	if player.health <= 0.0:
		status_label.text = "DEFEAT"
	elif enemy.health <= 0.0:
		status_label.text = "VICTORY"
	else:
		status_label.text = "PRACTICE" if practice_mode else "ELIMINATE THE RIVAL"

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for action_name in ["move_left", "move_right", "jump", "guard", "attack", "skill", "skill_alt", "dash"]:
			Input.action_release(action_name)
