extends Node2D

const Fighter = preload("res://scripts/fighter.gd")
const Rival = preload("res://scripts/enemy.gd")
const HUD = preload("res://scripts/hud.gd")
const ROUND_SECONDS := 99.0

var player: ArenaFighter
var enemy: ArenaFighter
var hud: ArenaHUD
var stage: ArenaStage
var battle_camera: Camera2D
var shake_time := 0.0
var shake_strength := 0.0
var ui_layer: CanvasLayer
var screen := "home"
var selection_return_screen := "mode"
var settings_return_to_battle := false
var selected_character_id := "kairo"
var selected_opponent_id := "ren"
var selected_arena_id := "forest_shrine"
var match_time := ROUND_SECONDS
var match_elapsed := 0.0
var match_finished := false
var elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().title = "Shinobi Arena 2D"
	GameSession.apply_audio_settings()
	_show_home()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if is_instance_valid(battle_camera) and not get_tree().paused:
		if shake_time > 0.0:
			shake_time = maxf(0.0, shake_time - delta)
			battle_camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		else:
			battle_camera.offset = Vector2.ZERO
	if screen != "battle" or match_finished or get_tree().paused:
		return
	match_elapsed += delta
	if GameSession.selected_mode != "practice":
		match_time = maxf(0.0, match_time - delta)
	if is_instance_valid(hud):
		hud.update_status(match_time, GameSession.selected_mode == "practice")
	if is_instance_valid(player) and is_instance_valid(enemy):
		if player.health <= 0.0:
			_finish_match("defeat")
		elif enemy.health <= 0.0:
			_finish_match("victory")
		elif match_time <= 0.0:
			if is_equal_approx(player.health, enemy.health):
				_finish_match("draw")
			else:
				_finish_match("victory" if player.health > enemy.health else "defeat")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if screen == "battle":
		if get_tree().paused:
			_resume_battle()
		else:
			_pause_battle()
	elif screen == "home":
		return
	else:
		_go_back()

func _draw() -> void:
	if screen == "battle":
		return
	var view := get_viewport_rect().size
	var arena: Dictionary = GameSession.arena_by_id(selected_arena_id)
	var base: Color = arena.color
	draw_rect(Rect2(Vector2.ZERO, view), base)
	draw_circle(Vector2(view.x * 0.78, view.y * 0.19), 70, Color(0.3, 0.5, 0.8, 0.08))
	draw_circle(Vector2(view.x * 0.78, view.y * 0.19), 40, Color("#d7e7ff"))
	draw_circle(Vector2(view.x * 0.78 + 13, view.y * 0.175), 37, base)
	var far := PackedVector2Array([Vector2(0, 430), Vector2(130, 300), Vector2(230, 385), Vector2(390, 275), Vector2(550, 405), Vector2(720, 315), Vector2(900, 410), Vector2(1080, 290), Vector2(1280, 420), Vector2(1280, 560), Vector2(0, 560)])
	draw_colored_polygon(far, arena.accent.darkened(0.57))
	var near := PackedVector2Array([Vector2(0, 485), Vector2(170, 390), Vector2(310, 465), Vector2(480, 365), Vector2(660, 475), Vector2(850, 380), Vector2(1040, 470), Vector2(1180, 390), Vector2(1280, 445), Vector2(1280, 600), Vector2(0, 600)])
	draw_colored_polygon(near, arena.accent.darkened(0.72))
	for x in [90.0, 1090.0]:
		draw_rect(Rect2(x, 340, 14, 185), Color("#0a1426"))
		draw_rect(Rect2(x + 75, 340, 14, 185), Color("#0a1426"))
		draw_rect(Rect2(x - 12, 330, 113, 15), Color("#0a1426"))
		draw_rect(Rect2(x - 22, 318, 133, 10), Color("#0a1426"))
	draw_rect(Rect2(0, 535, view.x, view.y - 535), Color("#202b3a"))
	draw_rect(Rect2(0, 535, view.x, 4), arena.accent.lightened(0.28))
	var particle_count := 0
	if not GameSession.settings.reduced_effects:
		particle_count = 4 if GameSession.settings.effects_quality == "low" else (12 if GameSession.settings.effects_quality == "medium" else 22)
	if particle_count > 0:
		for index in range(particle_count):
			var x := fposmod(index * 83.0 - elapsed * 25.0, view.x + 100.0)
			draw_line(Vector2(x, 552), Vector2(x - 35, 690), Color(0.39, 0.53, 0.67, 0.18), 2)

