class_name HillCourse
extends Node3D

@export var data: CourseData
var roll_seed: int = 42
var feature_list: Array[Dictionary] = []
var palette: Array = []
var posts: Array[Node3D] = []
var gate: Node3D
var visual: bool = true
var mats: Dictionary = {}
var terrain_mesh: ArrayMesh

func _ready() -> void:
	if data != null:
		build()

func material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var key: String = color.to_html() + str(metallic)
	if mats.has(key):
		return mats[key]
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	mat.metallic = metallic
	mats[key] = mat
	return mat

func mesh_node(mesh: Mesh, pos: Vector3, color: Color, parent: Node3D = self) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.position = pos
	parent.add_child(node)
	return node

func box(size_v: Vector3, pos: Vector3, color: Color, solid: bool = false, parent: Node3D = self) -> Node3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size_v
	var node: Node3D = mesh_node(mesh, pos, color, parent) if visual else Node3D.new()
	if not visual:
		parent.add_child(node)
		node.position = pos
	if solid:
		var body: StaticBody3D = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 2
		node.add_child(body)
		var col: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size_v
		col.shape = shape
		body.add_child(col)
	return node

func cylinder(radius: float, height: float, pos: Vector3, color: Color, solid: bool = false) -> Node3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var node: Node3D = mesh_node(mesh, pos, color) if visual else Node3D.new()
	if not visual:
		add_child(node)
		node.position = pos
	if solid:
		var body: StaticBody3D = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 2
		node.add_child(body)
		var col: CollisionShape3D = CollisionShape3D.new()
		var shape: CylinderShape3D = CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		col.shape = shape
		body.add_child(col)
	return node

func build() -> void:
	palette = CourseData.PALETTES[data.world]
	feature_list = data.features(roll_seed)
	_build_terrain()
	for f: Dictionary in feature_list:
		var pos: Vector3 = Vector3(f.x, data.height_at(f.x, f.z), f.z)
		match f.kind:
			"bumper", "peg":
				var radius: float = 0.68 if f.kind == "bumper" else 0.32
				cylinder(radius, 1.1, pos + Vector3.UP * 0.55, palette[3] if f.kind == "bumper" else palette[2], true)
				if visual:
					cylinder(radius + 0.10, 0.15, pos + Vector3.UP * 0.72, Color("fff3d5"))
					cylinder(radius + 0.18, 0.12, pos + Vector3.UP * 0.08, palette[5])
			"ramp":
				var ramp: Node3D = box(Vector3(2.4, 0.28, 3.6), pos + Vector3.UP * 0.45, palette[3], true)
				ramp.rotation.x = -0.24
				if visual:
					for i: int in range(3):
						box(Vector3(1.8, 0.035, 0.15), Vector3(0, 0.16, -1.0 + i * 0.8), Color("fff0d2"), false, ramp)
			"boost", "mud":
				if visual:
					var pad: Node3D = box(Vector3(2.2, 0.07, 3), pos + Vector3.UP * 0.06, palette[2] if f.kind == "boost" else palette[5])
					pad.rotation.x = atan(data.slope)
					if f.kind == "boost":
						for i: int in range(3):
							box(Vector3(1.5, 0.025, 0.15), Vector3(0, 0.05, -0.8 + i * 0.7), Color("e9f1b7"), false, pad)
			"rail":
				box(Vector3(0.24, 0.25, 7.0), pos + Vector3.UP * 0.8, palette[3], true).rotation.x = atan(data.slope)
			"log":
				var log_node: Node3D = cylinder(0.35, 2.7, pos + Vector3.UP * 0.45, palette[5], true)
				log_node.rotation.z = PI / 2.0
				log_node.rotation.y = f.strength
	_build_goal()
	if visual:
		_build_decor()
		_batch_visuals()

func _build_terrain() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx: int = 24
	var nz: int = int(data.length)
	for z: int in range(nz):
		for x: int in range(nx):
			var color: Color = palette[0].lerp(palette[1], 0.1 + 0.07 * float((x * 7 + z * 3) % 4))
			for c: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var px: float = -data.width / 2 + float(x + c.x) / nx * data.width
				var pz: float = float(z + c.y) / nz * (data.length + 5) - 2
				st.set_color(color)
				st.add_vertex(Vector3(px, data.height_at(px, pz), pz))
	st.generate_normals()
	terrain_mesh = st.commit()
	if visual:
		var mi: MeshInstance3D = mesh_node(terrain_mesh, Vector3.ZERO, palette[0])
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.roughness = 1.0
		mi.material_override = mat
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)
	var col: CollisionShape3D = CollisionShape3D.new()
	col.shape = terrain_mesh.create_trimesh_shape()
	body.add_child(col)
	var phys: PhysicsMaterial = PhysicsMaterial.new()
	phys.friction = 0.75
	phys.bounce = 0.05
	body.physics_material_override = phys
	if visual:
		# Layered cliff sides make the playable terrain a floating postcard diorama.
		for side: int in [-1, 1]:
			for z: int in range(0, int(data.length) + 3, 3):
				var x: float = side * (data.width / 2.0 - 0.15)
				box(Vector3(0.5, 3.1, 3.1), Vector3(x, data.height_at(x, z) - 1.65, z), palette[5].lerp(palette[3], float(z % 9) / 30.0))
		var pad: Node3D = box(Vector3(7.8, 0.10, 3.2), Vector3(0, data.height_at(0, 0) + 0.03, 0), palette[1])
		pad.rotation.x = atan(data.slope)
		for i: int in range(7):
			box(Vector3(0.65, 0.025, 0.25), Vector3(-3 + i, 0.065, 1), palette[2], false, pad)
		# Three readable routes converge toward the finish; actual gutters are in the mesh.
		for lane: int in [-1, 0, 1]:
			for z: int in range(7, int(data.length) - 3, 2):
				var x: float = lane * 4.7 + sin(z / data.length * TAU) * data.lane_curve
				var tile: Node3D = box(Vector3(0.10, 0.025, 0.5), Vector3(x, data.height_at(x, z) + 0.045, z), palette[1])
				tile.rotation.x = atan(data.slope)

