extends Node

enum State { BOOT, TITLE, COURSE_SELECT, AIM, ROLL, RESULT, PAUSE, SETTINGS, CREDITS, GARAGE }
var state: State = State.BOOT
var previous_state: State = State.TITLE
var settings_return: State = State.TITLE
var courses: Array[CourseData] = []
var course: HillCourse
var tire: RollingTire
var camera: HillCamera
var world_root: Node3D
var viewport: SubViewport
var viewport_container: SubViewportContainer
var ui: GameInterface
var guide: Node3D
var environment: WorldEnvironment
var aim_value: float = 0.0
var lean_value: float = 0.0
var roll_seed: int = 42
var selected_world: int = 0
var selected_number: int = 1
var purist: bool = false
var result: Dictionary = {}
var daily: Dictionary = {}
var pop_text: String = ""
var pop_time: float = 0.0
var drag_start: Vector2
var dragging: bool = false
var guide_dirty: bool = false
var slow_used: bool = false
var slow_until: float = 0.0
var capture_path: String = ""
var capture_at: int = 90
var frames: int = 0
var particles: Array[Dictionary] = []
var screen_size: Vector2
var automation: bool = false
var automation_output: String = "res://build/playtest"
var quitting: bool = false
var automating_step: int = 0
var frame_times: Array[float] = []
var screenshot_index: int = 0
var retired_worlds: Array[World3D] = []
var trails: TireTrails
var hit_until: int = 0
var perf_mode: bool = false
var perf_wall: Array[float] = []
var perf_cpu: Array[float] = []
var perf_physics: Array[float] = []
var perf_draws: int = 0
var perf_primitives: int = 0
var speed_fx: ShaderMaterial

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 60
	courses = CourseData.all_courses()
	viewport_container = SubViewportContainer.new()
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.stretch = true
	speed_fx = ShaderMaterial.new()
	speed_fx.shader = preload("res://src/feel/shaders/speed.gdshader")
	viewport_container.material = speed_fx
	add_child(viewport_container)
	viewport = SubViewport.new()
	viewport.world_3d = World3D.new()
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport_container.add_child(viewport)
	world_root = Node3D.new()
	world_root.process_mode = Node.PROCESS_MODE_PAUSABLE
	viewport.add_child(world_root)
	_setup_light()
	trails = TireTrails.new()
	world_root.add_child(trails)
	camera = HillCamera.new()
	world_root.add_child(camera)
	camera.current = true
	ui = GameInterface.new()
	ui.game = self
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	ui.action.connect(_action)
	get_viewport().size_changed.connect(_resize)
	load_course(courses[1])
	_resize()
	change_state(State.TITLE)
	_command_line()

func _setup_light() -> void:
	environment = WorldEnvironment.new()
	world_root.add_child(environment)
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("abcdd5")
	sky_mat.sky_horizon_color = Color("e6edd8")
	sky_mat.ground_bottom_color = Color("b4cebe")
	sky_mat.ground_horizon_color = Color("e6edd8")
	sky_mat.sky_curve = 0.25
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e4ecd9")
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	environment.environment = env
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color("fff0d5")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 110
	world_root.add_child(sun)

func _resize() -> void:
	screen_size = get_viewport().get_visible_rect().size
	var portrait: bool = screen_size.x / screen_size.y < 1
	var side: float = 0 if portrait else screen_size.x * 0.29
	var top: float = 0.0
	var bottom: float = 1.0
	if portrait:
		match state:
			State.AIM: top = 0.155; bottom = 0.76
			State.TITLE: top = 0.28; bottom = 0.78
			State.COURSE_SELECT: top = 0.34; bottom = 0.77
			State.RESULT: top = 0.34; bottom = 0.77
	viewport_container.position = Vector2(side, screen_size.y * top)
	viewport_container.size = Vector2(screen_size.x - side, screen_size.y * (bottom - top))
	camera.portrait = portrait
	ui.rebuild()