func _new_ui() -> Control:
	_clear_ui()
	ui_layer = CanvasLayer.new()
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	ui_layer.add_child(root)
	return root

func _clear_ui() -> void:
	if is_instance_valid(ui_layer):
		remove_child(ui_layer)
		ui_layer.free()
	ui_layer = null

func _panel(root: Control, title: String, subtitle: String = "", panel_size: Vector2 = Vector2(700, 580)) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.anchor_left = 0.5
	frame.anchor_top = 0.5
	frame.anchor_right = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -panel_size.x * 0.5
	frame.offset_top = -panel_size.y * 0.5
	frame.offset_right = panel_size.x * 0.5
	frame.offset_bottom = panel_size.y * 0.5
	frame.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(frame)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	frame.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color("#e8f5ff"))
	column.add_child(heading)
	if not subtitle.is_empty():
		var detail := Label.new()
		detail.text = subtitle
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_theme_color_override("font_color", Color("#aabbd0"))
		column.add_child(detail)
	return column

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.12, 0.94)
	style.border_color = Color("#55708d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _label(parent: Node, text: String, size: int = 16, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#d5e4f5"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Node, caption: String, callback: Callable, minimum: Vector2 = Vector2(0, 48)) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = minimum
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _show_home() -> void:
	screen = "home"
	var root := _new_ui()
	var column := _panel(root, "SHINOBI ARENA", "Original 2D fighter • Choose a path to begin")
	_button(column, "Play", _show_mode_select)
	_button(column, "Practice", _start_practice)
	_button(column, "Collection", _show_collection)
	_button(column, "Settings", _show_settings)
	_button(column, "Credits", _show_credits)
	if not OS.has_feature("web"):
		_button(column, "Quit", _quit_game)

func _show_mode_select() -> void:
	screen = "mode"
	var column := _panel(_new_ui(), "SELECT MODE", "Choose how this match should play")
	_button(column, "Quick Battle — fight the AI", func(): _choose_mode("quick_battle"))
	_button(column, "Practice — passive opponent, no timer", _start_practice)
	var versus := _button(column, "Versus Local — Coming Soon", func(): pass)
	versus.disabled = true
	_button(column, "Back", _show_home)

func _choose_mode(mode_id: String) -> void:
	GameSession.selected_mode = mode_id
	selection_return_screen = "mode"
	_show_character_select()

func _start_practice() -> void:
	GameSession.selected_mode = "practice"
	selection_return_screen = "home"
	_show_character_select()

