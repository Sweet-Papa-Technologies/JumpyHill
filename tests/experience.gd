extends SceneTree
var game: Node
var failures: Array[String] = []
var native: bool = false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func capture(name: String) -> void:
	if native:
		root.get_texture().get_image().save_png("res://build/experience/" + name + ".png")

func attempt(aim: float, lean: float, force_edge: bool = false) -> Dictionary:
	game.aim_value = aim
	game.lean_value = lean
	game.change_state(game.State.AIM)
	await physics_frame
	await physics_frame
	game.change_state(game.State.ROLL)
	var moved: bool = false
	var initial: Transform3D = game.course.movers[0].body.transform
	for tick: int in range(2600):
		await physics_frame
		if tick == 240:
			moved = not game.course.movers[0].body.transform.is_equal_approx(initial)
			capture("roll")
			if force_edge:
				# Explicitly cross an open boundary. Gentle extreme launches can now
				# rebound from glass, so they are no longer an off-edge fixture.
				game.tire.position.x = game.course.data.width * 0.5 + 2.1
				game.tire.previous = game.tire.position
		if game.state == game.State.RESULT: break
	check(game.state == game.State.RESULT, "Roll terminates")
	check(moved, "Hazard physically moves during roll")
	var position: Vector3 = game.tire.position
	var focus: Vector3 = game.camera.result_focus
	for tick: int in range(600): await physics_frame
	var camera_position: Vector3 = game.camera.position
	capture("win" if game.result.outcome == "GOAL" else ("miss" if game.result.outcome == "BLOCKED" else "edge-miss"))
	for tick: int in range(600): await physics_frame
	check(game.tire.position.distance_to(position) < 0.0001, "Finished tire stays put for ten seconds")
	check(game.camera.result_focus == focus, "Result focus is immutable")
	check(game.camera.position.distance_to(camera_position) < 0.03, "Result camera settles and stops")
	check(game.tire.freeze, "Finished body frozen")
	return game.result.duplicate(true)

func run() -> void:
	native = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute("res://build/experience")
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	if not native: Engine.max_fps = 0
	game.change_state(game.State.AIM)
	await physics_frame
	await physics_frame
	var original: Vector3 = game.tire.position
	var path: PackedVector3Array = RollPredictor.trace(game.tire, RollingTire.FEEL.guide_seconds)
	check(game.tire.position == original and game.tire.freeze, "Guide does not move or assist the real tire")
	check(path.size() > 3 and path[-1].z < 5.0, "Guide only shows initial launch")
	var miss: Dictionary = await attempt(0, 0)
	check(miss.outcome != "GOAL", "Default launch is not a free win")
	var win: Dictionary = await attempt(-0.6, 0)
	check(win.outcome == "GOAL", "A deliberate bank route clears the first hill")
	var edge: Dictionary = await attempt(0, 0, true)
	check(edge.outcome != "GOAL" and absf(edge.position.x) > game.course.data.width / 2, "Crossing an open boundary produces an off-edge miss")
	check(absf(game.tire.position.x) < game.course.data.width * 0.4, "Off-edge result is staged clear of decorative cliffs")
	check(game.tire.position.y > game.course.data.height_at(game.tire.position.x, game.tire.position.z) + 0.6, "Recovered result tire is visible above the ground")
	game.change_state(game.State.AIM)
	await physics_frame
	await physics_frame
	var reset_pose: Transform3D = game.course.movers[0].body.transform
	game.change_state(game.State.ROLL)
	for tick: int in range(120): await physics_frame
	game._action("pause")
	var pose: Transform3D = game.course.movers[0].body.transform
	for tick: int in range(30): await physics_frame
	check(game.course.movers[0].body.transform == pose, "Pause freezes moving hazards")
	game._action("resume")
	game._action("retry")
	check(game.state == game.State.AIM and not game.tire.active, "Retry resets finished body")
	check(game.course.movers[0].body.transform.is_equal_approx(reset_pose), "Retry restores the initial hazard phase")
	print("EXPERIENCE ", "PASS" if failures.is_empty() else "FAIL", " default=", miss.outcome, " planned=", win.outcome, " failures=", failures)
	root.get_node("Sound").stop_all()
	await create_timer(0.15, true, false, true).timeout
	quit(0 if failures.is_empty() else 1)
