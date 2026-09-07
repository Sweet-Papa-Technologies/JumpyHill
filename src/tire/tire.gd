class_name RollingTire
extends RigidBody3D
signal finished(result: Dictionary)
signal styled(event: String)
const FEEL: FeelData = preload("res://src/feel/feel.tres")
var course: CourseData
var variant: TireData = preload("res://src/tire/0.tres")
var roll_seed: int = 42
var aim: float = 0.0
var lean: float = 0.0
var active: bool = false
var elapsed: float = 0.0
var nudges: int = 0
var purist: bool = false
var tilted: bool = false
var last_nudge: float = -10.0
var style: StyleTracker = StyleTracker.new()
var features: Array[Dictionary] = []
var touched: Dictionary = {}
var model: Node3D
var previous: Vector3
var air_time: float = 0.0
var air_awarded: float = 0.0
var grounded_before: bool = true
var speed_time: float = 0.0
var post_hit: bool = false
var show_visual: bool = true
var gust_start: float = 3.0
var gust_force: float = 0.0
var last_result: Dictionary = {}
var stalled_time: float = 0.0
var motion_anchor: Vector3
const STUCK_RADIUS: float = 0.12
const STUCK_SECONDS: float = 3.0
var incoming_velocity: Vector3 = Vector3.ZERO
var crossed_gap: bool = false
var surface_kind: String = "ground"
var glass_contacts: Dictionary = {}
const GLASS_BREAK_SPEED: float = 4.8

func _ready() -> void:
	mass = variant.mass
	continuous_cd = true
	collision_layer = 2
	collision_mask = 1
	lock_rotation = false
	axis_lock_angular_y = false
	axis_lock_angular_z = false
	linear_damp = 0.05
	angular_damp = 0.03
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)
	var pm: PhysicsMaterial = PhysicsMaterial.new()
	pm.friction = variant.grip
	pm.bounce = variant.bounce
	physics_material_override = pm
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = FEEL.tire_radius
	shape.height = variant.width
	var col: CollisionShape3D = CollisionShape3D.new()
	col.shape = shape
	col.rotation.z = PI / 2
	add_child(col)
	if show_visual:
		_create_model()
	freeze = true
	if course != null:
		reset_to_aim()

func _create_model() -> void:
	model = Node3D.new()
	add_child(model)
	var rubber: StandardMaterial3D = StandardMaterial3D.new()
	rubber.albedo_color = Color("344549")
	rubber.roughness = 0.95
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.34
	torus.outer_radius = FEEL.tire_radius
	torus.rings = 24
	torus.ring_segments = 10
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = torus
	mesh.rotation.z = PI / 2
	mesh.scale.y = variant.width / 0.31
	mesh.material_override = rubber
	model.add_child(mesh)
	var rim: CylinderMesh = CylinderMesh.new()
	rim.top_radius = 0.34
	rim.bottom_radius = 0.34
	rim.height = variant.width * 0.7
	rim.radial_segments = 16
	var hub: MeshInstance3D = MeshInstance3D.new()
	hub.mesh = rim
	hub.rotation.z = PI / 2
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = variant.accent
	mat.metallic = 0.3
	mat.roughness = 0.5
	hub.material_override = mat
	model.add_child(hub)
	var tread_mat: StandardMaterial3D = StandardMaterial3D.new()
	tread_mat.albedo_color = Color("52605f")
	var tread_mesh: BoxMesh = BoxMesh.new()
	tread_mesh.size = Vector3(variant.width + 0.06, 0.065, 0.10)
	tread_mesh.material = tread_mat
	var multi: MultiMesh = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = tread_mesh
	multi.instance_count = 20
	for i: int in range(20):
		var angle: float = float(i) / 20 * TAU
		multi.set_instance_transform(i, Transform3D(Basis(Vector3.RIGHT, angle), Vector3(0, cos(angle) * 0.625, sin(angle) * 0.625)))
	var treads: MultiMeshInstance3D = MultiMeshInstance3D.new()
	treads.multimesh = multi
	model.add_child(treads)

