extends SceneTree
var game: Node
var failed: bool = false

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	Engine.max_fps = 0
	var baseline: Dictionary = {}
	for i: int in range(20):
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
		elif outcome.position.distance_to(baseline.position) > 0.0001 or outcome.events != baseline.events:
			push_error("Runtime retry drift %d: %s vs %s" % [i, outcome.position, baseline.position])
			failed = true
	print("RUNTIME RETRY ", "FAIL" if failed else "PASS", " 20 full game retries, slow motion enabled, result=", baseline)
	root.get_node("Sound").stop_all()
	await create_timer(0.15, true, false, true).timeout
	quit(1 if failed else 0)
