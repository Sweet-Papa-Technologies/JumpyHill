extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute("res://build/glass-04")
	game.change_state(game.State.AIM)
	game._action("view")
	await create_timer(0.5).timeout
	root.get_texture().get_image().save_png("res://build/glass-04/intact.png")
	game.change_state(game.State.ROLL)
	var wall: StaticBody3D = game.course.glass_bodies[1]
	game.tire.position = wall.position + Vector3(0.45, -0.1, 0)
	game.tire.previous = game.tire.position
	game.tire.linear_velocity = Vector3(-8, 0, 0)
	game.tire.incoming_velocity = game.tire.linear_velocity
	game.tire.reset_physics_interpolation()
	for i: int in range(60):
		await physics_frame
		if not game.course.broken_glass.is_empty(): break
	assert(not game.course.broken_glass.is_empty(), "Hard contact breaks rendered pane")
	assert(game.course.shards.size() == 16, "Visible shard burst")
	var index: int = game.course.broken_glass.keys()[0]

	await process_frame
	await RenderingServer.frame_post_draw
	assert(game.course.glass.get_instance_transform(index).basis.get_scale().is_zero_approx(), "Batched pane disappears")
	root.get_texture().get_image().save_png("res://build/glass-04/smash.png")
	await create_timer(1.4).timeout
	assert(game.course.shards.is_empty(), "Shards expire")
	game._action("retry")
	assert(game.course.broken_glass.is_empty(), "Retry restores all glass visuals")
	await process_frame
	await RenderingServer.frame_post_draw
	assert(game.course.glass.get_instance_transform(index).is_equal_approx(game.course.glass_transforms[index]))
	print("GLASS VISUAL PASS pane disappears, 16 shards expire, retry restores pane")
	root.get_node("Sound").stop_all()
	await create_timer(0.2).timeout
	quit()
