extends Node

func vibrate(kind: String) -> void:
	if Save.data.settings.haptics and OS.get_name() in ["iOS", "Android"]:
		Input.vibrate_handheld(18 if kind == "light" else (45 if kind == "medium" else 90))

func safe_area() -> Rect2:
	var screen: Rect2i = DisplayServer.get_display_safe_area()
	if OS.get_name() not in ["iOS", "Android"] or screen.size.x <= 0:
		return Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var scale_factor: Vector2 = get_viewport().get_visible_rect().size / Vector2(DisplayServer.screen_get_size())
	return Rect2(Vector2(screen.position) * scale_factor, Vector2(screen.size) * scale_factor)

func share_image(path: String) -> String:
	# Native share sheets need a platform plugin; reveal the saved card on desktop.
	if OS.get_name() in ["macOS", "Windows", "Linux", "FreeBSD", "NetBSD", "OpenBSD"]:
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))
	return ProjectSettings.globalize_path(path)

func open_store_review() -> void:
	pass # Store IDs are assigned only after creating the actual store listings.
