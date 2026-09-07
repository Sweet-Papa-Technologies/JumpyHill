extends SceneTree
var game: Node
var output: String = "res://build/store/screenshots"

func _initialize() -> void:
	call_deferred("run")

func shot(name_v: String, dimensions: Vector2i, course_id: String, state_v: int, overview: bool = false) -> void:
	root.size = dimensions / 3
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = dimensions
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	for data: CourseData in CourseData.all_courses():
		if data.id() == course_id: game.load_course(data)
	game.change_state(state_v)
	game.camera.first_person = not overview
	game.ui.rebuild()
	for frame: int in range(100): await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	assert(img.get_size() == dimensions, "Screenshot must retain its full native pixel dimensions")
	img.convert(Image.FORMAT_RGB8)
	img.save_png(output + "/" + name_v + ".png")
	print("STORE CAPTURE ", name_v, " ", img.get_size())

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output + "/iphone")
	DirAccess.make_dir_recursive_absolute(output + "/ipad")
	game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	game.aim_value = -0.6
	await shot("iphone/01-meadow", Vector2i(1290, 2796), "meadow/03", game.State.AIM)
	await shot("iphone/02-coral", Vector2i(1290, 2796), "coral/04", game.State.AIM, true)
	await shot("iphone/03-ember", Vector2i(1290, 2796), "ember/06", game.State.AIM, true)
	await shot("iphone/04-title", Vector2i(1290, 2796), "meadow/01", game.State.TITLE)
	await shot("ipad/01-meadow", Vector2i(2064, 2752), "meadow/03", game.State.AIM)
	await shot("ipad/02-coral", Vector2i(2064, 2752), "coral/04", game.State.AIM, true)
	await shot("feature-graphic", Vector2i(1024, 500), "coral/04", game.State.TITLE)
	root.get_node("Sound").stop_all()
	await create_timer(0.2, true, false, true).timeout
	quit()
