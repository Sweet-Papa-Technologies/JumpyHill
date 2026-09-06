extends SceneTree
# Round-trip a procedural height field through an editable PNG, then bake the
# exact sampled mesh and triangle collider into a reusable terrain scene.
func _initialize() -> void:
	call_deferred("bake")

func bake() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var course_id: String = args[0] if args.size() > 0 else "meadow/01"
	var data: CourseData
	for candidate: CourseData in CourseData.all_courses():
		if candidate.id() == course_id:
			data = candidate
	if data == null:
		push_error("Unknown course: " + course_id)
		quit(1)
		return
	var path: String = "res://build/baked/" + course_id.replace("/", "_")
	DirAccess.make_dir_recursive_absolute(path)
	var image: Image
	if args.size() > 1:
		image = Image.load_from_file(args[1])
		if image == null or image.is_empty():
			push_error("Cannot load heightmap")
			quit(1)
			return
	else:
		image = Image.create(129, 257, false, Image.FORMAT_RGB8)
		for z: int in range(image.get_height()):
			for x: int in range(image.get_width()):
				var px: float = (float(x) / (image.get_width() - 1) - 0.5) * data.width
				var pz: float = float(z) / (image.get_height() - 1) * (data.length + 5) - 2
				var height: float = (data.height_at(px, pz) + 4) / 40
				image.set_pixel(x, z, Color(height, height, height))
		image.save_png(path + "/heightmap.png")
		image = Image.load_from_file(path + "/heightmap.png")
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z: int in range(image.get_height() - 1):
		for x: int in range(image.get_width() - 1):
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var ix: int = x + corner.x
				var iz: int = z + corner.y
				var px: float = (float(ix) / (image.get_width() - 1) - 0.5) * data.width
				var pz: float = float(iz) / (image.get_height() - 1) * (data.length + 5) - 2
				surface.add_vertex(Vector3(px, image.get_pixel(ix, iz).r * 40 - 4, pz))
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	var parent: Node3D = Node3D.new()
	parent.name = "BakedTerrain"
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	parent.add_child(mi)
	mi.owner = parent
	var body: StaticBody3D = StaticBody3D.new()
	parent.add_child(body)
	body.owner = parent
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	shape.owner = parent
	var scene: PackedScene = PackedScene.new()
	scene.pack(parent)
	var err: Error = ResourceSaver.save(scene, path + "/terrain.tscn")
	parent.free()
	print("BAKE ", course_id, " ", error_string(err), " PNG grayscale maps [-4,36] metres")
	quit(0 if err == OK else 1)
