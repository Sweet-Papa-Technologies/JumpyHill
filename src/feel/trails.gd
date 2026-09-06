class_name TireTrails
extends Node3D
var dust: CPUParticles3D
var decals: Array[Decal] = []
var cursor: int = 0
var timer: float = 0.0

func _ready() -> void:
	dust = CPUParticles3D.new()
	dust.amount = 24
	dust.lifetime = 0.65
	dust.direction = Vector3(0, 1, -0.3)
	dust.spread = 40
	dust.initial_velocity_min = 0.4
	dust.initial_velocity_max = 1.3
	dust.gravity = Vector3(0, 0.3, 0)
	dust.scale_amount_min = 0.05
	dust.scale_amount_max = 0.16
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 5
	mesh.rings = 2
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color("e8e6c6")
	mesh.material = mat
	dust.mesh = mesh
	dust.emitting = false
	add_child(dust)
	var img: Image = Image.create(32, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	for y: int in range(4, 60, 10):
		img.fill_rect(Rect2i(3, y, 11, 5), Color(0.18, 0.25, 0.23, 0.3))
		img.fill_rect(Rect2i(18, y + 3, 11, 5), Color(0.18, 0.25, 0.23, 0.3))
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	for i: int in range(24):
		var decal: Decal = Decal.new()
		decal.texture_albedo = texture
		decal.size = Vector3(0.6, 0.9, 1.0)
		decal.visible = false
		add_child(decal)
		decals.append(decal)

func tick(dt: float, tire: RollingTire) -> void:
	var rolling: bool = tire.active and tire.linear_velocity.length() > 2
	var ground: float = tire.course.height_at(tire.position.x, tire.position.z)
	rolling = rolling and tire.position.y - ground < 0.95
	dust.emitting = rolling
	dust.position = tire.position - Vector3.UP * 0.55
	dust.color = Color("e3eaf5") if tire.course.world == 3 else Color("e8e6c6")
	timer += dt
	if not rolling or timer < 0.15:
		return
	var soft_surface: bool = tire.course.world == 3
	for feature: Dictionary in tire.features:
		if feature.kind == "mud" and absf(tire.position.x - feature.x) < 1.3 and absf(tire.position.z - feature.z) < 1.7:
			soft_surface = true
	if soft_surface:
		timer = 0
		var decal: Decal = decals[cursor]
		decal.position = Vector3(tire.position.x, ground + 0.08, tire.position.z)
		decal.rotation = Vector3(atan(tire.course.slope), tire.rotation.y, 0)
		decal.visible = true
		cursor = (cursor + 1) % decals.size()

func clear() -> void:
	dust.emitting = false
	for decal: Decal in decals:
		decal.visible = false