func _show_character_select() -> void:
	screen = "character"
	selected_character_id = GameSession.player_character_id
	selected_opponent_id = GameSession.opponent_character_id
	var column := _panel(_new_ui(), "CHOOSE YOUR SHINOBI", "Select a fighter. Character data and stats are stored by ID.")
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 8)
	column.add_child(cards)
	for character in GameSession.CHARACTER_DATA:
		var card := Button.new()
		card.custom_minimum_size = Vector2(195, 108)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.text = "%s\n%s\nHP %d  •  Speed %d\nPower %d" % [character.name, character.role, int(character.hp), int(character.speed), int(character.power)]
		card.icon = _atlas_frame(character.sprite_path, Vector2i(0, 0))
		card.expand_icon = true
		card.focus_mode = Control.FOCUS_ALL
		card.pressed.connect(_select_character.bind(character.id))
		cards.add_child(card)
	_label(column, "Choose AI opponent", 14, true)
	var opponent_cards := HBoxContainer.new()
	opponent_cards.add_theme_constant_override("separation", 8)
	column.add_child(opponent_cards)
	for character in GameSession.CHARACTER_DATA:
		var card := Button.new()
		card.custom_minimum_size = Vector2(195, 54)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.text = "AI: %s" % character.name
		card.pressed.connect(_select_opponent.bind(character.id))
		opponent_cards.add_child(card)
	var preview_row := HBoxContainer.new()
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_row.add_theme_constant_override("separation", 16)
	column.add_child(preview_row)
	var preview := TextureRect.new()
	preview.name = "CharacterPreview"
	preview.custom_minimum_size = Vector2(96, 116)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_row.add_child(preview)
	var description := _label(preview_row, "", 15, false)
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.name = "CharacterDescription"
	_update_character_preview(preview)
	_update_character_description(description)
	_button(column, "Confirm Character", _confirm_character)
	_button(column, "Back", _go_back)

func _select_character(character_id: String) -> void:
	selected_character_id = character_id
	var description := ui_layer.find_child("CharacterDescription", true, false) as Label
	var preview := ui_layer.find_child("CharacterPreview", true, false) as TextureRect
	if is_instance_valid(description):
		_update_character_description(description)
	if is_instance_valid(preview):
		_update_character_preview(preview)

func _select_opponent(character_id: String) -> void:
	selected_opponent_id = character_id
	var description := ui_layer.find_child("CharacterDescription", true, false) as Label
	if is_instance_valid(description):
		_update_character_description(description)

func _atlas_frame(atlas_path: String, cell: Vector2i) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = load(atlas_path) as Texture2D
	frame.region = Rect2(cell.x * 384, cell.y * 512, 384, 512)
	return frame

func _update_character_preview(preview: TextureRect) -> void:
	var character: Dictionary = GameSession.character_by_id(selected_character_id)
	preview.texture = _atlas_frame(character.sprite_path, Vector2i(0, 0))

func _update_character_description(label: Label) -> void:
	var character: Dictionary = GameSession.character_by_id(selected_character_id)
	label.text = "%s — %s\n%s\nAI opponent: %s   •   Skills: Energy Bolt, Rising Strike" % [character.name, character.role, character.description, GameSession.character_by_id(selected_opponent_id).name]

func _confirm_character() -> void:
	GameSession.player_character_id = selected_character_id
	GameSession.opponent_character_id = selected_opponent_id
	_show_arena_select()

func _show_arena_select() -> void:
	screen = "arena"
	selected_arena_id = GameSession.selected_arena_id
	var column := _panel(_new_ui(), "CHOOSE AN ARENA", "Select the setting for your battle")
	for arena in GameSession.ARENA_DATA:
		var button := _button(column, "%s\n%s" % [arena.name, arena.description], _select_arena.bind(arena.id), Vector2(0, 60))
		button.add_theme_font_size_override("font_size", 15)
	var summary := _label(column, "Fighter: %s" % GameSession.character_by_id(GameSession.player_character_id).name, 16, true)
	summary.name = "ArenaSelectionSummary"
	_button(column, "Random Arena", _random_arena)
	_button(column, "Start Battle", _start_battle)
	_button(column, "Back", _go_back)
	_update_arena_summary(summary)

func _select_arena(arena_id: String) -> void:
	selected_arena_id = arena_id
	var summary := ui_layer.find_child("ArenaSelectionSummary", true, false) as Label
	if is_instance_valid(summary):
		_update_arena_summary(summary)

func _update_arena_summary(label: Label) -> void:
	var arena: Dictionary = GameSession.arena_by_id(selected_arena_id)
	label.text = "Selected: %s   •   Fighter: %s" % [arena.name, GameSession.character_by_id(GameSession.player_character_id).name]

func _random_arena() -> void:
	var index := randi_range(0, GameSession.ARENA_DATA.size() - 1)
	_select_arena(GameSession.ARENA_DATA[index].id)

