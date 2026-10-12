extends Control

var player: Variant

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.04, 0.045, 0.96), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.26, 0.34, 0.36), false, 2.0)
	if Objectives.discovered_areas.has("service"):
		draw_line(Vector2(215, 42), Vector2(215, 83), Color(0.48, 0.56, 0.54), 12.0)
		draw_rect(Rect2(170, 76, 90, 44), Color(0.16, 0.22, 0.22), true)
		draw_string(ThemeDB.fallback_font, Vector2(174, 102), "SERVICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.84, 0.87, 0.81))
		if not Objectives.completed.has("restore_power"):
			draw_circle(Vector2(188, 92), 4.0, Color(0.94, 0.68, 0.27))
			draw_string(ThemeDB.fallback_font, Vector2(178, 116), "GEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.94, 0.78, 0.48))
	if Objectives.discovered_areas.has("administration"):
		draw_rect(Rect2(240, 37, 85, 34), Color(0.16, 0.22, 0.22), true)
		draw_string(ThemeDB.fallback_font, Vector2(245, 59), "ADMIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.84, 0.87, 0.81))
	if Objectives.discovered_areas.has("corridor"):
		draw_rect(Rect2(262, 76, 38, 44), Color(0.13, 0.19, 0.2), true)
		draw_rect(Rect2(300, 85, 130, 26), Color(0.12, 0.18, 0.2), true)
		draw_string(ThemeDB.fallback_font, Vector2(304, 103), "CORRIDOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.84, 0.87, 0.81))
	if Objectives.discovered_areas.has("laboratory"):
		draw_rect(Rect2(303, 38, 110, 42), Color(0.16, 0.22, 0.22), true)
		draw_string(ThemeDB.fallback_font, Vector2(311, 63), "LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.84, 0.87, 0.81))
	if Objectives.discovered_areas.has("exit"):
		draw_string(ThemeDB.fallback_font, Vector2(389, 79), "EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.84, 0.87, 0.81))
		if Objectives.completed.has("restore_power"):
			draw_circle(Vector2(402, 85), 4.0, Color(0.94, 0.68, 0.27))
	draw_rect(Rect2(182, 41, 66, 38), Color(0.16, 0.22, 0.22), true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(182, 65), "ENTRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.84, 0.87, 0.81))
	if is_instance_valid(player):
		var map_x := clampf(215.0 + player.global_position.x * 9.0, 175.0, 423.0)
		var map_y := clampf(50.0 + maxf(0.0, -player.global_position.z) * 2.0, 50.0, 107.0)
		draw_circle(Vector2(map_x, map_y), 6.0, Color(0.93, 0.23, 0.17))
