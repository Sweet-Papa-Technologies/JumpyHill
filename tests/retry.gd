extends SceneTree
var game: Node
var failed: bool = false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	if "--no-slow" in OS.get_cmdline_user_args(): root.get_node("Save").data.settings.reduce_motion = true
	# This route reaches the moving sweeper and finish; a blocked launch would
	# miss precisely the physics lifecycle we need to protect.
	game.aim_value = -0.6
	game.lean_value = 0.0
	var baseline: Dictionary = {}
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var repeats: int = int(args[args.find("--repeats") + 1]) if "--repeats" in args else 20
	for i: int in range(repeats):
		game.change_state(game.State.AIM)
		await physics_frame
		await physics_frame
		game.change_state(game.State.ROLL)
		for tick: int in range(3000):
			await physics_frame
			if game.state == game.State.RESULT:
				break
		if game.state != game.State.RESULT:
			push_error("Retry never finished")
			failed = true
			break
		var outcome: Dictionary = game.result.duplicate(true)
		if i == 0:
			baseline = outcome
			if baseline.outcome != "GOAL":
				push_error("Expected the planned route to clear")
				failed = true
		elif outcome.position.distance_to(baseline.position) > 0.0001 or outcome.events != baseline.events:
			push_error("Runtime retry drift %d: %s vs %s" % [i, outcome.position, baseline.position])
			failed = true
	print("RUNTIME RETRY ", "FAIL" if failed else "PASS", " ", repeats, " full game retries, result=", baseline)
	root.get_node("Sound").stop_all()
	await create_timer(0.15, true, false, true).timeout
	quit(1 if failed else 0)