func _start_battle() -> void:
	GameSession.selected_arena_id = selected_arena_id
	get_tree().paused = false
	_clear_ui()
	_cleanup_battle()
	screen = "battle"
	match_finished = false
	match_time = ROUND_SECONDS
	match_elapsed = 0.0
	queue_redraw()
	var player_data: Dictionary = GameSession.character_by_id(GameSession.player_character_id)
	var opponent_data: Dictionary = GameSession.character_by_id(GameSession.opponent_character_id)
	var arena_data: Dictionary = GameSession.arena_by_id(selected_arena_id)
	var arena_scene := load(arena_data.scene_path) as PackedScene
	if arena_scene == null:
		push_error("Arena scene could not be loaded: %s" % arena_data.scene_path)
		screen = "arena"
		_show_arena_select()
		return
	stage = arena_scene.instantiate() as ArenaStage
	if stage == null:
		push_error("Arena scene has no ArenaStage root: %s" % arena_data.scene_path)
		screen = "arena"
		_show_arena_select()
		return
	add_child(stage)
	battle_camera = Camera2D.new()
	battle_camera.position = Vector2(640, 360)
	add_child(battle_camera)
	battle_camera.make_current()
	shake_time = 0.0
	shake_strength = 0.0
	player = Fighter.new()
	player.team = 0
	player.character_name = player_data.name
	player.max_health = player_data.hp
	player.move_speed = player_data.speed
	player.attack_power = player_data.power
	player.color_main = player_data.color
	player.color_accent = player_data.accent
	player.sprite_texture = load(player_data.sprite_path) as Texture2D
	player.damaged.connect(_on_fighter_damaged)
	player.position = arena_data.player_spawn
	player.arena_left = arena_data.left_bound
	player.arena_right = arena_data.right_bound
	add_child(player)
	enemy = Rival.new()
	enemy.team = 1
	enemy.character_name = opponent_data.name
	enemy.max_health = opponent_data.hp
	enemy.move_speed = opponent_data.speed
	enemy.attack_power = opponent_data.power
	enemy.color_main = opponent_data.color
	enemy.color_accent = opponent_data.accent
	enemy.sprite_texture = load(opponent_data.sprite_path) as Texture2D
	enemy.damaged.connect(_on_fighter_damaged)
	enemy.position = arena_data.opponent_spawn
	enemy.arena_left = arena_data.left_bound
	enemy.arena_right = arena_data.right_bound
	enemy.set("practice_mode", GameSession.selected_mode == "practice")
	add_child(enemy)
	player.opponent = enemy
	enemy.opponent = player
	hud = HUD.new()
	hud.player = player
	hud.enemy = enemy
	hud.pause_requested.connect(_pause_battle)
	add_child(hud)
	hud.set_match_info(GameSession.arena_by_id(selected_arena_id).name, player_data.name, opponent_data.name)

func _finish_match(outcome: String) -> void:
	if match_finished:
		return
	match_finished = true
	player.set_combat_enabled(false)
	enemy.set_combat_enabled(false)
	GameSession.match_result = {
		"outcome": outcome,
		"player_name": GameSession.character_by_id(GameSession.player_character_id).name,
		"opponent_name": GameSession.character_by_id(GameSession.opponent_character_id).name,
		"arena_name": GameSession.arena_by_id(GameSession.selected_arena_id).name,
		"duration": match_elapsed,
		"player_health": player.health,
		"opponent_health": enemy.health,
	}
	GameSession.record_result(outcome)
	_cleanup_battle()
	_show_result()

func _cleanup_battle() -> void:
	_release_combat_input()
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	if is_instance_valid(hud):
		hud.queue_free()
		hud = null
	if is_instance_valid(player):
		player.queue_free()
		player = null
	if is_instance_valid(enemy):
		enemy.queue_free()
		enemy = null
	if is_instance_valid(stage):
		stage.queue_free()
		stage = null
	if is_instance_valid(battle_camera):
		battle_camera.queue_free()
		battle_camera = null
	shake_time = 0.0
	shake_strength = 0.0