func _build_goal() -> void:
	for side: int in [-1, 1]:
		var x: float = data.goal_x + side * data.goal_width / 2.0
		var y: float = data.height_at(x, data.length)
		var post: Node3D = cylinder(0.16, 3.3, Vector3(x, y + 1.65, data.length), Color("fff3d7"), true)
		posts.append(post)
		if visual:
			var flag: Node3D = box(Vector3(0.8, 0.5, 0.06), Vector3(x + side * 0.35, y + 2.9, data.length), palette[3])
			flag.rotation.z = side * -0.12
			for stripe: int in range(3):
				box(Vector3(0.22, 0.07, 0.09), Vector3(x, y + 0.4 + stripe * 0.4, data.length - 0.13), palette[2])
	if visual:
		for x: int in range(8):
			for z: int in range(2):
				var px: float = data.goal_x - data.goal_width / 2 + data.goal_width * (x + 0.5) / 8.0
				var pz: float = data.length + z * 0.25
				box(Vector3(data.goal_width / 8, 0.035, 0.25), Vector3(px, data.height_at(px, pz) + 0.04, pz), palette[2] if (x + z) % 2 == 0 else Color("fff2d5"))
	if data.moving_gate:
		gate = box(Vector3(0.6, 1.2, 0.4), Vector3(data.goal_x, 0.8, data.length - 2), palette[3], true)

func tick_gate(time: float) -> void:
	if gate != null:
		gate.position.x = data.goal_x + sin(time * 1.8) * data.goal_width * 0.7

func _build_decor() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9000 + data.world * 100 + data.number
	for i: int in range(35):
		var z: float = rng.randf_range(-3, data.length + 3)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = side * rng.randf_range(data.width / 2 + 1.2, data.width / 2 + 8.0)
		var y: float = data.height_at(side * data.width / 2, z) - 0.9
		var scale_v: float = rng.randf_range(0.7, 1.8)
		var island: SphereMesh = SphereMesh.new()
		island.radial_segments = 8
		island.rings = 3
		island.radius = 2.0 * scale_v
		island.height = 1.4 * scale_v
		mesh_node(island, Vector3(x, y - 0.5, z), palette[0])
		if i % 3 != 0:
			_tree(Vector3(x, y, z), scale_v, i)
		else:
			var rock: SphereMesh = SphereMesh.new()
			rock.radial_segments = 5
			rock.rings = 2
			rock.radius = scale_v * 0.8
			rock.height = scale_v * 1.3
			mesh_node(rock, Vector3(x, y + scale_v * 0.4, z), palette[5].lerp(palette[1], 0.5))
	# Small flowers and mushrooms on the edge of the track.
	for i: int in range(24):
		var z: float = rng.randf_range(5, data.length - 3)
		var x: float = (-1 if i % 2 == 0 else 1) * (data.width * 0.43)
		var y: float = data.height_at(x, z)
		cylinder(0.06, 0.4, Vector3(x, y + 0.2, z), palette[2])
		var flower: SphereMesh = SphereMesh.new()
		flower.radius = 0.22
		flower.height = 0.2
		flower.radial_segments = 6
		flower.rings = 2
		mesh_node(flower, Vector3(x, y + 0.42, z), palette[3] if i % 2 == 0 else palette[1])

func _tree(pos: Vector3, s: float, index: int) -> void:
	var model_path: String = "res://assets/models/" + ["tree_pineRoundA.obj", "tree_palmTall.obj", "cactus_tall.obj", "tree_pineRoundA.obj"][data.world]
	if ResourceLoader.exists(model_path):
		var mesh: Mesh = load(model_path) as Mesh
		var tree: MeshInstance3D = mesh_node(mesh, pos, palette[2].lerp(palette[0], float(index % 3) * 0.16))
		tree.scale = Vector3.ONE * s * 1.7
		return
	cylinder(0.15 * s, 1.5 * s, pos + Vector3.UP * 0.75 * s, palette[5])
	var crown: CylinderMesh = CylinderMesh.new()
	crown.top_radius = 0.15
	crown.bottom_radius = 1.1 * s
	crown.height = 2.7 * s
	crown.radial_segments = 7
	mesh_node(crown, pos + Vector3.UP * 2.5 * s, palette[2])

func _batch_visuals() -> void:
	# Merge stationary primitives by material; physics bodies keep their transforms.
	var groups: Dictionary = {}
	var nodes: Array[Node] = find_children("*", "MeshInstance3D", true, false)
	for node: Node in nodes:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi == gate or mi in posts or mi.mesh == terrain_mesh:
			continue
		var mat: Material = mi.material_override
		if mat == null:
			continue
		var key: int = mat.get_instance_id()
		if not groups.has(key):
			var st: SurfaceTool = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = {"st": st, "mat": mat}
		for surface: int in range(mi.mesh.get_surface_count()):
			groups[key].st.append_from(mi.mesh, surface, global_transform.affine_inverse() * mi.global_transform)
		mi.visible = false
	for key: int in groups:
		var merged: MeshInstance3D = MeshInstance3D.new()
		merged.mesh = groups[key].st.commit()
		merged.material_override = groups[key].mat
		add_child(merged)
