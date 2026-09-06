extends SceneTree
var game: Node
var errors: int = 0

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, message: String) -> void:
	if not ok:
		errors += 1
		push_error("UI FAIL " + message)

func click(prefix: String) -> void:
	await process_frame
	var found: Button
	for child: Node in game.ui.buttons.get_children():
		if child is Button and child.name.begins_with(prefix + "_") and not child.is_queued_for_deletion():
			found = child
			break
	verify(found != null, "button exists: " + prefix)
	if found == null:
		return
	var pos: Vector2 = found.get_global_rect().get_center()
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.position = pos
	down.global_position = pos
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var up: InputEventMouseButton = down.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up, true)
	await process_frame
	await process_frame

func run() -> void:
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	verify(game.state == game.State.TITLE, "boots to title")
	await click("play")
	verify(game.state == game.State.COURSE_SELECT, "mouse opens course select")
	await click("start")
	verify(game.state == game.State.AIM, "mouse starts hill")
	var lean_key: InputEventKey = InputEventKey.new()
	lean_key.keycode = KEY_UP
	lean_key.pressed = true
	root.push_input(lean_key, true)
	await process_frame
	verify(game.lean_value == 0.5, "keyboard changes lean")
	await click("roll")
	verify(game.state == game.State.ROLL, "mouse releases tire")
	await click("pause")
	verify(paused, "pause freezes simulation")
	var old_elapsed: float = game.tire.elapsed
	for i: int in range(5):
		await process_frame
	verify(game.tire.elapsed == old_elapsed, "pause holds tire time")
	await click("settings")
	verify(game.state == game.State.SETTINGS, "pause settings opens")
	await click("settings_back")
	await click("resume")
	verify(not paused and game.state == game.State.ROLL, "resume continues roll")
	await click("nudge")
	verify(game.tire.nudges == 1, "nudge button applies impulse")
	game._action("retry")
	await process_frame
	verify(game.state == game.State.AIM and game.tire.nudges == 0, "retry clears nudge state")
	await click("select")
	await click("world_next")
	verify(game.selected_world == 1, "carousel changes world")
	var start: Button = game.ui.buttons.get_node_or_null("start_<null>") as Button
	if start == null:
		for child: Node in game.ui.buttons.get_children():
			if child is Button and child.name.begins_with("start_"):
				start = child
	verify(start != null and start.disabled, "locked world cannot launch")
	print("UI FLOW ", "PASS" if errors == 0 else "FAIL", " errors=", errors)
	root.get_node("Sound").stop_all()
	await create_timer(0.15, true, false, true).timeout
	quit(0 if errors == 0 else 1)