func _show_result() -> void:
	screen = "result"
	var result: Dictionary = GameSession.match_result
	var heading := "DRAW"
	if result.outcome == "victory":
		heading = "VICTORY"
	elif result.outcome == "defeat":
		heading = "DEFEAT"
	var column := _panel(_new_ui(), heading, "%s vs %s  •  %s\nTime: %d seconds   •   HP: %d — %d" % [result.player_name, result.opponent_name, result.arena_name, int(result.duration), int(result.player_health), int(result.opponent_health)])
	_button(column, "Rematch", _start_battle)
	_button(column, "Character Select", _show_character_select)
	_button(column, "Arena Select", _show_arena_select)
	_button(column, "Home", _return_home)

func _pause_battle() -> void:
	if screen != "battle" or match_finished or get_tree().paused:
		return
	get_tree().paused = true
	_release_combat_input()
	shake_time = 0.0
	if is_instance_valid(battle_camera):
		battle_camera.offset = Vector2.ZERO
	if is_instance_valid(hud):
		hud.visible = false
	var column := _panel(_new_ui(), "PAUSED", "The match and round timer are paused.")
	_button(column, "Resume", _resume_battle)
	_button(column, "Settings", _show_settings)
	_button(column, "Restart Match", _start_battle)
	_button(column, "Home", _return_home)

func _resume_battle() -> void:
	get_tree().paused = false
	if screen == "battle":
		_clear_ui()
		if is_instance_valid(hud):
			hud.visible = true

func _show_settings(return_to_battle_override: bool = false) -> void:
	var return_to_battle := screen == "battle" or return_to_battle_override
	settings_return_to_battle = return_to_battle
	screen = "settings"
	var column := _panel(_new_ui(), "SETTINGS", "Volume, controls, and visual preferences save locally.", Vector2(780, 670))
	_add_setting_slider(column, "Master volume", "master_volume", 0.0, 1.0, 0.05, "Master")
	_add_setting_slider(column, "Music volume", "music_volume", 0.0, 1.0, 0.05, "Music")
	_add_setting_slider(column, "SFX volume", "sfx_volume", 0.0, 1.0, 0.05, "SFX")
	_add_setting_slider(column, "Control sensitivity", "control_sensitivity", 0.5, 1.5, 0.05)
	_add_setting_slider(column, "Flash intensity", "flash_intensity", 0.0, 1.0, 0.05)
	var shake := CheckButton.new()
	shake.text = "Screen shake enabled"
	shake.button_pressed = GameSession.settings.screen_shake
	column.add_child(shake)
	shake.toggled.connect(func(enabled: bool):
		GameSession.settings.screen_shake = enabled
		GameSession.save_settings()
	)
	var quality_row := HBoxContainer.new()
	quality_row.add_theme_constant_override("separation", 16)
	column.add_child(quality_row)
	var quality_label := _label(quality_row, "Effects quality", 15)
	quality_label.custom_minimum_size.x = 190
	var quality_option := OptionButton.new()
	quality_option.add_item("Low")
	quality_option.add_item("Medium")
	quality_option.add_item("High")
	quality_option.selected = ["low", "medium", "high"].find(GameSession.settings.effects_quality)
	quality_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quality_row.add_child(quality_option)
	quality_option.item_selected.connect(func(index: int):
		GameSession.settings.effects_quality = ["low", "medium", "high"][index]
		GameSession.save_settings()
		queue_redraw()
	)
	var layout_row := HBoxContainer.new()
	layout_row.add_theme_constant_override("separation", 16)
	column.add_child(layout_row)
	var layout_label := _label(layout_row, "Touch button layout", 15)
	layout_label.custom_minimum_size.x = 190
	var layout_option := OptionButton.new()
	layout_option.add_item("Classic")
	layout_option.add_item("Compact")
	layout_option.selected = 1 if GameSession.settings.mobile_layout == "compact" else 0
	layout_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout_row.add_child(layout_option)
	layout_option.item_selected.connect(func(index: int):
		GameSession.settings.mobile_layout = "compact" if index == 1 else "classic"
		GameSession.save_settings()
		if is_instance_valid(hud):
			hud.apply_mobile_layout(GameSession.settings.mobile_layout)
	)
	var reduced := CheckButton.new()
	reduced.text = "Reduce visual effects"
	reduced.button_pressed = GameSession.settings.reduced_effects
	column.add_child(reduced)
	reduced.toggled.connect(func(enabled: bool):
		GameSession.settings.reduced_effects = enabled
		GameSession.save_settings()
		queue_redraw()
	)
	_button(column, "Reset Settings", func():
		GameSession.settings = {"master_volume": 1.0, "music_volume": 0.8, "sfx_volume": 1.0, "control_sensitivity": 1.0, "mobile_layout": "classic", "effects_quality": "medium", "screen_shake": true, "reduced_effects": false, "flash_intensity": 1.0}
		GameSession.save_settings()
		GameSession.apply_audio_settings()
		_show_settings(return_to_battle)
	)
	_button(column, "Back", func():
		if return_to_battle:
			screen = "battle"
			_resume_battle()
		else:
			_show_home()
	)

