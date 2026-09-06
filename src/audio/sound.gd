extends Node
var players: Array[AudioStreamPlayer] = []
var music_players: Array[AudioStreamPlayer] = []
var tier: float = 0.0
var world: int = -1
var duck: float = 0.0
var enabled: bool = true
var streams: Dictionary = {}
var rolling: AudioStreamPlayer
var roll_surface: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = DisplayServer.get_name() != "headless"
	for name: String in ["Music", "SFX"]:
		var index: int = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(index, name)
		AudioServer.set_bus_send(index, "Master")
	for i: int in range(8):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		players.append(player)
	for i: int in range(3):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		music_players.append(player)
	rolling = AudioStreamPlayer.new()
	rolling.bus = "SFX"
	add_child(rolling)
	apply_settings()

func apply_settings() -> void:
	for pair: Array in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(pair[0]), linear_to_db(maxf(0.0001, float(Save.data.settings[pair[1]]))))

func set_world(value: int) -> void:
	if not enabled or world == value:
		return
	world = value
	for i: int in range(3):
		music_players[i].stream = load("res://assets/audio/world_%d_stem_%d.wav" % [world, i]) as AudioStream
		music_players[i].play()

func _process(dt: float) -> void:
	duck = maxf(0, duck - dt)
	for i: int in range(music_players.size()):
		var volume: float = 0.55 if i == 0 else clampf(tier - (i - 1), 0.03, 0.7)
		var db: float = linear_to_db(volume) - (6.0 if duck > 0 else 0.0)
		music_players[i].volume_db = lerpf(music_players[i].volume_db, db, minf(1, dt * 4))

func play(event: String) -> void:
	if not enabled:
		return
	var path: String = "res://assets/audio/click.wav"
	match event:
		"BOING", "TOCK": path = "res://assets/audio/impactWood_medium_000.ogg"
		"POST", "WIDE": path = "res://assets/audio/impactMetal_light_000.ogg"
		"GOAL":
			path = "res://assets/audio/goal.wav"
			duck = 1.4
		"WHOOSH", "BOOST", "AIR": path = "res://assets/audio/whoosh.wav"
	if not streams.has(path):
		streams[path] = load(path)
	for player: AudioStreamPlayer in players:
		if not player.playing:
			player.stream = streams[path]
			player.play()
			return

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		AudioServer.set_bus_mute(0, false)

func set_roll(speed: float, surface: int) -> void:
	if not enabled or rolling == null:
		return
	if speed < 0.5:
		rolling.volume_db = -80
		return
	var index: int = 1 if surface == 3 else (2 if surface == 2 else 0)
	if index != roll_surface:
		roll_surface = index
		var file: String = ["footstep_grass_000.ogg", "footstep_snow_000.ogg", "footstep_concrete_000.ogg"][index]
		var stream: AudioStreamOggVorbis = load("res://assets/audio/" + file) as AudioStreamOggVorbis
		stream.loop = true
		rolling.stream = stream
		rolling.play()
	rolling.pitch_scale = clampf(0.7 + speed * 0.075, 0.7, 2.0)
	rolling.volume_db = lerpf(-25, -13, clampf(speed / 16, 0, 1))

func stop_all() -> void:
	enabled = false
	for player: AudioStreamPlayer in music_players + players:
		player.stop()
		player.stream = null
	if is_instance_valid(rolling):
		rolling.stop()
		rolling.stream = null
	streams.clear()

func _exit_tree() -> void:
	stop_all()