func load_course(data: CourseData) -> void:
	if is_instance_valid(course):
		world_root.remove_child(course)
		course.queue_free()
	if is_instance_valid(tire):
		world_root.remove_child(tire)
		tire.queue_free()
	if is_instance_valid(guide):
		guide.queue_free()
	for p: Dictionary in particles:
		if is_instance_valid(p.node):
			p.node.queue_free()
	particles.clear()
	course = HillCourse.new()
	course.data = data
	course.roll_seed = roll_seed
	world_root.add_child(course)
	selected_world = data.world
	selected_number = maxi(1, data.number)
	_create_tire()
	guide = Node3D.new()
	world_root.add_child(guide)
	camera.course = data
	camera.target = tire
	camera.blend_to("aim")
	var sky_mat: ProceduralSkyMaterial = environment.environment.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = CourseData.PALETTES[data.world][4]
	sky_mat.sky_horizon_color = CourseData.PALETTES[data.world][4].lerp(CourseData.PALETTES[data.world][1], 0.4)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	sky_mat.ground_bottom_color = sky_mat.sky_top_color
	Sound.set_world(data.world)
	_apply_post_markers()

func _create_tire() -> void:
	tire = RollingTire.new()
	tire.course = course.data
	tire.roll_seed = roll_seed
	tire.aim = aim_value
	tire.lean = lean_value
	tire.purist = purist
	tire.variant = load("res://src/tire/%d.tres" % int(Save.data.tire)) as TireData
	world_root.add_child(tire)
	tire.finished.connect(_finish)
	tire.styled.connect(_style)

func change_state(next: State) -> void:
	_exit_state(state)
	state = next
	_enter_state(next)

func _exit_state(_old: State) -> void:
	dragging = false
	Engine.time_scale = 1.0

func _enter_state(next: State) -> void:
	get_tree().paused = next in [State.PAUSE, State.SETTINGS, State.CREDITS, State.GARAGE]
	camera.reduce_motion = Save.data.settings.reduce_motion
	match next:
		State.TITLE:
			ui.page = "title"
			tire.reset_to_aim()
			camera.blend_to("aim")
		State.COURSE_SELECT:
			ui.page = "select"
			tire.reset_to_aim()
			camera.blend_to("aim")
		State.AIM:
			_reset_physics_space()
			trails.clear()
			ui.page = "aim"
			tire.aim = aim_value
			tire.lean = lean_value
			tire.purist = purist
			tire.roll_seed = roll_seed
			tire.linear_damp = 0.05
			tire.angular_damp = 0.03
			tire.reset_to_aim()
			camera.blend_to("aim")
			guide_dirty = true
			Sound.tier = 0
		State.ROLL:
			ui.page = "roll"
			tire.launch()
			camera.blend_to("roll")
			slow_used = false
			slow_until = 0
			Platform.vibrate("light")
			Sound.play("WHOOSH")
		State.RESULT:
			ui.page = "result"
			camera.blend_to("result")
		State.PAUSE: ui.page = "pause"
		State.SETTINGS: ui.page = "settings"
		State.CREDITS: ui.page = "credits"
		State.GARAGE: ui.page = "garage"
	guide.visible = next == State.AIM
	_resize()
	ui.rebuild()

