class_name HillCamera
extends Camera3D
var course: CourseData
var target: RollingTire
var mode: String = "aim"
var trauma: float = 0.0
var age: float = 0.0
var reduce_motion: bool = false
var portrait: bool = false
var first_person: bool = true
var gameplay_frame: bool = false
var snap_view: bool = false
var heading: float = 0.0
var result_focus: Vector3 = Vector3.ZERO

func blend_to(new_mode: String, _duration: float = 0.2) -> void:
	mode = new_mode
	age = 0.0
	if new_mode == "result" and is_instance_valid(target):
		result_focus = target.global_position
		result_focus.x = clampf(result_focus.x, -course.width * 0.5, course.width * 0.5)
		result_focus.z = clampf(result_focus.z, 0, course.length)
		result_focus.y = maxf(result_focus.y, course.height_at(result_focus.x, result_focus.z) + 0.65)

func toggle_view() -> void:
	first_person = not first_person
	snap_view = true

func _process(dt: float) -> void:
	if course == null:
		return
	age += dt
	var desired: Vector3
	var look: Vector3
	var target_fov: float = 45.0
	var middle: Vector3 = Vector3(0, course.length * course.slope * 0.48, course.length * 0.5)
	if mode in ["aim", "roll"] and gameplay_frame:
		if not is_instance_valid(target):
			return
		if first_person:
			# Follow translation, never the spinning tire basis. Keep gravity up
			# and damp heading changes so bumps do not become camera rolls.
			var wanted_heading: float = target.aim * deg_to_rad(25)
			if mode == "roll" and target.linear_velocity.length() > 1.0:
				wanted_heading = clampf(atan2(target.linear_velocity.x, maxf(1.0, target.linear_velocity.z)), -0.9, 0.9)
			heading = wanted_heading if mode == "aim" or snap_view else lerp_angle(heading, wanted_heading, 1.0 - exp(-dt * 3.0))
			var forward: Vector3 = Vector3(sin(heading), -course.slope - 0.18, cos(heading)).normalized()
			desired = target.position + Vector3.UP * 0.85 + Vector3(sin(heading), 0, cos(heading)) * 0.85
			look = desired + forward * 20
			target_fov = 72 if not portrait else 78
			near = 0.08
		else:
			# Fit the actual launch/finish bounds into the space above the dock.
			# This uses the full viewport and eliminates the old sidebar margin.
			target_fov = 50
			var direction: Vector3 = (Vector3(58, 60, 32) if not portrait else Vector3(5, 49, 42)).normalized()
			var right: Vector3 = Vector3.UP.cross(direction).normalized()
			var up: Vector3 = direction.cross(right)
			var aspect: float = get_viewport().get_visible_rect().size.aspect()
			var tan_v: float = tan(deg_to_rad(target_fov / 2))
			var distance: float = 0.0
			for x: float in [-course.width * 0.5, course.width * 0.5]:
				for z: float in [-1.0, course.length + 1.0]:
					for h: float in [0.0, 4.5]:
						var offset: Vector3 = Vector3(x, course.height_at(x, z) + h, z) - middle
						distance = maxf(distance, offset.dot(direction) + maxf(absf(offset.dot(right)) / (tan_v * aspect * 0.90), absf(offset.dot(up)) / (tan_v * (0.64 if portrait else 0.70))))
			var dock_offset: Vector3 = -up * distance * tan_v * (0.04 if portrait else 0.10)
			desired = middle + dock_offset + direction * distance
			look = middle + dock_offset
	elif mode == "result":
		var angle: float = minf(age, 1.2) * 0.45
		desired = result_focus + Vector3(sin(angle) * 10, 7, -cos(angle) * 10)
		look = result_focus
		target_fov = 55
	else:
		desired = middle + (Vector3(30, 49, 53) if not portrait else Vector3(7, 48, 47)) * (course.length / 58.0) * 1.05
		look = middle
		target_fov = 48 if not portrait else 54
	var weight: float = 1.0 if reduce_motion else 1.0 - exp(-dt * 5.0)
	if snap_view or (age < dt * 2 and mode == "aim"):
		weight = 1.0
	snap_view = false
	position = position.lerp(desired, weight)
	fov = lerpf(fov, target_fov, weight)
	look_at(look, Vector3.UP)
	trauma = maxf(0, trauma - dt * 1.5)
	if mode == "roll" and not first_person and not reduce_motion:
		h_offset = sin(age * 83) * trauma * trauma * 0.25
		v_offset = cos(age * 71) * trauma * trauma * 0.2
	else:
		h_offset = 0
		v_offset = 0