func reset_to_aim() -> void:
	freeze = true
	active = false
	elapsed = 0.0
	nudges = 0
	tilted = false
	last_nudge = -10.0
	style = StyleTracker.new()
	touched.clear()
	for body: PhysicsBody3D in get_collision_exceptions():
		remove_collision_exception_with(body)
	glass_contacts.clear()
	crossed_gap = false
	surface_kind = "ground"
	physics_material_override.friction = variant.grip
	post_hit = false
	stalled_time = 0.0
	last_result = {}
	air_time = 0.0
	air_awarded = 0.0
	speed_time = 0.0
	features = course.features(roll_seed)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = roll_seed
	gust_start = rng.randf_range(2.5, 5.5)
	gust_force = rng.randf_range(-3.5, 3.5)
	rotation = Vector3(0, aim * deg_to_rad(25), 0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	position = launch_position(course, aim)
	previous = position
	motion_anchor = position
	reset_physics_interpolation()

static func launch_position(data: CourseData, direction: float) -> Vector3:
	var x: float = direction * 2.6
	return Vector3(x, data.height_at(x, 0) + FEEL.tire_radius + 0.025, 0)

static func launch_velocity(data: CourseData, direction: float, tire_data: TireData) -> Vector3:
	var angle: float = direction * deg_to_rad(25.0)
	return Vector3(sin(angle), -data.slope * cos(angle), cos(angle)).normalized() * data.launch_speed * tire_data.speed_scale

func launch() -> void:
	reset_to_aim()
	freeze = false
	sleeping = false
	active = true
	linear_velocity = launch_velocity(course, aim, variant)
	angular_velocity = transform.basis.x * linear_velocity.length() / FEEL.tire_radius
	incoming_velocity = linear_velocity

func nudge(side: float) -> bool:
	if not active or purist or tilted:
		return false
	if nudges >= 2:
		tilted = true
		add_style("TILT")
		return false
	if elapsed - last_nudge < FEEL.nudge_cooldown:
		return false
	nudges += 1
	last_nudge = elapsed
	apply_central_impulse(Vector3(side * FEEL.nudge_strength, 0, 0))
	return true

func add_style(event: String) -> void:
	style.add(event)
	styled.emit(event)

func _physics_process(dt: float) -> void:
	if not active:
		return
	elapsed += dt
	# Lean supplies continuous force and rolling torque, never teleports the tire.
	var height: float = position.y - course.height_at(position.x, position.z) - FEEL.tire_radius
	var ground_exists: bool = course.has_ground(position.x, position.z)
	var on_ground: bool = ground_exists and height > -0.4 and height < 0.18
	if not ground_exists and absf(position.x) < course.width * 0.5 and position.z > 3:
		crossed_gap = true
	if height < -1.6 and position.z > 3:
		_finish("GAP" if crossed_gap else "WIDE", 0.0, absf(position.x - course.goal_x))
		return
	if on_ground:
		apply_central_force(Vector3(lean * FEEL.lean_force, 0, 0))
	var axle: Vector3 = transform.basis.x.normalized()
	var flat_axle: Vector3 = Vector3(axle.x, 0, axle.z).normalized()
	flat_axle = (flat_axle * cos(deg_to_rad(lean)) + Vector3.UP * sin(deg_to_rad(lean))).normalized()
	apply_torque(axle.cross(flat_axle) * 180.0)
	apply_torque(Vector3.UP * (lean * 0.22 - angular_velocity.y * 8.0))
	if elapsed >= gust_start and elapsed < gust_start + 0.65:
		apply_central_force(Vector3(gust_force, 0, 0))
	var speed: float = linear_velocity.length()
	var cap: float = course.max_speed * variant.speed_scale
	# A spinning axle or contact jitter is not forward progress. Let slow rolls
	# continue indefinitely while they move beyond this small physical radius.
	if position.distance_to(motion_anchor) >= STUCK_RADIUS:
		motion_anchor = position
		stalled_time = 0.0
	else:
		stalled_time += dt
	if stalled_time >= STUCK_SECONDS:
		_finish("BLOCKED", 0.0, absf(position.x - course.goal_x))
		return
	if speed > cap:
		apply_central_force(-linear_velocity.normalized() * (speed - cap) * mass * 30.0)
	var grounded: bool = on_ground
	if not grounded and position.z > 3:
		air_time += dt
		air_awarded += dt
		if air_awarded >= 0.25:
			air_awarded -= 0.25
			add_style("AIR")
	elif not grounded_before:
		if crossed_gap:
			add_style("GAP JUMP")
			crossed_gap = false
		if air_time >= 0.35:
			add_style("NICE")
		air_time = 0.0
	grounded_before = grounded
	if speed > cap * 0.9:
		speed_time += dt
		if speed_time >= 1.0:
			speed_time = 0.0
			add_style("FULL SEND")
	surface_kind = "ground"
	physics_material_override.friction = variant.grip
	for i: int in range(features.size()):
		var f: Dictionary = features[i]
		var dx: float = position.x - float(f.x)
		var dz: float = position.z - float(f.z)
		var distance: float = Vector2(dx, dz).length()
		if touched.has(i) and f.kind not in ["ice", "mud"]:
			continue
		match f.kind:
			"bumper", "peg":
				if distance < (1.25 if f.kind == "bumper" else 0.9) and height > -0.4 and height < 1.1:
					touched[i] = true
					if f.kind == "bumper":
						var normal: Vector3 = Vector3(dx, 0.12, maxf(0.3, absf(dz))).normalized()
						apply_central_impulse(normal * 24 * f.strength)
						add_style("BOING")
					else:
						styled.emit("TOCK")
				elif dz > 0.5 and distance < 1.5:
					touched[i] = true
					add_style("SO CLOSE")
			"ramp":
				if absf(dx) < 1.3 and absf(dz) < 0.7 and height > -0.4 and height < 1.3:
					touched[i] = true
					apply_central_impulse(Vector3(0, 34, 8))
					styled.emit("WHOOSH")
			"boost":
				if absf(dx) < 1.2 and absf(dz) < 1.5 and grounded:
					touched[i] = true
					apply_central_impulse(Vector3(0, 0, 32))
					styled.emit("BOOST")
			"mud":
				if absf(dx) < 1.2 and absf(dz) < 1.5 and grounded:
					apply_central_force(-linear_velocity * mass * 0.8)
			"ice":
				if absf(dx) < 1.2 and absf(dz) < 1.5 and grounded:
					surface_kind = "ice"
					physics_material_override.friction = 0.035
					if not touched.has(i):
						touched[i] = true
						styled.emit("SLIDE")
			"spring":
				if absf(dx) < 1.2 and absf(dz) < 1.5 and grounded:
					touched[i] = true
					apply_central_impulse(Vector3(0, 46, 5))
					add_style("SPRING")
			"rail":
				if absf(dx) < 0.55 and absf(dz) < 3.5 and height > 0.25:
					touched[i] = true
					add_style("GRIND")
	var goal_delta: float = absf(position.x - course.goal_x)
	if previous.z < course.length and position.z >= course.length:
		var t: float = (course.length - previous.z) / (position.z - previous.z)
		var crossing_x: float = lerpf(previous.x, position.x, t)
		var offset: float = absf(crossing_x - course.goal_x)
		# The physical posts already test the full oriented wheel shape. Score
		# its swept center through their inner faces; radius is NOT axle width.
		var crossing_y: float = lerpf(previous.y, position.y, t)
		var clear: bool = goal_passes(course, crossing_x, crossing_y)
		var accuracy: float = clampf(1.0 - offset / (course.goal_width / 2 - 0.16), 0, 1)
		if clear and offset < FEEL.tire_radius * 0.25:
			add_style("BULLSEYE")
		if clear and post_hit:
			add_style("GRAZE")
		_finish("GOAL" if clear else ("POST" if post_hit else "WIDE"), accuracy, offset)
	elif absf(position.x) > course.width / 2 + 2 or position.y < -8:
		_finish("POST" if post_hit else "WIDE", 0.0, goal_delta)
	previous = position
	incoming_velocity = linear_velocity

func _finish(outcome: String, accuracy: float, offset: float) -> void:
	active = false
	last_result = {"outcome": outcome, "accuracy": accuracy, "offset": offset, "stars": style.stars(outcome == "GOAL", accuracy, course.par_style, purist), "score": style.score, "seed": roll_seed, "time": elapsed, "position": position, "events": style.events.duplicate()}
	# A finished attempt is a stable tableau, including out-of-bounds misses.
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	# Preserve the scored endpoint above, then stage an off-edge miss on the
	# shoulder so decorative cliffs cannot swallow the result's subject.
	if outcome != "GOAL" and (absf(position.x) > course.width * 0.5 or position.y < course.height_at(position.x, position.z) - 0.4):
		position.x = clampf(position.x, -course.width * 0.38, course.width * 0.38)
		position.z = clampf(position.z, 0.0, course.length)
		position.y = course.height_at(position.x, position.z) + FEEL.tire_radius + 0.04
		rotation = Vector3(0, rotation.y, 0)
		reset_physics_interpolation()
	finished.emit(last_result)

static func goal_passes(data: CourseData, x: float, y: float) -> bool:
	return absf(x - data.goal_x) < data.goal_width * 0.5 - 0.16 and y >= data.height_at(x, data.length) - 0.1

func _on_body_entered(body: Node) -> void:
	if not active:
		return
	if body.has_meta("goal_post"):
		post_hit = true
	if not body.has_meta("glass_index"):
		return
	var index: int = body.get_meta("glass_index")
	if glass_contacts.get(index, false):
		return
	var hill: HillCourse = body.get_meta("glass_course")
	# Only the speed INTO the wall counts, not the downhill component. A fast,
	# shallow approach can bank safely; a hard sideways hit punches through.
	var normal_speed: float = absf(incoming_velocity.x)
	if normal_speed >= GLASS_BREAK_SPEED:
		glass_contacts[index] = true
		add_collision_exception_with(body as PhysicsBody3D)
		linear_velocity = Vector3(incoming_velocity.x * 0.72, incoming_velocity.y, incoming_velocity.z * 0.92)
		hill.shatter(index, incoming_velocity)
		add_style("SMASH")
	elif not glass_contacts.has(index):
		glass_contacts[index] = false
		add_style("BANK")