func _action(name: String, value: Variant = null) -> void:
	match name:
		"play", "select":
			daily = {}
			change_state(State.COURSE_SELECT)
		"title": change_state(State.TITLE)
		"start":
			if Save.world_unlocked(selected_world):
				change_state(State.AIM)
		"tutorial":
			load_course(courses[0])
			change_state(State.AIM)
		"world_prev", "world_next":
			selected_world = posmod(selected_world + (-1 if name == "world_prev" else 1), 4)
			selected_number = 1
			_preview_selected()
		"course":
			selected_number = int(value)
			_preview_selected()
		"roll":
			if state == State.AIM:
				change_state(State.ROLL)
		"aim", "lean":
			if name == "aim":
				aim_value = float(value)
			else:
				lean_value = float(value)
			tire.aim = aim_value
			tire.lean = lean_value
			if state == State.AIM:
				tire.position = RollingTire.launch_position(course.data, aim_value)
				guide_dirty = true
		"nudge":
			if tire.nudge(float(value)):
				Platform.vibrate("medium")
		"purist":
			purist = not purist
			tire.purist = purist
			ui.rebuild()
		"retry": change_state(State.AIM)
		"new_seed":
			roll_seed = (roll_seed * 1664525 + 1013904223) & 0x7fffffff
			daily = {}
			load_course(course.data)
			change_state(State.AIM)
		"next":
			daily = {}
			var index: int = courses.find(course.data)
			var next_course: CourseData = courses[mini(index + 1, courses.size() - 1)]
			if Save.world_unlocked(next_course.world):
				load_course(next_course)
				change_state(State.AIM)
			else:
				change_state(State.COURSE_SELECT)
				_toast("Earn 4 stars here to open the next world.")
		"pause":
			previous_state = state
			change_state(State.PAUSE)
		"resume":
			# Resume without re-entering ROLL, which would launch a fresh tire.
			state = previous_state
			get_tree().paused = false
			ui.page = "roll" if state == State.ROLL else "aim"
			ui.rebuild()
		"settings":
			settings_return = state
			change_state(State.SETTINGS)
		"settings_back":
			Save.persist()
			change_state(settings_return)
		"credits": change_state(State.CREDITS)
		"garage": change_state(State.GARAGE)
		"tire":
			var td: TireData = load("res://src/tire/%d.tres" % int(value)) as TireData
			if Save.stars_total() >= td.unlock_stars:
				Save.data.tire = int(value)
				Save.persist()
				load_course(course.data)
				ui.rebuild()
		"master", "music", "sfx":
			Save.data.settings[name] = float(value)
			Sound.apply_settings()
		"setting_toggle":
			Save.data.settings[value] = not Save.data.settings[value]
			Save.persist()
			camera.reduce_motion = Save.data.settings.reduce_motion
			_apply_post_markers()
			ui.rebuild()
		"daily":
			daily = Save.daily_for(Time.get_date_string_from_system())
			roll_seed = int(daily.seed)
			load_course(courses[int(daily.course)])
			change_state(State.AIM)
			_toast("DAILY ROLL  /  " + str(daily.date))
		"share": _share()

func _preview_selected() -> void:
	for data: CourseData in courses:
		if data.world == selected_world and data.number == selected_number:
			load_course(data)
			break
	ui.rebuild()

