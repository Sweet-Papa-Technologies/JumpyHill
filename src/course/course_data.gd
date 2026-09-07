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
	var gutters: float = -0.09 * cos((x - bend) * PI / 3.6) * sin(clampf(z / 9.0, 0.0, 1.0) * PI / 2.0)
	var edges: float = maxf(0.0, absf(x) - width * 0.40) * 0.20
	# Compact, smooth earthworks. The first obstacle stays on a predictable slope;
	# later crests launch fast wheels and compress slow wheels into the troughs.
	var relief: float = 0.0
	if number > 0:
		var side: float = -1.0 if layout % 2 == 0 else 1.0
		relief += (0.8 + world * 0.12) * mound(z, length * 0.34 + x * side * 0.12, 3.3)
		relief -= 0.55 * mound(z, length * 0.43, 3.4)
		relief += (0.65 + (number % 3) * 0.15) * mound(z, length * 0.78 - x * side * 0.16, 3.2)
		# Raised side-lane takeoff before the missing slab; the center is a bypass.
		relief += 1.05 * mound(x, side * 4.8, 3.0) * mound(z, gap_start() - 1.8, 2.8)
		# Outer bank is useful for wall rebounds without funneling the center lane.
		relief += 0.5 * mound(z, length * 0.54, 7.0) * pow(maxf(0, absf(x) - 4.0) / 4.0, 2)
	return base + gutters + edges + relief

static func mound(value: float, center: float, radius: float) -> float:
	var t: float = absf(value - center) / radius
	return 0.5 + 0.5 * cos(t * PI) if t < 1.0 else 0.0

func gap_start() -> float:
	return length * 0.60

func gap_rect() -> Rect2:
	var side: float = -1.0 if layout % 2 == 0 else 1.0
	return Rect2(2.7 if side > 0 else -6.7, gap_start(), 4.0, 2.2 + world * 0.25)

func has_ground(x: float, z: float) -> bool:
	if absf(x) > width * 0.5 or z < -2 or z > length + 3:
		return false
	if number == 0:
		return true
	# Match the mesh's omitted cells, including the exact boundary coordinates.
	var cell_x: float = width / 48.0
	var cell_z: float = (length + 5.0) / int(length * 2)
	var center: Vector2 = Vector2((floor((x + width * 0.5) / cell_x) + 0.5) * cell_x - width * 0.5, (floor((z + 2) / cell_z) + 0.5) * cell_z - 2)
	return not gap_rect().has_point(center)

func terrain_hint() -> String:
	return "Find your line. Two nudges if you need them." if number == 0 else "Roll the crests · jump the side gap · bank gently off glass"


func features(roll_seed: int) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = roll_seed
	var out: Array[Dictionary] = []
	if number == 0:
		out.append({"kind": "bumper", "x": 2.8 + rng.randf_range(-0.05, 0.05), "z": 23.0, "strength": 1.0})
		out.append({"kind": "ramp", "x": -3.8, "z": 34.0, "strength": 1.0})
		return out
	# Each chapter introduces a readable obstacle arrangement. The center is
	# deliberately contested; difficulty comes from route choice, not auto-aim.
	var mirror: float = -1.0 if layout % 2 == 0 else 1.0
	out.append({"kind": "barrier", "x": 0.0, "z": 13.0, "strength": 1.0, "span": 2.4, "yaw": 0.0})
	var rows: int = 3 + world / 2 + (1 if number >= 5 else 0)
	for row: int in range(rows):
		var z: float = 23.0 + row * (length - 33.0) / maxi(1, rows - 1)
		var side: float = mirror * (-1.0 if row % 2 == 0 else 1.0)
		var x: float = side * (3.0 + float((row + number) % 3) * 0.65)
		out.append({"kind": "bumper" if (row + number) % 3 != 0 else "barrier", "x": x + rng.randf_range(-0.08, 0.08), "z": z, "strength": rng.randf_range(0.9, 1.1), "span": 2.0, "yaw": side * -0.25})
		out.append({"kind": "peg", "x": -side * (4.0 + (row % 2) * 1.2), "z": z + 2.0, "strength": 1.0})
	var mover_z: float = length * (0.54 if number % 2 else 0.65)
	out.append({"kind": "sweeper" if number % 2 else "shuttle", "x": mirror * 0.8, "z": mover_z, "strength": 1.0, "span": 3.0 + world * 0.25, "rate": 0.75 + world * 0.12, "phase": float(number) * 0.7})
	if number >= 5 or world >= 2:
		out.append({"kind": "shuttle" if number % 2 else "sweeper", "x": -mirror * 1.8, "z": length * 0.82, "strength": 1.0, "span": 2.8, "rate": 1.0 + world * 0.1, "phase": float(number)})
	out.append({"kind": "ramp", "x": mirror * 4.7, "z": length * 0.44, "strength": 1.0})
	out.append({"kind": "boost", "x": -mirror * 4.2, "z": length * 0.35, "strength": 1.0})
	out.append({"kind": "mud", "x": mirror * 2.0, "z": length * 0.73, "strength": 1.0})
	out.append({"kind": "spring" if world == 2 else "ice", "x": -mirror * 3.7, "z": length * 0.86, "strength": 1.0})
	if number >= 3:
		out.append({"kind": "rail", "x": -mirror * 5.8, "z": length * 0.56, "strength": 1.0})
	# Never leave an old obstacle floating in a newly excavated jump lane.
	for feature: Dictionary in out:
		if not has_ground(feature.x, feature.z):
			feature.z = gap_rect().end.y + 2.0
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
