class_name HillScenery
extends RefCounted
# Original geometry: each biome gets a silhouette, landmark and trail furniture.
static func build(hill: HillCourse) -> void:
	var data: CourseData = hill.data
	var p: Array = hill.palette
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 821 + data.layout
	for side: int in [-1, 1]:
		# Continuous terraced cliffs replace the thin floating plank.
		for z: int in range(0, int(data.length) + 2, 4):
			var x: float = side * (data.width * 0.5 + 1.7)
			var y: float = data.height_at(x, z)
			for tier: int in range(3):
				var rock: CylinderMesh = CylinderMesh.new()
				rock.top_radius = 2.2 - tier * 0.35
				rock.bottom_radius = 1.9 - tier * 0.45
				rock.height = 2.0
				rock.radial_segments = 6
				var node: MeshInstance3D = hill.mesh_node(rock, Vector3(x, y - 1.8 - tier * 1.65, z), p[5].lerp(p[3], tier * 0.12))
				node.rotation.y = float(z % 5) * 0.2
			# Chunky cream curbs and contrasting corner reflectors.
			var curb: Node3D = hill.box(Vector3(0.24, 0.14, 3.6), Vector3(side * (data.width * 0.5 - 0.15), y + 0.02, z), p[1])
			curb.rotation.x = atan(data.slope)
			if z % 8 == 0:
				hill.cylinder(0.09, 0.8, Vector3(side * (data.width * 0.5 - 0.4), y + 0.4, z), p[5])
				hill.box(Vector3(0.22, 0.16, 0.12), Vector3(side * (data.width * 0.5 - 0.4), y + 0.72, z - 0.06), p[3])
		for i: int in range(9):
			var z: float = i * data.length / 8.0
			var x: float = side * rng.randf_range(12.0, 18.0)
			var y: float = data.height_at(side * 8, z) - 6.0
			var mountain: CylinderMesh = CylinderMesh.new()
			mountain.top_radius = 0.2 if data.world != 2 else 2.1
			mountain.bottom_radius = rng.randf_range(3.0, 5.0)
			mountain.height = rng.randf_range(4.0, 8.0)
			mountain.radial_segments = 6
			hill.mesh_node(mountain, Vector3(x, y, z), p[2].lerp(p[5], float(i % 3) * 0.16))
			if data.world == 0:
				var snow: CylinderMesh = CylinderMesh.new()
				snow.top_radius = 0.0
				snow.bottom_radius = mountain.bottom_radius * 0.30
				snow.height = mountain.height * 0.32
				snow.radial_segments = 6
				hill.mesh_node(snow, Vector3(x, y + mountain.height * 0.35, z), Color("fff4df"))
	# Dense shoulder planting stays outside the collision space.
	for i: int in range(160):
		var z: float = rng.randf_range(3, data.length - 1)
		var x: float = (-1 if i % 2 else 1) * rng.randf_range(6.75, 7.6)
		var y: float = data.height_at(x, z)
		if data.world in [0, 3]:
			var grass: CylinderMesh = CylinderMesh.new()
			grass.top_radius = 0
			grass.bottom_radius = rng.randf_range(0.08, 0.20)
			grass.height = rng.randf_range(0.18, 0.45)
			grass.radial_segments = 3
			hill.mesh_node(grass, Vector3(x, y + grass.height / 2, z), p[2] if i % 3 else p[3])
		else:
			var stone: SphereMesh = SphereMesh.new()
			stone.radius = rng.randf_range(0.08, 0.25)
			stone.height = stone.radius * 1.2
			stone.radial_segments = 6
			stone.rings = 3
			hill.mesh_node(stone, Vector3(x, y + stone.radius * 0.3, z), p[1] if i % 3 else p[3])
	_landmark(hill, Vector3(-11, data.height_at(-8, data.length * 0.40), data.length * 0.40))
	_landmark(hill, Vector3(11, data.height_at(8, data.length * 0.75), data.length * 0.75))
	# Finish pavilion: the end of a course has a destination and a landing apron.
	var finish_y: float = data.height_at(data.goal_x, data.length)
	for side: int in [-1, 1]:
		hill.box(Vector3(0.35, 4.3, 0.35), Vector3(data.goal_x + side * (data.goal_width / 2 + 0.5), finish_y + 2.0, data.length + 0.8), p[5])
	hill.box(Vector3(data.goal_width + 1.5, 0.65, 0.45), Vector3(data.goal_x, finish_y + 4.0, data.length + 0.8), p[3])
	for i: int in range(7):
		hill.box(Vector3(0.18, 0.28, 0.04), Vector3(data.goal_x - 1.2 + i * 0.4, finish_y + 4.0, data.length + 0.55), p[1])
	# Course pennants, each visually distinct from hazard warning marks.
	for z: float in [5.0, data.length * 0.5]:
		for side: int in [-1, 1]:
			var x: float = side * 7.4
			var y: float = data.height_at(x, z)
			hill.cylinder(0.06, 2.3, Vector3(x, y + 1.15, z), p[5])
			var flag: Node3D = hill.box(Vector3(0.7, 0.5, 0.035), Vector3(x - side * 0.3, y + 2.05, z), p[3])
			flag.rotation.z = side * 0.12

