extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	var sound: Node = root.get_node("Sound")
	assert(sound.enabled, "Audio regression requires a native audio device")
	game._action("play")
	await create_timer(1.5).timeout
	var stream: AudioStream = sound.music_players[0].stream
	var before: float = sound.music_players[0].get_playback_position()
	game._action("course", 2)
	await create_timer(0.2).timeout
	assert(sound.music_players[0].stream == stream)
	assert(sound.music_players[0].get_playback_position() > before)
	before = sound.music_players[0].get_playback_position()
	game._action("world_next")
	await create_timer(0.2).timeout
	assert(sound.music_players[0].stream == stream, "World previews preserve music")
	assert(sound.music_players[0].get_playback_position() > before)
	before = sound.music_players[0].get_playback_position()
	game.change_state(game.State.AIM)
	await create_timer(0.2).timeout
	assert(sound.world == 1 and sound.music_players[0].stream != stream)
	assert(sound.music_players[0].get_playback_position() >= before - 0.1, "Launching a new world preserves musical phase")
	print("AUDIO PASS course/world previews uninterrupted; new world starts at existing musical phase")
	sound.stop_all()
	await create_timer(0.2).timeout
	quit()
