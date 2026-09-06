class_name HillCamera
extends Camera3D
var course: CourseData
var target: RollingTire
var mode: String = "aim"
var trauma: float = 0.0
var age: float = 0.0
var reduce_motion: bool = false
var portrait: bool = false
var result_focus: Vector3 = Vector3.ZERO

func blend_to(new_mode: String, _duration: float = 0.2) -> void:
	mode = new_mode
	age = 0.0
	if new_mode == "result" and is_instance_valid(target):
		result_focus = target.global_position
		result_focus.x = clampf(result_focus.x, -course.width * 0.5, course.width * 0.5)
		result_focus.z = clampf(result_focus.z, 0, course.length)
		result_focus.y = maxf(result_focus.y, course.height_at(result_focus.x, result_focus.z) + 0.65)

func _process(dt: float) -> void:
	if course == null:
		return
	age += dt
	var desired: Vector3
	var look: Vector3
	var target_fov: float = 45.0
	var middle: Vector3 = Vector3(0, course.length * course.slope * 0.48, course.length * 0.5)
	match mode:
		"roll":
			if not is_instance_valid(target):
				return
			desired = target.global_position + Vector3(0, 10, -14)
			look = target.global_position + Vector3(0, -0.6, 5) + target.linear_velocity * 0.16
			target_fov = lerpf(60, 78, clampf(target.linear_velocity.length() / course.max_speed, 0, 1))
		"result":
			var angle: float = minf(age, 1.2) * 0.45
			var center: Vector3 = result_focus
			desired = center + Vector3(sin(angle) * 10, 7, -cos(angle) * 10)
			look = center
			target_fov = 55
		_:
			desired = middle + (Vector3(30, 49, 53) if not portrait else Vector3(7, 48, 47)) * (course.length / 58.0) * 1.05
			look = middle
			target_fov = 48 if not portrait else 54
	var weight: float = 1.0 if reduce_motion else 1.0 - exp(-dt * 5.0)
	if age < dt * 2 and mode == "aim":
		weight = 1.0
	position = position.lerp(desired, weight)
	fov = lerpf(fov, target_fov, weight)
	look_at(look, Vector3.UP)
	trauma = maxf(0, trauma - dt * 1.5)
	if mode == "roll" and not reduce_motion:
		h_offset = sin(age * 83) * trauma * trauma * 0.25
		v_offset = cos(age * 71) * trauma * trauma * 0.2
	else:
		h_offset = 0
		v_offset = 0