func _process(dt: float) -> void:
	retired_worlds.clear()
	var rolling: bool = state == State.ROLL and not get_tree().paused
	Sound.set_roll(tire.linear_velocity.length() if rolling else 0, course.data.world)
	var speed_v: float = clampf((tire.linear_velocity.length() / course.data.max_speed - 0.8) / 0.2, 0, 1) if rolling and not Save.data.settings.reduce_motion else 0.0
	speed_fx.set_shader_parameter("speed", speed_v)
	speed_fx.set_shader_parameter("combo", clampf(tire.style.combo / 12.0, 0, 1) if rolling and not Save.data.settings.reduce_motion else 0.0)
	frames += 1
	pop_time = maxf(0, pop_time - dt)
	if state == State.ROLL:
		Sound.tier = minf(2.0, tire.style.score / 120.0)
		course.tick_gate(tire.elapsed)
	if guide_dirty and state == State.AIM:
		guide_dirty = false
		_update_guide()
	if not get_tree().paused:
		_tick_particles(dt)
		trails.tick(dt, tire)
	if hit_until > 0 and Time.get_ticks_msec() >= hit_until:
		hit_until = 0
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if perf_mode and state == State.ROLL and tire.elapsed > 1:
		perf_wall.append(dt * 1000)
		perf_cpu.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
		perf_physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)
		perf_draws = maxi(perf_draws, viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME))
		perf_primitives = maxi(perf_primitives, viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
	if capture_path != "" and frames == capture_at:
		_capture(capture_path)
	if automation:
		_automate(dt)

func _update_guide() -> void:
	for child: Node in guide.get_children():
		child.queue_free()
	var points: PackedVector3Array = RollPredictor.trace(tire)
	for i: int in range(points.size()):
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 0.11 - i * 0.003
		mesh.height = mesh.radius * 2
		mesh.radial_segments = 6
		mesh.rings = 3
		var dot: MeshInstance3D = MeshInstance3D.new()
		dot.mesh = mesh
		dot.position = points[i] + Vector3.UP * 0.05
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color("fff5d5")
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dot.material_override = mat
		guide.add_child(dot)

func _finish(outcome: Dictionary) -> void:
	result = outcome
	if perf_mode:
		perf_wall.sort()
		perf_cpu.sort()
		perf_physics.sort()
		var report: Dictionary = {"device": RenderingServer.get_video_adapter_name(), "frames": perf_wall.size(), "p95_wall_ms": perf_wall[int(perf_wall.size() * 0.95)], "p95_cpu_ms": perf_cpu[int(perf_cpu.size() * 0.95)], "p95_physics_ms": perf_physics[int(perf_physics.size() * 0.95)], "max_draw_calls": perf_draws, "max_primitives": perf_primitives}
		var report_file: FileAccess = FileAccess.open("res://build/performance.json", FileAccess.WRITE)
		report_file.store_string(JSON.stringify(report, "\t"))
		print("PERFORMANCE ", JSON.stringify(report))
		_quit.call_deferred(0 if report.p95_wall_ms < 16.6 else 1)
	Save.record(course.data.id(), int(result.stars), int(result.score), roll_seed)
	if not daily.is_empty():
		var old: Dictionary = Save.data.daily.get(daily.date, {})
		if int(result.score) >= int(old.get("score", -1)):
			Save.data.daily[daily.date] = {"score": result.score, "stars": result.stars, "seed": roll_seed, "course": course.data.id()}
			Save.persist()
	Sound.play(str(result.outcome))
	Platform.vibrate("heavy")
	if result.outcome == "GOAL":
		_burst(tire.position, 70)
		if not Save.data.settings.reduce_motion:
			for post: Node3D in course.posts:
				var wobble: Tween = create_tween()
				wobble.tween_property(post, "rotation:z", 0.12, 0.08)
				wobble.tween_property(post, "rotation:z", -0.08, 0.09)
				wobble.tween_property(post, "rotation:z", 0.0, 0.12)
	change_state(State.RESULT)

func _style(event: String) -> void:
	pop_text = event
	pop_time = 0.8
	Sound.play(event)
	if event in ["BOING", "NICE", "GRIND"]:
		if not Save.data.settings.reduce_motion:
			hit_until = Time.get_ticks_msec() + 45
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		camera.trauma = minf(0.4, camera.trauma + 0.25)
		Platform.vibrate("medium")
		_burst(tire.position, 9)
		if is_instance_valid(tire.model) and not Save.data.settings.reduce_motion:
			var tween: Tween = create_tween()
			tween.tween_property(tire.model, "scale", Vector3(1.1, 0.82, 1.1), 0.045)
			tween.tween_property(tire.model, "scale", Vector3.ONE, 0.14)

func _burst(pos: Vector3, count: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = roll_seed + tire.style.events.size()
	for i: int in range(count):
		var node: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(0.13, 0.04, 0.21)
		node.mesh = mesh
		node.material_override = course.material(CourseData.PALETTES[course.data.world][i % 4])
		node.position = pos + Vector3.UP
		world_root.add_child(node)
		particles.append({"node": node, "v": Vector3(rng.randf_range(-4, 4), rng.randf_range(3, 7), rng.randf_range(-4, 4)), "life": 2.2})

func _tick_particles(dt: float) -> void:
	for i: int in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.life -= dt
		if p.life <= 0:
			p.node.queue_free()
			particles.remove_at(i)
			continue
		p.v.y -= 6 * dt
		p.node.position += p.v * dt
		p.node.rotation += Vector3(2, 3, 1) * dt

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if state == State.PAUSE:
					_action("resume")
				elif state in [State.AIM, State.ROLL]:
					_action("pause")
				else:
					_action("select")
			KEY_SPACE, KEY_ENTER:
				if state == State.AIM: _action("roll")
				elif state == State.RESULT: _action("retry")
				elif state == State.TITLE: _action("play")
			KEY_R:
				if state in [State.RESULT, State.AIM, State.ROLL]: _action("retry")
			KEY_LEFT, KEY_A:
				if state == State.AIM: _action("aim", clampf(aim_value - 0.05, -1, 1))
				elif state == State.ROLL: _action("nudge", -1)
			KEY_RIGHT, KEY_D:
				if state == State.AIM: _action("aim", clampf(aim_value + 0.05, -1, 1))
				elif state == State.ROLL: _action("nudge", 1)
			KEY_UP, KEY_W:
				if state == State.AIM: _action("lean", clampf(lean_value + 0.5, -15, 15))
			KEY_DOWN, KEY_S:
				if state == State.AIM: _action("lean", clampf(lean_value - 0.5, -15, 15))
		if is_instance_valid(ui.aim_slider): ui.aim_slider.set_value_no_signal(aim_value)
		if is_instance_valid(ui.lean_slider): ui.lean_slider.set_value_no_signal(lean_value)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer(event.position, event.pressed)
	elif event is InputEventScreenTouch:
		_pointer(event.position, event.pressed)
	elif event is InputEventMouseMotion and dragging:
		_drag(event.relative)
	elif event is InputEventScreenDrag and dragging:
		_drag(event.relative)

func _pointer(pos: Vector2, pressed: bool) -> void:
	if pressed:
		dragging = state in [State.AIM, State.ROLL]
		drag_start = pos
	elif dragging:
		dragging = false
		if state == State.AIM and pos.distance_to(drag_start) > 8:
			_action("roll")
		elif state == State.ROLL and absf(pos.x - drag_start.x) > 30:
			_action("nudge", signf(pos.x - drag_start.x))

func _drag(relative: Vector2) -> void:
	if state == State.AIM:
		_action("aim", clampf(aim_value + relative.x / screen_size.x * 2.5, -1, 1))
		_action("lean", clampf(lean_value - relative.y / screen_size.y * 30, -15, 15))
		if is_instance_valid(ui.aim_slider): ui.aim_slider.set_value_no_signal(aim_value)
		if is_instance_valid(ui.lean_slider): ui.lean_slider.set_value_no_signal(lean_value)

func _toast(text: String) -> void:
	ui.toast = text
	ui.toast_time = 3

func _share() -> void:
	await RenderingServer.frame_post_draw
	var path: String = "user://TREADFALL_%d.png" % roll_seed
	var error: Error = get_viewport().get_texture().get_image().save_png(path)
	if error == OK:
		Platform.share_image(path)
		_toast("Postcard saved. Go make someone's day.")
	else:
		_toast("Couldn't save the postcard. Please try again.")

func _capture(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE ", path)
	if not automation:
		_quit()

func _command_line() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var opts: Dictionary = {}
	for i: int in range(args.size()):
		if args[i].begins_with("--"):
			opts[args[i]] = args[i + 1] if i + 1 < args.size() and not args[i + 1].begins_with("--") else "true"
	if opts.has("--seed"): roll_seed = int(opts["--seed"])
	if opts.has("--aim"): aim_value = float(opts["--aim"])
	if opts.has("--lean"): lean_value = float(opts["--lean"])
	if opts.has("--course"):
		for c: CourseData in courses:
			if c.id() == opts["--course"]:
				load_course(c)
	if opts.has("--state"):
		var states: Dictionary = {"title": State.TITLE, "select": State.COURSE_SELECT, "aim": State.AIM, "roll": State.ROLL, "settings": State.SETTINGS, "credits": State.CREDITS, "garage": State.GARAGE}
		change_state(states.get(opts["--state"], State.TITLE))
	if opts.has("--capture"):
		capture_path = opts["--capture"]
		capture_at = int(opts.get("--capture-at", "90"))
	if opts.has("--perf"):
		perf_mode = true
		Engine.max_fps = 0
		Save.data.settings.reduce_motion = true
		load_course(courses.back())
		aim_value = -0.9
		lean_value = -5
		change_state(State.AIM)
		change_state.call_deferred(State.ROLL)
	if opts.has("--playtest"):
		automation = true
		Sound.enabled = false
		automation_output = opts.get("--test-output", "res://build/playtest")
		DirAccess.make_dir_recursive_absolute(automation_output)

func _automate(dt: float) -> void:
	if state == State.ROLL:
		frame_times.append(dt * 1000)
	match automating_step:
		0:
			if frames > 45:
				_capture(automation_output + "/title.png")
				_action("play")
				automating_step = 1
		1:
			if frames > 90:
				_capture(automation_output + "/select.png")
				_action("start")
				automating_step = 2
		2:
			if frames > 140:
				_capture(automation_output + "/aim.png")
				_action("roll")
				automating_step = 3
		3:
			if tire.elapsed > 2.0:
				_capture(automation_output + "/roll.png")
				_action("pause")
				automating_step = 4
		4:
			if frames % 30 == 0:
				assert(get_tree().paused)
				var old_time: float = tire.elapsed
				_action("resume")
				assert(tire.elapsed == old_time)
				automating_step = 5
		5:
			if state == State.RESULT:
				_capture(automation_output + "/result.png")
				var started: int = Time.get_ticks_usec()
				_action("retry")
				var retry_ms: float = (Time.get_ticks_usec() - started) / 1000.0
				assert(state == State.AIM and retry_ms < 300)
				print("PLAYTEST retry_ms=", retry_ms, " result=", result)
				_action("settings")
				automating_step = 6
		6:
			if frames % 30 == 0:
				_capture(automation_output + "/settings.png")
				_action("setting_toggle", "reduce_motion")
				_action("setting_toggle", "reduce_motion")
				_action("settings_back")
				_action("daily")
				assert(state == State.AIM and roll_seed == int(daily.seed))
				frame_times.sort()
				var report: Dictionary = {"retry": "pass", "pause_resume": "pass", "daily": "pass", "frames": frame_times.size(), "p95_frame_ms": frame_times[int(frame_times.size() * 0.95)] if not frame_times.is_empty() else 0, "result": result}
				var file: FileAccess = FileAccess.open(automation_output + "/report.json", FileAccess.WRITE)
				file.store_string(JSON.stringify(report, "\t"))
				print("PLAYTEST PASS ", JSON.stringify(report))
				automating_step = 7
		7:
			if frames % 60 == 0: _quit()

func _reset_physics_space() -> void:
	# Jolt retains contact caches/body ordering in a reused space. A fresh space
	# gives same-seed retries a canonical starting state without rebuilding meshes.
	retired_worlds.append(viewport.world_3d)
	viewport.remove_child(world_root)
	viewport.world_3d = World3D.new()
	viewport.add_child(world_root)
	course.tick_gate(0)

func _physics_process(_dt: float) -> void:
	if state != State.ROLL or get_tree().paused:
		return
	# Trigger and end slow motion on simulation time, independent of render FPS.
	if not slow_used and tire.position.z > course.data.length - 4 and absf(tire.position.x - course.data.goal_x) < course.data.goal_width and not Save.data.settings.reduce_motion:
		slow_used = true
		slow_until = tire.elapsed + 0.14
		Engine.time_scale = 0.35
	if slow_used and slow_until > 0 and tire.elapsed >= slow_until:
		Engine.time_scale = 1
		slow_until = 0

func _apply_post_markers() -> void:
	for i: int in range(course.posts.size()):
		var post: MeshInstance3D = course.posts[i] as MeshInstance3D
		post.material_override = course.material((Color("294d4c") if i == 0 else Color("f5ce78")) if Save.data.settings.colorblind else Color("fff3d7"))

func _quit(code: int = 0) -> void:
	if quitting:
		return
	quitting = true
	Sound.stop_all()
	await get_tree().create_timer(0.15, true, false, true).timeout
	get_tree().quit(code)
