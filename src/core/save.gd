extends Node
const PATH: String = "user://save.json"
var data: Dictionary = {"version": 1, "courses": {}, "daily": {}, "tire": 0, "settings": {"master": 0.8, "music": 0.55, "sfx": 0.8, "haptics": true, "left_handed": false, "reduce_motion": false, "colorblind": false}}
var last_error: String = ""
var test_mode: bool = false

func _ready() -> void:
	test_mode = "--test" in OS.get_cmdline_user_args()
	if test_mode:
		return
	if FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary and int(parsed.get("version", 0)) == 1:
			for key: String in ["courses", "daily", "settings"]:
				if parsed.get(key) is Dictionary:
					data[key].merge(parsed[key], true)
			data.tire = clampi(int(parsed.get("tire", 0)), 0, 3)

func persist(path: String = PATH) -> bool:
	if test_mode and path == PATH:
		return true
	var file: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	var err: Error = DirAccess.rename_absolute(path + ".tmp", path)
	last_error = "" if err == OK else error_string(err)
	return err == OK

func record(course_id: String, stars: int, score: int, roll_seed: int) -> void:
	var old: Dictionary = data.courses.get(course_id, {})
	data.courses[course_id] = {"stars": maxi(stars, int(old.get("stars", 0))), "score": maxi(score, int(old.get("score", 0))), "seed": roll_seed if score >= int(old.get("score", 0)) else old.get("seed", roll_seed)}
	persist()

func stars_total() -> int:
	var total: int = 0
	for value: Dictionary in data.courses.values():
		total += int(value.get("stars", 0))
	return total

func world_unlocked(world: int) -> bool:
	if world == 0:
		return true
	var total: int = 0
	for key: String in data.courses:
		if key.begins_with(CourseData.SLUGS[world - 1]):
			total += int(data.courses[key].stars)
	return total >= 4

func daily_for(date: String) -> Dictionary:
	var value: int = 2166136261
	for byte: int in ("treadfall-v1:" + date).to_utf8_buffer():
		value = ((value ^ byte) * 16777619) & 0x7fffffff
	return {"course": 1 + value % 32, "seed": value, "date": date}
