class_name CourseData
extends Resource

@export var title: String = "First Light"
@export var world: int = 0
@export var number: int = 1
@export var length: float = 60.0
@export var slope: float = 0.30
@export var width: float = 16.0
@export var launch_speed: float = 5.5
@export var max_speed: float = 16.0
@export var goal_x: float = 0.0
@export var goal_width: float = 3.4
@export var par_style: int = 120
@export var lane_curve: float = 1.0
@export var moving_gate: bool = false
@export var layout: int = 0
@export var description: String = "A little lean. A lot of possibility."

const WORLDS: Array[String] = ["Meadow Alps", "Coral Coast", "Ember Mesa", "Neon Nightcap"]
const SLUGS: Array[String] = ["meadow", "coral", "ember", "neon"]
const PALETTES: Array[Array] = [
	[Color("b7d8ac"), Color("e7ecc1"), Color("608775"), Color("eeb48d"), Color("cde6e5"), Color("46665c")],
	[Color("f5c0a0"), Color("ffe4ba"), Color("51978d"), Color("e8858f"), Color("bfe6e3"), Color("ba8175")],
	[Color("d98d85"), Color("f0b08b"), Color("906681"), Color("f6d177"), Color("dfbfd2"), Color("995e78")],
	[Color("b7c8e4"), Color("e2e9f5"), Color("8975b0"), Color("ec93c7"), Color("292c50"), Color("727397")]
]

func id() -> String:
	return "tutorial" if number == 0 else "%s/%02d" % [SLUGS[world], number]

func height_at(x: float, z: float) -> float:
	var base: float = (length - z) * slope
	var bend: float = sin(z / length * TAU) * lane_curve
	var gutters: float = -0.25 * cos((x - bend) * PI / 3.6) * sin(clampf(z / 9.0, 0.0, 1.0) * PI / 2.0)
	var edges: float = maxf(0.0, absf(x) - width * 0.40) * 0.50
	return base + gutters + edges

func features(roll_seed: int) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = roll_seed
	var out: Array[Dictionary] = []
	for row: int in range(3 if number < 3 else 4):
		for side: int in [-1, 1]:
			var z: float = 17.0 + row * 8.0
			var x: float = side * (2.6 + float((row + layout) % 3) * 0.9)
			out.append({"kind": "bumper" if row % 2 == 0 else "peg", "x": x + rng.randf_range(-0.05, 0.05), "z": z + rng.randf_range(-0.05, 0.05), "strength": rng.randf_range(0.9, 1.1)})
	out.append({"kind": "ramp", "x": -3.8 if layout % 2 == 0 else 3.8, "z": length * 0.57, "strength": 1.0})
	out.append({"kind": "boost", "x": 0.0, "z": length * 0.37, "strength": 1.0})
	out.append({"kind": "mud", "x": 4.4 if layout % 2 == 0 else -4.4, "z": length * 0.76, "strength": 1.0})
	if number >= 3:
		out.append({"kind": "rail", "x": -5.5, "z": length * 0.63, "strength": 1.0})
	if number >= 5:
		out.append({"kind": "log", "x": 2.0, "z": length * 0.69, "strength": rng.randf_range(-0.4, 0.4)})
	return out

static func all_courses() -> Array[CourseData]:
	var list: Array[CourseData] = []
	var paths: PackedStringArray = []
	_collect("res://courses", paths)
	paths.sort()
	for path: String in paths:
		list.append(load(path) as CourseData)
	list.sort_custom(func(a: CourseData, b: CourseData) -> bool: return a.world * 10 + a.number < b.world * 10 + b.number)
	return list

static func _collect(path: String, paths: PackedStringArray) -> void:
	for name: String in DirAccess.get_directories_at(path):
		_collect(path.path_join(name), paths)
	for name: String in DirAccess.get_files_at(path):
		if name == "course.tres" or name == "course.tres.remap":
			paths.append(path.path_join("course.tres"))
