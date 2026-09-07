extends SceneTree
var game: Node
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	for data: CourseData in CourseData.all_courses():
		if data.id() == "meadow/03": game.load_course(data)
	game.aim_value = -0.62
	game.change_state(game.State.AIM)
	await physics_frame
	await physics_frame
	game.change_state(game.State.ROLL)
	var passed_16: bool = false
	var passed_20: bool = false
	for tick: int in range(7200):
		await physics_frame
		passed_16 = passed_16 or (game.tire.active and game.tire.elapsed > 16.1)
		passed_20 = passed_20 or (game.tire.active and game.tire.elapsed > 20.1)
		if game.state == game.State.RESULT: break
	check(passed_16 and passed_20, "A moving level 3 tire survives both former deadlines")
	check(game.result.get("outcome") == "GOAL", "The long level 3 bank route reaches the goal")
	print("LONG ROLL ", game.result)
	game.change_state(game.State.AIM)
	await physics_frame
	await physics_frame
	# Drive position explicitly to distinguish slow motion from a blocked,
	# spinning wheel, without relying on platform-specific contact jitter.
	game.tire.set_physics_process(false)
	game.tire.active = true
	game.tire.elapsed = 120.0
	game.tire.linear_velocity = Vector3(0, 0, 0.10)
	for tick: int in range(1200):
		game.tire.position.z += 0.10 / 120.0
		game.tire.position.y = game.course.data.height_at(0, game.tire.position.z) + RollingTire.FEEL.tire_radius
		game.tire._physics_process(1.0 / 120.0)
	check(game.tire.active, "Slow rolling at 0.1 m/s is allowed even after two minutes")
	game.tire.angular_velocity = Vector3(20, 0, 0)
	game.tire.linear_velocity = Vector3.ZERO
	for tick: int in range(370): game.tire._physics_process(1.0 / 120.0)
	check(game.tire.last_result.get("outcome") == "BLOCKED", "A stationary spinning tire ends as stuck")
	game.change_state(game.State.AIM)
	check(game.tire.stalled_time == 0 and game.tire.motion_anchor == game.tire.position, "Retry clears stuck detection")
	print("ROLLING ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures)
	root.get_node("Sound").stop_all()
	await create_timer(0.15, true, false, true).timeout
	quit(0 if failures.is_empty() else 1)
