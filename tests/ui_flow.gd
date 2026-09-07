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
	verify(game.camera.first_person, "hill starts in first person")
	verify(game.viewport_container.position.x == 0, "gameplay uses the whole window")
	verify(game.ui.buttons.find_child("lean", true, false) == null, "no bank slider")
	var angle_key: InputEventKey = InputEventKey.new()
	angle_key.keycode = KEY_RIGHT
	angle_key.pressed = true
	root.push_input(angle_key, true)
	await process_frame
	verify(is_equal_approx(game.aim_value, 0.05) and game.lean_value == 0, "keyboard only changes launch angle")
	await click("view")
	verify(not game.camera.first_person and game.state == game.State.AIM, "view button opens course overview without launching")
	for z: float in [0.0, game.course.data.length]:
		var point: Vector2 = game.camera.unproject_position(Vector3(0, game.course.data.height_at(0, z) + 1.0, z))
		var bottom: float = game.ui.safe_origin.y + game.ui.control_dock().position.y * game.ui.factor
		verify(point.y > 80 * game.ui.factor and point.y < bottom, "overview keeps launch and goal above controls: %s < %.1f" % [point, bottom])
	await click("view")
	verify(game.camera.first_person, "view button returns to tire perspective")
	game._pointer(Vector2(600, 300), true)
	game._drag(Vector2(60, 100))
	game._pointer(Vector2(660, 400), false)
	verify(game.state == game.State.AIM and game.lean_value == 0, "drag release never launches or changes bank")
	var roll_key: InputEventKey = InputEventKey.new()
	roll_key.keycode = KEY_SPACE
	roll_key.pressed = true
	root.push_input(roll_key, true)
	await process_frame
	verify(game.state == game.State.ROLL, "space launches even after focusing the view button")
	await click("view")
	verify(not game.camera.first_person and game.state == game.State.ROLL, "view also switches during a roll")
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
	verify(game.camera.first_person, "retry returns to first-person launch")
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
