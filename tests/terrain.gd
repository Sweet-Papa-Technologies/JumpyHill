extends SceneTree
var failures: Array[String] = []
var space: SubViewport
var hill: HillCourse
var data: CourseData

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func new_hill(world: int = 0) -> void:
	if is_instance_valid(space): space.free()
	space = SubViewport.new()
	space.own_world_3d = true
	root.add_child(space)
	data = CourseData.all_courses()[1 + world * 8]
	hill = HillCourse.new()
	hill.visual = false
	hill.data = data
	space.add_child(hill)
	await physics_frame
	await physics_frame

func wheel(pos: Vector3, velocity: Vector3, variant_id: int = 0) -> RollingTire:
	var tire: RollingTire = RollingTire.new()
	tire.course = data
	tire.show_visual = false
	tire.variant = load("res://src/tire/%d.tres" % variant_id)
	space.add_child(tire)
	await physics_frame
	await physics_frame
	tire.launch()
	tire.position = pos
	tire.previous = pos
	tire.linear_velocity = velocity
	tire.incoming_velocity = velocity
	tire.gust_start = 99
	tire.reset_physics_interpolation()
	return tire

func ticks(count: int) -> void:
	for i: int in range(count): await physics_frame

func run() -> void:
	Engine.max_fps = 0
	# Passes close to either physical post must succeed; the old radial margin
	# rejected these even though the full axle fits through the visible opening.
	for side: int in [-1, 1]:
		for variant_id: int in [0, 1, 2]:
			await new_hill()
			var td: TireData = load("res://src/tire/%d.tres" % variant_id)
			var x: float = data.goal_x + side * (data.goal_width * 0.5 - 0.16 - td.width * 0.5 - 0.10)
			var z: float = data.length - 1.7
			var tire: RollingTire = await wheel(Vector3(x, data.height_at(x, z) + 0.68, z), Vector3(0, -data.slope * 7, 7), variant_id)
			await ticks(100)
			check(tire.last_result.get("outcome") == "GOAL", "Near-post pass side %d tire %d: %s" % [side, variant_id, tire.last_result])
			check(not tire.post_hit, "Near post without contact is not a graze")
	await new_hill()
	var outside_x: float = data.goal_x + data.goal_width * 0.5 + 0.8
	var outside: RollingTire = await wheel(Vector3(outside_x, data.height_at(outside_x, data.length - 1) + 0.68, data.length - 1), Vector3(0, -2, 7))
	await ticks(100)
	check(outside.last_result.get("outcome") == "WIDE", "Outside the post is still a miss")
	# Wall impact threshold uses normal speed; each wheel owns its exceptions.
	for speed: float in [2.0, 8.0]:
		await new_hill()
		var wall: StaticBody3D = hill.glass_bodies.back()
		var pos: Vector3 = wall.position + Vector3(-0.45, -0.10, 0)
		var tire: RollingTire = await wheel(pos, Vector3(speed, 0, 0))
		await ticks(100)
		check(("SMASH" in tire.style.events) == (speed > RollingTire.GLASS_BREAK_SPEED), "Glass shatters only on hard normal impact: %s" % [tire.style.events])
		check(("BANK" in tire.style.events) == (speed < RollingTire.GLASS_BREAK_SPEED), "Gentle glass impact banks: %s" % [tire.style.events])
		if speed > RollingTire.GLASS_BREAK_SPEED:
			check(wall in tire.get_collision_exceptions(), "Broken glass permits the striking wheel through")
			var independent: RollingTire = await wheel(pos, Vector3(2, 0, 0))
			await ticks(100)
			check("BANK" in independent.style.events and independent.get_collision_exceptions().is_empty(), "Parallel solver wheel retains its own unbroken wall")
			tire.reset_to_aim()
			check(tire.get_collision_exceptions().is_empty(), "Retry restores glass collision")
	await new_hill()
	var gap: Rect2 = data.gap_rect()
	var center: Vector2 = gap.get_center()
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(center.x, data.height_at(center.x, center.y) + 5, center.y), Vector3(center.x, -20, center.y), 1)
	check(hill.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "The terrain gap has no invisible collider or floor")
	var falling: RollingTire = await wheel(Vector3(center.x, data.height_at(center.x, center.y) + 0.68, center.y), Vector3.ZERO)
	await ticks(160)
	check(falling.last_result.get("outcome") == "GAP" and falling.freeze, "A slow drop into the gap finishes promptly and freezes")
	falling.free()
	var z: float = gap.position.y - 0.8
	var jumper: RollingTire = await wheel(Vector3(center.x, data.height_at(center.x, z) + 0.85, z), Vector3(0, 4, 14))
	await ticks(210)
	check("GAP JUMP" in jumper.style.events, "Carrying speed clears the real gap and earns landing style: %s" % [jumper.style.events])
	await new_hill()
	var ice: Dictionary = data.features(42).filter(func(f: Dictionary) -> bool: return f.kind == "ice")[0]
	var slider: RollingTire = await wheel(Vector3(ice.x, data.height_at(ice.x, ice.z) + 0.68, ice.z), Vector3(0, -1, 3))
	await ticks(12)
	check(slider.surface_kind == "ice" and slider.physics_material_override.friction < 0.1, "Ice changes physical traction")
	slider.position.z += 4
	slider.previous = slider.position
	await ticks(2)
	check(is_equal_approx(slider.physics_material_override.friction, slider.variant.grip), "Leaving ice restores normal grip")
	await new_hill(2)
	var spring: Dictionary = data.features(42).filter(func(f: Dictionary) -> bool: return f.kind == "spring")[0]
	var bouncer: RollingTire = await wheel(Vector3(spring.x, data.height_at(spring.x, spring.z) + 0.68, spring.z), Vector3(0, -1, 3))
	await ticks(30)
	check("SPRING" in bouncer.style.events and bouncer.linear_velocity.y > 0, "Spring pad launches the physical wheel")
	space.free()
	print("TERRAIN ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures)
	quit(0 if failures.is_empty() else 1)
