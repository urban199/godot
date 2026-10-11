extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ["interact", "inventory", "pause", "heal", "reload", "fire"]:
		if not InputMap.has_action(action):
			_fail("Missing Input Map action: %s" % action)
	var packed := load(MAIN_SCENE) as PackedScene
	if packed == null:
		_fail("Main scene is not a PackedScene.")
		_finish()
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	var player := game.get_node_or_null("Player")
	if player == null:
		_fail("Main scene does not contain the player.")
		_finish()
		return
	var enemies := get_nodes_in_group("enemy")
	if enemies.size() != 1:
		_fail("Vertical slice should have exactly one active enemy; found %d." % enemies.size())
	var fuse := game.get_node_or_null("FusePickup")
	var panel := game.get_node_or_null("PowerPanel")
	var exit_target := game.get_node_or_null("ExitInteraction")
	if fuse == null or panel == null or exit_target == null:
		_fail("Fuse, power panel, or exit interaction is missing.")
	else:
		fuse.interact(player)
		if not player.has_item("fuse"):
			_fail("Interacting with the fuse did not add it to inventory.")
		panel.interact(player)
		if not game.power_restored or player.has_item("fuse"):
			_fail("Power panel did not consume the fuse and restore power.")
		game.enemy_defeated()
		exit_target.interact(player)
		if not game.won:
			_fail("Powered exit did not complete the mission after the threat was cleared.")
	game.queue_free()
	await process_frame
	_finish()

func _fail(reason: String) -> void:
	failures.append(reason)
	push_error(reason)

func _finish() -> void:
	if failures.is_empty():
		print("Gameplay validation passed.")
		quit(0)
	else:
		push_error("Gameplay validation failed with %d issue(s)." % failures.size())
		quit(1)