func _add_setting_slider(parent: Node, title: String, setting_key: String, minimum: float, maximum: float, step: float, audio_bus: String = "") -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var label := _label(row, "%s: %.2f" % [title, float(GameSession.settings[setting_key])], 15)
	label.custom_minimum_size.x = 190
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = GameSession.settings[setting_key]
	slider.custom_minimum_size.y = 28
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	slider.value_changed.connect(func(value: float):
		GameSession.settings[setting_key] = value
		label.text = "%s: %.2f" % [title, value]
		if not audio_bus.is_empty():
			GameSession.set_audio_volume(audio_bus, value)
		GameSession.save_settings()
	)
	return slider

func _on_fighter_damaged(_amount: float) -> void:
	if not GameSession.settings.screen_shake or GameSession.settings.reduced_effects or not is_instance_valid(battle_camera):
		return
	shake_time = 0.12
	shake_strength = 6.0

func _show_credits() -> void:
	screen = "credits"
	var column := _panel(_new_ui(), "CREDITS", "Shinobi Arena 2D\nOriginal procedural placeholder art and code.\nReplace placeholders only with original or properly licensed assets.")
	_button(column, "Back", _show_home)

func _show_collection() -> void:
	screen = "collection"
	var column := _panel(_new_ui(), "COLLECTION", "Original prototype roster • all three fighters are available")
	for character in GameSession.CHARACTER_DATA:
		_label(column, "%s  •  %s  •  %d HP  •  %s" % [character.name, character.role, int(character.hp), "Unlocked" if character.unlocked else "Locked"], 16)
	_label(column, "Record: %d wins  •  %d losses  •  %d draws" % [GameSession.progress.wins, GameSession.progress.losses, GameSession.progress.draws], 16, true)
	_button(column, "Back", _show_home)

func _go_back() -> void:
	match screen:
		"mode": _show_home()
		"character": _show_home() if selection_return_screen == "home" else _show_mode_select()
		"arena": _show_character_select()
		"result": _return_home()
		"collection": _show_home()
		"settings":
			if settings_return_to_battle:
				screen = "battle"
				_resume_battle()
			else:
				_show_home()
		"credits": _show_home()
		_: _show_home()

func _return_home() -> void:
	get_tree().paused = false
	_cleanup_battle()
	GameSession.match_result = {}
	_show_home()

func _quit_game() -> void:
	get_tree().quit()

func _release_combat_input() -> void:
	for action_name in ["move_left", "move_right", "jump", "guard", "attack", "skill", "skill_alt", "dash"]:
		Input.action_release(action_name)