static func _landmark(hill: HillCourse, pos: Vector3) -> void:
	var p: Array = hill.palette
	match hill.data.world:
		0: # Alpine cabins, pitched roofs, windows and chimneys.
			hill.box(Vector3(3.1, 2.1, 3.3), pos + Vector3.UP * 0.7, p[1])
			for side: int in [-1, 1]:
				var roof: Node3D = hill.box(Vector3(2.1, 0.20, 3.9), pos + Vector3(side * 0.85, 2.15, 0), p[3])
				roof.rotation.z = side * -0.48
				hill.box(Vector3(0.55, 0.65, 0.08), pos + Vector3(side * 0.9, 0.85, -1.69), p[2])
			hill.box(Vector3(0.65, 1.25, 0.09), pos + Vector3(0, 0.3, -1.70), p[5])
			hill.box(Vector3(0.45, 1.3, 0.5), pos + Vector3(0.8, 2.5, 0.8), p[5])
		1: # Striped lighthouse and lantern gallery.
			for i: int in range(6):
				hill.cylinder(0.9 - i * 0.04, 0.8, pos + Vector3.UP * (i * 0.8), p[1] if i % 2 else p[3])
			hill.cylinder(1.2, 0.2, pos + Vector3.UP * 4.5, p[5])
			hill.cylinder(0.65, 0.9, pos + Vector3.UP * 5, Color("ffe8ad"))
			hill.cylinder(1.0, 0.25, pos + Vector3.UP * 5.6, p[2])
			for i: int in range(8):
				var a: float = i * TAU / 8
				hill.cylinder(0.04, 0.7, pos + Vector3(cos(a), 4.8, sin(a)), p[5])
		2: # Weathered desert stone arch.
			for side: int in [-1, 1]:
				hill.box(Vector3(1.4, 5.0, 2), pos + Vector3(side * 1.6, 1.3, 0), p[5])
				hill.box(Vector3(1.8, 0.5, 2.2), pos + Vector3(side * 1.6, 3.5, 0), p[3])
			hill.box(Vector3(4.6, 1.1, 2), pos + Vector3.UP * 4.0, p[3])
		3: # Stacked orbital sculptures and luminous pylons.
			hill.cylinder(1.8, 0.4, pos, p[5])
			for i: int in range(3):
				var ring: TorusMesh = TorusMesh.new()
				ring.inner_radius = 1.6 - i * 0.2
				ring.outer_radius = 1.76 - i * 0.2
				ring.rings = 32
				ring.ring_segments = 8
				var node: MeshInstance3D = hill.mesh_node(ring, pos + Vector3.UP * (1.3 + i * 1.15), p[3] if i % 2 else p[1])
				node.rotation = Vector3(0.3 + i * 0.5, 0, 0.4)
			hill.cylinder(0.2, 5.2, pos + Vector3.UP * 2.6, p[3])
