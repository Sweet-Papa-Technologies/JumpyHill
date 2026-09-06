class_name RollPredictor
extends RefCounted
# Uses Jolt's body_test_motion against the real terrain. Contact response is a
# reduced rolling model; solver validation always uses the full RigidBody3D.
static func trace(tire: RollingTire, seconds: float = 1.0) -> PackedVector3Array:
	var path: PackedVector3Array = []
	var pos: Vector3 = tire.position
	var velocity: Vector3 = RollingTire.launch_velocity(tire.course, tire.aim, tire.variant)
	var dt: float = 1.0 / 60.0
	var params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
	params.margin = 0.01
	var result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
	for i: int in range(int(seconds / dt)):
		velocity += Vector3(tire.lean * RollingTire.FEEL.lean_force / tire.mass, -9.8, 0) * dt
		params.from = Transform3D(tire.basis, pos)
		params.motion = velocity * dt
		if PhysicsServer3D.body_test_motion(tire.get_rid(), params, result):
			pos += result.get_travel()
			if result.get_collision_normal().y < 0.6:
				break
			var normal: Vector3 = result.get_collision_normal()
			velocity = velocity.slide(normal)
			pos += velocity * dt * (1.0 - result.get_collision_safe_fraction())
		else:
			pos += params.motion
		if i % 5 == 0:
			path.append(pos)
	return path
