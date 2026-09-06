extends "res://tests/run.gd"
func run() -> void:
	Engine.max_fps = 0
	courses = CourseData.all_courses()
	root3d = Node3D.new()
	root.add_child(root3d)
	for data: CourseData in courses:
		if data.number == 0: continue
		var wins: int = 0
		for seed_v: int in seed_values:
			var outcome: Dictionary = await trial(data, seed_v, 0, 0)
			if outcome.outcome == "GOAL": wins += 1
		check(wins == 0, data.id() + " neutral successes=" + str(wins))
		print("NEUTRAL ", data.id(), " ", wins, "/5")
	print("NEUTRAL ", "PASS" if failures.is_empty() else "FAIL")
	quit(0 if failures.is_empty() else 1)
