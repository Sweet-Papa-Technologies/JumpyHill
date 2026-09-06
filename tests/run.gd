extends SceneTree
var failures: Array[String] = []
var courses: Array[CourseData] = []
var root3d: Node3D
var results: Array[Dictionary] = []
var mode: String = "unit"
var seed_values: Array[int] = [42, 137, 2026, 7777, 31415]

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error("FAIL: " + message)

func run() -> void:
	Engine.max_fps = 0
	courses = CourseData.all_courses()
	root3d = Node3D.new()
	root.add_child(root3d)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	mode = "solver" if "--solver" in args else ("determinism" if "--determinism" in args else "unit")
	if mode == "unit":
		await unit_tests()
	elif mode == "determinism":
		await determinism()
	else:
		await solver(args)
	print("TESTS ", mode, " ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func unit_tests() -> void:
	check(courses.size() == 33, "33 courses exist")
	var ids: Dictionary = {}
	for data: CourseData in courses:
		check(not ids.has(data.id()), "unique course " + data.id())
		ids[data.id()] = true
		check(data.features(42) == data.features(42), "seeded features " + data.id())
		check(data.features(42) != data.features(43), "different seed " + data.id())
	var style: StyleTracker = StyleTracker.new()
	check(style.stars(false, 1, 100, true) == 0, "purist miss is zero")
	check(style.stars(true, 0, 100, false) == 1, "base clear one star")
	check(style.stars(true, 1, 100, false) == 2, "center clear two stars")
	style.add("BULLSEYE")
	check(style.stars(true, 1, 100, false) == 3, "center plus style three stars")
	style.add("TILT")
	check(style.score == 0 and style.combo == 0, "tilt penalty clamps score")
	var save_node: Node = root.get_node("Save")
	var original: Dictionary = save_node.data.duplicate(true)
	save_node.record("meadow/01", 3, 200, 42)
	save_node.record("meadow/01", 1, 50, 19)
	check(save_node.data.courses["meadow/01"].stars == 3, "best stars retained")
	check(save_node.data.courses["meadow/01"].seed == 42, "best seed retained")
	check(save_node.persist("res://build/test_save.json"), "atomic save writes")
	var loaded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://build/test_save.json"))
	check(int(loaded.version) == 1 and int(loaded.courses["meadow/01"].stars) == 3 and int(loaded.courses["meadow/01"].score) == 200 and int(loaded.courses["meadow/01"].seed) == 42 and is_equal_approx(float(loaded.settings.music), 0.55) and loaded.settings.haptics == true, "save JSON round trip")
	check(save_node.daily_for("2026-09-06") == save_node.daily_for("2026-09-06"), "daily deterministic")
	check(save_node.daily_for("2026-09-06") != save_node.daily_for("2026-09-07"), "daily advances")
	save_node.data = original
	var hill: HillCourse = create_hill(courses[1], 42)
	var tire: RollingTire = create_tire(courses[1], 42, 0, 0)
	await physics_frame
	await physics_frame
	tire.launch()
	check(tire.nudge(1), "first nudge")
	check(not tire.nudge(1), "cooldown blocks immediate nudge")
	tire.elapsed = 0.6
	check(tire.nudge(-1), "second nudge")
	tire.elapsed = 1.2
	check(not tire.nudge(1) and tire.tilted, "third nudge locks out")
	tire.reset_to_aim()
	tire.purist = true
	tire.launch()
	check(not tire.nudge(1), "purist disables nudges")
	tire.free()
	hill.free()
	print("UNIT checked course catalog, RNG, style, save, daily, nudge cooldown, TILT, Purist")

func create_hill(data: CourseData, seed_v: int) -> HillCourse:
	var hill: HillCourse = HillCourse.new()
	hill.visual = false
	hill.data = data
	hill.roll_seed = seed_v
	root3d.add_child(hill)
	return hill

func create_tire(data: CourseData, seed_v: int, aim_v: float, lean_v: float) -> RollingTire:
	var tire: RollingTire = RollingTire.new()
	tire.show_visual = false
	tire.course = data
	tire.roll_seed = seed_v
	tire.aim = aim_v
	tire.lean = lean_v
	root3d.add_child(tire)
	return tire

func trial(data: CourseData, seed_v: int, aim_v: float, lean_v: float) -> Dictionary:
	var isolated: SubViewport = SubViewport.new()
	isolated.own_world_3d = true
	root.add_child(isolated)
	var previous_root: Node3D = root3d
	root3d = Node3D.new()
	isolated.add_child(root3d)
	var hill: HillCourse = create_hill(data, seed_v)
	var tire: RollingTire = create_tire(data, seed_v, aim_v, lean_v)
	await physics_frame
	await physics_frame
	tire.launch()
	for tick: int in range(2410):
		await physics_frame
		hill.tick_gate(tire.elapsed)
		if not tire.active:
			break
	var outcome: Dictionary = tire.last_result.duplicate(true)
	tire.free()
	hill.free()
	isolated.free()
	root3d = previous_root
	await physics_frame
	return outcome

func determinism() -> void:
	var first: Dictionary = {}
	for i: int in range(20):
		var outcome: Dictionary = await trial(courses[1], 42, 0.0, 0.0)
		print("REPEAT ", i, " ", outcome.get("position"))
		check(not outcome.is_empty(), "trial terminates")
		if i == 0:
			first = outcome
		else:
			check(outcome.position.distance_to(first.position) < 0.0001, "repeat %d position" % i)
			check(outcome.events == first.events, "repeat %d events" % i)
			check(outcome.outcome == first.outcome, "repeat %d outcome" % i)
	print("DETERMINISM_RESULT ", JSON.stringify(first))

func solver(args: PackedStringArray) -> void:
	DirAccess.make_dir_recursive_absolute("res://build/solver")
	var only: String = ""
	if "--course" in args:
		only = args[args.find("--course") + 1]
	var quick: bool = "--quick" in args
	var seeds: Array[int] = seed_values.duplicate()
	if quick:
		seeds = [42]
	for data: CourseData in courses:
		if only != "" and data.id() != only:
			continue
		var clear_count: int = 0
		var count: int = 0
		var stuck: int = 0
		var best: Dictionary = {}
		var heat: Image = Image.create(21, 7, false, Image.FORMAT_RGB8)
		heat.fill(Color("663e57"))
		var rates: Dictionary = {}
		for seed_v: int in seeds:
			var hill: HillCourse = create_hill(data, seed_v)
			var tires: Array[RollingTire] = []
			for a: int in range(21):
				for l: int in range(7):
					tires.append(create_tire(data, seed_v, -1.0 + a * 0.1, -15.0 + l * 5))
			await physics_frame
			await physics_frame
			for tire: RollingTire in tires:
				tire.launch()
			var elapsed: float = 0
			for tick: int in range(2410):
				await physics_frame
				elapsed += 1.0 / 120
				hill.tick_gate(elapsed)
				var all_done: bool = true
				for tire: RollingTire in tires:
					if tire.active:
						all_done = false
						break
				if all_done:
					break
			for i: int in range(tires.size()):
				var tire: RollingTire = tires[i]
				count += 1
				if tire.last_result.is_empty() or tire.elapsed >= 20.0:
					stuck += 1
				if tire.last_result.get("outcome", "") == "GOAL":
					clear_count += 1
					var key: String = str(i)
					rates[key] = int(rates.get(key, 0)) + 1
					heat.set_pixel(i / 7, i % 7, Color("b7d8ac"))
					if best.is_empty() or int(tire.last_result.score) > int(best.score):
						best = {"aim": tire.aim, "lean": tire.lean, "seed": seed_v, "score": tire.last_result.score, "time": tire.elapsed}
				tire.free()
			hill.free()
			await physics_frame
		var rate: float = float(clear_count) / count
		check(clear_count > 0, data.id() + " is solvable")
		check(rate <= 0.6, data.id() + " clear rate <= 60%")
		check(stuck == 0, data.id() + " no stuck rolls")
		var report: Dictionary = {"course": data.id(), "samples": count, "clears": clear_count, "rate": rate, "stuck": stuck, "best": best}
		results.append(report)
		heat.resize(420, 140, Image.INTERPOLATE_NEAREST)
		heat.save_png("res://build/solver/" + data.id().replace("/", "_") + ".png")
		print("SOLVER ", JSON.stringify(report))
	var file: FileAccess = FileAccess.open("res://build/solver/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
